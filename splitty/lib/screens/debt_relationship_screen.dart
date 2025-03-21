import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/friend.dart';
import '../utils/debt_formatter.dart';

class DebtRelationshipScreen extends StatelessWidget {
  const DebtRelationshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debt Relationships'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'They Owe You'),
              Tab(text: 'You Owe Them'),
              Tab(text: 'No Debt'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Summary Card
            ValueListenableBuilder(
              valueListenable: Hive.box<Friend>('friends').listenable(),
              builder: (context, box, _) {
                final friends = box.values.toList();
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Overall Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DebtFormatter.getDebtSummary(friends),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Debt Lists
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Friend>('friends').listenable(),
                builder: (context, box, _) {
                  final friends = box.values.toList();
                  final theyOweYou = friends.where((f) => f.totalDebt > 0).toList()
                    ..sort((a, b) => b.totalDebt.compareTo(a.totalDebt));
                  final youOweThem = friends.where((f) => f.totalDebt < 0).toList()
                    ..sort((a, b) => a.totalDebt.compareTo(b.totalDebt));
                  final noDebt = friends.where((f) => f.totalDebt == 0).toList()
                    ..sort((a, b) => a.name.compareTo(b.name));

                  return TabBarView(
                    children: [
                      _buildDebtList(theyOweYou, true),
                      _buildDebtList(youOweThem, false),
                      _buildDebtList(noDebt, null),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtList(List<Friend> friends, bool? isOwedToYou) {
    if (friends.isEmpty) {
      return Center(
        child: Text(
          isOwedToYou == null
              ? 'No friends without debt'
              : isOwedToYou
                  ? 'No one owes you money'
                  : 'You don\'t owe anyone',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOwedToYou == null
                  ? Colors.grey
                  : isOwedToYou
                      ? Colors.green
                      : Colors.red,
              child: Icon(
                isOwedToYou == null
                    ? Icons.check
                    : isOwedToYou
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                color: Colors.white,
              ),
            ),
            title: Text(friend.name),
            subtitle: Text(
              DebtFormatter.formatDebtRelationship(
                friend: friend,
                amount: friend.totalDebt,
              ),
            ),
            trailing: friend.totalDebt != 0
                ? Text(
                    '₱${friend.totalDebt.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isOwedToYou ?? false ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
} 