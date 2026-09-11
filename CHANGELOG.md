# CHANGELOG
### DONG 2026-09-11
- ปรับปรุงความเสถียรของระบบ, FirebaseCrashlytics
- จำกัดช่องทางชำระตาม Coupon/E-Voucher ที่เลือกในหน้าเครื่องซัก/อบ
  - เปิดใช้ flag `payment_methods` ของเครื่อง + `allowed_payment_methods` ของคูปองที่เลือก มากรองช่องทางชำระ 2 ชั้น
  - ช่องทางที่ใช้ไม่ได้แสดงแบบจางและเรียงไว้ล่างสุด ช่องที่ผ่านเงื่อนไขถูกเลือกเป็นค่าเริ่มต้นให้อัตโนมัติ
  - ถ้าไม่มีช่องทางใดใช้ได้เลย ปิดปุ่มชำระเงินและกันไม่ให้สร้างออเดอร์
  - ไม่กระทบส่วนลด Browny Coin แบบ toggle ยังทำงานตามเดิม

### DONG 2026-08-29
- ปรับปรุงการทำงาน จังหวะ ซื้อ Coupon, สร้างคำส่งเครื่อง ให้นำ message จาก api มาแสดงถ้าสามารถเข้า model ได้
- Merge [3e9a9be, ddbe007]
  - ขยายส่วนลด Browny Coin แบบ toggle ไปหน้าซื้อ E-Voucher
  - รวม logic ส่วนลด coin ไว้ที่ TransactionsViewmodel ใช้ร่วมกับหน้าเครื่องซัก/อบ
  - ส่ง use_coin ใน CouponOrderRequest เมื่อเปิดใช้ส่วนลด
  - เปลี่ยน Browny Coin จากช่องทางชำระเงินเป็นส่วนลดแบบ toggle ในหน้าเครื่องซัก/อบ
  - อัตรา 10 coins = 1 บาท (ปัดลง) และหักยอดท้ายบิล/ปุ่มชำระให้ตรงกัน
  - ส่ง use_coin ตอนสร้างออเดอร์เมื่อเปิดใช้ส่วนลด

### DONG 2026-08-02
- [hotfix v3.0.7] แก้บัคหน้าสถานะเครื่อง (MachineStatusPage) พอเครื่องทำงานเสร็จแล้ว refresh จะเด้งกลับไปหน้า `เริ่มการทำงานเครื่อง` แทนที่จะแสดง Timeline เต็มหลอด สถานะ `สำเร็จ` พร้อมข้อมูล Order เดิม
- [hotfix v3.0.7] แก้บัคหน้าสถานะเครื่อง (MachineStatusPage) พอ Timeline นับถอยหลังจนหมดเวลา สถานะค้างที่ `กำลังทำงาน` ไม่เปลี่ยนเป็น `สำเร็จ` จนกว่าผู้ใช้จะ refresh เอง

### DONG 2026-07-17
- [hotfix v3.0.6]
  - ดัก error UserDuplicated เพิ่ม ให้แสดง wordig เตือนว่าใช้ เบอร์ / อีเมล์ซ้ำกันในระบบ
  - ดัก error Unprocessable เพิ่ม ให้แสดง wordig เตือนถ้าเป็น error contactCallCenterType ให้ติดต่อ Call Center

### DONG 2026-07-15
- [hotfix v3.0.6] แก้ไข Logic การตรวจสอบ User ก่อนที่จะขอเปลี่ยนรหัสผ่านทำงานไม่ถูกต้อง ทำให้สามารถเปลี่ยนรหัสผ่านได้ทั้งๆ ที่ไม่มี user ในระบบ

### DONG 2026-07-06
- [hotfix v3.0.5] ปิด link `ในกรณีที่ท่านพบปัญหาการใช้งาน หรือต้องการขอคืนเงิน กรุณาคลิกที่นี่` ในหน้า Wallet topup

### DONG 2026-06-09
- เพิ่มเช็ค Machine status inactive, maintenance

