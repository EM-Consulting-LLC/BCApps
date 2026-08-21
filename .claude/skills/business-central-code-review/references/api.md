# API Reference — API page ба web service-ийн шалгалт

## Стандарт (APIV2-ийн бүх page-ээс)

```al
page 30012 "APIV2 - Sales Invoices"
{
    PageType = API;  APIVersion = 'v2.0';
    EntityName = 'salesInvoice';  EntitySetName = 'salesInvoices';  // camelCase
    ODataKeyFields = Id;              // SystemId — тогтвортой түлхүүр
    DelayedInsert = true;             // талбарууд бүрэн ирээд Insert
    ChangeTrackingAllowed = true;  Extensible = false;
    SourceTable = "Sales Invoice Entity Aggregate";  // draft+posted нэгтгэсэн буфер
}
```
- Талбар бүрийн OnValidate-д `RegisterFieldSet` (template-тэй зөв нэгтгэх).
- Reference: `GetBySystemId` шалгаад олдохгүй бол тодорхой Error; Id + No. хоёулаа
  ирээд зөрвөл reject.
- Үйлдэл: `[ServiceEnabled]` bound action; PostAndSend = Post → **Commit** → Send.
- Custom API-д: APIPublisher, APIGroup, өөрийн namespace заавал.

## Дүрмүүд

### BC-API-001 [HIGH] — Contract breaking change
Талбар устгах/нэр солих, EntityName/ODataKeyFields өөрчлөх, төрлийн семантик
өөрчлөлт. **Засвар:** нэмэлт нь backward-compatible; өөрчлөлт бол шинэ version.

### BC-API-002 [MEDIUM] — Бүтцийн стандарт зөрчил
SystemId биш түлхүүр, DelayedInsert байхгүй, camelCase биш нэршил, том баримтад
aggregate биш түүхий хүснэгт, custom API-д Publisher/Group байхгүй.

### BC-API-003 [MEDIUM] — Validation/алдааны чанар
GetBySystemId үр дүн шалгаагүй, зөрсөн хос утга reject хийгдээгүй, generic 500
өгөх алдаа.

### BC-API-004 [HIGH] — Bound action-ийн transaction дэг
[ServiceEnabled] action: posting-ийн дараа Commit-гүй гадаад үйлдэл; давтан
дуудлагад давхар үйлдэл (идемпотенц шалгалт байхгүй). Client retry ердийн зүйл
гэдгийг санаарай.

### BC-API-005 [MEDIUM] — Query/хуудаслалт
UI page-ийг web service болгох; parent filter-гүй бүх child ачаалах; хязгааргүй
уншилт.

## Шалгах фокус цэгүүд

- API page-ийн OnInsert/OnModify/OnDelete trigger-т бизнес урсгал шигтгэсэн үү
  (Graph Mgt/aggregate codeunit-д байх ёстой)?
- Deprecated болгохгүйгээр field id өөрчилсөн үү?
- Enum талбар API-д Text/Option аль хэлбэрээр ил гарч байна, утга нэмэхэд гадаад
  тал эвдрэх үү?
