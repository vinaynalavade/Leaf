# Leaf for iOS — Release Notes (v1.0.0 Build 2)

**Release Date:** November 13, 2026  
**Platform:** iOS 17.0+ (iPhone & iPad)  
**Bundle Identifier:** `com.vinaynalavade.Leaf`  
**Version:** `1.0.0` (Build `2`)  
**Architecture:** Apple Silicon / arm64 Native  

---

## 🍃 Executive Overview

**Leaf iOS** is an authentic, privacy-first personal finance and wealth management application crafted entirely with native SwiftUI and GRDB (SQLite). Built strictly to match the master specification and functional parity with the Android reference implementation, Leaf operates 100% offline, keeping all user financial data strictly local and secure.

---

## 🌟 Key Features & Release Highlights

### 1. Dynamic Theme System (Emerald & Obsidian)
- **Instant Reactive Appearance Switching:** Toggle between **System**, **Light**, and **Dark** modes directly in Settings; visual changes propagate immediately across the entire view hierarchy without app restart.
- **Master Color Tokens:** High-contrast luxury palette honoring Emerald accents (`#10B981` / `#039876`) and deep Obsidian surfaces (`#0A0C0F` / `#14171E` / `#1C202A`).
- **Contrast & Legibility:** Zero illegible dark text on dark surfaces or harsh white boxes in dark mode; all cards, sheets, headers, and charts dynamically adapt.

### 2. Native WidgetKit Widgets & In-App Showcase
- **Small, Medium & Large Widgets:** Display real-time financial snapshots including checking balance, monthly income, expense totals, budget progress, and quick action shortcuts.
- **Interactive Balance Privacy Toggle:** One-tap eye/eye-slash button directly inside iOS 17+ widgets powered by App Intents (`ToggleWidgetBalancePrivacyIntent`) and synchronized with the main app via App Group (`group.com.vinaynalavade.Leaf`).
- **In-App Widget Showcase:** Accessible from Settings and Dashboard, featuring live interactive previews across all sizes and a step-by-step Home Screen installation guide.

### 3. Independent Cash & Account Ledgers & Data Integrity
- **Segregated Accounting:** Dedicated tracking for physical Cash (`💵 Cash`) and Bank/Online accounts (`💳 Account`).
- **Balance-Neutral Atomic Transfers:** Inter-ledger fund transfers recorded with zero double-counting, excluded from ordinary expense/income metrics, budgets, insights, and statements.
- **Atomic Transfer Linking & Lifecycle:** Paired transfer records are explicitly linked via `transfer_pair_id`. Deleting either leg atomically deletes both paired entries. Editing either leg consistently synchronizes amounts, notes, and dates across both records.
- **Transfer Reversal Engine:** Seamlessly reverse any inter-ledger transfer (`reverseTransfer` / `ReverseTransferUseCase`), creating an atomic reverse transfer that restores both ledgers to their exact initial balances while maintaining overall net liquid balance completely unchanged.
- **Migration v18 Data Safety:** Preserves original historical payment method strings (`raw_payment_method`). Normalizes only explicitly recognized Cash and electronic/account methods (`ACCOUNT`, `BANK_ACCOUNT`, `UPI`, `CARD`, `NET_BANKING`, `ONLINE`). Unknown methods (`CHEQUE`, `WALLET`, custom tokens) and `NULL` values are safely preserved in their original form and never converted to CASH.
- **Ledgers Hub:** Full breakdown of inflows, outflows, net balances, and transfer history.
- **Default Transaction Source:** Configurable default payment method in Settings, automatically preselected in Quick Add and Add/Edit Expense flows.