### DONG 2026-05-21
- เพิ่ม auto เลื่อนแถบไปที่ ซัก-อบ จังหวะเก็บคูปองจากการ กรอก/แสกน QR
- แก้ไขไม่สามารถ review ร้านค้าจากประวัติการใช้งานได้

### DONG 2026-05-9
- เพิ่ม Section "คูปอง/E-Voucher ที่ใช้ไม่ได้" ในหน้า CouponVoucherPage แสดงรายการที่หมดอายุหรือสิทธิ์เต็มแยกออก
- ปรับ Card คูปอง รองรับสถานะ "หมดอายุ" และ "สิทธิ์เต็ม" (icon + wording สี error)
- ปรับ default ช่วงวันที่หน้า HistoryTransactionPage เป็น 7 วันย้อนหลัง
- ปรับ flow สมัครสมาชิก เช็ค referral status ก่อนเข้าหน้า referral (ถ้าปิดอยู่ ข้ามไปสร้าง PIN เลย)
- แก้ไข wording วัน ในหน้าแสดง E-Voucher, Coupon
- แก้บัค StoreDetailPage refresh ใช้พิกัดร้านแทนพิกัดผู้ใช้ ทำให้คำนวณระยะห่างผิด
- แก้ไข format วันที่ในหน้า claim coin ให้มี จุด ในตัวย่อเดือน
- upgrade version v3.0.4
- Change token_dev to v3.0.4
- Change token_prd to v3.0.4
- ปรับ Process การ save referral ใช้เช็ค status การเปิดใช้งานด้วย
- ปรับปรุง UX หน้าสถานะเครื่อง (MachineStatusPage) กรณีเครื่องยังไม่เริ่มทำงาน
 - ย้าย Dialog ที่ Block หน้าจอ ไปแสดงเป็น Inline Panel ใน Scaffold แทน
 - ผู้ใช้สามารถกดปุ่ม Back จาก AppBar ออกจากหน้าได้ แม้เครื่องส่ง status ไม่ได้
 - คงการทำงาน Auto-check timer (poll ทุก 3 วิ) และปุ่ม ตรวจสอบสถานะ / แจ้งปัญหาการใช้งาน ไว้ใน Panel
- เพิ่มการ Refresh ข้อมูลสถานะเครื่องซัก/อบ หน้ารายละเอียดสาขา (StoreDetailPage) แบบ Real-time
 - Poll API `fetchStoreDetail` ทุก 5 วินาที อัพเดท UI เครื่องซักและเครื่องอบอัตโนมัติ
 - เพิ่ม StoreDetailViewModel แยกออกมาตาม Clean Architecture (ย้าย Timer + Repo ออกจาก Widget)

### DONG 2026-05-2
- Change env.prd API key to v3.0.3
- ปรัับปรุง Process การทำงานจังหวะสร้าง Order ป้องกันการกดกลับจาก User ที่อาจจะส่งผลให้การทำงานผิด Process
- bump Flutter min SDK to 3.10.0
- ปรับปรุง Widget แสดง Receipt หากข้อมูลที่แสดงยาวจะทำให้แสดงผลไม่ได้
- เพิ่มหน้าแสดง ประวัติการใช้งาน

### DONG 2026-05-1
- เพิ่มดัก event กดเบิ้ลจังหวะสร้าง Order ในจุดต่างๆ
- แก้ไข icon launcher App ภาพแตก
- เพิ่มปุ่ม Back ในหน้า Profile เพื่อให้ User สับสนการออกจากหน้า Profile
- ปรับขนาด font ทั้ง app +2 เพื่อให้ตัวอักษรดูใหญ่ขึ้น

### DONG 2026-04-27
- change token dev to v3.0.3
- ปรับปรุง Wording Alert กรณีเกิด Exception ที่ไม่ได้ถูก Handle ไว้ ให้รองรับ Localize ครบทุกภาษา
- ปรับ Sizing Banner เพราะมีปัญหา Content ใน Banner แสดงไม่ครบ (รอ Review)
- แก้ไขให้ปุ่ม บริการ สามารถกดเพื่อเปิดกล้องได้

