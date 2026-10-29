#!/usr/bin/env python3
import os
import sys
import glob
import shutil
import plistlib

def main():
    bundle_id = os.environ.get("BUNDLE_ID", "com.imbu.Dubai-Artists")
    team_id = os.environ.get("DEVELOPMENT_TEAM", "VDL4YWPJJ2")
    home = os.path.expanduser("~")

    legacy_dir = os.path.join(home, "Library", "MobileDevice", "Provisioning Profiles")
    xcode16_dir = os.path.join(home, "Library", "Developer", "Xcode", "UserData", "Provisioning Profiles")

    os.makedirs(legacy_dir, exist_ok=True)
    os.makedirs(xcode16_dir, exist_ok=True)

    # Sync profiles between legacy and Xcode 16 directories
    for src, dst in [(legacy_dir, xcode16_dir), (xcode16_dir, legacy_dir)]:
        for f in glob.glob(os.path.join(src, "*.mobileprovision")):
            target = os.path.join(dst, os.path.basename(f))
            if not os.path.exists(target):
                shutil.copy2(f, target)

    # Find all downloaded provisioning profiles
    profiles = glob.glob(os.path.join(legacy_dir, "*.mobileprovision")) + \
               glob.glob(os.path.join(xcode16_dir, "*.mobileprovision"))

    if not profiles:
        print("[WARNING] No .mobileprovision files found in MobileDevice or Xcode 16 UserData!")
        return

    # Pick the newest profile
    profiles.sort(key=os.path.getmtime, reverse=True)
    latest_profile_path = profiles[0]

    profile_name = None
    profile_uuid = None

    try:
        with open(latest_profile_path, "rb") as f:
            raw = f.read()
        start = raw.find(b"<?xml")
        end = raw.find(b"</plist>")
        if start != -1 and end != -1:
            end += len(b"</plist>")
            data = plistlib.loads(raw[start:end])
            profile_name = data.get("Name")
            profile_uuid = data.get("UUID")
    except Exception as e:
        print(f"[ERROR] Failed to parse {latest_profile_path}: {e}")

    if not profile_name:
        print(f"[WARNING] Could not parse profile name from {latest_profile_path}")
        return

    print(f"[INFO] Found Provisioning Profile: '{profile_name}' (UUID: {profile_uuid})")

    # 1. Update ios/Flutter/Release.xcconfig
    xcconfig_path = os.path.join("ios", "Flutter", "Release.xcconfig")
    if os.path.exists(xcconfig_path):
        with open(xcconfig_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        # Remove any existing specifier lines
        lines = [l for l in lines if not l.startswith("PROVISIONING_PROFILE_SPECIFIER") and not l.startswith("PROVISIONING_PROFILE =")]
        lines.append(f"PROVISIONING_PROFILE_SPECIFIER = {profile_name}\n")
        if profile_uuid:
            lines.append(f"PROVISIONING_PROFILE = {profile_uuid}\n")
        with open(xcconfig_path, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print(f"[INFO] Updated {xcconfig_path} with specifier '{profile_name}'")

    # 2. Update ios/Runner.xcodeproj/project.pbxproj Release target directly
    pbxproj_path = os.path.join("ios", "Runner.xcodeproj", "project.pbxproj")
    if os.path.exists(pbxproj_path):
        with open(pbxproj_path, "r", encoding="utf-8") as f:
            content = f.read()
        target_token = "97C147071CF9000F007C117D /* Release */"
        if target_token in content and f'PROVISIONING_PROFILE_SPECIFIER = "{profile_name}";' not in content:
            parts = content.split(target_token, 1)
            # Remove any older specifier in the Release target
            sub = parts[1]
            anchor = f"DEVELOPMENT_TEAM = {team_id};"
            if anchor in sub:
                sub = sub.replace(anchor, f"{anchor}\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = \"{profile_name}\";", 1)
                with open(pbxproj_path, "w", encoding="utf-8") as f:
                    f.write(parts[0] + target_token + sub)
                print(f"[INFO] Injected PROVISIONING_PROFILE_SPECIFIER directly into project.pbxproj Release target")

    # 3. Generate /Users/builder/export_options.plist and ios/ExportOptions.plist
    export_dict = {
        "method": "app-store",
        "teamID": team_id,
        "signingStyle": "manual",
        "uploadBitcode": False,
        "uploadSymbols": True,
        "manageAppVersionAndBuildNumber": False,
        "provisioningProfiles": {
            bundle_id: profile_name
        }
    }

    for export_dest in ["/Users/builder/export_options.plist", os.path.join("ios", "ExportOptions.plist")]:
        try:
            dest_dir = os.path.dirname(export_dest)
            if dest_dir:
                os.makedirs(dest_dir, exist_ok=True)
            with open(export_dest, "wb") as f:
                f.write(plistlib.dumps(export_dict))
            print(f"[INFO] Generated {export_dest} with bundle ID '{bundle_id}' mapped to '{profile_name}'")
        except Exception as e:
            print(f"[WARNING] Could not write {export_dest}: {e}")

if __name__ == "__main__":
    main()
