import urllib.request
import json
import sys
import time

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

categories = [
    ('Painting', 'artist', 'Canvas, oil, acrylic, and watercolor paintings', '🎨'),
    ('Photography', 'artist', 'Fine art, landscape, and portrait photography', '📷'),
    ('Sculpture', 'artist', '3D sculptural works, stone, bronze, and clay', '🗿'),
    ('Drawing', 'artist', 'Pencil, charcoal, ink, and pastel sketches', '✏️'),
    ('Digital Art', 'artist', 'Digital painting, 3D graphics, and generative art', '💻'),
    ('AI-Generated Art', 'artist', 'Artificial intelligence and algorithmic artworks', '🤖'),
    ('Architecture', 'artist', 'Architectural design, models, and spatial art', '🏛️'),
    ('Theatre', 'artist', 'Stage plays, dramatic productions, and theatrical arts', '🎭'),
    ('Dance', 'artist', 'Choreography, contemporary, and traditional dance', '💃'),
    ('Music', 'artist', 'Composition, instrumental, and acoustic music', '🎵'),
    ('Film', 'artist', 'Cinematography, short films, and indie filmmaking', '🎬'),
    ('Video Art', 'artist', 'Moving image installations and video experimental art', '📹'),
    ('Literature', 'artist', 'Literary works, novels, essays, and prose', '📚'),
    ('Poetry', 'artist', 'Classical, spoken word, and contemporary poetry', '📜'),
    ('Creative Writing', 'artist', 'Narrative storytelling, scripts, and creative writing', '🖋️'),
    ('Drama', 'artist', 'Dramatic performance, acting, and stage dialogue', '🎭'),
    ('Graphic Design', 'artist', 'Visual branding, typography, and graphic layout', '📐'),
    ('Fashion Design', 'artist', 'Haute couture, wearable art, and garment design', '👗'),
    ('Interior Design', 'artist', 'Spatial styling, artistic interiors, and decor', '🛋️'),
    ('Product Design', 'artist', 'Industrial design, aesthetic object creation', '📦'),
    ('Crafts', 'artist', 'Artisan handicrafts, papercraft, and artisanal work', '🧶'),
    ('Textile Art', 'artist', 'Weaving, tapestry, embroidery, and fiber art', '🧵'),
    ('Ceramics', 'artist', 'Pottery, stoneware, porcelain, and terracotta', '🏺'),
    ('Printmaking', 'artist', 'Screen printing, etching, woodcut, and lithography', '🖨️'),
    ('Illustration', 'artist', 'Editorial illustration, book art, and character art', '🖌️'),
    ('Street Art', 'artist', 'Urban graffiti, stencil, and public space art', '🏙️'),
    ('Mural Art', 'artist', 'Large-scale wall murals and outdoor public art', '🧱'),
    ('Performance Art', 'artist', 'Live artistic expression, interactive acts', '🩰'),
    ('Installation Art', 'artist', 'Immersive, site-specific art installations', '💡'),
    ('Conceptual Art', 'artist', 'Idea-driven contemporary art and experimental works', '🧠'),
    ('Mixed Media', 'artist', 'Multi-medium combinations and experimental artwork', '🔀'),
    ('Collage', 'artist', 'Assembled paper, textures, and cut-and-paste art', '📑'),
    ('Video Game Art', 'artist', 'Concept art, character models, and game world design', '🎮'),
    ('Virtual Reality (VR) Art', 'artist', 'Immersive VR painting and 3D spatial worlds', '🥽'),
    ('Animation', 'artist', '2D, 3D, and stop-motion animation', '🎞️'),
    ('Comic Art', 'artist', 'Comic strips, graphic novels, and sequential art', '🗯️'),
    ('Calligraphy', 'artist', 'Arabic, modern, and classical lettering art', '✍️'),
    ('Jewellery Design', 'artist', 'Handmade precious jewellery and gem craftsmanship', '💍'),
    ('Glass Art', 'artist', 'Stained glass, blown glass, and glass sculptures', '🪟'),
    ('Wood Art', 'artist', 'Wood carving, marquetry, and timber sculpture', '🪵'),
    ('Metal Art', 'artist', 'Forged metal, welding, wire art, and metalcraft', '⚙️'),
    ('Puppetry', 'artist', 'Marionettes, shadow puppets, and puppet theater', '🎎'),
    ('Opera', 'artist', 'Classical operatic performance and vocal arts', '🎼'),
    ('Ballet', 'artist', 'Classical and modern ballet dance performance', '🩰'),
    ('Musical Theatre', 'artist', 'Stage musicals blending singing, acting, and dance', '🎤'),
    ('Experimental Art', 'artist', 'Avant-garde boundary-pushing artistic explorations', '🧪'),
    ('Land Art', 'artist', 'Earth art, nature-integrated sculptures and topography', '🏞️'),
    ('Environmental Art', 'artist', 'Eco-conscious art addressing nature and sustainability', '🌿'),
    ('Body Art', 'artist', 'Body painting, henna, and creative epidermal art', '🎨'),
    ('Jewellery and Accessory Design', 'artist', 'Fine jewellery, headpieces, and fashion accessories', '👑')
]

add_url = 'https://technestpartners.com/api/api.php?resource=categories'
headers = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {token}',
    'User-Agent': 'Mozilla/5.0'
}

success_count = 0
for idx, (name, ctype, desc, emoji) in enumerate(categories, 1):
    payload = json.dumps({
        'name': name,
        'type': ctype,
        'description': desc,
        'emoji': emoji
    }).encode('utf-8')

    req = urllib.request.Request(add_url, data=payload, headers=headers)
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            if data.get('status') == 'success' or data.get('success'):
                success_count += 1
                print(f"[{idx}/{len(categories)}] Added/Updated: {emoji} {name}")
            else:
                print(f"[{idx}/{len(categories)}] Failed: {name} - {data.get('message')}")
    except Exception as e:
        print(f"[{idx}/{len(categories)}] Error on {name}: {e}")
    time.sleep(0.1)

print(f"\nFinished seeding! Successfully processed {success_count}/{len(categories)} categories.")
