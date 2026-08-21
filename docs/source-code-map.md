# Business Central Source Code Map (Эх кодын зураглал)

> Энэхүү баримт бичиг нь Microsoft Dynamics 365 Business Central-ийн эх кодын бүтцийг
> Business Central Code Review Skill боловсруулах зорилгоор системтэйгээр судалж гаргасан
> зураглал юм. Судалгаанд дараах хоёр repository хамрагдсан:
>
> - **BCApps** — System Application, Business Foundation, W1 extension апп-ууд, хөгжүүлэлтийн Tools
> - **BusinessCentralApps** — Base Application-ийн бүрэн эх код (W1 + улс орнуудын localization Layers, Tests)
>
> Судлагдсан хувилбар: **Business Central v29.0** (Base Application app.json-оос).

---

## 1. Repository-ийн дээд түвшний бүтэц

### 1.1 BCApps

| Хавтас | Агуулга |
|---|---|
| `src/System Application/App` | 116 бие даасан модуль, 1335 AL файл. Платформын түвшний functionality (Azure AD, Cryptography, Email, Telemetry, Upgrade Tags гэх мэт) |
| `src/Business Foundation/App` | 96 AL файл. Бизнесийн суурь модулиуд: **NoSeries**, **AuditCodes**, **Entitlements**, NoSeriesCopilot |
| `src/Apps/W1` | 103 first-party extension апп (APIV1, APIV2, EDocument, Email connectors, ExcelReports, BankDeposits гэх мэт) |
| `src/Tools` | Test Framework, Performance Toolkit (BCPT), AI Test Toolkit, Red Team Scan |
| `src/rulesets` | AL analyzer ruleset тохиргоо |
| `src/DemoTool`, `src/GDL`, `src/Layers` | Demo өгөгдөл болон layer бүтэц |

### 1.2 BusinessCentralApps

| Хавтас | Агуулга |
|---|---|
| `App/Layers/W1/BaseApp` | **Base Application** — 8081 AL файл. Худалдаа, санхүү, агуулах, үйлдвэрлэл гэх мэт бүх үндсэн бизнес логик |
| `App/Layers/W1/Tests` | 1790 AL файл бүхий тест код (ERM, SCM, Dimension, Permissions, TestLibraries гэх мэт) |
| `App/Layers/{AT,AU,BE,...}` | Улс орон бүрийн localization layer (23 улс) |
| `App/Projects` | Base Application болон тестийн bucket-уудын build project тодорхойлолт |

### 1.3 Хамаарлын дараалал (Layering)

```text
System Application (63ca2fa4-...)          ← платформын түвшин
        ↑
Business Foundation (f3552374-...)         ← бизнесийн суурь (No. Series, Audit Codes)
        ↑
Base Application (437dbf0e-...)            ← бүх үндсэн бизнес логик
        ↑
W1 Extension апп-ууд (APIV2, EDocument...) ← нэмэлт боломжууд
        ↑
Localization Layers (AT, DE, MN гэх мэт)   ← улс орны онцлог
        ↑
Partner / Customer extension-ууд           ← бидний review хийх код
```

Хамаарал үргэлж **дээрээс доош** чиглэнэ: Base Application нь System Application-ээс
хамаарна, харин System Application нь Base Application-ийн юуг ч мэдэхгүй.
Энэ нэг чиглэлт хамаарал нь review хийхэд шалгах ёстой суурь зарчим.

---

## 2. Base Application-ийн object type-уудын тоо (W1)

| Object type | Тоо | Тайлбар |
|---|---|---|
| Page | 2631 | UI давхарга — үндсэндээ "нимгэн", логик агуулахгүй |
| Codeunit | 1715 | Бизнес логикийн гол тээгч |
| Table | 1536 | Өгөгдлийн бүтэц + field validation |
| Report | 658 | Тайлан + batch processing |
| Enum | 568 | Extensible төрлүүд |
| Permission Set | 258 (+55 ext) | Эрхийн багцууд |
| Page Extension | 156 | Модулиуд хоорондын UI өргөтгөл |
| Query | 152 | Онолын багц уншилт, telemetry |
| Table Extension | 90 | Модулиуд хоорондын өгөгдлийн өргөтгөл |
| Interface | 30 | Солигдох боломжтой хэрэгжилтийн гэрээ |
| XMLPort | 36 | Импорт/экспорт |
| Profile | 42 | Role Center профайл |

