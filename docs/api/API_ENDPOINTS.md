# Dubai Artists - Comprehensive REST API Specification

Version: **6.3.0**  
Engine: **Pure MySQL (InnoDB, UTF8mb4)**  
Architecture: **Controller-Router Service with In-Memory Caching & Stale-While-Revalidate**  

---

## 🌐 Base URL & Routing Conventions

- **Production (Hostinger Cloud)**: `https://technestpartners.com/api/`
- **Local Development**: `http://localhost/artist_dubai/api/` or `http://artist_dubai.test/api/`

Every REST endpoint follows the resource routing convention:
```
GET/POST/PUT/DELETE https://technestpartners.com/api/api.php?resource={RESOURCE}&action={ACTION}
```

---

## 🔑 Authentication & Authorization

All requests to protected endpoints require one of the following HTTP headers:
```http
Authorization: Bearer <AUTH_TOKEN>
X-Auth-Token: <AUTH_TOKEN>
```

Role-based access levels:
- **Public**: Unauthenticated guests (read-only directory browsing).
- **User (Art Enthusiast)**: Can RSVP to events, save favorites, and manage their personal profile.
- **Artist**: Can create public profiles, upload portfolios, and chat with collectors.
- **Admin**: Full moderation privileges, KPI dashboard, permissions toggle, master category manager, and recycle bin recovery.

---

## 📋 Comprehensive Endpoint Catalog

### 1. Authentication & Users
| Resource & Action | Method | Description | Payload / Parameters |
|---|---|---|---|
| `?resource=login` | `POST` | Authenticate user or admin | `{ email, password }` |
| `?resource=register` | `POST` | Create new account | `{ full_name, email, password, role }` |
| `?resource=login&action=profile` | `GET` | Get authenticated profile | *Requires Auth Header* |
| `?resource=login&action=update_profile` | `POST` | Update user metadata | `{ name, phone, bio, avatar_url }` |
| `?resource=users` | `GET` | Admin list of users | `?page=1&limit=50&role=artist` |

### 2. Artists Directory
| Resource & Action | Method | Description | Payload / Parameters |
|---|---|---|---|
| `?resource=artists` | `GET` | Paginated artist catalog | `?page=1&limit=50&category=Painting&q=search` |
| `?resource=artists&id={ID}` | `GET` | Full artist profile with artworks | `?id=12` |
| `?resource=artists` | `POST` | Register or update artist profile | `{ name, category, bio, phone, location, portfolio }` |
| `?resource=artists&id={ID}&action=delete` | `POST` | Move artist to recycle bin | Admin privilege required |

### 3. Art Categories & Master Data
| Resource & Action | Method | Description | Payload / Parameters |
|---|---|---|---|
| `?resource=categories` | `GET` | List active categories | `?type=artist` or `?type=event` |
| `?resource=categories` | `POST` | Create category (Admin) | `{ name, emoji, type, status }` |
| `?resource=experience_levels` | `GET` | Master experience levels | Returns Emerging, Mid-Career, Established |
| `?resource=locations` | `GET` | Dubai hubs & districts | Returns Alserkal, DIFC, Downtown, etc. |

### 4. Exhibitions, Events & Open Calls
| Resource & Action | Method | Description | Payload / Parameters |
|---|---|---|---|
| `?resource=events` | `GET` | List active art events | `?category=All&filter=upcoming&page=1` |
| `?resource=events&id={ID}` | `GET` | Single event details & RSVPs | `?id=45` |
| `?resource=events` | `POST` | Create community exhibition | `{ title, date, venue, category, description, photos }` |
| `?resource=events&action=galleries` | `GET` | Fetch photo galleries for event | `?event_id=45` |

### 5. RSVPs & Event Bookings
| Resource & Action | Method | Description | Payload / Parameters |
|---|---|---|---|
| `?resource=bookings` | `GET` | User ticket reservations | *Requires Auth Header* |
| `?resource=bookings` | `POST` | Book attendance or RSVP | `{ event_id, seats, guest_names }` |
| `?resource=bookings&action=cancel`| `POST` | Cancel RSVP reservation | `{ booking_id }` |

### 6. Galleries & Cultural Portals
| Resource & Action | Method | Description | Payload / Parameters |
|---|---|---|---|
| `?resource=galleries` | `GET` | Directory of art spaces | `?location=Alserkal Avenue` |
| `?resource=galleries` | `POST` | Register art gallery venue | `{ name, address, phone, gallery_type, schedule }` |
| `?resource=government` | `GET` | Dubai Culture initiatives | Returns grants, permits, initiatives |

### 7. Bookmarks & Favorites
| Resource & Action | Method | Description | Payload / Parameters |
|---|---|---|---|
| `?resource=favorites` | `GET` | Sync saved items | `?type=artists` or `?type=events` |
| `?resource=favorites` | `POST` | Toggle favorite state | `{ item_id, item_type: "artist"|"event"|"artwork" }` |

### 8. Live Sync & Real-Time Polling
| Resource & Action | Method | Description | Payload / Parameters |
|---|---|---|---|
| `?resource=live_sync` | `GET` | Lightweight timestamp poll | Returns latest modification timestamps |

### 9. Media & File Uploads
| Resource & Action | Method | Description | Payload / Parameters |
|---|---|---|---|
| `?resource=upload` | `POST` | Upload image (PNG/JPEG/WEBP) | `multipart/form-data` with `file` key |

### 10. Subscriptions & Stripe Payments
| Resource & Action | Method | Description | Payload / Parameters |
|---|---|---|---|
| `?resource=publishing_pricing` | `GET` | Active listing subscription tiers | Returns plans and AED prices |
| `?resource=stripe&action=config` | `GET` | Fetch publishable key & currency | Returns `{ publishableKey, currency }` |
| `?resource=stripe&action=create_intent` | `POST` | Create Stripe PaymentIntent | `{ amount, currency, plan_id, user_email }` |

---

## 📦 Standard Response Envelope Format

### Successful Response:
```json
{
  "status": "success",
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 128,
    "total_pages": 3,
    "has_more": true
  }
}
```

### Error Response:
```json
{
  "status": "error",
  "success": false,
  "message": "User account could not be found.",
  "code": 404
}
```
