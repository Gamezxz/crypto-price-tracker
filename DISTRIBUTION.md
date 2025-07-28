# Bitcoin Price Tracker - Distribution Guide

## การสร้างแอปสำหรับแจก

### 1. เตรียมความพร้อม

```bash
# Install create-dmg (สำหรับสร้าง DMG file)
brew install create-dmg

# ตรวจสอบ Xcode Command Line Tools
xcode-select --install
```

### 2. Build แอป

```bash
# เข้าไปในโฟลเดอร์โปรเจกต์
cd BitcoinPriceStatusBar

# รัน build script
./build.sh
```

### 3. Code Signing (สำหรับแจกอย่างเป็นทางการ)

ถ้าต้องการแจกแอปอย่างเป็นทางการ ต้องมี:

1. **Apple Developer Account** ($99/ปี)
2. **Developer Certificate**
3. **App Notarization**

```bash
# ลงชื่อด้วย certificate
codesign --force --verify --verbose --sign "Developer ID Application: YOUR_NAME" "dist/Bitcoin Price Tracker.app"

# Notarize แอป
xcrun notarytool submit "dist/Bitcoin Price Tracker.dmg" --keychain-profile "AC_PASSWORD" --wait
```

### 4. การแจกแบบง่าย (ไม่ใช่ App Store)

สำหรับการแจกแบบง่าย ๆ:

1. Build แอปด้วย `./build.sh`
2. Zip ไฟล์ `Bitcoin Price Tracker.app`
3. แจกไฟล์ .zip

**หมายเหตุ:** ผู้ใช้จะต้อง:
- คลิกขวาที่แอป > เลือก "Open" (ครั้งแรก)
- หรือไป System Preferences > Security & Privacy > Allow apps downloaded from "Anywhere"

### 5. ไฟล์ที่ได้

หลังจาก build เสร็จจะได้:
- `dist/Bitcoin Price Tracker.app` - แอปหลัก
- `dist/Bitcoin Price Tracker.dmg` - ไฟล์ installer (ถ้ามี create-dmg)

### 6. การทดสอบ

```bash
# ทดสอบแอป
open "dist/Bitcoin Price Tracker.app"

# ตรวจสอบ code signature
codesign -dv "dist/Bitcoin Price Tracker.app"
```

### 7. ขนาดไฟล์

แอปจะมีขนาดประมาณ:
- .app: ~2-5 MB
- .dmg: ~3-7 MB

### 8. ความต้องการของระบบ

- macOS 13.0 ขึ้นไป
- Internet connection (สำหรับดึงข้อมูลราคา)

## Tips สำหรับการแจก

1. **ใส่คำอธิบายการใช้งาน** ในไฟล์ README
2. **ระบุความต้องการของระบบ** อย่างชัดเจน
3. **แนะนำวิธีการติดตั้ง** สำหรับผู้ใช้ทั่วไป
4. **สร้าง release notes** เมื่อมีการอัปเดต