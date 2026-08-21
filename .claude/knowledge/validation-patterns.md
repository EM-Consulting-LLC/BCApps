# Validation Patterns — Шалгалтын хэв маягийн мэдлэгийн сан

## 1. Зарчим

Business Central-д validation **гурван түвшинд** давхарлагдан хийгддэг:

1. **Талбарын түвшин** — Table-ийн OnValidate: тухайн талбарын утга + хамааралтай
   талбаруудын уялдаа.
2. **Баримтын түвшин** — Release үед (`Release Sales Document`): баримт "бүрэн" эсэх.
3. **Posting-ийн түвшин** — Post-ийн Check фаз (`CheckSalesDocument`,
   `ItemJnlCheckLine.RunCheck`): бичилт хийхийн өмнөх эцсийн, бүрэн шалгалт.

Доод түвшинд шалгасан зүйлд найдаж болохгүй — posting-ийн өмнө бүгд дахин шалгагдана.

## 2. Source code дээрх ажиглалт

### Талбарын OnValidate (SalesLine.Quantity-аас)
- Эхэнд `OnBeforeValidateQuantity(..., IsHandled)`.
- **`TestStatusOpen()`** — Released баримтын мөрийг өөрчлөхийг хориглоно
  (документ lifecycle-ийн хамгаалалт).
- `CheckAssocPurchOrder` — холбоотой баримтын уялдаа.
- Сөрөг/зөрсөн тоо хэмжээг `FieldError`-ээр: аль хэдийн тээвэрлэсэн хэмжээнээс
  бага болгохыг хориглох гэх мэт.
- `CurrFieldNo` шалгаж хэрэглэгчийн интерактив оролт ба кодын оролтыг ялгадаг
  (`if CurrFieldNo = Rec.FieldNo(Quantity) then CheckWarehouse(false)`).

### Posting-ийн Check фаз (CheckSalesDocument)
- `CheckMandatoryHeaderFields`, `TestField("Journal Templ. Name", ErrorInfo.Create())`.
- **Posting Date хязгаар:** `GenJnlCheckLine.IsDateNotAllowed(...)` — GL Setup +
  User Setup-ийн Allow Posting From/To. Алдааг `ErrorMessageMgt.LogContextFieldError`-оор
  контексттэй бүртгэдэг.
- `CheckDimensions.CheckSalesDim` — dimension combination + value posting дүрэм.
- `CheckPostRestrictions` — event-ээр өргөтгөгддөг хориг (approval workflow эндээс
  баримтыг зогсоодог).
- `CalcInvoice` — юу ч invoice хийгдэхгүй бол Invoice=false болгодог.
- Item journal: `ItemJnlCheckLine.RunCheck` — Item.Get + `TestField("Base Unit of
  Measure")`, Location Mandatory, dimension, дата шалгалт.

### Batch validation
- `[ErrorBehavior(ErrorBehavior::Collect)]` + `Error Message Management` — background
  full document check (CheckSalesDocBackgr) бүх алдааг цуглуулж UI-д харуулдаг.

### Duplicate хамгаалалт
- Vendor invoice: `CheckExternalDocumentNumber` — Vendor Ledger Entry-ээс ижил
  External Document No. + Pay-to Vendor-ийг хайж, олдвол Error
  (нийлүүлэгчийн нэхэмжлэх давхар бүртгэхээс сэргийлнэ).
- Мастер дугаар: Customer.OnInsert — `while Customer.Get("No.") do "No." := NoSeries.GetNextNo(...)`.

## 3. Яагаад ингэж хийсэн бэ (analysis)

- Гурван давхарга нь өөр өөр цагт, өөр өөр сувгаар өгөгдөл ирдэгтэй холбоотой:
  API-аар Insert хийхэд Page validation алгасагдана; Released баримт дээр
  талбар өөрчлөгдөж болохгүй; posting бол эцсийн бөгөөд эргэлт буцалтгүй тул
  100% бүрэн шалгалт шаардана.
- FieldError/TestField нь алдааны текстэд талбар, record-ын контекстыг автоматаар
  оруулдаг тул хэрэглэгчид ойлгомжтой.
- ErrorInfo.Create() нь collectible — олон алдааг нэг дор харуулах шинэ UX.

## 4. Зөв хэрэгжилт

```al
// Талбарын validation — статус шалгаад FieldError
field(50100; "Discount Points"; Integer)
{
    trigger OnValidate()
    begin
        TestStatusOpen();
        if "Discount Points" < 0 then
            FieldError("Discount Points", MustBePositiveErr);
    end;
}

// Custom posting-ийн өмнө бүрэн шалгалт
local procedure CheckBeforePost(LoyaltyEntry: Record "Loyalty Entry")
begin
    LoyaltyEntry.TestField("Customer No.");
    LoyaltyEntry.TestField("Posting Date");
    if GenJnlCheckLine.IsDateNotAllowed(LoyaltyEntry."Posting Date", SetupRecID, '') then
        Error(PostingDateNotAllowedErr, LoyaltyEntry.FieldCaption("Posting Date"));
end;
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: Released статус шалгалгүй мөр өөрчлөх
procedure UpdateLineDiscount(var SalesLine: Record "Sales Line")
begin
    SalesLine."Line Discount %" := 10; // TestStatusOpen байхгүй, Validate ч биш
    SalesLine.Modify();               // Released захиалгын үнийг зөөвөрлөж байна
end;

// БУРУУ: Posting Date-ийн Allow Posting From/To шалгалгүй бичилт
procedure PostAdjustment(PostingDate: Date)
begin
    GenJnlLine."Posting Date" := PostingDate; // хаагдсан тайлант үе рүү бичиж болзошгүй
    GenJnlPostLine.RunWithCheck(GenJnlLine);  // (RunWithCheck нь шалгана — гэхдээ
                                              // өөрийн custom entry бол шалгахгүй!)
end;

// БУРУУ: Validate-гүй утга олгох (validation алгасах)
SalesLine.Quantity := NewQty;   // OnValidate огт ажиллахгүй —
SalesLine.Modify();             // Qty (Base), reservation, warehouse шалгалт алгасна
```

## 6. Code review хийх дүрэм

1. **[HIGH]** Документын мөр/толгойн утгыг өөрчлөхдөө `Validate(...)` биш шууд
   assignment ашигласан, мөн тухайн талбарын OnValidate-д хамааралтай тооцоолол
   байдаг бол — өгөгдлийн уялдаа эвдэрнэ.
2. **[HIGH]** Released/Posted баримт дээр статус шалгалгүй өөрчлөлт хийж байвал
   (TestStatusOpen эсвэл Status шалгалт байхгүй) — lifecycle зөрчил.
3. **[HIGH]** Custom бичилт (journal/ledger үүсгэдэг код) Posting Date-ийн зөвшөөрөгдсөн
   хязгаарыг шалгахгүй байвал — хаагдсан үе рүү бичих эрсдэл.
4. **[MEDIUM]** Custom посттой урсгалд dimension шалгалт (CheckDimIDComb,
   CheckDimValuePosting) алгассан бол.
5. **[MEDIUM]** Гадаад баримтын дугаар (External Document No.) дээр давхардлын
   шалгалт хийх бизнес шаардлага байвал хийсэн эсэх.
6. **[MEDIUM]** Validation-ийг зөвхөн UI талд (Page) хийсэн бол Table/posting түвшинд
   давхарлах шаардлага.
7. **[LOW]** Олон алдаа гарах магадлалтай batch шалгалтад ErrorInfo/collectible
   хэлбэр ашиглах боломж.
