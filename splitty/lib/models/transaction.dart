import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  debt,
  @HiveField(1)
  payment
}

@HiveType(typeId: 2)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String friendId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final TransactionType type;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  bool isArchived;

  @HiveField(7)
  final bool youOweThemMode;

  @HiveField(8)
  DateTime? archivedAt;

  Transaction({
    String? id,
    required this.friendId,
    required this.amount,
    required this.type,
    this.description,
    DateTime? date,
    this.isArchived = false,
    this.youOweThemMode = false,
    this.archivedAt,
  }) : this.id = id ?? const Uuid().v4(),
       this.date = date ?? DateTime.now();

  void archive() {
    isArchived = true;
    archivedAt = DateTime.now();
    save();
  }

  void unarchive() {
    isArchived = false;
    archivedAt = null;
    save();
  }
} 