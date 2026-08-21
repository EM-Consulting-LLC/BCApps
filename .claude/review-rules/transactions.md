# Transaction Review Rules — BC-TXN

> COMMIT ашигласан бүх custom code нь transaction consistency талаас тусгай review
> шаарддаг. Файл дотор `Commit()` олдвол доорх бүх дүрмийг дэс дараалан шалга.

---

## BC-TXN-001 — Premature COMMIT (хагас гүйлгээний эрсдэл)

- **Severity:** CRITICAL
- **Rule:** Логик нэгж (баримт + мөрүүд, header + ledger, хос бичилт) бүрэн
  дуусахаас өмнө Commit() дуудагдаж байвал илрүүлнэ.
- **Why:** Commit-ээс хойшхи алдаа зөвхөн үлдсэн хэсгийг rollback хийнэ — өмнөх
  хэсэг нь хагас, зөрчилтэй төлөвөөр үлдэнэ.
- **Risk:** Мөргүй header, ledger-гүй баримт, зөрүүтэй санхүүгийн тайлан; гараар
  засварлахаас өөр аргагүй production осол.
- **Detection:** Commit()-ийн байрлалыг урсгалын алхмуудтай харьцуул: Commit-ийн
  дараа мөр/entry Insert, Modify, Validate, Error() боломжтой шалгалт байгаа эсэх.
  Ялангуяа: `InsertHeader → Commit → InsertLines`, loop дундах Commit.
- **Example — Bad:**
  ```al
  PostedHeader.Insert();
  Commit();                       // ← хагас цэг
  InsertPostedLines(PostedHeader); // энд алдаа гарвал мөргүй header үлдэнэ
  ```
- **Example — Good:**
  ```al
  PostedHeader.Insert();
  InsertPostedLines(PostedHeader);
  UpdateSourceDocument();
  Commit(); // бүрэн, уялдаатай төлөвт л
  ```
- **Suggested Fix:** Commit-ийг логик нэгжийн төгсгөлд шилжүүл; дундын checkpoint
  зайлшгүй бол (job queue гэх мэт) checkpoint-ийн өмнөх төлөв нь өөрөө бүрэн утгатай
  байхаар урсгалыг өөрчил.

---

## BC-TXN-002 — Unnecessary COMMIT (шаардлагагүй Commit)

- **Severity:** HIGH
- **Rule:** Дараах legitimate шалтгаануудын аль нь ч биш Commit() илрүүлнэ:
  (a) Codeunit.Run/Job Queue-ийн өмнөх, (b) гадаад дуудлагын өмнөх бүрэн төлөв,
  (c) batch нэгж хоорондын checkpoint, (d) удаан UI хүлээлтийн өмнө түгжээ суллах,
  (e) алдааны лог хадгалах.
- **Why:** AL-ийн implicit transaction + Error rollback нь үндсэн хамгаалалт;
  шаардлагагүй Commit энэ хамгаалалтыг цоолж, rollback-ийн хил хязгаарыг эвддэг.
- **Risk:** Хожим нэмэгдэх кодын алдаа хагас өгөгдөл үлдээх нөхцөл бүрддэг;
  posting/preview-тэй хамт дуудагдвал runtime алдаа.
- **Detection:** Commit() бүрийг олоод "яагаад энд заавал хэрэгтэй вэ?" гэсэн
  асуултад дээрх (a)–(e)-ийн аль нэгээр хариулагдахгүй бол report хий.
  Ялангуяа procedure-ийн төгсгөлийн "just in case" Commit.
- **Example — Bad:**
  ```al
  procedure UpdateSetup()
  begin
      Setup.Modify();
      Commit(); // процесс дуусахад автоматаар commit хийгдэнэ — дэмий + аюултай
  end;
  ```
- **Example — Good:**
  ```al
  procedure UpdateSetup()
  begin
      Setup.Modify(); // implicit commit хангалттай
  end;
  ```
- **Suggested Fix:** Commit-ийг устга; шаардлагатай гэж үзвэл шалтгааныг комментоор
  баримтжуулахыг шаард.

---

## BC-TXN-003 — Error after COMMIT (Commit-ийн дараах алдааны зам)

- **Severity:** HIGH
- **Rule:** Commit-ийн дараа Error(), TestField, FieldError, эсвэл алдаа хаяж
  болзошгүй дуудлага байгаа бөгөөд үлдэх төлөв нь зөрчилтэй бол илрүүлнэ.
- **Why:** Хэрэглэгч алдаа харна, гэвч өгөгдлийн нэг хэсэг аль хэдийн хадгалагдсан.
  Хэрэглэгч "амжилтгүй боллоо" гэж ойлгоод дахин оролдвол давхардал үүсч болно.
- **Risk:** Давхар бичилт, зөрүүтэй төлөв, төөрөлдсөн хэрэглэгч.
- **Detection:** Commit()-ээс procedure төгсөх хүртэлх зам дээрх Error боломжуудыг
  мөрд; тэр алдаа гарахад аль өгөгдөл үлдэхийг үнэл. Мөн Commit-ийн дараах кодод
  амжилтын төлөв бичдэг эсэхийг шалга (status update Commit-ийн өмнө байх ёстой).
- **Example — Bad:**
  ```al
  DocLog.Insert();
  Commit();
  DocLog.TestField("External Id"); // хоосон бол Error — гэвч log орчихсон, status тодорхойгүй
  ```
- **Example — Good:**
  ```al
  DocLog.TestField("External Id"); // бүх шалгалт Commit-ийн өмнө
  DocLog.Insert();
  Commit();
  ```
