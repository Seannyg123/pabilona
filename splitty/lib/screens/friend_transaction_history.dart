import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/friend.dart';
import '../models/transaction.dart';
import '../utils/debt_formatter.dart';
import '../widgets/add_transaction_dialog.dart';

class FriendTransactionHistory extends StatelessWidget {
  final Friend friend;

  const FriendTransactionHistory({
    super.key,
    required this.friend,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${friend.name}\'s History'),
      ),
      body: Column(
        children: [
          // Summary Card
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    DebtFormatter.formatDebtRelationship(
                      friend: friend,
                      amount: friend.totalDebt,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (friend.phoneNumber != null || friend.email != null)
                    const Divider(height: 24),
                  if (friend.phoneNumber != null)
                    Text('Phone: ${friend.phoneNumber}'),
                  if (friend.email != null)
                    Text('Email: ${friend.email}'),
                ],
              ),
            ),
          ),
          // Transaction List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Transaction>('transactions').listenable(),
              builder: (context, box, _) {
                final transactions = box.values
                    .where((t) => t.friendId == friend.id)
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('No transactions yet'),
                  );
                }

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isDebt = transaction.type == TransactionType.debt;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDebt ? Colors.red : Colors.green,
                          child: Icon(
                            isDebt
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          DebtFormatter.formatTransactionRelationship(
                            transaction: transaction,
                            friend: friend,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (transaction.description?.isNotEmpty ?? false)
                              Text(transaction.description!),
                            Text(
                              DateFormat('MMM d, y \'at\' h:mm a')
                                  .format(transaction.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: Text(
                          '₱${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isDebt ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        isThreeLine: transaction.description?.isNotEmpty ?? false,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop();
          showDialog(
            context: context,
            builder: (context) => AddTransactionDialog(friend: friend),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 