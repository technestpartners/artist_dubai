#!/usr/bin/env python3
import os
import sys
import glob
import shutil
import plistlib
import re

def main():
    bundle_id = os.environ.get("BUNDLE_ID", "com.imbu.Dubai-Artists")
    team_id = os.environ.get("DEVELOPMENT_TEAM", "VDL4YWPJJ2")
    home = os.path.expanduser("~")

    legacy_dir = os.path.join(home, "Library", "MobileDevice", "Provisioning Profiles")
    xcode16_dir = os.path.join(home, "Library", "Developer", "Xcode", "UserData", "Provisioning Profiles")

    os.makedirs(legacy_dir, exist_ok=True)
    os.makedirs(xcode16_dir, exist_ok=True)

    # Find all downloaded provisioning profiles across the entire HOME directory
    all_profiles = set()
    for root, dirs, files in os.walk(home):
        for f in files:
            if f.endswith(".mobileprovision"):
                all_profiles.add(os.path.join(root, f))

    # Copy all found profiles to BOTH legacy_dir and xcode16_dir
    for p in all_profiles:
        for target_dir in [legacy_dir, xcode16_dir]:
            dest = os.path.join(target_dir, os.path.basename(p))
            if not os.path.exists(dest) or os.path.getsize(dest) != os.path.getsize(p):
                shutil.copy2(p, dest)
                print(f"[INFO] Synced profile {os.path.basename(p)} -> {target_dir}")

    profiles = list(all_profiles)
    if not profiles:
        print("[WARNING] No .mobileprovision files found anywhere under $HOME!")
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

    # Export environment for subsequent shell steps
    for env_dest in ["/tmp/profile_env.sh", os.path.join(home, "profile_env.sh")]:
        try:
            with open(env_dest, "w", encoding="utf-8") as f:
                f.write(f'export PROFILE_NAME="{profile_name}"\n')
                f.write(f'export PROFILE_UUID="{profile_uuid}"\n')
            print(f"[INFO] Written profile environment variables to {env_dest}")
        except Exception as e:
            print(f"[WARNING] Could not write to {env_dest}: {e}")

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
        if target_token in content:
            before, target_block = content.split(target_token, 1)
            end_settings = target_block.find("};")
            if end_settings != -1:
                settings = target_block[:end_settings]
                rest = target_block[end_settings:]
                settings = re.sub(r'PROVISIONING_PROFILE_SPECIFIER\s*=\s*[^;]+;\n?', '', settings)
                settings = re.sub(r'PROVISIONING_PROFILE\s*=\s*[^;]+;\n?', '', settings)
                dev_team = f"DEVELOPMENT_TEAM = {team_id};"
                if dev_team in settings:
                    settings = settings.replace(dev_team, f"{dev_team}\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = \"{profile_name}\";", 1)
                else:
                    settings += f"\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = \"{profile_name}\";\n"
                with open(pbxproj_path, "w", encoding="utf-8") as f:
                    f.write(before + target_token + settings + rest)
                print(f"[INFO] Injected PROVISIONING_PROFILE_SPECIFIER = '{profile_name}' into project.pbxproj Release target")

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