### DONG 2026-04-23
- ปรับปรุงการทำงานหน้าแสดง Coupon, E-Voucher จากการใช้งานเครื่อง
- Change prd token to v3.0.2
- bump LINE SDK version v2.7.2

### DONG 2026-04-19
- แก้ไข ลืมรหัส ระบบไม่ focus Field PIN ทำให้เก็บค่าผิด
- เพิ่มการแสดง Field Bonus Browny coin จากการชำระใช้งานเครื่อง
 - เพิ่มรองรับ field bonus ใน api machine-orders/{order_id}/receipt

### DONG 2026-04-18
- แก้ไข Crash "GoError: There is nothing to pop" บน Android และ iOS ในหน้า ShowQRPromptpayPage
 - เพิ่มการตรวจสอบ context.canPop() ก่อนเรียก context.pop() และ fallback ไปยังหน้า Wallet แทน
- เพิ่มเงื่อนไขการตรวจสอบ Coupon, E-Voucher ที่เลือกมาว่าตรงเงื่อนไขการร่วมรายการหรือไม่
- เพิ่มการทำงาน หากสแกนใช้งาน Coupon, E-Voucher จากปุ่ม เริ่มการทำงาน จะใช้ Coupon, E-Voucher ให้ทันทีถ้าเข้าเงื่อนไข
- แก้ไขการเลือก Coupon/E-Voucher ในหน้า CouponVoucherPage ไม่แสดง Highlight รายการที่เคยเลือกไว้
 - เพิ่ม preSelectedCustomerCouponId ใน TransactionsViewmodel เพื่อ restore สถานะที่เลือกไว้
 - ปรับ MachineTransactionPage2 ส่ง selectedCouponId ไปยัง CouponVoucherPage
- เพิ่ม Localize wording ที่ยังเป็น Hardcoded
 - couponMinimumAmountRequired: "ต้องมียอดรวมขั้นต่ำ {minAmount}"
 - couponNotEligible: "ไม่ร่วมรายการ"
 - cannotUseCouponType: "ไม่สามารถใช้งาน {couponType} ได้"
- เก็บ Design Wallet Reciept

### DONG 2026-04-12
- แก้ไขการแจ้งเตือน Exception ที่ไม่ถูก Handle UI ให้แสดง wording `ขออภัย เกิดข้อผิดพลาดขึ้น โปรดลองอีกครั้ง`
- เพิ่ม function ตรวจสอบ API Key และการ ​Force Update App
- แก้ไขการแสดง ยอดชำระทั้งหมด ที่มีค่าติดลบให้แสดงเป็น 0.0 บาท
- แก้ไขการเลือกใช้ Coupon, E-Voucher ในขั้นตอนสั่งทำงานเครื่องซักอบไม่ถูกต้อง

### DONG 2026-04-10
- แก้ไขการดึงค่า machineID ให้ดึงจาก response ก่อน
- เพิ่มเงื่อนไขการเข้าหน้า CoinClaim ต้อง Login เป็น สมาชิกก่อน
- แก้ไขการแสดงเลข version ในหน้าแอพไม่ถูกต้อง

### DONG 2026-04-09
- แก้ไข Wording คงเหลือ วัน หลังซื้อ แสดงไม่ถูกประเภท Coupon/E-Voucher
- แก้ไขการแสดงจุดแจ้งเตือนไม่ถูกต้อง
- Android
 - แก้ไขปัญหา Permission ไม่สามารถ Save Image QRCode ได้
 - แก้ไขปัญหา Permission ไม่สามารถ Browse Image จาก Gallery ได้

### DONG 2026-04-06
- Prepare Release v3.0.0
- แก้ไขลบ User Permission ที่ไม่จำเป็นออก

### DONG 2026-04-03
- v3.0.0(47)
- เปลี่ยน env prd เป็น url, token ที่จะใช้งานจริง
- แก้ไข logic กรณีประเภทชำระไม่มีส่งมาจะเกิด Error

