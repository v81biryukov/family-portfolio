# Family Portfolio - Flutter App

A cross-platform family investment portfolio app with Yandex.Disk cloud synchronization.

## Features

- **Track Investments**: Monitor all family assets in one place
- **Multi-Currency Support**: USD, EUR, RUB with automatic exchange rates
- **Visual Dashboard**: Charts and KPIs for portfolio overview
- **Cloud Sync**: Synchronize data across devices via Yandex.Disk
- **Secure**: PIN and biometric authentication (Face ID/Touch ID)
- **Offline First**: Works without internet, syncs when connected

## Platforms

- ✅ Android (APK)
- ✅ iPhone (Web App)
- ✅ Windows (Web App)
- ✅ macOS (Web App)

---

## Installation & Setup

### Prerequisites

1. **Install Flutter SDK** (if not already installed)
   - Download from: https://docs.flutter.dev/get-started/install
   - Follow the installation instructions for your operating system

2. **Verify Installation**
   ```bash
   flutter doctor
   ```
   - Fix any issues shown by `flutter doctor`

### Step 1: Get the App Code

1. Download the `family_portfolio_flutter` folder to your computer
2. Open a terminal/command prompt
3. Navigate to the app folder:
   ```bash
   cd path/to/family_portfolio_flutter
   ```

### Step 2: Install Dependencies

```bash
flutter pub get
```

This downloads all required packages (may take a few minutes).

### Step 3: Run the App

#### Option A: Run in Browser (Recommended for First Test)

```bash
flutter run -d chrome
```

Or for any available browser:
```bash
flutter run -d web-server --web-port=8080
```
Then open http://localhost:8080 in your browser.

#### Option B: Build for Android (APK)

```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

Install on your Android phone:
1. Transfer the APK to your phone
2. Tap to install (allow "Unknown Sources" if prompted)

#### Option C: Build for Web (iPhone/Windows/macOS)

```bash
flutter build web --release
```

The web app will be at: `build/web/`

To serve the web app locally:
```bash
cd build/web
python -m http.server 8080
```
Then open http://localhost:8080 in any browser.

---

## Yandex.Disk Setup (Cloud Sync)

To sync your portfolio across devices, you need to connect Yandex.Disk:

### Step 1: Create Yandex OAuth App

1. Go to: https://oauth.yandex.com/client/new
2. Sign in with your Yandex account
3. Fill in the form:
   - **Service name**: Family Portfolio
   - **Description**: Personal investment portfolio sync
   - **Platform**: Web services
   - **Callback URL**: `https://fiwimu3pemxgm.ok.kimi.link/auth/callback`
4. Click "Save"
5. Note down your **Client ID** and **Client Secret**

### Step 2: Configure the App

1. Open `lib/utils/constants.dart`
2. Replace the placeholder values:
   ```dart
   static const String yandexClientId = 'YOUR_ACTUAL_CLIENT_ID';
   static const String yandexClientSecret = 'YOUR_ACTUAL_CLIENT_SECRET';
   ```
3. Save the file
4. Rebuild the app:
   ```bash
   flutter build apk --release
   ```

### Step 3: Connect in the App

1. Open the app
2. Go to **Settings**
3. Tap **Connect Yandex.Disk**
4. Sign in to your Yandex account
5. Allow access to Family Portfolio
6. You're now synced!

---

## Using the App

### First Launch

1. **Set Up Security**: Create a 4-6 digit PIN
2. **Enable Biometric** (optional): Use Face ID or fingerprint
3. **Add Your First Asset**: Tap "Add Asset" button

### Adding an Asset

1. Tap **+ Add Asset** button
2. Fill in the details:
   - **Owner**: Who owns this asset (V, M, etc.)
   - **Asset Type**: Deposit, Cash, Bonds, Stocks, etc.
   - **Institution**: Bank or company name
   - **Country**: Where the asset is located
   - **Currency**: USD, EUR, RUB
   - **Amount**: Current value
   - **Interest Rate**: Annual rate (e.g., 0.05 for 5%)
3. Tap **Save**

### Viewing Your Portfolio

- **Dashboard**: Overview with charts and KPIs
- **Assets List**: See all assets with details
- **Exchange Rates**: View and update currency rates

### Syncing Across Devices

1. Make changes on any device
2. Tap the **Sync** button (cloud icon) or pull down to refresh
3. Your data syncs to Yandex.Disk
4. On another device, tap Sync to get the latest data

---

## Troubleshooting

### "Unable to find directory entry in pubspec.yaml"

This error is now fixed. If you see it:
1. Make sure the `assets/images/` folder exists
2. Run `flutter clean` then `flutter pub get`

### App Won't Build

1. Run Flutter doctor:
   ```bash
   flutter doctor
   ```
2. Fix any issues shown
3. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

### Sync Not Working

1. Check internet connection
2. Verify Yandex.Disk credentials in `constants.dart`
3. Try logging out and reconnecting in Settings

### Charts Not Showing

Make sure you have at least one asset added. Charts appear when there's data to display.

---

## File Structure

```
family_portfolio_flutter/
├── android/              # Android-specific files
├── assets/               # Images and static files
│   └── images/           # App images
├── lib/                  # Main source code
│   ├── main.dart         # App entry point
│   ├── models/           # Data models
│   │   ├── asset_model.dart
│   │   ├── exchange_rate_model.dart
│   │   └── settings_model.dart
│   ├── screens/          # UI screens
│   │   ├── dashboard_screen.dart
│   │   ├── assets_screen.dart
│   │   ├── add_asset_screen.dart
│   │   ├── settings_screen.dart
│   │   └── ...
│   ├── services/         # Business logic
│   │   ├── sync_service.dart
│   │   ├── yandex_disk_service.dart
│   │   └── auth_service.dart
│   ├── providers/        # State management
│   ├── router/           # Navigation
│   └── utils/            # Constants and helpers
├── web/                  # Web-specific files
├── pubspec.yaml          # Dependencies
└── README.md             # This file
```

---

## Building for Production

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Web App

```bash
flutter build web --release
```

Output: `build/web/`

Deploy to any web server or hosting service.

---

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review Flutter documentation: https://docs.flutter.dev
3. Check Yandex.Disk API docs: https://yandex.com/dev/disk/api/reference/

---

## License

This is a personal project for family use.
