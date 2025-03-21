import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'friend.g.dart';

@HiveType(typeId: 0)
class Friend extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double totalDebt;

  @HiveField(3)
  String? phoneNumber;

  @HiveField(4)
  String? email;

  Friend({
    String? id,
    required this.name,
    this.totalDebt = 0.0,
    this.phoneNumber,
    this.email,
  }) : id = id ?? const Uuid().v4();

  void updateTotalDebt(double amount) {
    totalDebt += amount;
    save();
  }
} 