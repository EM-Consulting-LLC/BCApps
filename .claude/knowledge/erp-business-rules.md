# ERP Business Rules — ERP-ийн бизнес аюулгүй байдлын мэдлэгийн сан

## 1. Зарчим

Business Central бол нягтлан бодох бүртгэлийн систем: бичилт бүр аудит, татвар,
санхүүгийн тайлангийн эх сурвалж. Тиймээс ердийн CRUD аппликейшнд байдаггүй
дархан дүрмүүд үйлчилнэ:

1. **Бичигдсэн зүйл өөрчлөгддөггүй** — ledger entry, posted document засварлахгүй;
   алдааг зөвхөн сөрөг/урвуу бичилтээр (reversal, credit memo, correction) залруулна.
2. **Давхар бичилт бол осол** — нэг баримт хоёр удаа бичигдвэл санхүүгийн тайлан худал болно.
3. **Тэнцвэр** — debit = credit; GL бичилт тэнцвэргүй бол огт бичигдэхгүй.
4. **Тасралтгүй аудит мөр** — No. Series, Register, Navigate бүх бичилтийг мөрдөх
   боломж олгоно.
5. **Тайлант үеийн хаалт** — Allow Posting From/To хязгаараас гадуур бичилт хийхгүй.

## 2. Source code дээрх ажиглалт

### Санхүүгийн consistency
- `GenJnlPostLine.FinishPosting`: 6 balance хэмжигдэхүүн 0 → `Consistent()` —
  тэнцвэргүй transaction DB-д орохгүй.
- Amount тооцоолол үргэлж `Currency.Initialize(CurrencyCode)` + rounding precision-тэй;
  LCY болон валютын дүн зэрэг хөтлөгдөнө (`TotalSalesLine`, `TotalSalesLineLCY`);
  rounding remainder-ийг дамжуулж хуримтлагдах зөрүөг арилгадаг
  (`TempVATAmountLineRemainder`).
- Dimension бүх бичилтэд дагалдана: Dimension Set ID header → line → ledger руу
  дамжина; `CheckDimensions` combination/value posting дүрмийг шалгана.
- VAT: бичилт бүр VAT Posting Setup-аас гарна, custom тооцоолол байхгүй.

### Документ lifecycle
- Status: Open → (Pending Approval) → (Pending Prepayment) → Released; Reopen эсрэгээр.
- `TestStatusOpen()` — Released баримтын мөр өөрчлөгдөхгүй.
- `CheckSalesReleaseRestrictions` / `CheckSalesPostRestrictions` — event-ээр
  approval workflow баримтыг Release/Post-оос хориглодог.
- Мөрийн validation-ууд аль хэдийн ship хийгдсэн хэмжээнээс доош бууруулахыг
  хориглодог (`FieldError(Quantity, ... "Quantity Shipped" ...)`).
- Posted баримт устгагдах тохиолдол маш хязгаарлагдмал (Allow Document Deletion
  тохиргоотой, печатласан гэх мэт нөхцөлтэй).

### Идемпотенц ба давхардлаас хамгаалалт
- Posting No. урьдчилан олгож хадгалаад, posted хүснэгтэд conflict шалгадаг.
- Vendor invoice-ийн External Document No. давхардлыг Vendor Ledger Entry-ээс шалгадаг.
- Job Queue Status флаг давхар schedule-ээс сэргийлдэг.
- Integration coupling бүртгэл давхар sync-ээс сэргийлдэг.
- Applies-to ID/Amount to Apply — apply хийгдсэний дараа цэвэрлэгддэг
  (UpdateAppliedCVLedgerEntries) — давхар application-аас сэргийлнэ.

### Урвуу бичилт (correction)
- Reversal: `Reversal Entry` — ledger бичилтийг сөрөг бичилтээр буцаадаг.
- Credit Memo + "Applies-to Doc." — борлуулалтын залруулга.
- Correction флаг — сөрөг debit/credit хэлбэрээр бичих сонголт.

## 3. Яагаад ингэж хийсэн бэ (analysis)

- Immutable ledger нь аудитын шаардлага: тайлан гаргасны дараа өнгөрсөн үеийн
  бичилт өөрчлөгдвөл тайлангууд хоорондоо зөрнө.
- Урьдчилсан дугаар олголт + conflict шалгалт: crash-ийн дараах давтан posting нь
  ижил дугаартай тул давхардал үүсгэдэггүй, дугаар ч алдагддаггүй (audit gap-гүй).
- Lifecycle шалгалтууд: Released = "бизнесийн зөвшөөрөл өгөгдсөн" — түүнээс хойш
  чимээгүй өөрчлөлт нь approval-ийг утгагүй болгоно.

