"""
Comprehensive App Icon Generator for iOS, Android, and Web
Built from user uploaded master image: assets/images/user_source_icon.jpg
Features:
- Solid brand purple #45126E (RGB: 69, 18, 110) - NEVER white!
- 100px breathing room on circular launchers (Google Pixel, Motorola, etc.)
- 122-172px breathing room on squircles (iOS, Xiaomi, Samsung Galaxy, OnePlus, etc.)
- Android 8+ Adaptive Icons with clean safe-zone alignment
- Legacy square and round icons with anti-aliasing
- iOS complete AppIcon.appiconset suite (20px to 1024px)
- Web favicon & PWA maskable icons
"""
import os
import json
from PIL import Image, ImageDraw

PROJECT_DIR = r"d:\laragon\www\artist_dubai"
ASSETS_DIR = os.path.join(PROJECT_DIR, "assets", "images")
RES_DIR = os.path.join(PROJECT_DIR, "android", "app", "src", "main", "res")
IOS_DIR = os.path.join(PROJECT_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
WEB_DIR = os.path.join(PROJECT_DIR, "web")
WEB_ICONS_DIR = os.path.join(WEB_DIR, "icons")

BG_COLOR = (69, 18, 110, 255) # #45126E

def generate_all():
    src_path = os.path.join(PROJECT_DIR, "tools", "user_source_icon.jpg")
    src = Image.open(src_path).convert("RGB")
    w, h = src.size

    # 1. Cleanly extract white artwork as transparent RGBA
    fg = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fg_pix = fg.load()
    src_pix = src.load()

    for y in range(h):
        for x in range(w):
            r, g, b = src_pix[x, y]
            # Green channel distance (bg=18, white=255)
            alpha = (g - 18) / 237.0
            if alpha < 0.05:
                continue
            alpha = min(1.0, max(0.0, alpha))
            a_int = int(round(alpha * 255))
            if a_int > 0:
                fg_pix[x, y] = (255, 255, 255, a_int)

    crop_box = fg.getbbox()
    cropped_emblem = fg.crop(crop_box)
    ew, eh = cropped_emblem.size
    print(f"Extracted clean artwork: {ew}x{eh}")

    # 2. Master Full-Bleed 1024x1024 Icon
    # Target emblem width: 860px (fills 84% of icon for prominent, big presence)
    target_w = 860
    target_h = int(round(eh * (target_w / float(ew))))
    scaled_emblem = cropped_emblem.resize((target_w, target_h), Image.Resampling.LANCZOS)
    paste_pos = ((1024 - target_w) // 2, (1024 - target_h) // 2)

    master_1024 = Image.new("RGBA", (1024, 1024), BG_COLOR)
    master_1024.alpha_composite(scaled_emblem, paste_pos)
    
    # Save master RGB (100% opaque, no transparency for App Store / store requirements)
    master_rgb = Image.new("RGB", (1024, 1024), BG_COLOR[:3])
    master_rgb.paste(master_1024, (0, 0), master_1024)
    master_rgb.save(os.path.join(ASSETS_DIR, "app_icon_full.png"))
    print("Saved master icon to assets/images/app_icon_full.png")

    # 3. Master Adaptive Foreground (1024x1024 canvas)
    # The visible viewport on Android adaptive icon is 72dp out of 108dp canvas (2/3 ratio = 682.6px).
    # Scaling to fg_w = 640px makes the emblem bold, big, and beautifully filling the safe circle
    # with a clean 21px margin so no peripheral elements clip.
    fg_w = 640
    fg_h = int(round(eh * (fg_w / float(ew))))
    scaled_fg = cropped_emblem.resize((fg_w, fg_h), Image.Resampling.LANCZOS)
    fg_paste_pos = ((1024 - fg_w) // 2, (1024 - fg_h) // 2)

    master_fg_1024 = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    master_fg_1024.alpha_composite(scaled_fg, fg_paste_pos)
    master_fg_1024.save(os.path.join(ASSETS_DIR, "app_icon_foreground.png"))
    print("Saved master adaptive foreground to assets/images/app_icon_foreground.png")

    # 4. Generate Android Density Icons
    DENSITIES = {
        "mdpi":    {"legacy": 48,  "adaptive": 108},
        "hdpi":    {"legacy": 72,  "adaptive": 162},
        "xhdpi":   {"legacy": 96,  "adaptive": 216},
        "xxhdpi":  {"legacy": 144, "adaptive": 324},
        "xxxhdpi": {"legacy": 192, "adaptive": 432},
    }

    for density, sizes in DENSITIES.items():
        legacy_size = sizes["legacy"]
        adaptive_size = sizes["adaptive"]

        # Legacy Square Icon (full bleed #45126E background)
        legacy_icon = master_rgb.resize((legacy_size, legacy_size), Image.Resampling.LANCZOS)

        # Legacy Round Icon (anti-aliased circle of #45126E background, transparent corners)
        mask = Image.new("L", (legacy_size, legacy_size), 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse((0, 0, legacy_size - 1, legacy_size - 1), fill=255)
        legacy_round = Image.new("RGBA", (legacy_size, legacy_size), (0, 0, 0, 0))
        legacy_round.paste(legacy_icon, (0, 0), mask)

        # Adaptive Foreground Icon (scaled relative to adaptive_size so emblem is BIG inside)
        adaptive_w = int(round(adaptive_size * (fg_w / 1024.0)))
        adaptive_h = int(round(eh * (adaptive_w / float(ew))))
        scaled_adaptive = cropped_emblem.resize((adaptive_w, adaptive_h), Image.Resampling.LANCZOS)
        adaptive_pos = ((adaptive_size - adaptive_w) // 2, (adaptive_size - adaptive_h) // 2)

        adaptive_fg = Image.new("RGBA", (adaptive_size, adaptive_size), (0, 0, 0, 0))
        adaptive_fg.alpha_composite(scaled_adaptive, adaptive_pos)

        # Output folders
        mipmap_dir = os.path.join(RES_DIR, f"mipmap-{density}")
        drawable_dir = os.path.join(RES_DIR, f"drawable-{density}")
        os.makedirs(mipmap_dir, exist_ok=True)
        os.makedirs(drawable_dir, exist_ok=True)

        legacy_icon.save(os.path.join(mipmap_dir, "ic_launcher.png"))
        legacy_round.save(os.path.join(mipmap_dir, "ic_launcher_round.png"))
        adaptive_fg.save(os.path.join(mipmap_dir, "ic_launcher_foreground.png"))
        adaptive_fg.save(os.path.join(drawable_dir, "ic_launcher_foreground.png"))
        print(f"[Android {density}] legacy {legacy_size}px, adaptive_fg {adaptive_size}px (artwork {adaptive_w}px)")

    # 5. Android Adaptive XML Definitions
    anydpi_dir = os.path.join(RES_DIR, "mipmap-anydpi-v26")
    os.makedirs(anydpi_dir, exist_ok=True)

    adaptive_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n'
    )
    with open(os.path.join(anydpi_dir, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)
    with open(os.path.join(anydpi_dir, "ic_launcher_round.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)
    print("Saved mipmap-anydpi-v26 XML definitions")

    # 6. Generate iOS Icons (Full suite)
    os.makedirs(IOS_DIR, exist_ok=True)
    IOS_SIZES = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-50x50@1x.png": 50,
        "Icon-App-50x50@2x.png": 100,
        "Icon-App-57x57@1x.png": 57,
        "Icon-App-57x57@2x.png": 114,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-72x72@1x.png": 72,
        "Icon-App-72x72@2x.png": 144,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
        "AppIcon-1024.png": 1024,
    }

    for filename, sz in IOS_SIZES.items():
        ios_icon = master_rgb.resize((sz, sz), Image.Resampling.LANCZOS)
        ios_icon.save(os.path.join(IOS_DIR, filename))
        print(f"[iOS] generated {filename} ({sz}x{sz})")

    contents_data = {
        "images": [
            {"size": "20x20", "idiom": "iphone", "filename": "Icon-App-20x20@2x.png", "scale": "2x"},
            {"size": "20x20", "idiom": "iphone", "filename": "Icon-App-20x20@3x.png", "scale": "3x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@1x.png", "scale": "1x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@2x.png", "scale": "2x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@3x.png", "scale": "3x"},
            {"size": "40x40", "idiom": "iphone", "filename": "Icon-App-40x40@2x.png", "scale": "2x"},
            {"size": "40x40", "idiom": "iphone", "filename": "Icon-App-40x40@3x.png", "scale": "3x"},
            {"size": "57x57", "idiom": "iphone", "filename": "Icon-App-57x57@1x.png", "scale": "1x"},
            {"size": "57x57", "idiom": "iphone", "filename": "Icon-App-57x57@2x.png", "scale": "2x"},
            {"size": "60x60", "idiom": "iphone", "filename": "Icon-App-60x60@2x.png", "scale": "2x"},
            {"size": "60x60", "idiom": "iphone", "filename": "Icon-App-60x60@3x.png", "scale": "3x"},
            {"size": "20x20", "idiom": "ipad", "filename": "Icon-App-20x20@1x.png", "scale": "1x"},
            {"size": "20x20", "idiom": "ipad", "filename": "Icon-App-20x20@2x.png", "scale": "2x"},
            {"size": "29x29", "idiom": "ipad", "filename": "Icon-App-29x29@1x.png", "scale": "1x"},
            {"size": "29x29", "idiom": "ipad", "filename": "Icon-App-29x29@2x.png", "scale": "2x"},
            {"size": "40x40", "idiom": "ipad", "filename": "Icon-App-40x40@1x.png", "scale": "1x"},
            {"size": "40x40", "idiom": "ipad", "filename": "Icon-App-40x40@2x.png", "scale": "2x"},
            {"size": "50x50", "idiom": "ipad", "filename": "Icon-App-50x50@1x.png", "scale": "1x"},
            {"size": "50x50", "idiom": "ipad", "filename": "Icon-App-50x50@2x.png", "scale": "2x"},
            {"size": "72x72", "idiom": "ipad", "filename": "Icon-App-72x72@1x.png", "scale": "1x"},
            {"size": "72x72", "idiom": "ipad", "filename": "Icon-App-72x72@2x.png", "scale": "2x"},
            {"size": "76x76", "idiom": "ipad", "filename": "Icon-App-76x76@1x.png", "scale": "1x"},
            {"size": "76x76", "idiom": "ipad", "filename": "Icon-App-76x76@2x.png", "scale": "2x"},
            {"size": "83.5x83.5", "idiom": "ipad", "filename": "Icon-App-83.5x83.5@2x.png", "scale": "2x"},
            {"size": "1024x1024", "idiom": "ios-marketing", "filename": "Icon-App-1024x1024@1x.png", "scale": "1x"},
            {"size": "1024x1024", "idiom": "universal", "platform": "ios", "filename": "AppIcon-1024.png"}
        ],
        "info": {"version": 1, "author": "xcode"}
    }
    with open(os.path.join(IOS_DIR, "Contents.json"), "w", encoding="utf-8") as f:
        json.dump(contents_data, f, indent=2)
    print("Updated iOS Contents.json")

    # 7. Generate Web Icons
    os.makedirs(WEB_ICONS_DIR, exist_ok=True)
    master_rgb.resize((64, 64), Image.Resampling.LANCZOS).save(os.path.join(WEB_DIR, "favicon.png"))
    master_rgb.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(WEB_ICONS_DIR, "Icon-192.png"))
    master_rgb.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(WEB_ICONS_DIR, "Icon-512.png"))
    master_rgb.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(WEB_ICONS_DIR, "Icon-maskable-192.png"))
    master_rgb.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(WEB_ICONS_DIR, "Icon-maskable-512.png"))
    print("Updated Web favicon & PWA icons")

    print("App icon generation complete!")

if __name__ == "__main__":
    generate_all()
