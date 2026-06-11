import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/habit.dart';
import '../models/binary_habit.dart';
import '../models/numeric_habit.dart';
import '../models/habit_completion.dart';

class HabitProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Habit> _habits = [];
  Map<int, Map<String, int>> _completionsCache = {}; // habitId -> { "2026-06-10": value }
  
  List<Habit> get habits => _habits;
  
  // Loading state
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  // ========== LOAD DATA ==========
  
  /// Load all habits and today's completions
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();  // Show loading indicator
    
    // Load habits from database
    _habits = await _db.getAllHabits();
    
    // Load today's completions for all habits
    await _loadTodayCompletions();
    
    _isLoading = false;
    notifyListeners();  // Rebuild UI with data
  }
  
  /// Load completions for TODAY only (for performance)
  Future<void> _loadTodayCompletions() async {
    final today = DateTime.now();
    
    for (var habit in _habits) {
      final completion = await _db.getCompletion(habit.id!, today);
      if (completion != null) {
        _setCompletionCache(habit.id!, today, completion.value);
      }
    }
  }
  
  // ========== COMPLETION METHODS ==========
  
  /// Get completion value for a habit on a specific date
  int getCompletionValue(int habitId, DateTime date) {
    final dateKey = _dateToString(date);
    return _completionsCache[habitId]?[dateKey] ?? 0;
  }
  
  /// Get today's completion value for a habit
  int getTodayCompletionValue(int habitId) {
    return getCompletionValue(habitId, DateTime.now());
  }
  
  /// Toggle a binary habit (0 <-> 1)
  Future<void> toggleBinaryHabit(BinaryHabit habit) async {
    final today = DateTime.now();
    final currentValue = getTodayCompletionValue(habit.id!);
    final newValue = currentValue == 0 ? 1 : 0;
    
    // Save to database
    final completion = HabitCompletion(
      habitId: habit.id!,
      date: today,
      value: newValue,
    );
    await _db.saveCompletion(completion);
    
    // Update cache
    if (newValue == 1) {
      _setCompletionCache(habit.id!, today, 1);
    } else {
      _removeCompletionCache(habit.id!, today);
    }
    clearStatsCache();
    // Notify UI to rebuild
    notifyListeners();
  }
  
  /// Update a numeric habit (increment/decrement or set value)
  Future<void> updateNumericHabit(NumericHabit habit, int newValue) async {
    final today = DateTime.now();
    
    // Ensure value isn't negative
    newValue = newValue.clamp(0, 999);
    
    // Save to database
    final completion = HabitCompletion(
      habitId: habit.id!,
      date: today,
      value: newValue,
    );
    await _db.saveCompletion(completion);
    
    // Update cache
    if (newValue > 0) {
      _setCompletionCache(habit.id!, today, newValue);
    } else {
      _removeCompletionCache(habit.id!, today);
    }
    clearStatsCache();
    // Notify UI to rebuild
    notifyListeners();
  }
  
  /// Increment numeric habit by 1
  Future<void> incrementNumericHabit(NumericHabit habit) async {
    final currentValue = getTodayCompletionValue(habit.id!);
    await updateNumericHabit(habit, currentValue + 1);
  }
  
  /// Decrement numeric habit by 1
  Future<void> decrementNumericHabit(NumericHabit habit) async {
    final currentValue = getTodayCompletionValue(habit.id!);
    await updateNumericHabit(habit, currentValue - 1);
  }
  
  // ========== HABIT CRUD ==========
  
  /// Add a new habit
  Future<void> addHabit(Habit habit) async {
    final id = await _db.insertHabit(habit);
    
    // Refresh the list
    await loadAllData();
    clearStatsCache();
    // Notify UI
    notifyListeners();
  }
  
  /// Delete a habit
  Future<void> deleteHabit(int id) async {
    await _db.deleteHabit(id);
    await loadAllData();
    clearStatsCache();
    notifyListeners();
  }
  
  // ========== CACHE HELPERS ==========
  
  void _setCompletionCache(int habitId, DateTime date, int value) {
    final dateKey = _dateToString(date);
    _completionsCache[habitId] ??= {};
    _completionsCache[habitId]![dateKey] = value;
  }
  
  void _removeCompletionCache(int habitId, DateTime date) {
    final dateKey = _dateToString(date);
    _completionsCache[habitId]?.remove(dateKey);
    
    // Clean up empty maps
    if (_completionsCache[habitId]?.isEmpty == true) {
      _completionsCache.remove(habitId);
    }
  }
  
  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  final Map<int, int> _currentStreakCache = {};
  final Map<int, int> _longestStreakCache = {};
  final Map<int, double> _completionRateCache = {};
  
  /// Get current streak for a habit (with caching)
  Future<int> getCurrentStreak(int habitId) async {
    if (_currentStreakCache.containsKey(habitId)) {
      return _currentStreakCache[habitId]!;
    }
    final streak = await _db.calculateCurrentStreak(habitId);
    _currentStreakCache[habitId] = streak;
    return streak;
  }
  
  /// Get longest streak for a habit (with caching)
  Future<int> getLongestStreak(int habitId) async {
    if (_longestStreakCache.containsKey(habitId)) {
      return _longestStreakCache[habitId]!;
    }
    final streak = await _db.calculateLongestStreak(habitId);
    _longestStreakCache[habitId] = streak;
    return streak;
  }
  
  /// Get completion rate for a habit (with caching)
  Future<double> getCompletionRate(int habitId) async {
    if (_completionRateCache.containsKey(habitId)) {
      return _completionRateCache[habitId]!;
    }
    final rate = await _db.calculateCompletionRate(habitId);
    _completionRateCache[habitId] = rate;
    return rate;
  }
  
  /// Clear all caches (call when data changes)
  void clearStatsCache() {
    _currentStreakCache.clear();
    _longestStreakCache.clear();
    _completionRateCache.clear();
  }

  Future<Map<DateTime, int>> getCompletionsInRange(int habitId, DateTime start, DateTime end) async {
    final completions = await _db.getCompletionsInRange(habitId, start, end);
    
    Map<DateTime, int> result = {};
    for (var completion in completions) {
      final dateKey = DateTime(completion.date.year, completion.date.month, completion.date.day);
      result[dateKey] = completion.value;
    }
    return result;
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    await _db.updateHabit(updatedHabit);
    clearStatsCache();
    await loadAllData(); 
    notifyListeners();
  }
}