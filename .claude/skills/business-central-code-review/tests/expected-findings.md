# Туршилтын fixture-ийн хүлээгдэж буй findings

`tests/fixture/` доторх 4 файл нь зориудын алдаа бүхий туршилтын код юм.
Skill-ийг энэ fixture дээр ажиллуулахад дор хаяж дараах findings илрэх ёстой.
(Skill-ийг өөрчилсний дараа энэ fixture-ээр регресс шалгалт хий.)

## RebatePost.Codeunit.al

| Rule | Severity | Алдаа |
|---|---|---|
| BC-POST-001 | CRITICAL | PostRebateForInvoice-д "аль хэдийн rebate бичигдсэн үү" шалгалт байхгүй — давтан дуудлагад давхар бичилт |
| BC-TXN-001 | CRITICAL | Rebate Ledger Entry Insert-ийн дараа, GL бичилтийн ӨМНӨ Commit — GL унавал хагас гүйлгээ |
| BC-POST-004 | HIGH | Entry No. = FindLast+1 (GetLastEntryNo) LockTable-гүй — зэрэгцээ ажиллагаанд мөргөлдөнө |
| BC-AL-001 | HIGH | Confirm() GuiAllowed-гүй — subscriber/background-аас дуудагдвал унана |
| BC-BIZ-003 | HIGH | RebateAmount Round-гүй; Posting Date-д invoice-ийн огноо биш WorkDate |
| BC-BIZ-004 | HIGH | GenJnlLine-д Dimension Set ID дамжуулаагүй |
| BC-BIZ-006 | MEDIUM | GenJnlLine талбарууд Validate-гүй шууд assignment; Document Type, Source Code байхгүй |
| BC-PERM-002 | HIGH | Permissions property-д G/L Entry, Cust. Ledger Entry = rimd — codeunit өөрөө бичдэггүй (GL нь CU 12-оор) |
| BC-PERF-002 | HIGH | RecalculateAllRebates: Sales Invoice Header filter-гүй бүрэн scan |
| BC-PERF-001 | HIGH | Loop дотор SetRange+FindFirst (Customer) — Get + cache байх ёстой |
| BC-PERF-005 | MEDIUM | Loop дотор мөр бүрт Customer.CalcFields("Balance (LCY)") — ашиглагдаагүй ч тооцоолагдана |
| BC-AL-008 | HIGH | GetRebateAccount() hardcoded '998877' данс — Setup-аас авах ёстой |
| BC-AL-002 | MEDIUM | Confirm-ийн текст hardcoded (Label биш) |

## RebateSubscribers.Codeunit.al

| Rule | Severity | Алдаа |
|---|---|---|
| BC-EVT-001 | CRITICAL | OnAfterPostSalesDoc subscriber дотор Commit |
| BC-POST-006 | HIGH | Subscriber-т синхрон rebate бичилт + Confirm (RebatePost-оор дамжин); PreviewMode/SuppressCommit параметрүүд аваагүй, шалгаагүй |
| BC-EVT-004 | HIGH | OnAfterValidateEvent(Quantity) дотор бүх мөрөө Validate+Modify — Quantity validate бүрт бүх баримт дахин бичигдэнэ, гинжин event/рекурсын эрсдэл |
| BC-EVT-003 | CRITICAL | OnBeforeUpdatePostingNo-д IsHandled := true болзолгүй — БҮХ баримтын дугаар олголтыг орлоно, бусад extension унтарна |
| BC-POST-004 | CRITICAL | Timestamp-аар дугаар үүсгэх — No. Series биш: мөргөлдөх боломжтой, conflict шалгалтгүй, дахин post хийхэд өөр дугаар (идемпотенц эвдэрнэ) |
| BC-EVT-002 | MEDIUM | Subscriber-уудад IsTemporary/хоосон түлхүүр guard байхгүй |

## RebateWebhookAPI.Page.al

| Rule | Severity | Алдаа |
|---|---|---|
| BC-SEC-001 | CRITICAL | Hardcoded 'Bearer sk-live-...' token |
| BC-INT-001 / BC-API-004 | CRITICAL | externalPaymentId-аар давхардал шалгаагүй — API retry давхар journal мөр үүсгэнэ |
| BC-TXN-004 | HIGH | Insert хийснийхээ дараа (uncommitted) transaction дотор HTTP Post |
| BC-INT-002 | HIGH | HTTP Response статус огт шалгаагүй |
| BC-SEC-005 | HIGH | http:// endpoint (TLS-гүй) |
| BC-API-002 | MEDIUM | ODataKeyFields = "Line No." (SystemId биш); DelayedInsert байхгүй |
| BC-POST-004 | MEDIUM | GetNextLineNo FindLast+10000 — зэрэгцээ хүсэлтэд мөргөлдөнө |
| BC-AL-008 | MEDIUM | 'GENERAL'/'REBATE' journal template/batch hardcoded |

## RebatePermissions.PermissionSet.al

| Rule | Severity | Алдаа |
|---|---|---|
| BC-PERM-001 | CRITICAL | G/L Entry, Cust. Ledger Entry = RIMD (direct) — хэрэглэгч ledger шууд засна |
| BC-BIZ-001 / BC-PERM-001 | CRITICAL | Sales Invoice Header = RIMD — posted баримт шууд засах эрх |

## Багцын түвшинд

| Rule | Severity | Алдаа |
|---|---|---|
| BC-TEST-001 | MEDIUM | Бичилтийн логикт ямар ч тест байхгүй |
| BC-TEST-003 | MEDIUM | Идемпотенцийн тест байхгүй (rebate давтан, API retry) |

**Final Verdict (хүлээгдэж буй):** BLOCKED (олон CRITICAL).
