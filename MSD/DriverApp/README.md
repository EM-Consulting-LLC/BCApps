# MSD Driver App — BC mobile prototype

Жолоочийн аппын (Mobile Execution Layer, DEL-001…016) Business Central дээрх AL extension прототип.
Тусдаа апп биш, **Business Central mobile app** (утас / таблет) дээр ажилладаг. Хуудсууд нь BC-ийн
утасны хязгаарлалтыг харгалзан хийгдсэн:

- утсан дээр зөвхөн Promoted action харагдана → бүх жолоочийн action `area(Promoted)`-д байна
- Worksheet хуудас утсан дээр нээгддэггүй → буцаалтыг Card + ListPart хуудсаар оруулна
- ≡ цэс = Role Center-ийн `area(Embedding)`

## Урсгал

```
Supervisor: Get Sales Orders → Release to Driver                         (WMS урсгалыг орлоно)
Driver:     Ready to Load ──LOADED──▶ Loaded ──START──▶ In Transit ──FINISH──▶ Completed ──DELIVERED
            цэг бүр LOADED   туслах 1–2 нэмнэ    цэг бүр Fully /           дараагийн START-ыг
            тэмдэглэх,       (DEL-003)           Partially / Cancel        нээнэ (DEL-013)
            дараалал ▲▼                          (DEL-005, 007)
            (DEL-004, 014)
Background: Fully/Partially → Job Queue нэхэмжлэл post (DEL-008) → Partially бол SRO авто үүснэ (DEL-010)
```

## Шаардлагын хамрах хүрээ

| ID | Хаана |
|---|---|
| DEL-001 | `MSD Delivery Batch List`: зөвхөн өөрийн, Ready to Load..Completed төлөвтэй batch. Supervisor-ийн `Release to Driver` нь Warehouse Shipment post хийснийг орлоно |
| DEL-002 | `MSD Driver Mgt.StartDelivery` + `MSD Delivery Log Entry` |
| DEL-003 | `MSD Batch Helpers` part. Хамгийн багадаа 1, дээд тоо Setup-д (default 2) |
| DEL-004 | Stops part → `LOADED тэмдэглэх`, card → `LOADED`. Ачаагүй захиалга түгээгдэхгүй |
| DEL-005, 007 | `MSD Delivery Stop Card`: Fully / Partially / Cancel. Зөвхөн дараагийн цэгийг бүртгэнэ. Skip хийсэн цэг төгсгөлд шилжинэ |
| DEL-006 | Stop Card → `Төлбөрийн нөхцөл` (Бэлэн / Бэлэн бус / Зээл) → Setup-д Payment Method-той холбогдоно |
| DEL-008 | `MSD Delivery Posting` (Job Queue) → `MSD Delivery Invoice Post` |
| DEL-009 | `MSD Partial Delivery` + `MSD Return Lines Part` |
| DEL-010 | `MSD Delivery Return Order`: Posted Sales Invoice-ийн мөрт reference, `Appl.-from Item Entry` |
| DEL-011 | Cancel → Return Reason заавал, нэхэмжлэл үүсэхгүй |
| DEL-012 | `FINISH`: бүх ачсан цэг бүртгэгдсэн байх |
| DEL-013 | `DELIVERED` action. Бөглөөгүй бол дараагийн batch START хийгдэхгүй |
| DEL-014 | Stops part → `Дээш` / `Доош` (START-аас өмнө) |
| DEL-015 | Бүртгэх үед GPS (System App `Geolocation`) + зай line болон log-д хадгалагдана |
| DEL-016 | `MSD Geofence Mgt.`: харилцагчийн радиусаас гадуур бол төлөв өөрчлөгдөхгүй |

## Объектууд (50100–50115)