### DONG 2026-04-02
- เก็บ Localize wording ส่วนที่ยังไม่เรียบร้อย
- ยกเลิก gitignore Podfile

### DONG 2026-03-29
- เพิ่มการชำระเงินด้วย browny coin
 - ซื้อ E-Vouvher
 - สั่งการทำงานเครื่องซักอบ

### DONG 2026-03-28
- แก้จังหวะ Scan QR เก็บ Coupon ส่ง type ผิดทำให้เก็บ coupon ไม่ได้
- แก้ไขหน้าแสดง Coupon แสดงคำ ซัก, อบ, ซักอบ ไม่ถูกต้อง
- Localize wording
- แก้ไขการแสดงข้อมูลใน E-Voucher, Coupon

### DONG 2026-03-23
- รายละเอียดเงื่อนไข ระยะห่างซ้ายขวาไม่พอดีกัน
- ประวัติยังมีบัคอยู่ เพราะไม่ได้ login ก่อน
- อยากให้ปุ่ม fix ข้างล่างของจอ เพราะตอนนี้ทำให้ไม่รู้ว่ากดสแกนได้ 
- บัค scan event ที่เคยสแกนแล้ว แสดงไม่ถูกต้อง
- หลังสแกนแล้วต้องขึ้นประวัติทันที
- เมนูใต้ wallet อยากให้ ชิดกันเพิ่มอีก
- รายละเอียดให้หน้าแผนที่ยังแปลภาษาไม่ครบ

### DONG 2026-03-22
- เพิ่มขนาด Icon Browny หน้า home
- ปรับปรุงหน้า Festive scan ให้แสดง UI ตรงตาม Design
  - ปรับเพิ่มการทำงานปุ่ม ประวัติ

### DONG 2026-03-21
- แก้ไข Issue ตาม Feedback
 - ปรับ Icon Sizing
 - Wording ผิด
 - Localized wording

### DONG 2026-03-19
- เพิ่มหน้า LuckDraw (ยังไม่สมบูรณ์)

### DONG 2026-03-16
- Bumped Kotlin plugin 2.1.0 → 2.3.10

### DONG 2026-03-15
- Implement Notification Live Activites iOS
 - วางโครงสร้างการทำงานเบื้องต้นที่เกี่ยวข้อง
- ปุ่มรับสิทธิ์ หน้า Article กรณี หมดเขต ให้แสดงเป็นสีแดงตาม Design
- localize app wording
- แก้ไข E-Voucher กดเลือกเพื่อใช้งานจากส่วนท้ายไม่ได้

### DONG 2026-03-14
- แก้ไข Facebook Login ไม่ได้(workaround) ด้วยการไม่ผ่าน Firebase Authen แต่ใช้ข้อมูลจาก Facebook Register ตรงแทน
 - upgrade version firebase packages, version facebook_auth
- แก้ไข save referral ได้ response 500 แต่ App แสดง บันทึกชวนเพื่อนสำเร็จ
- แก้ไข ปุ่มบันทึก QR ขึ้น ทั้งทีปัดออกหน้า QR มาแล้ว - ต้องปัดลงถึงจะหาย
​ - ปรับ design ใหม่ ให้เป็นการแสดง Check ถูก แทน
- แก้ไข กดรหัสคูปองได้ แต่คูปองไม่โชว์ และไม่สามารถใช้งานได้
- แก้ไข UI หน้า home Spacing เหลืองเยอะไป, หูน้องบราวนี่ขาด

### DONG 2026-03-08
- เพิ่ม function การ Claim สิทธิพิเศษจาก Browny Club
- แก้บัคไม่สามารถแสดง scored review store ในหน้าแสดง Receipt ได้
- เก็บ UI หน้าแสดง Notification ตาม Design

