# Events & Extensibility — Event ба өргөтгөлийн мэдлэгийн сан

## 1. Зарчим

BC-ийн extensibility нь "base кодыг өөрчлөхгүйгээр зан төлөвийг өргөтгөх" зарчимтай.
Хэрэгслүүд нь зориулалтаараа ялгаатай:

| Хэрэгсэл | Зориулалт |
|---|---|
| IntegrationEvent (OnBefore/OnAfter) | Процессын цэгт нэмэлт үйлдэл |
| IsHandled pattern | Стандарт үйлдлийг бүрэн солих |
| Interface + Enum | Бүтэн algorithm-ийг сонгож солих |
| Table/Page/Enum extension | Өгөгдөл, UI, сонголт нэмэх |
| Manual binding (BindSubscription) | Тодорхой хугацаанд л идэвхтэй subscriber |

Subscriber нь **зочин** гэдгээ мэдэж биеэ авч явах ёстой: богино, хамгаалалттай,
host процессын transaction/ursгалыг эвдэхгүй.

## 2. Source code дээрх ажиглалт

### Event зарлалт (23 434 IntegrationEvent)
- Нэршил: `OnBefore<Action>`, `OnAfter<Action>`, `On<Proc>On<SubStep>`
  (жишээ: `OnRunOnBeforeCheckAndUpdate`, `OnCheckAndUpdateOnAfterCalcInvDiscount`).
- IsHandled хэлбэр:
```al
IsHandled := false;
OnBeforeUpdateShippingNo(SalesHeader, ..., IsHandled);
if IsHandled then
    exit;
```
- Event-д процессын төлөв дамжуулдаг: SuppressCommit, PreviewMode гэх мэт —
  subscriber зөв biеэ авч явах мэдээлэлтэй байна.
- `[IntegrationEvent(true, false)]` — эхний параметр true бол subscriber `sender`-г
  авч чадна.

### Subscriber-ийн сахилга (DocumentAttachmentMgmt)
- Guard-ууд: `if Rec."No." = '' then exit;` + **`if Rec.IsTemporary() then exit;`**.
- Нэг subscriber нэг зорилго; өөрийн модулийн өгөгдлийг л өөрчилдөг.
- Table-ийн built-in event (`OnAfterInsertEvent`, `OnAfterValidateEvent` +
  талбарын нэр) ашигладаг.

### Manual binding
- `EventSubscriberInstance = Manual` + `BindSubscription(this)` — Sales-Post нь
  зөвхөн өөрийн posting хугацаанд value entry цуглуулах subscriber идэвхжүүлдэг;
  Preview mode PostingPreviewEventHandler-ийг bind хийдэг.

### Interface + Enum (Price Calculation, Invoice Posting)
- `Extensible = true` enum → тохиргоонд implementation сонгоно → interface-ээр дуудна.
- Interface-ийн бүх method XML doc комменттой.

### Обsolete lifecycle
- Event-ийг ч ObsoleteState-ээр устгадаг: signature өөрчлөх бол шинэ event нэмээд
  хуучныг Pending болгодог.

## 3. Яагаад ингэж хийсэн бэ (analysis)

- OnBefore+IsHandled нь "override" боломж — гэхдээ subscriber бүх хариуцлагыг авдаг
  (exit хийвэл стандарт логик огт хийгдэхгүй). Тиймээс review-д IsHandled := true
  хийсэн subscriber-ийг онцгой шалгах хэрэгтэй.
- Событын нэрэнд процессын байрлал шингэсэн нь subscriber хэзээ дуудагдахаа нэрнээс
  ойлгох боломж өгдөг.
- Manual binding нь глобал subscriber-ийн "үргэлж сонсдог" зардал болон санамсаргүй
  идэвхжилтээс сэргийлдэг.

## 4. Зөв хэрэгжилт

