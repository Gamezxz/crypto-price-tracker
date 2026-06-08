#!/bin/bash
# สร้าง DMG แบบมืออาชีพ: ไอคอนแอป + ทางลัด Applications + พื้นหลังมีลูกศร "ลากเพื่อติดตั้ง"
# ใช้: ./make_dmg.sh "<path/to/App.app>" "<output.dmg>"
set -euo pipefail

APP="${1:?usage: make_dmg.sh <App.app> <output.dmg>}"
OUT="${2:?usage: make_dmg.sh <App.app> <output.dmg>}"
VOL="Crypto Price Tracker"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BG="$SCRIPT_DIR/dmg-assets/dmg-background.tiff"
APP_NAME="$(basename "$APP")"

[ -d "$APP" ] || { echo "❌ ไม่พบแอป: $APP"; exit 1; }

WORK="$(mktemp -d)"
STAGE="$WORK/stage"
RW="$WORK/rw.dmg"
mkdir -p "$STAGE/.background"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
[ -f "$BG" ] && cp "$BG" "$STAGE/.background/background.tiff"

# unmount เผื่อค้างจากรอบก่อน
hdiutil detach "/Volumes/$VOL" >/dev/null 2>&1 || true

SIZE_MB=$(( $(du -sm "$STAGE" | awk '{print $1}') + 60 ))
hdiutil create -volname "$VOL" -srcfolder "$STAGE" -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" -format UDRW -size "${SIZE_MB}m" "$RW" >/dev/null

DEV=$(hdiutil attach -readwrite -noverify -noautoopen "$RW" | egrep '^/dev/' | head -1 | awk '{print $1}')
MNT="/Volumes/$VOL"
sleep 2

# จัด layout ผ่าน Finder (ถ้า automation ใช้ไม่ได้ ก็ข้าม — DMG ยังมีแอป + Applications ให้ลากอยู่ดี)
if [ -f "$STAGE/.background/background.tiff" ]; then BGLINE='set background picture of theViewOptions to file ".background:background.tiff"'; else BGLINE=''; fi
osascript <<EOT || echo "⚠️  ตั้งค่า Finder layout ไม่สำเร็จ (DMG ยังใช้ลากติดตั้งได้)"
tell application "Finder"
  tell disk "$VOL"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 150, 840, 550}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 120
    $BGLINE
    set position of item "$APP_NAME" of container window to {160, 200}
    set position of item "Applications" of container window to {480, 200}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOT

sync
hdiutil detach "$DEV" >/dev/null 2>&1 || hdiutil detach "$MNT" >/dev/null 2>&1 || true
rm -f "$OUT"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$OUT" >/dev/null
rm -rf "$WORK"
echo "✅ สร้าง DMG เสร็จ: $OUT"
