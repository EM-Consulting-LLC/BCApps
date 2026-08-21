# Transaction Patterns — Transaction ба COMMIT-ийн мэдлэгийн сан

## 1. Зарчим

AL-д transaction нь implicit: trigger/процесс дуусахад автоматаар commit хийгдэнэ,
Error() гарвал автоматаар rollback хийгдэнэ. Тиймээс:

- **Commit() бол transaction-ийн хамгаалалтыг таслах зориудын шийдвэр** — 8081 файлд
  ердөө ~1000 удаа, бүгд тодорхой шалтгаантай.
- Commit хийсэн цэгээс өмнөх өөрчлөлт **эргэж буцахгүй** — түүнээс хойшхи алдаа
  зөвхөн үлдсэн хэсгийг rollback хийнэ → хагас гүйлгээ (partial transaction) үүсч болзошгүй.
- Microsoft Commit-ийг хязгаарлах платформын хэрэгслүүд гаргасан:
  `[CommitBehavior(CommitBehavior::Ignore)]`, `[CommitBehavior(CommitBehavior::Error)]`,
  `SuppressCommit` флаг, `PostingPreviewEventHandler.PreventCommit()`.

## 2. Source code дээрх ажиглалт — Commit-ийн legitimate хэрэглээнүүд

| Хэрэглээ | Жишээ | Шалтгаан |
|---|---|---|
| **Checkpoint дугаар олгосны дараа** | SalesPost.CheckAndUpdate: Posting No. олгоод Modify+Commit | Дараагийн алдаанд дугаар хадгалагдаж идемпотенц хангана |
| **Posting бүрэн дууссаны дараа** | SalesPost эцсийн `if not (InvtPickPutaway or SuppressCommit or PreviewMode) then Commit()` | Бүрэн төлөв, дараагийн analysis view update тусдаа |
| **Batch мөр/баримт хоорондын checkpoint** | GenJnlPostBatch, InsuranceJnlPostBatch | Баримт бүр өөрөө бүрэн нэгж |
| **Codeunit.Run-ийн өмнө** | Job Queue: SetJobQueueStatus (Modify+Commit) дараа нь Codeunit.Run | Платформ uncommitted өөрчлөлттэй Codeunit.Run хориглодог |
| **Гадаад дуудлагын өмнө төлөв хадгалах** | API PostAndSend: Post → Commit → Send email | Email илгээлт унасан ч posted баримт хадгалагдана |
| **Integration checkpoint** | IntegrationRecSynchInvoke.InsertRecord: coupling бичээд Commit | Sync тасалдвал хийсэн хэсэг нь coupling-оор тэмдэглэгдсэн — дахин sync давхардуулахгүй |
| **UI сонголтын өмнө** | Report асуухын өмнө, page нээхийн өмнө | Хэрэглэгч удаан байх үед түгжээ барихгүй |
| **Log бичилт хадгалах** | ImportConsolidationFromAPI.LogRequest...Commit | Алдаа гарсан ч лог үлдэнэ |

### Commit-ийг хориглох хэрэгслүүд

- `ProcessPosting` → `[CommitBehavior(CommitBehavior::Ignore)]` wrapper: мөр бичилтийн
  явцад subscriber Commit дуудвал **чимээгүй үл хэрэгсэнэ**.
- Preview: `[CommitBehavior(CommitBehavior::Error)]` (GenJnlPostPreview.PreviewStart):
  preview дотор Commit оролдвол алдаа; төгсгөлд заавал `ThrowError()` — бүгд rollback.
- `SuppressCommit` / `SetSuppressCommit()` — batch дуудагч transaction-ээ өөрөө удирдана.
- Date-ordered No. Series үед: `DateOrderSeriesUsed` бол дугаар олголтын Commit-ийг
  хойшлуулж, баримттай нэг transaction-д commit хийдэг (дугаарын цоорхойгоос сэргийлнэ).

## 3. Яагаад ингэж хийсэн бэ (analysis)

- Commit цэг болгоныг "энэ цэг дээр систем ямар ч тохиолдолд зөв төлөвтэй байна"
  гэсэн баталгаатай газар л тавьсан. Жишээ нь дугаар олгоод хадгалах нь өөрөө
  бүрэн бизнес факт: "энэ баримтад энэ дугаар оноогдсон".
- Commit хийхгүйгээр Codeunit.Run хийж болдоггүй платформын хязгаарлалт нь batch
  framework-уудад Commit-ийг албаддаг — үүнийг мэдэхгүй хүн "шаардлагагүй Commit"
  гэж андуурч болно (エкsception биш, зайлшгүй).
