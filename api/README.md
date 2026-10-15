# Dubai Artists - PHP Backend API

This directory contains the lightweight REST API powering the Dubai Artists mobile and web applications.

---

## 🏗️ Architecture

The backend is built as a hardened single-file/modular PHP service:
- **`api.php`**: Primary request router, authentication middleware, database queries, and response formatter.
- **`.htaccess`**: Web server configuration managing routing rewrites, CORS headers, fast CGI auth passing, and directory security.
- **`uploads/`**: Media storage directory with its own `.htaccess` restricting executable scripts while allowing image viewing.

---

## 💻 Local Development (Laragon)

1. Place the project inside your Laragon `www` directory: `D:\laragon\www\artist_dubai\`.
2. Ensure MySQL is running in Laragon.
3. Import `database/artist_dubai.sql` into MySQL database `artist_dubai`.
4. The API can be queried locally at:
   - `http://artist_dubai.test/api.php`
   - or `http://localhost/artist_dubai/api/api.php`

---

## 🔒 Security Measures

- **SQL Injection Prevention**: All queries use PDO parameterized prepared statements.
- **CORS & Headers**: Strict CORS origin and method whitelisting with `X-Frame-Options: SAMEORIGIN` and `X-Content-Type-Options: nosniff`.
- **Sensitive Files Protection**: Apache rules block direct access to `.sql`, `.env`, `.git`, `.yaml`, and `.zip` files.
- **Role-Based Access Control**: Middleware verifies admin token permissions before executing mutation actions.