---
### DONG 2026-03-07
- แก้บัคไม่สามารถ review store ในหน้าแสดง Receipt ได้
- เพิ่มการทำงานเมนู เปลี่ยนรหัสผ่าน, เปลี่ยน e-mail, สินค้าที่บันทึกไว้(แสดงเป็น Coming soon)
- Localized wording ใน app ที่ยังไม่เรียบร้อย
- แก้บัคหาก Login ผ่านหน้า User preferrence สำเร็จแล้ว ไม่ fetch user notification settings
- ปรับปรุง Logic ชำระเงินสั่งเครื่องซักอบทำงาน กรณียอดชำระเป็น 0 บาท ให้ข้ามไปหน้า Slip
- ปรับปรุง UI รายการ สถานะบริการ ในหน้า Home เมื่อสถานะเป็นเสร็จสิ้น
- หน้าสถานะเครื่องเพิ่ม Popup เตือนให้เริ่มการทำงานเครื่องกรณีที่เครื่องยังไม่เริ่มทำงาน
- Localized Popup เพื่อนเชิญเพื่อน
- ปรับ UI หน้า Wallet เมนูประวัติการขยับ ฿​ ให้เว้นวรรค

---
### DONG 2026-03-06
- เก็บ Logic การแสดง Machine status ให้แสดงผล status ต่างๆ ถูกต้อง
- แก้ไข ขนาด Banner ใน Browny Club แสดงไม่เท่ากัน
- แก้ไข Banner ที่กำหนดเป็น external_link เมื่อ กดแล้วไม่สั่งเปิด Browser
- เพิ่มการแสดง Banner WeChat Pay ที่หน้าแสดง QRCode
- แก้ไข UI หน้า Coin History, Icon เหรียญไม่ชิดขอบ
- แก้ไขจังหวะชำระ TPWallet แต่สั่งเปิด External Web

### DONG 2026-03-03
- เก็บ design และ ภาษาในหน้าหลัก
- ปรับ Logic จังหวะชำระเงินให้ redirect ไปที่ External Browser แทน
- ปรับ Api เช็ค status machine และเส้นดึง machine progress
- เพิ่มการทำงาน กรอกรหัสคูปอง/Scan QR เพื่อรับคูปอง
- เพิ่มการแสดงข้อมูล คูปองซักอบ

---
### DONG 2026-03-02
- แก้ไขบัคไม่สามารถเปิดกล้องเพื่อ Scan ได้

---
### DONG 2026-03-01
- เพิ่มการทำงานหน้า User Preferences ให้สามารถเปิดปิดตั้งค่าต่างๆ ได้จริง
- เพิ่นเส้น API ที่จำเป็น และปรับ model ตาม API ที่แก้ไขเพิ่มเติม
- เพิ่มหน้า Notifications (Draft)

---
### DONG 2026-02-28
- เพิ่มการ fetch API working machine ที่หน้า home และ UI การทำงานของแต่ละเครื่อง
- ปรับหน้า แก้ไขจังหวัดเลือกประเภทชำระใช้ qr, wechat ให้ดึงจาก field qr_and_wechat แทน redirect_url
 - เปิดหน้าแสดง QRCode แทนการใช้ WebView
- หน้าสถานะเครื่องซัก/อบ เพิ่มการทำงานให้ครบถ้วน

---
### DONG 2026-02-26
- หน้าแสดงสถานะเครื่องซัก (ยังไม่เสร็จ แสดง UI แห้ง)
- หน้า Receipt หลังสร้างรายการเครื่องซัก/อบเสร็จและการ review store
- เก็บรายละเอียดหน้าสั่งทำงานเครื่องซัก/อบ และการตัดชำระเงิน
- แก้ไขจังหวะเปิด Scan QR ด้วยภาพ ระบบไม่จับข้อมูลใน QRCode มา Process ต่อ

---
### DONG 2026-02-25
- แก้ไขไม่สามารถเปิดหน้า Coupon/E-Voucher ได้

---
### DONG 2026-02-25
- หน้า Receipt หลังสร้างรายการเครื่องซัก/อบเสร็จ (ยังไม่เสร็จ)
- การเลือกคูปองมาเป็นส่วนลดในการสร้างรายการเครื่องซัก/อบ (เลือกได้แต่ Logic ยังไม่เรียบร้อยดี)
- เพิ่มหน้าสั่งทำงานเครื่องซัก/อบ และการตัดชำระเงิน
- เพิ่มการ Scan QRCode เพื่อเปิดหน้าเครื่องซัก

