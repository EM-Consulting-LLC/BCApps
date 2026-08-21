# Posting Review Rules — BC-POST

> Posting болон санхүүгийн бичилттэй холбоотой өөрчлөлтөд хамгийн өндөр анхаарал
> хандуулна. Эдгээр дүрэм Sales-Post (CU 80), Gen. Jnl.-Post Line (CU 12),
> Item Jnl.-Post Line (CU 22)-ийн бодит хэрэгжилтээс гаргасан болно.

---

## BC-POST-001 — Duplicate posting risk (давхар бичилтийн эрсдэл)

- **Severity:** CRITICAL
- **Rule:** Ledger/journal бичилт үүсгэдэг урсгал давтан ажиллахад давхар бичилт
  үүсгэхээс хамгаалагдаагүй бол илрүүлнэ.
- **Why:** Microsoft-ийн posting: дугаар урьдчилан олгож хадгалдаг + posted
  хүснэгтэд conflict шалгадаг + статус флагаар давхар schedule хориглодог.
  Эдгээрийн аль нь ч байхгүй custom бичилт нь давтагдахад давхардана.
- **Risk:** Давхар нэхэмжлэх, давхар орлого — санхүүгийн тайлан худал, аудитын осол.
- **Detection:** Custom posting/бичилт үүсгэх procedure-д: (1) "аль хэдийн
  бичигдсэн" төлөв/existence шалгалт, (2) давтан оролдлогод ижил үр дүн өгөх
  дугаар/түлхүүрийн механизм, (3) job queue/API-аас дуудагдах бол статус хамгаалалт
  байгаа эсэхийг шалга. OnAfterPost* subscriber-т бичилт хийж байвал preview/
  давтан post-ийн үед хэд дуудагдахыг үнэл.
- **Example — Bad:**
  ```al
  procedure PostCommission(SalesInvHeader: Record "Sales Invoice Header")
  begin
      GenJnlLine.Init(); // ижил invoice-д хоёр удаа дуудвал хоёр бичилт!
      ...
      GenJnlPostLine.RunWithCheck(GenJnlLine);
  end;
  ```
- **Example — Good:**
  ```al
  procedure PostCommission(SalesInvHeader: Record "Sales Invoice Header")
  var
      CommissionEntry: Record "Commission Entry";
  begin
      CommissionEntry.SetRange("Invoice No.", SalesInvHeader."No.");
      if not CommissionEntry.IsEmpty() then
          exit; // идемпотенц: аль хэдийн бичигдсэн
      ...
  end;
  ```
- **Suggested Fix:** Бичилтийн эх сурвалж руу "Posted"/"Entry No." талбар нэмэх
  эсвэл өөрийн entry хүснэгтээс existence шалгах; шалгалт + бичилтийг нэг
  transaction-д хийж race-ээс LockTable-аар хамгаал.

---

## BC-POST-002 — Direct ledger write (ledger хүснэгтэд шууд бичилт)

- **Severity:** CRITICAL
- **Rule:** G/L Entry, VAT Entry, Cust./Vendor/Employee Ledger Entry, Item Ledger
  Entry, Value Entry, Bank Account Ledger Entry, Detailed * Ledger Entry зэрэгт
  custom код шууд Insert/Modify/Delete хийж байвал илрүүлнэ.
- **Why:** Стандарт Post Line codeunit-ууд balance шалгалт (Consistent), VAT,
  dimension, register, дугаарлалт, apply зэргийг нэг цэгт хийдэг. Шууд бичилт
  эдгээрийг бүгдийг алгасна.
- **Risk:** Тэнцвэргүй GL, register-гүй бичилт, Navigate/audit эвдрэл, TAX тайлан зөрүү.
- **Detection:** Ledger хүснэгтийн Record хувьсагч дээр Insert/Modify/Delete/
  ModifyAll/DeleteAll; Rename бол бүр ноцтой.
