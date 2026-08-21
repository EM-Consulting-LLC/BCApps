# Database Performance — Өгөгдлийн сангийн гүйцэтгэлийн мэдлэгийн сан

## 1. Зарчим

AL-ийн record үйлдэл бүр SQL дуудлага болдог тул **DB round-trip-ийн тоо** гол
хэмжигдэхүүн. Microsoft-ийн код: (1) аль болох цөөн дуудлага, (2) аль болох цөөн
талбар, (3) аль болох богино түгжээ, (4) зөв индекс гэсэн дөрвөн чиглэлээр
тогтмол оптимизаци хийдэг.

## 2. Source code дээрх ажиглалт

| Pattern | Жишээ | Тоо |
|---|---|---|
| `FindSet()` + `repeat...until Next() = 0` | Бүх мөр уншилт | стандарт |
| `IsEmpty()` | `if not Job.IsEmpty() then Error(...)` — existence шалгалт | өргөн |
| `SetLoadFields(...)` | `SalesInvoiceLine.SetLoadFields("Order No.")` дараа нь Get/Find | 994 |
| `ReadIsolation(IsolationLevel::ReadUncommitted)` | ItemJnlCheckLine-ийн Item.Get, Customer.OnInsert давхардлын шалгалт | 183 |
| `SetCurrentKey` | `VendLedgEntry.SetCurrentKey("External Document No.")` — филтерт таарсан индекс | өргөн |
| Temp buffer | GL entries TempGLEntryBuf-д цугларч нэг дор Insert | posting бүхэлдээ |
| `ModifyAll/DeleteAll` | Upgrade: `NoSeriesLine.ModifyAll(Implementation, ..., false)` — RunTrigger=false | bulk |
| Query object | `QtyReservedFromItemLedger` — aggregate-ийг серверт бодуулна | 152 query |
| `CalcSums` | Filtered SumIndexField уншилт (loop-гүй нийлбэр) | өргөн |
| Setup caching | GetGLSetup()/GetSalesSetup() — global флагтай lazy-load | бүх posting |
| Хожуу LockTable | Sales-Post: validation дууссаны ДАРАА LockTables | posting |
| `Get` давхардуулахгүй | Global record + Read флаг | өргөн |

Мөн: `FindFirst`/`FindLast` зөвхөн ганц бичлэг хэрэгтэй үед; `Find('-')` legacy;
`Next()`-тэй loop-ийг `FindSet()`-ээр эхлүүлдэг (FindFirst-ээр биш).

## 3. Яагаад ингэж хийсэн бэ (analysis)

- `IsEmpty()` нь TOP 1, 0 талбар уншдаг — `FindFirst`-ээс хөнгөн; `Count() = 0`-ээс
  бүр хөнгөн.
- `SetLoadFields` нь SELECT-ийн багана цөөрүүлж JOIN-гүй том хүснэгтэд (Sales Line,
  Item Ledger Entry) мэдэгдэхүйц ялгаа өгдөг; ялангуяа BLOB/Media талбартай хүснэгтэд.
- `ReadIsolation(ReadUncommitted)` — зөвхөн лүүкап зорилготой уншилтад түгжээ
  тавихгүй, deadlock магадлал бууруулна. Бичилт шийдвэрлэх уншилтад хэрэглэдэггүй.
- Хожуу LockTable — түгжээ баригдах хугацааг богиносгож олон хэрэглэгчийн
  concurrency сайжруулна.
- RunTrigger=false ModifyAll — trigger талбар бүрт ажиллавал O(n) codeunit дуудлага
  болно; upgrade-д зөвшөөрөгдсөн, бизнес урсгалд болгоомжтой.

## 4. Зөв хэрэгжилт

