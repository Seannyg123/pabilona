import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/friend.dart';
import '../utils/debt_formatter.dart';
import '../widgets/add_friend_dialog.dart';
import '../widgets/add_transaction_dialog.dart';
import 'friend_transaction_history.dart';
import 'friend_details_screen.dart';

class FriendsManagementScreen extends StatelessWidget {
  const FriendsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends & Debts'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Friend>('friends').listenable(),
        builder: (context, friendsBox, _) {
          final friends = friendsBox.values.toList();
          
          if (friends.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No friends added yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFriendDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Friend'),
                  ),
                ],
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
                    backgroundColor: friend.totalDebt > 0 
                      ? Colors.green 
                      : friend.totalDebt < 0 
                        ? Colors.red 
                        : Colors.grey,
                    child: Text(
                      friend.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(friend.name),
                  subtitle: Text(
                    DebtFormatter.formatDebtRelationship(
                      friend: friend,
                      amount: friend.totalDebt,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _showAddTransactionDialog(context, friend),
                        tooltip: 'Add Transaction',
                      ),
                      IconButton(
                        icon: const Icon(Icons.history),
                        onPressed: () => _showTransactionHistory(context, friend),
                        tooltip: 'View History',
                      ),
                    ],
                  ),
                  onTap: () => _showFriendDetails(context, friend),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddFriendDialog(),
    );
  }

  void _showAddTransactionDialog(BuildContext context, Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(friend: friend),
    );
  }

  void _showTransactionHistory(BuildContext context, Friend friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendTransactionHistory(friend: friend),
      ),
    );
  }

  void _showFriendDetails(BuildContext context, Friend friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendDetailsScreen(friend: friend),
      ),
    );
  }
} 