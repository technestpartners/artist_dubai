#!/usr/bin/env python3
import glob
import os
import plistlib
import sys

def main():
    bundle_id = os.environ.get("BUNDLE_ID", "com.imbu.Dubai-Artists")
    team_id = os.environ.get("DEVELOPMENT_TEAM", "VDL4YWPJJ2")

    home = os.path.expanduser("~")
    search_dirs = [
        os.path.join(home, "Library", "MobileDevice", "Provisioning Profiles"),
        os.path.join(home, "Library", "Developer", "Xcode", "UserData", "Provisioning Profiles"),
        os.path.join(home, "Library", "Developer", "Xcode", "UserData"),
        os.path.join(home, "Library", "MobileDevice"),
    ]

    profiles = []
    for d in search_dirs:
        if os.path.isdir(d):
            profiles.extend(glob.glob(os.path.join(d, "*.mobileprovision")))

    # Fallback recursive search if direct directories didn't match
    if not profiles:
        print("[INFO] Searching recursively in Library for .mobileprovision files...")
        lib_dir = os.path.join(home, "Library")
        if os.path.isdir(lib_dir):
            for root, _, files in os.walk(lib_dir):
                for f in files:
                    if f.endswith(".mobileprovision"):
                        profiles.append(os.path.join(root, f))

    if not profiles:
        print("[ERROR] No .mobileprovision files found in MobileDevice or Xcode UserData directories!")
        sys.exit(1)

    # Sort newest first
    profiles.sort(key=os.path.getmtime, reverse=True)

    selected_profile_name = None
    selected_profile_uuid = None

    for p in profiles:
        try:
            with open(p, "rb") as f:
                raw = f.read()
            start = raw.find(b"<?xml")
            end = raw.find(b"</plist>")
            if start != -1 and end != -1:
                end += len(b"</plist>")
                data = plistlib.loads(raw[start:end])
                name = data.get("Name", "")
                uuid = data.get("UUID", "")
                entitlements = data.get("Entitlements", {})
                app_id = entitlements.get("application-identifier", "")
                is_adhoc = entitlements.get("get-task-allow", False)

                print(f"[FOUND PROFILE] Path: {p} | Name: '{name}' | UUID: {uuid} | AppID: {app_id} | AdHoc/Dev: {is_adhoc}")

                # Prefer App Store distribution profiles (get-task-allow is False for App Store)
                if bundle_id in app_id and not is_adhoc:
                    selected_profile_name = name
                    selected_profile_uuid = uuid
                    break
                elif not selected_profile_name and bundle_id in app_id:
                    selected_profile_name = name
                    selected_profile_uuid = uuid
        except Exception as e:
            print(f"[WARN] Error parsing {p}: {e}")

    # Fallback to the newest profile if no specific match
    if not selected_profile_name:
        try:
            with open(profiles[0], "rb") as f:
                raw = f.read()
            start = raw.find(b"<?xml")
            end = raw.find(b"</plist>")
            if start != -1 and end != -1:
                end += len(b"</plist>")
                data = plistlib.loads(raw[start:end])
                selected_profile_name = data.get("Name", "")
                selected_profile_uuid = data.get("UUID", "")
        except Exception:
            pass

    if not selected_profile_name:
        print("[ERROR] Could not extract profile name from any provisioning profile!")
        sys.exit(1)

    print(f"\n>>> Selected Provisioning Profile: '{selected_profile_name}' (UUID: {selected_profile_uuid})")

    export_dict = {
        "method": "app-store",
        "teamID": team_id,
        "signingStyle": "manual",
        "signingCertificate": "Apple Distribution",
        "uploadBitcode": False,
        "uploadSymbols": True,
        "manageAppVersionAndBuildNumber": False,
        "provisioningProfiles": {
            bundle_id: selected_profile_name
        }
    }

    targets = [
        "/Users/builder/export_options.plist",
        os.path.join("ios", "ExportOptions.plist")
    ]

    for target in targets:
        try:
            parent = os.path.dirname(target)
            if parent:
                os.makedirs(parent, exist_ok=True)
            with open(target, "wb") as f:
                f.write(plistlib.dumps(export_dict))
            print(f"[SUCCESS] Wrote export options to: {target}")
        except Exception as e:
            print(f"[WARN] Failed writing to {target}: {e}")

    # Print out content for CI logs
    print("\n=== Generated ExportOptions.plist content ===")
    xml_content = plistlib.dumps(export_dict).decode("utf-8")
    print(xml_content)

if __name__ == "__main__":
    main()
