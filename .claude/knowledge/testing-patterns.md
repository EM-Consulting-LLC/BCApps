# Testing Patterns — Тестийн хэв маягийн мэдлэгийн сан

## 1. Зарчим

BC-ийн тест нь **бизнес сценарио** дээр тулгуурладаг: Library-гаар өгөгдөл бэлдэж,
бодит posting/процесс ажиллуулаад, ledger/баримтын үр дүнг шалгадаг.
Given/When/Then бүтэц, тест хоорондын тусгаарлалт, handler-ээр UI-г орлуулах нь
заавал дагадаг дүрэм.

## 2. Source code дээрх ажиглалт (Tests/ERM, TestLibraries)

### Тест codeunit-ийн бүтэц
```al
codeunit 134893 "Background Document Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue] [Background Posting]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoice()
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Post Sales Invoice via Job Queue.
        Initialize();
        // [GIVEN] Sales Invoice.
        LibrarySales.CreateSalesInvoice(SalesHeader);
        // [WHEN] Post Sales Invoice via Job Queue.
        PostSalesDocumentViaJobQueue(SalesHeader);
        // [THEN] Posted Sales Invoice was created.
        VerifyPostedSalesInvoice(SalesHeader);
    end;
}
```

### Гол хэв маягууд
- **Library codeunit-ууд:** `Library - Sales`, `Library - Purchase`, `Library - ERM`,
  `Library - Random`, `Library - Inventory` — тестийн өгөгдлийг стандарт аргаар үүсгэдэг;
  тест дотор гараар мастер өгөгдөл угсардаггүй.
- **Initialize() pattern:** `LibraryTestInitialize.OnTestInitialize(Codeunit::...)`,
  `isInitialized` флаг, `LibrarySetupStorage.Restore()` — Setup хүснэгтүүдийг
  тест бүрийн өмнө анхны төлөвт буцаадаг (тестийн тусгаарлалт).
- **Assert:** `Assert.ExpectedError(...)`, `Assert.AreEqual`, `Assert.RecordCount` —
  утга шалгалт бүр мессежтэй.
- **asserterror:** алдаа гарахыг шалгах: `asserterror PostSalesDocumentViaJobQueue(...)`
  дараа нь `Assert.ExpectedError(StrSubstNo('%1 must have a value', ...))`.
- **Negative тест дараах төлөвийг шалгадаг:** `VerifySalesOrderNotPosted(SalesHeaderCopy)` —
  алдааны дараа өгөгдөл өөрчлөгдөөгүйг баталдаг (rollback шалгалт!).
- **Handler функцууд:** `[ConfirmHandler]`, `[MessageHandler]`, `[RequestPageHandler]`,
  `[HandlerFunctions(...)]` — UI dialog-ийг тестэд орлуулна.
- **Mock/Event тест:** TestLibraries-д `*MockEvents.Codeunit.al` — event-ээр
  гадаад хамаарлыг орлуулдаг.
- **Scenario дугаар:** `// [SCENARIO 322727]` — bug/requirement-ийн ID холбодог.

## 3. Яагаад ингэж хийсэн бэ (analysis)

- Library-гээр өгөгдөл үүсгэх нь тестүүдийг schema өөрчлөлтөөс тусгаарлаж,
  анхны утгуудыг нэг цэгт барьдаг.
- Setup Restore/Initialize нь тест дарааллаас хамааралгүй болгодог — аль ч тест
  дангаараа, ямар ч дарааллаар ажиллана.
- Negative тест + NotPosted шалгалт нь ERP-д чухал: алдаа нь өөрөө зөв байдал —
  хагас бичилт үлдээгүйг заавал батлах ёстой.

## 4. Зөв хэрэгжилт

```al
[Test]
procedure PostingFailsWhenLoyaltyBlocked()
var
    SalesHeader: Record "Sales Header";
begin
    // [SCENARIO] Blocked loyalty гишүүнтэй захиалга post хийхэд алдаа өгнө
    Initialize();
    // [GIVEN] Blocked гишүүнтэй sales order
    CreateOrderWithBlockedLoyaltyMember(SalesHeader);
    // [WHEN] Post
    asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
    // [THEN] Тодорхой алдаа + юу ч бичигдээгүй
    Assert.ExpectedError(LoyaltyBlockedErr);
    VerifyNoLedgerEntriesCreated(SalesHeader);
end;
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: тест хоорондын хамаарал
[Test]
procedure Test1_CreateData()   // Test2 нь Test1-ийн өгөгдөлд найдна —
begin ... end;                 // дараалал өөрчлөгдвөл унана

// БУРУУ: hardcoded өгөгдөл
SalesHeader."Sell-to Customer No." := '10000';  // demo компанийн өгөгдөлд найдсан

// БУРУУ: зөвхөн happy path — negative тест байхгүй
// (алдааны зам, rollback, хязгаарын утга шалгаагүй)

// БУРУУ: assertion-гүй тест
[Test]
procedure TestPost()
begin
    LibrarySales.PostSalesDocument(SalesHeader, true, true);
    // юу ч шалгаагүй — "ажилласан" гэдэг нь ногоон гэсэн үг биш
end;
```

## 6. Code review хийх дүрэм

Өөрчлөлт бүрд "ямар тест шаардлагатай вэ" гэдгийг дараах логикоор үнэл:

1. **[MEDIUM]** Posting/бичилтийн логик өөрчлөгдсөн бол: (a) амжилттай бичилтийн
   ledger үр дүн, (b) validation алдааны negative тест, (c) алдааны дараа юу ч
   бичигдээгүйг шалгах тест гурвуулаа байх ёстой.
2. **[MEDIUM]** Идемпотенцтэй холбоотой код (давтан post, давтан sync) бол давтан
   дуудлагын тест шаардлагатай.
3. **[MEDIUM]** Тоо хэмжээ/дүн тооцоолол өөрчлөгдсөн бол хязгаарын утгууд:
   0, сөрөг, rounding, валюттай/валютгүй, хэсэгчилсэн ship/invoice.
4. **[MEDIUM]** Event subscriber нэмэгдсэн бол: subscriber идэвхтэй/идэвхгүй үеийн
   зан төлөв, IsHandled=true-гийн нөлөө.
5. **[MEDIUM]** Тест бий, гэхдээ assertion сул (зөвхөн "ажиллаж дууссан") бол —
   үр дүнгийн шалгалт нэмүүл.
6. **[LOW]** Тест Library ашиглахгүй гараар өгөгдөл угсарч байвал, hardcoded
   мастер дугаар ашиглаж байвал.
7. **[LOW]** Given/When/Then тайлбаргүй урт тест — уншигдах байдал.
8. **Regression эрсдэлийн асуулт:** өөрчилсөн procedure-ийг өөр хэдэн газраас
   дууддаг вэ? Дуудагч бүрийн сценарио одоо байгаа тестээр хамрагдсан уу?
   Хамрагдаагүй нь илэрвэл MEDIUM finding болгож тэмдэглэ.