---

## 3. Base Application-ийн модулиуд

Модуль бүрийг: **Зорилго / Гол object-ууд / Хамаарал / Архитектурын ач холбогдол** гэсэн
байдлаар тайлбарлав. (AL файлын тоог хаалтад бичив.)

### 3.1 Foundation (200) — Суурь модуль

- **Зорилго:** Бүх бизнес модульд ашиглагддаг суурь ойлголтууд.
- **Дэд хэсгүүд:** Address, Attachment, AuditCodes (Source Code, Reason Code),
  BatchProcessing, Calendar, Company, ExtendedText, Navigate, NoSeries (legacy холбогч),
  PaymentTerms, Period, Reporting, Shipping, UOM (Unit of Measure).
- **Чухал codeunit-ууд:** `Batch Processing Mgt.`, `Unit of Measure Management`,
  `Document Attachment Mgmt.` (event subscriber-ийн сайн жишээ).
- **Архитектурын ач холбогдол:** ӨНДӨР — бараг бүх модуль эндээс хамаардаг.

### 3.2 Finance (1024) — Санхүү

Хамгийн том модуль. Дэд хэсгүүд:

| Дэд модуль | Зорилго | Гол object-ууд |
|---|---|---|
| GeneralLedger | Ерөнхий дэвтэр | `G/L Entry`, `Gen. Journal Line`, **CU 12 "Gen. Jnl.-Post Line"** (11031 мөр), `Gen. Jnl.-Post Batch`, `Gen. Jnl.-Check Line` |
| GeneralLedger/Preview | Posting preview | `Gen. Jnl.-Post Preview`, `Posting Preview Event Handler` |
| VAT | НӨАТ тооцоолол | `VAT Entry`, `VAT Posting Setup`, VAT Calculation |
| Currency | Валют | `Currency`, `Currency Exchange Rate` (Currency.Initialize pattern) |
| Dimension | Хэмжээс (аналитик) | `Dimension Set Entry`, `DimensionManagement`, `Check Dimensions` |
| ReceivablesPayables | Авлага/Өглөг холбогч | **`Invoice Posting` interface**, `Invoice Posting Buffer`, Payment Tolerance |
| Deferral | Хойшлогдсон орлого/зардал | `Deferral Header/Line`, `Deferral Utilities` |
| Consolidation | Нэгтгэл | `ImportConsolidationFromAPI` (HTTP integration-ийн жишээ) |
| Intercompany | Компани хоорондын | IC Inbox/Outbox, `ICInboxOutboxMgt` |
| Analysis, FinancialReports, Budget | Тайлан шинжилгээ | Analysis View, Account Schedule |

- **Архитектурын ач холбогдол:** МАШ ӨНДӨР — санхүүгийн consistency-ийн цөм.
  `Gen. Jnl.-Post Line` нь бүх санхүүгийн бичилтийн ганц гарц (single entry point).

### 3.3 Sales (590) — Худалдаа

- **Дэд хэсгүүд:** Customer, Document, Posting, History, Receivables, Pricing, Archive,
  FinanceCharge, Reminder, Peppol, Setup.
- **Гол object-ууд:** `Sales Header` / `Sales Line` (15594 мөр — validation-ийн загвар),
  **CU 80 "Sales-Post"** (13969 мөр), `Sales-Post (Yes/No)`, `Sales-Post and Send`,
  `SalesPostInvoice` (Invoice Posting interface-ийн хэрэгжилт), `Release Sales Document`,
  `Sales Post via Job Queue`, `Customer` table (5072 мөр), `Cust. Ledger Entry`.
- **Архитектурын ач холбогдол:** МАШ ӨНДӨР — Sales-Post бол документ posting-ийн
  архитектурын эталон загвар.

### 3.4 Purchases (369) — Худалдан авалт

- **Дэд хэсгүүд:** Vendor, Document, Posting, History, Payables, Remittance, Pricing.
- **Гол object-ууд:** `Purchase Header/Line`, **CU 90 "Purch.-Post"**, `Vendor`,
  `Vendor Ledger Entry`, `Release Purchase Document`.
- **Архитектурын ач холбогдол:** ӨНДӨР — Sales-тай ижил бүтэцтэй толин загвар.

### 3.5 Inventory (949) — Бараа материал

