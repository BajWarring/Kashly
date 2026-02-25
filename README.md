# Kashly — Professional Cashbook & Transaction Manager

A Flutter application for professional cashbook and transaction management with advanced backup, sync, and audit controls.

---

## Features

### Core
- **Cashbooks** – Create, manage, archive multiple cashbooks with multi-currency support
- **Transactions** – Cash-in/out entries with categories, remarks, methods, split support
- **Running Balance** – Real-time running balance per cashbook with infinite scroll

### Backup & Sync
- **Google Drive Integration** – Per-entry and full-DB backup to Drive
- **Incremental Backup** – Only syncs changed/new entries
- **Conflict Resolution** – Detect and resolve Drive vs local conflicts
- **Backup Center** – Central UI for pending uploads, history, and conflict queue
- **Backup History** – Timeline of all backups with status
- **Reports** – PDF and CSV backup manifests

### Security
- **Encrypted local database** (SQLite with encryption support)
- **Optional backup encryption** with password
- **Biometric restore protection**
- **Google OAuth** for Drive access with account switching

### Professional Features
- Dashboard with cashflow charts
- Audit history per transaction
- Sync status icons throughout the app
- Retry with exponential backoff
- Background sync via WorkManager
- PDF reports and CSV exports
- Settings for fine-grained backup control

---

## Architecture

```
lib/
├── core/
│   ├── di/providers.dart          # Riverpod DI container
│   ├── error/                     # Exceptions & Failures
│   ├── router/app_router.dart     # GoRouter with bottom nav shell
│   ├── theme/app_theme.dart       # Dark/light Material 3 themes
│   └── utils/                     # Icons, formatting utils
├── data/
│   ├── datasources/               # SQLite (LocalDatasource)
│   └── repositories/              # Repository implementations
├── domain/
│   ├── entities/                  # Freezed models
│   ├── repositories/              # Abstract repository interfaces
│   └── usecases/                  # Use case classes
├── features/
│   ├── auth/                      # Google Sign-In
│   ├── backup_center/             # Central backup management UI
│   ├── cashbooks/                 # List + Detail pages
│   ├── dashboard/                 # Analytics dashboard
│   ├── settings/                  # App settings
│   └── transactions/              # Entry form + Detail page
├── reports/                       # PDF/CSV generators
├── services/
│   ├── backup/                    # BackupService (Drive upload logic)
│   ├── notification/              # Local notifications
│   └── sync_engine/               # SyncService (triggers & retry)
├── ux_and_ui_elements/
│   └── dialogs.dart               # Reusable dialogs/modals
└── main.dart
```

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.3.0
- Android SDK / Xcode
- Google Cloud project with Drive API enabled

### Setup
```bash
# Install dependencies
flutter pub get

# Generate Freezed code
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run
```

### Google OAuth Setup
1. Create a project at [console.cloud.google.com](https://console.cloud.google.com)
2. Enable the **Google Drive API**
3. Create OAuth 2.0 credentials
4. Replace the `clientId` in `lib/features/auth/auth_provider.dart`
5. For Android, add `google-services.json` and configure SHA-1

---

## Running Tests

```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# All tests
flutter test
```

---

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `sqflite` | Local database |
| `googleapis` | Google Drive API |
| `google_sign_in` | Authentication |
| `workmanager` | Background tasks |
| `freezed_annotation` | Immutable models |
| `fl_chart` | Dashboard charts |
| `pdf` | PDF report generation |
| `csv` | CSV export |
| `flutter_secure_storage` | Secure key storage |
| `flutter_local_notifications` | Push notifications |

---

## Sync Engine Flow

```
New Transaction
    │
    ▼
Local DB (SQLite) ──► sync_status: pending
    │
    ▼
SyncService.triggerSync(SyncTrigger.addEntry)
    │
    ▼
BackupService.incrementalBackup()
    │
    ├── Drive upload success ──► sync_status: synced, drive_meta updated
    └── Drive upload failure ──► sync_status: error, retry queue
```

---

## License

Private / Proprietary — Kashly © 2025
