# Loop Habit Tracker 🎯

A sleek, offline-first Flutter application designed to build and track daily habits. Supports both binary (Yes/No) habits and numeric (target-based) habits with built-in analytics, streak calculations, and calendar visualizers.

---

## ✨ Features

- **Binary & Numeric Habit Support**
  - **Binary Habits**: Simple Yes/No tracking (e.g., Read a book, Meditate).
  - **Numeric Habits**: Track quantitative goals with custom target values and units (e.g., Drink 2000 ml of water, Walk 10,000 steps).
  - Flexible target criteria: *At least*, *At most*, or *Exact*.
- **Streak & Analytics Engine**
  - Live calculations for **Current Streak**, **Longest Streak**, and **Completion Rate**.
  - Performance caching to ensure smooth scrolling and responsive UI.
- **Interactive Calendar View**
  - Monthly heat-map-style calendar visualizing historical progress.
  - Custom color intensity based on completion rates.
  - Detailed daily breakdown modals.
- **Customization & Dark Mode**
  - Built with Material 3 dark theme.
  - Per-habit color picker support.
  - Reminder times and custom habit notes.
- **Offline & Local First**
  - Powered by local SQLite database with automatic cascading deletes and fast query indexing.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK ^3.9.2)
- **State Management**: [Provider](https://pub.dev/packages/provider) (`ChangeNotifier`)
- **Local Storage**: [sqflite](https://pub.dev/packages/sqflite) (SQLite database)
- **UI Components & Utilities**:
  - `table_calendar`: Interactive calendar UI
  - `flutter_colorpicker`: Custom color selection
  - `intl`: Date formatting and manipulation

---

## 📂 Project Structure

```
lib/
├── database/
│   └── database_helper.dart  # SQLite database initialization & queries
├── models/
│   ├── habit.dart             # Base abstract Habit model
│   ├── binary_habit.dart      # Binary habit implementation
│   ├── numeric_habit.dart     # Numeric habit implementation
│   ├── habit_completion.dart  # Daily completion entry model
│   └── habit_type.dart        # Enums for HabitType, Frequency, TargetType
├── providers/
│   └── habit_provider.dart    # App state management & stats caching
├── screens/
│   ├── habit_list_screen.dart # Main screen listing all habits
│   ├── add_habit_screen.dart  # Screen for creating & editing habits
│   └── habit_calendar_screen.dart # Detailed calendar & heatmap view
└── widgets/
    ├── binary_habit_card.dart # UI card for binary habits
    ├── numeric_habit_card.dart# UI card for numeric habits
    └── stats_card.dart        # Summary card for streaks & rates
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Version 3.9.2 or higher)
- Android Studio / Xcode / VS Code with Flutter extension

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/habit_tracker.git
   cd habit_tracker
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📊 Database Schema

- `habits`: Stores habit configuration (id, name, question, type, frequency, colorValue, unit, targetValue, targetType, etc.).
- `completions`: Stores daily logs (habitId, date, value) with cascade deletion on habit removal.