---
### DONG 2026-02-21
- ขึ้น UI หน้าเครื่องซัก/อบ (Draft)

---
### DONG 2026-02-20
- ปรับปรุง Logic การเช็ค Balance TP Wallet จังหวะกดชำระเงิน
- เพิ่มหน้าแสดงช่องทางติดต่อต่างๆ 

---
### DONG 2026-02-18
- ปรับแก้ UI หน้า Home Badge เก็บได้ทุกตัวกับ Icon Browny แสดงซ้อนทับกันไม่ถูกต้อง
- เพิ่มหน้า Coin History

---
### DONG 2026-02-17
- เพิ่มหน้า Browny Club และหน้าแสดงเนื้อหา
- ปรับการแสดง Popup InvitFriend ในหน้าแรกให้แสดง 1 ครั้งต่อวัน

---
### DONG 2026-02-16
- เพิ่มหน้า Wallet History
- แก้ไขบัคจาก Review (15/02/2026)

---
### DONG 2026-02-15
- upgrade version v3.0.0(25)
- แก้ไข Icon Error ของ App ให้ใช้ BrownyError1
- เพิ่มการทำงานหน้าแสดง Map 
  - ปรับการแสดงช่อง Search ให้แสดง Icon ของ Store
  - ให้สามารถดูข้อมูลของแต่ละ Store ได้
- แก้ไข QR หน้าเติมเงิน บันทึกรูปภาพจากปุ่มบันทึกไม่ได้
- แก้ไข Browny Coin UI แสดงไม่ครบขาดห่วงไป
- แก้ไข เติมเงินขั้นต่ำ 100 แต่กรอกเลขเอง 1 บาทได้
- แก้ไข กรอกู OTP ไม่ถูก แต่เข้าได้
- แก้ไข Forgot password กำหนด endpoint ไม่ถูกต้อง
- ปรับปรุง Process การ save PIN ให้ call API เพื่อ savePIN และ Logic การ verify PIN

---
### DONG 2026-02-14
- เก็บ UI หน้า User Preferences ตาม Design
  - เพิ่ม function Logout, invit friend

---
### DONG 2026-02-12
- เพิ่มหน้า User Preferences (Draft)
- เพิ่มการแสดง Popup ในหน้าแรก
- เพิ่มหน้าสำหรับดู E-Voucher ของลูกค้าที่ซื้อเอาไว้
- Setup App Notification
  - Firebase-crashlytics สำหรับ Tracking Bug
  - Firebase-Messaging สำหรับ getToken และรอรับ Notification จาก firebase

---
### DONG 2026-02-11
- เพิ่ม Assets Menu หน้า home page (ยังไม่ implement การทำงาน)
- ปรับบ model รับข้อมูล E-Voucher ที่เป็นของ Customer ให้แสดงข้อมูลได้ถูกต้อง
- เก็บ logic การ Login ด้วย Social ให้ไปหน้า profile initial เมื่อเป็นการ login ครั้งแรก

---
### DONG 2026-02-08
- เพิ่มการ login ด้วย Social GOOGLE, Apple, LINE, FACEBOOK
- เพิ่ม Popup เงื่อนไขในหน้า claim coin (mockup ข้อมูล ตาม Design)
- เพิ่ม Popup เงื่อนไขวันเกิดในหน้า Profile Initial (mockup ข้อมูล ตาม Design)
- เพิ่ม Process การตั้งค่า PIN, Biometric หลังจากที่มีการ Login เข้าใช้งาน
- ปรับ UI หน้าซื้อ E-Voucher ด้วย Design UX/UI ใหม่
  - ขึ้น UI Reciept และ function การ Share, Save
  - เก็บ Logic การสั่งซื้อ E-Voucher

---
### DONG 2026-02-01
- ปรับ UI หน้าซื้อ E-Voucher ด้วย Design UX/UI ใหม่
  - เก็บ Logic การสั่งซื้อ E-Voucher (ยังไม่เสร็จ)
