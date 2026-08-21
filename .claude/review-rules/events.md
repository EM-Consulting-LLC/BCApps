# Events Review Rules — BC-EVT

---

## BC-EVT-001 — Subscriber доторх Commit / transaction эвдрэл

- **Severity:** CRITICAL
- **Rule:** Event subscriber (ялангуяа table event, posting event) дотор Commit()
  дуудагдаж байвал илрүүлнэ.
- **Why:** Subscriber нь host transaction-ий нэг хэсэг. Host-ийн rollback хил
  subscriber-ийн Commit-ээр эвдэрнэ. Microsoft үүнээс хамгаалж posting-ийн мөр
  боловсруулалтыг CommitBehavior::Ignore-оор ороодог — өөрөөр хэлбэл subscriber-т
  Commit хийх нь дизайны хувьд хориотой гэдгийг платформын түвшинд илэрхийлсэн.
- **Risk:** Хагас posting үлдэх, preview бодит бичилт болох.
- **Detection:** [EventSubscriber] attribute-тай procedure-ийн биед (шууд болон
  дуудсан helper-үүдэд) Commit().
- **Suggested Fix:** Commit-ийг устга; тусдаа transaction зайлшгүй бол queue табл +
  Job Queue-ээр тусгаарла.

---

## BC-EVT-002 — Subscriber-ийн guard дутуу

- **Severity:** MEDIUM
- **Rule:** Table/posting event subscriber-т дараах guard-ууд байхгүй бол илрүүлнэ:
  `Rec.IsTemporary()`, хоосон түлхүүр (`Rec."No." = ''`), posting event-д
  PreviewMode, шаардлагатай бол RunTrigger.
- **Why:** DocumentAttachmentMgmt-ийн бүх subscriber эдгээр guard-тай: temp record
  дээр side-effect хийхгүй, дутуу record дээр ажиллахгүй.
- **Risk:** Temp/буфер record-оос бодит өгөгдөл үүсэх; preview-д бодит бичилт;
  давхар боловсруулалт.
- **Detection:** Subscriber биеийн эхний мөрүүдэд эдгээр шалгалт байгаа эсэх;
  event signature-т PreviewMode параметр байгаа ч ашиглаагүй.
- **Suggested Fix:** Guard-уудыг эхэнд нэм.

---

## BC-EVT-003 — IsHandled-ийг болзолгүй/өргөн эзэмших

- **Severity:** HIGH
- **Rule:** OnBefore* event-ийн IsHandled параметрийг нөхцөлгүй эсвэл хэт өргөн
  нөхцөлд true болгож байвал илрүүлнэ.
- **Why:** IsHandled := true нь стандарт логикийг БҮРЭН унтраана; өөр extension-ий
  ижил event-ийн subscriber-тэй зөрчилдөнө (сүүлд ажилласан нь дийлнэ гэсэн
  баталгаа ч байхгүй).
- **Risk:** Стандарт validation/бичилт алгасагдах; extension хоорондын зөрчил.
- **Detection:** `IsHandled := true;` — ямар нөхцөлд хийгдэж буйг үнэл; өөрийн
  бүрэн орлуулах хэрэгжилт байгаа эсэхийг шалга (exit хийчихээд юу ч хийгээгүй
  бол стандарт үйлдэл зүгээр л алга болно).
- **Suggested Fix:** Нөхцөлийг аль болох нарийсга (зөвхөн өөрийн setup идэвхтэй,
  өөрийн document type гэх мэт); орлуулах логикоо бүрэн хэрэгжүүл.

---

## BC-EVT-004 — Subscriber доторх хүнд/гинжин үйлдэл

- **Severity:** HIGH
- **Rule:** OnAfterValidateEvent зэрэг өндөр давтамжийн event-ийн subscriber дотор:
  олон record-ын Modify, өөр талбарын Validate (гинжин event үүсгэх), bulk уншилт,
  тайлан ажиллуулах зэрэг хүнд үйлдэл байвал илрүүлнэ.
- **Why:** Validate бүрд дуудагддаг subscriber нь мөр олонтой баримтад үржвэрээр
  ажиллана; Validate → subscriber → Validate гинж нь рекурс/давталт үүсгэж болно.
- **Risk:** Гүйцэтгэлийн огцом уналт; stack overflow/давталт; түгжээ.
- **Detection:** Field-level event subscriber-т Modify(true)/Validate дуудлага;
  дуудагдах давтамжийг үнэл.
- **Suggested Fix:** Хөнгөн тэмдэглэгээ (флаг) хийгээд бодит ажлыг OnAfterModify/
  posting/Job Queue үед нэг удаа хий; рекурсээс single-instance флагаар хамгаал.

---

## BC-EVT-005 — Дарааллаас хамааралтай subscriber

- **Severity:** MEDIUM
- **Rule:** Нэг event-ийн олон subscriber бие биеийн үр дүнд найдаж байвал
  (нэг нь утга бэлдэж, нөгөө нь ашигладаг), эсвэл нэг өгөгдлийг хоёр subscriber
  зэрэг өөрчилдөг бол илрүүлнэ.
- **Why:** Subscriber-ийн execution order баталгаагүй.
- **Risk:** Орчноос хамаарсан (build бүрт өөр) зан төлөв.
- **Detection:** Ижил event дээрх олон subscriber-ийн бичдэг/уншдаг талбаруудын
  огтлолцол.
- **Suggested Fix:** Дараалал шаардлагатай логикийг нэг subscriber-т нэгтгэ; эсвэл
  эх процессын дараагийн event цэгийг ашигла.

---

## BC-EVT-006 — Manual binding-ийн зохисгүй хэрэглээ

- **Severity:** LOW
- **Rule:** EventSubscriberInstance = Manual codeunit-ийг Bind хийснээ Unbind
  хийдэггүй, эсвэл глобал sсope-д удаан barih; エсрэгээр — түр зуурын subscriber-ийг
  static (автомат) болгосон бол илрүүлнэ.
- **Why:** Sales-Post: BindSubscription(this) → ажил → UnbindSubscription(this)
  хосоор; Preview handler мөн ижил.
- **Risk:** Subscriber санамсаргүй идэвхтэй үлдэж давхар боловсруулалт.
- **Detection:** BindSubscription дуудлагад харгалзах Unbind байгаа эсэх (алдааны
  замд ч).
- **Suggested Fix:** Bind/Unbind-ийг нэг procedure-д хослуул.