- **Example — Bad:**
  ```al
  GLEntry.Init();
  GLEntry."Entry No." := LastEntryNo + 1;
  GLEntry.Amount := Amount;
  GLEntry.Insert();
  ```
- **Example — Good:**
  ```al
  GenJnlLine.Init();
  GenJnlLine.Validate("Account No.", AccNo);
  GenJnlLine.Validate(Amount, Amount);
  ...
  GenJnlPostLine.RunWithCheck(GenJnlLine);
  ```
- **Suggested Fix:** Gen. Journal Line бэлдэж `Gen. Jnl.-Post Line`-ээр, item
  хөдөлгөөнийг Item Journal Line + `Item Jnl.-Post Line`-ээр бич.

---

## BC-POST-003 — Validation after write (бичилтийн дараах шалгалт)

- **Severity:** HIGH
- **Rule:** Posting урсгалд ledger/posted өгөгдөл бичигдэж эхэлснээс хойш business
  validation (TestField, Error нөхцөл) хийгдэж байвал илрүүлнэ.
- **Why:** Стандарт бүтэц: бүх Check эхэнд (CheckSalesDocument бүх мөрийг бичилт
  эхлэхээс өмнө шалгадаг). Дундах алдаа rollback-аар хамгаалагдана гэсэн ч Commit
  нэмэгдвэл эмзэг болно; мөн урт transaction-д түгжээ уддаг.
- **Risk:** Commit-тэй хослоход хагас бичилт; урт rollback.
- **Detection:** Post/Insert хийсний дараах TestField/Error; ялангуяа loop дотор
  "бичээд шалгах" дараалал.
- **Example — Bad:** (posting-patterns.md-ийн жишээ) мөр бичсэний дараа
  `LoyaltyLine.TestField("Reason Code")`.
- **Example — Good:** Бүх мөрийг эхлээд Check loop-оор шалгаад, дараа нь Post loop.
- **Suggested Fix:** Check фазыг тусгаарлаж бичилтийн өмнө бүрэн гүйцэтгэ.

---

## BC-POST-004 — No. Series зөрчил

- **Severity:** HIGH
- **Rule:** Баримт/бичилтийн дугаарыг No. Series-ээс гадуур (өөрийн counter, max+1,
  random) олгож байвал, эсвэл дугаар авсныг хадгалалгүй алдаж байвал илрүүлнэ.
- **Why:** No. Series нь concurrency-safe, аудит мөртэй, тохиргоогоор удирдагддаг.
  Max+1 нь зэрэгцээ хэрэглэгчдэд мөргөлдөнө; авсан дугаараа хадгалахгүй бол алдааны
  дараа дугаар "гоожно" (audit gap).
- **Risk:** Давхар дугаар, дугаарын цоорхой, татварын шаардлага зөрчигдөх.
- **Detection:** `FindLast` + `"No." + 1` хэлбэр; NoSeries.GetNextNo-г transaction
  бүрт дахин дуудах; posting-д авсан дугаараа header-т хадгалаагүй байх.
- **Example — Bad:**
  ```al
  LoyaltyEntry.FindLast();
  NewNo := IncStr(LoyaltyEntry."Document No."); // race + gap
  ```
- **Example — Good:**
  ```al
  if Header."Posting No." = '' then begin
      Header."Posting No." := NoSeries.GetNextNo(Setup."Posting Nos.", Header."Posting Date");
      Header.Modify();
  end; // дахин post хийхэд ижил дугаар
  ```
- **Suggested Fix:** No. Series codeunit ашигла; олгосон дугаарыг эх баримтад
  хадгалж дахин ашигла; Entry No.-д AutoIncrement эсвэл Number Sequence ашигла.

---

## BC-POST-005 — Locking дутуу/буруу

- **Severity:** MEDIUM
- **Rule:** Олон хэрэглэгч зэрэг ажиллах бичилтийн урсгалд LockTable огт байхгүй
  (давхар бичилт/дугаар мөргөлдөх боломж) эсвэл процессын хамгийн эхэнд түгжиж
  удаан validation хийж байвал илрүүлнэ.
