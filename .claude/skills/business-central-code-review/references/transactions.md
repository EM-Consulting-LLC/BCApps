# Transactions Reference — COMMIT-ийн шалгалт

## Суурь зарчим

- AL transaction implicit: процесс дуусахад авто-commit, Error() = бүрэн rollback.
- **Commit() = rollback хамгаалалтыг таслах зориудын шийдвэр.** Base App-д 8081
  файлд ~1000 удаа л байдаг — бүгд шалтгаантай.
- Хамгаалах хэрэгслүүд: `[CommitBehavior(CommitBehavior::Ignore)]` (posting-ийн мөр
  боловсруулалт subscriber-ийн Commit-ийг залгидаг), `[CommitBehavior(CommitBehavior::Error)]`
  (preview дотор Commit = алдаа), SuppressCommit флаг, PreventCommit.

## Commit-ийн legitimate 5 шалтгаан (Base App-аас)

1. **Codeunit.Run-ийн өмнө** — платформ uncommitted өөрчлөлттэй conditional Run
   хориглодог (Job Queue status Commit).
2. **Гадаад дуудлагын өмнө бүрэн төлөв** — Post → Commit → Send email
   (илгээлт унасан ч posting үлдэнэ).
3. **Batch нэгж хоорондын checkpoint** — баримт бүр өөрөө бүрэн нэгж.
4. **UI хүлээлтийн өмнө түгжээ суллах** — report request page г.м.
5. **Алдааны лог хадгалах** — алдаа гарсан ч лог үлдэх ёстой.

## COMMIT бүрд асуух 7 асуулт

1. Дээрх 5 шалтгааны аль нь вэ? Аль нь ч биш → **BC-TXN-002 [HIGH]** шаардлагагүй
   Commit; устгуул.
2. Commit-ийн өмнөх төлөв бүрэн үү? Header-гүй мөр, ledger-гүй register гэх мэт
   дутуу бол → **BC-TXN-001 [CRITICAL]** premature Commit.
3. Commit-ийн дараа алдаа гарвал үлдэх төлөв утга төгөлдөр үү? Үгүй бол →
   **BC-TXN-001/003 [CRITICAL/HIGH]**; шалгалтуудыг Commit-ийн өмнө шилжүүл,
   эсвэл compensating статус бич.
4. Posting процесс/subscriber дотор уу? → **BC-TXN-005 / BC-EVT-001 [CRITICAL]**.
5. SuppressCommit/PreviewMode шалгагдсан уу? Posting-тэй урсгалд
   `if not (SuppressCommit or PreviewMode) then Commit()` хэлбэргүй бол →
   **BC-TXN-005 [HIGH]**.
6. Гадаад HTTP transaction дотор уу (uncommitted бичилттэй үед Send)? →
   **BC-TXN-004 [HIGH]**: гадаад дуудлагыг Commit-ийн дараа, статус машин +
   идемпотенц түлхүүртэй болго.
7. Loop дотор уу? Мөр бүрийн Commit batch-ийн атомар чанарыг эвдэж байвал →
   **BC-TXN-001 [HIGH+]**; баримт бүр бие даасан нэгж бол зөвшөөрөгдөнө.

## BC-TXN-006 [MEDIUM] — Codeunit.Run-ийн өмнөх commit дутуу

`if Codeunit.Run(...)`-ийн өмнөх зам дээр uncommitted Insert/Modify байвал runtime
error ("...commit the changes..."). Тодорхой өгөгдлийн нөхцөлд л илэрдэг тул
тестээс мултардаг. **Засвар:** өөрчлөлтөө бүрэн болгоод Commit хийж Run дууд.

## Жишээ

```al
// ЗӨВ: гадаад дуудлагын өмнөх commit + статус машин
Entry.Status := Entry.Status::Pending;
Entry.Insert();
Commit();
if TrySend(Entry) then Entry.Status := Entry.Status::Sent
else Entry.Status := Entry.Status::Error;
Entry.Modify();

// БУРУУ: premature
Header.Insert();
Commit();          // ← мөр бичихээс өмнө commit
InsertLines();     // унавал мөргүй header үлдэнэ

// БУРУУ: transaction доторх HTTP
PaymentEntry.Insert();
HttpClient.Post(BankUrl, ...);  // rollback хийгдвэл банк талд явчихсан
PaymentEntry.Modify();
```
