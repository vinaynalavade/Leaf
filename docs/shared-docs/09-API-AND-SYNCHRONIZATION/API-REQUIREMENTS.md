# Leaf API & Synchronization: External API Requirements & Specifications

## 1. Executive Summary
Leaf operates strictly as an **offline-first, zero-backend** application. It does not maintain or connect to any proprietary servers, databases, or analytics endpoints. 

However, Leaf interacts with two external REST API ecosystems for optional cloud storage and application updates:
1. **Google Drive API (v3)**: Used for secure, user-owned cloud backups stored in the user's private Google Drive appdata vault.
2. **GitHub Releases API**: Used on Android for discovering published releases, release notes, and OTA packages. On iOS, mapped to the **iTunes Lookup API** for App Store release checks.

---

## 2. Google Drive v3 REST API Specification

### 2.1 Authorization & OAuth Scopes
Leaf requests access exclusively to the application-isolated data folder or user-created files:
- **Primary Scope**: `https://www.googleapis.com/auth/drive.appdata` (Access to Application Data folder; hidden from standard Drive UI, invisible to other apps).
- **Secondary Fallback Scope**: `https://www.googleapis.com/auth/drive.file` (Per-file access created by Leaf).

### 2.2 Endpoints Utilized
| Operation | HTTP Method | Endpoint | Query Parameters | Headers |
| :--- | :--- | :--- | :--- | :--- |
| **Search Existing Backup** | `GET` | `https://www.googleapis.com/drive/v3/files` | `spaces=appDataFolder&q=name='leaf_backup_v2.json'&fields=files(id,name,modifiedTime,size)` | `Authorization: Bearer <TOKEN>` |
| **Upload New Backup (Multipart)** | `POST` | `https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart` | None | `Authorization: Bearer <TOKEN>`<br>`Content-Type: multipart/related` |
| **Update Existing Backup** | `PATCH` | `https://www.googleapis.com/upload/drive/v3/files/{fileId}?uploadType=media` | None | `Authorization: Bearer <TOKEN>`<br>`Content-Type: application/json` |
| **Download Backup** | `GET` | `https://www.googleapis.com/drive/v3/files/{fileId}?alt=media` | `alt=media` | `Authorization: Bearer <TOKEN>` |

---

## 3. GitHub Releases API Specification (Android Update System)

### 3.1 Endpoint & Headers
- **Endpoint**: `GET https://api.github.com/repos/vinaynalavade/Leaf/releases/latest`
- **Request Headers**:
  - `User-Agent: Leaf-Android-App`
  - `Accept: application/vnd.github.v3+json, application/json`
  - `Connect-Timeout`: 15,000 ms
  - `Read-Timeout`: 20,000 ms

### 3.2 Rate Limiting & Error Codes
- **HTTP 200 OK**: Release found. Parse `tag_name`, `name`, `body`, and `assets`.
- **HTTP 403 Forbidden**: Rate limit exceeded (60 requests/hr for unauthenticated IPs). App catches this and displays a friendly retry message.
- **HTTP 404 Not Found**: Repository or release not found.

---

## 4. iTunes Lookup API Specification (Native iOS App Store Updates)

On iOS, downloading executable binaries outside the App Store is forbidden. To check for updates, the iOS app queries Apple's public iTunes Lookup API:

- **Endpoint**: `GET https://itunes.apple.com/lookup?bundleId=com.vinaynalavade.Leaf`
- **Response Format**:
  ```json
  {
    "resultCount": 1,
    "results": [
      {
        "version": "1.4.0",
        "releaseNotes": "Bug fixes and performance improvements.",
        "trackViewUrl": "https://apps.apple.com/app/id1234567890",
        "currentVersionReleaseDate": "2026-11-04T12:00:00Z"
      }
    ]
  }
  ```
- **Update Action**: If `results[0].version > Bundle.main.appVersion`, prompt user to update and launch deep link:
  `itms-apps://itunes.apple.com/app/id1234567890`.

