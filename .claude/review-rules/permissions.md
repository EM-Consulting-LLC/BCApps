# Permissions Review Rules — BC-PERM

---

## BC-PERM-001 — Хэрэглэгчид ledger-ийн шууд бичих эрх

- **Severity:** CRITICAL
- **Rule:** Assignable permission set-д ledger/posted хүснэгтэд том үсгийн I/M/D
  (direct) эрх олгогдож байвал илрүүлнэ.
- **Why:** Base App-ийн permission set-үүд ledger-т ихэвчлэн R + жижиг үсгийн imd
  (indirect) өгдөг — бичилт зөвхөн posting codeunit-ээр. Том үсгийн эрх нь
  хэрэглэгч ямар ч объектгүйгээр (API, configuration package) ledger засах боломж.
- **Risk:** Санхүүгийн өгөгдөл гуйвуулах, audit bypass.
- **Detection:** permissionset файлд `tabledata "G/L Entry" = RIMD` маягийн мөр;
  `*Ledger Entry`, `* Register`, posted document хүснэгтүүдэд I/M/D том үсэгтэй.
- **Example — Good:** `tabledata "Loyalty Ledger Entry" = Rimd` (унших шууд,
  бичих зөвхөн codeunit-ээр).
- **Suggested Fix:** Жижиг үсэгт шилжүүлж, бичдэг codeunit-д Permissions property нэм.

---

## BC-PERM-002 — Codeunit-ийн Permissions property хэт өргөн

- **Severity:** HIGH
- **Rule:** Codeunit-ийн Permissions property-д уг codeunit-ийн бодит хэрэглээнээс
  илүү хүснэгт/үйлдэл зарлагдсан бол илрүүлнэ (ялангуяа TableData = rimd бүгдэд).
- **Why:** CU 80: G/L Entry-д зөвхөн `r` — бичилт CU 12-ийн эрхээр. Property нь
  "энэ codeunit юу хийж чадах вэ" гэдгийн аудит; өргөн байвал escalation цэг болно.
- **Risk:** Уг codeunit-ээр дамжсан ямар ч код (event subscriber!) өргөн эрхтэй
  ажиллана — privilege escalation.
- **Detection:** Permissions жагсаалтын хүснэгт бүрд codeunit доторх бодит
  үйлдлүүдийг тааруул: d зарлаад Delete байхгүй, m зарлаад Modify байхгүй г.м.
- **Suggested Fix:** Ашиглаагүй эрхийг хас; бичилт өөр codeunit-ийн үүрэг бол
  түүнд нь үлдээ.

---

## BC-PERM-003 — Шинэ объектын permission бүрхэлт

- **Severity:** MEDIUM
- **Rule:** Шинэ table/page/codeunit/report нэмэгдсэн мөртлөө аль ч permission
  set-д ороогүй, эсвэл зөвхөн админ багцад орсон бол илрүүлнэ.
- **Why:** InherentPermissions/Entitlements X биш л бол permission-гүй объектыг
  энгийн хэрэглэгч ашиглаж чадахгүй — feature нь SUPER-т л ажилладаг далд гажиг үүснэ.
- **Detection:** Diff-ийн шинэ объектуудыг permissionset файлуудтай тулга.
- **Suggested Fix:** Read/User/Edit/Admin түвшний багцуудад тохирох эрх нэм;
  объектын permission (page/codeunit X) мартагдсан бол мөн нэм.

---

## BC-PERM-004 — TestPermissions болон эрхийн тест

- **Severity:** LOW
- **Rule:** Permission set өөрчлөгдсөн/шинэ feature-т permission тест байхгүй;
  тест бүгд TestPermissions = Disabled бол илрүүлнэ.
- **Why:** Tests/Permissions хавтас тусдаа байдаг — эрхийн регрессийг барьдаг.
- **Suggested Fix:** Гол хэрэглэгчийн сценариог тухайн permission set-тэй
  ажиллуулах тест нэм.

---

## BC-PERM-005 — InherentPermissions / SecurityFiltering

- **Severity:** HIGH
- **Rule:** `[InherentPermissions(...)]`, `[SecurityFiltering(SecurityFilter::Ignored)]`,
  `SecurityFilter := SecurityFilter::Filtered` өөрчлөлтүүд тайлбар, хамгаалалтгүй
  нэмэгдэж байвал илрүүлнэ.
- **Why:** Эдгээр нь хэрэглэгчийн эрх/шүүлтийг алгасдаг онцгой механизм — Base App
  маш цөөн, зориудын газарт хэрэглэдэг.
- **Risk:** Хэрэглэгч харах ёсгүй өгөгдөлдөө хүрэх, security filter bypass.
- **Detection:** Diff-д эдгээр attribute; ямар өгөгдөлд, яагаад гэдгийг үнэл.
- **Suggested Fix:** Зайлшгүй бол хүрээг нь хамгийн жижиг record/үйлдэлд хязгаарлаж,
  шалтгааныг комментоор баримтжуул; үгүй бол устга.
