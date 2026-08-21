# Architecture Review Rules — BC-ARCH

---

## BC-ARCH-001 — Ledger руу шууд бичилт (давхаргын зөрчил)

- **Severity:** CRITICAL
- **Rule:** Ledger/register хүснэгтэд posting engine-ийн гадуур бичилт. (Дэлгэрэнгүй
  нь BC-POST-002 — энд давхаргын зөрчлийн өнцгөөс: бичилт нь Journal → Post Line →
  Ledger сувгаар л явна.)
- **Detection/Fix:** BC-POST-002-ыг үз.

---

## BC-ARCH-002 — Page дээрх бизнес логик

- **Severity:** HIGH
- **Rule:** Page/Page Extension-ий trigger, action дотор өгөгдөл өөрчлөх урсгал,
  тооцоолол, олон record-ын боловсруулалт байвал илрүүлнэ. (Visibility, style,
  notification, lookup зэрэг UI логик зөвшөөрөгдөнө.)
- **Why:** Base App-ийн page-ууд нимгэн: action → codeunit delegate. Логик page-д
  байвал API/batch/тестээс дахин ашиглагдахгүй, permission нь хэрэглэгчийн эрхээр
  хязгаарлагдана.
- **Risk:** Давхардсан логик, тест хийгдэхгүй код, API зан төлөвийн зөрүү.
- **Detection:** Page action/trigger-ийн бие > 10 мөр бизнес үйлдэлтэй; Rec-ээс
  бусад хүснэгтийн Modify/Insert page код дотор.
- **Suggested Fix:** Codeunit үүсгэж нүүлгэ; page-ээс нэг мөрөөр дууд.

---

## BC-ARCH-003 — Модулийн хил зөрчсөн хамаарал

- **Severity:** MEDIUM
- **Rule:** Custom модуль өөр функциональ модулийн дотоод хэрэгжилт рүү (Impl.
  codeunit, буфер хүснэгт, internal procedure) хамаарал үүсгэж байвал; ерөнхий
  зориулалтын кодыг тодорхой домэйноос хамааралтай болгож байвал илрүүлнэ.
- **Why:** Base App: модулиуд facade/event/interface-ээр харилцдаг; internal
  хэрэгжилт өөрчлөгдөхөд гадна код эвдэрдэггүй.
- **Detection:** `using`-д өөр домэйны Impl namespace; Access=Internal объект руу
  хандах оролдлого; туслах (utility) codeunit дотор бизнес домэйны хүснэгт.
- **Suggested Fix:** Public facade/event ашигла; хамаарлыг interface-ээр урвуула.

---

## BC-ARCH-004 — Тохиромжгүй extensibility цэг сонгосон

- **Severity:** MEDIUM
- **Rule:** Стандарт зан төлөвийг өөрчлөхөд: байгаа event/interface-ийг ашиглахын
  оронд кодыг хуулбарлах (copy-paste posting routine), эсвэл олон event-д тархсан
  нөхцөлт hack хийж байвал илрүүлнэ.
- **Why:** Sales-Post дээр 100+ event цэг бий; Invoice Posting, Price Calculation
  interface-ууд солигдох боломжтой. Хуулбарласан engine нь хувилбар шинэчлэлтэд
  хоцорч зөрүү үүсгэдэг.
- **Risk:** Upgrade бүрт зөрүү; стандарт fix-үүд хуулбарт очихгүй.
- **Detection:** Стандарт codeunit-ийн том хэсэгтэй ижил custom код; "custom
  posting" гэх боловч стандарт баримт бичдэг routine.
- **Suggested Fix:** Тохирох event/interface цэгийг олж түүн дээр суурил;
  шаардлагатай event байхгүй бол Microsoft-оос event хүсэх (BCApps-д PR/issue).

---

## BC-ARCH-005 — Global state-ийн зохисгүй хэрэглээ

- **Severity:** MEDIUM
- **Rule:** Single-instance codeunit эсвэл global хувьсагчаар session-ийн турш
  бизнес төлөв хадгалж, цэвэрлэгдэхгүй байвал илрүүлнэ.
- **Why:** Base App posting engine global-уудаа `ClearAllVariables()`-аар нэг
  posting-ийн хүрээнд цэвэрлэдэг; single-instance нь зөвхөн setup cache,
  UI state зэрэгт.
- **Risk:** Өмнөх дуудлагын үлдэгдэл төлөв дараагийн үйлдэлд нөлөөлөх
  (том хэмжээний зөрчилтэй бичилт болж хувирдаг ангилалын алдаа).
- **Detection:** SingleInstance = true + бизнес өгөгдөл хадгалдаг global; posting
  чиглэлийн codeunit-д Clear хийгдээгүй global-ууд.
- **Suggested Fix:** Процесс эхлэхэд Clear; төлвийг параметрээр дамжуул.
