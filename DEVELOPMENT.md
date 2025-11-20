# Developer Setup Guide

## Prerequisites

### Required
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
- [Android Studio](https://developer.android.com/studio) (for Android development)
- [Xcode](https://developer.apple.com/xcode/) (for iOS/macOS development - **Mac only**)
- [Git](https://git-scm.com/downloads)

### Optional but Recommended
- [VS Code](https://code.visualstudio.com/) with Flutter/Dart extensions

---

## Initial Setup

### 1. Clone the Repository
```bash
# Clone the repository
git clone <your-repo-url>
cd dotlottie_flutter
```

### 2. Install Dependencies
```bash
# Install Flutter dependencies for the plugin
flutter pub get

# Navigate to the example app
cd example

# Install example app dependencies
flutter pub get
```

---

## Platform-Specific Setup

### Android Setup

#### Prerequisites
- Android Studio installed with Android SDK
- Android emulator or physical device with USB debugging enabled

#### Steps
```bash
# From the example directory
cd example

# Check for connected devices/emulators
flutter devices

# If no devices found, start an Android emulator from Android Studio
# Or connect a physical Android device

# Run the app
flutter run
```

#### First-Time Android Setup

1. Open **Android Studio**
2. Go to **Tools → Device Manager** (or **AVD Manager** in older versions)
3. Create an emulator if you don't have one
4. Start the emulator
5. Run `flutter run` from the terminal

---

### iOS/macOS Setup (Mac Only)

#### Prerequisites
- Xcode installed (from Mac App Store)
- Xcode Command Line Tools installed
- CocoaPods installed

#### Install CocoaPods (if needed)
```bash
sudo gem install cocoapods
```

#### iOS Setup Steps
```bash
# From the example directory
cd example/ios

# Install CocoaPods dependencies
pod install

# Go back to example directory
cd ..

# Run on iOS simulator
flutter run -d ios
```

#### First-Time Xcode Setup

1. **Open the workspace in Xcode:**
```bash
   cd example/ios
   open Runner.xcworkspace  # Important: open .xcworkspace, NOT .xcodeproj
```

2. **Configure signing:**
   - In Xcode, select the **Runner** project in the left sidebar
   - Go to **Signing & Capabilities** tab
   - Select your development team (or add your Apple ID under Xcode → Settings → Accounts)

3. **Build and run:**
   - Select a simulator or connected device from the dropdown
   - Click the **Play** button (▶) or press **Cmd+R** to build

4. **Return to terminal:**
   - After the first successful Xcode build, you can use `flutter run` from the terminal

#### macOS Setup Steps
```bash
# From the example directory
cd example/macos

# Open in Xcode
open Runner.xcworkspace

# Follow the same signing steps as iOS
# Then run from terminal:
cd ..
flutter run -d macos
```

---

## Common Issues & Solutions

### iOS/macOS Issues

#### "No development team selected"
**Solution:**
1. Open the project in Xcode
2. Go to **Runner → Signing & Capabilities**
3. Select your team or add your Apple ID in **Xcode → Settings → Accounts**

#### "CocoaPods not installed"
**Solution:**
```bash
sudo gem install cocoapods
```

#### "Pod install failed"
**Solution:**
```bash
cd example/ios
pod deintegrate
pod install
```

#### "The sandbox is not in sync with the Podfile.lock"
**Solution:**
```bash
cd example/ios
pod install --repo-update
```

### Android Issues

#### "Android build fails with Gradle errors"
**Solution:**
```bash
cd example/android
./gradlew clean
cd ../..
flutter clean
flutter pub get
cd example
flutter pub get
```

#### "SDK location not found"
**Solution:**
1. Create `local.properties` in `example/android/`:
```properties
   sdk.dir=/Users/YOUR_USERNAME/Library/Android/sdk
```
2. Replace `YOUR_USERNAME` with your actual username

### General Issues

#### "Plugin not found" or "MissingPluginException"
**Solution:**
1. Make sure you're in the `example` directory when running
2. Check that `example/pubspec.yaml` has:
```yaml
   dependencies:
     dotlottie_flutter:
       path: ../
```
3. Run:
```bash
   flutter clean
   flutter pub get
   cd example
   flutter clean
   flutter pub get
```

#### "Version solving failed" or dependency conflicts
**Solution:**
```bash
flutter clean
rm pubspec.lock
flutter pub get
cd example
rm pubspec.lock
flutter pub get
```

---

## Verification

After setup, verify everything works:
```bash
# From the example directory
cd example

# Check Flutter setup
flutter doctor

# Check available devices
flutter devices

# Run the example app
flutter run
```

You should see output like:
```
Multiple devices found:
sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64 • Android 13 (API 33)
iPhone 15 Pro (mobile)      • ABC123...     • ios           • com.apple.CoreSimulator...
```

---

## Quick Reference Commands

### Clean Everything
```bash
# From project root
flutter clean
cd example
flutter clean
cd ..
flutter pub get
cd example
flutter pub get
```

### Run on Specific Platform
```bash
flutter run -d android
flutter run -d ios
flutter run -d macos
```

### View Logs
```bash
# Flutter logs (all platforms)
flutter logs

# Android-specific logs
adb logcat | grep -i dotlottie
```

### List Available Devices
```bash
flutter devices
```

---

## Next Steps

Once setup is complete:
1. ✅ Run `flutter doctor` to verify your environment
2. ✅ Run `flutter devices` to see available devices
3. ✅ Run `flutter run` in the `example` directory
4. ✅ Check the [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines

---

## Getting Help

If you encounter issues not covered here:
- Check the [Flutter documentation](https://flutter.dev/docs)
- Run `flutter doctor -v` for detailed diagnostics
- Review [GitHub Issues](your-repo-issues-url)
- Contact the team