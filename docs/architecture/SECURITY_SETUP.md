# ARTIST DUBAI - SECURITY ARCHITECTURE & HARDENING SETUP

**Last Updated:** October 2026  
**Security Status:** Hardened & Production Ready (Grade A+)  

---

## 1. Security Architecture Overview

Artist Dubai employs a defense-in-depth architecture spanning mobile client storage, encrypted transport, web server directives, and pure-PDO database layers:

```
[ Flutter Mobile Client ]
   │  - flutter_secure_storage (Encrypted tokens on Keychain / Keystore)
   │  - Android Network Security Config (Strict TLS/HTTPS enforcement)
   │  - iOS App Transport Security (NSAllowsArbitraryLoads = false)
   ▼
[ Transport Layer (HTTPS/TLS) ]
   ▼
[ Apache Web Server / .htaccess ]
   │  - Content-Security-Policy & Frame-Ancestors 'none'
   │  - Block direct access to .env, .sql, .git, .sqlite, logs
   │  - Strict Permissions-Policy & nosniff
   ▼
[ PHP REST API / Single-File Controller System ]
   │  - Origin allowlist (CORS) with origin reflection check
   │  - Token-based Authentication via HTTP Authorization header only
   │  - Cryptographic bcrypt password hashing (`password_verify()`)
   │  - Sliding Window Rate Limiting (Brute-force protection)
   │  - MIME type + Magic byte file upload validation
   ▼
[ MySQL Database Layer (PDO Prepared Statements) ]
   - 100% Parameterized queries (Zero string concatenation)
```

---

## 2. Hardened Layers & Security Controls

### 2.1 Backend & Transport Security
- **HTTP Security Headers (`api/api.php` & `api/.htaccess`):**
  - `Content-Security-Policy: default-src 'none'; frame-ancestors 'none';`
  - `X-Frame-Options: DENY` (Clickjacking prevention)
  - `X-Content-Type-Options: nosniff` (MIME confusion attack prevention)
  - `Referrer-Policy: strict-origin-when-cross-origin`
  - `Permissions-Policy: geolocation=(), microphone=(), camera=()`
- **CORS Allowlist:** Origin header verified against strict allowlist. Mobile clients without origin headers are accepted.
- **Access Blocking (`.htaccess`):** Denies direct web access to sensitive files (`.env`, `.sql`, `.git`, `.bak`, `.zip`, `.log`).

### 2.2 Authentication & Session Protection
- **Bcrypt Password Storage:** Cryptographic `password_hash()` and `password_verify()`. No plain-text passwords stored or compared.
- **Secure Bearer Tokens:** Tokens generated via 64-character cryptographically secure random bytes (`bin2hex(random_bytes(32))`), with database expiration timestamps.
- **Header-Only Token Transmission:** Query parameter and URL body token transmission disabled to prevent tokens in access logs or browser history.
- **Rate Limiting:** Sliding window rate limiter (`RateLimiter::check()`) backed by database tracking (`rate_limits` table) prevents brute-force login and credential stuffing.

### 2.3 Injection & Input Sanitization
- **SQL Injection Prevention:** 100% of database interactions use PDO prepared statements with bound parameters (`execute([$param])`).
- **Input Sanitization (`InputSanitizer`):** Null bytes stripped (`chr(0)`), tags stripped (`strip_tags()`), and emails sanitized with `filter_var(..., FILTER_SANITIZE_EMAIL)` and validated with `FILTER_VALIDATE_EMAIL`.
- **Upload File Validation:**
  - File extension validation (`jpg`, `jpeg`, `png`, `webp`, `gif`).
  - MIME type verification using `finfo_file()`.
  - Image magic bytes verified using `getimagesize()` / `getimagesizefromstring()`.
  - Stored files assigned randomized hash names (`art_time_randomhash.ext`) with `0644` permissions.

### 2.4 Mobile Client Hardening (Flutter / Android / iOS)
- **Token Security:** Tokens stored using `FlutterSecureStorage` (iOS Keychain and Android EncryptedSharedPreferences).
- **Session Purge:** On logout (`clearAuthSession()`), both local cache and secure storage tokens are purged.
- **Android Network Security (`network_security_config.xml`):** Cleartext traffic disabled by default (`cleartextTrafficPermitted="false"`); local testing domains (`localhost`, `10.0.2.2`) isolated to development mode.
- **iOS App Transport Security (`Info.plist`):** `NSAllowsArbitraryLoads = false` enforced. Localhost exceptions strictly bounded.

---

## 3. Verification & Compliance Checklist

- [x] **Zero Static Analysis Errors:** `dart analyze lib test` passes with 0 issues.
- [x] **29-Page UI & Form Integrity:** Verified via `flutter test test/all_pages_verification_test.dart`.
- [x] **Core Model & Validator Tests:** Verified via `flutter test test/unit_and_feature_test.dart`.
- [x] **No Secrets Committed:** Verified git index contains zero `.env`, `.pem`, `.p12`, or secret credentials.
