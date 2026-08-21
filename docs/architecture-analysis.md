# Business Central Architecture Analysis (Архитектурын шинжилгээ)

> Энэ баримт бичиг нь Base Application (v29, W1), System Application болон Business
> Foundation-ийн эх кодыг шууд уншиж, давтагдсан бүтцүүдийг харьцуулах замаар гаргасан
> архитектурын дүн шинжилгээ юм. Бүх ажиглалт нь бодит файл, мөрөнд суурилсан бөгөөд
> дан ганц жишээнээс биш, олон модульд давтагдсан pattern-уудаас нэгтгэсэн болно.

---

## 1. Layering — Давхаргын хуваарилалт

### 1.1 Апп хоорондын давхарга

```text
System Application     → платформ wrapper, security, interop (бизнес логикгүй)
Business Foundation    → No. Series, Audit Codes гэх мэт бизнесийн суурь
Base Application       → бүх бизнес процесс, posting engine
Extension апп-ууд      → API, e-document, connector гэх мэт
Localization layer     → улс орны онцлог
```

Хамаарал зөвхөн **доороос дээшээ** (Base App нь System App-аас хамаарна, эсрэгээр
хэзээ ч үгүй). System App нь Base App-ийн ямар ч хүснэгт, ойлголтыг мэдэхгүй.

### 1.2 Base Application доторх давхарга

Эх кодоос дараах давхаргууд тодорхой ялгарч байна:

| Давхарга | Тээгч object | Ажиглалт (эх код) |
|---|---|---|
| **UI layer** | Page, Page Extension | `SalesOrder.Page.al`-ийн `action(Post)` нь зөвхөн `PostSalesOrder(CODEUNIT::"Sales-Post (Yes/No)", ...)` гэж дуудна — ямар ч бизнес логик page дээр байхгүй |
| **UI туслах** | (Yes/No), (Y/N), and Send codeunit | `Sales-Post (Yes/No)` нь баталгаажуулах асуулт + delegate. Хэрэглэгчийн харилцан үйлчлэлийг бизнес логикоос тусгаарладаг |
| **Application layer** | Table trigger + validation | `SalesLine.Table.al` — Quantity-ийн OnValidate-д статус шалгалт (`TestStatusOpen`), Qty base тооцоолол, FieldError |
| **Document lifecycle** | Release/Reopen codeunit | `Release Sales Document` — Status Open → Released шилжилт, mandatory field шалгалт |
| **Posting layer** | Post, Post Batch, Post Line codeunit-ууд | `Sales-Post` (CU 80) → `Gen. Jnl.-Post Line` (CU 12), `Item Jnl.-Post Line` (CU 22), `Res. Jnl.-Post Line`, `Job Post-Line` |
| **Ledger layer** | Ledger Entry хүснэгтүүд | `G/L Entry`, `Cust. Ledger Entry`, `Item Ledger Entry`, `Value Entry` — зөвхөн posting codeunit-ууд Permissions property-оор бичдэг |
| **Integration layer** | SynchEngine, Graph, API entity | `IntegrationTableSynch`, Entity Aggregate хүснэгтүүд |
| **Event layer** | IntegrationEvent + Subscriber | 23 434 IntegrationEvent, 3 240 subscriber |

### 1.3 Journal → Ledger зарчим

Бүх санхүү, нөөцийн бичилт **Journal Line → Post Line codeunit → Ledger Entry** гэсэн
ганц сувгаар явдаг. Документ posting (Sales-Post) хүртэл дотооддоо
Gen. Journal Line буфер үүсгэж CU 12-оор дамжуулдаг. Үүний учир:

- Ledger Entry-г шууд Insert хийдэг цэг ганц байх тул balance, VAT, dimension,
  дугаарлалтын бүрэн бүтэн байдал нэг дор шалгагдана.
