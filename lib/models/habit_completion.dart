class HabitCompletion {
  final int habitId;
  final DateTime date;
  final int value;

  HabitCompletion({
    required this.habitId,
    required this.date,
    required this.value,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'date': _dateToStorageString(date),
      'value': value,
    };
  }

  static String _dateToStorageString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime fromStorageString(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
  
  @override
  String toString() {
    return 'HabitCompletion(habitId: $habitId, date: ${_dateToStorageString(date)}, value: $value)';
  }
}