```al
// Existence шалгалт
CustLedgEntry.SetRange("Customer No.", Customer."No.");
CustLedgEntry.SetRange(Open, true);
if not CustLedgEntry.IsEmpty() then
    Error(OpenEntriesExistErr);

// Цөөн талбартай уншилт
Item.SetLoadFields(Blocked, "Base Unit of Measure");
Item.Get(SalesLine."No.");

// Нийлбэр — loop-гүй
DtldCustLedgEntry.SetRange("Customer No.", CustNo);
DtldCustLedgEntry.SetFilter("Posting Date", '..%1', AsOfDate);
DtldCustLedgEntry.CalcSums(Amount);

// Loop-ийн гадна лүүкап cache
if Item."No." <> SalesLine."No." then
    Item.Get(SalesLine."No.");
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: loop дотор Get/FindFirst (N+1 асуудал)
SalesLine.FindSet();
repeat
    Item.Get(SalesLine."No.");                 // мөр бүрт DB дуудлага, cache байхгүй
    Cust.SetRange("No.", SalesLine."Sell-to Customer No.");
    Cust.FindFirst();                          // SetRange+FindFirst нь Get-ээс удаан
until SalesLine.Next() = 0;

// БУРУУ: filter-гүй FindSet — бүх хүснэгт уншина
ItemLedgEntry.FindSet();                       // Item Ledger Entry сая мөртэй байж болно!
repeat
    if ItemLedgEntry."Item No." = ItemNo then  // filter-ийг AL талд хийж байна
        Total += ItemLedgEntry.Quantity;
until ItemLedgEntry.Next() = 0;
// Зөв нь: SetRange("Item No.") + CalcSums(Quantity)

// БУРУУ: Count() > 0 existence шалгалтад
if SalesLine.Count() > 0 then ...              // бүх мөр тоолно; IsEmpty() хангалттай

// БУРУУ: loop дотор давтан CalcFields
repeat
    Customer.CalcFields("Balance (LCY)");      // FlowField бүр SUM query
until ...;

// БУРУУ: шаардлагагүй Modify
SalesLine."Description 2" := SalesLine."Description 2"; // өөрчлөлтгүй
SalesLine.Modify(true);                                  // trigger + бичилт дэмий
```

## 6. Code review хийх дүрэм

1. **[HIGH]** Loop дотор өөрчлөгдөөгүй түлхүүрээр Get/FindFirst/CalcFields давтагдаж
   байвал — cache эсвэл join/query санал болго. (Том хүснэгт бол HIGH, жижиг Setup бол MEDIUM.)
2. **[HIGH]** Том ledger хүснэгт (Item Ledger Entry, G/L Entry, Value Entry,
   Cust./Vendor Ledger Entry) дээр filter-гүй эсвэл сул filter-тэй FindSet/Count
   байвал.
3. **[MEDIUM]** Existence шалгалтад FindFirst/Count ашигласан бол IsEmpty() зөвлө;
   мөр unread үлдээж байвал FindSet-ийн оронд IsEmpty.
4. **[MEDIUM]** Нийлбэр тооцоход loop ашигласан бол CalcSums/Query зөвлө
   (SumIndexField байгаа эсэхийг хамт шалга).
5. **[MEDIUM]** Цөөн талбар ашиглах том хүснэгтийн уншилтад SetLoadFields байхгүй
   бол зөвлө (ялангуяа loop, том scan). NB: SetLoadFields-ийн дараа бусад талбар
   хэрэглэвэл implicit reload — талбарын жагсаалт бүрэн эсэхийг шалга.
6. **[MEDIUM]** Filter-т тохирох key байхгүй SetRange/SetFilter их өгөгдөл дээр —
   SetCurrentKey/шинэ key-ийн хэрэгцээг дурд.
7. **[MEDIUM]** Lock хийх шаардлагагүй лүүкап уншилт хурц concurrency цэгт байвал
   ReadIsolation(ReadUncommitted) боломж; харин бичилт шийдвэрлэх уншилтад
   ReadUncommitted байвал HIGH (зөв өгөгдлийн эрсдэл).
8. **[MEDIUM]** LockTable-ийг процессын хамгийн эхэнд барьж удаан validation хийж
   байвал — түгжээг хожуу шилжүүл.
9. **[LOW]** Өөрчлөлт байгаа эсэхийг шалгалгүй Modify; xRec харьцуулалтгүй OnModify
   дахин бичилт.
10. **[LOW]** ModifyAll/DeleteAll ашиглаж болох loop бичилт (trigger хэрэггүй үед).
