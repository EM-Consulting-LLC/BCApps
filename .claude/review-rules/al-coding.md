# AL Coding Review Rules — BC-AL

---

## BC-AL-001 — GuiAllowed-гүй UI дуудлага

- **Severity:** HIGH
- **Rule:** Confirm/Message/Dialog/Page.Run* дуудлага GuiAllowed() шалгалтгүй бөгөөд
  код нь posting, API, Job Queue, web service замаар дуудагдаж болзошгүй бол илрүүлнэ.
- **Why:** Base App бүх dialog-оо `GuiAllowed()` (+HideProgressWindow) шалгалттай
  хийдэг; background session-д UI дуудлага exception болно.
- **Risk:** Job Queue posting унах, API 500 буцаах.
- **Detection:** `Confirm(`, `Message(`, `Dialog.Open`, `Page.RunModal` — дуудагдах
  контекстыг (posting урсгал, event subscriber, API) хамт үнэл.
- **Example — Good:** `if GuiAllowed() and not HideDialog then Window.Open(...);`
  батжуулалтад `Confirm Management` codeunit (GuiAllowed-ийг өөрөө шалгадаг).
- **Suggested Fix:** GuiAllowed guard нэм эсвэл Confirm Management ашигла; batch-д
  HideDialog параметр нэвтрүүл.

---

## BC-AL-002 — Hardcoded хэрэглэгчийн текст

- **Severity:** MEDIUM
- **Rule:** Error/Message/Confirm-д string literal шууд бичсэн, эсвэл Label-д
  placeholder байгаа ч Comment байхгүй бол илрүүлнэ.
- **Why:** Бүх хэрэглэгчийн текст Label-ээр орчуулагддаг; Comment нь орчуулагчид
  placeholder-ийн утгыг тайлбарладаг. Locked = true нь орчуулагдахгүй токенд.
- **Risk:** Локалчлол эвдэрнэ; олон хэлний хэрэглэгчид ойлгомжгүй.
- **Detection:** `Error('...')`, `Message('...')` literal-тай; `%1` бүхий Label
  Comment-гүй.
- **Suggested Fix:** Label зарлаж Comment бич; техникийн токенд Locked = true.

---

## BC-AL-003 — Text overflow / CopyStr дутуу

- **Severity:** MEDIUM
- **Rule:** Урт эх утгыг богино Code/Text талбарт шууд олгож байвал (runtime
  overflow error боломж) илрүүлнэ.
- **Why:** Base App: `CopyStr(Uri, 1, MaxStrLen(Rec."Request URI Preview"))` хэлбэрийг
  тогтмол ашигладаг.
- **Risk:** Тодорхой өгөгдөл дээр л илэрдэг runtime алдаа (тестээс мултардаг).
- **Detection:** Гадаад/JSON/тооцоолсон Text утгыг талбарт `:=`-ээр олгох; ялгаатай
  урттай талбар хооронд хуулах.
- **Suggested Fix:** `CopyStr(Value, 1, MaxStrLen(Target))`; тасалдах нь болохгүй
  бол урьдчилан урт шалгаж алдаа өг.

---

## BC-AL-004 — IsHandled pattern-ийн зөрчил

- **Severity:** MEDIUM
- **Rule:** Public/чухал процесст OnBefore event нь IsHandled параметргүй, эсвэл
  IsHandled := false reset хийлгүй event дуудаж байвал; өөрийн event-ийн үр дүнг
  үл хэрэгсэж байвал илрүүлнэ.
- **Why:** Стандарт хэлбэр: `IsHandled := false; OnBeforeX(..., IsHandled);
  if IsHandled then exit;` — reset хийхгүй бол өмнөх утга үлдэж санамсаргүй skip
  хийгдэж болно.
- **Risk:** Extension-үүд процессыг орлож чадахгүй; давтан дуудлагад алдаатай skip.
- **Detection:** `OnBefore*` дуудлагын өмнөх мөрөнд `IsHandled := false;` байгаа
  эсэх; event-ийн дараа if шалгалт байгаа эсэх.
