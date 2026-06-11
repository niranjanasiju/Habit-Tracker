import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/binary_habit.dart';
import '../models/numeric_habit.dart';
import '../widgets/binary_habit_card.dart';
import '../widgets/numeric_habit_card.dart';
import 'add_habit_screen.dart';

class HabitListScreen extends StatelessWidget {
  const HabitListScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Habits'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your habits...'),
                ],
              ),
            );
          }
          
          if (provider.habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: Colors.grey[600]),
                  SizedBox(height: 16),
                  Text(
                    'No habits yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first habit',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () => provider.loadAllData(),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.habits.length,
              itemBuilder: (context, index) {
                final habit = provider.habits[index];
                final currentValue = provider.getTodayCompletionValue(habit.id!);
                
                // Dismissible enables swipe-to-delete
                return Dismissible(
                  key: Key(habit.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete "${habit.name}"?'),
                        content: Text(
                          'Are you sure? This will permanently delete this habit and all its history.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    provider.deleteHabit(habit.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${habit.name} deleted'),
                        backgroundColor: Colors.red.shade900,
                      ),
                    );
                  },
                  child: habit is BinaryHabit
                      ? BinaryHabitCard(
                          habit: habit,
                          currentValue: currentValue,
                          onToggle: () => provider.toggleBinaryHabit(habit),
                        )
                      : NumericHabitCard(
                          habit: habit as NumericHabit,
                          currentValue: currentValue,
                          onIncrement: () => provider.incrementNumericHabit(habit as NumericHabit),
                          onDecrement: () => provider.decrementNumericHabit(habit as NumericHabit),
                        ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddHabitScreen()),
          ).then((_) {
            final provider = Provider.of<HabitProvider>(context, listen: false);
            provider.loadAllData();
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
  
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Habit Tracker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Binary habits: Yes/No tracking'),
            SizedBox(height: 8),
            Text('• Numeric habits: Track quantities'),
            SizedBox(height: 8),
            Text('• Tap checkboxes to complete habits'),
            SizedBox(height: 8),
            Text('• Swipe left on a habit to delete it'),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              'Data is saved locally on your device',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}