- **Дэд хэсгүүд:** Item, Journal, Ledger, Posting, Costing, Tracking, Location, Transfer,
  Availability, BOM, Counting (Phys. Invt.), Reservation.
- **Гол object-ууд:** `Item`, `Item Journal Line`, `Item Ledger Entry`, `Value Entry`,
  **CU 22 "Item Jnl.-Post Line"**, `ItemJnlCheckLine`, `Item Tracking Management`,
  Costing engine (`Inventory Adjustment`, `Cost Calculation Management`).
- **Архитектурын ач холбогдол:** МАШ ӨНДӨР — өртгийн тооцоолол (costing) болон
  нөөцийн хөдөлгөөний цөм. Quantity болон Cost хоёр тусдаа урсгалаар бичигддэг
  (ILE + Value Entry).

### 3.6 Warehouse (355) — Агуулах

- **Дэд хэсгүүд:** Activity (Pick/Put-away), Document (Receipt/Shipment), Journal,
  Ledger, Request, Structure (Bin), ADCS.
- **Гол object-ууд:** `Warehouse Entry`, `Whse.-Post Receipt`, `Whse.-Post Shipment`,
  `Whse. Jnl.-Register Line`, Inventory Pick/Put-away.
- **Архитектурын ач холбогдол:** ӨНДӨР — Inventory-тэй нягт уялдаатай, posting-ийн
  дараалал (whse → item journal) чухал.

### 3.7 Manufacturing (513) — Үйлдвэрлэл

- **Гол object-ууд:** `Production Order`, `Prod. Order Line/Component`, Routing,
  Capacity, `Output Journal`, Flushing, Subcontracting.
- **Архитектурын ач холбогдол:** ДУНД-ӨНДӨР — Item Journal дээр суурилсан output/consumption posting.

### 3.8 Service (637) — Сервис

- **Гол object-ууд:** `Service Header/Line`, `Service Contract`, Serv-Post цуврал,
  Service Ledger Entry, Preview binding (`ServPostingPreviewBinding` — preview-ийн
  өргөтгөх жишээ).
- **Архитектурын ач холбогдол:** ДУНД — Sales posting pattern-ийг дагадаг.

### 3.9 Projects / Jobs (333) — Төсөл

- **Гол object-ууд:** `Job`, `Job Task`, `Job Planning Line`, `Job Ledger Entry`,
  `Job Jnl.-Post Line`, `Job Post-Line`, WIP тооцоолол.
- **Архитектурын ач холбогдол:** ДУНД.

### 3.10 FixedAssets (213) — Үндсэн хөрөнгө

- **Гол object-ууд:** `Fixed Asset`, `FA Ledger Entry`, `FA Jnl.-Post Line`, Depreciation,
  Insurance journals.
- **Архитектурын ач холбогдол:** ДУНД.

### 3.11 Bank (239) — Банк

- **Гол object-ууд:** `Bank Account`, `Bank Account Ledger Entry`, Reconciliation,
  Payment Matching, `Check Ledger Entry`, Data Exchange Framework холболт.
- **Архитектурын ач холбогдол:** ДУНД-ӨНДӨР — төлбөрийн идемпотенц чухал.

### 3.12 CRM (369) + Integration (329) — Харилцагч ба интеграц

- **CRM:** Contact, Opportunity, Segment, Interaction, Task, Outlook холболт.
- **Integration:** **SynchEngine** (`IntegrationTableSynch`, `IntegrationRecSynchInvoke` —
  TryFunction + idempotency-ийн загвар), Dataverse/CDS холболт
  (`CRMIntegrationManagement`, `CDSIntTableSubscriber`), Graph API entity-үүд,
  `APISetup`, Entity Aggregate tables (`Sales Invoice Entity Aggregate`).
- **Архитектурын ач холбогдол:** ӨНДӨР — гадаад системтэй холбогдох бүх pattern эндээс харагдана.

### 3.13 Pricing (78) — Үнэ тооцоолол

- **Гол object-ууд:** **`Price Calculation` interface**, `Line With Price` interface,
  `Price Calculation Setup`, `Price List Line`. Interface + Enum-ээр солигдох
  хэрэгжилтийн (pluggable implementation) хамгийн тод жишээ.
- **Архитектурын ач холбогдол:** ӨНДӨР (extensibility загварын хувьд).

### 3.14 Finance-ийн туслах болон бусад модулиуд