- **Suggested Fix:** Стандарт гурван мөрийн хэлбэрт оруул.

---

## BC-AL-005 — Object/талбарын нэршил ба бүтэц

- **Severity:** LOW
- **Rule:** Дараах конвенцоос гажилт: Temp хувьсагч Temp* угтваргүй; procedure нэр
  үйл үгээр эхлээгүй; global хувьсагч шаардлагагүй өргөн хүрээтэй; nested if-ийн
  оронд guard clause ашиглах боломжтой гүн nesting; нэг procedure олон үүрэгтэй.
- **Why:** Base App-ийн код жижиг, нэг үүрэгтэй procedure, named return value,
  guard clause хэв маягтай.
- **Risk:** Уншигдах/засварлагдах чанар.
- **Detection:** Кодын бүтцийн ажиглалт; > 100 мөр procedure, 4+ түвшний nesting.
- **Suggested Fix:** Задал, нэрлэ, guard clause хэрэглэ. (Style-only findings-ийг
  зөвхөн бусад асуудалтай хамт, товч дурд.)

---

## BC-AL-006 — Obsolete lifecycle-гүй breaking change

- **Severity:** HIGH (public API-д), MEDIUM (дотоод)
- **Rule:** Public object, procedure, event, талбар, enum утга устгагдаж/нэр
  өөрчлөгдөж байвал ObsoleteState = Pending үе шат дамжаагүйг илрүүлнэ.
- **Why:** Base App 634 газар ObsoleteState-тэй — signature өөрчлөх бол шинэ
  нэмээд хуучныг Pending болгодог; `#if not CLEANxx`-ээр цэвэрлэдэг.
- **Risk:** Хамааралтай extension-ууд compile алдаатай болно (AppSource-д хориотой).
- **Detection:** Diff-д public procedure/event/талбар устгагдсан эсвэл параметр
  өөрчлөгдсөн; Obsolete* шинж чанар nemэгдээгүй.
- **Suggested Fix:** Хуучныг ObsoleteState = Pending + Reason + Tag-тай үлдээж,
  шинэ хувилбар нэм.

---

## BC-AL-008 — Hardcoded мастер өгөгдөл / setup утга

- **Severity:** MEDIUM (бичилтэд ашиглагдвал HIGH)
- **Rule:** G/L данс, journal template/batch, location, dimension код, No. Series
  код зэрэг тохиргооны утгыг код дотор literal-аар бичсэн бол илрүүлнэ.
- **Why:** Base App эдгээрийг үргэлж Setup хүснэгтээс авдаг (Source Code Setup,
  Sales & Receivables Setup, General Posting Setup гэх мэт) — компани бүрийн
  дансны төлөвлөгөө өөр, орчинд шилжүүлэхэд утга өөрчлөгддөг.
- **Risk:** Өөр компанид/production-д буруу данс руу бичилт; тохиргоо солиход
  код засах шаардлага.
- **Detection:** `'998877'` маягийн Code literal данс/template параметрт;
  Get/TestField-гүй шууд утга.
- **Example — Good:**
  ```al
  RebateSetup.Get();
  RebateSetup.TestField("Rebate G/L Account No.");
  exit(RebateSetup."Rebate G/L Account No.");
  ```
- **Suggested Fix:** Setup хүснэгт/талбар үүсгэж TestField-тэй уншиж хэрэглэ.

---

## BC-AL-007 — DataClassification болон ApplicationArea дутуу

- **Severity:** LOW
- **Rule:** Шинэ талбарт DataClassification буруу/байхгүй (хувь хүний өгөгдөлд
  CustomerContent биш), page талбарт ApplicationArea/ToolTip байхгүй бол илрүүлнэ.
- **Why:** GDPR ангилал + UI стандарт (Base App шинэ талбаруудад ToolTip заавал).
- **Detection:** Table diff — DataClassification; Page diff — ApplicationArea, ToolTip.
- **Suggested Fix:** Зөв ангилал, ApplicationArea, ToolTip нэм.