- `FinishPosting`-д (CU 12) debit/credit balance-ийн зургаан хэмжигдэхүүн 0 байх ёстой,
  үгүй бол `GLEntry.Consistent(false)` дуудаж transaction-ийг commit хийх боломжгүй
  болгодог — өөрөөр хэлбэл **тэнцвэргүй бичилт зарчмын хувьд DB-д орж чадахгүй**.

**Review-ийн дүрэм болгон хөрвүүлбэл:** custom код G/L Entry, Item Ledger Entry,
Cust./Vendor Ledger Entry рүү шууд Insert/Modify хийж байвал CRITICAL асуудал.

---

## 2. Object Responsibility — Объектын хариуцлага

Эх кодын олон жишээг харьцуулж гаргасан хариуцлагын хуваарилалт:

### Table
- Өгөгдлийн бүтэц, харилцан хамаарал (TableRelation), FlowField.
- **Талбарын түвшний validation** OnValidate дээр: төлөв шалгах (`TestStatusOpen`),
  бусад талбарын дагалдах өөрчлөлт, FieldError. Жишээ: SalesLine.Quantity.
- **Мастер өгөгдлийн амьдралын мөчлөг** trigger дээр: Customer.OnInsert (No. Series
  олгох + давхардал шалгах), OnDelete (нээлттэй бичилт шалгаад Error, хамааралтай
  өгөгдөл цэвэрлэх), OnRename.
- Table trigger дотор ч OnBefore/OnAfter event + IsHandled pattern зарлагддаг.
- Documents/journals нь хэрэглэгчийн бичилтийн үед шалгах validation-ийг агуулна,
  харин **баримт бүхэлдээ зөв эсэхийг posting-ийн Check codeunit** давхар шалгана
  (SalesLine validation ≠ CheckSalesDocument — хоёулаа хэрэгтэй).

### Table Extension
- Модулиуд хоорондын нэмэлт талбар (жишээ: Pricing → "Feature Data Update Status").
- Бизнес урсгалын гол логик table extension-д биш, subscriber codeunit-д байрладаг.

### Page
- Зөвхөн UI: layout, action, view. Action-ууд codeunit рүү delegate хийнэ.
- Page-ийн trigger дээр зөвхөн UI-тэй холбоотой богино логик (visibility, style,
  notification) байна.

### Codeunit
Base App-д хэд хэдэн үүрэгтэй ангилал давтагддаг:
- **Posting codeunit-ууд** (`TableNo =` тодорхойлолттой, Permissions property-той):
  Check → Post → Finalize бүтэцтэй.
- **Management codeunit-ууд** (`* Mgt.`, `* Management`): тодорхой домэйний туслах логик.
- **(Yes/No) / (Y/N) codeunit-ууд**: UI confirmation давхарга.
- **Subscriber codeunit-ууд** (`* Subscribers`, `*Subscriber`): event-ээр модулиудыг холбоно.
- **Facade + Impl. хос** (System App/Business Foundation): `No. Series` (Access = Public)
  → `No. Series - Impl.` (Access = Internal). Public API-г тогтвортой байлгаж,
  хэрэгжилтийг чөлөөтэй өөрчлөх боломж олгодог.
- **Install/Upgrade codeunit-ууд**: `Subtype = Install/Upgrade`, Upgrade Tag-аар хамгаалагдсан.

### Report
- Тайлан + batch боловсруулалт (Copy Company гэх мэт). Batch report нь өөрийн
  transaction/Commit-ийн менежментийг хийдэг.

### Query
- Багц уншилт, aggregate тооцоолол (жишээ: `QtyReservedFromItemLedger`),
  telemetry (`NonInventoryTelemetry.Query.al`). Loop + CalcSums-ын оронд ашиглагддаг.

### XMLPort
- Импорт/экспортын формат тодорхойлолт, логикгүй.

### Enum
- Extensible сонголт. `Extensible = true` enum нь interface-тэй хослон
  implementation сонгодог (`SalesInvoicePosting.Enum.al` → "Invoice Posting" interface).

### Interface
- Солигдох боломжтой хэрэгжилтийн гэрээ. 30 ширхэг (W1). Гол жишээ:
  `Invoice Posting`, `Price Calculation`, `Line With Price`, `No. Series - Single`.
