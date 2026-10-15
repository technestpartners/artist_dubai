# Dubai Artists - Deployment Bundles

This folder holds prepared deployment archives and configurations for remote servers.

---

## 🗂️ Deployment Archives

- **`hostinger/artist_dubai_api_hostinger.zip`**:
  Production-ready backend package designed for extraction into the Hostinger `public_html/api/` web directory.

---

## 📋 Archive Contents
```
api.php                  # Primary API engine and routes
.htaccess                # Server security and URL rewrite directives
api/
  api.php                # Fallback handler
  .htaccess              # Subdirectory rewrite rules
  uploads/
    .htaccess            # Secure upload sandbox rules
```

For deployment instructions, refer to [Hostinger Backend Setup](../docs/deployment/HOSTINGER_BACKEND_SETUP.md).