- **Why:** Sales-Post: validation бүрэн дууссаны ДАРАА LockTables дууддаг —
  түгжээ богино, гэхдээ бичилт хамгаалагдсан.
- **Risk:** Deadlock, lock timeout, эсвэл race-ийн улмаас давхар бичилт.
- **Detection:** "Шалгаад бичих" (check-then-act) урсгалд шалгалт ба бичилтийн
  хооронд өөр session өгөгдөл өөрчилж болох цэг; LockTable-ийн байрлал.
- **Example — Bad:**
  ```al
  if not DuplicateExists() then begin   // түгжээгүй шалгалт
      // ← энэ хооронд өөр session ижил бичилт хийж болно
      Entry.Insert();
  end;
  ```
- **Example — Good:**
  ```al
  Entry.LockTable();
  if not DuplicateExists() then
      Entry.Insert();
  ```
- **Suggested Fix:** Идемпотенц шалгалтын өмнө LockTable; validation-ийг түгжээний
  өмнө, бичилтийг дараа нь байрлуул.

---

## BC-POST-006 — Posting subscriber-ийн зөрчил

- **Severity:** HIGH
- **Rule:** OnBefore/OnAfter posting event-ийн subscriber дотор: Commit, UI dialog,
  гадаад HTTP, өөр баримтын posting, unrelated Error байвал илрүүлнэ.
- **Why:** Subscriber нь posting transaction-ий НЭГ ХЭСЭГ: түүний алдаа бүх posting-ийг
  унагана, Commit нь rollback-ийг эвдэнэ, удаан үйлдэл түгжээг сунгана.
- **Risk:** Posting бүхэлдээ тогтворгүй болно; PreviewMode-д бодит бичилт үлдэж болно.
- **Detection:** `OnBeforePost*`/`OnAfterPost*`/`OnBeforeFinalize*` subscriber-ийн
  биед Commit/Confirm/HttpClient/Codeunit.Run(Post*); PreviewMode параметр
  ашиглаагүй бичилт.
- **Example — Bad / Good:** events-extensibility.md-г үз.
- **Suggested Fix:** Хүнд/гадаад үйлдлийг OnAfterPostSalesDoc дээр queue хүснэгтэд
  бичээд Job Queue-ээр гүйцэтгэ; PreviewMode бол exit.

---

## BC-POST-007 — Батч posting-ийн алдааны тусгаарлалт

- **Severity:** MEDIUM
- **Rule:** Олон баримт дараалан post хийдэг custom batch-д нэг баримтын алдаа бүх
  batch-ыг унагаж байвал (эсвэл эсрэгээр — алдааг залгиад бүртгэхгүй байвал) илрүүлнэ.
- **Why:** Стандарт batch: `if Codeunit.Run(Codeunit::"Sales-Post", ...) then` +
  алдааг Job Queue status/log-д бүртгэж үргэлжилдэг.
- **Risk:** Нэг эвдэрхий баримт бүх өдрийн posting-ийг блоклох; эсвэл чимээгүй
  алгасагдсан баримтууд.
- **Detection:** Batch loop дотор шууд Post дуудлага (Codeunit.Run биш) — нэг алдаа
  бүгдийг зогсооно; Codeunit.Run + else-гүй (лог байхгүй).
- **Example — Good:**
  ```al
  repeat
      if not Codeunit.Run(Codeunit::"Sales-Post", SalesHeader) then begin
          LogPostingError(SalesHeader, GetLastErrorText());
          Commit(); // лог хадгалаад дараагийн баримт
      end;
  until SalesHeader.Next() = 0;
  ```
- **Suggested Fix:** Баримт бүрийг Codeunit.Run-аар тусгаарлаж, алдааг бүртгэж,
  бусад баримтыг үргэлжлүүл.
