# Testing Review Rules — BC-TEST

---

## BC-TEST-001 — Posting/бичилтийн өөрчлөлтөд тест байхгүй

- **Severity:** MEDIUM
- **Rule:** Ledger бичилт, дүнгийн тооцоолол, validation-д нөлөөлөх өөрчлөлт
  ирсэн мөртлөө дагалдах тест байхгүй/өөрчлөгдөөгүй бол илрүүлнэ.
- **Why:** Base App-ийн бүх posting өөрчлөлт ERM/SCM тесттэй хамт явдаг; ledger үр
  дүнг шалгадаг тестгүй өөрчлөлт нь regression-ийг зөвхөн production дээр илрүүлнэ.
- **Risk:** Санхүүгийн regression — хамгийн үнэтэй ангиллын алдаа.
- **Detection:** Diff-д Post*/Validate логик өөрчлөгдсөн ч Tests төрлийн файл
  өөрчлөгдөөгүй.
- **Suggested Fix:** Дор хаяж: амжилттай бичилтийн ledger шалгалт + negative тест +
  rollback шалгалт (алдааны дараа юу ч бичигдээгүй) гэсэн гурван тест шаард.

---

## BC-TEST-002 — Negative/rollback тест дутуу

- **Severity:** MEDIUM
- **Rule:** Validation нэмэгдсэн бол түүний ажиллах (asserterror) тест;
  алдааны дараах төлөв (юу ч бичигдээгүй) шалгадаг тест байхгүй бол илрүүлнэ.
- **Why:** Стандарт тест: `asserterror Post...; Assert.ExpectedError(...);
  VerifySalesOrderNotPosted(...)` — алдаа нь зөв гарч, өгөгдөл цэвэр үлдсэнийг
  хоёуланг баталдаг.
- **Detection:** Шинэ Error/TestField-д харгалзах asserterror тест; Commit-тэй
  урсгалд partial-state тест.
- **Suggested Fix:** Error зам бүрд asserterror + NotPosted/NoEntries шалгалт нэм.

---

## BC-TEST-003 — Идемпотенц/давталтын тест дутуу

- **Severity:** MEDIUM
- **Rule:** Давтан ажиллаж болзошгүй урсгалд (API bound action, Job Queue task,
  импорт, retry-тэй илгээлт) давтан дуудлагын тест байхгүй бол илрүүлнэ.
- **Why:** Идемпотенцийн алдаа зөвхөн давтан дуудлагад илэрдэг тул ердийн happy-path
  тест барьж чаддаггүй.
- **Detection:** BC-POST-001/BC-INT-001 хамгаалалт нэмэгдсэн газарт "хоёр удаа
  дуудаад нэг л үр дүн" тест байгаа эсэх.
- **Suggested Fix:** Процессыг хоёр удаа ажиллуулж бичлэгийн тоо/дүн өөрчлөгдөөгүйг
  шалгадаг тест нэм.

---

## BC-TEST-004 — Тестийн тусгаарлалт ба Library хэрэглээ

- **Severity:** LOW
- **Rule:** Тест demo өгөгдөл/hardcoded дугаарт найдах, тест хоорондын дараалалд
  найдах, Initialize/Setup restore байхгүй, Library биш гараар мастер угсрах
  тохиолдлуудыг илрүүлнэ.
- **Why:** Стандарт: Library - * + Initialize() + LibrarySetupStorage.Restore() —
  тест дангаараа, ямар ч дарааллаар ажиллана.
- **Detection:** `'10000'` маягийн hardcoded дугаар; isInitialized pattern байхгүй;
  Setup өөрчилснөө буцаадаггүй.
- **Suggested Fix:** Library ашигла; Initialize pattern нэвтрүүл.

---

## BC-TEST-005 — Assertion-гүй/сул тест

- **Severity:** MEDIUM
- **Rule:** Тест процесс ажиллуулаад үр дүнг шалгадаггүй (Assert байхгүй), эсвэл
  зөвхөн "алдаа гараагүй" гэдгийг шалгадаг бол илрүүлнэ.
- **Why:** Ledger үр дүн, статус, талбарын утга шалгаагүй тест regression-ийг
  барихгүй — хуурамч ногоон.
- **Detection:** [Test] procedure-д Assert./asserterror байхгүй; Verify* helper
  дуудаагүй.
- **Suggested Fix:** Үр дүнгийн бүрэн шалгалт нэм (entries, amounts, status).

---

## BC-TEST-006 — Handler-ийн зөв хэрэглээ

- **Severity:** LOW
- **Rule:** UI dialog гардаг урсгалыг тестлэхдээ handler ([ConfirmHandler] г.м.)
  байхгүй; эсвэл handler дотор болзолгүй Reply := true (алдааг нууж болзошгүй)
  бол илрүүлнэ.
- **Detection:** HandlerFunctions attribute vs урсгалын dialog-ууд; handler-ийн
  question параметр шалгадаг эсэх.
- **Suggested Fix:** Handler-д асуултын текст шалгаж зөв хариулт өг.