- Interface-ийн method бүр XML documentation комменттой.

### Permission Set
- `IncludedPermissionSets`-ээр давхарласан бүтэц (D365 ACC. RECEIVABLE нь
  D365 JOURNALS, POST + D365 SALES DOC, POST-ыг агуулна).
- Том/жижиг үсгийн ялгаа утга илэрхийлдэг: `RIMD` = шууд эрх, `Rimd` = зөвхөн Read
  шууд, бусад нь indirect (объектоор дамжсан) эрх.

---

## 3. Dependency Direction — Хамаарлын чиглэл

### 3.1 Ажиглагдсан зарчмууд

1. **Documents → Ledger нэг чиглэлт.** Posting codeunit баримтаас ledger үүсгэдэг;
   ledger модуль баримтын тухай мэддэггүй.
2. **Sales ↔ Purchases шууд хамааралтай** (drop shipment-ийн улмаас Sales-Post нь
   Purch. Header-ийг Modify эрхтэй). Энэ нь зориудын, permission property-д
   баримтжсан хамаарал.
3. **Гол цөм рүү чиглэсэн хамаарал:** бүх модуль Foundation, Finance/GeneralLedger,
   Dimension руу хамаардаг; эсрэг чиглэл event-ээр шийдэгдэнэ.
4. **Modулиуд хоорондын "сул" холбоо event-ээр:** Жишээ нь Document Attachment нь
   Sales Header-ийн OnAfterInsertEvent, OnAfterValidateEvent-д subscribe хийдэг —
   Sales модуль Attachment-ийн тухай юу ч мэддэггүй.
5. **Interface-ээр урвуу хамаарлыг тайлах:** Sales-Post нь "Invoice Posting"
   interface-ээр хэрэгжилтээ enum-оос сонгодог тул шинэ posting хэрэгжилтийг
   Sales-Post-ыг өөрчлөхгүйгээр нэмж болдог.
6. **Circular dependency-ээс namespace + using-аар сэргийлдэг:** AL файл бүр
   namespace зарлаж, хамаарлаа using-аар илэрхийлдэг тул хамаарлын граф ил байдаг.

### 3.2 Tight coupling зөвшөөрөгдсөн газар

Posting engine дотор (Sales-Post ↔ GenJnlPostLine ↔ ItemJnlPostLine) global
codeunit хувьсагчаар төлөв хуваалцсан нягт холбоо байдаг. Энэ нь transaction-ийн
нэгдмэл байдлыг хангахын тулд зориуд хийгдсэн: нэг posting нэг instance дотор
дуусах ёстой. Гаднаас ашиглах нь зөвхөн `Run`/`RunWithCheck` төрлийн цэгээр.

---

## 4. Extensibility — Өргөтгөх боломжийн загвар

### 4.1 Хэрэгсэл бүрийн сонголтын логик (design rationale)

| Хэрэгсэл | Хэзээ ашигладаг (эх кодын ажиглалт) |
|---|---|
| **IntegrationEvent (OnBefore/OnAfter)** | Процессын тодорхой цэгт нэмэлт үйлдэл нээх. Бараг бүх public урсгалд OnBefore + OnAfter хос event байдаг |
| **IsHandled pattern** | `IsHandled := false; OnBeforeX(..., IsHandled); if IsHandled then exit;` — процессыг бүхэлд нь **солих** боломж. 5632 удаа давтагдсан стандарт |
| **Event + var параметр** | Утга өөрчлөх боломж (жишээ: OnSetCommitBehavior(IgnoreCommit)) |
| **Interface + Enum** | Бүтэн algorithm солигдох үед: Price Calculation, Invoice Posting, No. Series - Single. Enum extensible тул гуравдагч этгээд шинэ implementation бүртгэж чадна |
| **Шууд codeunit дуудлага** | Нэг domain доторх, солигдох шаардлагагүй логик |
| **Table/Page Extension** | Өгөгдөл + UI өргөтгөл (логик биш) |
| **Manual event subscriber (`EventSubscriberInstance = Manual` + BindSubscription)** | Тодорхой хугацаанд л идэвхтэй байх subscriber: Sales-Post өөрийгөө bind хийж value entry цуглуулаад unbind хийдэг; Posting Preview mode |
| **Facade (Access=Public) + Impl (Access=Internal)** | System App/BF-ийн бүх модуль. API тогтвортой, хэрэгжилт чөлөөтэй |
| **Obsolete lifecycle** | `ObsoleteState = Pending` (634 удаа) → Removed. Breaking change-ийг хугацаатай зарладаг |
| **`#if not CLEANxx` preprocessor** | Хуучин schema/логикийг хувилбарын дагуу үе шаттай цэвэрлэх |

