# Birthday Promo Info Settings — แผนงานตั้งค่า Info เงื่อนไขวันเกิด

## Overview

ทำให้ popup **เงื่อนไขสิทธิพิเศษวันเกิด** (รูปภาพ / หัวข้อ / เงื่อนไข) ตั้งค่าได้จาก Gateway Admin  
รองรับ 3 ภาษา (`th`, `en`, `zh`) และให้แอป Flutter แสดงตามค่าที่ตั้งไว้

**สถานะปัจจุบัน:** hardcode ใน `ProfileViewModel` + รูป `Assets.png.brownyPromotion`  
**เป้าหมาย:** ตั้งค่าจาก Gateway → API → แอปแสดงตาม locale ของผู้ใช้ (มี fallback)

### Scope งานนี้ (สำคัญ)

งานนี้ทำเฉพาะ **การตั้งค่า info ของ popup** เท่านั้น

| รวมในงานนี้ | ไม่รวมในงานนี้ |
|-------------|----------------|
| ตั้งค่าหัวข้อ (title) 3 ภาษา | ตั้งค่า / สร้างโปรโมชันวันเกิด |
| ตั้งค่าเงื่อนไข (description HTML) 3 ภาษา | แจกคูปอง / ของขวัญอัตโนมัติ |
| ตั้งค่ารูปภาพ (image) ต่อภาษา | ส่วนลด checkout ตามเดือนเกิด |
| เปิด–ปิดการดึงเนื้อหาจาก API (`active`) | lock / ห้ามแก้ `birthdate` |
| แอปแสดง info ตามที่ตั้งค่า | DiscountCondition / Festive / Coupon engine |

> **ไม่มีการตั้งโปรโมชันใดๆ ในรอบนี้** — เป็นแค่ CMS ของข้อความและรูปใน dialog ข้อมูลเท่านั้น  
> พฤติกรรมสิทธิ์จริง (ถ้ามี) ยังอยู่นอกระบบนี้เหมือนเดิม

---

## สรุปผลการวางแผน

| หัวข้อ | มติ |
|--------|-----|
| Scope | **ตั้งค่า info popup เท่านั้น** (รูป / หัวข้อ / เงื่อนไข) — **ไม่มีการตั้งโปรโมชัน** |
| Pattern ที่ใช้ | App Settings แบบ **Wallet First Notification + Coin claim success popup** |
| Storage | `config/setting_defaults.php` key `birthday_promo_info` (ไม่ใช้ DB / ไม่ใช้ AppPopup) |
| ภาษา | `th` / `en` / `zh` ตาม `config('locales.supported')` |
| รูปภาพ | **แยกต่อภาษา** (เหมือน coin claim popup) |
| เงื่อนไข | HTML (เหมือนข้อความเดิม / coin popup detail) |
| API | `GET /api/profile/birthday-promo-info` |
| แอป | fetch ตอนเข้า Profile / ก่อนเปิด popup → เลือกตาม `languageCode` |
| Fallback | ถ้า API `null` / ว่าง / error → ใช้ hardcode + asset เดิม |
| Out of scope | โปรโมชัน, คูปอง, ส่วนลด, lock วันเกิด, engine ให้สิทธิ์ |

---

## As-Is vs To-Be

```
As-Is
─────
ProfilePage._showBirthDayOffers()
  └─ title / description จาก ProfileViewModel (hardcode HTML 3 ภาษา)
  └─ image จาก Assets.png.brownyPromotion

To-Be
─────
Gateway Admin (App Settings → Birthday Promo Info)
  └─ บันทึก setting_defaults.birthday_promo_info
       │
       ▼
GET /api/profile/birthday-promo-info
       │
       ▼
Flutter ProfileRepo → ProfileViewModel
  └─ title / description / image ตาม locale
  └─ fallback → hardcode + asset เดิม
```

---

## Architecture ที่เลือก

### ทำไมใช้ App Settings (config) ไม่ใช้ AppPopup / Banner DB