| Модуль | Файл | Зорилго |
|---|---|---|
| CashFlow (49) | Мөнгөн урсгалын төсөөлөл | `CashFlowWkshRegisterBatch` (batch + Commit жишээ) |
| CostAccounting (82) | Зардлын нягтлан бодох | `Transfer GL Entries to CA` |
| HumanResources (115) | Ажилтан | `Employee`, Employee Ledger |
| Assembly (113) | Угсралт | `Assembly Header`, `Assembly-Post` |
| Invoicing (21) | Microsoft Invoicing (legacy) | O365 объектууд |
| eServices (65) | E-Document (Incoming Documents, OCR) | `Incoming Document` |
| CostAccounting (82) | Зардлын НБ | Cost Journal |

### 3.15 System (558) + Modules (287) + OtherCapabilities (99)

- **System:** API infrastructure (`APIDataUpgrade`, Webhooks), Automation, Azure AD,
  DataAdministration, DataMigration (`DataMigrationMgt` — Commit-той batch жишээ),
  Environment, Feature Key (`Feature Data Update Mgt.`), Jobs (Job Queue), RapidStart
  (`ConfigPackageManagement`), Threading, Upgrade (`UpgradeTagDefinitions`), UserGroups.
- **Modules/System:** Email, ErrorMessage (**`Error Message Management`** — collectible
  error-ийн цөм), JobQueue, Logging, PowerBI.
- **Архитектурын ач холбогдол:** ӨНДӨР — background posting, upgrade, error handling
  framework-ууд энд байрладаг.

### 3.16 Permissions (235) — Эрхийн багцууд

- D365 нэршилтэй бизнес permission set-үүд (`d365accpayable`, `d365accreceivable` гэх мэт),
  `SecurityBaseApp`, объектын execute багцууд, OnPrem дэд хавтас.
- **Архитектурын ач холбогдол:** ӨНДӨР — permission review-ийн лавлагаа.

### 3.17 RoleCenters (34), Utilities (65), Removed (2)

- RoleCenters: профайл + role center page-үүд.
- Utilities: туслах functionality.
- Removed: устгагдсан объектуудын үлдэгдэл (obsolete lifecycle-ийн жишээ).

---

## 4. System Application-ийн чухал модулиуд (BCApps)

116 модулиас code review-д хамгийн их хамааралтай нь:

| Модуль | Зорилго | Review-д ашиглагдах нь |
|---|---|---|
| Cryptography Management | Шифрлэлт | Custom crypto бичихийг хориглох |
| Azure Key Vault | Нууц хадгалалт | Hardcoded secret илрүүлэх |
| Confirm Management | Dialog харуулах | GuiAllowed-check pattern |
| Telemetry / Logging | Session.LogMessage | Verbosity, DataClassification |
| Upgrade Tags | Давхардалгүй upgrade | Upgrade идемпотенц |
| Retention Policy | Өгөгдөл цэвэрлэлт | Log хүснэгтийн менежмент |
| Edit in Excel, Email, Document Sharing | Interop | Facade ашиглалт |
| Secret Text (SecretText type) | Нууц утга дамжуулах | Token/password plain text эсэх |

**System Application-ийн гол design pattern:** Модуль бүр `Access = Public` facade
codeunit + `Access = Internal` Impl. codeunit гэсэн хос бүтэцтэй.
(Жишээ: Business Foundation-ийн `No. Series` CU 310 → `No. Series - Impl.`)
Мөн `InherentEntitlements = X; InherentPermissions = X;` заавал зарлагддаг.

## 5. Business Foundation-ийн модулиуд

| Модуль | Агуулга |
|---|---|
| **NoSeries** | Дугаарын серийн шинэ facade: `No. Series` (CU 310), `No. Series - Batch`, `No. Series - Single` interface, Sequence/Stateless хэрэгжилтүүд, Legacy харилцан үйлчлэл, Upgrade tags |
| AuditCodes | Source Code, Reason Code |
| Entitlements | License entitlements |

---

## 6. Test-ийн бүтэц (BusinessCentralApps/App/Layers/W1/Tests)

