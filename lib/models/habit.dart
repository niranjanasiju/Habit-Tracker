import 'habit_type.dart';

abstract class Habit {
  final int? id;
  final String name;
  final String question;
  final Frequency frequency;
  final bool reminderEnabled;
  final DateTime? reminderTime;
  final String? notes;
  final DateTime createdAt;
  final int colorValue;

  Habit({
    this.id,
    required this.name,
    required this.question,
    required this.frequency,
    this.reminderEnabled = false,
    this.reminderTime,
    this.notes,
    required this.createdAt,
    this.colorValue = 0xFF009688,
  });

  Map<String, dynamic> toMap();

  HabitType get habitType;
}