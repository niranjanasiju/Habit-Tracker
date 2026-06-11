// lib/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';
import '../models/binary_habit.dart';
import '../models/numeric_habit.dart';
import '../models/habit_completion.dart';
import '../models/habit_type.dart';

class DatabaseHelper {
  // Singleton pattern - only ONE instance of this class exists
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  
  static Database? _database;
  
  // Get the database (creates it if it doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'loop_habits.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,  // For future updates
    );
  }
  
  // Called when database is first created
  Future<void> _onCreate(Database db, int version) async {
    print('📦 Creating database tables...');
    
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        question TEXT NOT NULL,
        type INTEGER NOT NULL,
        frequency INTEGER NOT NULL,
        reminderEnabled INTEGER NOT NULL,
        reminderTime TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        -- Numeric habit specific fields (NULL for binary habits)
        unit TEXT,
        targetValue INTEGER,
        targetType INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE completions (
        habitId INTEGER NOT NULL,
        date TEXT NOT NULL,
        value INTEGER NOT NULL,
        PRIMARY KEY (habitId, date),
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
    
    print('✅ Database tables created!');
  }
  
  // Called when app updates and database version changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from $oldVersion to $newVersion');
    // We'll handle migrations here in future chunks
  }
  
  // ========== HABIT OPERATIONS ==========
  
  /// Insert a new habit (can be Binary or Numeric)
  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    final map = habit.toMap();
    // Remove id if it's null (let database auto-assign)
    map.removeWhere((key, value) => value == null);
    
    final id = await db.insert('habits', map);
    print('➕ Inserted habit: ${habit.name} (ID: $id)');
    return id;
  }
  
  /// Get ALL habits (returns List of Habit objects - both types!)
  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habits',
      orderBy: 'createdAt DESC',  // Newest first
    );
    
    return maps.map((map) => _habitFromMap(map)).toList();
  }
  
  /// Get a single habit by ID
  Future<Habit?> getHabitById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return _habitFromMap(maps.first);
  }
  
  /// Update an existing habit
  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    final map = habit.toMap();
    final id = map['id'];
    map.remove('id');  // Don't try to update the ID column
    
    final count = await db.update(
      'habits',
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    print('✏️ Updated habit: ${habit.name}');
    return count;
  }
  
  /// Delete a habit (and all its completions due to CASCADE)
  Future<int> deleteHabit(int id) async {
    final db = await database;
    final count = await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    print('🗑️ Deleted habit with ID: $id');
    return count;
  }
  
  // ========== COMPLETION OPERATIONS ==========
  
  /// Save or update a completion for a habit on a specific date
  Future<void> saveCompletion(HabitCompletion completion) async {
    final db = await database;
    final map = completion.toMap();
    
    // Insert or replace (if exists)
    await db.insert(
      'completions',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print('💾 Saved completion: Habit ${completion.habitId} on ${_dateToStorageString(completion.date)} = ${completion.value}');
  }
  
  /// Get completion for a specific habit on a specific date
  Future<HabitCompletion?> getCompletion(int habitId, DateTime date) async {
    final db = await database;
    final dateStr = _dateToStorageString(date);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'completions',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, dateStr],
    );
    
    if (maps.isEmpty) return null;
    
    return HabitCompletion(
      habitId: maps.first['habitId'],
      date: _dateFromStorageString(maps.first['date']),
      value: maps.first['value'],
    );
  }
  
  /// Get all completions for a habit (for statistics)
  Future<List<HabitCompletion>> getCompletionsForHabit(int habitId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'completions',
      where: 'habitId = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    
    return maps.map((map) => HabitCompletion(
      habitId: map['habitId'],
      date: _dateFromStorageString(map['date']),
      value: map['value'],
    )).toList();
  }
  
  /// Get completions for a date range (for calendar view)
  Future<List<HabitCompletion>> getCompletionsInRange(
    int habitId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr = _dateToStorageString(start);
    final endStr = _dateToStorageString(end);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'completions',
      where: 'habitId = ? AND date BETWEEN ? AND ?',
      whereArgs: [habitId, startStr, endStr],
    );
    
    return maps.map((map) => HabitCompletion(
      habitId: map['habitId'],
      date: _dateFromStorageString(map['date']),
      value: map['value'],
    )).toList();
  }
  
  /// Delete a completion
  Future<int> deleteCompletion(int habitId, DateTime date) async {
    final db = await database;
    final dateStr = _dateToStorageString(date);
    
    return await db.delete(
      'completions',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, dateStr],
    );
  }
  
  // ========== HELPER METHODS ==========
  
  /// Convert database row to Habit object (handles polymorphism!)
  Habit _habitFromMap(Map<String, dynamic> map) {
    final type = HabitType.values[map['type']];
    final frequency = Frequency.values[map['frequency']];
    
    switch (type) {
      case HabitType.binary:
        return BinaryHabit(
          id: map['id'],
          name: map['name'],
          question: map['question'],
          frequency: frequency,
          reminderEnabled: map['reminderEnabled'] == 1,
          reminderTime: map['reminderTime'] != null 
              ? DateTime.parse(map['reminderTime']) 
              : null,
          notes: map['notes'],
          createdAt: DateTime.parse(map['createdAt']),
          colorValue: map['colorValue'],
        );
        
      case HabitType.numeric:
        return NumericHabit(
          id: map['id'],
          name: map['name'],
          question: map['question'],
          frequency: frequency,
          unit: map['unit'] ?? 'times',  // Fallback if null
          targetValue: map['targetValue'] ?? 1,
          targetType: TargetType.values[map['targetType'] ?? 0],
          reminderEnabled: map['reminderEnabled'] == 1,
          reminderTime: map['reminderTime'] != null 
              ? DateTime.parse(map['reminderTime']) 
              : null,
          notes: map['notes'],
          createdAt: DateTime.parse(map['createdAt']),
          colorValue: map['colorValue'],
        );
    }
  }
  
  /// Convert DateTime to storage string (YYYY-MM-DD)
  String _dateToStorageString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Convert storage string back to DateTime
  DateTime _dateFromStorageString(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  
  Future<int> calculateCurrentStreak(int habitId) async {
    final db = await database;
    final today = DateTime.now();
    var streak = 0;
    var checkDate = today;
    
    while (true) {
      final dateStr = _dateToStorageString(checkDate);
      
      final List<Map<String, dynamic>> result = await db.query(
        'completions',
        where: 'habitId = ? AND date = ?',
        whereArgs: [habitId, dateStr],
      );
      
      if (result.isEmpty) {
        break; // Missed a day, streak breaks
      }
      
      // Check if the completion meets the habit's target
      final habit = await getHabitById(habitId);
      if (habit != null) {
        final isCompleted = await _isCompletionSuccessful(habit, result.first['value']);
        if (!isCompleted) break;
      }
      
      streak++;
      checkDate = checkDate.subtract(Duration(days: 1));
    }
    
    return streak;
  }
  
  Future<int> calculateLongestStreak(int habitId) async {
    final completions = await getCompletionsForHabit(habitId);
    if (completions.isEmpty) return 0;
    
    // Sort by date (oldest first for easier calculation)
    completions.sort((a, b) => a.date.compareTo(b.date));
    
    var longestStreak = 0;
    var currentStreak = 0;
    DateTime? previousDate;
    
    for (var completion in completions) {
      final habit = await getHabitById(habitId);
      if (habit == null) continue;
      
      final isCompleted = await _isCompletionSuccessful(habit, completion.value);
      if (!isCompleted) {
        currentStreak = 0;
        previousDate = null;
        continue;
      }
      
      if (previousDate == null) {
        // First completion
        currentStreak = 1;
      } else {
        // Check if dates are consecutive
        final dayDifference = completion.date.difference(previousDate).inDays;
        if (dayDifference == 1) {
          currentStreak++;
        } else if (dayDifference > 1) {
          currentStreak = 1; // Reset streak, gap in days
        }
      }
      
      longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
      previousDate = completion.date;
    }
    
    return longestStreak;
  }
  
  Future<double> calculateCompletionRate(int habitId, {int days = 30}) async {
    final db = await database;
    final habit = await getHabitById(habitId);
    if (habit == null) return 0.0;

    final today = DateTime.now();
    final habitCreatedDate = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final earliestDate = today.subtract(Duration(days: days - 1));
    final startDate = habitCreatedDate.isAfter(earliestDate) ? habitCreatedDate : earliestDate;

    var completedDays = 0;
    var totalDays = 0;

    for (var checkDate = startDate;
        !checkDate.isAfter(today);
        checkDate = checkDate.add(Duration(days: 1))) {
      final dateStr = _dateToStorageString(checkDate);
      final List<Map<String, dynamic>> result = await db.query(
        'completions',
        where: 'habitId = ? AND date = ?',
        whereArgs: [habitId, dateStr],
      );

      totalDays++;

      if (result.isNotEmpty) {
        final isCompleted = await _isCompletionSuccessful(habit, result.first['value']);
        if (isCompleted) completedDays++;
      }
    }

    return totalDays > 0 ? completedDays / totalDays : 0.0;
  }
  
  Future<bool> _isCompletionSuccessful(Habit habit, int value) async {
    if (habit is BinaryHabit) {
      return value == 1;
    } else if (habit is NumericHabit) {
      return habit.isTargetMet(value);
    }
    return false;
  }



  // TEMPORARY - for testing streaks
  Future<void> addTestCompletion(int habitId, DateTime date, int value) async {
    final completion = HabitCompletion(
      habitId: habitId,
      date: date,
      value: value,
    );
    await saveCompletion(completion);
  }
}