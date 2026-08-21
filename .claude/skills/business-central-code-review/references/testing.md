# Testing Reference — Тестийн шалгалт

## Стандарт (Base App-ийн тест кодоос)

```al
codeunit 134893 "..." {
    Subtype = Test;
    [Test]
    procedure PostSalesInvoice()
    begin
        // [SCENARIO ###] ...
        Initialize();                             // тусгаарлалт
        // [GIVEN] Library-гаар өгөгдөл
        LibrarySales.CreateSalesInvoice(SalesHeader);
        // [WHEN] үйлдэл
        // [THEN] үр дүнгийн шалгалт (Assert)
    end;
}
```
- Library - Sales/Purchase/ERM/Random/Inventory — өгөгдөл үүсгэлт; hardcoded
  дугаар байхгүй.
- Initialize(): isInitialized флаг + LibrarySetupStorage.Restore() — Setup-ийг
  анхны төлөвт.
- Negative тест: `asserterror` + `Assert.ExpectedError` + **дараах төлөвийн
  шалгалт** (`VerifySalesOrderNotPosted` — rollback баталгаа).
- UI-г handler-ээр: [ConfirmHandler], [MessageHandler], [RequestPageHandler].

## Дүрмүүд

### BC-TEST-001 [MEDIUM] — Posting/бичилтийн өөрчлөлтөд тест байхгүй
Ledger бичилт, дүн тооцоолол, validation өөрчлөгдсөн ч тест өөрчлөгдөөгүй.
Шаардах багц: (1) амжилттай бичилтийн ledger шалгалт, (2) negative (asserterror),
(3) rollback (алдааны дараа юу ч бичигдээгүй).

### BC-TEST-002 [MEDIUM] — Negative/rollback тест дутуу
Шинэ Error/TestField-д asserterror тест; Commit-тэй урсгалд partial-state тест байхгүй.

### BC-TEST-003 [MEDIUM] — Идемпотенц тест дутуу
Давтан ажиллаж болзошгүй урсгалд (API action, Job Queue, импорт, retry) "хоёр удаа
дуудаад үр дүн нэг" тест байхгүй.

### BC-TEST-005 [MEDIUM] — Assertion-гүй тест
Процесс ажиллуулаад үр дүн шалгаагүй — хуурамч ногоон.

### BC-TEST-004 [LOW] — Тусгаарлалт/Library
Hardcoded дугаар, demo өгөгдөлд найдах, Initialize байхгүй, тест дарааллын хамаарал.

### BC-TEST-006 [LOW] — Handler-ийн дэг
Dialog-той урсгалд handler байхгүй; handler болзолгүй Reply := true.

## Test Assessment гаргах журам (review-ийн төгсгөлд)

1. **Existing coverage:** өөрчлөгдсөн объектуудад ямар тест байгааг тодорхойл
   (test файлууд diff-д байгаа эсэх, байгаа тестүүд өөрчлөлтийг хамрах эсэх).
2. **Missing:** дүрмүүдээс үүдсэн дутуу тестүүдийг жагсаа.
3. **Recommended scenarios:** тодорхой Given/When/Then хэлбэрээр 2-5 сценарио
   санал болго (хамгийн эрсдэлтэйгээс эхэл: давхар бичилт, rollback, edge case).
