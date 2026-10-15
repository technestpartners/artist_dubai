import os
import math
from PIL import Image

LOGO_SOURCE = r'C:\Users\hp\.gemini\antigravity-ide\brain\58d9ca4b-d783-418a-8193-2a9ad544556f\.user_uploaded\media_1792061986736.png'
BG_COLOR = (0x36, 0x0E, 0x55, 255) # #360E55

def main():
    print(f"Loading logo from: {LOGO_SOURCE}")
    raw_logo = Image.open(LOGO_SOURCE).convert('RGBA')

    # Bounding box of artwork
    bbox = raw_logo.getbbox()
    cropped_logo = raw_logo.crop(bbox)
    crop_w, crop_h = cropped_logo.size
    aspect = crop_w / crop_h
    print(f"Cropped logo size: {crop_w}x{crop_h}, aspect: {aspect:.3f}")

    # 1. Save transparent logo asset
    os.makedirs('assets/images', exist_ok=True)
    raw_logo.save('assets/images/app_logo_direct.png', format='PNG', optimize=True)
    print("Saved assets/images/app_logo_direct.png")

    # 2. Helper to build solid #360E55 canvas with centered logo
    def make_splash(width, height, logo_w):
        canvas = Image.new('RGBA', (width, height), BG_COLOR)
        logo_h = int(logo_w / aspect)
        scaled = cropped_logo.resize((logo_w, logo_h), Image.Resampling.LANCZOS)
        x = (width - logo_w) // 2
        y = (height - logo_h) // 2
        canvas.paste(scaled, (x, y), scaled)
        return canvas

    # Flutter Assets
    targets_flutter = [
        ('assets/images/splash_screen_art.png', 1080, 1920, 520),
        ('assets/images/splash_screen_art_standard.png', 1080, 1920, 520),
        ('assets/images/splash_screen_art_modern.png', 1080, 2340, 520),
        ('assets/images/splash_screen_art_tall.png', 1080, 2400, 520),
        ('assets/images/splash_screen_art_tablet.png', 1536, 2048, 640),
        ('assets/images/splash_screen_art_wide.png', 1920, 1080, 480),
    ]

    for path, w, h, lw in targets_flutter:
        img = make_splash(w, h, lw)
        img.save(path, format='PNG', optimize=True)
        print(f"Generated Flutter splash: {path} ({w}x{h})")

    # Android Native Drawables
    targets_android = [
        ('android/app/src/main/res/drawable/launch_image.png', 1080, 1920, 520),
        ('android/app/src/main/res/drawable-v21/launch_image.png', 1080, 1920, 520),
        ('android/app/src/main/res/drawable-nodpi/launch_image.png', 1080, 1920, 520),
        ('android/app/src/main/res/drawable-land/launch_image.png', 1920, 1080, 480),
        ('android/app/src/main/res/drawable-long/launch_image.png', 1080, 2400, 520),
        ('android/app/src/main/res/drawable-sw600dp/launch_image.png', 1536, 2048, 640),
    ]

    for path, w, h, lw in targets_android:
        dir_name = os.path.dirname(path)
        os.makedirs(dir_name, exist_ok=True)
        img = make_splash(w, h, lw)
        img.save(path, format='PNG', optimize=True)
        print(f"Generated Android launch image: {path} ({w}x{h})")

    # Android 12+ Adaptive Splash Icon (432x432, safe within 288-dp circle)
    # Target logo width ~220px to stay cleanly within the 288dp circle
    adaptive_canvas = Image.new('RGBA', (432, 432), (0, 0, 0, 0))
    adapt_w = 216
    adapt_h = int(adapt_w / aspect)
    scaled_adapt = cropped_logo.resize((adapt_w, adapt_h), Image.Resampling.LANCZOS)
    ax = (432 - adapt_w) // 2
    ay = (432 - adapt_h) // 2
    adaptive_canvas.paste(scaled_adapt, (ax, ay), scaled_adapt)
    adaptive_path = 'android/app/src/main/res/drawable-nodpi/launch_splash_icon.png'
    adaptive_canvas.save(adaptive_path, format='PNG', optimize=True)
    print(f"Generated Android 12 adaptive icon: {adaptive_path} (432x432)")

    # iOS Native Launch Images
    targets_ios = [
        ('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png', 1080, 1920, 520),
        ('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png', 1080, 1920, 520),
        ('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png', 1080, 1920, 520),
    ]

    for path, w, h, lw in targets_ios:
        dir_name = os.path.dirname(path)
        os.makedirs(dir_name, exist_ok=True)
        img = make_splash(w, h, lw)
        img.save(path, format='PNG', optimize=True)
        print(f"Generated iOS LaunchImage: {path} ({w}x{h})")

    print("\nAll splash variants generated successfully with background #360E55!")

if __name__ == '__main__':
    main()
