# Posting Reference — Бичилтийн урсгалын шалгалт

## Стандарт posting-ийн бүтэц (Sales-Post CU 80-аас)

```text
Check (бүх validation: mandatory, posting date хязгаар, VAT date, dimensions,
       post restrictions, item charge)
→ Prepare (Posting No. олгох + хадгалах + conflict шалгах; Commit*; Release;
           Archive; LockTables; posted headers)
→ Post Lines (мөр бүр: ItemJnlPostLine / GenJnlPostLine / ResJnlPostLine;
              GL нь temp буферээр, FinishPosting-д нэг дор)
→ Finalize (баримт шинэчлэх/устгах; Preview бол ThrowError = бүрэн rollback)
→ Commit (зөвхөн: not SuppressCommit, not PreviewMode, not InvtPickPutaway)
```

Гол баталгаанууд:
- Validation бүгд бичилтийн ӨМНӨ.
- Posting No. нэг удаа олгогдож header-т хадгалагдана → давтан post ижил дугаартай,
  давхардахгүй; posted хүснэгтэд Get-ээр conflict шалгадаг.
- LockTable validation-ий дараа, бичилтийн өмнө.
- SuppressCommit/PreviewMode бүх Commit-ийн өмнө шалгагдана.
- Progress Window зөвхөн GuiAllowed.

## Дүрмүүд

### BC-POST-001 [CRITICAL] — Давхар бичилтийн эрсдэл
Бичилт үүсгэдэг урсгал давтан ажиллахад давхардахаас хамгаалагдаагүй:
"аль хэдийн бичигдсэн" шалгалт байхгүй, дугаар/түлхүүр урьдчилан хадгалагддаггүй,
статус хамгаалалтгүй. OnAfterPost* subscriber-т бичилт хийж байвал preview +
давтан post-д хэдэн удаа дуудагдахыг үнэл. **Засвар:** existence/status шалгалт +
LockTable; эх баримтад Posted флаг/Entry No.

### BC-POST-002 [CRITICAL] — Ledger-т шууд бичилт
(= BC-ARCH-001) Стандарт Post Line codeunit-ээр л бич.

### BC-POST-003 [HIGH] — Бичилтийн дараах validation
Insert/post эхэлснээс хойш TestField/Error нөхцөл → Check фазыг урд тусгаарла.

### BC-POST-004 [HIGH] — No. Series зөрчил
FindLast + 1 буюу өөрийн counter (race + gap); NoSeries.GetNextNo-г давтан дуудаад
хадгалдаггүй (дугаар гоожно). **Засвар:** No. Series ашигла; олгосон дугаараа
header-т хадгалж дахин ашигла; Entry No.-д AutoIncrement/sequence.

### BC-POST-005 [MEDIUM] — Locking дутуу/буруу
Check-then-act түгжээгүй (давхар бичилтийн race); эсвэл хэт эрт LockTable + удаан
validation. **Засвар:** идемпотенц шалгалтын өмнө LockTable; validation түгжээний өмнө.

### BC-POST-006 [HIGH] — Posting subscriber-ийн зөрчил
OnBefore/OnAfterPost* subscriber дотор: Commit, UI dialog, HTTP, өөр баримтын
posting, unrelated Error, PreviewMode үл тоох. **Засвар:** queue табл + Job Queue;
PreviewMode бол exit.

### BC-POST-007 [MEDIUM] — Batch-ийн алдааны тусгаарлалт
Batch loop-д шууд Post (нэг алдаа бүгдийг зогсооно) эсвэл алдааг бүртгэлгүй залгих.
**Засвар:** `if not Codeunit.Run(...) then begin Log; Commit; end` + үргэлжлүүлэлт.

## Ялгаж салгах (false positive-оос сэргийлэх)

- Journal batch-ийн баримт хоорондын Commit — стандарт, зөв (баримт бүр бүрэн нэгж).
- Job Queue status-ийн LockTable+Modify+Commit — стандарт pattern.
- OnAfterPostSalesDoc дээр queue бичлэг Insert (Commit-гүй) — зөв outbox хэлбэр.
- InvoicePostingInterface / SalesPostInvoice ашигласан бол стандарт зам —
  зөвхөн параметрүүд (SuppressCommit, PreviewMode) зөв дамжсан эсэхийг шалга.
