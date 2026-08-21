# Жишээ review тайлан (fixture дээр skill-ийг ажиллуулсан үр дүн)

> Энэ бол `tests/fixture/`-ийн 4 файлд skill-ийн зааврыг бүрэн дагаж хийсэн
> review-ийн жишээ output. Skill-ийн Review Output Format-ийн лавлагаа болно.

---

# Code Review Summary

## PR / Change Purpose

EMC Rebate extension: борлуулалтын нэхэмжлэх post хийгдэх үед харилцагчийн
Rebate %-иар урамшуулал тооцож Rebate Ledger Entry + G/L бичилт үүсгэх, гадаад
төлбөрийн системээс rebate төлбөр хүлээн авах API нэмж байна.

## Architecture Assessment

Өөрчлөлт нь BC-ийн posting архитектурын хэд хэдэн суурь зарчмыг зөрчиж байна:
бичилтийн идемпотенц огт хамгаалагдаагүй, дугаарлалт No. Series-ийн гадуур,
subscriber-ууд posting transaction-ийг эвдэж байна. G/L бичилтийг GenJnlPostLine-ээр
хийж буй нь зөв сонголт. Хэмжээ багатай ч CRITICAL түвшний олон эрсдэлтэй тул
одоо байгаа хэлбэрээрээ merge хийгдэх боломжгүй.

## Findings

### [CRITICAL] BC-EVT-001 — Subscriber дотор Commit
**Файл:** `RebateSubscribers.Codeunit.al`
**Байршил:** `OnAfterPostSalesDoc`
**Асуудал:** Sales-Post-ийн event subscriber дотор `Commit()` дуудаж байна.
**Яагаад асуудал вэ:** Subscriber нь posting transaction-ий нэг хэсэг. Энэ Commit
нь Sales-Post-ийн rollback хамгаалалтын хилийг эвдэнэ; мөн event-ийн
`SuppressCommit`, `PreviewMode` параметрүүдийг огт аваагүй тул preview/batch
горимд ч мөн адил ажиллана.
**Эрсдэл:** Posting-ийн сүүл хэсэгт алдаа гарвал хагас бичигдсэн төлөв үлдэнэ;
batch posting-ийн атомар чанар алдагдана.
**Санал болгож буй засвар:** Commit-ийг устгаж, subscriber-ийн signature-т
`PreviewMode`, `SuppressCommit` параметрүүдийг нэмж, `if PreviewMode then exit;`
guard тавь. Rebate бичилтийг queue хүснэгтэд бүртгээд Job Queue-ээр гүйцэтгэ.

### [CRITICAL] BC-POST-001 — Давхар rebate бичилтийн эрсдэл
**Файл:** `RebatePost.Codeunit.al`
**Байршил:** `PostRebateForInvoice`
**Асуудал:** Нэг invoice-д rebate аль хэдийн бичигдсэн эсэхийг шалгадаггүй.
**Яагаад асуудал вэ:** Стандарт posting нь дугаар урьдчилан хадгалах + conflict
шалгалтаар идемпотенц хангадаг. Энэ procedure давтан дуудагдвал (алдааны дараах
дахин post, event давхар ажиллах) Rebate Ledger Entry + G/L бичилт давхардана.
**Эрсдэл:** Давхар зарлагын бичилт — санхүүгийн тайлан зөрүүтэй болно.
**Санал болгож буй засвар:**
```al
RebateLedgerEntry.SetRange("Invoice No.", SalesInvHeader."No.");
if not RebateLedgerEntry.IsEmpty() then
    exit;
```
шалгалтыг `RebateLedgerEntry.LockTable()`-ийн дараа хий.

