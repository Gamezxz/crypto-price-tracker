# 📥 Bitcoin Price Tracker - Installation Guide

เราได้สร้างไฟล์ installer หลายแบบเพื่อให้การติดตั้งง่ายและสะดวกที่สุด

## 🎯 วิธีการ Install (สำหรับผู้ใช้)

### วิธีที่ 1: DMG Installer (แนะนำ) 🌟

1. **ดาวน์โหลด** `Bitcoin-Price-Tracker-Installer.dmg`
2. **Double-click** ไฟล์ DMG เพื่อเปิด
3. **ลาก** แอป `Bitcoin Price Tracker` ไปใส่โฟลเดอร์ `Applications`
4. **เปิดแอป** จาก Applications หรือ Spotlight
5. **ดู** ราคา Bitcoin ใน status bar ได้เลย!

```
📁 DMG จะแสดง:
┌─────────────────────────────────────┐
│  ₿ Bitcoin Price Tracker            │
│     ↓ ลากมาใส่นี่ ↓                   │
│  📁 Applications                    │
└─────────────────────────────────────┘
```

### วิธีที่ 2: PKG Installer (สำหรับ Auto-install)

1. **ดาวน์โหลด** `Bitcoin-Price-Tracker-Installer-Final.pkg`
2. **Double-click** ไฟล์ PKG
3. **ตาม** ขั้นตอนในหน้า installer
4. **เสร็จ!** แอปจะติดตั้งอัตโนมัติ

### วิธีที่ 3: Manual Installation

1. **ดาวน์โหลด** `Bitcoin Price Tracker.app.zip`
2. **แตกไฟล์** ZIP
3. **ย้าย** แอปไป `/Applications`
4. **เปิดใช้งาน**

## 🛠 วิธีการสร้าง Installer (สำหรับ Developer)

### สร้าง DMG Installer
```bash
cd BitcoinPriceStatusBar
./create_installer.sh
```

### สร้าง PKG Installer  
```bash
cd BitcoinPriceStatusBar
./create_pkg_installer.sh
```

### สร้างทั้งหมด
```bash
cd BitcoinPriceStatusBar
./build.sh              # Build แอป
./create_installer.sh    # สร้าง DMG
./create_pkg_installer.sh # สร้าง PKG
```

## 📋 ไฟล์ที่ได้

หลังจากรัน script จะได้ไฟล์เหล่านี้ในโฟลเดอร์ `dist/`:

```
dist/
├── Bitcoin-Price-Tracker-Installer.dmg      # DMG installer (แนะนำ)
├── Bitcoin-Price-Tracker-Installer-Final.pkg # PKG installer  
└── Bitcoin Price Tracker.app                # แอปเดี่ยว
```

## 🎨 คุณสมบัติของ Installer

### DMG Installer
- ✨ **Beautiful UI** - พื้นหลังสวยงามพร้อมคำแนะนำ
- 🎯 **Drag & Drop** - ลากแอปไปโฟลเดอร์ Applications
- 📜 **License Agreement** - แสดง MIT License
- 🖼 **Custom Icon** - ไอคอน Bitcoin สีส้ม
- 📏 **Perfect Size** - หน้าต่างขนาดเหมาะสม

### PKG Installer
- 🤖 **Auto Installation** - ติดตั้งอัตโนมัติ
- ✅ **Post-install Script** - ตั้งค่า permissions
- 💬 **Success Dialog** - แจ้งเตือนเมื่อติดตั้งสำเร็จ
- 🔧 **System Integration** - ติดตั้งแบบ native macOS

## 🚀 การแจก

### สำหรับการแจกธรรมดา
1. อัปโหลด DMG ไป GitHub Releases
2. แชร์ลิงก์ดาวน์โหลด
3. ผู้ใช้ดาวน์โหลดและลาก-วาง

### สำหรับการแจกแบบมืออาชีพ
1. Code sign ด้วย Developer Certificate
2. Notarize ผ่าน Apple
3. อัปโหลดไป App Store หรือเว็บไซต์

## ⚠️ หมายเหตุสำคัญ

### สำหรับผู้ใช้
- ครั้งแรกต้อง **คลิกขวา > Open** (เพื่อ bypass Gatekeeper)
- ต้องมี **Internet connection** สำหรับข้อมูลราคา
- รองรับ **macOS 13.0+** เท่านั้น

### สำหรับ Developer  
- ต้องมี **Xcode** และ **Command Line Tools**
- ต้องติดตั้ง **create-dmg**: `brew install create-dmg`
- ต้องติดตั้ง **Pillow**: `pip3 install Pillow`

## 📊 ขนาดไฟล์

- **DMG**: ~3-7 MB
- **PKG**: ~2-5 MB  
- **App**: ~2-4 MB

สำเร็จแล้ว! ตอนนี้มี installer ที่ใช้งานง่ายสำหรับการแจก 🎉