import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/friend.dart';
import '../models/transaction.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Dashboard'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Transaction>('transactions').listenable(),
        builder: (context, transactionsBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<Friend>('friends').listenable(),
            builder: (context, friendsBox, _) {
              final transactions = transactionsBox.values.where((t) => !t.isArchived).toList();
              final friends = friendsBox.values.toList();
              
              double totalOwedToYou = 0;
              double totalYouOwe = 0;
              int activeDebts = 0;
              int settledDebts = 0;
              
              // Calculate totals
              for (final friend in friends) {
                if (friend.totalDebt > 0) {
                  totalOwedToYou += friend.totalDebt;
                  if (friend.totalDebt > 0) activeDebts++;
                } else if (friend.totalDebt < 0) {
                  totalYouOwe += friend.totalDebt.abs();
                  if (friend.totalDebt < 0) activeDebts++;
                } else {
                  settledDebts++;
                }
              }

              // Get recent activity
              final recentTransactions = transactions
                  .where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'They Owe You',
                            '₱${totalOwedToYou.toStringAsFixed(2)}',
                            Icons.arrow_upward,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'You Owe Them',
                            '₱${totalYouOwe.toStringAsFixed(2)}',
                            Icons.arrow_downward,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Statistics
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistics',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Divider(),
                            _buildStatRow('Active Debts', activeDebts.toString()),
                            _buildStatRow('Settled Debts', settledDebts.toString()),
                            _buildStatRow('Total Friends', friends.length.toString()),
                            _buildStatRow(
                              'Net Balance',
                              '₱${(totalOwedToYou - totalYouOwe).toStringAsFixed(2)}',
                              color: totalOwedToYou > totalYouOwe ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recent Activity
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Activity',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Divider(),
                            if (recentTransactions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No recent activity'),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recentTransactions.take(5).length,
                                itemBuilder: (context, index) {
                                  final transaction = recentTransactions[index];
                                  final friend = friendsBox.get(transaction.friendId);
                                  final isDebt = transaction.type == TransactionType.debt;
                                  
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isDebt ? Colors.red : Colors.green,
                                      radius: 16,
                                      child: Icon(
                                        isDebt ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    title: Text(
                                      friend?.name ?? 'Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      DateFormat('MMM d, y').format(transaction.date),
                                    ),
                                    trailing: Text(
                                      '₱${transaction.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isDebt ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 