### 4. Cryptographic Security & Privacy
- **Salted PBKDF2-HMAC-SHA256 PIN Protection:** Upgraded 6-digit PIN derivation with 100,000 rounds and a 16-byte cryptographically secure random salt stored strictly in Apple Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- **Zero-Downtime Safe Migration:** Seamless automatic migration from legacy single-pass hashes upon next successful PIN entry.
- **App Lock Safeguards:** Disabled by default; strictly requires user PIN confirmation prior to activation. Automatic rate-limiting and 30-second lockout after 5 consecutive failed attempts.
- **Multitasking Privacy Shield:** Instant snapshot concealment concealing balances and transactions whenever app is resigned or backgrounded.
- **Balance Privacy (Eye Toggle):** Instant masking of sensitive balances (`₹••••••`) across Dashboard and widgets.
- **Data Protection:** Absolute preservation of legitimate opening balances (including ₹1,00,000) with zero test pollution or accidental resets.

### 5. Split & Collect Suite
- **Prominent Settle Up:** Effortless discovery from group details and individual participant views.
- **Net Balance Calculation:** Clear breakdown of who owes whom and how much, handling direct and reverse debts.
- **Partial Payments & Reversals:** Support for partial payments, live status updates (Pending, Partially Settled, Settled), and transaction logging with ledger integration.
- **Calculations & Distribution:** Equal, unequal, percentage, and itemized splits with deterministic penny reconciliation.

### 6. Multi-Currency & Travel Wallets
- **11 Global Currencies:** INR, USD, EUR, GBP, AED, SGD, AUD, CAD, JPY, CHF, CNY.
- **Travel Wallets:** Dedicated trip wallets with original foreign currency tracking and automatic primary equivalent conversions.
- **Exchange Rate Engine:** Built-in rate caching with manual rate customization and base currency recalculation.

### 7. Financial Tools & Calculators Suite
- **6 Fintech Calculation Engines:** EMI (Amortization), SIP (Wealth Growth), Fixed Deposit (FD), Recurring Deposit (RD), Retail Discount, and Statutory GST Apportionment.
- **Interactive Visualizations:** Amortization tables, maturity timelines, breakdown cards, and dynamic theme gradients.

### 8. Financial Statements & Native Export
- **PDF & CSV Statement Generation:** One-tap presets (Monthly, Quarterly, Annual, Custom) with comprehensive cashflow analytics, category breakdowns, and savings progress.
- **Native iOS File Sharing:** In-app PDF viewer with seamless iOS ShareSheet integration.

### 9. Encrypted Backups & Cloud Integration Status
- **AES-GCM 256 Local Encryption (ACTIVE & PRODUCTION-READY):** Hardened with 600,000 PBKDF2 iterations and random IVs.
- **Google Drive Cloud Sync (UNAVAILABLE IN PRODUCTION):** Development and simulator simulated flows are implemented. Production Google Cloud Console OAuth 2.0 client credentials (Client ID, iOS URL schemes, and verified redirect URIs) have not been configured for this standalone client build. Google Drive Cloud Sync is therefore explicitly marked as **UNAVAILABLE for production release** until credentials are provisioned in Google Cloud Console.

---

## 🛠 Validation & Quality Assurance

- **Unit & Integration Tests:** 71/71 automated tests passing with 0 failures (`** TEST SUCCEEDED **`).
- **Simulators Tested:** iPhone 18 Pro (iOS 27.2 Simulator).
- **Appearance Verification:** Light Mode, Dark Mode, and System appearance transitions verified.
- **Release Archive:** Generated native Xcode archive at `build/Leaf.xcarchive` (`** ARCHIVE SUCCEEDED **`).
- **Zero Git Operations:** Maintained complete git isolation.
- **Android Directory:** Untouched and strictly preserved (`READ-ONLY`).

---

## 📦 Artifacts Ready for GitHub

1. **Source Package:** `release/Leaf-iOS-v1.0.0-Source.zip` (1.2 MB clean source code, ready for GitHub release or repository upload).
2. **Xcode Archive:** `build/Leaf.xcarchive` (Contains `Leaf.app` arm64 binary and `dSYMs` for symbolication).
3. **Release Documentation:** `release/RELEASE_NOTES.md`.