- **Suggested Fix:** Шалгалтуудыг Commit-ийн өмнө шилжүүл; Commit-ийн дараах алдааг
  барьж compensating үйлдэл (status=Error гэх мэт) хий.

---

## BC-TXN-004 — External call inside transaction (transaction доторх гадаад дуудлага)

- **Severity:** HIGH
- **Rule:** Uncommitted DB өөрчлөлттэй байх үед HttpClient.Send/Get/Post,
  email илгээлт, файл экспорт зэрэг гадаад үйлдэл хийгдэж байвал илрүүлнэ.
- **Why:** (1) Гадаад дуудлага удаан — түгжээ уддаг; (2) дараа нь rollback хийгдвэл
  гадаад систем "болсон", BC "болоогүй" гэсэн зөрүү үүснэ (гадаад үйлдэл rollback
  хийгддэггүй).
- **Risk:** Хоёр системийн зөрүү, давхар илгээлт, deadlock/lock timeout.
- **Detection:** HttpClient/Email/File үйлдлийн өмнөх кодод Insert/Modify/Delete
  байгаад Commit байхгүй эсэх; мөн posting subscriber дотор HTTP дуудлага.
- **Example — Bad:**
  ```al
  PaymentEntry.Insert();
  HttpClient.Post(BankUrl, Content, Response); // uncommitted бичилттэй HTTP
  PaymentEntry."Bank Ref." := GetRef(Response);
  PaymentEntry.Modify();
  ```
- **Example — Good:**
  ```al
  PaymentEntry.Status := PaymentEntry.Status::Pending;
  PaymentEntry.Insert();
  Commit();                                     // төлөв бүрэн
  if TrySendToBank(PaymentEntry, Response) then begin
      PaymentEntry.Status := PaymentEntry.Status::Sent;
      PaymentEntry."Bank Ref." := GetRef(Response);
  end else
      PaymentEntry.Status := PaymentEntry.Status::Error;
  PaymentEntry.Modify();
  ```
- **Suggested Fix:** Гадаад дуудлагыг transaction-ийн гадна (Commit-ийн дараа)
  гарга; статус машин + идемпотенц түлхүүрээр давхар илгээлтээс хамгаал; боломжтой
  бол Job Queue-ээр async болго.

---

## BC-TXN-005 — SuppressCommit / PreviewMode үл хүндэтгэх

- **Severity:** HIGH
- **Rule:** Posting урсгалд оролцдог custom код (subscriber, custom post routine)
  Commit() дуудахдаа SuppressCommit/PreviewMode төлөвийг шалгахгүй байвал илрүүлнэ.
- **Why:** Batch posting болон Posting Preview нь transaction-ийг өөрөө удирддаг;
  preview үед Commit хийгдвэл preview бодит бичилт болж хувирна, batch үед
  нэгж баримтын атомар чанар алдагдана.
- **Risk:** Preview-ээс бодит бичилт үлдэх (маш ноцтой), batch-ийн алдааны rollback эвдрэх.
- **Detection:** Posting event-ийн subscriber эсвэл posting-оос дуудагддаг кодод
  нөхцөлгүй Commit(); event signature-т SuppressCommit/PreviewMode параметр байгаа
  ч ашиглаагүй байх.
- **Example — Bad:**
  ```al
  [EventSubscriber(..., 'OnAfterPostSalesDoc', ...)]
  local procedure OnAfterPost(var SalesHeader: Record "Sales Header"; ...; SuppressCommit: Boolean; ...)
  begin
      MyIntegrationQueue.Insert();
      Commit(); // SuppressCommit-ийг үл хэрэгссэн
  end;
  ```
- **Example — Good:**
  ```al
  begin
      MyIntegrationQueue.Insert(); // Commit огт хэрэггүй — host өөрөө commit хийнэ
  end;
  ```
- **Suggested Fix:** Subscriber-ээс Commit-ийг устга; өөрийн posting routine-д
  SuppressCommit параметр нэвтрүүлж `if not SuppressCommit then Commit()` хэлбэрт оруул.

---

## BC-TXN-006 — Codeunit.Run-ийн өмнөх commit нөхцөл

- **Severity:** MEDIUM
- **Rule:** `if Codeunit.Run(...)` хэлбэрийн дуудлагын өмнө uncommitted өөрчлөлт
  байж болзошгүй бол илрүүлнэ (runtime error: "commit the changes before...").
- **Why:** Платформ uncommitted бичилттэй үед conditional Codeunit.Run-ыг хориглодог.
- **Risk:** Runtime failure — зөвхөн тодорхой өгөгдлийн нөхцөлд илэрдэг тул тестээс
  амархан мултардаг.
- **Detection:** Codeunit.Run/Report.Run(false)-ийн өмнөх зам дээр Insert/Modify/
  Delete байгаад Commit байхгүй; ялангуяа UI action-аас шууд дуудагдах урсгал.
- **Example — Bad:**
  ```al
  SalesHeader."My Flag" := true;
  SalesHeader.Modify();
  if Codeunit.Run(Codeunit::"Sales-Post", SalesHeader) then; // runtime error!
  ```
- **Example — Good:**
  ```al
  SalesHeader."My Flag" := true;
  SalesHeader.Modify();
  Commit(); // Codeunit.Run-ийн өмнөх зайлшгүй commit (баримтжуулсан шалтгаан)
  if Codeunit.Run(Codeunit::"Sales-Post", SalesHeader) then;
  ```
- **Suggested Fix:** Өөрчлөлтөө тусад нь бүрэн болгоод Commit хийж, дараа нь Run
  дууд; эсвэл Run-ийг unconditional (Codeunit.Run биш шууд дуудлага) болго.
