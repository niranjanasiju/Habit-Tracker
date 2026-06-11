import 'habit.dart';
import 'habit_type.dart';

class NumericHabit extends Habit {
  final String unit;           
  final int targetValue;       
  final TargetType targetType;

  NumericHabit({
    super.id,
    required super.name,
    required super.question,
    required super.frequency,
    required this.unit,
    required this.targetValue,
    required this.targetType,
    super.reminderEnabled = false,
    super.reminderTime,
    super.notes,
    required super.createdAt,
    super.colorValue,
  });

  @override
  HabitType get habitType => HabitType.numeric;
  
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
      'unit': unit,
      'targetValue': targetValue,
      'targetType': targetType.index,
    };
  }

  bool isTargetMet(int value) {
    switch (targetType) {
      case TargetType.atLeast:
        return value >= targetValue;
      case TargetType.atMost:
        return value <= targetValue;
      case TargetType.exact:
        return value == targetValue;
    }
  }

  double getProgressPercentage(int currentValue) {
    switch (targetType) {
      case TargetType.atLeast:
        return (currentValue / targetValue).clamp(0.0, 1.0);
      case TargetType.atMost:
        return (targetValue - currentValue) / targetValue;
      case TargetType.exact:
        return currentValue == targetValue ? 1.0 : 0.0;
    }
  }

  @override
  String toString() {
    return 'NumericHabit(name: $name, target: $targetValue $unit, frequency: ${frequency.displayName})';
  }
}