| ทางเลือก | เหมาะเมื่อ | เหตุผลที่ไม่เลือก / เลือก |
|----------|------------|---------------------------|
| **App Settings (`setting_defaults`)** | singleton content 1 ชุด | **เลือก** — เหมือน Wallet First Notification + Coin popup |
| AppPopup | แคมเปญมีช่วงเวลา / dismiss / carousel | UX คนละแบบกับ dialog เงื่อนไขโปรไฟล์ |
| Banner / Festive DB | หลายรายการ + schedule | overkill สำหรับ dialog เดียว |

### Pattern ที่ mirror

| ส่วน | Mirror จาก |
|------|------------|
| Admin form (title + description + tabs ภาษา) | `settings/app/wallet-first-notification.blade.php` |
| อัปโหลดรูปต่อภาษา | `settings/app/coin.blade.php` (`claim_success_popup_image`) |
| บันทึก config | `SettingDefaultController::updateWalletFirstNotification` / `updateCoin` |
| API response `{ th, en, zh }` | `WalletController::walletFirstNotification` + `resolve_media_url()` |
| Flutter localize model | `ContentLocalizeData` |
| Flutter HTML + network image | `coin_page.dart` claim success popup |

---

## Gateway Design

### 1) Config shape

ไฟล์: `AB_Gateway/config/setting_defaults.php`

```php
'birthday_promo_info' => [
    'active' => true,
    'title' => [
        'th' => 'สิทธิพิเศษวันเกิดสุดพิเศษ รอคุณอยู่!',
        'en' => 'Special birthday privileges are waiting for you!',
        'zh' => '特别的生日优惠正在等着您!',
    ],
    'description' => [
        'th' => '<p>เงื่อนไข</p><ul><li>...</li></ul>',
        'en' => '<p>Terms and Conditions</p><ul><li>...</li></ul>',
        'zh' => '<p>条款和条件</p><ul><li>...</li></ul>',
    ],
    'image' => [
        'th' => 'storage/uploads/birthday_promo_info/....png', // หรือ '' ถ้ายังไม่อัปโหลด
        'en' => '',
        'zh' => '',
    ],
],
```

**Seed เริ่มต้น:** คัดลอกข้อความ hardcode จาก `ProfileViewModel` ปัจจุบัน

### 2) Admin UI

| รายการ | รายละเอียด |
|--------|------------|
| เมนู | App Settings → **Birthday Promo Info** |
| Nav | `resources/views/settings/app/partials/nav-tabs.blade.php` |
| View | `resources/views/settings/app/birthday-promo-info.blade.php` |
| Controller | `SettingDefaultController` → `editBirthdayPromoInfo` / `updateBirthdayPromoInfo` |
| Web routes | `GET/POST settings/defaults/birthday-promo-info` |
| Permission | `setting.defaults.birthday_promo_info.edit` / `.update` ใน `EnsureUserRoutePermission` |

**ฟอร์ม (ต่อภาษา th/en/zh):**
- Active switch
- Title (text, max 255)
- Description (textarea / CKEditor สำหรับ HTML)
- Image (file upload jpg/jpeg/png/webp) + preview

### 3) API

```
GET /api/profile/birthday-promo-info
Middleware: CheckApiToken (ไม่บังคับ customer login ก็ได้ ถ้าอยู่ในกลุ่ม token เดียวกับ /popups)
```

**เมื่อ `active = false` หรือยังไม่มี config:**

```json
null
```

**เมื่อ active:**

```json
{
  "title": {
    "th": "...",
    "en": "...",
    "zh": "..."
  },
  "description": {
    "th": "<p>...</p>",
    "en": "<p>...</p>",
    "zh": "<p>...</p>"
  },
  "image": {
    "th": "https://gateway.../storage/uploads/...",
    "en": "https://...",
    "zh": "https://..."
  }
}
```

หมายเหตุ:
- `image` ต้องผ่าน `resolve_media_url()` ก่อนส่ง
- ถ้า path ว่าง → ส่ง `null` หรือ `""` ต่อ locale นั้น (แอปใช้ fallback asset)

**Controller แนะนำ:** `Api\ProfileController` หรือ method ใหม่ใน controller ที่มีอยู่แล้วของ profile settings  
**Route ใน** `routes/api.php` ใกล้กลุ่ม customer/profile

### 4) Gateway task checklist

