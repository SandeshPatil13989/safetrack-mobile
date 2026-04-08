# SafeTrack — Mobile App 📱

![SafeTrack](https://img.shields.io/badge/SafeTrack-v1.0.0-brightgreen)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Firebase](https://img.shields.io/badge/Firebase-Realtime%20DB-orange)
![Android](https://img.shields.io/badge/Android-5.0%2B-green)
![License](https://img.shields.io/badge/License-MIT-green)

Real-Time Location Tracking Android App with Intelligent Emergency Alerts

🌐 **Web Dashboard:** https://safetrack-web-999.vercel.app

📲 **Download APK:** [SafeTrack v1.0.0](https://github.com/SandeshPatil13989/safetrack-mobile/releases/tag/v1.0.0)

---

## ✨ Features

- 📍 **Live GPS Tracking** — bestForNavigation accuracy (±5m to ±15m outdoors)
- 🚨 **SOS Emergency Alert** — 3-second countdown prevents accidental triggers
- 🔴 **Geofence Zones** — Create zones and detect inside/outside breaches
- 🗺️ **Live Map** — OpenStreetMap with real-time route trail
- 📊 **Live Stats** — Current speed, accuracy, and point count
- 👤 **User Profile** — Manage name, email, phone number
- 📜 **Location History** — Last 100 GPS points stored automatically
- 🔐 **Persistent Login** — Stay logged in after closing app
- ⚡ **Auto GPS Filter** — Readings > 50m accuracy automatically skipped

---

## 📲 Installation (Direct APK)

1. Download `app-release.apk` from [Releases](https://github.com/SandeshPatil13989/safetrack-mobile/releases/tag/v1.0.0)
2. On your Android phone go to **Settings → Security**
3. Enable **"Install from unknown sources"**
4. Open the downloaded APK
5. Tap **Install**
6. Open **SafeTrack** and register

---

## 🛠️ Tech Stack

| Technology | Version | Purpose |
|---|---|---|
| Flutter | 3.x | Mobile framework |
| Dart | 3.x | Programming language |
| firebase_auth | Latest | User authentication |
| firebase_database | Latest | Real-time data sync |
| geolocator | Latest | GPS location tracking |
| flutter_map | Latest | OpenStreetMap integration |
| latlong2 | Latest | Coordinate handling |
| flutter_background_service | 5.1.0 | Background tracking |

---

## 🚀 Getting Started (Development)

### Prerequisites
- Flutter SDK 3.x
- Android Studio
- Android SDK (API 21+)
- Firebase project

### Installation

```bash
# Clone the repository
git clone https://github.com/SandeshPatil13989/safetrack-mobile.git

# Navigate to project
cd safetrack-mobile

# Install dependencies
flutter pub get
```

### Firebase Setup

1. Create a Firebase project
2. Add Android app with package name: `com.example.safetrack_mobile`
3. Download `google-services.json`
4. Place it in `android/app/`
5. Run FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### Running the App

```bash
# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📁 Project Structure

```
safetrack_mobile/
├── android/
│   └── app/
│       ├── src/main/AndroidManifest.xml   # Permissions
│       └── google-services.json           # Firebase config
├── lib/
│   ├── main.dart                          # App entry point + auth wrapper
│   ├── firebase_options.dart              # Firebase options
│   └── screens/
│       ├── login_screen.dart              # Login/Register
│       ├── home_screen.dart               # Main screen + SOS button
│       ├── map_screen.dart                # GPS tracking + map
│       ├── history_screen.dart            # Location history
│       ├── geofence_screen.dart           # Geofence management
│       ├── profile_screen.dart            # User profile
│       └── register_screen.dart          # Registration
├── pubspec.yaml                           # Dependencies
└── README.md
```

---

## 🔑 Required Permissions

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
```

---

## 📊 GPS Accuracy

| Condition | Accuracy |
|---|---|
| Outdoors open sky | ±5m to ±15m ✅ |
| Near buildings | ±15m to ±30m |
| Indoors | ±20m to ±50m |
| Poor readings | Auto filtered ✅ |

---

## 🔥 Firebase Data Structure

```
locations/{uid}/
├── current/
│   ├── latitude        # Current GPS latitude
│   ├── longitude       # Current GPS longitude
│   ├── speed           # Speed in m/s
│   ├── accuracy        # GPS accuracy in meters
│   └── timestamp       # ISO 8601 timestamp
└── history/
    └── {pushId}/       # Last 100 location points

sos/{uid}/
├── active              # true/false
├── timestamp           # Alert time
└── userName            # User's name

geofences/{uid}/
└── {fenceId}/
    ├── name            # Zone name
    ├── latitude        # Zone center
    ├── longitude       # Zone center
    └── radius          # Zone radius in meters

users/{uid}/
├── name                # Full name
├── email               # Email address
└── phone               # Phone number
```

---

## 📱 How to Use

### Setup (First Time)
1. Install APK on phone
2. Open SafeTrack
3. Register with email and password
4. Allow location permissions

### Live Tracking
1. Open SafeTrack on phone
2. Tap **"Start Live Tracking"**
3. Open web dashboard: https://safetrack-web-999.vercel.app
4. Login with monitor account
5. See live location on map!

### SOS Emergency
1. **Long press** the red SOS button
2. 3-second countdown appears
3. Tap **Cancel** to abort
4. Alert fires automatically after countdown
5. Web dashboard shows alert with alarm sound

### Geofence
1. Go to **Geofence** tab
2. Tap **"Add Zone"**
3. Enter zone name and radius
4. Tap on map to set location
5. Web dashboard shows inside/outside status

---

## 🔗 Related Repository

🌐 **Web Dashboard:** https://github.com/SandeshPatil13989/safetrack-web

---

## 📋 Requirements

- Android 5.0 (API Level 21) or higher
- GPS hardware
- Internet connection
- Location permissions granted

---

## 👨‍💻 Developer

**Sandesh(Roshan) Patil**
- 🎓 B.E. Computer Science and Engineering
- 🏫 Jain College of Engineering, Belagavi
- 🎓 Visvesvaraya Technological University (VTU)

---

## 📄 License

This project is licensed under the MIT License.