### 4.2 Event-ийн нэршлийн конвенц

- `OnBefore<Action>` / `OnAfter<Action>` — процессын өмнө/дараа.
- `On<Procedure>On<SubStep>` — урт процессын дундах нарийн цэг
  (жишээ: `OnRunOnBeforeCheckAndUpdate`, `OnCheckAndUpdateOnAfterCalcInvDiscount`).
- Table event: `OnAfterValidateEvent` field-ийн нэрээр subscribe хийдэг built-in event.
- Event-ийн signature-д ихэвчлэн Rec + процессын төлөв (SuppressCommit, PreviewMode)
  дамжуулагддаг.

### 4.3 Subscriber-ийн сахилга (Base App-ийн өөрийн subscriber-уудаас)

`DocumentAttachmentMgmt.Codeunit.al`-ийн subscriber-ууд бүгд:
1. Хамгаалалтын early-exit шалгалтууд (`Rec."No." = ''`, **`Rec.IsTemporary()`**) хийдэг.
2. Богино, нэг зорилготой.
3. Өөр модулийн өгөгдлийг л удирддаг (өөрийн domain).
4. Error үүсгэхээс зайлсхийдэг (posting дунд unrelated алдаа хаяхгүй).

---

## 5. Posting Engine — Гүйцэтгэлийн дараалал (Sales-Post-оос нэгтгэв)

```text
RunWithCheck(SalesHeader)
│
├── 1. OnBeforePostSalesDoc (IsHandled боломжтой)
├── 2. ValidatePostingAndDocumentDate
├── 3. FillTempLines            ← мөрүүдийг temp хүснэгт рүү хуулна (DB-оос тусгаарлана)
├── 4. CheckTotalInvoiceAmount  ← нийт дүн ≥ 0
├── 5. CheckAndUpdate
│     ├── CheckSalesDocument    ← бүх validation: mandatory fields, posting date
│     │                            (IsDateNotAllowed), VAT date, dimensions
│     │                            (CheckSalesDim), CheckPostRestrictions (event-ээр
│     │                            approval г.м. өргөтгөгддөг), item charge, due date
│     ├── CreatePrepaymentLines
│     ├── UpdatePostingNos      ← No. Series-ээс дугаар авна, ДАВХАРДЛЫГ ШАЛГАНА:
│     │                            posted хүснэгтэд дугаар аль хэдийн байвал Error
│     ├── SalesHeader.Modify + Commit  ← дугаар олгосны дараа (SuppressCommit биш үед)
│     │                            → алдаа гарч дахин post хийхэд ижил дугаар дахин
│     │                              ашиглагдана = duplicate үүсэхгүй (идемпотенц)
│     ├── CalcInvDiscount (+Commit)
│     ├── ReleaseSalesDocument  ← Open байвал Release хийнэ
│     ├── ArchiveUnpostedOrder
│     ├── LockTables            ← SalesLine, PurchLine, (legacy үед G/L Entry) LockTable
│     └── InsertPostedHeaders   ← Shipment/Invoice/CrMemo header-үүд
│
├── 6. ProcessPosting  [CommitBehavior(CommitBehavior::Ignore)] wrapper-тэй
│     ├── мөр бүр дээр: PostSalesLine
│     │     ├── Item line → ItemJnlPostLine (ILE + Value Entry + Whse)
│     │     ├── G/L, Resource, FA, Job → тус тусын Post Line
│     │     └── posted document line-ууд Insert
│     ├── PostInvoice → InvoicePostingInterface → GenJnlPostLine
│     │     (Cust. Ledger Entry, VAT Entry, G/L Entry)
│     ├── PostICGenJnl, PostDropOrderShipment
│     └── MakeInventoryAdjustment
│
├── 7. FinalizePosting
│     ├── Order бүрэн invoice-логдоогүй → PostUpdateOrderLine (үлдэгдэл шинэчлэх)
│     ├── бүрэн бол → DeleteAfterPosting (баримт устгах)
│     ├── PreviewMode бол → GenJnlPostPreview.ThrowError() ← БҮГДИЙГ ROLLBACK
│     └── Commit  (зөвхөн: not InvtPickPutaway, not SuppressCommit, not PreviewMode)
│
└── 8. OnAfterPostSalesDoc + UpdateAnalysisView
```

