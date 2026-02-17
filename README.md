# Kashly — Smart Cashbook App

A beautiful, feature-rich cashbook management app built with Flutter and Material Design 3. Track your income and expenses with automatic Google Drive cloud backup.

---

## ✨ Features

### 📒 Cashbook Management
- Create unlimited cashbooks (Personal, Business, Travel, etc.)
- Real-time balance tracking across all books
- Color-coded Cash In / Cash Out entries
- Net balance summary dashboard
- Search, sort, and filter cashbooks

### 💸 Transaction Tracking
- Add Cash In and Cash Out entries
- Date & time picker per entry
- Category tagging (10 defaults + custom)
- Payment method tagging (Cash, UPI, Card, etc.)
- Optional remarks/notes per entry
- Running balance per transaction
- Grouped by date (Today / Yesterday / date)

### ✏️ Edit Entry with Full History
- **Pencil button in the Entry Detail header** opens edit form
- All edits tracked: what field changed, from what value, to what value
- Edit history displayed in Entry Detail screen, newest first
- Edit indicator (pencil icon) on transaction cards
- Changes trigger automatic backup

### 🔍 Search & Filter
- Search transactions within a cashbook
- Search cashbooks by name
- Sort by balance (positive/negative first), or alphabetically

### ☁️ Google Drive Backup (Cloud)
- Sign in with Google (minimal scope: `drive.appdata`)
- Backups stored in your private Google Drive app folder
- **Never shared — only you can access them**
- Data exported as JSON, encrypted, uploaded as `.db.enc` file
- Keeps the latest 5 backups automatically
- File naming: `KASHLY_backup_v{timestamp}.db.enc`
- Manual "Backup Now" button
- Restore from any of the 5 saved backups

### ⚡ Auto-Backup System
- **Event-triggered**: backup starts 20 seconds after any data change
- Debounced: multiple rapid changes reset the timer
- Exponential backoff retry on network failure
- Toggle Auto Backup on/off in Settings
- Background safety backup every 24 hours (configurable)

### 🔔 Backup Status Indicators
| State | Icon | Meaning |
|-------|------|---------|
| Synced | ☁️✓ green | All data backed up |
| Syncing | ☁️ spinning | Upload in progress |
| Pending | ☁️• dot | Changes waiting to upload |
| Error | ☁️⚠ red | Backup paused, will retry |
| Never | ☁️↑ grey | Not connected / never backed up |

- Status text: "Last backup 3m ago", "Changes pending…", "Syncing…"
- "Saving…" pill shown after adding/editing entries
- Calm error banner: "Backup paused — will retry when connection is available."

### ⚙️ Settings
- Google Drive connection (sign in / disconnect)
- Connected account email display
- Last backup timestamp & file size
- Backup history (last 5 entries with restore buttons)
- Auto Backup toggle
- Manual Backup Now button
- Restore from Backup button
- Currency preference
- Date format preference
- Notifications toggle
- Biometric Lock toggle
- Import / Export data
- About & Privacy Policy

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry, DataStore + BackupService init
├── logic/
│   ├── cashbook_logic.dart      # Business logic, edit history generation
│   └── data_store.dart          # SharedPreferences persistence, JSON export/import
├── models/
│   ├── cashbook.dart            # CashBook model
│   └── transaction.dart         # Transaction + EditLog + FieldChange models
├── services/
│   └── backup_service.dart      # Google Drive backup/restore, encryption, debounce
├── state/
│   └── backup_state.dart        # InheritedWidget UI state, bridges BackupService
├── screens/
│   ├── home_screen.dart         # Cashbook list, summary banner
│   ├── cashbook_detail_screen.dart  # Transaction list, dual FAB
│   ├── add_entry_screen.dart    # Add new transaction
│   ├── edit_entry_screen.dart   # ✨ NEW: Edit transaction with history tracking
│   ├── entry_detail_screen.dart # ✨ UPDATED: Edit button, full edit history display
│   ├── cashbook_options_screen.dart # Manage categories & payment methods
│   └── settings_screen.dart    # ✨ UPDATED: Full Google Drive backup UI
└── widgets/
    ├── backup_status_icon.dart  # Cloud icon with states, backup sheet
    ├── balance_summary_card.dart
    ├── cashbook_card.dart
    └── transaction_card.dart    # ✨ Shows edit indicator on edited entries
```

---

## 🚀 Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project (or use existing)
3. Enable **Google Drive API**
4. Go to **APIs & Services → OAuth consent screen**
   - Choose "External" user type
   - Fill in App Name, email, etc.
   - Add scope: `https://www.googleapis.com/auth/drive.appdata`
5. Go to **APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID**
   - For Android: Choose "Android", enter your package name (`com.yourcompany.kashly`) and SHA-1 fingerprint
   - For iOS: Choose "iOS", enter bundle ID

### 3. Android Setup (`android/app/build.gradle`)

```gradle
defaultConfig {
    applicationId "com.yourcompany.kashly"
    minSdkVersion 21
    // ...
}
```

Add your `google-services.json` (from Firebase) OR use the SHA-1 from:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 4. iOS Setup

Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### 5. Run the App

```bash
flutter run
```

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `shared_preferences` | Local data persistence |
| `google_sign_in` | Google OAuth authentication |
| `googleapis` | Google Drive API v3 |
| `http` | HTTP client for Drive auth |
| `path_provider` | File system paths |

---

## 🔐 Security Notes

- Backups use the `drive.appdata` scope — hidden, private folder
- No other apps can see your backup files
- Backup data is XOR-encrypted before upload
- **For production**: Replace XOR with AES-256 encryption (e.g., using `pointycastle` package)
- Google tokens are managed securely by the `google_sign_in` package

---

## 🗺️ Roadmap

- [ ] AES-256 encryption for backups
- [ ] PDF / CSV export
- [ ] Multiple currency support
- [ ] Biometric lock implementation
- [ ] Category spending charts
- [ ] Budget goals per category
- [ ] Multi-device sync

---

## 📄 License

Private / proprietary. All rights reserved.
