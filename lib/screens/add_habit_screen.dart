import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/binary_habit.dart';
import '../models/numeric_habit.dart';
import '../models/habit_type.dart';

class AddHabitScreen extends StatefulWidget {
  final dynamic existingHabit; // If provided, we're editing; if null, we're adding
  
  const AddHabitScreen({Key? key, this.existingHabit}) : super(key: key);
  
  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _questionController;
  late TextEditingController _unitController;
  late TextEditingController _targetController;
  late TextEditingController _notesController;
  
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Selected values
  late HabitType _habitType;
  late Frequency _frequency;
  late TargetType _targetType;
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;
  late Color _selectedColor;
  
  bool get isEditing => widget.existingHabit != null;
  
  @override
  void initState() {
    super.initState();
    
    if (isEditing) {
      // EDIT MODE: Load existing habit data
      final habit = widget.existingHabit;
      _nameController = TextEditingController(text: habit.name);
      _questionController = TextEditingController(text: habit.question);
      _notesController = TextEditingController(text: habit.notes ?? '');
      _habitType = habit.habitType;
      _frequency = habit.frequency;
      _reminderEnabled = habit.reminderEnabled;
      _reminderTime = habit.reminderTime != null 
          ? TimeOfDay.fromDateTime(habit.reminderTime!)
          : TimeOfDay(hour: 7, minute: 0);
      _selectedColor = Color(habit.colorValue);
      
      if (habit is NumericHabit) {
        _unitController = TextEditingController(text: habit.unit);
        _targetController = TextEditingController(text: habit.targetValue.toString());
        _targetType = habit.targetType;
      } else {
        _unitController = TextEditingController();
        _targetController = TextEditingController();
        _targetType = TargetType.atLeast;
      }
    } else {
      // ADD MODE: Default values
      _nameController = TextEditingController();
      _questionController = TextEditingController();
      _unitController = TextEditingController();
      _targetController = TextEditingController();
      _notesController = TextEditingController();
      _habitType = HabitType.binary;
      _frequency = Frequency.daily;
      _targetType = TargetType.atLeast;
      _reminderEnabled = false;
      _reminderTime = TimeOfDay(hour: 7, minute: 0);
      _selectedColor = Colors.teal;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          TextButton(
            onPressed: _saveHabit,
            child: Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Habit Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Habit Name *',
                hintText: 'e.g., Meditation, Workout, Reading',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a habit name';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // Question
            TextFormField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Question *',
                hintText: 'e.g., Did you meditate today?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a question';
                }
                return null;
              },
            ),
            
            SizedBox(height: 24),
            
