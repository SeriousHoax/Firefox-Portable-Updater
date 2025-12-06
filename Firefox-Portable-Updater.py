"""
Firefox Portable Updater
Author: SeriousHoax
GitHub: https://github.com/SeriousHoax
License: MIT

Dependencies:
    - 7zr.exe (Required for extraction)
    - aria2c.exe (Optional for faster downloading)
"""

import sys, os, shutil, subprocess, re, json, time, msvcrt
from pathlib import Path
from urllib.request import urlopen, Request
URL = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
def find_7zip():
    base_dir = Path(__file__).parent.absolute()
    path = base_dir / "Dependencies" / "7zr.exe"
    return str(path) if path.exists() else None
def get_version(exe_path):
    ini = exe_path.parent / "application.ini"
    print(f"Debug Local: Checking '{ini}'")
    if ini.exists():
        txt = ini.read_text(errors="ignore")
        m = re.search(r'Version=([^\n]+)', txt)
        if m:
            ver = m.group(1).strip()
            print(f"Debug Local: Found version '{ver}'")
            return ver
        else:
            print("Debug Local: No Version= line found")
    else:
        print("Debug Local: File not found")
    return None
def get_remote_version(url):
    try:
        req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urlopen(req, timeout=10) as r:
            final_url = r.geturl()
            print(f"Debug Remote: URL='{final_url}'")
            m = re.search(r'(\d+\.\d+(?:\.\d+)?)', final_url)
            if m:
                ver = m.group(1)
                print(f"Debug Remote: Found version '{ver}'")
                return ver
            else:
                print("Debug Remote: Regex did not match")
    except Exception as e:
        print(f"Debug Remote: Error - {e}")
    return None
def compare_versions(ver1, ver2):
    if not ver1 or not ver2:
        return False
    v1_parts = [int(x) for x in ver1.split('.')]
    v2_parts = [int(x) for x in ver2.split('.')]
    max_len = max(len(v1_parts), len(v2_parts))
    for i in range(max_len):
        p1 = v1_parts[i] if i < len(v1_parts) else 0
        p2 = v2_parts[i] if i < len(v2_parts) else 0
        if p1 != p2:
            return False
    return True
def find_aria2():
    base_dir = Path(__file__).parent.absolute()
    path = base_dir / "Dependencies" / "aria2c.exe"
    return str(path) if path.exists() else None
def download_with_aria2(url, dest, aria2_path):
    try:
        args = [
            aria2_path,
            url,
            "-o", dest.name,
            "-d", str(dest.parent),
            "-x", "8",
            "-s", "8",
            "-k", "1M",
            "--file-allocation=none",
            "--allow-overwrite=true",
            "--auto-file-renaming=false",
            "--summary-interval=0",
            "--user-agent=Mozilla/5.0"
        ]
        print("Downloading with aria2c (8 connections)...\n")
        result = subprocess.run(args, check=True)
        return result.returncode == 0
    except Exception as e:
        print(f"aria2c download failed: {e}")
        return False
def download(url, dest, aria2_path=None):
    if aria2_path:
        if download_with_aria2(url, dest, aria2_path):
            return
        print("Falling back to default download method...")
    req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urlopen(req, timeout=60) as r, open(dest, 'wb') as f:
        total = int(r.headers.get('content-length', 0))
        downloaded = 0
        while True:
            chunk = r.read(8192)
            if not chunk:
                break
            f.write(chunk)
            downloaded += len(chunk)
            if total:
                print(f"\rDownloading: {downloaded*100//total}%", end='', flush=True)
        if total:
            print()
def disable_updates(base_dir):
    core_dir = base_dir / "Firefox" / "core"
    profile_dir = base_dir / "Firefox" / "profile"
    distribution_dir = core_dir / "distribution"
    distribution_dir.mkdir(exist_ok=True)
    policies = {
        "policies": {
            "DisableAppUpdate": True,
            "ManualAppUpdateOnly": True
        }
    }
    policies_file = distribution_dir / "policies.json"
    policies_file.write_text(json.dumps(policies, indent=2))
    print("Enterprise policies configured (updates disabled)")
    prefs_js = profile_dir / "prefs.js"
    prefs_content = '''user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("app.update.enabled", false);
user_pref("app.update.auto", false);
user_pref("app.update.checkInstallTime", false);
user_pref("app.update.service.enabled", false);
user_pref("app.update.staging.enabled", false);
user_pref("app.update.silent", false);
'''
    if prefs_js.exists():
        existing = prefs_js.read_text()
        if "app.update.enabled" not in existing:
            prefs_js.write_text(existing + "\n" + prefs_content)
    else:
        prefs_js.write_text(prefs_content)
    print("Profile preferences configured (updates disabled)")