### [CRITICAL] BC-TXN-001 — Premature Commit (хагас гүйлгээ)
**Файл:** `RebatePost.Codeunit.al`
**Байршил:** `PostRebateForInvoice` — Rebate Ledger Entry Insert-ийн дараах `Commit()`
**Асуудал:** Rebate entry Insert хийгээд Commit хийсний ДАРАА G/L бичилт хийж байна.
**Яагаад асуудал вэ:** GenJnlPostLine унавал (данс хаалттай, огноо хориотой г.м.)
rebate entry үлдэж, G/L бичилт үлдэхгүй — хоёр бүртгэл зөрнө. Commit нь энд
legitimate 5 шалтгааны алинд ч хамаарахгүй.
**Эрсдэл:** Subledger ↔ G/L зөрүү; дахин post хийвэл (идемпотенц шалгалт нэмсэн ч)
G/L тал дутуу үлдэнэ.
**Санал болгож буй засвар:** Commit-ийг бүрмөсөн устга — entry + G/L нэг
transaction-д бичигдэж, алдаанд хамтдаа rollback хийгдэнэ.

### [CRITICAL] BC-EVT-003 / BC-POST-004 — Дугаар олголтыг болзолгүй орлуулсан
**Файл:** `RebateSubscribers.Codeunit.al`
**Байршил:** `OnBeforeUpdatePostingNo`
**Асуудал:** `IsHandled := true`-г болзолгүй тавьж, Posting No.-г timestamp-аар
үүсгэж байна.
**Яагаад асуудал вэ:** (1) БҮХ борлуулалтын баримтын дугаар олголт No. Series-ээс
гарч, өөр extension-ий ижил subscriber-тэй зөрчилдөнө. (2) Timestamp дугаар нь
зэрэгцээ posting-д мөргөлдөж болно, conflict шалгалтгүй, дахин post хийхэд ӨӨР
дугаар гарна — стандартын "нэг баримт нэг дугаар" идемпотенц эвдэрнэ.
(3) Дугаарын тасралтгүй байдлын (audit) шаардлага зөрчигдөнө.
**Эрсдэл:** Давхар/алдагдсан дугаар, аудит зөрчил, бусад extension эвдрэх.
**Санал болгож буй засвар:** Subscriber-ийг бүхэлд нь устгаж, тусгай дугаарлалт
хэрэгтэй бол тусдаа No. Series тохиргоо ашигла.

### [CRITICAL] BC-SEC-001 — Hardcoded API token
**Файл:** `RebateWebhookAPI.Page.al`
**Байршил:** `OnInsertRecord` — `Token := 'Bearer sk-live-9f8e7d6c5b4a'`
**Асуудал:** Live нууц түлхүүр эх кодод ил байна.
**Эрсдэл:** Repo хандалттай хэн ч төлбөрийн системийн эрхтэй болно; .app файлаас
сэргээгдэнэ.
**Санал болгож буй засвар:** Isolated Storage/Azure Key Vault-д хадгалж
`SecretText` + `SecretStrSubstNo`-оор дамжуул; одоогийн түлхүүрийг шууд хүчингүй болго.

### [CRITICAL] BC-INT-001 / BC-API-004 — API retry давхар мөр үүсгэнэ
**Файл:** `RebateWebhookAPI.Page.al`
**Байршил:** `OnInsertRecord`
**Асуудал:** `externalPaymentId` ("External Document No.")-ээр давхардлыг
шалгахгүйгээр journal мөр үүсгэж байна.
**Яагаад асуудал вэ:** Гадаад систем timeout-ийн дараа хүсэлтээ давтан илгээх нь
хэвийн (at-least-once). Одоогийн код давталт бүрт шинэ мөр үүсгэнэ.
**Эрсдэл:** Давхар төлбөрийн бичилт.
**Санал болгож буй засвар:** Insert-ийн өмнө `SetRange("External Document No.", ...)`
+ `IsEmpty()` шалгалт; олдвол одоо байгаа мөрийг буцаа (идемпотент response).

### [CRITICAL] BC-PERM-001 / BC-BIZ-001 — Ledger/posted хүснэгтийн direct эрх
**Файл:** `RebatePermissions.PermissionSet.al`
**Асуудал:** Assignable permission set-д `G/L Entry = RIMD`,
`Cust. Ledger Entry = RIMD`, `Sales Invoice Header = RIMD`.
**Яагаад асуудал вэ:** Хэрэглэгч ledger болон posted баримтыг ямар ч objectгүйгээр
(API, configuration package) шууд засах эрхтэй болно.
**Эрсдэл:** Санхүүгийн өгөгдөл гуйвуулах, audit bypass.
**Санал болгож буй засвар:** `= Rimd` (зөвхөн Read direct) болгож, бичилтийг
codeunit-ийн Permissions property-д даатга; Sales Invoice Header-ийг `= R`.