- CommitBehavior::Ignore нь гуравдагч subscriber-ийн буруу Commit-ээс цөм posting-ийг
  хамгаалдаг — Microsoft өөрөө ч subscriber-т итгэдэггүй гэсэн үг.

## 4. Зөв хэрэгжилт

```al
// Гадаад дуудлагын өмнө бүрэн төлөвөө commit хийх
procedure PostAndNotify(var SalesHeader: Record "Sales Header")
begin
    SalesPost.Run(SalesHeader);       // бүрэн бичилт (өөрийн commit-тэй)
    Commit();                         // NB: гадаад дуудлагын өмнөх хамгаалалт
    if not TryNotifyExternalSystem(SalesHeader) then
        LogNotificationFailure(GetLastErrorText()); // бичилт хэвээр, зөвхөн мэдэгдэл дутуу
end;

// Batch: баримт бүр бүрэн нэгж
repeat
    if Codeunit.Run(Codeunit::"Sales-Post", SalesHeader) then
        Commit()                       // баримт бүрэн бичигдсэн — checkpoint
    else begin
        LogError(SalesHeader, GetLastErrorText());
        Commit();                      // алдааны лог хадгалагдана, дараагийн баримт руу
    end;
until SalesHeader.Next() = 0;
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: premature commit — дараагийн алхам унавал хагас гүйлгээ
InsertShipmentHeader();
Commit();                 // ← エдгээр хоёрын хооронд unrelated
InsertShipmentLines();    //   алдаа гарвал header мөргүй үлдэнэ

// БУРУУ: transaction дотор гадаад HTTP дуудлага
InsertPaymentEntry();
HttpClient.Post(BankUrl, ...);  // удаан + унавал rollback, гэвч банк руу явчихсан!
PaymentEntry.Modify();
// → банк талд гүйлгээ хийгдсэн, BC талд бичилт байхгүй = зөрүү

// БУРУУ: subscriber дотор Commit
[EventSubscriber(..., 'OnBeforePostSalesDoc', ...)]
local procedure OnBeforePost(var SalesHeader: Record "Sales Header")
begin
    MyLog.Insert();
    Commit(); // ← posting-ийн rollback хамгаалалтыг эвдэнэ
              //   (CommitBehavior::Ignore үүнийг залгих ч бусад цэгт аюултай)
end;

// БУРУУ: алдаа "дарах" зорилготой Commit
Commit();
if not TryDoSomething() then; // Commit-оор Try-ийн хязгаарлалтаас зугтах нь буруу дизайн
```

## 6. Code review хийх дүрэм

Custom кодод Commit() харагдвал ҮРГЭЛЖ дараах асуултуудыг тавь:

1. **Яагаад энд Commit хэрэгтэй вэ?** Хариулт нь: (a) Codeunit.Run-ийн өмнө,
   (b) гадаад дуудлагын өмнөх бүрэн төлөв, (c) batch-ийн нэгж хоорондын checkpoint,
   (d) UI хүлээлтийн өмнө түгжээ суллах — эдгээрийн аль нь ч биш бол **шаардлагагүй
   Commit** байх магадлал өндөр → [HIGH].
2. **Commit-ийн өмнөх төлөв бүрэн үү?** Хагас баримт, header-гүй мөр, ledger-гүй
   register гэх мэт дутуу төлөвт Commit байвал → [CRITICAL] partial transaction.
3. **Commit-ийн дараа алдаа гарвал юу үлдэх вэ?** Үлдэх төлөв нь өөрөө утга
   төгөлдөр биш бол → [CRITICAL].
4. **Posting процесс дотор уу?** OnBefore/OnAfter posting subscriber, эсвэл Post
   codeunit-ийн дунд бол → [CRITICAL].
5. **SuppressCommit/PreviewMode-ийг хүндэтгэсэн үү?** Posting-тэй холбоотой код
   `if not (SuppressCommit or PreviewMode) then Commit()` хэлбэргүй бол → [HIGH].
6. **Гадаад HTTP дуудлага transaction дотор уу?** Бичилтийн дунд HTTP байвал → [HIGH]
   (удаан түгжээ + хоёр системийн зөрүү). Гадаад дуудлагыг transaction-ийн гадна,
   Commit-ийн дараа, идемпотенц түлхүүртэй хий.
7. **Loop дотор Commit үү?** Мөр бүрийн дараах Commit нь batch-ийн атомар чанарыг
   эвдэж байвал → [HIGH]; баримт бүр бие даасан нэгж бол зөвшөөрөгдөнө (жишээ:
   journal batch баримт тус бүрээр).
