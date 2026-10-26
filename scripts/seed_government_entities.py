import urllib.request
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Login to get fresh admin token
login_url = 'https://technestpartners.com/api/api.php?resource=auth&action=login'
login_payload = json.dumps({
    'email': 'admin@artistdubai.com',
    'password': 'Admin@Dubai2026!'
}).encode('utf-8')

req = urllib.request.Request(
    login_url,
    data=login_payload,
    headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'}
)

try:
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode('utf-8'))
        token = res.get('data', {}).get('token')
        print('Logged in as admin! Token:', token[:10] + '...')
except Exception as e:
    print('Login failed:', e)
    sys.exit(1)

entities = [
    {
        'name': 'Dubai Culture & Arts Authority',
        'category': 'Government · Cultural Authority',
        'location': 'Al Shindagha, Dubai',
        'rating': 4.5,
        'review_count': 120,
        'default_timing': 'Open · Closes at 15:00',
        'is_open': 1,
        'website_url': 'https://dubaiculture.gov.ae/en',
        'directions_url': 'https://maps.google.com/?q=Dubai+Culture+and+Arts+Authority+Al+Shindagha+Dubai',
        'google_maps_reviews_url': 'https://www.google.com/maps/search/?api=1&query=Dubai+Culture+and+Arts+Authority+Al+Shindagha+Dubai'
    },
    {
        'name': 'Ministry of Culture & Youth',
        'category': 'Government · Federal Ministry',
        'location': 'Abu Dhabi, UAE',
        'rating': 4.2,
        'review_count': 98,
        'default_timing': 'Open · Closes at 14:30',
        'is_open': 1,
        'website_url': 'https://www.mcy.gov.ae/',
        'directions_url': 'https://maps.google.com/?q=Ministry+of+Culture+and+Youth+Abu+Dhabi',
        'google_maps_reviews_url': 'https://www.google.com/maps/search/?api=1&query=Ministry+of+Culture+and+Youth+Abu+Dhabi'
    },
    {
        'name': 'Dubai Design District (d3)',
        'category': 'Creative Hub · Design District',
        'location': 'Dubai Design District, Dubai',
        'rating': 4.7,
        'review_count': 215,
        'default_timing': 'Open · Closes at 22:00',
        'is_open': 1,
        'website_url': 'https://dubaidesigndistrict.com/',
        'directions_url': 'https://maps.google.com/?q=Dubai+Design+District+Dubai',
        'google_maps_reviews_url': 'https://www.google.com/maps/search/?api=1&query=Dubai+Design+District+Dubai'
    },
    {
        'name': 'Art Dubai',
        'category': 'Art Fair · Cultural Event',
        'location': 'Madinat Jumeirah, Dubai',
        'rating': 4.6,
        'review_count': 180,
        'default_timing': 'Closed · Opens Mar 2026',
        'is_open': 0,
        'website_url': 'https://www.artdubai.ae/',
        'directions_url': 'https://maps.google.com/?q=Madinat+Jumeirah+Dubai',
        'google_maps_reviews_url': 'https://www.google.com/maps/search/?api=1&query=Madinat+Jumeirah+Dubai'
    },
    {
        'name': 'Alserkal Avenue',
        'category': 'Arts District · Gallery Hub',
        'location': 'Al Quoz, Dubai',
        'rating': 4.8,
        'review_count': 310,
        'default_timing': 'Open · Closes at 20:00',
        'is_open': 1,
        'website_url': 'https://alserkal.online/',
        'directions_url': 'https://maps.google.com/?q=Alserkal+Avenue+Al+Quoz+Dubai',
        'google_maps_reviews_url': 'https://www.google.com/maps/search/?api=1&query=Alserkal+Avenue+Al+Quoz+Dubai'
    },
    {
        'name': 'Dubai Opera',
        'category': 'Performing Arts · Venue',
        'location': 'Downtown Dubai',
        'rating': 4.9,
        'review_count': 450,
        'default_timing': 'Open · Next show at 19:30',
        'is_open': 1,
        'website_url': 'https://www.dubaiopera.com/en',
        'directions_url': 'https://maps.google.com/?q=Dubai+Opera+Downtown+Dubai',
        'google_maps_reviews_url': 'https://www.google.com/maps/search/?api=1&query=Dubai+Opera+Downtown+Dubai'
    }
]

# Trigger official backend seed to populate rich database attributes
seed_url = 'https://technestpartners.com/api/api.php?resource=government&action=seed'
try:
    with urllib.request.urlopen(seed_url) as resp:
        seed_res = json.loads(resp.read().decode('utf-8'))
        print(f"Backend seed response: {seed_res.get('message')}")
except Exception as e:
    print('Direct seed endpoint trigger note:', e)

# Fetch existing entities to determine whether to create or update
gov_url = 'https://technestpartners.com/api/api.php?resource=government'
existing_names = set()
try:
    with urllib.request.urlopen(gov_url) as resp:
        fetch_res = json.loads(resp.read().decode('utf-8'))
        for r in fetch_res.get('data', []):
            existing_names.add(r.get('name'))
except Exception as e:
    pass

for ent in entities:
    if ent['name'] in existing_names:
        # Use PUT to update existing entity
        payload = json.dumps(ent).encode('utf-8')
        req = urllib.request.Request(
            gov_url,
            data=payload,
            headers={
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {token}',
                'User-Agent': 'Mozilla/5.0'
            },
            method='PUT'
        )
        try:
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                print(f"Updated: {ent['name']} -> {data.get('message')}")
        except Exception as e:
            print(f"Update note for {ent['name']}: {e}")
    else:
        # Use POST to create new entity
        payload = json.dumps(ent).encode('utf-8')
        req = urllib.request.Request(
            gov_url,
            data=payload,
            headers={
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {token}',
                'User-Agent': 'Mozilla/5.0'
            },
            method='POST'
        )
        try:
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                print(f"Created: {ent['name']} -> {data.get('message')}")
        except Exception as e:
            print(f"Create note for {ent['name']}: {e}")

# Fetch and verify current active database records
print("\n--- Current Government Entities in Database ---")
try:
    with urllib.request.urlopen(gov_url) as resp:
        fetch_res = json.loads(resp.read().decode('utf-8'))
        records = fetch_res.get('data', [])
        print(f"Total entities found: {len(records)}")
        for idx, r in enumerate(records, 1):
            print(f"{idx}. {r.get('name')} | {r.get('category')} | {r.get('location')} | Rating: {r.get('rating')} ({r.get('review_count')} reviews)")
except Exception as e:
    print('Verification failed:', e)