```al
// Богино, хамгаалалттай subscriber
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
local procedure SyncLoyaltyOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header";
    SalesInvHdrNo: Code[20]; SuppressCommit: Boolean; PreviewMode: Boolean)
begin
    if PreviewMode then          // preview-д бодит бичилт хийхгүй
        exit;
    if SalesInvHdrNo = '' then
        exit;
    if SalesHeader.IsTemporary() then
        exit;
    UpdateLoyaltyPoints(SalesHeader, SalesInvHdrNo);  // өөрийн domain-ы жижиг үйлдэл
end;

// Өөрийн кодод extensibility нээх
procedure CalculateBonus(var Bonus: Decimal; SalesLine: Record "Sales Line")
var
    IsHandled: Boolean;
begin
    IsHandled := false;
    OnBeforeCalculateBonus(SalesLine, Bonus, IsHandled);
    if IsHandled then
        exit;
    ...
    OnAfterCalculateBonus(SalesLine, Bonus);
end;
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: subscriber дотор хүнд бизнес логик + Commit + UI
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
local procedure OnBeforePost(var SalesHeader: Record "Sales Header")
begin
    RecalculateAllPrices(SalesHeader);      // өөр domain-ий өгөгдлийг бөөнөөр өөрчилнө
    Commit();                                // posting-ийн rollback-ийг эвдэнэ
    if not Confirm(AreYouSureQst) then       // background-д унана
        Error('');
end;

// БУРУУ: OnAfterValidateEvent дотор өөр table-ийн Modify цикл
[EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'Quantity', false, false)]
local procedure OnValidateQty(var Rec: Record "Sales Line")
begin
    SalesHeader.Get(Rec."Document Type", Rec."Document No.");
    SalesHeader.Validate("Order Total", CalcTotal(Rec));  // validate → бусад event →
    SalesHeader.Modify(true);                             // subscriber гинжин цуваа, гүйцэтгэл + давталтын эрсдэл
end;

// БУРУУ: IsHandled-ийг болзолгүй true болгох
[EventSubscriber(..., 'OnBeforeUpdateShippingNo', ...)]
local procedure SkipShippingNo(var IsHandled: Boolean)
begin
    IsHandled := true;  // БҮХ баримтад стандарт дугаар олголтыг унтраана —
                        // өөр extension-ий ижил subscriber-тэй мөргөлдөнө
end;
```

## 6. Code review хийх дүрэм

1. **[HIGH]** Subscriber posting/validate урсгалд Commit, Confirm/Dialog, Error
   (өөрийн validation-аас бусад), удаан үйлдэл (HTTP, bulk уншилт) хийж байвал.
2. **[HIGH]** `IsHandled := true` болзолгүй эсвэл өргөн нөхцөлд — стандарт логик
   болон бусад extension-ийг унтрааж байгааг нотлуул; аль болос нарийн нөхцөлтэй болго.
3. **[HIGH]** Олон subscriber нэг өгөгдлийг өөрчилдөг эсвэл subscriber доторх Modify
   нь өөр event-ийг гинжээр дуудаж рекурс/давталт үүсгэж болзошгүй бол.
4. **[MEDIUM]** Subscriber-т guard байхгүй: IsTemporary, хоосон түлхүүр, PreviewMode
   (posting event-д), RunTrigger шалгалт.
5. **[MEDIUM]** Base object-ыг өөрчлөх/hook хийхийн оронд аль хэдийн байгаа event
   (OnBefore/OnAfter) эсвэл interface ашиглаж болох байсан бол — existing
   extensibility point-ыг эхэлж хайлга.
6. **[MEDIUM]** Solid algorithm солих шаардлагад event-ийн олон цэг барьж
   "мяндас" үүсгэсэн бол Interface + Enum extension санал болго.
7. **[MEDIUM]** Subscriber-ийн execution order-т найдсан логик (өөр subscriber-ийн
   дараа ажиллана гэж таамагласан) — дараалал баталгаагүй.
8. **[LOW]** Өөрийн кодод extensibility нээгээгүй public процесс (partner-ийн
   extension-ээс өргөтгөх боломжгүй монолит) — OnBefore/OnAfter event нэмэхийг зөвлө.