- [ ] เพิ่ม key `birthday_promo_info` ใน `setting_defaults` (seed จาก copy ปัจจุบัน)
- [ ] Admin blade + nav tab
- [ ] `edit` / `update` ใน `SettingDefaultController` (validate + upload + `File::put`)
- [ ] Permission aliases
- [ ] Web routes
- [ ] API endpoint + response mapping
- [ ] Feature test (active / inactive / locale keys / image URL)

---

## Flutter Design

### 1) Data layer

| ไฟล์ | งาน |
|------|-----|
| `app_client.dart` | `GET /profile/birthday-promo-info` |
| `birthday_promo_info_response.dart` | model: `title`, `description`, `image` เป็น `ContentLocalizeData?` |
| `profile_repo.dart` | `fetchBirthdayPromoInfo()` |
| build_runner | regen `*.g.dart` |

### 2) ViewModel

`ProfileViewModel`:
- โหลด birthday promo info พร้อม / หลัง `fetchProfileData`
- expose:
  - `resolvedTitle(BuildContext)`
  - `resolvedDescription(BuildContext)`
  - `resolvedImageUrl(BuildContext)` หรือ `ImageProvider`
- logic:
  1. ถ้า API มีค่า locale → ใช้ค่านั้น
  2. ถ้า locale ว่าง → fallback `th` แล้วค่อย hardcode
  3. ถ้า image URL ว่าง / โหลดไม่ได้ → `Assets.png.brownyPromotion`

เก็บ hardcode เดิมเป็น **fallback methods** (อย่าลบทันทีใน release แรก)

### 3) UI

`profile_page.dart` → `_showBirthDayOffers()`:
- หัวข้อ: จาก API
- เงื่อนไข: `Html(...)` จาก API
- รูป: `Image.network` + `errorBuilder` / `CachedNetworkImage` ตาม pattern โปรเจกต์ → fallback asset

จุดเรียกใช้ยังเหมือนเดิม:
1. First signup (`isFirstSignup`)
2. ปุ่ม `birthdaySpecialConditions`

### 4) Flutter task checklist

- [ ] Response model + Retrofit method
- [ ] Repo fetch
- [ ] ViewModel resolve + fallback
- [ ] Dialog ใช้ข้อมูล remote
- [ ] ทดสอบ th/en/zh + offline / null API
- [ ] (optional) cache ใน memory ตลอด session ของ Profile

---

## Rollout

```
Phase 1 — Gateway
  seed config + admin + API
  (แอปเก่ายัง hardcode ได้ตามเดิม)

Phase 2 — Flutter
  เรียก API + fallback
  QA 3 ภาษา / active off / ไม่มีรูป

Phase 3 — Content
  แอดมินอัปโหลดรูปจริง + ปรับข้อความ
  (ถ้าต้องการ) ค่อยลบ hardcode ในรอบถัดไป
```

ลำดับ deploy: **Gateway ก่อน** → App ตามหลัง (backward compatible)

---

## Acceptance Criteria

1. Admin ตั้งค่า title / description / image ได้ครบ `th`, `en`, `zh`
2. สวิตช์ active ปิดแล้ว API คืน `null` และแอปใช้ fallback (หรือไม่โชว์ตามมติ product)
3. แอปภาษาไทย/อังกฤษ/จีน แสดงข้อความตรงกับที่ตั้ง
4. ไม่มีรูป → แสดง asset เดิม ไม่พัง UI
5. API ล่ม / timeout → ยังเปิด dialog ด้วย fallback ได้
6. ไม่กระทบ flow บันทึก `birthdate` เดิม

---

## Open Decisions (ยืนยันตอน implement)

| # | คำถาม | ค่า default ในแผนนี้ |
|---|--------|----------------------|
| 1 | `active=false` → ซ่อน dialog ทั้งก้อน หรือโชว์ fallback? | **โชว์ fallback** (ไม่เปลี่ยน UX ปัจจุบัน) |
| 2 | รูปแชร์ใบเดียวทุกภาษา หรือแยก 3 ใบ? | **แยก 3 ใบ** (ยืดหยุ่นกว่า; admin ใส่ซ้ำได้) |
| 3 | Description ใช้ textarea หรือ CKEditor? | **textarea ก่อน** (HTML จาก seed เดิมสั้น); อัปเกรด CKEditor ได้ภายหลัง |
| 4 | ต้อง auth customer หรือแค่ API token? | **API token** แบบ `/popups` / wallet first notification |
| 5 | ทำ engine ให้สิทธิ์ / ตั้งโปรโมชันเดือนเกิดด้วยไหม? | **ไม่ในรอบนี้ — เฉพาะตั้งค่า info** |