### Гол дүгнэлтүүд

1. **Validation бүгд бичилт эхлэхээс өмнө.** Ledger бичилт эхэлсний дараа шинэ
   business validation алдаа гарвал хагас бичилт үүсэх байсан — тиймээс бүх шалгалт
   урд байрладаг.
2. **Commit цэгүүд зөвхөн "аюулгүй шугам" дээр:** дугаар олголт хадгалагдсаны дараа
   болон бүх бичилт дууссаны дараа. Дундах хэсэгт Commit байхгүй, харин ч
   `CommitBehavior::Ignore` wrapper-аар subscriber-ийн Commit-ийг хүчингүй болгодог.
3. **SuppressCommit / PreviewMode бүх Commit-ийн урд шалгагддаг** — batch posting
   болон preview үед transaction-ийг гаднаас удирдах боломж.
4. **Идемпотенцийн хамгаалалт:** Posting No. нэг удаа олгогдоод header дээр
   хадгалагддаг; posted хүснэгтэд тухайн дугаар байгаа эсэхийг Get-ээр шалгадаг.
5. **LockTables-ийг validation дууссаны дараа, бичилтийн өмнө** дууддаг — түгжээ
   барих хугацааг богиносгодог (concurrency).
6. **Preview бол тусдаа зам биш, мөн л ижил код** — гэхдээ бодит дугаар авахгүй
   (`***` токен), Commit хийхгүй, төгсгөлд нь заавал Error-оор rollback хийдэг.
   `[CommitBehavior(CommitBehavior::Error)]` — preview дотор Commit оролдвол алдаа.

---

## 6. Error Handling Framework

| Механизм | Хэрэглээ (эх кодоос) |
|---|---|
| `Error(Lbl)` | Процесс зогсоох. Label үргэлж Comment-той, format placeholder-той |
| `FieldError(Field, Text)` | Талбарт хамааруулсан алдаа — validation-д өргөн (829) |
| `TestField(Field)` | Mandatory шалгалт |
| `TestField(Field, ErrorInfo.Create())` | Collectible: бүх алдааг нэг дор цуглуулж харуулах боломж (шинэ код) |
| `ErrorMessage Mgt.` + PushContext/PopContext | Алдааг ямар recordId, ямар алхамд гарсныг хамт хадгалдаг |
| `[ErrorBehavior(ErrorBehavior::Collect)]` | Background validation (CheckSalesDocBackgr) — алдаа цуглуулаад буферээр буцаана |
| `[TryFunction]` | Зөвхөн interop/integration давхаргад (328); бизнес логикт бараг байхгүй. **Try дотор DB бичилт хийхээс сэргийлдэг** |
| `Codeunit.Run` + `if not ... then` | Тусгаарлагдсан transaction-тай дуудлага (Job Queue-ийн posting: `if not Codeunit.Run(...) then SetJobQueueStatus(Error)`) |
| `GLEntry.Consistent(false)` | Transaction-ийг DB түвшинд commit хийх боломжгүй болгох |
| Notification + AddAction | Хэрэглэгчид зөвлөмжтэй, blocking биш анхааруулга |

