# Hostinger API Deployment & CI/CD Pipeline Guide

This guide details how to automatically deploy updates to Hostinger using the GitHub Actions CI/CD pipeline, remove unwanted legacy files, and maintain the latest production API.

---

## 🛑 Unwanted Legacy Files to Remove

If you see these files in `public_html/api/` on Hostinger (as shown in File Manager):
- ❌ `artist_dubai.sql` *(Unwanted database dump - security risk)*
- ❌ `artist_dubai.sqlite` *(Unwanted SQLite database)*
- ❌ `db.php` *(Unwanted legacy database script)*
- ❌ `index.php` *(Unwanted legacy index script)*
- ❌ `share.php` *(Unwanted legacy script)*

### How They Are Removed:
1. **Automatic Removal by API**:
   The latest `api/api.php` includes an automatic self-cleaner (`UnifiedMySqlApiRouter::purgeObsoleteFiles()`). As soon as the latest `api.php` runs, or when you visit:
   ```
   https://technestpartners.com/api/api.php?resource=system&action=cleanup
   ```
   The server will immediately unlink and delete all 5 unwanted files and return a status report.
2. **Manual Removal via File Manager**:
   In Hostinger hPanel File Manager (`public_html/api/`), select the 5 files above and click **Delete** (Trash icon).

---

## ⚡ Automated CI/CD Deployment Pipeline

We have configured a GitHub Actions pipeline at [`.github/workflows/deploy_backend_hostinger.yml`](file:///d:/laragon/www/artist_dubai/.github/workflows/deploy_backend_hostinger.yml).

### How It Works:
- **Automatic Deployment on Push**: Any commit pushed to `main` or `master` touching `api/**` triggers the workflow.
- **PHP Syntax Validation**: Verifies that `api/api.php` passes `php -l` linting prior to deployment.
- **Safe Sync via FTPS**: Deploys only `api.php`, `.htaccess`, and `uploads/.htaccess` directly to `public_html/api/`.
- **Automatic Post-Deploy Cleanup**: Sends a ping to `?resource=system&action=cleanup` to verify health and purge any lingering legacy files.

### Setting Up GitHub Repository Secrets:
In your GitHub repository, navigate to **Settings > Secrets and variables > Actions > New repository secret** and add:

| Secret Name | Value | Where to find in Hostinger |
|---|---|---|
| `HOSTINGER_FTP_SERVER` | e.g. `ftp.technestpartners.com` or your Hostinger FTP IP | hPanel > **Files** > **FTP Accounts** |
| `HOSTINGER_FTP_USERNAME` | Your FTP account username (e.g. `u530915492` or created FTP user) | hPanel > **Files** > **FTP Accounts** |
| `HOSTINGER_FTP_PASSWORD` | Your FTP account password | hPanel > **Files** > **FTP Accounts** |

Once configured, any push to GitHub will automatically deploy the latest API to Hostinger!

---

## 📦 Manual Deployment Package (Alternative)

If you prefer to update manually right now without pushing to GitHub:

1. **Pre-built Archive**:
   [deploy/hostinger/artist_dubai_api_hostinger.zip](file:///d:/laragon/www/artist_dubai/deploy/hostinger/artist_dubai_api_hostinger.zip) contains:
   - `api.php` (Latest pure MySQL API with self-cleanup & like-viewers)
   - `.htaccess` (Hardened Apache / LiteSpeed security rules)
   - `uploads/.htaccess` (Script execution blocking for upload directory)
   - `.env.example`
2. **Steps in Hostinger File Manager**:
   - Go to `public_html/api/`.
   - Delete `artist_dubai.sql`, `artist_dubai.sqlite`, `db.php`, `index.php`, `share.php`.
   - Upload `artist_dubai_api_hostinger.zip`.
   - Right-click and choose **Extract**.
   - Overwrite existing `api.php` and `.htaccess`.
3. **Verify Health**:
   Visit in browser or run:
   ```bash
   curl https://technestpartners.com/api/api.php?resource=system&action=cleanup
   ```
