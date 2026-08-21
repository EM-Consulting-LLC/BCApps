# Business Logic Reference — ERP-ийн бизнес аюулгүй байдал

## Суурь зарчим

1. **Бичигдсэн зүйл immutable:** posted document, ledger entry-ийн санхүүгийн утга
   өөрчлөгддөггүй; залруулга = урвуу/сөрөг бичилт (Reversal, Corrective Credit Memo,
   Reversed флаг + сөрөг entry).
2. **Документ lifecycle:** Open → (Pending Approval) → (Pending Prepayment) →
   Released → Posted. Released мөр `TestStatusOpen()`-оор хамгаалагдана; статус
   шилжилт зөвхөн Release/Reopen codeunit-ээр (approval шалгалттай).
3. **Validation гурван давхарга:** Table OnValidate (интерактив) → Release
   (баримт бүрэн) → Posting Check codeunit (эцсийн бүрэн шалгалт). API/code-оор
   орсон өгөгдөлд эхний давхарга ажиллахгүй байж болно — сүүлийнх заавал.
4. **Дүн тооцоолол:** Currency.Initialize + Amount Rounding Precision; гүйлгээний
   огнооны ханш; rounding remainder дамжуулж хуримтлагдах зөрүөг арилгана;
   LCY + валютын дүн зэрэгцээ.
5. **Идемпотенц:** Posting No. урьдчилан олгож хадгална + posted хүснэгтэд conflict
   шалгана; vendor invoice-д External Document No. давхардлыг шалгана; Job Queue
   Status флаг давхар schedule хориглоно.

## Дүрмүүд

### BC-BIZ-001 [CRITICAL] — Posted/ledger өгөгдөл гуйвуулах
Posted document/ledger entry-ийн дүн, тоо, данс, огноо, VAT Modify хийгдэж байвал.
Non-financial талбар (тайлбар, холбоос id) стандартад ч шинэчлэгддэг — ялгаж үнэл.
**Засвар:** Correct Posted Sales Invoice г.м. стандарт correction; custom ledger-т
Reversed флаг + сөрөг entry.

### BC-BIZ-002 [HIGH] — Lifecycle зөрчил
`Status :=` шууд assignment (Release/Reopen-ийн гадна); Released баримтын мөрийг
TestStatusOpen/Validate-гүй өөрчлөх; approval bypass (SetSkipCheckReleaseRestrictions
төрлийн дуудлага үндэслэлгүй). **Засвар:** Release Sales/Purchase Document дууд;
өөрчлөлтийн өмнө статус шалга.

### BC-BIZ-003 [HIGH] — Rounding/currency зөрчил
`Qty * Price` Round-гүй Amount-д олгох; Currency precision үл хэрэглэх; ханшид
posting date биш WorkDate; мөр бүр Round хийж drift үүсгэх. **Засвар:** Currency
Initialize + precision; ExchangeAmtFCYToLCY-д гүйлгээний огноо; remainder дамжуул.

### BC-BIZ-004 [HIGH] — Dimension алдагдал
Custom бичилтэд эх баримтын "Dimension Set ID" дамжаагүй; CheckDimIDComb/
CheckDimValuePosting алгассан. **Засвар:** Dimension Set ID хуулж, DimMgt-ээр
default нэгтгэ, шалгалт хий.

### BC-BIZ-005 [MEDIUM] — Blocked шалгалт алгасах
Customer/Vendor/Item/Account-ийг Validate биш `:=`-ээр олгох — Blocked,
Privacy Blocked шалгагдахгүй. **Засвар:** Validate ашигла; batch/API урсгалд
шалгалт нэм.

### BC-BIZ-006 [MEDIUM] — Validate дараалал
Document line үүсгэхэд Type → No. → Variant/Location → Quantity → Unit Price
стандарт дарааллыг зөрчих; OnValidate-тэй талбарт шууд assignment. Дагалдах
тооцоолол (үнэ, UOM, availability) алгасагдана.

### BC-BIZ-007 [MEDIUM] — Хэсэгчилсэн ship/invoice үл тооцох
Quantity = Qty. to Ship = Qty. to Invoice гэж таамаглах; Outstanding/"Qty. Shipped
Not Invoiced"-ийг үл тоох custom тооцоолол — хэсэгчилсэн posting-т зөрүү гарна.

### Идемпотенцийн шалгуур (BC-POST-001-тэй хамт хэрэглэ)
Ямар ч бичилт үүсгэдэг урсгалд асуу: "Энэ хоёр удаа ажиллавал юу болох вэ?"
Хамгаалалт: (1) existence/status шалгалт, (2) урьдчилан хадгалсан дугаар,
(3) LockTable-тэй check-then-act, (4) unique key.