---

## 7. Performance Patterns

1. **Temp буфер + нэг удаагийн бичилт:** GL entries эхлээд TempGLEntryBuf-д, FinishPosting
   дээр нэг дор Insert. Sales lines temp хүснэгтээр боловсруулагддаг.
2. **`SetLoadFields`** — цөөн талбар унших үед (994 газар). Ялангуяа Get-ийн өмнө:
   `SalesInvoiceLine.SetLoadFields("Order No.")`.
3. **`ReadIsolation(IsolationLevel::ReadUncommitted)`** — lock үүсгэлгүй лүүкап
   (ItemJnlCheckLine-ийн Item.Get, Customer.OnInsert-ийн давхардал шалгалт).
4. **`IsEmpty()`** — тоолох/олох шаардлагагүй existence шалгалт (`if not Job.IsEmpty() then Error`).
5. **Query object** — aggregate уншилт (reservation qty г.м.).
6. **`FindSet()` + `repeat until Next() = 0`** — олон мөр унших цор ганц хэлбэр.
7. **SetCurrentKey** — зөв индекс сонгох (TempSalesLineGlobal.SetCurrentKey(Type, "Line No.")).
8. **LockTable-ийг аль болох хожуу** — validation дараа.
9. **`ModifyAll`/`DeleteAll`** — loop-гүй bulk үйлдэл (upgrade кодод RunTrigger=false-тайгаар).
10. **CalcFields-ийг шаардлагатай үед л** — FlowField-ийг loop дотор давтан бодохгүй.

---

## 8. Security / Permission Patterns

1. Posting codeunit-ууд `Permissions = TableData ... = rimd` property-оор ledger
   хүснэгтэд бичих эрхээ **өөртөө** авдаг → хэрэглэгчид ledger-ийн шууд эрх өгөх
   шаардлагагүй (indirect permission зарчим).
2. `[SecurityFiltering(SecurityFilter::Ignored)]` — зөвхөн зориудын, баримтжсан газарт
   (G/L Entry-ийн дотоод уншилт).
3. System App: `InherentEntitlements = X; InherentPermissions = X;` заавал.
4. Permission set-үүд composition-оор (IncludedPermissionSets) угсарддаг.
5. `Access = Internal` — гаднаас дуудагдах ёсгүй implementation.
6. Нууц утга: `SecretText`, `SecretStrSubstNo` (HTTP Authorization header).
7. Мэдрэмтгий үйлдлүүд tenant admin шалгалттай (`CheckPermissionToSendICTransaction`).

---

## 9. Review-д хөрвүүлэх гол архитектурын дүрмүүд (товчоор)

1. Ledger хүснэгтэд шууд бичихгүй — зөвхөн Post Line codeunit-ээр.
2. Page-д бизнес логик байхгүй — codeunit рүү delegate.
3. Validation posting-ийн бичилт эхлэхээс өмнө дуусна.
4. Commit нь зөвхөн бүрэн, уялдаатай төлөвт; SuppressCommit/PreviewMode-ийг үргэлж хүндэтгэнэ.
5. Идемпотенц: дугаар/төлөв урьдчилан хадгалж, давхардлыг шалгана.
6. Extensibility: override хийхийн оронд event/interface ашиглана.
7. Subscriber богино, guard-тай, IsTemporary шалгадаг, өөрийн domain-д л нөлөөлнө.
8. Permission объект дээр наряцтай (rimd жижиг үсэг = indirect); өргөн эрх өгөхгүй.
9. Performance: FindSet/IsEmpty/SetLoadFields/ReadIsolation-ийг зохистой хэрэглэнэ.
10. Obsolete lifecycle-гүйгээр public зүйл устгахгүй (breaking change).
