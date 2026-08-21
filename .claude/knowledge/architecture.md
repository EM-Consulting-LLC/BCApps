# Architecture — Архитектурын мэдлэгийн сан

## 1. Зарчим

Business Central-ийн архитектур нь дараах суурь зарчмууд дээр тогтдог:

1. **Давхаргын нэг чиглэлт хамаарал:** System Application → Business Foundation →
   Base Application → Extension → Localization. Доод давхарга дээд давхаргын юуг ч мэдэхгүй.
2. **Journal → Ledger нэг суваг:** бүх санхүү, нөөц, өглөг/авлагын бичилт зөвхөн
   Post Line codeunit-уудаар (CU 12 Gen. Jnl.-Post Line, CU 22 Item Jnl.-Post Line гэх мэт)
   дамжин Ledger Entry болдог.
3. **UI логикоос ангид:** Page нь зөвхөн харагдац; бизнес логик Table validation болон
   Codeunit-д байрладаг.
4. **Extensibility-г урьдчилан төлөвлөсөн:** event, interface, enum extension-ээр
   өргөтгөх цэгүүдийг зориуд нээж өгсөн; base object-ыг өөрчлөхгүйгээр өргөтгөнө.
5. **Transaction consistency бол дархан зарчим:** нэг бизнес үйлдэл нэг transaction —
   бүрэн амжилттай эсвэл бүрэн rollback.

## 2. Source code дээрх ажиглалт

- `SalesOrder.Page.al`-ийн Post action нь ганц мөр: `PostSalesOrder(CODEUNIT::"Sales-Post (Yes/No)", ...)`.
  Page бизнес логик агуулдаггүй.
- `Sales-Post` (CU 80, 13 969 мөр) нь Check → Update → Post Lines → Finalize гэсэн
  тодорхой фазуудтай; бүх validation бичилт эхлэхээс өмнө хийгддэг.
- `Gen. Jnl.-Post Line`-ийн `FinishPosting`-д зургаан balance хэмжигдэхүүн 0 эсэхийг
  шалгаад `GLEntry.Consistent(IsTransactionConsistent)` дууддаг — тэнцвэргүй бичилт
  commit хийгдэх боломжгүй.
- Ledger хүснэгтэд бичих эрхийг posting codeunit-ууд `Permissions = TableData ... = rimd`
  property-оор өөртөө авдаг (жишээ: CU 80-ийн толгойд 20+ tabledata эрх зарлагдсан).
- System Application-ийн модуль бүр facade (`Access = Public`) + `... - Impl.`
  (`Access = Internal`) хос codeunit-тэй (жишээ: Business Foundation-ийн `No. Series` CU 310).
- 23 434 IntegrationEvent, 5 632 IsHandled шалгалт — extensibility нь системийн хэмжээнд
  жигд хэрэгжсэн.
- Модулиуд хоорондын нэмэлт функц event subscriber-ээр холбогддог
  (жишээ: `DocumentAttachmentMgmt` нь Sales Header-ийн table event-үүдэд subscribe хийдэг).

## 3. Яагаад ингэж хийсэн бэ (analysis)

- **Ganz ledger суваг** — санхүүгийн бүрэн бүтэн байдлыг ганц цэгт шалгах боломж олгодог.
  Хэрэв олон газраас G/L Entry бичдэг байсан бол balance, VAT, dimension шалгалт
  газар бүр давхардах байсан.
- **Validation урдаа** — бичилт эхэлсний дараа алдаа гарвал rollback том, түгжээ удаан
  барина; урьдчилан шалгаснаар transaction богино, амжилтын магадлал өндөр болно.
- **Facade + Impl** — public API-г тогтвортой байлгаж breaking change-ээс сэргийлнэ.
- **Permission property** — хэрэглэгчид ledger-ийн шууд эрх өгөхгүйгээр posting
  хийлгэх (least privilege + indirect permission).

## 4. Зөв хэрэгжилт

```al
// Page: зөвхөн delegate
trigger OnAction()
begin
    CODEUNIT.Run(CODEUNIT::"My Process (Yes/No)", Rec);
end;

// Ledger бичилт: стандарт posting engine-ээр
local procedure PostToGL(var GenJnlLine: Record "Gen. Journal Line")
var
    GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
begin
    GenJnlPostLine.RunWithCheck(GenJnlLine);
end;
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: Ledger Entry-г шууд бичих
local procedure CreateGLEntry()
var
    GLEntry: Record "G/L Entry";
begin
    GLEntry.Init();
    GLEntry."Entry No." := GetNextEntryNo();
    GLEntry.Amount := 100;
    GLEntry.Insert(); // balance, VAT, dimension, register — юу ч шалгагдахгүй!
end;

// БУРУУ: Page дээр бизнес логик
trigger OnAction()
var
    CustLedgEntry: Record "Cust. Ledger Entry";
begin
    CustLedgEntry.SetRange("Customer No.", Rec."No.");
    if CustLedgEntry.FindSet() then
        repeat
            CustLedgEntry."Remaining Amount" := 0; // санхүүгийн өгөгдлийг UI-аас гуйвуулж байна
            CustLedgEntry.Modify();
        until CustLedgEntry.Next() = 0;
end;
```

## 6. Code review хийх дүрэм

1. **[CRITICAL]** G/L Entry, Cust./Vendor Ledger Entry, Item Ledger Entry, Value Entry,
   VAT Entry, Bank Account Ledger Entry зэрэг ledger хүснэгтэд custom код шууд
   Insert/Modify/Delete хийж байвал зогсоо. Зөвхөн стандарт Post Line codeunit-ээр бичнэ.
2. **[HIGH]** Page/Page Extension дээр бизнес тооцоолол, өгөгдөл өөрчлөх урсгал байвал
   codeunit рүү нүүлгэхийг шаард (visibility, style, notification зэрэг UI логик зөвшөөрнө).
3. **[HIGH]** Custom код нь давхаргын хамаарлыг урвуулж байвал (жишээ нь суурь модулийг
   дээд модулиас хамааралтай болгох) анхааруул.
4. **[MEDIUM]** Гуравдагч талд зориулсан API гаргаж байгаа бол facade зарчим (public
   гадаргуу цөөн, тогтвортой; хэрэгжилт internal) баримталсан эсэхийг шалга.
5. **[MEDIUM]** Модулиуд хоорондын холбоос шууд хамаарал үүсгэж байвал event/interface
   ашиглах боломжтой эсэхийг ассесс хий.
6. **[LOW]** Public object/procedure устгах, нэр өөрчлөх бол Obsolete lifecycle
   (ObsoleteState = Pending → Removed) ашигласан эсэхийг шалга.
