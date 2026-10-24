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
        'website_url': 'https://dubaiculture.gov.ae/en'
    },
    {
        'name': 'Ministry of Culture & Youth',
        'category': 'Government · Federal Ministry',
        'location': 'Abu Dhabi, UAE',
        'rating': 4.2,
        'review_count': 98,
        'default_timing': 'Open · Closes at 14:30',
        'is_open': 1,
        'website_url': 'https://www.mcy.gov.ae/'
    },
    {
        'name': 'Dubai Design District (d3)',
        'category': 'Creative Hub · Design District',
        'location': 'Dubai Design District, Dubai',
        'rating': 4.7,
        'review_count': 215,
        'default_timing': 'Open · Closes at 22:00',
        'is_open': 1,
        'website_url': 'https://dubaidesigndistrict.com/'
    },
    {
        'name': 'Art Dubai',
        'category': 'Art Fair · Cultural Event',
        'location': 'Madinat Jumeirah, Dubai',
        'rating': 4.6,
        'review_count': 180,
        'default_timing': 'Closed · Opens Mar 2026',
        'is_open': 0,
        'website_url': 'https://www.artdubai.ae/'
    },
    {
        'name': 'Alserkal Avenue',
        'category': 'Arts District · Gallery Hub',
        'location': 'Al Quoz, Dubai',
        'rating': 4.8,
        'review_count': 310,
        'default_timing': 'Open · Closes at 20:00',
        'is_open': 1,
        'website_url': 'https://alserkal.online/'
    },
    {
        'name': 'Dubai Opera',
        'category': 'Performing Arts · Venue',
        'location': 'Downtown Dubai',
        'rating': 4.9,
        'review_count': 450,
        'default_timing': 'Open · Next show at 19:30',
        'is_open': 1,
        'website_url': 'https://www.dubaiopera.com/en'
    }
]

gov_url = 'https://technestpartners.com/api/api.php?resource=government'

for ent in entities:
    payload = json.dumps(ent).encode('utf-8')
    req = urllib.request.Request(
        gov_url,
        data=payload,
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {token}',
            'User-Agent': 'Mozilla/5.0'
        }
    )
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            print(f"Created: {ent['name']} -> {data.get('message')}")
    except urllib.error.HTTPError as e:
        err_body = e.read().decode('utf-8')
        print(f"Failed to create {ent['name']}: {e.code} - {err_body}")
    except Exception as e:
        print(f"Error {ent['name']}: {e}")
