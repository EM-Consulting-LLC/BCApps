# Coding Patterns — AL кодын хэв маягийн мэдлэгийн сан

## 1. Зарчим

Base Application-ийн код нь цөөн тооны, маш тогтвортой давтагддаг хэв маягуудаас
бүрддэг. Эдгээр нь зүгээр нэг style биш — олонх нь correctness (зөв ажиллагаа),
extensibility, локалчлалын шаардлагаас урган гарсан.

## 2. Source code дээрх ажиглалт

### Label / Text constant
- Бүх хэрэглэгчид харагдах текст `Label` зарлалттай, placeholder ашиглавал
  `Comment = '%1 = ...'` заавал бичигддэг.
- Орчуулагдах ёсгүй токен `Locked = true` (жишээ: `PostingPreviewNoTok: Label '***', Locked = true`).
- Telemetry label-ууд Locked (жишээ: `SalesLinePostCategoryTok`).

### Procedure бүтэц
- Named return value: `local procedure UpdatePostingNos(...) ModifyHeader: Boolean`.
- Guard clause эхэнд: `if not ... then exit;` — гүн nesting-ээс зайлсхийдэг.
- `IsHandled := false; OnBeforeX(...); if IsHandled then exit;` — бараг бүх
  чухал procedure-ийн эхний мөрүүд.
- Процессын төлөв (SuppressCommit, PreviewMode, HideProgressWindow) global хувьсагчид
  хадгалагдаж Set* procedure-ээр гаднаас тохируулагддаг.

### GUI хамгаалалт
- `if GuiAllowed() and not HideProgressWindow then Window.Update(...)` — dialog,
  confirm бүхэн GuiAllowed шалгалттай (background/web service session-д унахгүй).

### Setup caching
- `GetGLSetup()`, `GetSalesSetup()` — global boolean (GLSetupRead) + нэг удаа Get
  хийдэг lazy-load pattern; loop дотор Setup-ыг давтан уншдаггүй.

### Temporary record
- Боловсруулалт temp хүснэгт дээр: `FillTempLines(SalesHeader, TempSalesLineGlobal)`.
- Temp гэдгийг нэрээр илэрхийлдэг: `TempSalesLineGlobal`, `TempVATAmountLine`.
- Subscriber-ууд `Rec.IsTemporary()` шалгаж temp record дээр ажиллахаас татгалздаг.

### Оbsolete lifecycle
- `ObsoleteState = Pending; ObsoleteReason = '...'; ObsoleteTag = 'xx.x'` (634 газар),
  `#if not CLEANxx` preprocessor — public зүйлийг шууд устгадаггүй.

### Бусад
- `Codeunit.Run(Codeunit::X, Rec)` + `if not ... then` — тусгаарлагдсан алдаа барих.
- `StrSubstNo`, `CopyStr(..., 1, MaxStrLen(Field))` — string аюулгүй боловсруулалт.
- `Session.LogMessage('0000XXX', ..., Verbosity, DataClassification::SystemMetadata, ...)`
  — telemetry нь SystemMetadata ангилалтай, хэрэглэгчийн өгөгдөл агуулдаггүй.
- Pragma-г зөвхөн шалтгаантай үед: `#pragma warning disable AA0470` (label placeholder).

## 3. Яагаад ингэж хийсэн бэ (analysis)

- Label+Comment нь орчуулагчид контекст өгч, олон улсын хувилбарыг зөв гаргадаг.
- GuiAllowed шалгалт нь ижил кодыг UI, API, Job Queue, background session-д
  ажиллуулах боломж олгодог — BC-ийн олон suv archетипт заавал хэрэгтэй.
- Setup caching нь БД дуудлага багасгана; гэхдээ нэг transaction доторх cache тул
  урт процесст төлөв өөрчлөгдөхөөс сэргийлж норм болсон.
- IsTemporary шалгалт: temp record дээр subscriber ажиллавал бодит бус өгөгдөл дээр
  бичилт хийх, давхардсан side-effect үүсгэх эрсдэлтэй.

## 4. Зөв хэрэгжилт

```al
var
    ItemBlockedErr: Label 'Item %1 is blocked for sales.', Comment = '%1 = Item No.';

procedure ProcessOrder(var SalesHeader: Record "Sales Header")
var
    IsHandled: Boolean;
begin
    IsHandled := false;
    OnBeforeProcessOrder(SalesHeader, IsHandled);
    if IsHandled then
        exit;

    if GuiAllowed() then
        Window.Open(ProcessingMsg);
    ...
end;
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: hardcoded текст, орчуулагдахгүй
Error('Барааг борлуулах боломжгүй!');

// БУРУУ: background session-д унана
Window.Open('Processing...');           // GuiAllowed шалгаагүй
if not Confirm(ContinueQst) then exit;  // Job Queue дээр exception

// БУРУУ: loop дотор Setup давтан унших
repeat
    GLSetup.Get(); // мөр бүр дээр DB дуудлага
    ...
until Line.Next() = 0;

// БУРУУ: subscriber temp record шалгаагүй
[EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInsertEvent', '', false, false)]
local procedure OnInsert(var Rec: Record "Sales Header")
begin
    MyLog.LogInsert(Rec); // Rec.IsTemporary() бол log бохирдоно
end;
```

## 6. Code review хийх дүрэм

1. **[MEDIUM]** Хэрэглэгчид харагдах текст hardcoded байвал Label болгохыг шаард;
   placeholder-той Label-д Comment байхгүй бол нэм.
2. **[HIGH]** `Confirm`, `Message`, `Dialog`, page Run зэрэг UI дуудлага
   `GuiAllowed()` шалгалтгүй бөгөөд тухайн код posting/API/Job Queue замаар дуудагдах
   боломжтой бол — runtime failure эрсдэл.
3. **[MEDIUM]** Event subscriber-т `Rec.IsTemporary()` guard байхгүй бөгөөд бичилт
   хийдэг бол анхааруул.
4. **[MEDIUM]** Loop дотор Setup/тогтмол record давтан уншиж байвал caching зөвлө.
5. **[MEDIUM]** Public object/procedure-ийг Obsolete lifecycle-гүйгээр устгаж/нэр
   өөрчилж байвал breaking change гэж тэмдэглэ.
6. **[LOW]** Text overflow: Code/Text талбар руу хуулахдаа CopyStr+MaxStrLen
   ашиглаагүй implicit truncation байвал тэмдэглэ.
7. **[LOW]** Нэршил: Temp хувьсагч Temp* угтваргүй, эсвэл procedure нэр үйлдлээ
   илэрхийлэхгүй бол consistency асуудал.