def create_shortcut(base_dir):
    shortcut_path = base_dir / "Firefox Portable.lnk"
    exe_path = base_dir / "Firefox" / "core" / "firefox.exe"
    profile_path = base_dir / "Firefox" / "profile"
    if not exe_path.exists():
        return
    ps_script = f"""
$ws = New-Object -ComObject WScript.Shell
$shortcut = $ws.CreateShortcut('{shortcut_path}')
$shortcut.TargetPath = '{exe_path}'
$shortcut.Arguments = '-profile "{profile_path}" -no-remote'
$shortcut.WorkingDirectory = '{exe_path.parent}'
$shortcut.IconLocation = '{exe_path}'
$shortcut.Save()
"""
    try:
        subprocess.run(["powershell", "-Command", ps_script], 
                      check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"Shortcut created: {shortcut_path}")
    except:
        print("Warning: Could not create shortcut")
def install_firefox(base_dir, seven, aria2_path=None):
    install_dir = base_dir / "Firefox"
    core_dir = install_dir / "core"
    profile_dir = install_dir / "profile"
    exe = core_dir / "firefox.exe"
    current_ver = get_version(exe) if exe.exists() else None
    remote_ver = get_remote_version(URL)
    print(f"Debug: Current='{current_ver or ''}' Remote='{remote_ver or ''}'")
    if current_ver:
        print(f"Installed: {current_ver}, Remote: {remote_ver}")
        match = compare_versions(current_ver, remote_ver)
        print(f"Debug: Version match = {match}")
        if match:
            print("Firefox is up to date")
            disable_updates(base_dir)
            return True
        print("Updating Firefox...")
    else:
        print("Installing Firefox...")
    temp_dir = base_dir / "temp"
    temp_dir.mkdir(exist_ok=True)
    installer = temp_dir / "installer.exe"
    try:
        download(URL, installer, aria2_path)
        print("Extracting...")
        extract_dir = temp_dir / "extract"
        extract_dir.mkdir(exist_ok=True)
        subprocess.run([seven, "x", str(installer), f"-o{extract_dir}", "-y"], 
                      check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        firefox_core = None
        for root, dirs, files in os.walk(extract_dir):
            if "firefox.exe" in files:
                firefox_core = Path(root)
                break
        if not firefox_core:
            print("Error: Firefox core not found")
            return False
        if core_dir.exists():
            backup = install_dir / "core_backup"
            if backup.exists():
                shutil.rmtree(backup)
            shutil.move(str(core_dir), str(backup))
        install_dir.mkdir(exist_ok=True)
        shutil.move(str(firefox_core), str(core_dir))
        profile_dir.mkdir(parents=True, exist_ok=True)
        new_ver = get_version(exe)
        print(f"Success! Firefox version: {new_ver}")
        disable_updates(base_dir)
        if (install_dir / "core_backup").exists():
            shutil.rmtree(install_dir / "core_backup")
        return True
    except Exception as e:
        print(f"Error: {e}")
        if core_dir.exists() and (install_dir / "core_backup").exists():
            shutil.rmtree(core_dir, ignore_errors=True)
            shutil.move(str(install_dir / "core_backup"), str(core_dir))
        return False
    finally:
        if temp_dir.exists():
            shutil.rmtree(temp_dir, ignore_errors=True)
def main():
    if os.name != "nt":
        print("Windows only")
        sys.exit(1)
    seven = find_7zip()
    if not seven:
        print("Error: 7zr.exe not found in Dependencies folder.")
        input("Press Enter to exit")
        sys.exit(1)
    aria2_path = find_aria2()
    if aria2_path:
        print(f"Found aria2c: {aria2_path}")
    else:
        print("aria2c not found, using default download method")
    base_dir = Path(__file__).parent.absolute()
    print(f"Working directory: {base_dir}\n")
    success = install_firefox(base_dir, seven, aria2_path)
    create_shortcut(base_dir)
    if success:
        print("\033[92m\nSuccess! Closing in 3 seconds...\033[0m")
        print("\033[90mPress Enter to close immediately\033[0m")
        for i in range(3, 0, -1):
            print(f"{i}...", end='', flush=True)
            start_time = time.time()
            while time.time() - start_time < 1:
                if msvcrt.kbhit():
                    key = msvcrt.getch()
                    if key == b'\r':
                        print("\nClosing now...")
                        sys.exit(0)
                time.sleep(0.05)
        print()
    else:
        print("\033[91m\nErrors occurred. Press Enter to exit.\033[0m")
        input()
if __name__ == "__main__":
    main()