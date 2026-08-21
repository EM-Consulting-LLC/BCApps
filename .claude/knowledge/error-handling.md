# Error Handling — Алдааны боловсруулалтын мэдлэгийн сан

## 1. Зарчим

BC-д алдаа бол transaction-ийн удирдлагын хэрэгсэл: **Error() нь автоматаар бүх
uncommitted өөрчлөлтийг rollback хийдэг.** Тиймээс алдааг "хаях" ба "барих" хоёр нь
өгөгдлийн бүрэн бүтэн байдалд шууд нөлөөлдөг. Microsoft-ийн код алдааг дараах
зарчмаар ашигладаг:

- Бизнес дүрмийн зөрчил → Error/FieldError/TestField (rollback-д найдна).
- Гадаад системийн эвдрэл → TryFunction/Codeunit.Run-аар барьж, өөрөө шийднэ.
- Олон алдааг нэг дор → ErrorInfo + Error Message Management framework.

## 2. Source code дээрх ажиглалт

| Механизм | Хэрэглээ |
|---|---|
| `Error(Lbl, ...)` | Процесс зогсоох, бүрэн rollback. Text үргэлж Label |
| `FieldError(Field, Txt)` | Талбарт хамааруулсан алдаа (829 удаа). Txt нь "must ..." хэлбэрийн үргэлжлэл |
| `TestField(Field)` | Заавал бөглөх шалгалт |
| `TestField(F, ErrorInfo.Create())` | Collectible хувилбар (179 удаа, шинэ код) |
| `Error('')` | Чимээгүй зогсолт (preview-ийн rollback, аль хэдийн харуулсан алдааны дараа) |
| `[TryFunction]` | Interop/integration-д л (328). `GetFieldNameAndCaption` гэх мэт — DB бичилтгүй туслах үйлдлүүд |
| `if not Codeunit.Run(...) then` | Тусгаарлагдсан transaction-тэй алдаа барих: Job Queue posting `if not Codeunit.Run(Codeunit::"Sales-Post", SalesHeader) then begin SetJobQueueStatus(Error); Error(GetLastErrorText); end` |
| `ErrorMessageMgt` PushContext/PopContext | Алдаа гарвал ямар record, ямар алхам байсныг хамт бүртгэдэг (Sales-Post бүх фазад ашигладаг) |
| `[ErrorBehavior(ErrorBehavior::Collect)]` | Background бүрэн шалгалт — бүх алдааг цуглуулна |
| `GetLastErrorText/GetLastErrorCallstack` | Барьсан алдааг хэрэглэгчид/лог руу дамжуулах |
| Notification + AddAction | Blocking биш анхааруулга + залруулах action |
| `GenJnlPostPreview.ThrowError()` | Preview-г зориуд Error-оор дуусгаж rollback баталгаажуулдаг |

Чухал ажиглалт: **Codeunit.Run нь commit хийгдээгүй өөрчлөлттэй үед дуудагдвал
runtime error өгдөг** тул Job Queue/batch код дуудлагын өмнө Commit хийдэг
(SetJobQueueStatus дотор Modify + Commit). Энэ нь Commit-ийн legitimate шалтгаануудын нэг.

## 3. Яагаад ингэж хийсэн бэ (analysis)

- Rollback-д тулгуурласан загвар нь ERP-д ашигтай: алдаа гарвал хагас бичилт үлддэггүй.
  Гэвч энэ нь **Commit-ийг буруу байрлуулбал rollback хамгаалалт алга болно** гэсэн үг.
- TryFunction-ийг бизнес логикт хэрэглэдэггүйн шалтгаан: Try дотор хийсэн DB өөрчлөлт
  автоматаар rollback хийгдэхгүй тул commit хийгээгүй inconsistent төлөв
  "амьд үлдэх" эрсдэлтэй. (Platform нь Try дотор бичилт хийгдсэн бол exit үед
  хатуу хориглодог тохиолдол ч бий.)
- ErrorMessageMgt framework — batch/background горимд алдаа хэрэглэгчийн нүдний өмнө
  шууд гарахгүй тул контексттэй хадгалах шаардлагатай.

## 4. Зөв хэрэгжилт

```al
// Бизнес алдаа — Label + FieldError
if Customer.Blocked = Customer.Blocked::All then
    Customer.FieldError(Blocked);

// Гадаад дуудлагын алдаа барих — TryFunction, DB бичилтгүй
[TryFunction]
local procedure TrySendRequest(Url: Text; var ResponseText: Text)
begin
    ...HttpClient.Send...
end;

procedure SendWithRetry()
begin
    if not TrySendRequest(Url, Response) then begin
        LogFailure(GetLastErrorText());   // log — DB бичилт Try-ийн ГАДНА
        exit;
    end;
end;

// Тусгаарлагдсан posting алдаа барих
if not Codeunit.Run(Codeunit::"Sales-Post", SalesHeader) then begin
    MarkDocumentFailed(SalesHeader, GetLastErrorText());
    Commit(); // төлөвөө хадгалж дараагийн баримт руу
end;
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: алдааг залгиад үргэлжлүүлэх
if not Codeunit.Run(Codeunit::"Sales-Post", SalesHeader) then;
// юу ч бүртгэлгүй — баримт "амжилттай" харагдана

// БУРУУ: TryFunction дотор DB бичилт
[TryFunction]
local procedure TryPostAndLog()
begin
    LogEntry.Insert();          // Try-д бичилт: алдаа гарсан ч rollback хийгдэхгүй
    PostSomething();            // байж болзошгүй, unpredictable төлөв
end;

// БУРУУ: Commit-ийн дараах алдаа
Commit();
DoRiskyThing();  // энд Error гарвал өмнөх бичилт үлдчихсэн — хагас гүйлгээ

// БУРУУ: hardcoded, контекстгүй алдаа
Error('Алдаа гарлаа');
```

## 6. Code review хийх дүрэм

1. **[HIGH]** `if not Codeunit.Run(...) then;` эсвэл try-барьсан алдааг бүртгэлгүй
   алгасаж байвал — silent failure. Лог/статус/дахин оролдлого аль нэг нь заавал.
2. **[HIGH]** `[TryFunction]` дотор Insert/Modify/Delete/posting байвал —
   inconsistent төлөвийн эрсдэл. Try нь зөвхөн уншилт/тооцоолол/interop байх ёстой.
3. **[HIGH]** Commit хийсний дараа алдаа гарч болзошгүй үйлдэл (Error, validation,
   гадаад дуудлага) байгаа бөгөөд compensation байхгүй бол — transaction док руу.
4. **[MEDIUM]** Batch loop дотор нэг бичлэгийн алдаа бүх batch-ыг унагадаг бол
   Codeunit.Run + статус бүртгэл (Job Queue pattern) санал болго.
5. **[MEDIUM]** Хэрэглэгчийн алдааны мэдээлэл ойлгомжгүй (талбар/record контекстгүй
   generic Error) бол FieldError/TestField/ErrorInfo ашиглахыг зөвлө.
6. **[LOW]** GetLastErrorText-ийг Clear хийхгүй дахин ашиглах, эсвэл алдааны текстээр
   логик салаалуулах (error message string comparison) — эмзэг код.