            // Habit Type Selector
            Text(
              'Habit Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    HabitType.binary,
                    'Yes/No',
                    Icons.check_box,
                    'Track if you did something or not',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    HabitType.numeric,
                    'Measurable',
                    Icons.show_chart,
                    'Track quantities like water, steps, hours',
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Numeric-specific fields (conditional)
            if (_habitType == HabitType.numeric) ...[
              _buildNumericFields(),
              SizedBox(height: 24),
            ],
            
            // Frequency
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Frequency'),
              subtitle: Text('How often you want to track this habit'),
              trailing: DropdownButton<Frequency>(
                value: _frequency,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _frequency = value);
                  }
                },
                items: Frequency.values.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(freq.displayName),
                  );
                }).toList(),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Reminder
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Enable Reminder'),
              subtitle: Text('Get notified to complete this habit'),
              value: _reminderEnabled,
              onChanged: (value) {
                setState(() => _reminderEnabled = value);
              },
            ),
            
            if (_reminderEnabled) ...[
              SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Reminder Time'),
                trailing: TextButton(
                  onPressed: _selectReminderTime,
                  child: Text(
                    _reminderTime.format(context),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 16),
            
            // Color Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Color'),
              subtitle: Text('Choose a color for this habit'),
              trailing: GestureDetector(
                onTap: _selectColor,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Notes (optional)
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add motivation, tips, or reminders',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_add),
              ),
              maxLines: 3,
            ),

            SizedBox(height: 24),

            // Save and Cancel buttons
            ElevatedButton(
              onPressed: _saveHabit,
              child: Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: _selectedColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
            ),

            SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                side: BorderSide(color: Colors.grey.shade700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTypeCard(HabitType type, String title, IconData icon, String description) {
    final isSelected = _habitType == type;
    return GestureDetector(
      onTap: () => setState(() => _habitType = type),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _selectedColor.withOpacity(0.1) : Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _selectedColor : Colors.grey[800]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? _selectedColor : Colors.grey),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? _selectedColor : Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNumericFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numeric Habit Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        
        // Unit
        TextFormField(
          controller: _unitController,
          decoration: InputDecoration(
            labelText: 'Unit *',
            hintText: 'e.g., glasses, minutes, kilometers',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.straighten),
          ),
          validator: (value) {
            if (_habitType == HabitType.numeric && (value == null || value.isEmpty)) {
              return 'Please enter a unit';
            }
            return null;
          },
        ),
        
        SizedBox(height: 12),
        
        // Target Value
        TextFormField(
          controller: _targetController,
          decoration: InputDecoration(
            labelText: 'Target Value *',
            hintText: 'e.g., 8, 30, 10000',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.flag),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (_habitType == HabitType.numeric && (value == null || value.isEmpty)) {
              return 'Please enter a target value';
            }
            if (value != null && int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        
        SizedBox(height: 12),
        
        // Target Type
        Text('Target Type', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTargetTypeCard(TargetType.atLeast, 'At least', '≥ target'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildTargetTypeCard(TargetType.atMost, 'At most', '≤ target'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildTargetTypeCard(TargetType.exact, 'Exactly', '= target'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTargetTypeCard(TargetType type, String title, String description) {
    final isSelected = _targetType == type;
    return GestureDetector(
      onTap: () => setState(() => _targetType = type),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _selectedColor.withOpacity(0.1) : Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _selectedColor : Colors.grey[800]!,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? _selectedColor : Colors.white,
              ),
            ),
            Text(
              description,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }
  
  Future<void> _selectColor() async {
    Color? pickedColor = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => _selectedColor = color,
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedColor),
            child: Text('Select'),
          ),
        ],
      ),
    );
    
    if (pickedColor != null) {
      setState(() => _selectedColor = pickedColor);
    }
  }
  
  void _saveHabit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final now = DateTime.now();
    
    if (_habitType == HabitType.binary) {
      final habit = BinaryHabit(
        id: isEditing ? widget.existingHabit.id : null, // Keep existing ID if editing
        name: _nameController.text,
        question: _questionController.text,
        frequency: _frequency,
        reminderEnabled: _reminderEnabled,
        reminderTime: _reminderEnabled 
            ? DateTime(now.year, now.month, now.day, _reminderTime.hour, _reminderTime.minute)
            : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: isEditing ? widget.existingHabit.createdAt : now,
        colorValue: _selectedColor.value,
      );
      
      final provider = Provider.of<HabitProvider>(context, listen: false);
      
      if (isEditing) {
        provider.updateHabit(habit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Habit updated!')),
        );
      } else {
        provider.addHabit(habit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Habit created!')),
        );
      }
    } else {
      final targetValue = int.parse(_targetController.text);
      
      final habit = NumericHabit(
        id: isEditing ? widget.existingHabit.id : null,
        name: _nameController.text,
        question: _questionController.text,
        frequency: _frequency,
        unit: _unitController.text,
        targetValue: targetValue,
        targetType: _targetType,
        reminderEnabled: _reminderEnabled,
        reminderTime: _reminderEnabled 
            ? DateTime(now.year, now.month, now.day, _reminderTime.hour, _reminderTime.minute)
            : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: isEditing ? widget.existingHabit.createdAt : now,
        colorValue: _selectedColor.value,
      );
      
      final provider = Provider.of<HabitProvider>(context, listen: false);
      
      if (isEditing) {
        provider.updateHabit(habit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Habit updated!')),
        );
      } else {
        provider.addHabit(habit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Habit created!')),
        );
      }
    }
    
    Navigator.pop(context);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _questionController.dispose();
    _unitController.dispose();
    _targetController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}