| Хавтас | Агуулга |
|---|---|
| `TestLibraries` | Library codeunit-ууд: mock events, backup management, буфер хүснэгтүүд |
| `ApplicationTestLibrary` | `Library - Sales`, `Library - Purchase`, `Library - ERM`, `Library - Random`, `Library - Setup Storage`, `Library - Test Initialize` гэх мэт |
| `ERM` | Санхүү, борлуулалт, худалдан авалтын тест (жишээ: `BackgroundDocumentPosting`) |
| `SCM`, `SCM-Assembly`, `SCM-Manufacturing`, `SCM-Service` | Нийлүүлэлтийн гинжин хэлхээ |
| `Dimension`, `VAT`, `Prepayment`, `Cash Flow`, `Cost Accounting` | Санхүүгийн дэд систем |
| `Permissions` | Permission тест |
| `Integration`, `CRM integration`, `Graph` | Интеграцийн тест |
| `Upgrade` | Upgrade тест |
| `Performance-Internal`, `BCPT-SampleTests` | Performance тест |

**Тестийн гол pattern:** `Subtype = Test`, `[Test]` attribute, `// [FEATURE]`,
`// [SCENARIO ###]`, `// [GIVEN] / [WHEN] / [THEN]` тайлбар, `Initialize()` +
`Library - Test Initialize`, `Assert` codeunit, `asserterror`, Handler функцууд
(`[ConfirmHandler]`, `[MessageHandler]` гэх мэт).

---

## 7. Кодын хэмжээний статистик (pattern-ийн давтамж, W1 BaseApp)

| Pattern | Давтамж | Дүгнэлт |
|---|---|---|
| `[IntegrationEvent]` | 23 434 | Extensibility-ийн үндсэн механизм |
| `[EventSubscriber]` | 3 240 | Модулиуд event-ээр холбогддог |
| `if IsHandled then` | 5 632 | OnBefore + IsHandled нь стандарт override цэг |
| `Commit()` | 999 | 8081 файлд ердөө ~1000 — Commit бол ховор, зориудын шийдвэр |
| `SetLoadFields(` | 994 | Шинэ кодод идэвхтэй ашиглагддаг performance pattern |
| `LockTable()` | 926 | Posting-ийн өмнөх зориудын түгжээ |
| `FieldError(` | 829 | Талбарт хамааруулсан алдаа |
| `[TryFunction]` | 328 | Зөвхөн integration/interop давхаргад голчлон |
| `ErrorInfo.Create()` | 179 | Collectible error (шинэ validation-ууд) |
| `ReadIsolation(` | 183 | ReadUncommitted-оор лүүкап хийх шинэ pattern |
| `[BusinessEvent]` | 0 (BaseApp W1) | Business event-үүд тусдаа app-уудад байрладаг |

---

## 8. Review skill-д хамгийн их ач холбогдолтой лавлагаа файлууд

| Сэдэв | Файл |
|---|---|
| Документ posting-ийн эталон | `Sales/Posting/SalesPost.Codeunit.al` (CU 80) |
| Санхүүгийн бичилтийн цөм | `Finance/GeneralLedger/Posting/GenJnlPostLine.Codeunit.al` (CU 12) |
| Batch posting + Commit | `Finance/GeneralLedger/Posting/GenJnlPostBatch.Codeunit.al` |
| Бараа материалын бичилт | `Inventory/Posting/ItemJnlPostLine.Codeunit.al` (CU 22), `Inventory/Journal/ItemJnlCheckLine.Codeunit.al` |
| Posting preview | `Finance/GeneralLedger/Preview/GenJnlPostPreview.Codeunit.al` |
| Документ lifecycle | `Sales/Document/ReleaseSalesDocument.Codeunit.al` |
| Background posting | `Sales/Posting/SalesPostviaJobQueue.Codeunit.al` (CU 88) |
| Table validation | `Sales/Document/SalesLine.Table.al`, `Sales/Customer/Customer.Table.al` |
| Interface pattern | `Finance/ReceivablesPayables/InvoicePosting.Interface.al`, `Pricing/Calculation/PriceCalculation.Interface.al` |
| API page pattern | BCApps: `Apps/W1/APIV2/app/src/pages/APIV2SalesInvoices.Page.al` |
| Facade pattern | BCApps: `Business Foundation/App/NoSeries/src/Single/NoSeries.Codeunit.al` |
| Event subscriber загвар | `Foundation/Attachment/DocumentAttachmentMgmt.Codeunit.al` |
| HTTP integration | `Finance/Consolidation/ImportConsolidationFromAPI.Codeunit.al` |
| Тестийн загвар | `Tests/ERM/BackgroundDocumentPosting.Codeunit.al` |
