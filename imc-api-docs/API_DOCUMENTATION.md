# EM.BC.IMC.API — Бүрэн API Гарын Авлага

> **Publisher:** EM Consulting LLC  
> **App Name:** EM.BC.IMC.API  
> **Version:** 1.0.1.18 (`dev` салбар, сүүлийн commit `802b343`, 2026-09-07)  
> **Зориулалт:** SYNC → Business Central интеграцийн бүх API-ууд  
> **Шинэчилсэн огноо:** 2026-10-14 — бүх хэсгийг `dev` салбарын эх кодтой (Page / Codeunit / Table) тулган шалгаж засварласан

---

## Агуулга

1. [Ерөнхий мэдээлэл](#1-ерөнхий-мэдээлэл)
2. [API Жагсаалт](#2-api-жагсаалт)
3. [GET API-ууд (Лавлагаа)](#3-get-api-ууд-лавлагаа)
   - [3.1 FA Inquiry — Үндсэн хөрөнгийн лавлагаа](#31-fa-inquiry--үндсэн-хөрөнгийн-лавлагаа)
   - [3.2 Customer AR Inquiry — Авлагын лавлагаа](#32-customer-ar-inquiry--авлагын-лавлагаа)
   - [3.3 Vendor AP Inquiry — Өглөгийн лавлагаа](#33-vendor-ap-inquiry--өглөгийн-лавлагаа)
   - [3.4 Misc Article Inquiry — Эд зүйлсийн лавлагаа](#34-misc-article-inquiry--эд-зүйлсийн-лавлагаа)
   - [3.5 Customer Inquiry — Харилцагчийн лавлагаа](#35-customer-inquiry--харилцагчийн-лавлагаа)
   - [3.6 Warehouse Inquiry — Агуулахын лавлагаа](#36-warehouse-inquiry--агуулахын-лавлагаа)
   - [3.7 Item Inquiry — Барааны лавлагаа](#37-item-inquiry--барааны-лавлагаа)
   - [3.8 Item Location Inquiry — Байршлын барааны лавлагаа](#38-item-location-inquiry--байршлын-барааны-лавлагаа)
   - [3.9 Item UOM Inquiry — Хэмжих нэгжийн лавлагаа](#39-item-uom-inquiry--хэмжих-нэгжийн-лавлагаа)
   - [3.10 Employee Inquiry — Ажилтны лавлагаа](#310-employee-inquiry--ажилтны-лавлагаа)
   - [3.11 Employee Ledger Inquiry — Ажилтны дэвтрийн лавлагаа](#311-employee-ledger-inquiry--ажилтны-дэвтрийн-лавлагаа)
4. [POST API-ууд (Бичилт)](#4-post-api-ууд-бичилт)
   - [4.1 Entity Creation — Ажилтан үүсгэх / шинэчлэх / идэвхгүй болгох](#41-entity-creation--ажилтан-үүсгэх--шинэчлэх--идэвхгүй-болгох)
   - [4.2 FA Movement — ҮХ шилжүүлэг](#42-fa-movement--үх-шилжүүлэг)
   - [4.3 Gen Journal Import — Ерөнхий журнал импорт](#43-gen-journal-import--ерөнхий-журнал-импорт)
   - [4.4 POS Sales — POS борлуулалт](#44-pos-sales--pos-борлуулалт)
   - [4.5 POS Sales Return — POS буцаалт](#45-pos-sales-return--pos-буцаалт)
   - [4.6 Item Journal — Барааны журнал](#46-item-journal--барааны-журнал)
   - [4.7 Sales Journal — Борлуулалтын журнал](#47-sales-journal--борлуулалтын-журнал)
   - [4.8 Salary Journal — Цалингийн журнал](#48-salary-journal--цалингийн-журнал)
5. [Өөрчлөлтийн түүх (Change History)](#5-өөрчлөлтийн-түүх-change-history)
6. [Хавсралт: Sync Integration Setup тохиргоо](#хавсралт-sync-integration-setup-тохиргоо)

---

## 1. Ерөнхий мэдээлэл

### Base URL

```
https://api.businesscentral.dynamics.com/v2.0/{tenantId}/{environmentName}/api/EMConsulting/Sync/v1.0/companies({companyId})/
```

| Орчин | environmentName |
|-------|----------------|
| Production | `production` |
| Sandbox | `sand0205` |

> **Тэмдэглэл:** BC-ийн custom API-ууд компанийн түвшинд ажилладаг тул `companies({companyId})/` хэсгийг URL-д оруулна. Доорх endpoint-ууд энэ base URL-аас хойших харьцангуй замаар бичигдсэн.

### Баталгаажуулалт (Authentication)

- **Төрөл:** OAuth 2.0 (Client Credentials)
- **Token endpoint:** `https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token`
- **Scope:** `https://api.businesscentral.dynamics.com/.default`

### HTTP Headers

```
Authorization: Bearer {access_token}
Content-Type: application/json
```

### API Publisher / Group / Version

| Параметр | Утга |
|----------|------|
| APIPublisher | `EMConsulting` |
| APIGroup | `Sync` |
| APIVersion | `v1.0` |

### Ерөнхий зарчмууд

- **Лог:** Бүх API хүсэлт бүрийг `API Log Management` (codeunit 83009, EM.BC.Base-ийн `EM API Log Entry`)-д хүсэлт/хариу, амжилт/алдаатайгаар бичнэ.
- **Лавлагааны (GET) API-ууд** түр (temporary) buffer хүснэгт дээр ажилладаг. Зөвхөн тухайн API-д тайлбарласан шүүлтүүрийн талбаруудыг код уншина — бусад талбараар өгсөн `$filter` найдвартай ажиллахгүй.
- **Олон GET API илэрц олдохгүй үед хоосон массив биш алдаа буцаадаг** (API тус бүрийн тэмдэглэлийг үз).
- **Журналын (Item / Sales / Salary) API-ууд** `requestJson` string хүлээн авч, HTTP түвшинд алдаа шиддэггүй — үр дүнг `responseJson`-д буцаана.
- **POS Sales** нь Sales Order-ийг шууд үүсгэхгүй, Job Queue-ээр ажилладаг background processor үүсгэнэ.

### Хамаарал (Dependencies)

`EM.BC.IMC.API` **v1.0.1.18** (`app.json`, `dev` салбар) суулгахын өмнө дараах өргөтгөлүүд суусан байх ёстой:

| Өргөтгөл | Publisher | Хамгийн бага хувилбар | Хэрэглэгч API / объект |
|----------|-----------|----------------------|------------------------|
| System Application | Microsoft | 26.0.0.0 | — |
| Base Application | Microsoft | 26.0.0.0 | — |
| EM.BC.FA.Movement | EM Consulting LLC | 1.0.0.0 | FA Movement (`FA Movement Header`, `FA Movement Line` хүснэгтүүдэд бичнэ) |
| EM.BC.FA.Count | EM Consulting LLC | 1.0.0.0 | Misc Article Inquiry |
| EM.BC.IMC.FM | EM Consulting LLC | 1.0.0.14 | FA Inquiry, FA Movement |
| EM.BC.Base | EM Consulting LLC | 1.0.0.2 | API Log Management (`EM API Log Management`, `EM Core Log Management`, `EM API Log Entry`) |
| **EM.BC.Core.CG** | EM Consulting LLC | **1.0.0.46** | **Entity Creation** (Employee дээрх `EM CG Bank Code`, `EM CG Bank Account Name` талбарууд) |

> **Тэмдэглэл:** `EM.BC.Core.CG`-ийн хамаарлын хувилбар 2026-08-28-ны `10544410` commit-д `1.0.0.52` байсан ч мөн өдрийн `83318044` ("app json changed") commit-оор **`1.0.0.46`** болж буурсан. `dev` дээрх одоогийн утга нь `1.0.0.46`.
> Runtime `15.0`, application `26.0.0.0`, idRange `83000–83120`.

---

## 2. API Жагсаалт

### GET API-ууд (Зөвхөн унших)

| # | API нэр | EntitySetName | Page | Шүүлтүүр | Тайлбар |
|---|---------|---------------|------|----------|---------|
| 1 | FA Inquiry | `faInquiries` | 83004 | `employeeNo` (**заавал**) | Ажилтны хариуцсан үндсэн хөрөнгө |
| 2 | Customer AR Inquiry | `customerARInquiries` | 83005 | `customerNo` (**заавал**) | Харилцагчийн нээлттэй авлага |
| 3 | Vendor AP Inquiry | `vendorAPInquiries` | 83006 | `vendorNo` (**заавал**) | Нийлүүлэгчийн нээлттэй өглөг |
| 4 | Misc Article Inquiry | `miscArticleInquiries` | 83007 | `employeeNo` (**заавал**) | Ажилтанд олгосон эд зүйлс |
| 5 | Customer Inquiry | `customerInquiries` | 83008 | `no`, `name` | Харилцагчийн мэдээлэл |
| 6 | Warehouse Inquiry | `warehouseInquiries` | 83009 | `code`, `name` | Агуулах (Location) |
| 7 | Item Inquiry | `itemInquiries` | 83010 | `itemNumber`, `itemCategoryCode`, `unitPrice`, `locationCode` | Барааны үлдэгдэл, lot, баркод |
| 8 | Item Location Inquiry | `itemLocationInquiries` | 83054 | `itemNumber` + `locationCode` (**хоёулаа заавал**) | Нэг барааны нэг байршил дахь үлдэгдэл |
| 9 | Item UOM Inquiry | `unitsOfMeasure` | 83055 | — | Хэмжих нэгжийн ерөнхий жагсаалт |
| 10 | Employee Inquiry | `employeeInquiries` | 83016 | `no`, `firstName` | Ажилтны мэдээлэл |
| 11 | Employee Ledger Inquiry | `employeeLedgerInquiries` | 83060 | — | Ажилтны нээлттэй үлдэгдэл (бүлгээр) |

### POST API-ууд (Бичих)

| # | API нэр | EntitySetName | Page | Тайлбар |
|---|---------|---------------|------|---------|
| 1 | Entity Creation | `entityCreations` | 83000 | **Зөвхөн ажилтан** үүсгэх / шинэчлэх / идэвхгүй болгох (банкны мэдээлэл, COST CENTER / BRANCH dimension орно) |
| 2 | FA Movement | `faMovements` | 83011 | ҮХ шилжүүлгийн баримт (`FA Movement Header/Line`) үүсгэх. Мөрүүдийг `linesJson` string-ээр |
| 3 | Gen Journal Import | `genJournalImports` | 83012 | Ерөнхий журналын мөр үүсгэх (хүсэлт дотроо шууд) |
| 4 | POS Sales | `posSales` | 83030 | POS борлуулалт хадгалах (толгой + `lines`), SO-г background-оор үүсгэнэ |
| 5 | POS Sales Return | `posSalesReturn` | 83036 | POS борлуулалт буцаах |
| 6 | Item Journal | `itemJournals` | 83052 | Барааны мөрүүдийг Pre Item Journal-д бичих (`requestJson`) |
| 7 | Sales Journal | `salesJournals` | 83053 | Борлуулалтын мөрүүдийг Pre Sales Journal-д бичих (`requestJson`) |
| 8 | Salary Journal | `salaryJournals` | 83058 | Цалингийн мөрүүдийг Pre Salary Journal-д бичих (`requestJson`) |

---

## 3. GET API-ууд (Лавлагаа)

> **3.1–3.6 API-уудын нийтлэг шинж:** Бүгд `PageType = API`, зөвхөн унших (`InsertAllowed`/`ModifyAllowed`/`DeleteAllowed = false`), түр (temporary) buffer хүснэгт дээр ажилладаг, `ODataKeyFields` заагаагүй. Өгөгдлийг `OnOpenPage` триггерт `Rec.GetFilter(...)`-ээр **зөвхөн доор заасан шүүлтүүрийн талбар(ууд)**-ыг уншиж, management codeunit-ээр buffer-ийг дүүргэнэ. Codeunit эхлээд buffer-т `Reset()` хийдэг тул бусад талбараар өгсөн `$filter` найдвартай ажиллахгүй. Хүсэлт бүр `API Log Management`-д бүртгэгдэнэ (амжилт/алдаа). Хоосон огноо `0001-01-01` хэлбэрээр ирнэ.

---

### 3.1 FA Inquiry — Үндсэн хөрөнгийн лавлагаа

**Endpoint:**
```
GET /faInquiries?$filter=employeeNo eq 'EMP001'
```

| Шинж | Утга |
|------|------|
| Page | 83004 `FA Inquiry API` |
| EntityName / EntitySetName | `faInquiry` / `faInquiries` |
| Codeunit / Buffer | 83001 `FA Inquiry Management` / 83001 `FA Inquiry Buffer` |
| Шүүлтүүр | `employeeNo` — **заавал** |

> **Тэмдэглэл (шүүлтүүр):**
> - `employeeNo` шүүлтүүргүй дуудвал `Employee No filter is required for FA inquiry` алдаа буцна.
> - Ажилтан олдохгүй бол `Employee {filter} not found` алдаа.
> - Шүүлтүүрийг `Employee`-д `SetFilter` хийгээд `FindFirst()` авдаг тул wildcard/range өгсөн ч **зөвхөн эхний олдсон ажилтны** хөрөнгө буцна.

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Хариун доторх дэс дугаар (1-ээс) |
| employeeNo | Code | Ажилтны дугаар (Employee `No.`) |
| employeeName | Text | `First Name` + ' ' + `Last Name` |
| faNo | Code | ҮХ дугаар (Fixed Asset `No.`) |
| faDescription | Text | ҮХ-ийн `Description` |
| faClassCode | Code | `FA Class Code` |
| faSubclassCode | Code | `FA Subclass Code` |
| faLocationCode | Code | `FA Location Code` |
| responsibleEmployee | Code | ҮХ-ийн `Responsible Employee` (= employeeNo) |
| serialNo | Text | `Serial No.` |
| acquisitionDate | Date | `FINANCE` элэгдлийн дэвтрийн **`Depreciation Starting Date`** (бодит олж авсан огноо биш) |
| acquisitionCost | Decimal | FA Ledger Entry-ийн `FA Posting Type = Acquisition Cost` бичилтүүдийн `Amount`-ийн нийлбэр (бүх элэгдлийн дэвтэр); бичилт байхгүй/0 бол `FINANCE` дэвтрийн `Acquisition Cost` |
| depreciationBookCode | Code | `FINANCE` (уг дэвтэр ҮХ-д байхгүй бол хоосон) |
| bookValue | Decimal | `FINANCE` дэвтрийн `Acquisition Cost` − `Depreciation` |
| faStatus | Option | `Active` эсвэл `Under Maintenance` (ҮХ-ийн `Under Maintenance` тэмдэглэгээгээр) |
| blocked | Boolean | ҮХ картын `Blocked` төлөв |
| lastMaintenanceDate | Date | Код дүүргэдэггүй — үргэлж хоосон |
| comment | Text | ҮХ-ийн Comment Line-уудыг JSON массив **текст** болгосон утга (`[{"date":"YYYY-MM-DD","comment":"..."}]`), 2048 тэмдэгтээр тасална |
| rfidCode | Code | ҮХ картын `RFID Code` |

**Жишээ хариу:**
```json
{
  "value": [
    {
      "entryNo": 1,
      "employeeNo": "EMP001",
      "employeeName": "Бат Дорж",
      "faNo": "FA000010",
      "faDescription": "Зөөврийн компьютер",
      "faClassCode": "TANGIBLE",
      "faSubclassCode": "COMPUTER",
      "faLocationCode": "OFFICE-01",
      "responsibleEmployee": "EMP001",
      "serialNo": "SN12345",
      "acquisitionDate": "2023-01-15",
      "acquisitionCost": 2500000,
      "depreciationBookCode": "FINANCE",
      "bookValue": 1800000,
      "faStatus": "Active",
      "blocked": false,
      "lastMaintenanceDate": "0001-01-01",
      "comment": "[{\"date\":\"2024-03-15\",\"comment\":\"Серверийн өрөөнд байна\"},{\"date\":\"2025-01-10\",\"comment\":\"2024 онд шалгагдсан\"}]",
      "rfidCode": "RF0000123"
    }
  ]
}
```

> **Тэмдэглэл (бизнес дүрэм):**
> - `Responsible Employee` = тухайн ажилтан байгаа **бүх** ҮХ буцна. Blocked ҮХ ч орно (`blocked = true`), Inactive/актлагдсан эсэхийг шүүдэггүй.
> - `comment` нь JSON массив биш, JSON агуулсан **string** — клиент талд дахин parse хийнэ. Comment байхгүй бол `"[]"`.
> - Элэгдлийн дэвтэр `FINANCE` гэж кодонд хатуу тогтоогдсон.
> - Ажилтанд ҮХ огт оноогдоогүй бол алдаа биш, нэг "хоосон" мөр буцна: `faNo = ""`, `faDescription = "No fixed assets assigned to this employee"`, бусад талбар хоосон (`comment = ""`).

---

### 3.2 Customer AR Inquiry — Авлагын лавлагаа

**Endpoint:**
```
GET /customerARInquiries?$filter=customerNo eq 'C00010'
```

| Шинж | Утга |
|------|------|
| Page | 83005 `Customer AR Inquiry API` |
| EntityName / EntitySetName | `customerARInquiry` / `customerARInquiries` |
| Codeunit / Buffer | 83002 `Customer AR Management` / 83008 `Customer AR Inquiry Buffer` |
| Шүүлтүүр | `customerNo` — **заавал** |

> **Тэмдэглэл (шүүлтүүр):**
> - Шүүлтүүргүй бол `Customer No filter is required for AR inquiry` алдаа.
> - Харилцагч олдохгүй бол `Customer {filter} not found` алдаа.
> - `FindFirst()` ашигладаг тул wildcard/range өгсөн ч зөвхөн эхний харилцагчийн бичилт буцна.

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Хариун доторх дэс дугаар (Cust. Ledger Entry-ийн Entry No. биш) |
| customerNo | Code | Харилцагчийн дугаар |
| customerName | Text | Customer `Name` |
| documentType | Enum | Баримтын төрөл (`Gen. Journal Document Type`: Invoice, Payment, Credit Memo …) |
| documentNo | Code | `Document No.` |
| externalDocumentNo | Code | `External Document No.` |
| postingDate | Date | `Posting Date` |
| dueDate | Date | `Due Date` |
| documentDate | Date | `Document Date` |
| currencyCode | Code | `Currency Code` (MNT бол хоосон) |
| originalAmount | Decimal | `Original Amount` (бичилтийн валютаар) |
| remainingAmount | Decimal | `Remaining Amount` (бичилтийн валютаар) |
| amountLCY | Decimal | `Amount (LCY)` |
| remainingAmtLCY | Decimal | `Remaining Amt. (LCY)` |
| daysOverdue | Integer | `Today − Due Date` (хугацаа хэтрээгүй бол 0) |
| paymentTermsCode | Code | Код дүүргэдэггүй — үргэлж хоосон |
| salespersonCode | Code | Бичилтийн `Salesperson Code` |
| globalDimension1Code | Code | Бичилтийн `Global Dimension 1 Code` |
| globalDimension2Code | Code | Бичилтийн `Global Dimension 2 Code` |
| entryStatus | Option | `Open` (үлдэгдэл = анхны дүн) / `Partial` (хэсэгчлэн хаагдсан) |

**Жишээ хариу:**
```json
{
  "value": [
    {
      "entryNo": 1,
      "customerNo": "C00010",
      "customerName": "Ган ХХК",
      "documentType": "Invoice",
      "documentNo": "INV-001234",
      "externalDocumentNo": "EXT-001",
      "postingDate": "2024-11-15",
      "dueDate": "2024-12-15",
      "documentDate": "2024-11-15",
      "currencyCode": "",
      "originalAmount": 5000000,
      "remainingAmount": 3000000,
      "amountLCY": 5000000,
      "remainingAmtLCY": 3000000,
      "daysOverdue": 30,
      "paymentTermsCode": "",
      "salespersonCode": "SP01",
      "globalDimension1Code": "BRANCH01",
      "globalDimension2Code": "DEPT01",
      "entryStatus": "Partial"
    }
  ]
}
```

> **Тэмдэглэл (бизнес дүрэм):**
> - Зөвхөн **нээлттэй** (`Open = true`) бөгөөд `Remaining Amount <> 0` Cust. Ledger Entry-үүд орно. Хаагдсан бичилт буцахгүй (`Closed` статус практикт гарахгүй).
> - `entryStatus`: `Remaining Amount = Original Amount` → `Open`, бусад → `Partial`.
> - `daysOverdue` нь серверийн өнөөдрийн огноо (`Today`)-оор тооцогдоно.
> - Нээлттэй бичилтгүй бол алдаа биш, нэг мөр буцна: `documentNo = "NO-AR-ENTRIES"`, `externalDocumentNo = "No accounts receivable entries found"`, дүнгүүд 0.

---

### 3.3 Vendor AP Inquiry — Өглөгийн лавлагаа

**Endpoint:**
```
GET /vendorAPInquiries?$filter=vendorNo eq 'V00010'
```

| Шинж | Утга |
|------|------|
| Page | 83006 `Vendor AP Inquiry API` |
| EntityName / EntitySetName | `vendorAPInquiry` / `vendorAPInquiries` |
| Codeunit / Buffer | 83003 `Vendor AP Management` / 83009 `Vendor AP Inquiry Buffer` |
| Шүүлтүүр | `vendorNo` — **заавал** |

> **Тэмдэглэл (шүүлтүүр):**
> - Шүүлтүүргүй бол `Vendor No filter is required for AP inquiry` алдаа.
> - Нийлүүлэгч олдохгүй бол `Vendor {filter} not found` алдаа.
> - `FindFirst()` ашигладаг тул зөвхөн эхний олдсон нийлүүлэгчийн бичилт буцна.

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Хариун доторх дэс дугаар |
| vendorNo | Code | Нийлүүлэгчийн дугаар |
| vendorName | Text | Vendor `Name` |
| documentType | Enum | Баримтын төрөл (`Gen. Journal Document Type`) |
| documentNo | Code | `Document No.` |
| externalDocumentNo | Code | `External Document No.` |
| vendorInvoiceNo | Code | Код дүүргэдэггүй — үргэлж хоосон |
| postingDate | Date | `Posting Date` |
| dueDate | Date | `Due Date` |
| documentDate | Date | `Document Date` |
| currencyCode | Code | `Currency Code` (MNT бол хоосон) |
| originalAmount | Decimal | `Original Amount` (өглөг сөрөг тэмдэгтэй) |
| remainingAmount | Decimal | `Remaining Amount` |
| amountLCY | Decimal | `Amount (LCY)` |
| remainingAmtLCY | Decimal | `Remaining Amt. (LCY)` |
| daysOverdue | Integer | `Today − Due Date` (хэтрээгүй бол 0) |
| paymentTermsCode | Code | Код дүүргэдэггүй — үргэлж хоосон |
| purchaserCode | Code | Бичилтийн `Purchaser Code` |
| globalDimension1Code | Code | Бичилтийн `Global Dimension 1 Code` |
| globalDimension2Code | Code | Бичилтийн `Global Dimension 2 Code` |
| entryStatus | Option | `Open` (\|үлдэгдэл\| = \|анхны дүн\|) / `Partial` |

**Жишээ хариу:**
```json
{
  "value": [
    {
      "entryNo": 1,
      "vendorNo": "V00010",
      "vendorName": "Мөнх Трейд ХХК",
      "documentType": "Invoice",
      "documentNo": "PI-005678",
      "externalDocumentNo": "VND-INV-001",
      "vendorInvoiceNo": "",
      "postingDate": "2024-10-20",
      "dueDate": "2024-11-20",
      "documentDate": "2024-10-20",
      "currencyCode": "",
      "originalAmount": -3500000,
      "remainingAmount": -3500000,
      "amountLCY": -3500000,
      "remainingAmtLCY": -3500000,
      "daysOverdue": 0,
      "paymentTermsCode": "",
      "purchaserCode": "PUR01",
      "globalDimension1Code": "BRANCH01",
      "globalDimension2Code": "",
      "entryStatus": "Open"
    }
  ]
}
```

> **Тэмдэглэл (бизнес дүрэм):**
> - Зөвхөн нээлттэй (`Open = true`), `Remaining Amount <> 0` Vendor Ledger Entry-үүд орно.
> - `entryStatus`-ийг абсолют утгаар харьцуулна: `Abs(Remaining) = Abs(Original)` → `Open`, бусад → `Partial`.
> - Нийлүүлэгчийн нэхэмжлэлийн дугаар нь Vendor Ledger Entry-д `External Document No.`-д хадгалагддаг тул `externalDocumentNo`-г ашиглана.
> - Нээлттэй бичилтгүй бол нэг мөр буцна: `documentNo = "NO-AP-ENTRIES"`, `externalDocumentNo = "No accounts payable entries found"`.

---

### 3.4 Misc Article Inquiry — Эд зүйлсийн лавлагаа

**Endpoint:**
```
GET /miscArticleInquiries?$filter=employeeNo eq 'EMP001'
```

| Шинж | Утга |
|------|------|
| Page | 83007 `Misc Article Inquiry API` |
| EntityName / EntitySetName | `miscArticleInquiry` / `miscArticleInquiries` |
| Codeunit / Buffer | 83004 `Misc Article Management` / 83010 `Misc Article Inquiry Buffer` |
| Эх хүснэгт | `Misc. Article Information` (ажилтанд олгосон эд зүйлс) |
| Шүүлтүүр | `employeeNo` — **заавал** |

> **Тэмдэглэл (шүүлтүүр ба алдаа):**
> - Шүүлтүүргүй бол `Employee filter is required. Received empty filter.` алдаа.
> - Ажилтан олдохгүй бол `No employee found with number: {filter}` алдаа.
> - Ажилтанд эд зүйл бүртгэгдээгүй бол хоосон жагсаалт биш, **`No misc articles found` алдаа** буцна.

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Хариун доторх дэс дугаар |
| employeeNo | Code | Ажилтны дугаар |
| employeeName | Text | Ажилтны бүтэн нэр (`Employee.FullName()`) |
| miscArticleCode | Code | `Misc. Article Code` |
| description | Text | Misc. Article Information-ийн `Description` |
| fromDate | Date | `From Date` |
| toDate | Date | `To Date` |
| inUse | Boolean | `In Use` |
| comment | Text | Тогтмол текст: `"Assigned to {employeeNo}"` |
| serialNo | Text | Код дүүргэдэггүй — үргэлж хоосон |
| unitOfMeasureCode | Code | Код дүүргэдэггүй — үргэлж хоосон |
| unitCost | Decimal | Код дүүргэдэггүй — үргэлж 0 |
| vendorNo | Code | Код дүүргэдэггүй — үргэлж хоосон |
| vendorName | Text | Код дүүргэдэггүй — үргэлж хоосон |
| status | Option | Үргэлж `Active` |
| lastModifiedDate | Date | Бичлэгийн `SystemModifiedAt`-ийн огноо |
| globalDimension1Code | Code | **Ажилтны** `Global Dimension 1 Code` |
| globalDimension2Code | Code | **Ажилтны** `Global Dimension 2 Code` |

**Жишээ хариу:**
```json
{
  "value": [
    {
      "entryNo": 1,
      "employeeNo": "EMP001",
      "employeeName": "Бат Дорж",
      "miscArticleCode": "PHONE",
      "description": "Гар утас",
      "fromDate": "2025-02-01",
      "toDate": "0001-01-01",
      "inUse": true,
      "comment": "Assigned to EMP001",
      "serialNo": "",
      "unitOfMeasureCode": "",
      "unitCost": 0,
      "vendorNo": "",
      "vendorName": "",
      "status": "Active",
      "lastModifiedDate": "2026-06-25",
      "globalDimension1Code": "BRANCH01",
      "globalDimension2Code": ""
    }
  ]
}
```

> **Тэмдэглэл (бизнес дүрэм):**
> - `In Use` эсэхээс үл хамааран ажилтны бүх Misc. Article Information мөр буцна (шүүдэггүй).
> - `fromDate`, `toDate`, `inUse`, `lastModifiedDate` нь бодит бичлэгээс авагдана (2026-06-25-аас өмнө `Today` / `true` гэж хатуу тогтоогддог байсан).
> - Шүүлтүүрийг Misc. Article Information-д шууд `SetFilter` хийдэг тул wildcard өгвөл олон ажилтны мөр гарч болох ч `employeeNo`, `employeeName`, dimension нь **эхний олдсон ажилтных** байна — тодорхой нэг ажилтны дугаар өгөхийг зөвлөнө.

---

### 3.5 Customer Inquiry — Харилцагчийн лавлагаа

**Endpoint:**
```
GET /customerInquiries
GET /customerInquiries?$filter=no eq 'C00010'
GET /customerInquiries?$filter=name eq 'Ган'
```

| Шинж | Утга |
|------|------|
| Page | 83008 `Customer Inquiry API` |
| EntityName / EntitySetName | `customerInquiry` / `customerInquiries` |
| Codeunit / Buffer | 83005 `Customer Inquiry Management` / 83011 `Customer Inquiry Buffer` |
| Шүүлтүүр | `no`, `name` — сонголттой (хоёуланг нь өгвөл AND) |

> **Тэмдэглэл (шүүлтүүр):**
> - Шүүлтүүргүй бол **бүх** харилцагч (blocked-ыг оруулаад) буцна.
> - `no`: утгаас `'` болон `*` тэмдэгтийг хасаад **яг тэнцүү** (`SetRange`) хайна — wildcard ажиллахгүй.
> - `name`: `'` болон `*`-г хасаад **агуулсан, том жижиг үсэг ялгахгүй** (`@*утга*`) хайна. Иймд `name eq 'Ган'` ба `name eq '*Ган*'` адил үр дүнтэй.
> - Илэрц байхгүй бол алдаа: `No customers found matching filter: {no}` (зөвхөн `name` өгсөн үед `No customers found in the system`).

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Хариун доторх дэс дугаар |
| no | Code | Харилцагчийн дугаар |
| name | Text | Нэр |
| name2 | Text | Нэр 2 |
| address | Text | Хаяг |
| address2 | Text | Хаяг 2 |
| city | Text | Хот |
| postCode | Code | Шуудангийн код |
| countryRegionCode | Code | Улс/бүсийн код |
| phoneNo | Text | Утас |
| email | Text | И-мэйл |
| contact | Text | Холбоо барих хүн |
| customerPostingGroup | Code | Customer Posting Group |
| genBusPostingGroup | Code | Gen. Bus. Posting Group |
| vatBusPostingGroup | Code | VAT Bus. Posting Group |
| paymentTermsCode | Code | Төлбөрийн нөхцөл |
| paymentMethodCode | Code | Төлбөрийн хэлбэр |
| currencyCode | Code | Валютын код |
| creditLimit | Decimal | `Credit Limit (LCY)` |
| balance | Decimal | `Balance (LCY)` — үлдэгдэл (MNT) |
| balanceDue | Decimal | `Balance Due (LCY)` — төлөх хугацаа болсон үлдэгдэл (MNT) |
| blocked | Enum | `Customer Blocked`: хоосон / `Ship` / `Invoice` / `All` |
| lastDateModified | Date | Last Date Modified |
| salespersonCode | Code | Борлуулагч |
| territoryCode | Code | Бүсийн код |
| globalDimension1Code | Code | Глобал хэмжигдэхүүн 1 |
| globalDimension2Code | Code | Глобал хэмжигдэхүүн 2 |
| registrationNumber | Text | Регистрийн дугаар |
| vatRegistrationNo | Text | НӨАТ-ын бүртгэлийн дугаар |
| customerPriceGroup | Code | Үнийн бүлэг |

**Жишээ хариу:**
```json
{
  "value": [
    {
      "entryNo": 1,
      "no": "C00010",
      "name": "Ган ХХК",
      "name2": "",
      "address": "Сүхбаатар дүүрэг, 1-р хороо",
      "address2": "",
      "city": "Улаанбаатар",
      "postCode": "14200",
      "countryRegionCode": "MN",
      "phoneNo": "99112233",
      "email": "info@gan.mn",
      "contact": "Болд",
      "customerPostingGroup": "DOMESTIC",
      "genBusPostingGroup": "DOMESTIC",
      "vatBusPostingGroup": "DOMESTIC",
      "paymentTermsCode": "NET30",
      "paymentMethodCode": "BANK",
      "currencyCode": "",
      "creditLimit": 10000000,
      "balance": 3000000,
      "balanceDue": 3000000,
      "blocked": "_x0020_",
      "lastDateModified": "2025-11-01",
      "salespersonCode": "SP01",
      "territoryCode": "",
      "globalDimension1Code": "BRANCH01",
      "globalDimension2Code": "",
      "registrationNumber": "1234567",
      "vatRegistrationNo": "1234567",
      "customerPriceGroup": "RETAIL"
    }
  ]
}
```

> **Тэмдэглэл:** `blocked`-ийн хоосон утга BC OData-д `_x0020_` хэлбэрээр ирдэг.

---

### 3.6 Warehouse Inquiry — Агуулахын лавлагаа

**Endpoint:**
```
GET /warehouseInquiries
GET /warehouseInquiries?$filter=code eq 'MAIN'
GET /warehouseInquiries?$filter=name eq 'Төв агуулах'
```

| Шинж | Утга |
|------|------|
| Page | 83009 `Warehouse Inquiry API` |
| EntityName / EntitySetName | `warehouseInquiry` / `warehouseInquiries` |
| Codeunit / Buffer | 83006 `Warehouse Inquiry Management` / 83012 `Warehouse Inquiry Buffer` |
| Эх хүснэгт | `Location` |
| Шүүлтүүр | `code`, `name` — сонголттой (хоёуланг нь өгвөл AND) |

> **Тэмдэглэл (шүүлтүүр):**
> - Шүүлтүүргүй бол **бүх** байршил (In-Transit байршлыг оруулаад) буцна.
> - `code`, `name` утгыг `Location`-д өөрчлөлтгүйгээр `SetFilter` хийнэ. Customer Inquiry-ээс ялгаатай нь `name`-д `@`/`*` нэмэгддэггүй тул **яг тэнцүү, том жижиг үсэг ялгах** хайлт гэж үзнэ.
> - Илэрц байхгүй бол алдаа: `No locations found matching filter: {code}` (зөвхөн `name` өгсөн үед `No locations found in the system`).

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Хариун доторх дэс дугаар |
| code | Code | Байршлын код |
| name | Text | Нэр |
| address | Text | Хаяг |
| address2 | Text | Хаяг 2 |
| city | Text | Хот |
| postCode | Code | Шуудангийн код |
| countryRegionCode | Code | Улс/бүсийн код |
| phoneNo | Text | Утас |
| faxNo | Text | Факс |
| contact | Text | Холбоо барих хүн |
| email | Text | И-мэйл |
| useAsInTransit | Boolean | Дамжин өнгөрөх (In-Transit) байршил эсэх |
| requirePutAway | Boolean | Put-away (байршуулалт) шаардлагатай |
| requirePick | Boolean | Pick (түүвэрлэлт) шаардлагатай |
| requireReceive | Boolean | Receive (хүлээн авалт) шаардлагатай |
| requireShipment | Boolean | Shipment (ачилт) шаардлагатай |
| binMandatory | Boolean | Bin заавал |
| directedPutAwayAndPick | Boolean | Directed Put-away and Pick |
| defaultBinSelection | Enum | Default Bin Selection (`Location Default Bin Selection`) |
| crossDockDueDateCalc | DateFormula | Cross-Dock Due Date Calc. |
| useCrossDocking | Boolean | Cross-docking ашиглах |
| globalDimension1Code | Code | Үргэлж хоосон (кодонд `''`) |
| globalDimension2Code | Code | Үргэлж хоосон (кодонд `''`) |
| lastDateModified | Date | **Үргэлж хүсэлтийн өдөр (`Today`)** — бодит өөрчлөлтийн огноо биш |
| warehouseClassCode | Code | Үргэлж хоосон |
| blockMovement | Option | Үргэлж хоосон (`" "`) |
| specialEquipment | Option | Үргэлж хоосон (`" "`) |
| putAwayTemplateCode | Code | Үргэлж хоосон |
| pickAccordingToFEFO | Boolean | Үргэлж `false` |

**Жишээ хариу:**
```json
{
  "value": [
    {
      "entryNo": 1,
      "code": "MAIN",
      "name": "Төв агуулах",
      "address": "Хан-Уул дүүрэг",
      "address2": "",
      "city": "Улаанбаатар",
      "postCode": "",
      "countryRegionCode": "MN",
      "phoneNo": "77001122",
      "faxNo": "",
      "contact": "Ганаа",
      "email": "",
      "useAsInTransit": false,
      "requirePutAway": false,
      "requirePick": false,
      "requireReceive": false,
      "requireShipment": false,
      "binMandatory": false,
      "directedPutAwayAndPick": false,
      "defaultBinSelection": "_x0020_",
      "crossDockDueDateCalc": "",
      "useCrossDocking": false,
      "globalDimension1Code": "",
      "globalDimension2Code": "",
      "lastDateModified": "2026-10-14",
      "warehouseClassCode": "",
      "blockMovement": "_x0020_",
      "specialEquipment": "_x0020_",
      "putAwayTemplateCode": "",
      "pickAccordingToFEFO": false
    }
  ]
}
```

> **Тэмдэглэл:** `globalDimension1Code`, `globalDimension2Code`, `lastDateModified`, `warehouseClassCode`, `blockMovement`, `specialEquipment`, `putAwayTemplateCode`, `pickAccordingToFEFO` нь codeunit-д тогтмол утгаар бөглөгддөг тул эдгээрт бизнесийн логик бүү тулгуурла.

---

### 3.7 Item Inquiry — Барааны лавлагаа

**Endpoint:**
```
GET /itemInquiries
GET /itemInquiries?$filter=itemNumber eq 'ITEM001'
GET /itemInquiries?$filter=itemCategoryCode eq 'FOOD'
GET /itemInquiries?$filter=unitPrice eq 25000
GET /itemInquiries?$filter=locationCode eq 'MAIN'
GET /itemInquiries?$filter=locationCode eq 'MAIN' and itemNumber eq 'ITEM001'
```

| Параметр | Утга |
|----------|------|
| Page | 83010 `Item Inquiry API` |
| EntityName / EntitySetName | `itemInquiry` / `itemInquiries` |
| Эх хүснэгт | `Item Inquiry Buffer` (83013, түр хүснэгт) |
| Бичих эрх | Байхгүй (Insert/Modify/Delete = false) |
| ODataKeyFields | Тодорхойлоогүй |
| Логик | Codeunit 83007 `Item Inquiry Management` → `GetPosItemListWithAllFilters` |

**Дэмжигдэх шүүлтүүрүүд:** `itemNumber`, `itemCategoryCode`, `unitPrice`, `locationCode`. Эдгээрийг page уншиж Item хүснэгтэд (`No.`, `Item Category Code`, `Unit Price`) болон Item Ledger Entry-д (`Location Code`) шүүлтүүр болгон тавина. Бусад талбараар өгсөн шүүлтүүрийг код боловсруулдаггүй.

> **Тэмдэглэл (байршлын шүүлтүүр):** `locationCode` өгөөгүй үед **бүх байршлын нийлбэрээр** тооцоолно. Sync Integration Setup-н `POS Default Location Code`-оор автоматаар шүүх код **тайлбар (comment) болгогдсон** — "POS-оос өөр гүйлгээнд ашиглаж байгаа тул хаалаа". Иймд POS-ийн байршлын үлдэгдэл хэрэгтэй бол `locationCode`-ийг заавал илгээнэ.

**Хоёр горим:**

| | `locationCode` өгөөгүй | `locationCode` өгсөн |
|---|---|---|
| Ямар бараа буцах | `Blocked = false` бүх бараа (үлдэгдэлгүй бараа ч орно) | Тухайн байршилд `Open = true`, `Remaining Quantity <> 0` Item Ledger Entry-тэй, `Blocked = false` бараа |
| Мөрийн тоо | Бараа тус бүрт 1 мөр | Бараа + байршил хослол тус бүрт 1 мөр |
| locationCode | `""` | ILE-ийн байршил |
| lotNumber / serialNumber / postingDate | `""` / `""` / өнөөдрийн огноо | Тухайн бараа+байршлын **анхны олдсон** нээлттэй ILE-ийн утга (нийлбэр биш) |
| remainingQuantity | Бүх байршлын боломжит үлдэгдэл | Тухайн байршлын боломжит үлдэгдэл |
| inventory | `Inventory − Qty. on Sales Order` (бүх байршил, 0-ээс бага бол 0) | Тухайн байршлын бодит `Inventory` (0-ээс бага бол 0) |
| globalDimension1/2Code | Item картын утга | ILE-ийн утга |
| lotInfo | Бүх байршлын lot-ууд | Тухайн байршлын lot-ууд |

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Хариун дахь дэс дугаар (1, 2, 3 …). BC-ийн бичилтийн дугаар биш |
| itemNumber | Code[20] | Барааны дугаар (`Item."No."`) |
| description | Text[100] | Барааны тайлбар (`Item.Description`) |
| locationCode | Code[10] | Байршлын код (байршлын шүүлтүүргүй үед хоосон) |
| lotNumber | Code[50] | Байршлын горимд анхны нээлттэй ILE-ийн Lot No., бусад үед хоосон |
| serialNumber | Code[50] | Байршлын горимд анхны нээлттэй ILE-ийн Serial No., бусад үед хоосон |
| remainingQuantity | Decimal | Боломжит (зарж болох) үлдэгдэл — доорх тооцооллыг үзнэ үү |
| postingDate | Date | Байршлын горимд анхны нээлттэй ILE-ийн Posting Date, бусад үед өнөөдрийн огноо |
| lastModifiedDateTime | DateTime | Хүсэлт боловсруулсан цаг (`CurrentDateTime`). Барааны бодит өөрчлөлтийн огноо биш |
| baseUnitOfMeasure | Code[10] | Суурь хэмжих нэгж |
| unitPrice | Decimal | Нэгжийн үнэ (`Item."Unit Price"`) |
| unitCost | Decimal | Нэгжийн өртөг (`Item."Unit Cost"`) |
| itemCategoryCode | Code[20] | Барааны ангиллын код |
| blocked | Boolean | Хаагдсан эсэх (хаагдсан бараа хасагддаг тул үргэлж `false`) |
| isPosItem | Boolean | Item картын `Is Pos Item` талбар (TableExt 83000 `EM Item Extension`, Item Card → "EM Config" хэсэг). Шүүлтүүр биш, зөвхөн мэдээлэл |
| inventory | Decimal | Дээрх хүснэгтийн дагуу (горимоос хамаарч өөр утгатай) |
| globalDimension1Code | Code[20] | Глобал хэмжигдэхүүн 1 |
| globalDimension2Code | Code[20] | Глобал хэмжигдэхүүн 2 |
| lotInfo | Text[2000] | Lot тус бүрийн боломжит үлдэгдэл (JSON массив, текст хэлбэрээр) |
| barcodes | Text[2000] | Баркодуудын жагсаалт (JSON массив, текст хэлбэрээр) |

> **Тэмдэглэл (remainingQuantity тооцоолол):** Lot тус бүрээр дараах дарааллаар тооцно:
> 1. `Item Ledger Entry`-ээс `Open = true`, `Remaining Quantity <> 0` бичилтийн `Remaining Quantity`-г lot-оор нийлбэрлэнэ (lot-гүй бичилт `(No Lot)` нэрээр нэгтгэгдэнэ). `locationCode` өгсөн бол тухайн байршлаар шүүнэ.
> 2. BC-ийн борлуулалтын захиалгын эрэлт (`Item."Qty. on Sales Order"` FlowField, байршил өгсөн бол `Location Filter`-тэй) -ийг lot-уудаас **дарааллаар** (ILE-д анх гарсан дарааллаар) хасна. Энэ хасалт lot-д тусгайлан холбогдохгүй.
> 3. POS Sales-ийн нөөцлөсөн тоог хасна: толгой (`POS Sales`) нь **`Status = New`** бөгөөд (байршил өгсөн бол) `POS Sales.Location` таарч буй мөрүүдийн `Quantity`-г ижил `Lot Number`-тэй lot-оос хасна (lot-гүй мөр → `(No Lot)`). Lot тус бүр 0-ээс доош орохгүй. Гарт үлдэгдэлгүй lot-д хамаарах POS мөрийг тооцохгүй.
> 4. `remainingQuantity` = 0-ээс их lot-уудын нийлбэр.
>
> Бусад POS статус (`Cancelled`, `EB Done`, `SO Generated`, `Partial SO Generated`, `Returned`, `SO Returned`) нөөцөд тооцогдохгүй (SO үүссэн бол 2-р алхмаар хасагдана).

> **Тэмдэглэл (хоосон хариу):** Шүүлтүүрт таарах бараа олдохгүй бол хоосон массив биш **алдаа** буцаана: байршлын шүүлтүүргүй үед `No POS items found (Is Pos Item = true, Blocked = false) matching the specified filters`, байршилтай үед `No items found with inventory at the specified location` эсвэл `No items found matching the specified filters with inventory at the given location`. (Мессежид "Is Pos Item = true" гэж бичигдсэн ч код `Is Pos Item`-ээр шүүдэггүй — тухайн шүүлтүүр тайлбар болгогдсон.)

**lotInfo бүтэц:**
- `lotNumber` — Lot дугаар, lot-гүй бичилтүүдэд `"(No Lot)"`
- `remainingQuantity` — тухайн lot-ийн **боломжит** тоо (2–3-р алхмын хасалтын дараах)
- `expiryDate` — тухайн lot-ийн нээлттэй ILE-үүдийн хамгийн **эрт** `Expiration Date` (`YYYY-MM-DD`), огноогүй бол `null`
- Зөвхөн `remainingQuantity > 0` lot-ууд орно; нэг ч үгүй бол `"[]"`
- Талбарын урт 2000 тэмдэгт тул маш олон lot-той бараанд JSON тасарч болзошгүй

```json
[
  {"lotNumber": "LOT001", "remainingQuantity": 50, "expiryDate": "2025-06-30"},
  {"lotNumber": "(No Lot)", "remainingQuantity": 30, "expiryDate": null}
]
```

**barcodes бүтэц:** `Item Reference` хүснэгтээс `Reference Type = Bar Code` бүх мөрийн `Reference No.` (хувилбар/хэмжих нэгжээр ялгахгүй). Байхгүй бол `"[]"`.
```json
["8901234567890", "8901234567891"]
```

**Жишээ хариу (`locationCode eq 'OUT'`):**
```json
{
  "value": [
    {
      "entryNo": 1,
      "itemNumber": "ITEM001",
      "description": "Мах (Үхэр)",
      "locationCode": "OUT",
      "lotNumber": "LOT001",
      "serialNumber": "",
      "remainingQuantity": 120.5,
      "postingDate": "2024-12-01",
      "lastModifiedDateTime": "2026-09-07T10:30:00Z",
      "baseUnitOfMeasure": "KG",
      "unitPrice": 25000,
      "unitCost": 18000,
      "itemCategoryCode": "FOOD",
      "blocked": false,
      "isPosItem": true,
      "inventory": 150,
      "globalDimension1Code": "BRANCH01",
      "globalDimension2Code": "",
      "lotInfo": "[{\"lotNumber\":\"LOT001\",\"remainingQuantity\":120.5,\"expiryDate\":\"2025-06-30\"}]",
      "barcodes": "[\"8901234567890\",\"8901234567891\"]"
    }
  ]
}
```

**Жишээ хариу (байршлын шүүлтүүргүй):**
```json
{
  "value": [
    {
      "entryNo": 1,
      "itemNumber": "ITEM001",
      "description": "Мах (Үхэр)",
      "locationCode": "",
      "lotNumber": "",
      "serialNumber": "",
      "remainingQuantity": 180.5,
      "postingDate": "2026-09-07",
      "lastModifiedDateTime": "2026-09-07T10:30:00Z",
      "baseUnitOfMeasure": "KG",
      "unitPrice": 25000,
      "unitCost": 18000,
      "itemCategoryCode": "FOOD",
      "blocked": false,
      "isPosItem": true,
      "inventory": 190,
      "globalDimension1Code": "",
      "globalDimension2Code": "",
      "lotInfo": "[{\"lotNumber\":\"LOT001\",\"remainingQuantity\":120.5,\"expiryDate\":\"2025-06-30\"},{\"lotNumber\":\"LOT002\",\"remainingQuantity\":60,\"expiryDate\":null}]",
      "barcodes": "[\"8901234567890\"]"
    }
  ]
}
```

> **Тэмдэглэл (v1.0.1.18 засвар):** Өмнө нь `locationCode` шүүлтүүргүй үед `remainingQuantity` үргэлж `0`, `lotInfo` үргэлж `"[]"` буцдаг байсан (тооцоологдоогүй `Item.Inventory` FlowField уншиж байсан). Одоо байршлын горимтой ижил lot-д суурилсан тооцооллоор бүх байршлын нийлбэрийг буцаана.

---

### 3.8 Item Location Inquiry — Байршлын барааны лавлагаа

**Endpoint:**
```
GET /itemLocationInquiries?$filter=itemNumber eq 'ITEM001' and locationCode eq 'MAIN'
```

| Параметр | Утга |
|----------|------|
| Page | 83054 `Item Location Inquiry API` |
| EntityName / EntitySetName | `itemLocationInquiry` / `itemLocationInquiries` |
| Эх хүснэгт | `Item Inquiry Buffer` (83013, түр хүснэгт) |
| Бичих эрх | Байхгүй (Insert/Modify/Delete = false) |
| ODataKeyFields | `Entry No.` |
| Логик | Codeunit 83007 `Item Inquiry Management` → `GetItemWithPriceAndQtyByLocation` |

> **Тэмдэглэл (заавал шүүлтүүр):** `itemNumber` болон `locationCode` хоёулаа **заавал**. Утгыг ганц тодорхой утгаар (`eq`) өгнө — код зөвхөн `'` тэмдэгтийг арилгаад утгыг шууд ашигладаг тул wildcard (`*`), муж (`..`), `|` ажиллахгүй.

**Алдааны мессеж:**

| Алдаа | Шалтгаан |
|-------|----------|
| `Item number parameter is required` | `itemNumber` шүүлтүүр өгөөгүй |
| `Location code parameter is required` | `locationCode` шүүлтүүр өгөөгүй |
| `Item {No} does not exist` | Бараа олдсонгүй |
| `Item {No} is blocked` | Бараа хаагдсан |

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Үргэлж `1` |
| itemNumber | Code[20] | Барааны дугаар |
| description | Text[100] | Барааны тайлбар |
| locationCode | Code[10] | Хүсэлтэд өгсөн байршлын код |
| availableQuantity | Decimal | Боломжит (зарж болох) тоо — 3.7-ийн `remainingQuantity`-тэй ижил тооцоолол (нээлттэй ILE үлдэгдэл − борлуулалтын захиалга − POS `Status = New` нөөц), тухайн байршлаар |
| baseUnitOfMeasure | Code[10] | Суурь хэмжих нэгж |
| unitPrice | Decimal | Нэгжийн үнэ (`Item."Unit Price"`) |
| itemCategoryCode | Code[20] | Барааны ангиллын код |
| inventory | Decimal | Тухайн байршлын бодит үлдэгдэл (`Item.Inventory`, `Location Filter`-тэй; 0-ээс бага бол 0) |
| blocked | Boolean | Хаагдсан эсэх (хаагдсан бол алдаа буцдаг тул үргэлж `false`) |
| isPosItem | Boolean | Item картын `Is Pos Item` талбар (шүүлтүүр биш) |
| lotInfo | Text[2000] | Lot мэдээлэл (JSON массив, 3.7-тэй ижил бүтэц/дүрэм, тухайн байршлаар) |
| barcodes | Text[2000] | Баркодууд (JSON массив, `Item Reference` → `Bar Code`) |

> **Тэмдэглэл:** Бараа олдсон, хаагдаагүй бол үлдэгдэл 0 байсан ч **нэг мөр** буцаана (`availableQuantity: 0`, `lotInfo: "[]"`). `unitCost`, `lotNumber`, `serialNumber`, `postingDate`, глобал хэмжигдэхүүн энэ API-д гарахгүй.

**Жишээ хариу:**
```json
{
  "value": [
    {
      "entryNo": 1,
      "itemNumber": "ITEM001",
      "description": "Мах (Үхэр)",
      "locationCode": "MAIN",
      "availableQuantity": 120.5,
      "baseUnitOfMeasure": "KG",
      "unitPrice": 25000,
      "itemCategoryCode": "FOOD",
      "inventory": 150,
      "blocked": false,
      "isPosItem": true,
      "lotInfo": "[{\"lotNumber\":\"LOT001\",\"remainingQuantity\":120.5,\"expiryDate\":\"2025-06-30\"}]",
      "barcodes": "[\"8901234567890\"]"
    }
  ]
}
```

---

### 3.9 Item UOM Inquiry — Хэмжих нэгжийн лавлагаа

**Endpoint:**
```
GET /unitsOfMeasure
```

| Параметр | Утга |
|----------|------|
| Page | 83055 `Item UOM Inquiry API` |
| EntityName / EntitySetName | `unitOfMeasure` / `unitsOfMeasure` |
| Эх хүснэгт | `Item UOM Inquiry Buffer` (83055, түр хүснэгт) |
| Бичих эрх | Байхгүй (Insert/Modify/Delete = false) |
| ODataKeyFields | Тодорхойлоогүй |
| Логик | Codeunit 83055 `Item UOM Inquiry Management` → `GetUOMList` |

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Хариун дахь дэс дугаар |
| code | Code[10] | Хэмжих нэгжийн код |
| description | Text[50] | Тайлбар |
| internationalStandardCode | Code[10] | Олон улсын стандарт код |

> **Тэмдэглэл:** Өгөгдлийг BC-ийн `Unit of Measure` (хэмжих нэгжийн ерөнхий жагсаалт) хүснэгтээс бүхэлд нь авна. Нэрэндээ "Item" гэж байгаа ч **бараа тус бүрийн хэмжих нэгж (`Item Unit of Measure`, хөрвүүлэх коэффициент) биш**. Код ямар нэг шүүлтүүр боловсруулдаггүй. Хүснэгт хоосон бол алдаа биш, хоосон массив буцна.

**Жишээ хариу:**
```json
{
  "value": [
    { "entryNo": 1, "code": "KG", "description": "Килограмм", "internationalStandardCode": "KGM" },
    { "entryNo": 2, "code": "PCS", "description": "Ширхэг", "internationalStandardCode": "H87" }
  ]
}
```

---

### 3.10 Employee Inquiry — Ажилтны лавлагаа

**Endpoint:**
```
GET /employeeInquiries
GET /employeeInquiries?$filter=no eq 'EMP001'
GET /employeeInquiries?$filter=firstName eq 'Бат'
```

| Параметр | Утга |
|----------|------|
| Page | 83016 `Employee Inquiry API` |
| EntityName / EntitySetName | `employeeInquiry` / `employeeInquiries` |
| Эх хүснэгт | `Employee Inquiry Buffer` (83015, түр хүснэгт) |
| Бичих эрх | Байхгүй (Insert/Modify/Delete = false) |
| ODataKeyFields | Тодорхойлоогүй |
| Логик | Codeunit 83016 `Employee Inquiry Management` → `GetEmployeeListWithFilters` |

**Шүүлтүүр:**

| Шүүлтүүр | Ажиллах зарчим |
|----------|----------------|
| `no` | `'` болон `*` тэмдэгтийг арилгаад `Employee."No."`-оор **яг тэнцүү** (`SetRange`) шүүнэ |
| `firstName` | `'` тэмдэгтийг арилгаад `Employee."First Name"`-ээр **агуулсан, том/жижиг үсэг ялгахгүй** (`@*утга*`) шүүнэ |

> **Тэмдэглэл:** Статусаар шүүдэггүй — `Active`, `Inactive`, `Terminated` бүх ажилтан буцна. Таарах ажилтан олдохгүй бол хоосон массив биш алдаа буцаана: `No employees found matching filter: {no}` (шүүлтүүртэй үед) эсвэл `No employees found in the system`.

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Хариун дахь дэс дугаар |
| no | Code[20] | Ажилтны дугаар |
| firstName | Text[30] | Нэр |
| middleName | Text[30] | Дунд нэр |
| lastName | Text[30] | Овог |
| jobTitle | Text[30] | Албан тушаал |
| address | Text[100] | Хаяг |
| address2 | Text[50] | Хаяг 2 |
| city | Text[30] | Хот |
| postCode | Code[20] | Шуудангийн код |
| countryRegionCode | Code[10] | Улс/бүсийн код |
| phoneNo | Text[30] | Утас |
| mobilePhoneNo | Text[30] | Гар утас |
| email | Text[80] | И-мэйл (`E-Mail`) |
| employmentDate | Date | Ажилд орсон огноо |
| terminationDate | Date | Ажлаас гарсан огноо |
| status | Enum `Employee Status` | `Active`, `Inactive`, `Terminated` |
| birthDate | Date | Төрсөн огноо |
| socialSecurityNo | Text[30] | НД дугаар |
| unionCode | Code[10] | Үйлдвэрчний эвлэлийн код |
| resourceNo | Code[20] | Ресурсын дугаар |
| lastDateModified | Date | Ажилтны картыг сүүлд өөрчилсөн огноо |
| globalDimension1Code | Code[20] | Глобал хэмжигдэхүүн 1 |
| globalDimension2Code | Code[20] | Глобал хэмжигдэхүүн 2 |
| managerNo | Code[20] | Менежерийн дугаар (`Manager No.`) |
| emplymtContractCode | Code[10] | Хөдөлмөрийн гэрээний код |
| statisticsGroupCode | Code[10] | Статистик бүлгийн код |

> **Тэмдэглэл:** Банкны мэдээлэл (`Bank Account No.`, `EM CG Bank Code`, `EM CG Bank Account Name`), зардлын төв/салбарын default dimension, ажилтны төрөл зэрэг талбар энэ API-д **байхгүй** (тэдгээрийг зөвхөн `entityCreations` POST API бичдэг).

**Жишээ хариу:**
```json
{
  "value": [
    {
      "entryNo": 1,
      "no": "EMP001",
      "firstName": "Бат",
      "middleName": "",
      "lastName": "Дорж",
      "jobTitle": "Нягтлан",
      "address": "",
      "address2": "",
      "city": "Улаанбаатар",
      "postCode": "",
      "countryRegionCode": "MN",
      "phoneNo": "",
      "mobilePhoneNo": "99112233",
      "email": "bat@example.mn",
      "employmentDate": "2024-01-15",
      "terminationDate": "0001-01-01",
      "status": "Active",
      "birthDate": "1990-05-20",
      "socialSecurityNo": "",
      "unionCode": "",
      "resourceNo": "",
      "lastDateModified": "2026-08-28",
      "globalDimension1Code": "BRANCH01",
      "globalDimension2Code": "",
      "managerNo": "",
      "emplymtContractCode": "",
      "statisticsGroupCode": ""
    }
  ]
}
```

---

### 3.11 Employee Ledger Inquiry — Ажилтны дэвтрийн лавлагаа

**Endpoint:**
```
GET /employeeLedgerInquiries
```

| Параметр | Утга |
|----------|------|
| Page | 83060 `Employee Ledger Inquiry API` |
| EntityName / EntitySetName | `employeeLedgerInquiry` / `employeeLedgerInquiries` |
| Эх хүснэгт | `Emp Ledger Summary Buffer` (83064, түр хүснэгт) |
| Бичих эрх | Байхгүй (Insert/Modify/Delete = false) |
| ODataKeyFields | Тодорхойлоогүй |
| Логик | Codeunit 83030 `Emp Ledger Inquiry Management` → `GetEmployeeLedgerSummary` |

**Хариу талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| employeeNo | Code[20] | Ажилтны дугаар (`Employee Ledger Entry."Employee No."`) |
| employeePostingGroup | Code[20] | Ажилтны бүртгэлийн бүлэг (бичилт дээрх `Employee Posting Group`) |
| employeePostingGroupDescription | Text[100] | `Employee Posting Group` хүснэгтийн `EM Description` талбар (стандарт BC талбар биш, EM өргөтгөлийн талбар) |
| totalRemainingAmount | Decimal | Бүлгийн бичилтүүдийн `Remaining Amount` нийлбэр (бичилтийн валютаар) |
| totalRemainingAmountLCY | Decimal | Бичилт бүрийн `Detailed Employee Ledger Entry."Amount (LCY)"` нийлбэрийн нийлбэр (MNT) |

> **Тэмдэглэл (бүлэглэлт):** Бүх `Employee Ledger Entry`-г уншиж, **ажилтны дугаар + бүртгэлийн бүлэг** хослолоор нэг мөр болгон нэгтгэнэ. `Remaining Amount` болон LCY дүн хоёулаа 0 бичилтийг алгасна (иймд хаагдсан бичилтүүд орохгүй). Тэмдэг нь BC-ийн Employee Ledger-ийн дүрмээр.

> **Тэмдэглэл (шүүлтүүр):** Код ямар нэг шүүлтүүр уншдаггүй — үргэлж бүх ажилтны нээлттэй үлдэгдлийг буцаана. Өгөгдөл байхгүй бол хоосон массив буцна. Хариунд `entryNo` талбар гарахгүй.

**Жишээ хариу:**
```json
{
  "value": [
    {
      "employeeNo": "EMP001",
      "employeePostingGroup": "ADVANCE",
      "employeePostingGroupDescription": "Ажилтны урьдчилгаа",
      "totalRemainingAmount": 500000,
      "totalRemainingAmountLCY": 500000
    },
    {
      "employeeNo": "EMP001",
      "employeePostingGroup": "SALARY",
      "employeePostingGroupDescription": "Цалингийн өглөг",
      "totalRemainingAmount": -1200000,
      "totalRemainingAmountLCY": -1200000
    }
  ]
}
```

---

## 4. POST API-ууд (Бичилт)

### 4.1 Entity Creation — Ажилтан үүсгэх / шинэчлэх / идэвхгүй болгох

**Endpoint:**
```
POST /entityCreations
```

**Зориулалт:** Зөвхөн **Ажилтан (Employee)** бүртгэлийг `syncId`-аар үүсгэх (`status = 1`), шинэчлэх (`status = 2`), идэвхгүй болгох (`status = 3`). Ажилтны банкны мэдээлэл (`bankAccountNo`, `bankCode`, `bankAccountName`) болон `COST CENTER`, `BRANCH` default dimension-ийг мөн энэ API-аар бичнэ. **Vendor, Customer үүсгэхгүй/өөрчлөхгүй** (codeunit-д `CreateVendor`, `CreateCustomer`, `UpdateVendor`… процедурууд байгаа ч хаанаас ч дуудагддаггүй).

Эх код: `Page/83000 Entity Creation API.al`, `Codeunit/83000 Entity Creation Management.al`, `Table/83000 Entity Creation Buffer.al`

**Хүсэлтийн талбарууд:**

| Талбар | Төрөл | Заавал | BC талбар | Тайлбар |
|--------|-------|--------|-----------|---------|
| syncId | Text(30) | **Тийм** | Employee → `No.` | Хоосон бол алдаа. Ажилтны дугаар болж бичигдэнэ (Code[20] → том үсэг болно; **20 тэмдэгтээс урт бол BC уртын алдаа өгнө**). 30-аас урт утгыг page таслана |
| status | Integer | **Тийм** | — | `1` = үүсгэх, `2` = шинэчлэх, `3` = идэвхгүй болгох. Өөр утга (илгээгээгүй бол 0) → алдаа |
| firstName | Text(30) | Үгүй* | Employee → `First Name` | 30 тэмдэгтээр таслагдана |
| lastName | Text(30) | Үгүй* | Employee → `Last Name` | 30 тэмдэгтээр таслагдана |
| jobTitle | Text(30) | Үгүй | Employee → `Job Title` | 30 тэмдэгтээр таслагдана |
| registerNo | Text(30) | Үгүй | — | Хүлээн авч API лог-д бичигдэнэ, **Employee-д бичигдэхгүй** |
| costCenter | Code(20) | Үгүй | Default Dimension `COST CENTER` (Table = Employee) | Хоосон бол default dimension устгагдана. Бүртгэлгүй dimension value бол чимээгүй алгасна |
| branch | Code(20) | Үгүй | Default Dimension `BRANCH` (Table = Employee) | `costCenter`-тэй ижил дүрэм |
| bankAccountNo | Text(30) | Үгүй | Employee → `Bank Account No.` (стандарт) | 30 тэмдэгтээр таслагдана |
| bankCode | Code(10) | Үгүй | Employee → `EM CG Bank Code` (EM.BC.Core.CG) | 10-аас урт бол BC уртын алдаа |
| bankAccountName | Text(100) | Үгүй | Employee → `EM CG Bank Account Name` (EM.BC.Core.CG) | 100 (мөн Employee талбарын урт) хүртэл таслагдана |

\* `firstName`, `lastName`-ийг код шалгадаггүй. Гэхдээ `status = 2` үед хоосон илгээвэл одоогийн утгыг хоосолно.

**Хариуны (зөвхөн унших) талбарууд:**

| Талбар | Төрөл | Тайлбар |
|--------|-------|---------|
| entryNo | Integer | Түр buffer-ийн дугаар (утга нь бизнесийн ач холбогдолгүй) |
| employeeNo | Code(20) | `status 1/2`: ажилтны дугаар. `status 3`: `<дугаар>-INACTIVE` |
| vendorNo | Code(20) | **`employeeNo`-той яг ижил утга** (Vendor үүсгэдэггүй) |
| customerNo | Code(20) | **`employeeNo`-той яг ижил утга** (Customer үүсгэдэггүй) |
| createdEntityNo | Code(500) | `Created: EMP=…, VEND=…, CUST=…` / `Updated: …` / `Inactivated: …` хэлбэрийн текст. Code төрөл тул **том үсгээр** буцна (`CREATED: EMP=AD00002, …`) |

**Codeunit-ийн үйлдэл status тус бүрээр:**

| status | Үйлдэл |
|--------|--------|
| 1 | `Employee.Get(syncId)` олдвол алдаа. Үгүй бол Employee үүсгэнэ: `No.`, `First Name`, `Last Name`, `Job Title`, **`Employee Posting Group = '12210000'` (хатуу кодлогдсон)**, `Allow Multiple Posting Groups = true`, `Status = Active`, банкны 3 талбар. Дараа нь `COST CENTER`, `BRANCH` default dimension бичнэ |
| 2 | Ажилтан олдохгүй бол алдаа. `First Name`, `Last Name`, `Job Title`, банкны 3 талбарыг **ирсэн утгаар нь (хоосон ч гэсэн) дарж бичнэ**, dimension-уудыг шинэчилнэ/устгана |
| 3 | Ажилтан олдохгүй бол алдаа. Зөвхөн `Status = Inactive` болгоно (нэр, банк, dimension өөрчлөхгүй). `employeeNo` = `<дугаар>-INACTIVE` |

**Жишээ хүсэлт (status = 1):**
```json
{
  "syncId": "AD00002",
  "firstName": "Яндаг",
  "lastName": "Нямтогтох",
  "jobTitle": "Нягтлан",
  "registerNo": "УА98765432",
  "status": 1,
  "costCenter": "CC001",
  "branch": "BR001",
  "bankAccountNo": "MN520004000495049969",
  "bankCode": "040000",
  "bankAccountName": "Нямтогтох Яндаг"
}
```

**Жишээ хариу (status = 1):**
```json
{
  "syncId": "AD00002",
  "firstName": "Яндаг",
  "lastName": "Нямтогтох",
  "jobTitle": "Нягтлан",
  "registerNo": "УА98765432",
  "status": 1,
  "employeeNo": "AD00002",
  "vendorNo": "AD00002",
  "customerNo": "AD00002",
  "createdEntityNo": "CREATED: EMP=AD00002, VEND=AD00002, CUST=AD00002",
  "costCenter": "CC001",
  "branch": "BR001",
  "bankAccountNo": "MN520004000495049969",
  "bankCode": "040000",
  "bankAccountName": "Нямтогтох Яндаг"
}
```

**Жишээ хариу (status = 3):**
```json
{
  "syncId": "AD00002",
  "status": 3,
  "employeeNo": "AD00002-INACTIVE",
  "vendorNo": "AD00002-INACTIVE",
  "customerNo": "AD00002-INACTIVE",
  "createdEntityNo": "INACTIVATED: EMP=AD00002-INACTIVE, VEND=AD00002-INACTIVE, CUST=AD00002-INACTIVE"
}
```

**Алдааны мессеж:** (бүгд `Error()`-оор шидэгдэж HTTP алдаа буцна; API лог-д commit хийгдэнэ)

| Алдаа | Шалтгаан |
|-------|----------|
| `Sync ID is required and cannot be null or zero.` | `syncId` хоосон |
| `Employee {No} already exists. Cannot create duplicate.` | `status = 1`, ажилтан бүртгэлтэй |
| `Employee {No} not found. Cannot update.` | `status = 2`, ажилтан олдсонгүй |
| `Employee {No} not found. Cannot inactivate.` | `status = 3`, ажилтан олдсонгүй |
| `Invalid status. Use 1 for Create, 2 for Update, 3 for Inactivate.` | `status` нь 1, 2, 3-аас өөр |
| BC-ийн стандарт validation/уртын алдаа | `bankCode`-ийн `EM CG Bank Code` талбарын validation (EM.BC.Core.CG-д тодорхойлогдсон), `syncId` > 20 тэмдэгт, `bankCode` > 10 тэмдэгт гэх мэт |

> **Тэмдэглэл:**
> - **Банкны талбар:** `SetEmployeeBankInfo` нь `Validate("Bank Account No.")`, `Validate("EM CG Bank Code")`, `Validate("EM CG Bank Account Name")`-ийг **шууд** дуудна (commit `10544410` "refactor: write employee bank fields directly, no Core.CG code changes"). Анхны `4c20d861` commit-д байсан `CG Employee Bank` codeunit-ийн дуудлага болон `Bank code %1 does not exist. Cannot set employee bank information.` гэсэн тусгай шалгалт **устгагдсан**. Иймд бүртгэлгүй `bankCode`-ийн алдаа нь зөвхөн Core.CG талбарын өөрийн validation (TableRelation байгаа бол)-оор гарна — энэ repo-оос баталгаажуулах боломжгүй.
> - **Хоосон утга (`status = 2`):** нэр, албан тушаал, банкны 3 талбар хоосон утгаар дарагдана; `costCenter`/`branch` хоосон бол тухайн default dimension **устгагдана**. Иймд шинэчлэх хүсэлтэд бүх талбарыг бүтнээр нь илгээнэ.
> - **Dimension:** dimension code нь хатуу `'COST CENTER'`, `'BRANCH'`. `Dimension Value` бүртгэлгүй бол алдаа өгөхгүй, одоогийн default dimension хэвээр үлдэнэ.
> - **`status = 3`:** `employeeNo` нь `Code[20]` тул `syncId` 11 тэмдэгтээс урт бол `"-INACTIVE"` залгахад урт хэтэрч BC алдаа гарна.
> - **Enum:** `BC Employee Status` (83001), `Employee Type` (83005) enum-ууд энэ API-д **ашиглагдахгүй**; идэвхгүй болгохдоо BC стандарт `Employee.Status::Inactive`-ийг ашиглана.
> - **Эрх:** Employee хүснэгтэд унших эрхгүй бол codeunit бодит бичлэг үүсгэлгүйгээр дугаар (`…-UPD`, `…-INACTIVE`) буцаана.
> - **API лог:** `Entity Creation API` нэрээр лог эхлүүлж шууд commit хийнэ; амжилттай бол `Entity created successfully` (status 2, 3-т ч ижил мессеж).

---

### 4.2 FA Movement — ҮХ шилжүүлэг

**Endpoint:**
```
POST /faMovements
```

**Зориулалт:** Үндсэн хөрөнгийн байршил, хариуцагч, бүртгэлийн бүлэг, shortcut dimension 1–6-ийн өөрчлөлтийг **EM.BC.FA.Movement өргөтгөлийн ноорог баримт** (`FA Movement Header` Document Type = Standard + `FA Movement Line`) болгон үүсгэх. Энэ API **Fixed Asset картыг шууд өөрчлөхгүй** — өөрчлөлт тухайн FA Movement баримтыг EM.BC.FA.Movement-д боловсруулах (post хийх) үед хийгдэнэ.

Эх код: `Page/83011 FA Movement API.al`, `Codeunit/83008 FA Movement Management.al`, `Table/83014 FA Movement Buffer.al`, `Table/83017 FA Movement Line Buffer.al`

**Хүсэлтийн талбарууд (header):**

| Талбар | Төрөл | Заавал | Тайлбар |
|--------|-------|--------|---------|
| userID | Code(50) | **Тийм** | Хоосон бол алдаа. Зөвхөн шалгагдана, баримтад бичигдэхгүй |
| changedDate | Date | **Тийм** | `FA Movement Header/Line → Movement Date` |
| documentNo | Code(20) | **Тийм** | `FA Movement Header → No.` болон `External Document No.`. Ижил дугаартай Standard header байвал **шинэ мөрүүд түүн рүү нэмэгдэнэ** |
| linesJson | Text (JSON массив **тэмдэгт мөр** хэлбэрээр) | **Тийм** | Мөрүүдийн JSON массив. Хоосон бол алдаа |
| fixedAssetNo | Code(20) | Үгүй | Header-т ил гарсан ч **боловсруулалтад ашиглагдахгүй** (мөр бүрийн `fixedAssetNo`-г ашиглана) |

> `FA Movement API` page-д `faMovementLines` гэсэн navigation part **байхгүй**. Мөрүүдийг зөвхөн `linesJson` талбараар string хэлбэрээр илгээнэ. `Page/83013 FA Movement Lines API Part` нь `faMovements` page-д холбогдоогүй.

**`linesJson` доторх мөрийн талбарууд:**

| Талбар | Төрөл | Заавал | FA Movement Line талбар | Тайлбар |
|--------|-------|--------|-------------------------|---------|
| fixedAssetNo | Code(20) | **Тийм** | `Fixed Asset No.` | Fixed Asset бүртгэлтэй байх ёстой |
| comment | Text(100) | Үгүй | `Comment` | `Doc: {documentNo} - {comment}` хэлбэрээр бичигдэнэ (comment хоосон бол `Doc: {documentNo}`) |
| newLocationCode | Code(20) | Үгүй** | `New Location Code` | `FA Location`-д бүртгэлтэй байх ёстой |
| newResponsibleEmployee | Code(20) | Үгүй** | `New Responsible Employee` | Employee бүртгэлтэй байх ёстой. Мөн тухайн ажилтны `Global Dimension 2 Code` → `New Default Dimension` |
| newPostingGroup | Code(20) | Үгүй** | `New Posting Group` | `FA Posting Group`-д бүртгэлтэй байх ёстой. Өгөөгүй бол ҮХ-ийн одоогийн бүлэг |
| dimension1CostCenter | Code(20) | Үгүй** | `Shortcut Dimension 1 Code` | |
| dimension2ProductCode | Code(20) | Үгүй** | `Shortcut Dimension 2 Code` | |
| dimension3CashFlow | Code(20) | Үгүй** | `Shortcut Dimension 3 Code` | |
| dimension4DepartmentCode | Code(20) | Үгүй** | `Shortcut Dimension 4 Code` | |
| dimension5Field | Code(20) | Үгүй** | `Shortcut Dimension 5 Code` | |
| dimension6AssetCode | Code(20) | Үгүй** | `Shortcut Dimension 6 Code` | |

\*\* Мөр бүрт `newLocationCode`, `newResponsibleEmployee`, `newPostingGroup`, `dimension1…6`-аас **дор хаяж нэг** нь заавал байна.

Автоматаар бөглөгдөх "хуучин" утгууд (Fixed Asset картаас): `Old Location Code` ← `FA Location Code`, `Old Responsible Employee` ← `Responsible Employee`, `Old Posting Group` ← `FA Posting Group`, `Old Shortcut Dimension 1/2 Code` ← `Global Dimension 1/2 Code`, `Current Dimension` ← хуучин хариуцагчийн `Global Dimension 2 Code`.

**Жишээ хүсэлт:**
```json
{
  "userID": "ADMIN",
  "changedDate": "2024-12-01",
  "documentNo": "FA-MOV-001",
  "linesJson": "[{\"fixedAssetNo\":\"FA000010\",\"newLocationCode\":\"OFFICE-02\",\"newResponsibleEmployee\":\"EMP002\",\"comment\":\"Шилжүүлэг хийв\",\"dimension1CostCenter\":\"CC002\"},{\"fixedAssetNo\":\"FA000011\",\"newLocationCode\":\"WAREHOUSE\",\"comment\":\"Агуулахад шилжүүлэв\"}]"
}
```

**Жишээ хариу (амжилттай):**
```json
{
  "id": "…guid…",
  "userID": "ADMIN",
  "fixedAssetNo": "",
  "changedDate": "2024-12-01",
  "documentNo": "FA-MOV-001",
  "linesJson": "[…]",
  "linesProcessed": 2,
  "success": true,
  "errorMessage": ""
}
```

**Жишээ хариу (шалгалтын алдаа):**
```json
{
  "documentNo": "FA-MOV-001",
  "linesProcessed": 0,
  "success": false,
  "errorMessage": "All 1 line(s) failed: Line 2 (FA000011): Location Code WAREHOUSE does not exist. | "
}
```

**Алдааны мессеж:** (`errorMessage` талбарт буцна, `success = false`; HTTP хүсэлт өөрөө амжилттай дуусна)

| Алдаа | Шалтгаан |
|-------|----------|
| `User ID is required` | `userID` хоосон |
| `Changed Date is required` | `changedDate` хоосон |
| `Document No. is required` | `documentNo` хоосон |
| `faMovementLines is required. Send a JSON array of line objects.` | `linesJson` хоосон (мессеж дээрх нэр `faMovementLines` боловч бодит талбар нь `linesJson`) |
| `All 1 line(s) failed: Invalid JSON array format for faMovementLines.` | `linesJson` JSON массив биш |
| `Fixed Asset No. is required.` | Мөрийн `fixedAssetNo` хоосон |
| `Fixed Asset {No} does not exist.` | ҮХ олдсонгүй |
| `At least one change must be specified for Fixed Asset {No}.` | Мөрт өөрчлөх талбар алга |
| `Location Code {Code} does not exist.` | `FA Location` олдсонгүй |
| `Employee {No} does not exist.` | Хариуцагч ажилтан олдсонгүй |
| `FA Posting Group {Code} does not exist.` | FA Posting Group олдсонгүй |
| `All {N} line(s) failed: Line {i} ({FA}): {алдаа} \| …` | Шалгалтад унасан мөрийн тоо N (бусад мөр ч бичигдэхгүй) |
| `Partial: {X} succeeded, {Y} failed: …` | Шалгалт давсны дараа `FA Movement Line` insert үед зарим мөр унасан |

> **Тэмдэглэл:**
> - **Хоёр үе шат:** (1) Бүх мөрийг санах ойд задлан шалгана — **аль нэг мөр алдаатай бол нэг ч баримт үүсэхгүй** (header ч үүсэхгүй). (2) Бүгд зөв бол header (байхгүй бол) үүсгээд мөрүүдийг `Line No.` = сүүлийн + 10000 алхмаар нэмнэ.
> - Шинээр үүсгэх header: `No. Series = ''`, `Description = 'FA Movement via API'`, `External Document No. = documentNo`.
> - **Dimension:** `dimension1…6` нь FA Movement Line-ийн `Shortcut Dimension 1…6 Code`-д шууд (Validate-гүй) оноогдоно; бодит dimension code нь General Ledger Setup-ийн shortcut dimension тохиргооноос хамаарна (кодонд хатуу dimension code байхгүй). Dimension value-г энэ codeunit шалгахгүй.
> - `linesProcessed` = амжилттай insert хийгдсэн мөрийн тоо.
> - API лог: page нээгдэхэд `{"action": "FA Movement Request Initiated"}`-ээр, insert үед бүрэн хүсэлтээр `StartAPILogging` дуудагдана; амжилттай бол `FA Movement created successfully. {N} line(s) processed.`

---

### 4.3 Gen Journal Import — Ерөнхий журнал импорт

**Endpoint:**
```
POST /genJournalImports
```

**Зориулалт:** Ерөнхий журналд (`Gen. Journal Line`) **нэг хүсэлтээр нэг мөр** оруулах. Боловсруулалт **тухайн хүсэлт дотор шууд (synchronous)** хийгдэнэ — Job Queue / `Journal Background Processor` ашиглахгүй. Журналыг **post хийхгүй**, зөвхөн мөр үүсгэнэ.

Эх код: `Page/83012 Gen Journal Import API.al`, `Codeunit/83010 Gen Journal Import Management.al`, `Table/83016 Gen Journal Import Buffer.al`

**Хүсэлтийн талбарууд:**

| Талбар | Төрөл | Заавал | Тайлбар |
|--------|-------|--------|---------|
| batchID | Text(100) | Үгүй | Хоосон бол GUID үүсгэнэ. Зөвхөн buffer доторх бүлэглэл ба лог-д ашиглагдана |
| journalTemplateName | Code(10) | Үгүй | Хоосон бол `Type = General` бүхий **эхний** template. Өгсөн бол оршин байх ёстой |
| journalBatchName | Code(10) | Үгүй | Хоосон бол тухайн template-ийн **эхний** batch. Өгсөн бол оршин байх ёстой |
| lineNo | Integer | Үгүй | **Ашиглагдахгүй.** Журналын мөрийн дугаарыг batch-ийн сүүлийн мөр + 10000 гэж тооцно (`createdLineNo`-д буцна) |
| postingDate | Date | **Тийм** | `Posting Date` |
| documentDate | Date | Үгүй | Хоосон бол `postingDate` |
| documentType | Option | Үгүй | `" "`, `Payment`, `Invoice`, `Credit Memo`, `Finance Charge Memo`, `Reminder`, `Refund` (дарааллын дугаараар `Gen. Journal Document Type` руу хөрвүүлнэ) |
| documentNo | Code(20) | **Тийм** | `Document No.` |
| accountType | Option | Үгүй (анхдагч `G/L Account`) | `G/L Account`, `Customer`, `Vendor`, `Bank Account`, `Fixed Asset`, `IC Partner`, `Employee` |
| accountNo | Code(20) | **Тийм** | `Validate("Account No.")` |
| description | Text(100) | Үгүй | `Description`-д **үргэлж** дарж бичнэ (хоосон бол хоосон) |
| description2 | Text(50) | Үгүй | Хүлээн авна, **журналд бичигдэхгүй** |
| currencyCode | Code(10) | Үгүй | Өгсөн бол `Validate("Currency Code")` |
| amount | Decimal | Нөхцөлт*** | Дебит/кредит хоёулаа 0 үед `Validate(Amount)` |
| amountLCY | Decimal | Үгүй | Хүлээн авна, **журналд бичигдэхгүй** |
| debitAmount | Decimal | Нөхцөлт*** | Тэргүүн ээлжинд ашиглагдана |
| creditAmount | Decimal | Нөхцөлт*** | `debitAmount = 0` үед ашиглагдана |
| balAccountType | Option | Үгүй | `accountType`-тэй ижил утгууд. Зөвхөн `balAccountNo` өгсөн үед хэрэглэгдэнэ |
| balAccountNo | Code(20) | Үгүй | `Validate("Bal. Account No.")` |
| externalDocumentNo | Code(35) | Үгүй | `External Document No.` |
| shortcutDimension1Code | Code(20) | Үгүй | `Validate("Shortcut Dimension 1 Code")` |
| shortcutDimension2Code | Code(20) | Үгүй | `Validate("Shortcut Dimension 2 Code")` |
| shortcutDimension3Code…6Code | Code(20) | Үгүй | `ValidateShortcutDimCode(3…6, …)` |
| appliesToDocType | Option | Үгүй | `documentType`-тэй ижил утгууд. Зөвхөн `appliesToDocNo` өгсөн үед |
| appliesToDocNo | Code(20) | Үгүй | `Applies-to Doc. No.` |
| appliesToID | Code(50) | Үгүй | `Applies-to ID` |

\*\*\* `amount`, `debitAmount`, `creditAmount`-аас дор хаяж нэг нь 0 биш байна. Тэргүүлэх дараалал: `debitAmount` → `creditAmount` → `amount` (зөвхөн нэгийг нь ашиглана).

**Хариуны (зөвхөн унших) талбарууд:** `entryNo`, `success` (Boolean), `errorMessage` (Text 250), `createdLineNo` (Integer — үүссэн `Gen. Journal Line`-ийн `Line No.`, алдаатай бол 0). Мөн `journalTemplateName`, `journalBatchName` нь бодит ашигласан утгаар шинэчлэгдэнэ.

**Жишээ хүсэлт:**
```json
{
  "batchID": "BATCH-001",
  "journalTemplateName": "GENERAL",
  "journalBatchName": "DEFAULT",
  "postingDate": "2024-12-01",
  "documentNo": "GJ-001",
  "accountType": "G/L Account",
  "accountNo": "6100",
  "description": "Цахилгааны зардал",
  "debitAmount": 500000,
  "balAccountType": "Bank Account",
  "balAccountNo": "BANK01",
  "shortcutDimension1Code": "BRANCH01"
}
```

**Жишээ хариу:**
```json
{
  "batchID": "BATCH-001",
  "journalTemplateName": "GENERAL",
  "journalBatchName": "DEFAULT",
  "lineNo": 0,
  "postingDate": "2024-12-01",
  "documentNo": "GJ-001",
  "accountNo": "6100",
  "debitAmount": 500000,
  "success": true,
  "errorMessage": "",
  "createdLineNo": 30000
}
```

**Алдааны мессеж:**

| Алдаа | Шалтгаан | Хариунд харагдах байдал |
|-------|----------|------------------------|
| `Posting Date is required.` | `postingDate` хоосон | `success: false`, `errorMessage` |
| `Document No. is required.` | `documentNo` хоосон | `success: false`, `errorMessage` |
| `Account No. is required.` | `accountNo` хоосон | `success: false`, `errorMessage` |
| `Amount, Debit Amount, or Credit Amount is required.` | Гурван дүн бүгд 0 | `success: false`, `errorMessage` |
| `Failed to insert journal line.` | `Gen. Journal Line` insert false буцаасан | `success: false`, `errorMessage` |
| `No General Journal Template found.` | Template хоосон, General template алга | `success: false`, **`errorMessage` хоосон** (алдаа зөвхөн түр buffer-т бичигдэж, API лог-д `Failed to process journal batch`) |
| `Journal Template {Name} does not exist.` | Template олдсонгүй | дээрхтэй адил |
| `No Journal Batch found for template {Name}.` | Batch хоосон, template-д batch алга | дээрхтэй адил |
| `Journal Batch {Name} does not exist.` | Batch олдсонгүй | дээрхтэй адил |
| BC-ийн стандарт validation алдаа | Жишээ нь бүртгэлгүй `accountNo`, `currencyCode`, dimension value | `Validate` нь try-гүй тул **HTTP алдаагаар** бүх хүсэлт буцна |

> **Тэмдэглэл:**
> - **Хариу:** `{ "status": "Completed", "batchID": …, "successCount": …, "errorCount": … }` текст нь **API-ийн хариу биш** — зөвхөн API лог-д (`UpdateAPILogSuccess/Error`) бичигддэг. Клиент нь бичлэгийн `success`, `errorMessage`, `createdLineNo` талбаруудыг уншина.
> - **Боловсруулах цэг:** `OnInsertRecord` зөвхөн `Session ID`, `batchID`-ийг бэлдэнэ; бодит журнал үүсгэлт page-ийн `OnAfterGetRecord` (insert хийсэн бичлэгийг хариунд унших үе)-д `ProcessGenJournalBatch`-ээр нэг удаа хийгдэнэ.
> - **Batch:** buffer нь temporary тул хүсэлт бүрт зөвхөн тухайн нэг мөр байна; олон мөрийг нэг `batchID`-аар нэг дор боловсруулах механизм бодитоор ажиллахгүй — мөр тус бүрийг тусад нь POST хийнэ.
> - **Option утгууд:** `accountType`, `balAccountType`, `documentType`, `appliesToDocType` нь AL Option тул API-д нэрээр нь (тоогоор биш) илгээнэ. Хоосон зай, `/` агуулсан утгуудыг BC OData `$metadata`-д encode хийсэн хэлбэрээр (жнь. `G_x002F_L_x0020_Account`, `Bank_x0020_Account`, `Credit_x0020_Memo`) шаардаж болзошгүй тул `$metadata`-аас шалгана. Option-ийн дарааллын дугаар (0…6) нь `Gen. Journal Account Type` / `Gen. Journal Document Type`-ийн дугаартай шууд тааруулагдана.
> - Template-ийн төрлийг (`General` эсэх) зөвхөн template хоосон үед шалгана.
> - `Journal Background Processor` (83019) болон `Journal Background Processing` page (83035) нь **Sales Lines** (Sales Journal)-ийг боловсруулдаг (Item Journal хэсэг нь comment-лэгдсэн) — Gen Journal Import-тэй холбоогүй.


---

### 4.4 POS Sales — POS борлуулалт

**Endpoint:**
```
POST /posSales
```

| Параметр | Утга |
|----------|------|
| Page | 83030 `POS Sales API` |
| EntityName / EntitySetName | `posSales` / `posSales` |
| SourceTable | 83022 `POS Sales` |
| Мөрийн navigation part | `lines` (EntityName `line`, page 83031 `POS Sales Lines API Part`, `SubPageLink = "Header ID" = field(Id)`) |

**Зориулалт:** POS системийн борлуулалтын баримтыг (толгой + мөрүүд) BC-ийн `POS Sales` / `POS Sales Lines` хүснэгтэд **Status = New** төлөвтэйгөөр хадгална. **Sales Order энэ дуудлагаар шууд үүсэхгүй** — Job Queue-ээр ажилладаг `POS Sales Background Processor` (codeunit 83017) дараа нь үүсгэнэ (доорх "Боловсруулалтын урсгал"-ыг үз).

**Толгойн талбарууд:**

| Талбар | Төрөл | Заавал | Тайлбар |
|--------|-------|--------|---------|
| id | Integer | — (read-only) | AutoIncrement дотоод ID (`POS Sales.Id`) |
| posDocumentNo | Code[20] | Тийм | POS баримтын дугаар. `NotBlank`; давхардлыг шалгана (доор) |
| posTxnDate | DateTime | Үгүй* | Борлуулалтын огноо цаг. Sales Order-ийн Posting/Document/Order Date болон `External Document No.`-д ашиглагдана |
| location | Code[10] | Үгүй | Байршлын код (`Location` хүснэгттэй TableRelation). Хоосон бол Sync Integration Setup → `POS Default Location Code` |
| totalAmount | Decimal | Үгүй | Нийт дүн (зөвхөн хадгална) |
| vatAmount | Decimal | Үгүй | НӨАТ (зөвхөн хадгална) |
| cityTaxAmount | Decimal | Үгүй | Хотын татвар (зөвхөн хадгална) |
| lines | Array | Үгүй* | Мөрүүд (deep insert) |
| status | Option | — (read-only) | Толгойн төлөв (доорх хүснэгт) |
| linesCreated | Integer | — (read-only) | Тухайн толгойд холбогдсон мөрийн тоо (`OnAfterGetRecord`-д тоолно) |
| createdAt | DateTime | — (read-only) | Бүртгэсэн огноо цаг (`CurrentDateTime()`) |

\* Кодонд заавал гэж шалгадаггүй, гэхдээ мөргүй болон огноогүй баримтаас Sales Order үүсэхгүй/буруу огноотой үүснэ.

> **Тэмдэглэл:** `customerNo`, `userId`, `ebddtd`, `ebDate`, `ebReceiptType`, `ebReturnDate` талбарууд page дээр **comment-оор хаагдсан** тул API-аар илгээх боломжгүй. Харилцагч үргэлж Sync Integration Setup → `POS Default Customer No.`-оос авагдана. `sessionId` талбар dev салбарын кодонд **байхгүй**.

**Мөрийн талбарууд (`lines`):**

| Талбар | Төрөл | Заавал | Тайлбар |
|--------|-------|--------|---------|
| id | Guid | — (read-only) | `SystemId` (ODataKeyFields) |
| HeaderId | Integer | Үгүй | Толгойн ID — `SubPageLink`-ээр автоматаар бөглөгдөнө (API нэр том `H`-ээр эхэлдэг) |
| lineNo | Integer | Үгүй | Мөрийн дугаар. 0 эсвэл тухайн толгойд аль хэдийн байгаа бол автоматаар үүсгэнэ (2020-01-01-ээс хойшх секунд + тоолуур) |
| itemNo | Code[20] | Тийм | Барааны дугаар (`Item` TableRelation) |
| lotNumber | Code[50] | Үгүй | Lot дугаар (доорх Lot-ын дүрмийг үз) |
| quantity | Decimal | Тийм | Тоо хэмжээ |
| unitOfMeasureCode | Code[10] | Үгүй | Хэмжих нэгж (`Unit of Measure` TableRelation). Хоосон бол барааны суурь нэгж |
| unitPrice | Decimal | Тийм | Нэгжийн үнэ — Sales Line-ийн `Unit Price` болно |
| lineAmount | Decimal | Үгүй | Мөрийн дүн (хадгална) |
| vatAmount | Decimal | Үгүй | НӨАТ (хадгална) |
| cityTaxAmount | Decimal | Үгүй | Хотын татвар (хадгална) |
| status | Enum `POS Sales Line Status` | — (read-only) | `New` / `Processed` / `Returned` |
| errorMessage | Text[2000] | — (read-only) | SO үүсгэх үеийн мөрийн алдаа |

**Жишээ хүсэлт:**
```json
{
  "posDocumentNo": "POS-20241201-001",
  "posTxnDate": "2024-12-01T14:30:00Z",
  "location": "OUT",
  "totalAmount": 75000,
  "vatAmount": 7500,
  "cityTaxAmount": 750,
  "lines": [
    {
      "lineNo": 10000,
      "itemNo": "ITEM001",
      "lotNumber": "LOT001",
      "quantity": 2,
      "unitOfMeasureCode": "KG",
      "unitPrice": 25000,
      "lineAmount": 50000,
      "vatAmount": 5000,
      "cityTaxAmount": 500
    },
    {
      "lineNo": 20000,
      "itemNo": "ITEM002",
      "quantity": 1,
      "unitPrice": 25000,
      "lineAmount": 25000,
      "vatAmount": 2500,
      "cityTaxAmount": 250
    }
  ]
}
```

**Жишээ хариу** (page-ийн талбаруудаас бүрдэнэ; `lines`-ийг `$expand=lines`-ээр авна):
```json
{
  "id": 1234,
  "posDocumentNo": "POS-20241201-001",
  "posTxnDate": "2024-12-01T14:30:00Z",
  "location": "OUT",
  "totalAmount": 75000,
  "vatAmount": 7500,
  "cityTaxAmount": 750,
  "status": "New",
  "linesCreated": 2,
  "createdAt": "2024-12-01T14:30:05Z"
}
```

> **Тэмдэглэл:** API Log-д бичигддэг `{"status":"Success","message":"POS Sales ... created with N line(s). Status: New","posId":..,"posDocumentNo":..,"linesCount":..,"soNumber":..,"createdAt":..}` бүтэц нь зөвхөн **API Log Entry**-ийн response body (codeunit 83015 `OnAfterInsertPOSSalesLine`) бөгөөд HTTP хариу биш.

**Давхардлын шалгалт:**

`posDocumentNo` ижил **ямар ч төлөвтэй** (New, SO Generated, Returned …) `POS Sales` бичлэг байвал баримтыг хүлээж авахгүй, HTTP алдаа буцаана. Хоёр түвшинд шалгана:
1. API page `OnInsertRecord` — `POS Document No. %1 already exists (ID: %2).` (API Log-д Error гэж бичнэ)
2. Хүснэгтийн `OnInsert` — `POS Document No. %1 already exists.`

**Боловсруулалтын урсгал:**

1. **POST үед:** толгой `Status = New`, `Created At` бөглөгдөнө; `Customer No.` хоосон тул `POS Default Customer No.`, `location` хоосон бол `POS Default Location Code` тавигдана. Мөр бүр `Status = New`-ээр хадгалагдана. Sales Order үүсгэхгүй.
2. **Цагийн бүс:** `posTxnDate`-ийн `OnValidate` нь `CurrentClientType() = ClientType::ODataV4` үед утгаас 8 цаг хасдаг (кодын тайлбар: UTC+8).
3. **Background processor** (codeunit 83017, `POS Sales Background Setup` page → *Create Job Queue Entry* нь 1 минут тутам ажиллах Job Queue үүсгэнэ):
   - Sync Integration Setup → `POS Is Generate SO` = false бол юу ч хийхгүй.
   - `POS SO Processing` flag-аар зэрэг ажиллахаас сэргийлнэ (15 минутын timeout).
   - `Status = New` бөгөөд мөртэй бүх `POS Sales`-ийг `CreateSalesOrderFromPOS`-оор боловсруулж, баримт бүрийн дараа `Commit()` хийнэ.
4. **Sales Order үүсгэх дүрэм** (codeunit 83014):
   - `External Document No.` = `'POS' + YYMMDD` (`posTxnDate`-ээс).
   - Ижил харилцагч + ижил External Document No. + ижил Order Date + `Status = Open` Sales Order байвал **тэр SO-д нэмнэ**, үгүй бол шинээр үүсгэнэ (Location, Posting/Document/Order Date = `posTxnDate`-ийн огноо).
   - Зөвхөн `Status = New` мөрүүдийг авна. Мөр бүрийн бараа/хэмжих нэгжийг шалгана (бараа байхгүй, blocked, эсвэл UOM тухайн бараанд бүртгэлгүй бол алдаа).
   - SO дээр ижил бараа + ижил `Unit Price` (+ UOM өгсөн бол ижил UOM) мөр байвал **тоо хэмжээг нэмж нэгтгэнэ**, үгүй бол шинэ мөр (`Qty. to Ship`, `Qty. to Invoice` = тоо хэмжээ).
   - Амжилттай мөр → `Processed`; алдаатай мөр `New` хэвээр, `errorMessage`-д алдаа бичигдэнэ.
   - Толгойн `SO Number` бөглөгдөж, төлөв: бүх мөр Processed → `SOGenerated`; зарим нь → `PartialSOGenerated`; нэг ч амжилтгүй → `New` (дараагийн ажиллалтаар дахин оролдоно).
5. **Lot-ын дүрэм** (зөвхөн `Lot Specific Tracking` идэвхтэй бараанд):
   - `lotNumber` өгсөн бөгөөд тухайн бараа + байршилд Item Ledger Entry-д бүртгэлтэй бол түүнийг ашиглана.
   - Өгөөгүй эсвэл бүртгэлгүй бол: `POS Use FEFO for Untracked Lot` = true үед хамгийн эрт дуусах хугацаатай, үлдэгдэлтэй (`Remaining Quantity > 0`) lot-ыг (FEFO) сонгоно; false үед lot хоосон үлдэнэ.
   - Lot нь `Prospect` төлөвтэй Reservation Entry болж Sales Line-д холбогдоно. Мөр нэгтгэх үед хуучин reservation устгагдаж, нийт тоогоор дахин үүснэ.

**Төлөвүүд:**

| Түвшин | Утга (AL / caption) | Утга |
|--------|--------------------|------|
| Толгой | `New` | Хүлээн авсан, SO үүсээгүй (эсвэл бүх мөр алдаатай) |
| Толгой | `Cancelled` / `EB Done` | Option-д тодорхойлогдсон; энэ API-ийн кодонд тавигддаггүй |
| Толгой | `SOGenerated` / `SO Generated` | Бүх мөр SO-д орсон |
| Толгой | `PartialSOGenerated` / `Partial SO Generated` | Зарим мөр SO-д орсон |
| Толгой | `Returned` | Буцаалт хүлээн авсан (4.5) |
| Толгой | `SOReturned` / `SO Returned` | Бүх мөр буцаагдсан (4.5) |
| Мөр | `New` | Боловсруулаагүй |
| Мөр | `Processed` | SO-д орсон |
| Мөр | `Returned` | Буцаагдсан |

**Алдааны мессеж:**

| Алдаа | Хаана | Шалтгаан |
|-------|-------|----------|
| `POS Document No. %1 already exists (ID: %2).` | HTTP хариу | Ижил `posDocumentNo` бүртгэлтэй |
| `POS Document No. %1 already exists.` | HTTP хариу | Хүснэгтийн түвшний давхардал |
| `Invalid UOM: %1 for Item: %2` | мөрийн `errorMessage` | Бараа олдсонгүй / blocked / UOM бүртгэлгүй |
| BC-ийн системийн алдааны текст | мөрийн `errorMessage` | Sales Line үүсгэх үеийн бусад алдаа |
| `No unprocessed lines found for POS Document %1` | Background (log хийгдэхгүй) | `New` мөр алга |

> **Тэмдэглэл:** POS Sales List (page 83032)-ээс *Create Sales Order*, *Process All Pending Sales*, *Check POS Sales Status* (мөрийн төлөвөөр толгойн төлөвийг засах) үйлдлүүдийг гараар ажиллуулж болно.

---

### 4.5 POS Sales Return — POS буцаалт

**Endpoint:**
```
POST /posSalesReturn
```

| Параметр | Утга |
|----------|------|
| Page | 83036 `POS Sales Return API` |
| EntityName / EntitySetName | `posSalesReturn` / `posSalesReturn` |
| SourceTable | 83022 `POS Sales` (**temporary**) |

**Зориулалт:** Өмнө бүртгэгдсэн POS борлуулалтыг `posDocumentNo`-оор нь олж `Returned` төлөвт оруулах ба Sync Integration Setup-аас хамааран **Sales Return Order үүсгэх** эсвэл **холбогдох Sales Order-оос тоо хэмжээг хасна**. Буцаалт нь баримтын бүх `Processed` мөрийг бүхэлд нь буцаана (мөрөөр сонгох боломжгүй).

**Хүсэлтийн талбарууд:**

| Талбар | Төрөл | Заавал | Тайлбар |
|--------|-------|--------|---------|
| posDocumentNo | Code[20] | Тийм | Буцаах POS баримтын дугаар |
| status | Option | — (read-only) | Буцаалтын дараах толгойн төлөв |
| message | Text | — (read-only) | Үр дүнгийн мессеж |

**Жишээ хүсэлт:**
```json
{
  "posDocumentNo": "POS-20241201-001"
}
```

**Жишээ хариу (амжилттай):**
```json
{
  "posDocumentNo": "POS-20241201-001",
  "status": "SOReturned",
  "message": "POS Sales POS-20241201-001 status updated to Returned and Sales Return Order SRO000123 created"
}
```

**Жишээ хариу (SR/SO боловсруулалт амжилтгүй — HTTP алдаа биш):**
```json
{
  "posDocumentNo": "POS-20241201-001",
  "status": "Returned",
  "message": "Failed to create Sales Return Order: POS Sales does not have an associated Sales Order"
}
```

**Боловсруулалтын урсгал:**

1. `posDocumentNo` хоосон бол алдаа.
2. `POS Sales`-ийг **зөвхөн `POS Document No.`-оор** хайна (`FindFirst`). Одоогийн төлөвийг шалгадаггүй.
3. Олдсон бичлэгийн `Status := Returned`, `EBReturnDate := Format(CurrentDateTime())` болгож хадгална.
4. `CreateSalesReturnFromPOS` (codeunit 83014):
   - `POS Is Generate SO` = false бол юу ч хийхгүй (хоосон дугаар буцаана) — мессеж амжилттай гэж гарна.
   - **`POS Is Return Order Generate` = false (setup-ийн анхны утга)** бол `SubtractFromSalesOrder`: толгойн `SO Number`-той, `Open` Sales Order-оос `Processed` мөр бүрийн тоог (ижил бараа + Unit Price + UOM мөрөөс) хасна; lot reservation-уудыг FEFO дарааллаар багасгана; тоо 0 болсон мөрийг устгана. Энэ үед мессеж дэх "Sales Return Order %2" нь үнэндээ **SO дугаар** байна.
   - `POS Is Return Order Generate` = true бол Sales **Return Order** үүсгэнэ: ижил харилцагч + `'POS' + YYMMDD` External Document No. + ижил Document Date + `Open` Return Order байвал түүнд нэмнэ; `Processed` мөрүүдийг ижил бараа/үнэ/UOM-аар нэгтгэж `Return Qty. to Receive`-тэй мөр үүсгэнэ; lot-ыг 4.4-ийн дүрмээр онооно. `SR Number` бөглөгдөнө.
   - Амжилттай мөр → `Returned`; толгой: бүх мөр буцсан → `SOReturned`, үгүй бол `Returned`.
5. Алхам 4 алдаа өгвөл (TryFunction) HTTP амжилттай буцааж, `message`-д `Failed to create Sales Return Order: ...` бичнэ; толгой `Returned` төлөвт үлдэнэ.

> **Тэмдэглэл (огнооны цонх):** `OnOpenPage` нь page-ийн **түр (temporary) Rec** дээр `POS TxnDate`-ийг өчигдрийн 00:00:00 – өнөөдрийн 23:59:59 (`Today()` — серверийн/хэрэглэгчийн цагаар, тодорхой цагийн бүс заагаагүй) хооронд шүүдэг. Харин буцаах бичлэгийг хайхдаа энэ шүүлтүүрийг **хэрэглэдэггүй** (`POSSales.SetRange("POS Document No.", ...)` л байна) тул кодонд "зөвхөн өчигдөр/өнөөдрийн борлуулалт" гэсэн хязгаарлалт бодитоор шалгагддаггүй.

> **Тэмдэглэл:** Төлөв шалгадаггүй тул `New` (SO үүсээгүй) баримтыг буцаавал `Returned` болж, background processor дахин авахгүй. Аль хэдийн буцаагдсан баримтыг дахин илгээвэл `Processed` мөр байхгүй тул `No processed lines found for POS Document %1` алдаа `message`-д гарна.

**Алдааны мессеж:**

| Алдаа | Хэлбэр | Шалтгаан |
|-------|--------|----------|
| `POS Document No is required` | HTTP алдаа | `posDocumentNo` хоосон |
| `POS Sales record with POS Document No %1 not found` | HTTP алдаа | Баримт олдсонгүй |
| `Failed to update POS Sales status: %1` | HTTP алдаа | Төлөв шинэчилж чадсангүй |
| `Failed to create Sales Return Order: %1` | `message` талбарт | Доорх дотоод алдааны аль нэг |
| ↳ `POS Sales does not have an associated Sales Order` | | Subtract горим, `SO Number` хоосон |
| ↳ `Sales Order %1 not found` | | Subtract горим |
| ↳ `Sales Order %1 is not open and cannot be modified` | | Subtract горим, SO Released |
| ↳ `No processed lines found for POS Document %1` | | `Processed` мөр алга |

Мөрийн түвшний алдаа (`errorMessage`-д, мөр `Processed` хэвээр): `Invalid UOM: %1 for Item: %2`, `Sales Order line not found for Item %1`, `Cannot subtract %1 from Sales Order line with quantity %2 for Item %3`, `Quantity cannot be zero for item %1`, `Item %1 does not exist`, `Item %1 is blocked`.

---

### 4.6 Item Journal — Барааны журнал

**Endpoint:**
```
POST /itemJournals
```

| Параметр | Утга |
|----------|------|
| Page | 83052 `Item Journal API` |
| EntityName / EntitySetName | `itemJournal` / `itemJournals` |
| SourceTable | 83060 `Item Batch Buffer` (temporary) |
| Мөр хадгалах хүснэгт | 83061 `Item Lines` ("Pre Item Journal List", page 83057) |

**Зориулалт:** FOOD/HIS системээс ирсэн барааны зарлага/буцаалтыг **урьдчилсан (pre-journal) `Item Lines` хүснэгтэд** хадгална. Item Journal Line **API дуудлагаар үүсэхгүй** — "Pre Item Journal List" дээр *Process Selected Items* үйлдлээр гараар үүсгэнэ (`Journal Background Processor` дахь `ProcessItemJournals` comment-оор хаагдсан).

**Хүсэлтийн бүтэц:**

| Талбар | Төрөл | Заавал | Тайлбар |
|--------|-------|--------|---------|
| requestJson | Text | Тийм | `{"lines":[...]}` бүтэцтэй JSON-ийг **string** хэлбэрээр |
| responseJson | Text | — (read-only) | Үр дүн (JSON string) |

**`requestJson.lines[]` доторх түлхүүрүүд** (JSON түлхүүр том/жижиг үсэг ялгана — кодонд яг доорх нэрээр уншина):

| Түлхүүр | Уншдаг төрөл | Заавал | Тайлбар |
|---------|-------------|--------|---------|
| lineNo | Text (≤50) | Тийм* | Гадаад мөрийн ID. Давхардлын шалгалт, Item Journal Line-ийн `External Document No.` |
| sourceType | Integer | Үгүй | `0` = FOOD (анхдагч), бусад утга = HIS |
| entryType | Integer | — | Уншигддаг ч **ашиглагддаггүй**. Бичилтийн төрлийг `quantity`-ийн тэмдэг тодорхойлно |
| itemNo | Code[20] | Тийм | Барааны дугаар (`Item`-д байх ёстой) |
| quantity | Decimal | Тийм | ≠ 0. Эерэг → `Sale`, сөрөг → `Return` (абсолют утгаар хадгална) |
| description | Text[100] | Үгүй | `Item Lines`-д хадгална (журналын мөрд барааны карт дээрх тайлбар орно) |
| locationCode | Code[20] | Үгүй | Байршил — batch/posting group-ийг тодорхойлно (доор) |
| branch | Code[20] | Үгүй | Shortcut Dimension 1 |
| department | Code[20] | Үгүй | Shortcut Dimension 2 (бүртгэлгүй утга бол хоосон үлдэнэ) |
| unitOfMeasureCode | Code[10] | Үгүй | Хэмжих нэгж |
| lotNumber | Code[50] | Үгүй | Lot дугаар (`Return` үед хадгалахдаа хоосолно) |
| postingDate | Date | Үгүй | Хоосон/буруу формат бол `Today()` |
| type | Text | Үгүй | `"admin"` → ADMIN, `"medical"` → MEDICAL (том/жижиг үсэг хамаагүй), бусад → хоосон |

\* Хоосон байж болох ч давхардлын шалгалт хоосон утгаар ажиллана.

**Жишээ хүсэлт:**
```json
{
  "requestJson": "{\"lines\":[{\"lineNo\":\"F-10001\",\"sourceType\":0,\"itemNo\":\"ITEM001\",\"quantity\":5,\"description\":\"Эмчилгээний хоол\",\"locationCode\":\"THER-FOOD\",\"branch\":\"BR001\",\"department\":\"CC001\",\"unitOfMeasureCode\":\"PCS\",\"lotNumber\":\"LOT001\",\"postingDate\":\"2024-12-01\",\"type\":\"medical\"},{\"lineNo\":\"H-20001\",\"sourceType\":1,\"itemNo\":\"ITEM002\",\"quantity\":-2,\"locationCode\":\"MAIN\",\"postingDate\":\"2024-12-01\"}]}"
}
```

**Жишээ хариу:**
```json
{
  "requestJson": "...",
  "responseJson": "{\"success\":true,\"message\":\"2 line(s) inserted successfully, 0 error(s)\",\"recordsCreated\":2,\"recordsWithErrors\":0,\"errorLines\":[]}"
}
```

**Алдаатай хариу:**
```json
{
  "requestJson": "...",
  "responseJson": "{\"success\":false,\"message\":\"1 line(s) inserted successfully, 1 error(s)\",\"recordsCreated\":1,\"recordsWithErrors\":1,\"errorLines\":[{\"lineNo\":\"F-10001\",\"error\":\"Duplicate line number: F-10001\"}]}"
}
```

`responseJson` түлхүүрүүд: `success` (алдаа 0 бол true), `message` (`%1 line(s) inserted successfully, %2 error(s)`), `recordsCreated`, `recordsWithErrors`, `errorLines[]` (`lineNo`, `error`). JSON задлах алдааны үед зөвхөн `success`, `message`, `recordsCreated` гурав буцна.

**Давхардлын шалгалт:** ижил `lineNo` + ижил `sourceType`-тай, `Status ≠ Error` мөр `Item Lines`-д байвал давхардал гэж үзнэ. Алдаатай мөр бүр `Item Lines`-д `Status = Error`, `Error Message`-тэйгээр хадгалагдана (тиймээс алдаатай мөрийг ижил `lineNo`-оор дахин илгээж болно).

**Journal үүсгэх урсгал** (`ProcessSelectedItemLines`, codeunit 83028):

- Template: Sync Integration Setup → `Item Journal Template` (хоосон бол алдаа).
- Batch / Gen. Bus. Posting Group / INV CATEGORY:

| sourceType | locationCode | Batch | Gen. Bus. Posting Group (Sale) | INV CATEGORY |
|-----------|--------------|-------|-------------------------------|--------------|
| FOOD (0) | `EMP-FOOD` | `SYNC-MEAL` | `MEAL-MED` | — |
| FOOD (0) | `THER-FOOD` | `SYNC-MEAL` | `MEAL-INP` | `PF` |
| FOOD (0) | `KITCHEN` | `SYNC-MEAL` | (хоосон) | — |
| FOOD (0) | `EW-KIT` | `SYNC-MEAL` | `MEAL-INP` | — |
| FOOD (0) | бусад | — (алдаа: batch тодорхойлогдохгүй) | — | — |
| HIS (1) | дурын | `HIS-ITEM` | `HIS` | — |

- Entry Type: `Sale` → Item Journal `Sale` (дээрх posting group); `Return` (сөрөг тоо) → `Positive Adjmt.`, Gen. Bus. Posting Group = **`HIS`** (эх сурвалжаас үл хамаарна).
- Байршил: `THER-FOOD`, `EMP-FOOD` → журналын мөрд `KITCHEN`; бусад нь өөрөөрөө.
- `Document No.` = Batch нэр + `YYMMDD` (posting date); `External Document No.` = `lineNo`.
- `INV CATEGORY` dimension: `THER-FOOD` үед барааны default dimension-ыг дарж `PF` болгоно (dimension value бүртгэлгүй бол чимээгүй алгасна).
- Lot (зөвхөн `Lot Specific Tracking` бараанд): `lotNumber` тухайн бараа + **анхны** `locationCode`-д Item Ledger Entry-д бүртгэлтэй бол түүгээр reservation үүсгэнэ; үгүй/хоосон бол FEFO — хугацаа эрт дуусах lot-оос эхлэн, lot бүрийн **нийт** `Remaining Quantity`-аас тухайн batch-д аль хэдийн хуваарилсан тоог хасаж, хэрэгтэй тоо хүртэл **хэд хэдэн lot-д хуваан** онооно. Хүрэлцэхгүй бол үлдэгдлийг lot-гүй орхино (зөвхөн debug log).
- Амжилттай мөр → `Status = Processed`, `Item Journal No` = batch. Item Journal-ыг post хийхгүй.

**Алдааны мессеж** (`errorLines[].error`):

| Алдаа | Шалтгаан |
|-------|----------|
| `Duplicate line number: %1` | Ижил `lineNo` + `sourceType` (Error биш) бүртгэлтэй |
| `Item No required (line %1)` | `itemNo` хоосон |
| `Item %1 not found (line %2)` | Бараа олдсонгүй |
| `Qty cannot be zero (line %1)` | `quantity` = 0 |
| `Insert failed (line %1)` | Бичлэг хадгалж чадсангүй |
| `Invalid JSON format` | `requestJson` JSON биш (`message`-д) |
| `Property lines not found in JSON` | `lines` түлхүүр алга (`message`-д) |

> **Тэмдэглэл:** API нь `Error()` шиддэггүй — бүх үр дүнг `responseJson`-д буцаана; `OnInsertRecord` нь `exit(false)` буцаадаг тул buffer бичлэг хадгалагдахгүй. Хүсэлт бүр API Log-д бичигдэнэ.

---

### 4.7 Sales Journal — Борлуулалтын журнал

**Endpoint:**
```
POST /salesJournals
```

| Параметр | Утга |
|----------|------|
| Page | 83053 `Sales Journal API` |
| EntityName / EntitySetName | `salesJournal` / `salesJournals` |
| SourceTable | 83053 `Sales Batch Buffer` (temporary) |
| Мөр хадгалах хүснэгт | 83054 `Sales Lines` ("Pre Sales Journal", page 83056) |

**Зориулалт:** HIS/FOOD-ийн борлуулалтын санхүүгийн гүйлгээг **`Sales Lines` pre-journal хүснэгтэд** хадгална. Gen. Journal Line-ийг `Journal Background Processor` (codeunit 83019; *Journal Background Setup* page → *Create Job Queue Entry* нь 5 минут тутам) **автоматаар**, эсвэл "Pre Sales Journal" дээрх *Process Selected Items* үйлдлээр гараар үүсгэнэ.

**Хүсэлтийн бүтэц:** 4.6-тай ижил (`requestJson` / `responseJson` string талбар).

**`requestJson.lines[]` доторх түлхүүрүүд:**

| Түлхүүр | Уншдаг төрөл | Заавал | Тайлбар |
|---------|-------------|--------|---------|
| lineNo | Text (≤50) | Тийм* | Гадаад мөрийн ID. Давхардлын шалгалт, `External Document No.` |
| accountNo | Text (≤20) | Тийм | HIS дансны дугаар. Эхний 2 тэмдэгтээр Account Dictionary-аас дансны төрөл тодорхойлно |
| customerNo | Code[20] | Тийм | Customer **эсвэл** Employee-д бүртгэлтэй байх ёстой |
| amount | Decimal | Тийм | ≠ 0 |
| description | Text[100] | Үгүй | Тайлбар |
| branch | Code[20] | Үгүй | Shortcut Dimension 1 |
| costcenter | Code[20] | Үгүй | Shortcut Dimension 2 (түлхүүр **бүгд жижиг үсгээр** `costcenter`) |
| postingDate | Date | Үгүй | Хоосон/буруу бол `Today()` |
| sourceType | Integer | Үгүй | `0` = FOOD (анхдагч), бусад = HIS |

\* Хоосон байж болох ч давхардлын шалгалт хоосон утгаар ажиллана.

**Жишээ хүсэлт:**
```json
{
  "requestJson": "{\"lines\":[{\"lineNo\":\"HIS-50001\",\"accountNo\":\"12100100-56-00-01\",\"customerNo\":\"C00010\",\"amount\":500000,\"description\":\"Эмчилгээний төлбөр\",\"branch\":\"BR001\",\"costcenter\":\"CC001\",\"postingDate\":\"2024-12-01\",\"sourceType\":1}]}"
}
```

**Жишээ хариу:**
```json
{
  "requestJson": "...",
  "responseJson": "{\"success\":true,\"message\":\"1 line(s) inserted successfully, 0 error(s)\",\"recordsCreated\":1,\"recordsWithErrors\":0,\"errorLines\":[]}"
}
```

**Давхардлын шалгалт:** ижил `lineNo` + ижил `sourceType`-тай, `Status ≠ Error` мөр байвал:
- **өмнө бүртгэгдсэн тэр мөр(үүд)-ийг мөн `Error` төлөвт** оруулж `Error Message`-д `Duplicate line number: %1` бичнэ;
- шинэ мөрийг `Error` төлөвтэй хадгалж, `errorLines`-д буцаана.

**Journal үүсгэх урсгал** (`ProcessSelectedSalesLines`, codeunit 83027):

- Template: Sync Integration Setup → `HIS Sales Journal Template` (хоосон бол алдаа); Batch: **`HISSALES`** (байхгүй бол үүсгэнэ).
- `Customer No` = Sync Integration Setup → `Exclude Customers` бол мөрийг алгасна (`New` хэвээр үлдэнэ).
- Account Dictionary (эхний 2 тэмдэгт) → дансны төрөл:

| Dictionary төрөл | Gen. Journal `Account Type` | `Account No.` |
|------------------|----------------------------|---------------|
| 1 Customer | `customerNo` Employee-д байвал Employee, үгүй бол Customer | `customerNo` |
| 2 Vendor | `customerNo` Employee-д байвал Employee, үгүй бол Vendor | `customerNo` |
| 3 Bank Account | Bank Account (+ `CASHFLOW` = `1.1.1`) | Account Number Mapping-ийн `BC Account No.` (байхгүй бол `accountNo`) |
| 4 G/L account | G/L Account | Account Number Mapping-ийн `BC Account No.` (байхгүй бол `accountNo`) |

- `Document No.` = `'SL' + YYMMDD + '-' + 3 оронтой дараалал` (Sync Integration Setup → `Document Seq No`, 999-ийн дараа 1 болно); `External Document No.` = `lineNo`; `Amount` = `amount`; dimension 1/2 = `branch`/`costcenter`.
- Posting Group override: `accountNo = '32100100-56-00-02'` → `HIS-INP`; `accountNo` `3`-аар эхэлж Account Type = Employee → `31200103`.
- **Тэнцүүлэх мөр:** ижил Document No.-той, Account Type = Customer, Account No. = `Exclude Customers`, дүн = `-amount`.
- Амжилттай → `Status = Processed`, `Sales Journal No` = `HISSALES`. Журналыг post хийхгүй.

**Алдааны мессеж** (`errorLines[].error`):

| Алдаа | Шалтгаан |
|-------|----------|
| `Duplicate line number: %1` | Давхардал (өмнөх мөр мөн Error болно) |
| `Account No required (L%1)` | `accountNo` хоосон |
| `Customer No required (L%1)` | `customerNo` хоосон |
| `Amount cannot be 0 (L%1)` | `amount` = 0 |
| `Customer %1 not found (L%2)` | Customer, Employee аль алинд байхгүй |
| `Insert failed (L%1)` | Хадгалж чадсангүй |
| `Invalid JSON format` / `Property lines not found in JSON` | `message`-д (4.6-тай ижил) |

> **Тэмдэглэл:** Dictionary-д бүртгэлгүй prefix (төрөл 0) бол API шатанд алдаа өгөхгүй; journal үүсгэх үед Account Type/No. тохируулагдахгүй тул Account Dictionary-г урьдчилан бөглөсөн байх шаардлагатай.

---

### 4.8 Salary Journal — Цалингийн журнал

**Endpoint:**
```
POST /salaryJournals
```

| Параметр | Утга |
|----------|------|
| Page | 83058 `Salary Journal API` |
| EntityName / EntitySetName | `salaryJournal` / `salaryJournals` |
| SourceTable | 83062 `Salary Batch Buffer` (temporary) |
| Мөр хадгалах хүснэгт | 83063 `Salary Lines` ("Pre Salary Journal List", page 83059) |

**Зориулалт:** Цалингийн гүйлгээг **`Salary Lines` pre-journal хүснэгтэд** хадгална. Gen. Journal Line-ийг "Pre Salary Journal List" дээрх *Process Selected Lines* үйлдлээр **гараар** үүсгэнэ (`Journal Background Processor` цалинг боловсруулдаггүй).

**Хүсэлтийн бүтэц:** 4.6-тай ижил (`requestJson` / `responseJson` string талбар).

**`requestJson.lines[]` доторх түлхүүрүүд:**

| Түлхүүр | Уншдаг төрөл | Заавал | Тайлбар |
|---------|-------------|--------|---------|
| lineNo | Text (≤50) | Үгүй** | Давхардлын шалгалт (`journalNo`-тэй хамт), `External Document No.` |
| journalNo | Code[20] | Тийм | Журналын дугаар → Gen. Journal `Document No.` |
| journalDate | Date | Үгүй | Хоосон/буруу бол `Today()` → Posting/Document Date |
| accountType | Text | Үгүй* | Дансны төрөл (доорх хүснэгт) |
| accountNo | Code[20] | Үгүй* | Дансны/харилцагчийн дугаар |
| glAccountNo | Code[20] | Үгүй* | Ерөнхий дансны дугаар (зөвхөн `accountType`, `accountNo` хоёул хоосон үед данс болно) |
| debitAmount | Decimal | Үгүй*** | Дебит дүн |
| creditAmount | Decimal | Үгүй*** | Кредит дүн |
| description | Text[250] | Үгүй | Тайлбар (журналын мөрд талбарын уртаар таслагдана) |
| branchCode | Code[20] | Үгүй | Shortcut Dimension 1 (Global Dimension 1-д бүртгэлтэй бол) |
| costCenter | Code[20] | Үгүй | Shortcut Dimension 2 (Global Dimension 2-т бүртгэлтэй бол) |
| taxCode | Code[20] | Үгүй | `TAX ACTIVITY CODE` dimension (бүртгэлтэй бол) |
| postingGroup | Code[20] | Үгүй | Gen. Journal Line-ийн `Posting Group` |

\* Эцсийн байдлаар дансны дугаар тодорхойлогдох ёстой (доорх 3 хувилбар).
\** Хоосон бол давхардлыг шалгахгүй.
\*** `debitAmount`, `creditAmount`-ийн **дор хаяж нэг нь** 0 биш байх ёстой.

> JSON түлхүүрүүд том/жижиг үсэг ялгана — кодонд яг `glAccountNo`, `branchCode`, `costCenter` гэх мэтээр уншина.

**Дансны тодорхойлолт (`ResolveAccountInfo`):**

| Хувилбар | Нөхцөл | Дансны төрөл | Дансны дугаар |
|----------|--------|--------------|---------------|
| 1 | `accountType` хоосон, `accountNo` хоосон, `glAccountNo` өгсөн | G/L Account | `glAccountNo` |
| 2 | `accountType` хоосон, `accountNo` болон `glAccountNo` өгсөн | Account Dictionary-аас (`accountNo`-ийн эхний 2 тэмдэгт) | `accountNo` |
| 3 | Бусад бүх хослол | `accountType` текстээс | `accountNo` |

Хувилбар 2-ын Account Dictionary → Salary төрлийн хөрвүүлэлт:

| Dictionary `Account Type` | Salary `Account Type` |
|---------------------------|-----------------------|
| 1 Customer | Customer |
| 2 Vendor | Vendor |
| 4 G/L account | G/L Account |
| 0 (бүртгэлгүй), 3 Bank Account | G/L Account |

> Account Dictionary нь (`Sync Account Prefix` → `Account Type`) тохиргооны хүснэгт бөгөөд prefix-үүд кодонд hard-code хийгдээгүй — Account Dictionary page-ээс удирдана. Dictionary-д Employee төрөл байхгүй тул хувилбар 2-оор Employee данс тодорхойлогдохгүй; ажилтанд `accountType`-ийг тодорхой өгнө.

`accountType` текстийн утгууд (том/жижиг үсэг хамаагүй):

| Утга | Төрөл |
|------|-------|
| `customer`, `custno`, `1` | Customer |
| `employee`, `empno`, `2` | Employee |
| `vendor`, `vendno`, `3` | Vendor |
| бусад / хоосон | G/L Account |

> **Тэмдэглэл:** Хувилбар 3-т `glAccountNo` ашиглагдахгүй. Жишээ нь `accountNo` өгч `glAccountNo` өгөөгүй бол төрөл G/L Account болж `accountNo`-г G/L данс гэж шалгана; `accountType` өгч `accountNo` хоосон бол `Account No required` алдаа гарна.

**Жишээ хүсэлт:**
```json
{
  "requestJson": "{\"lines\":[{\"lineNo\":\"10000\",\"journalNo\":\"SAL-2412\",\"journalDate\":\"2024-12-31\",\"glAccountNo\":\"61000000\",\"debitAmount\":5000000,\"creditAmount\":0,\"description\":\"Үндсэн цалин\",\"branchCode\":\"BR01\",\"costCenter\":\"CC001\",\"taxCode\":\"T01\"},{\"lineNo\":\"20000\",\"journalNo\":\"SAL-2412\",\"journalDate\":\"2024-12-31\",\"accountType\":\"employee\",\"accountNo\":\"EMP001\",\"debitAmount\":0,\"creditAmount\":5000000,\"description\":\"Ажилтанд олгох\",\"branchCode\":\"BR01\",\"costCenter\":\"CC001\",\"postingGroup\":\"SALARY\"}]}"
}
```

**Жишээ хариу:**
```json
{
  "requestJson": "...",
  "responseJson": "{\"success\":true,\"message\":\"2 line(s) inserted successfully, 0 error(s)\",\"recordsCreated\":2,\"recordsWithErrors\":0,\"errorLines\":[]}"
}
```

**Алдааны жишээ хариу:**
```json
{
  "requestJson": "...",
  "responseJson": "{\"success\":false,\"message\":\"1 line(s) inserted successfully, 1 error(s)\",\"recordsCreated\":1,\"recordsWithErrors\":1,\"errorLines\":[{\"lineNo\":\"20000\",\"error\":\"Гүйлгээ давхардсан\"}]}"
}
```

**Шалгалтын дараалал (мөр бүрт):**
1. `journalNo` хоосон → алдаа.
2. `lineNo` өгсөн бол: ижил `lineNo` **ба ижил `journalNo`**-той, `Status ≠ Error` мөр байвал → `Гүйлгээ давхардсан`.
3. Тодорхойлогдсон дансны дугаар хоосон → алдаа.
4. Дебит, кредит хоёулаа 0 → алдаа.
5. Дансны төрлөөр нь G/L Account / Customer / Employee / Vendor хүснэгтэд байгаа эсэхийг шалгана.
6. Амжилттай бол `Account Name`-ийг (G/L нэр, харилцагч/нийлүүлэгчийн нэр, ажилтны бүтэн нэр) бөглөж хадгална. Алдаатай мөр `Status = Error`-оор хадгалагдана.

**Journal үүсгэх урсгал** (`ProcessSelectedSalaryLines`, codeunit 83029):
- Template: Sync Integration Setup → `Salary Journal Template` (хоосон бол `GENERAL`); Batch: **`SALARY`**.
- `Document No.` = `journalNo`; `Posting Date`/`Document Date` = `journalDate`; `External Document No.` = `lineNo`.
- `Debit Amount` / `Credit Amount`-ийг тус тусад нь validate хийнэ.
- `costCenter` → Shortcut Dimension 2, `branchCode` → Shortcut Dimension 1 — зөвхөн тухайн Global Dimension-д бүртгэлтэй үед; эс бөгөөс хоосон үлдэнэ (алдаа өгөхгүй).
- `taxCode` → `TAX ACTIVITY CODE` dimension (бүртгэлгүй бол хоосон).
- `postingGroup` → Gen. Journal Line `Posting Group`.
- Амжилттай → `Status = Processed`, `Gen. Journal Batch`/`Gen. Journal Template` бөглөгдөнө; journal insert амжилтгүй бол мөр `Error` болно. Журналыг post хийхгүй.

**Алдааны мессеж** (`errorLines[].error`):

| Алдаа | Шалтгаан |
|-------|----------|
| `Journal No required (L%1)` | `journalNo` хоосон |
| `Гүйлгээ давхардсан` | Ижил `lineNo` + `journalNo` (Error биш) бүртгэлтэй |
| `Account No required (L%1)` | Дансны дугаар тодорхойлогдсонгүй |
| `Debit or Credit Amount required (L%1)` | Дебит, кредит хоёулаа 0 |
| `G/L Account %1 not found (L%2)` | G/L данс олдсонгүй |
| `Customer %1 not found (L%2)` | Харилцагч олдсонгүй |
| `Employee %1 not found (L%2)` | Ажилтан олдсонгүй |
| `Vendor %1 not found (L%2)` | Нийлүүлэгч олдсонгүй |
| `Insert failed (L%1)` | Хадгалж чадсангүй |
| `Invalid JSON format` / `Property lines not found in JSON` | `message`-д (4.6-тай ижил) |

> **Тэмдэглэл:** Item / Sales / Salary Journal API-ууд бүгд ижил загвартай: `requestJson` string-ийг задлаад мөр бүрийг pre-journal хүснэгтэд тус тусад нь `Commit()` хийж хадгална (нэг мөрийн алдаа бусдыг цуцлахгүй), HTTP түвшинд алдаа шиддэггүй, хүсэлт бүрийг API Log-д бичнэ.

---

## 5. Өөрчлөлтийн түүх (Change History)

| Хувилбар | Огноо | Өөрчлөлт | Нөлөөлөх API |
|----------|-------|-----------|-------------|
| 1.0.0.1 – 1.0.0.11 | — | Анхны хөгжүүлэлт, суурь API-ууд үүсгэсэн | Бүх API |
| 1.0.0.12 – 1.0.0.22 | — | BackupApps хувилбарууд, тогтворжуулалт | Бүх API |
| 1.0.0.23 | 2024 | Entity Creation API — costCenter, branch талбар нэмсэн | Entity Creation |
| 1.0.0.24 | 2024 | POS Sales API Event Subscriber нэмсэн | POS Sales |
| 1.0.0.25 | 2024 | Gen Journal Import — dimension 3-6 нэмсэн | Gen Journal Import |
| 1.0.0.26 | 2024 | API Log Management нэмсэн, бүх API-д лог бичилт | Бүх API |
| 1.0.0.27 | 2024 | Employee Inquiry API нэмсэн | Employee Inquiry |
| 1.0.0.28 | 2024 | POS Sales Return API нэмсэн | POS Sales Return |
| 1.0.0.29 | 2024 | Item Journal, Sales Journal API нэмсэн | Item Journal, Sales Journal |
| 1.0.0.30 | 2024 | Item Location Inquiry API нэмсэн | Item Location Inquiry |
| 1.0.0.31 | 2024 | Item UOM Inquiry API нэмсэн | Item UOM Inquiry |
| 1.0.0.32 | 2026-03-16 | Salary Journal API нэмсэн | Salary Journal |
| 1.0.0.33 | 2026-03-17 | Employee Ledger Inquiry API нэмсэн | Employee Ledger Inquiry |
| 1.0.0.34 | 2026-04-01 | Salary Lines — давхардлын шалгалт, `"Гүйлгээ давхардсан"` алдаа | Salary Journal |
| 1.0.0.35 | 2026-04-02 | Salary Journal — `glAccountNo` талбар, 3 хувилбарт дансны тодорхойлолт (ResolveAccountInfo) | Salary Journal |
| 1.0.0.35 | 2026-04-02 | Item Inquiry — POS нөөцлөсөн тоо хэмжээ хассан (SubtractPosReservedQty), `barcodes` нэмсэн | Item Inquiry, Item Location Inquiry |
| 1.0.0.35 | 2026-04-02 | Item Inquiry — `locationCode`-гүй үед POS Default Location Code-оор шүүх логик нэмсэн. **Дараа нь comment болгож хаагдсан — одоо шүүхгүй** (3.7-г үз) | Item Inquiry |
| 1.0.0.36 | 2026-04-02 | Account Dictionary — InitializeData устгасан, Setup page-ээс удирдах болсон | Sales / Salary Journal (config) |
| 1.0.0.37 | 2026-04-03 | Salary API дуусгасан. *(Өмнөх гарын авлагад "`glaccountNo`/`glAccountNo` том жижиг үсэг ялгахгүй" гэж бичсэн нь буруу — код зөвхөн `glAccountNo` уншина)* | Salary Journal |
| 1.0.1.08 | 2026-04-20 | FA Inquiry — `comment` талбар нэмэгдсэн (JSON массив агуулсан **string**) | FA Inquiry |
| — | 2026-05-01 | FA / Item Inquiry сайжруулалт (FA Inquiry-д blocked ҮХ-г хасах логик түр нэмэгдсэн) | FA Inquiry, Item Inquiry |
| — | 2026-06-11 | POS Sales — `posDocumentNo` давхардлын шалгалт сайжруулсан | POS Sales |
| — | 2026-06-18 | Item Journal — HIS Sale posting group, THER-FOOD `INV CATEGORY` override | Item Journal |
| 1.0.1.13 | 2026-06-22 | FA Inquiry — `blocked` талбар нэмэгдсэн, blocked ҮХ-г дахин response-д буцаадаг болсон | FA Inquiry |
| — | 2026-06-24 | FA Inquiry — `rfidCode` талбар нэмэгдсэн (RFID improvement) | FA Inquiry |
| — | 2026-06-25 | Misc Article Inquiry — `fromDate`, `toDate`, `inUse`, `lastModifiedDate` бодит бичлэгээс авдаг болсон; Item Location Inquiry сайжруулалт | Misc Article Inquiry, Item Location Inquiry |
| — | 2026-06-26 | Item Journal — олон lot-д FEFO-оор хуваах (lot qty) | Item Journal |
| 1.0.1.15 | 2026-07-03 | Salary Journal — `branchCode` талбар нэмэгдсэн (Pre Salary Journal List, Gen. Journal Line `Shortcut Dimension 1 Code`) | Salary Journal |
| 1.0.1.16 | 2026-08-28 | Entity Creation — `bankAccountNo`, `bankCode`, `bankAccountName` талбарууд нэмэгдсэн (Employee `Bank Account No.`, `EM CG Bank Code`, `EM CG Bank Account Name`) | Entity Creation |
| 1.0.1.17 | 2026-08-28 / 08-31 | `EM.BC.Core.CG` хамаарлын хувилбар **1.0.0.52 → 1.0.0.46** болгож бууруулсан; хувилбар ахиулсан | — |
| **1.0.1.18** | **2026-09-07** | **Item Inquiry — `locationCode`-гүй дуудахад `remainingQuantity` үргэлж 0, `lotInfo` үргэлж `"[]"` буцдаг алдааг зассан.** Одоо бүх байршлаар lot-д суурилсан тооцоолол (нээлттэй ILE − борлуулалтын захиалга − `New` POS нөөц) хийнэ; lot-ийн `expiryDate` = хамгийн эрт дуусах огноо | Item Inquiry |

> **Тэмдэглэл:** "—" гэсэн мөрүүд нь commit түүхээс тодорхойлсон өөрчлөлтүүд бөгөөд тухайн үеийн app хувилбарын дугаар баттай тодорхойгүй.

### Гарын авлагын засвар (2026-10-14)

Энэ шинэчлэлээр өмнөх гарын авлага (v1.0.1.16)-ын кодтой зөрж байсан дараах гол зүйлсийг зассан:

- **Хамаарал:** `EM.BC.Core.CG` хамгийн бага хувилбар `1.0.0.52` биш **`1.0.0.46`**.
- **Base URL:** `companies({companyId})/` хэсэг нэмсэн.
- **FA Inquiry:** `employeeNo` заавал; `rfidCode` талбар нэмсэн; `comment` нь JSON массив биш JSON агуулсан string; элэгдлийн дэвтэр `FINANCE`; `lastMaintenanceDate` бөглөгддөггүй.
- **Customer AR / Vendor AP Inquiry:** шүүлтүүр заавал; зөвхөн нээлттэй бичилт; `paymentTermsCode`, `vendorInvoiceNo` үргэлж хоосон; бичилтгүй үед `NO-AR-ENTRIES` / `NO-AP-ENTRIES` мөр.
- **Misc Article Inquiry:** хэд хэдэн талбар үргэлж хоосон/тогтмол; эд зүйлгүй үед алдаа буцна.
- **Warehouse Inquiry:** баримтжуулаагүй 8 талбар нэмсэн; тогтмол утгатай талбаруудыг тэмдэглэсэн.
- **Item Inquiry:** `categoryCode` биш `itemCategoryCode`; POS бус бараа ч буцна; POS Default Location-оор шүүхгүй; `inventory`-ийн утга горимоос хамаарна.
- **Item Location Inquiry:** хоёр шүүлтүүр заавал, үргэлж нэг мөр.
- **Item UOM Inquiry:** барааны биш, ерөнхий `Unit of Measure` жагсаалт.
- **Entity Creation:** зөвхөн Employee үүсгэнэ (Vendor/Customer үүсгэхгүй); `registerNo` хадгалагдахгүй; status 3 үед `employeeNo` = `<No>-INACTIVE`.
- **FA Movement:** мөрүүд `faMovementLines` part биш, **`linesJson` string** талбараар; ҮХ картыг шууд өөрчлөхгүй, FA Movement баримт үүсгэнэ.
- **Gen Journal Import:** бодит хариу нь `success`, `errorMessage`, `createdLineNo` бүхий бичлэг.
- **POS Sales:** SO-г шууд үүсгэхгүй (background processor); `customerNo` илгээх боломжгүй; статусууд, давхардлын дүрэм.
- **POS Sales Return:** бодит хариу/мессеж, `POS Is Return Order Generate` тохиргооны нөлөө, огнооны хязгаарлалт бодитоор шалгагддаггүй.
- **Item Journal:** `entryType` ашиглагддаггүй (тоо хэмжээний тэмдгээр шийднэ); `sourceType`, `type` утгууд; хариу мессеж.
- **Sales / Salary Journal:** Account Dictionary нь тохируулдаг хүснэгт (хатуу prefix дүрэм байхгүй); давхардлын түлхүүр `lineNo` + `journalNo`; `taxCode`, `postingGroup`.
- **Sync Integration Setup:** 4 биш 16 талбартай.

---

## Хавсралт: Sync Integration Setup тохиргоо

`Sync Integration Setup` (Table 83099, Page 83099 — нэг мөртэй setup). Page нээгдэхэд эсвэл `GetSetup()` дуудагдахад мөр байхгүй бол дараах анхдагч утгаар үүснэ: `POS Default Customer No. = 'I0000002'`, `Default Revenue Type = 'FD'`, `POS Default Location Code = 'OUT'`, `POS Is Return Order Generate = false`, `POS Use FEFO for Untracked Lot = true`, `POS Is Generate SO = true`.

| # | Талбар (AL нэр) | Caption | Төрөл | Тайлбар | Ашигладаг API / объект |
|---|-----------------|---------|-------|---------|------------------------|
| 1 | Primary Key | Primary Key | Code(10) | Setup-ийн түлхүүр | — |
| 2 | POS Default Customer No. | POS Default Customer No. | Code(20) → Customer | POS Sales-д customer хоосон үед | POS Sales (`POS Sales` table `GetDefaultCustomer`, `POS Sales API` OnInsertRecord, `POS Sales Order Management.CreateSalesOrderFromPOS`) |
| 3 | POS Default Location Code | POS Default Location Code | Code(10) → Location | POS Sales-д `location` хоосон үед | POS Sales (`POS Sales API` → `GetDefaultLocation`). **Item Inquiry ашиглахгүй** |
| 4 | Item Journal Template | Item Journal Template | Code(10) → Item Journal Template | Item Journal мөр үүсгэх template. Хоосон бол `Item Journal Template not configured in Sync Integration Setup` алдаа | Item Journal (`Item Line Insert Handler.ProcessSelectedItemLines`) |
| 5 | Default Revenue Type | Default Revenue Type | Code(20) → Dimension Value (`REVENUE TYPE`) | Setup page-д харагдана, `GetDefaultRevenueType()` функц байгаа | Шалгасан API/codeunit-уудад уншилт олдсонгүй |
| 6 | HIS Sales Journal Template | HIS Sales Journal Template | Code(10) → Gen. Journal Template | Sales Journal-ын template (batch нь `HISSALES`). Хоосон бол `HIS Sales Journal Template not configured in Sync Integration Setup` алдаа | Sales Journal (`Sales Line Insert Handler.ProcessSelectedSalesLines`) |
| 7 | Sales Default Customer | Sales Default Customer | Text(20) → Customer | Page дээр "HIS Default Customer No." нэрээр харагдана | Шалгасан API/codeunit-уудад уншилт олдсонгүй |
| 8 | POS Is Return Order Generate | POS: Is Return Order Generate | Boolean | `true`: POS буцаалтаар Sales Return Order үүсгэнэ; `false`: үүссэн Sales Order-оос тоо хэмжээг хасна | POS Sales Return (`POS Sales Order Management.CreateSalesReturnFromPOS`) |
| 9 | POS Use FEFO for Untracked Lot | POS: Use FEFO for Untracked Lot | Boolean | Lot өгөөгүй/бүртгэлгүй үед FEFO-оор lot сонгох эсэх | POS Sales / Return (`POS Sales Order Management.AddLotNumberToSalesLine`) |
| 10 | POS Is Generate SO | POS: Is Generate SO | Boolean | `false` бол SO/SR автоматаар үүсгэхгүй | `POS Sales Background Processor`, `CreateSalesReturnFromPOS` |
| 11 | Exclude Customers | Exclude Customer | Code(20) → Customer | Sales Journal-д энэ customer-тэй мөрийг алгасна; **мөн тэнцвэржүүлэх (balancing) мөрийн Customer дансаар ашиглагдана** | Sales Journal (`Sales Line Insert Handler`) |
| 12 | Document Seq No | Document Sequence Number | Integer (анхдагч 1) | Sales Journal баримтын дугаар `SL{YYMMDD}-{NNN}`-ийн дараалал; 1000 хүрэхэд 1 болно | Sales Journal (`GetNextDocumentSeqNo`) |
| 13 | Salary Journal Template | Salary Journal Template | Code(10) → Gen. Journal Template | Цалингийн журналын template (batch нь `SALARY`). Хоосон бол `GENERAL` | Salary Journal (`Salary Line Insert Handler.ProcessSelectedSalaryLines`) |
| 14 | POS SO Processing | POS SO Processing | Boolean (засах боломжгүй) | SO үүсгэх background процессын түгжээ | `POS Sales Background Processor` |
| 15 | POS SO Processing Started At | POS SO Processing Started At | DateTime (засах боломжгүй) | Түгжээ эхэлсэн цаг (15 минутын timeout) | `POS Sales Background Processor` |
| 16 | POS SO Processing User | POS SO Processing User | Code(50) (засах боломжгүй) | Түгжээ авсан хэрэглэгч | `POS Sales Background Processor` |

> **Тэмдэглэл:** Entity Creation, FA Movement, Gen Journal Import API-ууд `Sync Integration Setup`-ийг **ашигладаггүй**. Setup page-д мөн `Account Dictionary` болон `Account Number Mapping` part-ууд (Sales/Salary Journal-ын дансны төрөл ба дугаар тааруулалт) байрлана.

---

> **Тэмдэглэл:** Энэхүү баримт бичиг нь `EM.BC.IMC.API` **v1.0.1.18** (`dev` салбар, commit `802b343`) хувилбарын эх кодод суурилсан бөгөөд шинэ хувилбар гарах тутам шинэчлэгдэх шаардлагатай.