### [HIGH] BC-PERM-002 — Codeunit-ийн Permissions хэт өргөн
**Файл:** `RebatePost.Codeunit.al`
**Асуудал:** `G/L Entry = rimd`, `Cust. Ledger Entry = rimd`, `Sales Invoice
Header = rimd` зарлагдсан ч codeunit эдгээрт шууд бичдэггүй (G/L бичилт
GenJnlPostLine-ийн эрхээр хийгддэг).
**Санал болгож буй засвар:** Зөвхөн `"Rebate Ledger Entry" = rim` үлдээ.

### [HIGH] BC-TXN-004 / BC-INT-002 / BC-SEC-005 — Transaction доторх шалгалтгүй HTTP
**Файл:** `RebateWebhookAPI.Page.al`
**Байршил:** `OnInsertRecord`
**Асуудал:** (1) Insert хийсний дараа uncommitted төлөвтэйгээр HTTP Post;
(2) Response-ийн статус огт шалгаагүй; (3) endpoint нь http:// (TLS-гүй).
**Эрсдэл:** Гадаад тал "болсон" гэж үзээд BC тал rollback хийгдэх зөрүү; амжилтгүй
confirm чимээгүй алгасагдана; token сүлжээгээр ил дамжина.
**Санал болгож буй засвар:** Insert → Commit → TrySend + статус шалгалт + statuс
машин; https болго.

### [HIGH] BC-EVT-004 — Quantity validate бүрт бүх мөрийг дахин бичих
**Файл:** `RebateSubscribers.Codeunit.al`
**Байршил:** `OnValidateQuantity`
**Асуудал:** Sales Line-ийн Quantity-ийн OnAfterValidateEvent дотор баримтын БҮХ
мөр дээр `Validate("Line Discount %") + Modify(true)` давталт хийж байна.
**Яагаад асуудал вэ:** Validate бүрт бүх мөр дахин бичигдэнэ (N мөртэй баримтад
O(N²)); Validate → бусад subscriber → гинжин хэлхээ, өөрийгөө дахин дуудах
эрсдэлтэй; мөн Rec-ийн өөрийнх нь мөрийг зэрэг Modify хийж буфер зөрчил үүсгэнэ.
**Санал болгож буй засвар:** Зөвхөн Rec мөрийн discount-ийг тооцох; баримтын
түвшний бодлого бол Release/posting-ийн өмнө нэг удаа хэрэглэ.

### [HIGH] BC-AL-001 — Confirm posting урсгалд
**Файл:** `RebatePost.Codeunit.al`
**Байршил:** `PostRebateForInvoice` — `Confirm('Rebate амжилттай бичигдлээ...')`
**Асуудал:** GuiAllowed шалгалтгүй Confirm; энэ procedure нь OnAfterPostSalesDoc
subscriber-ээс дуудагддаг тул Job Queue/API/batch posting-д exception болно.
Мөн текст нь hardcoded (BC-AL-002).
**Санал болгож буй засвар:** Confirm-ийг устгаж имэйл илгээлтийг тохиргоогоор
удирд; texт хэрэгтэй бол Label зарла.

### [HIGH] BC-POST-004 — Entry No. FindLast+1
**Файл:** `RebatePost.Codeunit.al` (`GetLastEntryNo`), `RebateWebhookAPI.Page.al` (`GetNextLineNo`)
**Асуудал:** LockTable-гүй FindLast + 1 дугаарлалт — зэрэгцээ session-д мөргөлдөнө.
**Санал болгож буй засвар:** Rebate Ledger Entry-д AutoIncrement эсвэл бичилтийн
өмнө LockTable + FindLast; journal мөрөнд стандарт line no. олголт.

