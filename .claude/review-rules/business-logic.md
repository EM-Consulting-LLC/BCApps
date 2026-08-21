# Business Logic Review Rules — BC-BIZ

---

## BC-BIZ-001 — Posted/ledger өгөгдлийг гуйвуулах

- **Severity:** CRITICAL
- **Rule:** Posted document болон ledger entry-ийн санхүүгийн утга (дүн, тоо хэмжээ,
  данс, огноо, VAT) custom кодоор Modify хийгдэж байвал илрүүлнэ.
- **Why:** Бичигдсэн зүйл immutable; залруулга нь зөвхөн урвуу/сөрөг бичилтээр
  хийгддэг (Reversal, Corrective Credit Memo). Non-financial талбар (тайлбар,
  холбоос ID) стандартад ч шинэчлэгддэг тул ялгаж үнэлнэ.
- **Risk:** GL ↔ subledger ↔ posted document зөрүү; аудит бүтэлгүйтэл.
- **Detection:** Sales Invoice Header/Line, Sales Shipment, G/L Entry, *Ledger Entry
  гэх мэт posted/ledger хүснэгт дээрх Modify/ModifyAll — өөрчилж буй талбарын
  төрлийг ангил.
- **Example — Good:** `Correct Posted Sales Invoice` codeunit ашиглах; custom
  ledger-т Reversed флаг + сөрөг entry.
- **Suggested Fix:** Стандарт correction урсгал; өөрийн ledger-т reversal pattern
  хэрэгжүүл.

---

## BC-BIZ-002 — Документ lifecycle зөрчил

- **Severity:** HIGH
- **Rule:** Released/Pending Approval баримтын өгөгдлийг статус шалгалгүй өөрчлөх,
  статусыг Release/Reopen codeunit-гүйгээр гараар шилжүүлэх, approval шаардлагыг
  тойрох код илрүүлнэ.
- **Why:** Status::Released гэдэг нь validation бүрэн хийгдсэн + бизнес зөвшөөрөл
  өгөгдсөн төлөв. Сервис нь `TestStatusOpen`, `PerformManualRelease` (approval
  шалгалттай), `CheckSalesReleaseRestrictions` зэргээр хамгаалагдсан.
- **Risk:** Approve хийгдээгүй өөрчлөлт posting-д орох; warehouse-т аль хэдийн
  илгээгдсэн баримт зөрчилтэй болох.
- **Detection:** `Status :=` шууд assignment (Release/Reopen codeunit-ийн гадна);
  Sales/Purchase Line-ийн утга өөрчлөхөд TestStatusOpen/Validate байхгүй;
  `SetSkipCheckReleaseRestrictions` төрлийн bypass дуудлага.
- **Example — Bad:** erp-business-rules.md-ийн "Released захиалгыг чимээгүй Open болгох" жишээ.
- **Suggested Fix:** `Release Sales Document`/`Reopen`-ийг дууд; өөрчлөлтийн өмнө
  статус шалга; approval-тай баримтад ApprovalsMgmt шалгалт нэм.

---

## BC-BIZ-003 — Дүнгийн тооцооллын зөрчил (rounding/currency)

- **Severity:** HIGH
- **Rule:** Мөнгөн дүн тооцоолоход: Round precision-гүй, Currency-ийн rounding
  тохиргоог үл хэрэгсэх, LCY хөрвүүлэлтгүй/буруу огнооны ханштай, мөр бүр Round
  хийж хуримтлагдах зөрүү үүсгэх тооцоолол илрүүлнэ.
- **Why:** Base App: `Currency.Initialize`, "Amount Rounding Precision",
  remainder дамжуулах DivideAmount pattern, гүйлгээний огнооны ханш.
- **Risk:** Тэнцвэрийн зөрүү (rounding drift), НӨАТ зөрүү, валютын зөрүү.
- **Detection:** `Qty * Price` хэлбэрийн тооцоолол Round-гүйгээр Amount талбарт
  олгогдож байвал; CurrExchRate.ExchangeAmtFCYToLCY-д WorkDate() ашигласан
  (posting date биш); нийлбэрийг мөрөөр Round хийсэн.
- **Suggested Fix:** Currency-г Initialize хийж precision-ийг нь ашигла; ханшид
  Posting Date дамжуул; нийт дүнг нэг удаа Round хийж remainder хадгал.

