# Posting Patterns — Бичилтийн хэв маягийн мэдлэгийн сан

## 1. Зарчим

Posting бол BC-ийн хамгийн эмзэг үйлдэл: эргэлт буцалтгүй санхүүгийн бичилт үүсгэдэг.
Microsoft-ийн бүх posting engine (Sales, Purchase, Gen. Journal, Item Journal,
Warehouse, FA, Job, Service) ижил хэлбэрийн фазтай:

```text
Check (бүх validation) → Prepare (дугаар, түгжээ, posted header)
→ Post Lines (ledger бичилт) → Finalize (баримт шинэчлэх/устгах) → Commit
```

Гол дүрэм: **бичилт эхэлсний дараа business validation алдаа гарах ёсгүй** —
бүх шалгалт эхэнд; Commit зөвхөн бүрэн төлөвт.

## 2. Source code дээрх ажиглалт (Sales-Post, CU 80)

1. **Check фаз:** `CheckSalesDocument` — mandatory fields, Posting Date-ийн хязгаар,
   VAT Date, dimensions, CheckPostRestrictions (approval-ийн event), item charge,
   drop shipment уялдаа, электрон баримт. Бүгд ErrorMessageMgt контексттэй.
2. **Дугаар олголт (идемпотенцийн гол цэг):**
   - `UpdatePostingNos` — "Posting No." хоосон үед л No. Series-ээс авна.
   - Авсан дугаараа `SalesHeader.Modify()` + `Commit()`-оор шууд хадгална (SuppressCommit биш үед).
   - **Дараа нь алдаа гарч дахин post хийвэл хадгалагдсан дугаараа дахин ашиглана** —
     давхар дугаар зарцуулахгүй, давхар баримт үүсгэхгүй.
   - Conflict шалгалт: `if SalesInvHeader.Get(SalesHeader."Posting No.") then Error(...)` —
     posted хүснэгтэд аль хэдийн байвал зогсооно.
3. **LockTables** — validation-ийн дараа, бичилтийн өмнө: SalesLine, PurchLine LockTable;
   legacy горимд GLEntry.LockTable + GetLastEntryNo.
4. **Мөрийн бичилт:** Item мөр → `ItemJnlPostLine` (ILE + Value Entry), G/L мөр → IC buffer,
   Resource → ResJnlPostLine гэх мэт. Бүгд нэг transaction дотор.
5. **Invoice бичилт:** `InvoicePostingInterface` (enum-оор сонгогдсон хэрэгжилт) →
   `GenJnlPostLine` → Cust. Ledger Entry + VAT Entry + G/L Entry. GL entries эхлээд
   TempGLEntryBuf-д цугларч `FinishPosting`-д нэг дор Insert хийгдэнэ.
   Balance 0 биш бол `GLEntry.Consistent(false)` — commit боломжгүй.
6. **FinalizePosting:**
   - Order бүрэн invoice-логдоогүй → үлдэгдэл хэмжээ шинэчилнэ (PostUpdateOrderLine).
   - Бүрэн бол → баримтыг устгана (DeleteAfterPosting), archive хийнэ.
   - PreviewMode → `GenJnlPostPreview.ThrowError()` — бүх зүйл rollback.
   - Төгсгөлд: `if not (InvtPickPutaway or SuppressCommit or PreviewMode) then Commit()`.
7. **Progress Window:** зөвхөн `GuiAllowed() and not HideProgressWindow`.
8. **Batch/Job Queue integration:** `SuppressCommit` флагаар гадна transaction-ийг
   удирдана; `Sales Post via Job Queue` нь Job Queue Status-ыг LockTable+Modify+Commit-оор
   тэмдэглэж давхар schedule-ээс сэргийлдэг.

### Journal posting (Gen. Jnl.-Post Batch)
- Batch бүх мөрөө нэг transaction-д post хийгээд төгсгөлд Commit.
- Хоосон batch үед эрт Commit + exit.
- `StartPosting`/`ContinuePosting`/`FinishPosting` API — олон баримт/мөр нэг
  register дор бичигдэнэ.

### Item Journal
- `ItemJnlCheckLine.RunCheck` бичилтийн өмнө; `ItemJnlPostLine` нь Item, ILE,
  Value Entry, Capacity зэрэгт өргөн Permissions property-той.
- Quantity ба Value (өртөг) тусдаа бичигддэг — costing дараа нь
  `MakeInventoryAdjustment`-аар тохируулагддаг.

## 3. Яагаад ингэж хийсэн бэ (analysis)

