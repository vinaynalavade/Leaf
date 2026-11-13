# FEATURE SPECIFICATION: FEAT-12 — SECURITY, APP LOCK & BIOMETRICS

## 1. Feature ID
`FEAT-12`

## 2. Feature Name
App Lock Security: Salted PIN Vault, Biometric Authentication & App Switcher Concealment

## 3. Purpose
Protects personal financial records from unauthorized physical access. Implements a secure salted PIN verification vault with temporary lockout throttling, native biometric authentication (Face ID / Touch ID / Fingerprint), configurable auto-lock timeouts, and app switcher privacy shielding.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with private security vault, lockout timer, biometric helper, window security flags, and lifecycle tests.

## 5. User-Facing Functionality
- **App Lock Setup Screen (`AppLockSetupScreen`)**:
  - Enter 4-digit PIN.
  - Confirm 4-digit PIN.
  - Enable Biometrics toggle (Face ID / Fingerprint).
  - Auto-Lock Duration selector: "Immediately", "After 15 seconds", "After 1 minute", "After 5 minutes".
  - "Hide Content in App Switcher" toggle.
- **Unlock Screen (`UnlockScreen`)**:
  - Presented immediately upon opening app if locked.
  - App Logo, "Unlock Leaf", PIN indicator dots.
  - Custom numeric keypad (1..9, Biometric trigger button, 0, Backspace).
  - Error messages with remaining attempts count.
  - Lockout countdown timer display when temporarily locked out ("Try again in 30 seconds").
- **Change PIN Screen (`ChangePinScreen`)**:
  - Step 1: Verify current PIN.
  - Step 2: Enter new PIN.
  - Step 3: Confirm new PIN.
- **Privacy Window Concealment**:
  - Masks app contents when switching apps or in multitasking recents view.

## 6. Entry Points
- Full-screen modal blocking UI upon app launch / resume when locked.
- Settings menu -> "Security & App Lock" (`Screen.AppLockSetup`).

## 7. Screen Structure
```text
UnlockScreen
├── BrandHeader (Leaf Logo, "Leaf", Subtitle "Enter your PIN")
├── PinIndicatorsRow (4 Circular Dots: Empty / Filled)
├── ErrorMessageText ("Incorrect PIN. 3 attempts remaining" / "Locked out for 25s")
└── NumericKeypad (3x4 Grid)
    ├── [1] [2] [3]
    ├── [4] [5] [6]
    ├── [7] [8] [9]
    └── [Biometric Button] [0] [Backspace]
```

## 8. UI Components
- `UnlockScreen`: Full-screen lock shield with BackHandler preventing task back navigation.
- `PinDot`: Circular indicator animating state (unfilled vs filled).
- `KeypadButton`: Circular haptic key.
- `SecurePinManager`: Cryptographic vault manager.
- `AppLockManager`: Session state and lifecycle tracker.

## 9. User Interactions
- Tap keypad digits: Updates entered PIN; automatically verifies upon entering 4th digit.
- Tap Biometric button: Invokes native Face ID / Fingerprint prompt.
- Backgrounding app: Triggers auto-lock evaluation based on elapsed time.

## 10. Input Fields
- PIN: Exactly 4 numeric digits (`0000` to `9999`).

## 11. Validation Rules
- Confirmation PIN must exactly match the first PIN during setup.
- Non-numeric or invalid length inputs are rejected.

## 12. Cryptographic & Security Architecture
- **Cryptographic Salt:** Secure random 16-byte salt generated per PIN (`SecureRandom`).
- **Hash Derivation:** Salted SHA-256 (or PBKDF2 with 10,000+ iterations):
  $$\text{Hash} = \text{SHA-256}(\text{saltBytes} + \text{pinBytes})$$
- **Storage Isolation:** Stored in a private vault (`kharchaflow_security_vault` / iOS Keychain). Never exported to JSON/CSV backups.
- **Attempt Throttling & Lockout:**
  - Maximum failed attempts: **5**.
  - Lockout duration: **30,000 ms (30 seconds)**.
  - After 5 failed attempts, verification is blocked until lockout expires.
  - Success resets the failed attempts counter to 0.
- **Auto-Lock Lifecycle:**
  - On app backgrounded: Records `lastBackgroundTimestamp`.
  - On app foregrounded: If `elapsedMillis >= autoLockDurationSeconds * 1000`, session locks.
  - `autoLockDurationSeconds == 0` locks immediately upon exiting.
- **App Switcher Privacy:**
  - Android: `WindowManager.LayoutParams.FLAG_SECURE`.
  - iOS: Obscuring view added to window during `sceneWillResignActive`.

## 13. Calculation Logic
- Lockout remaining calculation:
  $$\text{secondsRemaining} = \max\left(0, \frac{\text{lockoutUntil} - \text{System.currentTimeMillis}() + 999}{1000}\right)$$

## 14. Database Interactions
None (security credentials reside in isolated keychain preferences, not in SQLite Room database).

## 15. State Management
- `AppLockManager`: Controls `isSessionUnlocked: StateFlow<Boolean>`.
- `AppLockViewModel`: Handles PIN keypad buffer and biometric trigger state.

## 16. Navigation
- Locked state overlays `UnlockScreen` on top of all routes; back press minimizes app (`moveTaskToBack`).
- Successful authentication unlocks session and returns user to their previous screen.

## 17. Error Handling
- Biometric hardware unavailable / not enrolled: Hides biometric button, relies on PIN.
- System cancellations: Resets to PIN keypad.

## 18. Edge Cases
- Device reboot: Session defaults to locked; requires PIN/Biometrics on start.
- Clock tampering: Lockout uses elapsed real-time or monotonic clock where possible.

## 19. Dependencies
- `SecurePinManager`
- `AppLockManager`
- `BiometricAuthHelper`
- `UserPreferencesRepository`

## 20. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/core/security/SecurePinManager.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/core/security/AppLockManager.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/core/security/BiometricAuthHelper.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/security/UnlockScreen.kt`

## 21. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/AppLockSecurityTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/AppLockLifecycleTest.kt`

## 22. iOS Implementation Expectations
- Store PIN salt and hash in **iOS Keychain Services** (`kSecClassGenericPassword` with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- Biometrics handled via `LocalAuthentication` framework (`LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`).
- App switcher obscuring handled in `SceneDelegate` / `UIWindowSceneDelegate`:
  - `sceneWillResignActive`: Insert privacy blur or brand splash view.
  - `sceneDidBecomeActive`: Remove privacy view if unlocked.

## 23. Acceptance Criteria
1. PIN is stored salted and hashed in Keychain; never saved in plain text or exported in backups.
2. 5 consecutive incorrect attempts triggers a 30-second lockout.
3. Successful Face ID / Touch ID or correct PIN immediately unlocks the session.
4. Setting auto-lock to "Immediately" locks the app every time user leaves the app.

