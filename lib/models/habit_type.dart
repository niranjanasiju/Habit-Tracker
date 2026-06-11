enum HabitType {
  binary,   
  numeric,  
}

enum Frequency {
  daily,
  weekly,
  monthly;
  
  
  String get displayName {
    switch (this) {
      case Frequency.daily:
        return 'Every day';
      case Frequency.weekly:
        return 'Weekly';
      case Frequency.monthly:
        return 'Monthly';
    }
  }
}

enum TargetType {
  atLeast,    
  atMost,     
  exact;      
  
  String get displayName {
    switch (this) {
      case TargetType.atLeast:
        return 'At least';
      case TargetType.atMost:
        return 'At most';
      case TargetType.exact:
        return 'Exactly';
    }
  }
}