### [HIGH] BC-BIZ-003 / BC-BIZ-004 — Дүн ба dimension-ий зөрчил
**Файл:** `RebatePost.Codeunit.al`
**Асуудал:** (1) `RebateAmount` Round-гүй — precision-ээс олон орontой дүн
G/L рүү очно; (2) Posting Date-д invoice-ийн огноо биш `WorkDate()`;
(3) GenJnlLine-д Dimension Set ID, Document Type, Source Code огт олгоогүй,
талбарууд Validate-гүй (BC-BIZ-006).
**Санал болгож буй засвар:** `Round(SalesInvHeader.Amount * Customer."Rebate %" / 100,
Currency."Amount Rounding Precision")`; `SalesInvHeader."Posting Date"` ашигла;
`GenJnlLine.Validate(...)` дараалал + `"Dimension Set ID" := SalesInvHeader."Dimension Set ID"`.

### [HIGH] BC-AL-008 — Hardcoded данс/journal нэр
**Файл:** `RebatePost.Codeunit.al` (`'998877'`), `RebateWebhookAPI.Page.al` (`'GENERAL'`, `'REBATE'`)
**Асуудал:** G/L данс болон journal template/batch нэр код дотор.
**Санал болгож буй засвар:** Rebate Setup хүснэгт үүсгэж TestField-тэй уншиж хэрэглэ.

### [HIGH] BC-PERF-001 / BC-PERF-002 — Filter-гүй scan + loop доторх уншилт
**Файл:** `RebatePost.Codeunit.al`
**Байршил:** `RecalculateAllRebates`
**Асуудал:** Sales Invoice Header-ийг filter-гүй бүрэн scan; loop дотор
`SetRange + FindFirst` (Get + cache байх ёстой); мөр бүрт ашиглагдаагүй
`CalcFields("Balance (LCY)")` (BC-PERF-005).
**Санал болгож буй засвар:** Огноо/харилцагчийн filter нэм; Customer-ийг
`if Customer."No." <> ... then Customer.Get(...)` хэлбэрээр cache; CalcFields-ийг устга.

### [MEDIUM] BC-API-002 — API page-ийн бүтцийн зөрчил
**Файл:** `RebateWebhookAPI.Page.al`
**Асуудал:** `ODataKeyFields = "Line No."` (SystemId биш), DelayedInsert байхгүй,
source нь буфер биш шууд Gen. Journal Line.
**Санал болгож буй засвар:** SystemId түлхүүр + DelayedInsert = true; оролтыг
staging хүснэгтээр авч боловсруул.

### [MEDIUM] BC-EVT-002 — Subscriber guard дутуу
**Файл:** `RebateSubscribers.Codeunit.al`
**Асуудал:** Бүх subscriber-т `Rec.IsTemporary()`, хоосон түлхүүр, PreviewMode
guard байхгүй.
**Санал болгож буй засвар:** Guard-уудыг subscriber бүрийн эхэнд нэм.

## Positive Observations

- G/L бичилтийг Gen. Jnl.-Post Line-ээр хийсэн нь зөв (ledger-т шууд Insert хийгээгүй).
- API page-д APIPublisher/APIGroup/APIVersion зөв зарлагдсан.

## Test Assessment

- **Existing test coverage:** Тест огт байхгүй.
- **Missing test:** Rebate тооцооллын unit тест; давтан post/давтан API хүсэлтийн
  идемпотенц тест; G/L унах үеийн rollback тест; permission тест.
- **Recommended test scenario:**
  1. [GIVEN] Rebate %-тэй харилцагчийн invoice [WHEN] post [THEN] rebate entry +
     G/L бичилт зөв дүнтэй үүснэ.
  2. [WHEN] PostRebateForInvoice-ийг хоёр удаа дуудахад [THEN] нэг л entry байна.
  3. [GIVEN] Хаагдсан G/L данс [WHEN] post [THEN] алдаа + rebate entry ч үүсээгүй.
  4. [WHEN] Ижил externalPaymentId-тэй API хүсэлт 2 удаа [THEN] нэг л journal мөр.

## Final Verdict

**BLOCKED** — 7 CRITICAL finding: идемпотенцгүй давхар бичилт, subscriber-ийн
Commit, дугаарлалтын орлуулалт, hardcoded нууц, ledger-ийн direct эрх зэрэг нь
production-д санхүүгийн зөрүү болон аюулгүй байдлын осол үүсгэнэ. Эдгээрийг
засаагүйгээр merge хийхгүй.
