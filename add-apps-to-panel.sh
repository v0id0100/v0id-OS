# 1. Run the brute-force python injector to update all active docks/panels
python3 -c '
import os, re

config_path = os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")
if os.path.exists(config_path):
    with open(config_path, "r") as f:
        content = f.read()

    # Define the precise list of apps you want pinned
    apps = [
        "applications:firefox.desktop",
        "applications:org.kde.dolphin.desktop",
        "applications:systemsettings.desktop",
        "applications:code-oss.desktop",
        "applications:org.mozilla.Thunderbird.desktop",
        "applications:virtualbox.desktop",
        "applications:proton.vpn.app.gtk.desktop",
        "applications:org.kde.konsole.desktop",
        "applications:org.kde.dolphin.desktop",
        "applications:systemsettings.desktop"
    ]
    launcher_string = "launchers=" + ",".join(apps)

    # Brute-force override any line starting with launchers= across the entire file
    new_content = re.sub(r"launchers=.*", launcher_string, content)

    # Also handle widgets that might have had empty configurations
    new_content = new_content.replace("[Configuration][General]\n", f"[Configuration][General]\n{launcher_string}\n")

    with open(config_path, "w") as f:
        f.write(new_content)
'

# 2. Clear out the graphical layout caches
rm -rf ~/.cache/plasma*

# 3. Reload the panel engine silently
systemctl --user restart plasma-plasmashell.service