| Төрөл | Объект |
|---|---|
| Table | Delivery Setup, Distribution Worker, Delivery Batch Header / Line / Helper, Delivery Return Line, Delivery Log Entry, Driver Cue |
| Table ext | Customer (Latitude, Longitude, Geofence Radius), Sales Header (Delivery Status, Batch No.), Sales Line (Ref. Invoice No./Line No.) |
| Codeunit | Driver Mgt., Geofence Mgt., Delivery Invoice Post, Delivery Posting (Job Queue), Delivery Return Order, Delivery Batch Mgt. |
| Page — жолооч | Driver Role Center, Driver Activities, Delivery Batch List / Card, Delivery Stops, Batch Helpers, Delivery Stop Card, Stop Order Lines, Partial Delivery, Return Lines Part, Delivery Log Entries |
| Page — супервайзер | Supervisor Batches / Batch / Batch Lines, Distribution Workers, Delivery Setup |
| Бусад | Profile `MSD DRIVER`, Permission set `MSD DRIVER`, `MSD DELIVERY ADMIN` |

## Демо тохиргоо

1. Extension-ийг sandbox руу publish хийнэ (`app.json`: application 26.0, runtime 15.0. Шаардлагатай бол хувилбарыг өөрчилнө).
2. **MSD Delivery Setup**: `Delivery Batch Nos.`, Payment Method гурвыг тохируулна.
   - Демод `Post via Job Queue` = Off байвал нэхэмжлэл шууд post хийгдэнэ (жолоочид posting эрх хэрэгтэй болно).
   - Бодит орчинд On байлгаад `Job Queue үүсгэх` дарна. Job Queue-г posting эрхтэй service user-ээр ажиллуулна (WMS-089).
3. **Distribution Workers**: жолооч (Role = Driver, User ID, Vehicle No.), 2–3 туслах (Role = Helper).
4. Жолоочийн хэрэглэгчид: profile `MSD DRIVER`, permission set `MSD DRIVER` + стандарт уншах эрх (Customer, Sales Line, Return Reason).
5. **Return Reasons**: ABSENT, REFUSED, DAMAGED, EXPIRED, WRONGITEM гэх мэт.
6. Customer Card → *Delivery Point (Geofence)*: координат, радиус (метр). Geofence-ийг Setup дээр асаана.
7. Released Sales Order-уудыг үүсгээд Warehouse Shipment-ийг post хийнэ (нэхэмжлэх тоо = shipped not invoiced).
8. **Delivery Batches** → New → Driver, Delivery Date → `Get Sales Orders` → `Release to Driver`.
9. Утсаар BC mobile app-аар нэвтэрч MSD DRIVER Role Center-ээс эхэлнэ.

## Прототип дээр гаргасан шийдвэрүүд (баталгаажуулах)

- **Geofence радиус метрээр.** Шаардлагад "50/100/150 км" гэсэн нь хэт том тул метр гэж үзэв (`Default Geofence Radius (m)` = 150).
- **Partially**: shipped тоогоор бүтэн нэхэмжилж, буцаасан барааг Posted Sales Invoice-ийн мөрт reference хийсэн Sales Return Order болгоно (DEL-010). SRO post хийгдэхгүй, супервайзер хүлээн авна (WMS-102). WMS-097-д *Posted Sales Shipment* гэж зөрүүтэй бичигдсэн.
- **Cancel**: нэхэмжлэл үүсэхгүй. Undo Shipment-ийг супервайзер хийнэ (WMS-101). Аппад хийгдээгүй.
- **Skip**: шаардлагад байхгүй ч прототипийн дагуу нэмсэн. FINISH-ийн өмнө заавал бүртгэнэ.
- **DELIVERED (DEL-013)**: Completed-ийн дараах тусдаа баталгаажуулалт (`Delivered Confirmed`) гэж үзэв.
- **Ачаагүй захиалга**: түгээгдэхгүй, FINISH үед log-д бичигдэнэ. Shipment-ийг буцаах урсгал тодорхойгүй.
- **Нэг жолооч, нэг идэвхтэй batch**: In Transit batch байхад өөр batch START хийгдэхгүй.
- **Posting алдаа**: жолооч цааш үргэлжлүүлнэ. Супервайзер шалтгааныг засаад `Retry Posting` дарна.

## Анхааруулга

Энэ орчинд AL compiler болон BC symbol татах боломжгүй байсан тул код **compile хийгдээгүй**.
Base App / System App-ын объект, талбарын нэрийг BCApps репогийн эх кодтой тулгаж шалгасан.
Эхлээд VS Code + AL Language-ээр compile хийж, гарсан алдааг засна уу.
