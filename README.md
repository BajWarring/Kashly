# CashBook App - Material Design 3

A beautiful Flutter cashbook management app built with Material Design 3 (MD3) by Google.

## Features

✨ **Material Design 3 UI**
- Modern, clean interface following Google's latest design guidelines
- Dynamic color schemes (light & dark modes)
- Smooth animations and transitions

📚 **CashBook Management**
- View all your cashbooks at a glance
- Running balance display with positive/negative indicators
- Search functionality to quickly find cashbooks
- Filter options to organize your books

➕ **Easy Add/Edit**
- Floating Action Button for quick cashbook creation
- Intuitive dialog for adding new cashbooks

⚙️ **Settings**
- Dark mode toggle
- Notification preferences
- Profile management
- Backup & restore options

🧭 **Bottom Navigation**
- Easy switching between Home and Settings
- Material Design 3 NavigationBar component

## Project Structure

```
cashbook_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   └── cashbook.dart         # CashBook data model
│   ├── screens/
│   │   ├── home_screen.dart      # Home screen with cashbook list
│   │   └── settings_screen.dart  # Settings screen
│   └── widgets/
│       └── cashbook_card.dart    # Reusable cashbook card widget
└── pubspec.yaml                  # Dependencies
```

## How to Run

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter plugins

### Steps

1. **Extract/Download this folder to your machine**

2. **Open terminal in the project directory**

3. **Get dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

   Or choose a specific device:
   ```bash
   flutter devices          # List available devices
   flutter run -d chrome    # Run on Chrome
   flutter run -d android   # Run on Android
   flutter run -d ios       # Run on iOS
   ```

### Running Online

If you don't have Flutter installed locally, you can:

1. **Use FlutLab** (https://flutlab.io)
   - Create a new project
   - Copy all files from this project
   - Run in the online emulator

2. **Use DartPad** (https://dartpad.dev)
   - Note: DartPad has limitations and may not support all features
   - Best for testing individual widgets

## Customization

### Change Color Theme
Edit `main.dart` and modify the `seedColor`:
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.purple,  // Change this color
  brightness: Brightness.light,
),
```

### Add More CashBooks
Edit the sample data in `home_screen.dart`:
```dart
final List<CashBook> _cashbooks = [
  CashBook(
    id: '1',
    name: 'Your CashBook Name',
    balance: 1000.00,
    isPositive: true,
  ),
  // Add more...
];
```

## Material Design 3 Components Used

- **NavigationBar** - Bottom navigation with Material You design
- **Card** - Elevated cards for cashbook items
- **FAB (Floating Action Button)** - Extended FAB for adding cashbooks
- **AppBar** - Top app bar with actions
- **TextField** - Material text input fields
- **Dialog** - Alert dialogs and bottom sheets
- **Switch** - Material switches for settings
- **ListTile** - Standard list items

## Future Enhancements

- [ ] Add database integration (SQLite/Hive)
- [ ] Implement transaction history for each cashbook
- [ ] Add charts and analytics
- [ ] Export to PDF/Excel
- [ ] Cloud sync
- [ ] Multi-currency support
- [ ] Biometric authentication

## License

This is a sample project for demonstration purposes.

---

Made with ❤️ using Flutter & Material Design 3