---

## Risks

| Risk | Mitigation |
|------|------------|
| `setting_defaults.php` ต้อง sync หลาย server | เหมือน coin/wallet settings ปัจจุบัน — deploy/commit config หรือ shared volume |
| รูปอัปโหลดต้องอยู่ shared storage | ใช้ `public` disk + `resolve_media_url` ตามของเดิม |
| Config cache ~3 วินาทีหลังเซฟ | ข้อความ success แจ้ง admin เหมือน wallet setting |
| HTML จาก admin ใน `flutter_html` | ยอมรับตาม banner/coin (admin-trusted content) |
| แอปเก่าระหว่างรออัปเดต | hardcode ยังอยู่; Gateway เปลี่ยนได้ทันทีหลังแอปใหม่ขึ้น |

---

## Out of Scope (รอบนี้)

งานนี้ **ไม่รวมการตั้งค่าหรือสร้างโปรโมชันใดๆ**

- ไม่สร้าง / แก้โปรโมชันวันเกิดในระบบ Discount / Coupon / Festive
- ไม่แจกคูปอง / ของขวัญ / สิทธิ์อัตโนมัติในเดือนเกิด
- ไม่ล็อกการแก้ `birthdate` หลังใช้สิทธิ์
- ไม่เพิ่มเงื่อนไขส่วนลด checkout แบบ `birth_month` ใน `DiscountConditionService`
- ไม่ย้ายเนื้อหาไปเป็น AppPopup แคมเปญ

ถ้าจะทำ engine ให้สิทธิ์หรือตั้งโปรโมชันจริง ควรเป็นเอกสารแผนแยก (Birthday Privilege / Promotion Engine)

---

## คำชี้แจง naming

ชื่อ key / API ใช้คำว่า `birthday_promo_info` เพื่อให้ตรงกับ UI เดิม (“โปร” / สิทธิพิเศษวันเกิด)  
แต่ในงานนี้หมายถึง **info content ของ popup เท่านั้น** — ไม่ใช่โมดูลจัดการโปรโมชัน

---

## File Index (เป้าหมาย implement)

### Gateway (`AB_Gateway-worktree-20260806-151446`)

> Implement บน worktree: `/Applications/XAMPP/xamppfiles/htdocs/AB_Gateway-worktree-20260806-151446`  
> Branch: `feat/birthday-promo-info-cms`

- `app/Http/Controllers/Setting/SettingDefaultController.php`
- `resources/views/settings/app/birthday-promo-info.blade.php`
- `resources/views/settings/app/partials/nav-tabs.blade.php`
- `routes/web.php`
- `routes/api.php`
- `app/Http/Middleware/EnsureUserRoutePermission.php`
- `app/Http/Controllers/Api/BirthdayPromoInfoController.php`
- `tests/Feature/BirthdayPromoInfoApiTest.php`

### Flutter (`BrownyApplicationV2-202511`)

> Branch: `feat/birthday-promo-info-cms`

- `lib/core/data/remote/app_client.dart`
- `lib/core/data/remote/models/response/birthday_promo_info_response.dart` (+ `.g.dart`)
- `lib/feature/profile/repository/profile_repo.dart`
- `lib/feature/profile/viewmodel/profile_viewmodel.dart`
- `lib/feature/profile/screen/profile_page.dart`

---

## Estimate (คร่าวๆ)

| ส่วน | ขนาดงาน |
|------|---------|
| Gateway admin + config + API + test | M (~0.5–1 วัน) |
| Flutter model/repo/VM/UI + fallback | S–M (~0.5 วัน) |
| QA 3 ภาษา + edge cases | S |

รวมประมาณ **1–1.5 วันทำงาน** สำหรับ info settings ตาม scope นี้
