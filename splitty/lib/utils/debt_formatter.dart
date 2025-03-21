import '../models/friend.dart';
import '../models/transaction.dart';

class DebtFormatter {
  static String formatDebtRelationship({
    required Friend friend,
    required double amount,
    String? currentUserName = 'you',
  }) {
    if (amount == 0) {
      return 'No debt with ${friend.name}';
    }
    
    if (amount > 0) {
      return '${friend.name} owes ${currentUserName ?? 'you'} ₱${amount.abs().toStringAsFixed(2)}';
    } else {
      return '${currentUserName ?? 'You'} owe ${friend.name} ₱${amount.abs().toStringAsFixed(2)}';
    }
  }

  static String formatTransactionRelationship({
    required Transaction transaction,
    required Friend friend,
    String? currentUserName = 'you',
  }) {
    if (transaction.type == TransactionType.debt) {
      return '${friend.name} borrowed ₱${transaction.amount.toStringAsFixed(2)} from ${currentUserName ?? 'you'}';
    } else {
      return '${friend.name} paid ₱${transaction.amount.toStringAsFixed(2)} to ${currentUserName ?? 'you'}';
    }
  }

  static String getDebtSummary(List<Friend> friends) {
    int debtors = 0;
    int creditors = 0;
    double totalOwed = 0;
    double totalOwing = 0;

    for (final friend in friends) {
      if (friend.totalDebt > 0) {
        debtors++;
        totalOwed += friend.totalDebt;
      } else if (friend.totalDebt < 0) {
        creditors++;
        totalOwing += friend.totalDebt.abs();
      }
    }

    return 'You are owed ₱${totalOwed.toStringAsFixed(2)} by $debtors people\n'
           'You owe ₱${totalOwing.toStringAsFixed(2)} to $creditors people';
  }
} 