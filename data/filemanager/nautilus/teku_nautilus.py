# Top-level "Install with Teku" in Nautilus' right-click menu.
# Needs nautilus-python (Debian/Ubuntu: python3-nautilus).
import subprocess

from gi.repository import GObject, Nautilus

TEKU = "@BINDIR@/teku"
EXTENSIONS = (".deb", ".rpm", ".appimage", ".flatpakref", ".exe", ".msi", ".dmg", ".pkg")


class TekuMenu(GObject.GObject, Nautilus.MenuProvider):
    def get_file_items(self, files):
        paths = [f.get_location().get_path() for f in files]
        if not paths or not all(p and p.lower().endswith(EXTENSIONS) for p in paths):
            return []
        item = Nautilus.MenuItem(name="Teku::Install", label="Install with Teku", icon="teku")
        item.connect("activate", lambda *_: subprocess.Popen([TEKU, *paths]))
        return [item]
