import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/friend.dart';
import '../models/transaction.dart';
import '../utils/debt_formatter.dart';
import '../widgets/add_transaction_dialog.dart';

class DebtsListScreen extends StatefulWidget {
  const DebtsListScreen({super.key});

  @override
  State<DebtsListScreen> createState() => _DebtsListScreenState();
}

class _DebtsListScreenState extends State<DebtsListScreen> {
  String _searchQuery = '';
  String _groupBy = 'friend'; // 'friend', 'date', 'amount'
  bool _showSettled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts List'),
        actions: [
          IconButton(
            icon: Icon(
              _showSettled ? Icons.check_circle : Icons.check_circle_outline,
            ),
            onPressed: () {
              setState(() {
                _showSettled = !_showSettled;
              });
            },
            tooltip: 'Show Settled Debts',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _groupBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'friend',
                child: Text('Group by Friend'),
              ),
              const PopupMenuItem(
                value: 'date',
                child: Text('Group by Date'),
              ),
              const PopupMenuItem(
                value: 'amount',
                child: Text('Group by Amount'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search debts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Friend>('friends').listenable(),
              builder: (context, friendsBox, _) {
                var friends = friendsBox.values.toList();
                
                // Filter out settled debts if not showing them
                if (!_showSettled) {
                  friends = friends.where((f) => f.totalDebt != 0).toList();
                }

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  friends = friends.where((f) =>
                    f.name.toLowerCase().contains(_searchQuery) ||
                    f.totalDebt.toString().contains(_searchQuery)
                  ).toList();
                }

                // Sort based on grouping
                switch (_groupBy) {
                  case 'date':
                    // Sort by most recent transaction
                    final transactionsBox = Hive.box<Transaction>('transactions');
                    friends.sort((a, b) {
                      final aTransactions = transactionsBox.values
                          .where((t) => t.friendId == a.id)
                          .toList();
                      final bTransactions = transactionsBox.values
                          .where((t) => t.friendId == b.id)
                          .toList();
                      
                      final aLatest = aTransactions.isEmpty
                          ? DateTime(1900)
                          : aTransactions
                              .reduce((t1, t2) =>
                                t1.date.isAfter(t2.date) ? t1 : t2)
                              .date;
                      final bLatest = bTransactions.isEmpty
                          ? DateTime(1900)
                          : bTransactions
                              .reduce((t1, t2) =>
                                t1.date.isAfter(t2.date) ? t1 : t2)
                              .date;
                      
                      return bLatest.compareTo(aLatest);
                    });
                    break;
                  case 'amount':
                    friends.sort((a, b) =>
                        b.totalDebt.abs().compareTo(a.totalDebt.abs()));
                    break;
                  default: // 'friend'
                    friends.sort((a, b) => a.name.compareTo(b.name));
                }

                if (friends.isEmpty) {
                  return const Center(
                    child: Text('No debts found'),
                  );
                }

                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final hasDebt = friend.totalDebt != 0;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: hasDebt
                              ? (friend.totalDebt > 0
                                  ? Colors.green
                                  : Colors.red)
                              : Colors.grey,
                          child: Text(
                            friend.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(friend.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DebtFormatter.formatDebtRelationship(
                                friend: friend,
                                amount: friend.totalDebt,
                              ),
                            ),
                            ValueListenableBuilder(
                              valueListenable: Hive.box<Transaction>('transactions')
                                  .listenable(),
                              builder: (context, transactionsBox, _) {
                                final latestTransaction = transactionsBox.values
                                    .where((t) => t.friendId == friend.id)
                                    .toList()
                                  ..sort((a, b) => b.date.compareTo(a.date));
                                
                                if (latestTransaction.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Text(
                                  'Last activity: ${DateFormat('MMM d, y').format(latestTransaction.first.date)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  AddTransactionDialog(friend: friend),
                            );
                          },
                          tooltip: 'Add Transaction',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 