- เพิ่มหน้า Map สำหรับดูสาขา
- เก็บ Process Forgot password
- เก็บรายละเอียดตาม Review
  - ปุ่มเปิดกล้่องที่ bottomNav
  - สมัคร กดกลับหน้า PIN เอาปุ่มกลับออก
  - (BUG) หน้าตั้งค่าโปรไฟล์ ข้าม ไม่ได้
  - ออกจากระบบ -> หน้าหลัก
  - หน้ารายละเอียด E-Voucher หัว รายละเอียด, เงื่อนไขบริการ ออก
  - ปิด Soft-keyboard หลังกดปุ่มต่างๆ
- Initialize app to Firebase

---
### DONG 2026-01-22
- เก็บ Logic หน้าการรับ Coin
- เพิ่ม Banner เก็บได้ทุกวัน จุดการ์ด Browny coin
- เพิ่มหน้า เก็บคูปอง (กำลัง develop)

---
### DONG 2026-01-12
- เพิ่มหน้าการรับ Coin
  - เชื่อม API ทั้งขา fetch มาแสดงและขา claim แล้ว
  - มีปรับแก้ฝั่ง API เพิ่มเติม ณ วันที่ comment logic การ highlight วันที่รับ Coin แล้วจะยังไม่ทำงาน
- เพิ่ม Popup invit friend เพื่อไปหน้าข้อมูลการ ชวนเพื่อน
  - - เปิดทุกครั้งที่เข้าหน้าแรก (ทำเพื่อทดสอบเข้าหน้า ต้องปรับ Logic ตามทีหลัง)

---
### DONG 2026-01-12
- build 3.0.0(21) เป็นตัว update progress ล่าสุด ซึ่งยังไม่ครบใน phase1
  - ที่เล่นได้แล้วจะมี
    - login
    - Register
    - ตั้ง Pin, Biometric
    - ตั้งค่า Profile
    - เติมเงิน
    - Scan QRCode (Scan ติดแล้วแต่ยังไม่มี Process อะไรต่อ)
    - History(เป็น Mockup Data รอ API)

---
### DONG 2026-01-11
- เพิ่มหน้า Wallet
 - Process การ topup, QRCode Display, Slip (Mockup Data)
- เก็บรายละเอียดหน้า ProfilePage
- Process การสมัครสมาชิก
 - หน้าเก็บรายละเอียดหน้า Pin input

---
### DONG 2025-12-02
- Process การสมัครสมาชิก
  - หน้า Pin input (ยังไม่เสร็จ)
  - ปรับ Logic รองรับการสมัครสมาชิกและส่งค่าไปหน้า Pin input (ยังไม่เรียบร้อย)
  - เพิ่ม Wording en, th, zh สำหรับ Process การสมัครสมาชิก
- เพิ่มหน้า ProfilePage (ยังไม่เสร็จ)

---
### DONG 2025-11-26
- เพิ่ม Logic การ Login ด้วย User ที่มีอยู่ในระบบแล้ว
  - fetch data จาก API เพิ่มแสดงยอดเงินคงเหลือ, คอยน์ ในหน้า home
  - login และ caching ข้อมูล User ที่ login ได้สำเร็จ
  - handle การ Login ด้วย case error ต่างๆ ที่อาจเกิดขึ้น
- เพิ่ม Logic การดึงข้อมูล customer ที่เคย Login เอาไว้แล้วมาใช้งานต่อ

---
### DONG 2025-11-19
- ขึ้นหน้า HomePage
  - ส่วนการแสดง TP Wallet, Coin, การ Login
- Authen process
  - login ```(on develop)```
  - sign up ```(draft)```
  - forgot password ```(draft)```

---
### DONG 2025-11-11
- วางโครงสร้าง Project
  - --ลบ platform ที่ไม่รองรับ windows, linux--
- เพิ่ม BottomNavigation Design Browny
- เพิ่มหน้า OnBoardingPage
- ขึ้นหน้า HomePage (ยังไม่เสร็จ)