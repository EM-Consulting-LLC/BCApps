# Extensibility Review Rules — BC-EXT

---

## BC-EXT-001 — Стандарт кодыг хуулбарлах (copy-paste engine)

- **Severity:** HIGH
- **Rule:** Стандарт posting/тооцооллын codeunit-ийн логикийг хуулж өөрчилсөн
  custom хувилбар (жишээ: өөрийн "Sales-Post lite") илрүүлнэ.
- **Why:** Стандарт engine event/interface-ээр өргөтгөгдөхөөр зохиогдсон; хуулбар
  нь Microsoft-ийн bug fix, татварын өөрчлөлтүүдээс хоцордог.
- **Risk:** Хувилбар шинэчлэлт бүрт зөрүү; давхар засвар.
- **Detection:** Стандарт CU-ийн бүтэцтэй ижил урт procedure-ууд; posted хүснэгтэд
  бичдэг стандарт бус routine.
- **Suggested Fix:** Event цэг/interface-ээр стандарт урсгалд шигтгэ; боломжгүй бол
  зөрүүг documented, минимал байлга.

---

## BC-EXT-002 — Extensibility цэг нээгээгүй custom код

- **Severity:** MEDIUM
- **Rule:** Дахин ашиглагдах/өргөтгөгдөх магадлалтай public процесст OnBefore/
  OnAfter event, IsHandled боломж байхгүй монолит хэрэгжилт илрүүлнэ.
- **Why:** Base App бүх чухал урсгалдаа event цэг нээдэг — өөрийн апп дотор ч
  ижил зарчим (өөр багийн extension чинийхээс хамаарч болно).
- **Risk:** Дараагийн өөрчлөлт бүр base кодоо засахад хүрнэ.
- **Detection:** Модулийн гол урсгалын procedure-уудад IntegrationEvent байхгүй.
- **Suggested Fix:** Гол цэгүүдэд OnBefore(+IsHandled)/OnAfter event нэм.

---

## BC-EXT-003 — Enum + Interface-ийн оронд hardcoded салаалалт

- **Severity:** MEDIUM
- **Rule:** Солигдох боломжтой algorithm-ийг case/if-ээр hardcode хийж, шинэ
  хувилбар нэмэхэд base кодыг засахаас өөр аргагүй болгож байвал илрүүлнэ.
- **Why:** Price Calculation, Invoice Posting: Extensible enum + interface —
  гуравдагч тал enum extension-ээр шинэ хэрэгжилт бүртгэдэг.
- **Detection:** `case Type of` дотор төрөл бүрт бизнес хэрэгжилт; extensible
  байх ёстой enum `Extensible = false`.
- **Suggested Fix:** Interface гаргаж enum-оор сонгуул; enum-ийг Extensible болго.

---

## BC-EXT-004 — Obsolete-гүй өөрчлөлт нийтийн гадаргуу дээр

- **Severity:** HIGH
- **Rule:** Нийтэд ил procedure/event/талбар/enum утгын устгал, signature өөрчлөлт
  Obsolete үе шатгүй хийгдэж байвал илрүүлнэ. (BC-AL-006-тай ижил — extensibility
  өнцгөөс: event-ийн параметр өөрчлөх нь бүх subscriber-ийг эвднэ.)
- **Detection:** Diff-д event signature өөрчлөлт; [Obsolete...] байхгүй устгал.
- **Suggested Fix:** Шинэ event нэмж хуучныг ObsoleteState = Pending болго.

---

## BC-EXT-005 — TableExtension доторх зохисгүй агуулга

- **Severity:** MEDIUM
- **Rule:** Table extension-д: том бизнес урсгал trigger дотор, өөр модулийн
  өгөгдлийг удирдах логик, стандарт талбарын утгыг event-гүйгээр дарж бичих
  оролдлого илрүүлнэ.
- **Why:** Base App-ийн table extension-ууд талбар + богино validation л агуулдаг;
  урсгалын логик subscriber codeunit-д.
- **Detection:** TableExt trigger-ийн урт/дуудлагууд.
- **Suggested Fix:** Логикийг codeunit рүү нүүлгэж table ext-ийг өгөгдлийн
  тодорхойлолт болго.
