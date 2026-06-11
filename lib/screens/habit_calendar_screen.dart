// lib/screens/habit_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/numeric_habit.dart';
import '../providers/habit_provider.dart';

class HabitCalendarScreen extends StatefulWidget {
  final Habit habit;
  
  const HabitCalendarScreen({
    Key? key,
    required this.habit,
  }) : super(key: key);
  
  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  Map<DateTime, int> _completionsMap = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCompletions();
  }
  
  Future<void> _loadCompletions() async {
    setState(() => _isLoading = true);
    
    // Load completions for the last 6 months to 6 months ahead
    final startDate = DateTime(_focusedMonth.year - 1, _focusedMonth.month, 1);
    final endDate = DateTime(_focusedMonth.year + 1, _focusedMonth.month, 0);
    
    final provider = Provider.of<HabitProvider>(context, listen: false);
    final completions = await provider.getCompletionsInRange(widget.habit.id!, startDate, endDate);
    
    setState(() {
      _completionsMap = completions;
      _isLoading = false;
    });
  }
  
  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
      _loadCompletions();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.habit.name),
            Text(
              'Calendar View',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime.now();
                _loadCompletions();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month navigation
                _buildMonthNavigation(),
                
                // Month stats summary
                _buildMonthStats(),
                
                SizedBox(height: 16),
                
                // Calendar grid
                Expanded(
                  child: _buildCalendarGrid(),
                ),
                
                // Legend
                _buildLegend(),
              ],
            ),
    );
  }
  
  Widget _buildMonthNavigation() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
            iconSize: 32,
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedMonth),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
            iconSize: 32,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthStats() {
    final now = DateTime.now();
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    
    int completedCount = 0;
    int totalDays = 0;
    
    for (var day = firstDay; day.isBefore(lastDay) || day.isAtSameMomentAs(lastDay); day = day.add(Duration(days: 1))) {
      if (day.isAfter(now)) break;
      totalDays++;
      
      final completion = _completionsMap[DateTime(day.year, day.month, day.day)];
      if (completion != null && completion > 0) {
        if (widget.habit is NumericHabit) {
          final numericHabit = widget.habit as NumericHabit;
          if (numericHabit.isTargetMet(completion)) {
            completedCount++;
          }
        } else {
          completedCount++;
        }
      }
    }
    
    final completionRate = totalDays > 0 ? (completedCount / totalDays * 100).toInt() : 0;
    
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'This Month',
            value: '$completionRate%',
            subtitle: '$completedCount / $totalDays days',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[800],
          ),
          _buildStatItem(
            label: 'Best Streak',
            value: '${_getBestStreakInMonth()}',
            subtitle: 'consecutive days',
          ),
        ],
      ),
    );
  }
  
  int _getBestStreakInMonth() {
    int currentStreak = 0;
    int bestStreak = 0;
    
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    
    for (var day = firstDay; day.isBefore(lastDay); day = day.add(Duration(days: 1))) {
      final completion = _completionsMap[DateTime(day.year, day.month, day.day)];
      bool isCompleted = false;
      
      if (completion != null && completion > 0) {
        if (widget.habit is NumericHabit) {
          isCompleted = (widget.habit as NumericHabit).isTargetMet(completion);
        } else {
          isCompleted = true;
        }
      }
      
      if (isCompleted) {
        currentStreak++;
        bestStreak = bestStreak > currentStreak ? bestStreak : currentStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    return bestStreak;
  }
  
  Widget _buildStatItem({
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // Monday=1, Sunday=7
    
    // Calculate days to show from previous month
    final leadingDays = firstWeekday - 1;
    
    // Get first day to display (might be from previous month)
    final firstDisplayDay = firstDayOfMonth.subtract(Duration(days: leadingDays));
    
    // Build 6 weeks of days (42 days total)
    List<DateTime> days = [];
    for (int i = 0; i < 42; i++) {
      days.add(firstDisplayDay.add(Duration(days: i)));
    }
    
    // Split into weeks
    List<List<DateTime>> weeks = [];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }
    
    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 8),
        
        // Calendar grid
        Expanded(
          child: Column(
            children: weeks.map((week) {
              return Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: week.map((date) {
                    return Expanded(
                      child: _buildCalendarDay(date),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCalendarDay(DateTime date) {
    final isCurrentMonth = date.month == _focusedMonth.month;
    final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
    
    final completion = _completionsMap[DateTime(date.year, date.month, date.day)];
    bool isCompleted = false;
    int? value;
    
    if (completion != null && completion > 0) {
      value = completion;
      if (widget.habit is NumericHabit) {
        isCompleted = (widget.habit as NumericHabit).isTargetMet(completion);
      } else {
        isCompleted = true;
      }
    }
    
    // Calculate color intensity based on completion
    Color? backgroundColor;
    if (isCompleted) {
      final intensity = 0.7; // Full intensity for completed
      backgroundColor = Color(widget.habit.colorValue).withOpacity(intensity);
    } else if (value != null && value > 0 && widget.habit is NumericHabit) {
      // Partial completion for numeric habits
      final numericHabit = widget.habit as NumericHabit;
      final progress = numericHabit.getProgressPercentage(value);
      if (progress > 0) {
        backgroundColor = Color(widget.habit.colorValue).withOpacity(progress * 0.5);
      }
    }
    
    return GestureDetector(
      onTap: () {
        _showDayDetails(date, value);
      },
      child: Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor ?? (isCurrentMonth ? Colors.grey[850] : Colors.grey[900]),
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: Color(widget.habit.colorValue), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                color: isCurrentMonth ? Colors.white : Colors.grey[600],
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (value != null && widget.habit is NumericHabit)
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            if (isCompleted && widget.habit is NumericHabit)
              Icon(Icons.check_circle, size: 12, color: Colors.green),
          ],
        ),
      ),
    );
  }
  
  void _showDayDetails(DateTime date, int? value) {
    final isCompleted = value != null && value > 0;
    String status;
    
    if (!isCompleted) {
      status = 'Not completed';
    } else if (widget.habit is NumericHabit) {
      final numericHabit = widget.habit as NumericHabit;
      status = 'Completed: $value / ${numericHabit.targetValue} ${numericHabit.unit}';
      if (numericHabit.isTargetMet(value!)) {
        status += ' ✓ Target met!';
      }
    } else {
      status = 'Completed ✓';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('EEEE, MMMM d, yyyy').format(date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.habit.question),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? Color(widget.habit.colorValue) : Colors.grey,
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text(status)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegend() {
    if (widget.habit is! NumericHabit) {
      return SizedBox.shrink(); 
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 12, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text('Less', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 12, color: Colors.grey[600]),
          SizedBox(width: 8),
          Icon(Icons.circle, size: 16, color: Color(widget.habit.colorValue).withOpacity(0.3)),
          SizedBox(width: 4),
          Icon(Icons.circle, size: 20, color: Color(widget.habit.colorValue).withOpacity(0.6)),
          SizedBox(width: 4),
          Icon(Icons.circle, size: 24, color: Color(widget.habit.colorValue)),
          SizedBox(width: 8),
          Text('More', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}