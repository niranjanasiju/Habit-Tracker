import 'habit.dart';
import 'habit_type.dart';

class BinaryHabit extends Habit {
  BinaryHabit({
    super.id,
    required super.name,
    required super.question,
    required super.frequency,
    super.reminderEnabled = false,
    super.reminderTime,
    super.notes,
    required super.createdAt,
    super.colorValue,
  });

  @override
  HabitType get habitType => HabitType.binary;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'question': question,
      'type': habitType.index,  
      'frequency': frequency.index,
      'reminderEnabled': reminderEnabled ? 1 : 0,  
      'reminderTime': reminderTime?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'colorValue': colorValue,
      'unit': null,
      'targetValue': null,
      'targetType': null,
    };
  }

  @override
  String toString() {
    return 'BinaryHabit(name: $name, question: $question, frequency: ${frequency.displayName})';
  }
}