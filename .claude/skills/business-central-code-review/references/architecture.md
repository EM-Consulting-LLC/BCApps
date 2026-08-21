# Architecture Reference — Архитектур ба Object Responsibility

## Суурь зарчим (Base Application-аас)

1. **Давхарга:** System Application → Business Foundation → Base Application →
   Extensions → Localizations. Хамаарал зөвхөн доороос дээш.
2. **Journal → Ledger нэг суваг:** бүх бичилт Post Line codeunit-уудаар
   (CU 12 "Gen. Jnl.-Post Line", CU 22 "Item Jnl.-Post Line") л Ledger Entry болно.
   CU 12-ийн FinishPosting balance ≠ 0 бол `GLEntry.Consistent(false)` — тэнцвэргүй
   бичилт commit хийгдэхгүй.
3. **Page нимгэн:** action → codeunit delegate (SalesOrder.Page.al-ийн Post action
   ганц мөр). UI логик (visibility, style, notification) л page-д байна.
4. **Object хариуцлага:** өгөгдлийн дүрэм Table-д (OnValidate, lifecycle trigger),
   процесс Codeunit-д, солигдох algorithm Interface + Extensible Enum-д,
   permission нь composition-той PermissionSet-д.
5. **Facade зарчим:** public гадаргуу цөөн, тогтвортой (`Access = Public` facade +
   `Access = Internal` Impl.); public өөрчлөлт Obsolete lifecycle-ээр.

## Дүрмүүд

### BC-ARCH-001 [CRITICAL] — Ledger руу шууд бичилт
G/L Entry, VAT Entry, Cust./Vendor/Employee Ledger Entry, Item Ledger Entry,
Value Entry, Bank Account Ledger Entry, Detailed * Entry, * Register хүснэгтэд
custom Insert/Modify/Delete → зогсоо. Balance, VAT, dimension, register, audit
бүгд алгасагдана. **Засвар:** Gen. Journal Line бэлдэж GenJnlPostLine.RunWithCheck;
item хөдөлгөөнд Item Journal Line + ItemJnlPostLine.

### BC-ARCH-002 [HIGH] — Page дээрх бизнес логик
Page action/trigger дотор өгөгдөл өөрчлөх урсгал, олон record боловсруулалт →
codeunit рүү нүүлгэ. Шалгуур: Rec-ээс бусад хүснэгтийн Modify page дотор,
> 10 мөр бизнес үйлдэл.

### BC-ARCH-003 [MEDIUM] — Модулийн хил зөрчсөн хамаарал
Өөр модулийн Impl./internal объект руу хандах, utility кодыг домэйноос хамааралтай
болгох → facade/event/interface ашиглуул.

### BC-ARCH-004 [MEDIUM] — Extensibility цэгийг үл тоох
Стандарт зан төлөв өөрчлөхөд copy-paste engine эсвэл олон event дээрх hack →
байгаа event/interface цэгийг ол (Sales-Post 100+ event-тэй; Invoice Posting,
Price Calculation interface солигддог).

### BC-ARCH-005 [MEDIUM] — Global state
SingleInstance/global-д бизнес төлөв цэвэрлэгдэхгүй хадгалагдах → процесс эхлэхэд
Clear (Sales-Post ClearAllVariables загвар), төлвийг параметрээр дамжуул.

### BC-AL дүрмүүд (кодын түвшин)

- **BC-AL-001 [HIGH]:** Confirm/Message/Dialog GuiAllowed()-гүй — posting/API/
  Job Queue-д унана. Confirm Management codeunit ашигла.
- **BC-AL-002 [MEDIUM]:** Hardcoded хэрэглэгчийн текст → Label + Comment
  (placeholder-т), Locked = true (токенд).
- **BC-AL-003 [MEDIUM]:** Урт утга → богино талбар CopyStr/MaxStrLen-гүй —
  runtime overflow.
- **BC-AL-004 [MEDIUM]:** IsHandled pattern зөрчил — стандарт:
  `IsHandled := false; OnBeforeX(..., IsHandled); if IsHandled then exit;`
- **BC-AL-006 [HIGH]:** Public procedure/event/талбар Obsolete lifecycle-гүй
  устгах/өөрчлөх — dependent extension-ууд эвдэрнэ. ObsoleteState = Pending +
  Reason + Tag.
- **BC-AL-007 [LOW]:** Шинэ талбарт DataClassification, page талбарт
  ApplicationArea/ToolTip дутуу.
- **BC-AL-008 [MEDIUM, бичилтэд бол HIGH]:** Hardcoded данс/journal template/
  location/No. Series утга — Setup хүснэгтээс TestField-тэй авах ёстой
  (компани бүрийн тохиргоо өөр).
- **BC-EXT-002 [MEDIUM]:** Өргөтгөгдөх магадлалтай public процесст event цэг
  нээгээгүй монолит.
- **BC-EXT-003 [MEDIUM]:** Солигдох algorithm-ийг case-ээр hardcode —
  Interface + Extensible Enum ашиглуул.
- **BC-EXT-005 [MEDIUM]:** TableExtension-д урсгалын логик — талбар + богино
  validation л байна, урсгал subscriber codeunit-д.
