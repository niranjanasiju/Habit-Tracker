import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import 'stats_card.dart';
import 'package:flutter/material.dart';
import '../models/numeric_habit.dart';
import '../screens/habit_calendar_screen.dart';
import '../screens/add_habit_screen.dart';

class NumericHabitCard extends StatelessWidget {
  final NumericHabit habit;
  final int currentValue;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  
  const NumericHabitCard({
    Key? key,
    required this.habit,
    required this.currentValue,
    required this.onIncrement,
    required this.onDecrement,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final progress = habit.getProgressPercentage(currentValue);
    final isTargetMet = habit.isTargetMet(currentValue);
    final remaining = habit.targetValue - currentValue;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[850],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit name and question
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        habit.question,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Target status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTargetMet 
                        ? Color(habit.colorValue).withOpacity(0.2)
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isTargetMet ? "✓ TARGET MET" : "$remaining LEFT",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isTargetMet ? Color(habit.colorValue) : Colors.grey[400],
                    ),
                  ),
                ),
                // Calendar button
                IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HabitCalendarScreen(habit: habit),
                      ),
                    );
                  },
                ),
                // Edit button
                IconButton(
                    icon: Icon(Icons.edit, color: Colors.grey[600]),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddHabitScreen(existingHabit: habit),
                        ),
                      ).then((_) {
                        // Refresh after editing
                        Provider.of<HabitProvider>(context, listen: false).loadAllData();
                      });
                    },
                  ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(Color(habit.colorValue)),
              ),
            ),
            
            SizedBox(height: 12),
            
            // Progress text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Text(
                  '$currentValue / ${habit.targetValue} ${habit.unit}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Controls and metadata
            Row(
              children: [
                // Increment/Decrement buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.white),
                        onPressed: onDecrement,
                        constraints: BoxConstraints(minWidth: 40),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[700],
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.white),
                        onPressed: onIncrement,
                        constraints: BoxConstraints(minWidth: 40),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Frequency and reminder info
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            habit.frequency.displayName,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (habit.reminderEnabled) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.alarm, size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              _formatTime(habit.reminderTime!),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // In numeric_habit_card.dart, after the Row with buttons, add:

          SizedBox(height: 12),
          
          // Stats Section
          FutureBuilder(
            future: Future.wait([
              Provider.of<HabitProvider>(context, listen: false).getCurrentStreak(habit.id!),
              Provider.of<HabitProvider>(context, listen: false).getLongestStreak(habit.id!),
              Provider.of<HabitProvider>(context, listen: false).getCompletionRate(habit.id!),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final currentStreak = snapshot.data![0] as int;
              final longestStreak = snapshot.data![1] as int;
              final completionRate = snapshot.data![2] as double;
              
              return StatsCard(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                completionRate: completionRate,
                accentColor: Color(habit.colorValue),
              );
            },
          ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}