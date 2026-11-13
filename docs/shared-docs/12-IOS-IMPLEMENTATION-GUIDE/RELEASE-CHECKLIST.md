# Leaf Master iOS Implementation: App Store Release & Compliance Checklist

## 1. Executive Summary
This document provides the mandatory pre-flight checklist for preparing and submitting Leaf for native distribution on the Apple App Store. It ensures complete compliance with Apple App Store Review Guidelines, privacy manifest mandates, and TestFlight release gates.

---

## 2. Apple App Store Privacy Manifest (`PrivacyInfo.xcprivacy`)

Starting in iOS 17, Apple requires all applications to include an explicit `PrivacyInfo.xcprivacy` manifest declaring data usage and required reason APIs.

### 2.1 Privacy Nutrition Labels
- **Data Collection**: **None**. Leaf collects **zero** user data, tracks no personal information, and contains zero third-party analytics SDKs (no Firebase, no Mixpanel, no Facebook SDK).
- **Data Linked to User**: None.
- **Data Used to Track You**: None.

### 2.2 Required Reason APIs Declaration
Leaf accesses `UserDefaults` for storing non-sensitive user preferences. The manifest must declare:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPITypeUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string> <!-- Access user defaults inside app to read/write app-specific preferences -->
            </array>
        </dict>
    </array>
</dict>
</plist>
```

---

## 3. Mandatory `Info.plist` Permission Strings

Apple rejects apps with generic permission strings. Use these exact, transparent privacy disclosures:

| Key | Value / String | Rationale |
| :--- | :--- | :--- |
| `NSFaceIDUsageDescription` | *"Leaf uses Face ID to securely unlock your financial vault and protect your balance records."* | Required for `LocalAuthentication` biometric app lock. |
| `NSPhotoLibraryUsageDescription` | *"Leaf accesses your photo library only when you select a local avatar picture for your profile."* | Required if user selects local avatar photo. |
| `CADisableMinimumFrameDurationOnPhone` | `<true/>` | Enables smooth 120Hz ProMotion animations on supported iPhones. |

---

## 4. App Store Review Guidelines Compliance

1. **Section 2.5.2 (No Executable Code Sideloading)**:
   - The Android update mechanism (downloading APKs from GitHub) is strictly omitted. In-app checks on iOS link exclusively to the Apple App Store.
2. **Section 5.1.1 (Data Collection & Storage)**:
   - Leaf operates completely offline and requires no account registration, satisfying Apple's strongest user privacy standards.
3. **Section 2.1 (App Completeness)**:
   - Ensure placeholder buttons, mock links, or dead ends do not exist in the submission build.
   - All sample categories and demo calculators must function without network connectivity.

---

## 5. Pre-Submission Build & TestFlight Verification

- [ ] App compiles in Release configuration with zero compiler warnings under Swift 6 strict concurrency checking.
- [ ] App Icon includes all required sizes (1024×1024 App Store icon, iPhone home icons, Settings icons, Spotlight icons) without alpha transparency.
- [ ] Xcode Archive creates clean `.xcarchive` with symbols stripped for release.
- [ ] TestFlight build distributed to internal testers and verified across iPhone SE (compact), iPhone 15/16 Pro (Dynamic Island), and iPhone Pro Max (large display).
- [ ] Dark Mode and Light Mode appearance verified on real hardware devices.
- [ ] Face ID unlock tested with enrolled biometric, failed biometric, and passcode fallback.
- [ ] Memory footprint remains under 50 MB during continuous scrolling of 5,000 transactions.
- [ ] VoiceOver screen reader tested on primary navigation tabs and Hero Balance card.

