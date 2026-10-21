import os
from PIL import Image

def generate_variant(orig_path, target_path, target_w, target_h, mode='standard_exact'):
    orig = Image.open(orig_path).convert('RGBA')
    orig_w, orig_h = orig.size

    # Base dark violet matching AppColors and android splash_background (#160230)
    canvas = Image.new('RGBA', (target_w, target_h), (22, 2, 48, 255))

    if mode == 'standard_exact':
        art = orig.resize((target_w, target_h), Image.Resampling.LANCZOS)
        dir_name = os.path.dirname(target_path)
        if dir_name:
            os.makedirs(dir_name, exist_ok=True)
        art.save(target_path, format='PNG', optimize=True)
        print(f'Generated {target_path} (exact fit): {target_w}x{target_h}')
        return

    elif mode == 'tall_portrait':
        scale = target_w / orig_w
        art_w = target_w
        art_h = int(orig_h * scale)
        art = orig.resize((art_w, art_h), Image.Resampling.LANCZOS)

        extra_h = target_h - art_h
        art_y = int(extra_h * 0.44) # Golden ratio centering
        art_x = 0

        # 1. Fill top area with smooth sky lighting
        top_row = [art.getpixel((x, 0)) for x in range(art_w)]
        for y in range(art_y):
            t = y / max(1, art_y)
            curve = t * t * (3 - 2 * t)
            for x in range(target_w):
                c = top_row[x]
                top_sky = (int(c[0] * 0.72), int(c[1] * 0.72), int(c[2] * 0.72), 255)
                r = int(top_sky[0] * (1 - curve) + c[0] * curve)
                g = int(top_sky[1] * (1 - curve) + c[1] * curve)
                b = int(top_sky[2] * (1 - curve) + c[2] * curve)
                canvas.putpixel((x, y), (r, g, b, 255))

        # 2. Fill bottom area with reflective water floor
        bot_h = target_h - (art_y + art_h)
        bot_samples = [
            [art.getpixel((x, art_h - 1 - dy)) for x in range(art_w)]
            for dy in range(min(20, art_h))
        ]

        for y_offset in range(bot_h):
            cy = art_y + art_h + y_offset
            t = y_offset / max(1, bot_h)
            curve = t * t * (3 - 2 * t)

            for x in range(target_w):
                sample_idx = min(len(bot_samples) - 1, int(t * (len(bot_samples) - 1)))
                c = bot_samples[sample_idx][x]
                dist_from_center = abs(x - target_w // 2) / (target_w // 2)
                floor_r = int(45 * (1 - dist_from_center * 0.55))
                floor_g = int(4 * (1 - dist_from_center * 0.5))
                floor_b = int(88 * (1 - dist_from_center * 0.5))

                r = int(c[0] * (1 - curve) + floor_r * curve)
                g = int(c[1] * (1 - curve) + floor_g * curve)
                b = int(c[2] * (1 - curve) + floor_b * curve)
                canvas.putpixel((x, cy), (r, g, b, 255))

        # 3. Paste main artwork
        canvas.paste(art, (art_x, art_y), art)
        dir_name = os.path.dirname(target_path)
        if dir_name:
            os.makedirs(dir_name, exist_ok=True)
        canvas.save(target_path, format='PNG', optimize=True)
        print(f'Generated {target_path} (tall seamless): {target_w}x{target_h}')
        return

    elif mode == 'tablet':
        scale = target_h / orig_h
        art_w = int(orig_w * scale)
        art_h = target_h
        art = orig.resize((art_w, art_h), Image.Resampling.LANCZOS)
        art_x = (target_w - art_w) // 2
        art_y = 0

        for y in range(art_h):
            left_c = art.getpixel((0, y))
            right_c = art.getpixel((art_w - 1, y))
            for x in range(art_x):
                t = x / max(1, art_x)
                curve = t * t * (3 - 2 * t)
                r = int(22 * (1 - curve) + left_c[0] * curve)
                g = int(2 * (1 - curve) + left_c[1] * curve)
                b = int(48 * (1 - curve) + left_c[2] * curve)
                canvas.putpixel((x, y), (r, g, b, 255))
            for x in range(art_x + art_w, target_w):
                t = (x - (art_x + art_w)) / max(1, target_w - (art_x + art_w))
                curve = (1 - t) * (1 - t) * (3 - 2 * (1 - t))
                r = int(22 * (1 - curve) + right_c[0] * curve)
                g = int(2 * (1 - curve) + right_c[1] * curve)
                b = int(48 * (1 - curve) + right_c[2] * curve)
                canvas.putpixel((x, y), (r, g, b, 255))

        canvas.paste(art, (art_x, art_y), art)
        dir_name = os.path.dirname(target_path)
        if dir_name:
            os.makedirs(dir_name, exist_ok=True)
        canvas.save(target_path, format='PNG', optimize=True)
        print(f'Generated {target_path} (tablet seamless): {target_w}x{target_h}')
        return

    elif mode == 'wide':
        scale = target_h / orig_h
        art_w = int(orig_w * scale)
        art_h = target_h
        art = orig.resize((art_w, art_h), Image.Resampling.LANCZOS)
        art_x = (target_w - art_w) // 2
        art_y = 0

        for y in range(art_h):
            left_c = art.getpixel((0, y))
            right_c = art.getpixel((art_w - 1, y))
            for x in range(art_x):
                t = x / max(1, art_x)
                curve = t * t * (3 - 2 * t)
                r = int(20 * (1 - curve) + left_c[0] * curve)
                g = int(2 * (1 - curve) + left_c[1] * curve)
                b = int(45 * (1 - curve) + left_c[2] * curve)
                canvas.putpixel((x, y), (r, g, b, 255))
            for x in range(art_x + art_w, target_w):
                t = (x - (art_x + art_w)) / max(1, target_w - (art_x + art_w))
                curve = (1 - t) * (1 - t) * (3 - 2 * (1 - t))
                r = int(20 * (1 - curve) + right_c[0] * curve)
                g = int(2 * (1 - curve) + right_c[1] * curve)
                b = int(45 * (1 - curve) + right_c[2] * curve)
                canvas.putpixel((x, y), (r, g, b, 255))

        canvas.paste(art, (art_x, art_y), art)
        dir_name = os.path.dirname(target_path)
        if dir_name:
            os.makedirs(dir_name, exist_ok=True)
        canvas.save(target_path, format='PNG', optimize=True)
        print(f'Generated {target_path} (wide seamless): {target_w}x{target_h}')
        return

def main():
    orig_path = 'assets/images/splash_screen_art.original.png'
    if not os.path.exists(orig_path):
        raise FileNotFoundError(f"Original splash not found at: {orig_path}")

    print("Generating comprehensive splash variants for all screen aspect ratios, sizes, and types...")

    # 1. Flutter Assets
    flutter_variants = [
        ('assets/images/splash_screen_art_tall.png', 1080, 2400, 'tall_portrait'),
        ('assets/images/splash_screen_art_modern.png', 1080, 2340, 'tall_portrait'),
        ('assets/images/splash_screen_art_standard.png', 1080, 1920, 'standard_exact'),
        ('assets/images/splash_screen_art.png', 1080, 1920, 'standard_exact'),
        ('assets/images/splash_screen_art_tablet.png', 1536, 2048, 'tablet'),
        ('assets/images/splash_screen_art_wide.png', 1920, 1080, 'wide'),
        # Foldable & Flip screens - identical unified assets
        ('assets/images/splash_screen_art_fold_inner.png', 2048, 2048, 'tablet'),
        ('assets/images/splash_screen_art_fold_cover.png', 2048, 2048, 'tablet'),
    ]

    for path, w, h, mode in flutter_variants:
        generate_variant(orig_path, path, w, h, mode)

    # 2. Android Native Drawables (Configuration Qualifiers)
    android_variants = [
        ('android/app/src/main/res/drawable/launch_image.png', 1080, 1920, 'standard_exact'),
        ('android/app/src/main/res/drawable-v21/launch_image.png', 1080, 1920, 'standard_exact'),
        ('android/app/src/main/res/drawable-nodpi/launch_image.png', 1080, 1920, 'standard_exact'),
        ('android/app/src/main/res/drawable-long/launch_image.png', 1080, 2400, 'tall_portrait'),
        ('android/app/src/main/res/drawable-land/launch_image.png', 1920, 1080, 'wide'),
        ('android/app/src/main/res/drawable-sw600dp/launch_image.png', 1536, 2048, 'tablet'),
        # Android Foldable qualifiers
        ('android/app/src/main/res/drawable-sw720dp/launch_image.png', 2048, 2048, 'tablet'),
    ]

    for path, w, h, mode in android_variants:
        generate_variant(orig_path, path, w, h, mode)

    # 3. Android Screen Density Buckets
    android_densities = [
        ('android/app/src/main/res/drawable-mdpi/launch_image.png', 360, 640, 'standard_exact'),
        ('android/app/src/main/res/drawable-hdpi/launch_image.png', 540, 960, 'standard_exact'),
        ('android/app/src/main/res/drawable-xhdpi/launch_image.png', 720, 1280, 'standard_exact'),
        ('android/app/src/main/res/drawable-xxhdpi/launch_image.png', 1080, 1920, 'standard_exact'),
        ('android/app/src/main/res/drawable-xxxhdpi/launch_image.png', 1440, 2560, 'standard_exact'),
    ]

    for path, w, h, mode in android_densities:
        generate_variant(orig_path, path, w, h, mode)

    # 4. Android 12+ (API 31+) Adaptive Splash Icon
    logo_path = 'assets/images/header_logo.png'
    logo_img = Image.open(logo_path).convert('RGBA')
    emblem_scaled = logo_img.resize((260, 260), Image.Resampling.LANCZOS)

    adaptive_canvas = Image.new('RGBA', (432, 432), (0, 0, 0, 0))
    ax = (432 - 260) // 2
    ay = (432 - 260) // 2
    adaptive_canvas.paste(emblem_scaled, (ax, ay), emblem_scaled)

    for ad_path in [
        'android/app/src/main/res/drawable-nodpi/launch_splash_icon.png',
        'android/app/src/main/res/drawable/launch_splash_icon.png',
    ]:
        dir_name = os.path.dirname(ad_path)
        if dir_name:
            os.makedirs(dir_name, exist_ok=True)
        adaptive_canvas.save(ad_path, format='PNG', optimize=True)
        print(f'Generated {ad_path} (432x432 adaptive icon)')

    # 5. iOS Native Launch Images
    ios_variants = [
        ('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png', 1080, 1920, 'standard_exact'),
        ('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png', 1080, 1920, 'standard_exact'),
        ('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png', 1242, 2688, 'tall_portrait'),
    ]

    for path, w, h, mode in ios_variants:
        generate_variant(orig_path, path, w, h, mode)

    print("\n[SUCCESS] All splash variants generated across all screen aspect ratios, sizes, and platforms!")

if __name__ == '__main__':
    main()
