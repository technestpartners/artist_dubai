# Hostinger API Deployment Guide

This guide details how to deploy and update the PHP backend API on Hostinger.

---

## 📦 Deployment Archive

The production deployment package is located at:
`deploy/hostinger/artist_dubai_api_hostinger.zip`

This zip contains:
```
├── api.php                  # Primary API routing and database controller
├── .htaccess                # LiteSpeed / Apache CORS & routing rules
├── api/
│   ├── api.php              # Subdirectory fallback endpoint
│   ├── .htaccess            # Rewrite to parent / security rules
│   └── uploads/
│       └── .htaccess        # Protected upload directory configuration
```

---

## 🚀 Steps to Deploy on Hostinger

1. **Log in to Hostinger hPanel**:
   - Access **File Manager** for `technestpartners.com`.
2. **Navigate to Target Directory**:
   - Navigate to `public_html/api/` (or target subdomain path).
3. **Upload the Zip Package**:
   - Upload `deploy/hostinger/artist_dubai_api_hostinger.zip`.
4. **Extract Files**:
   - Extract the contents directly into the folder.
   - Verify that `.htaccess` is present and permissions are set to `644` for files and `755` for directories.
5. **Database Verification**:
   - Confirm database credentials in `api.php`:
     - Host: `localhost`
     - Database name, username, and password configured for Hostinger MySQL.
6. **Health Check**:
   - Test in browser or curl:
     ```bash
     curl -I https://technestpartners.com/api/api.php?resource=categories
     ```
   - Expect HTTP `200 OK` with JSON array.
