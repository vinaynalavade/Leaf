# Leaf Android — Production Release Signing Architecture & Protection

> **CRITICAL SECURITY SPECIFICATION**  
> This document records non-sensitive release signing parameters, file locations, backup protocols, and disaster recovery procedures for the Leaf Android production application.  
> **Under no circumstances should passwords, keypass values, or private key binary data be committed to version control or added to this document.**

---

## 1. Specification & Signing Identity

* **Application ID:** `com.vinaynalavade.expensetracker`
* **Keystore Relative Location:** `keystore/leaf-release-key.jks`
* **Keystore Absolute Location:** `<PROJECT_ROOT>/keystore/leaf-release-key.jks`
* **Key Alias:** `leaf-upload`
* **Key Algorithm:** `RSA`
* **Key Size:** `4096-bit`
* **Signature Scheme:** APK Signature Scheme v2 & v3 (with v1 JAR fallback disabled for minimum API 26+)
* **Validity Period:** `10,000 days` (~27 years)
* **Distinguished Name (DName):** `CN=Vinay Nalavade, OU=KharchaFlow, O=KharchaFlow, L=Mumbai, ST=Maharashtra, C=IN`

---

## 2. Configuration & Credential Resolution

Leaf Gradle release builds read credentials through `<PROJECT_ROOT>/keystore/signing.properties`.

### Expected `keystore/signing.properties` Format:
```properties
storeFile=keystore/leaf-release-key.jks
storePassword=<YOUR_STORE_PASSWORD>
keyAlias=leaf-upload
keyPassword=<YOUR_KEY_PASSWORD>
```

### Resolution Order in `app/build.gradle.kts`:
1. `<PROJECT_ROOT>/keystore/signing.properties` (Primary local config)
2. `<PROJECT_ROOT>/signing.properties` (Legacy root fallback)
3. `~/.android/leaf-signing.properties` (User home fallback)
4. Environment variables (`LEAF_KEYSTORE_PATH`, `LEAF_KEYSTORE_PASSWORD`, `LEAF_KEY_ALIAS`, `LEAF_KEY_PASSWORD`)

If credentials or keystore binary are missing during a release task (`assembleRelease`), Gradle fails fast with an explicit descriptive error preventing accidental unsigned or debug-signed deployments.

---

## 3. Git Protection Rules

Both `keystore/leaf-release-key.jks` and `keystore/signing.properties` are strictly excluded from source control in `.gitignore`:
```gitignore
# Leaf production signing credentials — NEVER COMMIT
/keystore/
*.jks
*.keystore
*.p12
*.pfx
signing.properties
keystore.properties
key.properties
```

---

## 4. Backup & Disaster Recovery Protocols

The Android operating system strictly enforces that application updates must be signed with the identical cryptographic private key as the currently installed version.

> [!WARNING]
> **Loss of the production signing key is permanent and irrecoverable.**  
> Losing `leaf-release-key.jks` or its password will prevent existing users from updating Leaf without uninstalling the application and losing local database records.

### Primary Local Backup:
* **Directory:** `%USERPROFILE%\Leaf-Signing-Backups\`
* **Access Control:** Restricted via Windows ACL (`icacls "%USERPROFILE%\Leaf-Signing-Backups" /inheritance:r /grant:r "%USERNAME%:(OI)(CI)F"`). Only the logged-in developer has read/write access.
* **Contents:**
  * `leaf-release-key.jks`
  * `signing.properties`

### Encrypted Offline Backup Procedure (Recommended):
1. **Create an AES-256 Encrypted Archive:**
   Compress the keystore and properties using 7-Zip with AES-256 encryption:
   ```powershell
   & "C:\Program Files\7-Zip\7z.exe" a -p -mhe=on "Leaf-Signing-Backup-Encrypted.7z" "$env:USERPROFILE\Leaf-Signing-Backups\*"
   ```
2. **Offline Air-Gapped Storage:**
   Store the resulting `.7z` archive on two distinct physical media:
   * A dedicated, encrypted hardware USB drive stored in a secure physical location.
   * An offline secondary machine or private encrypted archive.
3. **Password Management:**
   Store the archive decryption passphrase in a trusted password manager (e.g. 1Password, Bitwarden, KeePass). Never store the password on the same physical medium as the encrypted archive.

---

## 5. Keystore Generation Command

When initializing the permanent key:
```powershell
keytool -genkeypair -v `
  -keystore "keystore/leaf-release-key.jks" `
  -alias "leaf-upload" `
  -keyalg RSA `
  -keysize 4096 `
  -validity 10000 `
  -dname "CN=Vinay Nalavade, OU=KharchaFlow, O=KharchaFlow, L=Mumbai, ST=Maharashtra, C=IN" `
  -storetype JKS
```
Once generated, compute and verify the fingerprint:
```powershell
keytool -list -v -keystore "keystore/leaf-release-key.jks" -alias "leaf-upload"
```

### Verified Production Certificate Fingerprints (Generated 14-Nov-2026)

* **Status:** Verified Active Production Key
* **Entry Type:** `PrivateKeyEntry`
* **Subject / Issuer:** `CN=Vinay Nalavade, OU=KharchaFlow, O=KharchaFlow, L=Mumbai, ST=Maharashtra, C=IN`
* **Serial Number:** `93126e486460dd9e`
* **Key Algorithm:** `4096-bit RSA key`
* **Signature Algorithm:** `SHA384withRSA`
* **Validity:** `14-Nov-2026` to `01-Apr-2054` (10,000 days)
* **SHA-256 Fingerprint (colon-separated):**
  `0E:CB:0E:1D:25:9B:5F:32:61:2F:DF:AC:00:8B:F7:3C:80:41:2D:3C:81:86:88:9D:C8:42:B4:EF:42:5E:35:A1`
* **SHA-256 Fingerprint (raw hex):**
  `0ecb0e1d259b5f32612fdfac008bf73c80412d3c8186889dc842b4ef425e35a1`
* **SHA-1 Fingerprint:**
  `8C:B2:69:93:E1:E3:77:A9:65:6E:AF:62:6F:AB:57:41:4E:8C:ED:DA`
* **MD5 Fingerprint:**
  `6F:D5:B5:F9:6B:1E:2A:E9:D5:91:18:8A:4D:D0:16:2B` (`6fd5b5f96b1e2ae9d591188a4dd0162b`)
* **Keystore Binary SHA-256 Hash:**
  `2a449d403458c4a7031ee299adfcc3cac73c6c99f30d03b17e97aba1ab9141ea`

---

## 6. Release Verification Record

* **Target Build:** Leaf v1.1.4 (versionCode 16)
* **Build Artifact:** `app/build/outputs/apk/release/app-release.apk`
* **Artifact Size:** 4,625,000 bytes (~4.41 MiB)
* **Verification Tool:** Android SDK `apksigner`
* **Verification Status:** `Verifies` (APK Signature Scheme v2: `true`)
* **Signer DN:** `CN=Vinay Nalavade, OU=KharchaFlow, O=KharchaFlow, L=Mumbai, ST=Maharashtra, C=IN`
* **Signer Certificate Digest (SHA-256):**
  `0ecb0e1d259b5f32612fdfac008bf73c80412d3c8186889dc842b4ef425e35a1` (Identical match to keystore)