## 4. Зөв хэрэгжилт

```al
// Posted баримтын залруулга — шинэ баримтаар
procedure CorrectPostedInvoice(SalesInvHeader: Record "Sales Invoice Header")
var
    CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
begin
    CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader); // стандарт cancel/corrective
end;

// Custom ledger-тэй бол: бичигдсэнийг өөрчлөхгүй, шинэ entry-ээр буцаана
procedure ReverseLoyaltyEntry(LoyaltyLedgEntry: Record "Loyalty Ledger Entry")
var
    NewEntry: Record "Loyalty Ledger Entry";
begin
    LoyaltyLedgEntry.TestField(Reversed, false);
    NewEntry.Init();
    NewEntry.CopyFromEntry(LoyaltyLedgEntry);
    NewEntry.Points := -LoyaltyLedgEntry.Points;      // сөрөг бичилт
    NewEntry."Reversed Entry No." := LoyaltyLedgEntry."Entry No.";
    NewEntry.Insert(true);
    LoyaltyLedgEntry.Reversed := true;                 // зөвхөн флаг — дүн өөрчлөгдөхгүй
    LoyaltyLedgEntry.Modify();
end;
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: posted баримт/ledger-ийг шууд засах
SalesInvLine.Get(DocNo, LineNo);
SalesInvLine."Unit Price" := NewPrice;   // posted invoice-ийн үнийг өөрчилж байна!
SalesInvLine.Modify();                    // G/L, VAT, Cust. Ledger-тэй зөрнө

// БУРУУ: Released захиалгыг чимээгүй Open болгож өөрчлөөд буцаах
SalesHeader.Status := SalesHeader.Status::Open;  // Reopen-ийн шалгалтуудыг тойрсон
SalesHeader.Modify();
SalesLine.Validate(Quantity, NewQty);
SalesLine.Modify(true);
SalesHeader.Status := SalesHeader.Status::Released; // approval дахин хийгдээгүй!
SalesHeader.Modify();

// БУРУУ: дүнг гараар, rounding/currency-гүй тооцоолох
Total := Qty * Price * (1 - Disc / 100);   // Round(...) байхгүй, ACY тооцоогүй
GenJnlLine.Amount := Total;                 // тэнцвэрийн зөрүү үүсгэж болзошгүй

// БУРУУ: dimension-гүй бичилт
GenJnlLine.Init();
GenJnlLine."Account No." := AccNo;
GenJnlLine.Amount := Amt;                  // "Dimension Set ID" хоосон —
GenJnlPostLine.RunWithCheck(GenJnlLine);   // аналитик тайлан дутуу болно
```

## 6. Code review хийх дүрэм

1. **[CRITICAL]** Posted document / ledger entry-ийн санхүүгийн утга (дүн, тоо,
   огноо, данс) Modify хийгдэж байвал. (Тайлбар талбар, холбоос ID зэрэг
   non-financial талбарын шинэчлэл стандартад ч байдаг — ялгаж үнэл.)
2. **[CRITICAL]** Давтан ажиллахад давхар баримт/бичилт үүсгэх урсгал (идемпотенц
   шалгалтгүй posting, integration, job queue).
3. **[HIGH]** Status/lifecycle-ийг тойрсон өөрчлөлт: Released баримт дээр
   TestStatusOpen-гүй засвар, статус гараар шилжүүлэлт, approval-ийг алгасах зам.
4. **[HIGH]** Гараар дүн тооцоолол: Round-гүй, Currency precision-гүй, LCY/ACY
   зөрүүтэй, эсвэл rounding remainder дамжуулалгүй мөр тус бүр Round хийж
   хуримтлагдах зөрүү үүсгэх.
5. **[HIGH]** Dimension дамжуулалгүй бичилт (Dimension Set ID алдагдах) —
   аналитик тайлан эвдэрнэ.
6. **[HIGH]** Хаагдсан үе рүү бичих боломж: Posting Date-ийг Allow Posting
   хязгаараар шалгаагүй custom бичилт.
7. **[MEDIUM]** Custom ledger хүснэгттэй бол: Entry No. дараалал, Reversed флаг,
   Register/Navigate холболт, огноо+dimension талбарууд стандарт ledger-ийн
   загварыг дагасан эсэх.
8. **[MEDIUM]** Валютын ханш огноо: гүйлгээний огнооны ханш биш өнөөдрийн ханш
   ашигласан бол.
9. **[MEDIUM]** Document No./External Document No. давхардлын бизнес шалгалт
   шаардлагатай урсгалд байхгүй бол.