- Дугаарыг урьдчилан хадгалах + conflict шалгах нь **crash/error-ийн дараах дахин
  оролдлогыг идемпотент** болгодог — ERP-д давхар нэхэмжлэх бол ноцтой осол.
- Буфердсэн GL бичилт + Consistent флаг нь тэнцвэргүй бичилтийг зарчмын хувьд
  боломжгүй болгодог.
- SuppressCommit нь дуудагч (batch, job queue, өөр posting) transaction-ийн эзэн
  байх боломж олгодог — иймд **custom код posting дуудахдаа SuppressCommit-ийн
  семантикийг эвдэж болохгүй**.

## 4. Зөв хэрэгжилт (custom posting routine)

```al
procedure PostLoyaltyBatch(var LoyaltyLine: Record "Loyalty Journal Line")
begin
    // 1. Check фаз — бүх мөрийг эхлээд шалгана
    if LoyaltyLine.FindSet() then
        repeat
            CheckLoyaltyLine(LoyaltyLine);
        until LoyaltyLine.Next() = 0;

    // 2. Түгжээ
    LoyaltyLedgerEntry.LockTable();

    // 3. Бичилт — нэг transaction
    if LoyaltyLine.FindSet() then
        repeat
            InsertLedgerEntry(LoyaltyLine);
        until LoyaltyLine.Next() = 0;

    // 4. Finalize + цэвэрлэгээ
    LoyaltyLine.DeleteAll(true);
    // 5. Commit-ийг дуудагчид үлдээх эсвэл яг энд, бүрэн төлөвт хийх
end;
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: мөр бүрийн дараа Commit — алдаа гарвал хагас batch бичигдсэн үлдэнэ
repeat
    InsertLedgerEntry(LoyaltyLine);
    Commit();  // ← 5 дахь мөрөнд алдаа гарвал 4 нь бичигдсэн, эх баримт устаагүй
until LoyaltyLine.Next() = 0;

// БУРУУ: бичилтийн дундуур validation
repeat
    InsertLedgerEntry(LoyaltyLine);
    LoyaltyLine.TestField("Reason Code"); // ← бичилтийн ДАРАА шалгаж байна
until LoyaltyLine.Next() = 0;

// БУРУУ: дугаарыг бичилт бүрт шинээр авах
LedgerEntry."Document No." := NoSeries.GetNextNo(SetupNoSeries, WorkDate());
// алдаа → дахин post → шинэ дугаар → conflict шалгах боломжгүй, дугаар "гоождог"

// БУРУУ: Posted гэдгийг тэмдэглэхгүй давтан post хийх боломж үлдээх
procedure PostRebate(SalesInvHeader: Record "Sales Invoice Header")
begin
    // "аль хэдийн rebate бичигдсэн үү?" шалгалт байхгүй —
    // хоёр удаа дуудвал давхар G/L бичилт
    PostRebateToGL(SalesInvHeader);
end;
```

## 6. Code review хийх дүрэм

1. **[CRITICAL]** Давтан ажиллуулахад давхар бичилт үүсгэх posting логик:
   "аль хэдийн бичигдсэн" төлөв/дугаар/existence шалгалт байхгүй бол зогсоо.
2. **[CRITICAL]** Posting урсгал дундуур Commit — хагас бичилтийн эрсдэл.
   Commit зөвхөн бүрэн, уялдаатай төлөвт байх ёстой.
3. **[HIGH]** Validation бичилт эхэлсний дараа хийгдэж байвал урд шилжүүл.
4. **[HIGH]** Custom код Sales-Post/Purch.-Post/GenJnlPostLine-ийг дуудахдаа
   SetSuppressCommit/SetPreviewMode дамжуулах ёстой контекст (batch, preview)
   байхад дамжуулаагүй бол.
5. **[HIGH]** Posting-той subscriber (OnBeforePost.../OnAfterPost...) дотор Commit,
   Confirm, удаан үйлдэл, unrelated Error байвал.
6. **[MEDIUM]** LockTable-ийг огт хийгээгүй (олон хэрэглэгчийн орчинд давхар
   бичилт/дугаарын зөрчил) эсвэл хэт эрт хийсэн (түгжээ урт барина).
7. **[MEDIUM]** Дугаар олголт No. Series-ээр биш өөрийн counter-оор хийгдэж байвал
   (concurrency + audit асуудал).
8. **[MEDIUM]** Progress dialog GuiAllowed-гүй нээгдэж байвал (background posting унана).