---

## BC-BIZ-004 — Dimension алдагдал

- **Severity:** HIGH
- **Rule:** Custom бичилт/баримт үүсгэхэд эх баримтын "Dimension Set ID",
  Shortcut Dimension-ууд дамжуулагдахгүй, эсвэл dimension validation
  (CheckDimIDComb/CheckDimValuePosting) алгасагдаж байвал илрүүлнэ.
- **Why:** Dimension бүх бичилтийн аналитик тайлангийн суурь; Sales-Post
  `CheckDimensions.CheckSalesDim`-ийг заавал дууддаг.
- **Risk:** Тайлан дутуу; dimension mandatory тохиргоотой компанид posting алдаа.
- **Detection:** Gen. Journal Line үүсгэхдээ "Dimension Set ID" олгоогүй;
  DimMgt дуудлага байхгүй custom бичилт.
- **Suggested Fix:** Эх record-оос "Dimension Set ID"-г хуулж, шаардлагатай бол
  DimMgt.GetDefaultDimID-ээр default-уудыг нэгтгэ.

---

## BC-BIZ-005 — Мастер өгөгдлийн Blocked/статус шалгалт

- **Severity:** MEDIUM
- **Rule:** Customer/Vendor/Item/G-L Account/Bank Account ашиглах бичилт үүсгэхдээ
  Blocked, Privacy Blocked төлөв шалгаагүй бол илрүүлнэ.
- **Why:** Стандарт validation Blocked-ийг шалгадаг (Customer.Blocked::All,
  Item.Blocked, "Sales Blocked" гэх мэт) — гэхдээ Validate дуудаагүй шууд
  assignment эдгээрийг алгасна.
- **Risk:** Хориотой харилцагч/бараагаар гүйлгээ хийгдэх (комплаенсын зөрчил).
- **Detection:** `Line."No." := ItemNo` хэлбэрийн шууд assignment (Validate биш);
  journal бэлдэхэд CheckBlocked төрлийн дуудлага байхгүй.
- **Suggested Fix:** Validate ашигла; API/batch урсгалд Blocked шалгалт нэм.

---

## BC-BIZ-006 — Validate дараалал ба шууд assignment

- **Severity:** MEDIUM
- **Rule:** Хамааралтай талбаруудыг буруу дарааллаар Validate хийх (жишээ: Quantity-г
  "No."-ийн өмнө), эсвэл OnValidate-тэй талбарт шууд assignment хийж дагалдах
  тооцооллыг алгасаж байвал илрүүлнэ.
- **Why:** OnValidate-ууд гинжин тооцоололтой: "No." нь price/UOM-ийг, Quantity нь
  Amount-ийг шинэчилдэг. Дараалал эвдэрвэл эцсийн утга буруу.
- **Risk:** Буруу үнэ/дүн, хоосон posting group, warehouse шалгалт алгасах.
- **Detection:** Document line үүсгэж буй кодод Validate-ийн дараалал: Type →
  No. → Variant/Location → Quantity → Unit Price гэсэн стандарт дарааллаас зөрүү;
  тооцоололтой талбарт `:=`.
- **Suggested Fix:** Стандарт дарааллаар Validate; тест: UI-гаас үүсгэсэн мөртэй
  талбар бүрээр харьцуул.

---

## BC-BIZ-007 — Хэсэгчилсэн ship/invoice-ийн логик

- **Severity:** MEDIUM
- **Rule:** Захиалгын урсгалд Quantity = "Qty. to Ship" = "Qty. to Invoice" гэж
  таамагласан, эсвэл Outstanding/Shipped Not Invoiced хэмжээг тооцоогүй custom
  логик илрүүлнэ.
- **Why:** BC-ийн захиалга хэсэгчлэн ship/receive/invoice хийгддэг; стандарт код
  бүх тооцоололд "Qty. Shipped Not Invoiced", "Outstanding Quantity" зэрэг
  завсрын талбаруудыг ашигладаг.
- **Risk:** Хэсэгчилсэн posting-ийн дараа custom тайлан/integration зөрүү гарна.
- **Detection:** Quantity-г шууд ашигласан commission/статистик тооцоолол;
  давхар invoice-оос хамгаалах шалгалтгүй.
- **Suggested Fix:** Зөв quantity талбар сонго; хэсэгчилсэн сценариог тесттэй болго.
