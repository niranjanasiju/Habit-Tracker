// lib/widgets/binary_habit_card.dart - UPDATED with stats
import '../screens/habit_calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/binary_habit.dart';
import '../providers/habit_provider.dart';
import 'stats_card.dart';
import '../screens/add_habit_screen.dart';

class BinaryHabitCard extends StatelessWidget {
  final BinaryHabit habit;
  final int currentValue;
  final VoidCallback onToggle;
  
  const BinaryHabitCard({
    Key? key,
    required this.habit,
    required this.currentValue,
    required this.onToggle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isCompleted = currentValue == 1;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[850],
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted 
                          ? Color(habit.colorValue).withOpacity(0.2)
                          : Colors.grey[800],
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isCompleted 
                          ? Color(habit.colorValue)
                          : Colors.grey[600],
                      size: 32,
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Habit details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey[400] : Colors.white,
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
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: [
                            // Frequency
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
                            // Reminder time
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
                            // Completed badge
                            if (isCompleted)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(habit.colorValue).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'COMPLETED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(habit.colorValue),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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
            ),
          ),
          
          // Stats Section
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FutureBuilder(
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
          ),
        ],
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