# Performance Reference — Database гүйцэтгэлийн шалгалт

## Суурь зарчим (Base App-ийн дадал)

- Record үйлдэл бүр SQL round-trip: тоог нь цөөл (FindSet loop, temp буфер,
  CalcSums, Query), талбарыг нь цөөл (SetLoadFields — 994 газар), түгжээг богиносго
  (хожуу LockTable, лүүкапд ReadIsolation(ReadUncommitted) — 183 газар),
  индексээ тааруул (SetCurrentKey, SIFT).
- Existence = IsEmpty(); нийлбэр = CalcSums/Query; bulk = ModifyAll/DeleteAll;
  setup = нэг удаа Get + cache.

## Дүрмүүд

### BC-PERF-001 [HIGH том хүснэгт / MEDIUM бусад] — Loop доторх давтан уншилт
`repeat ... Get/FindFirst/Setup.Get ... until` түлхүүр нь өөрчлөгдөхгүй/цөөн
утгатай үед. **Засвар:** `if Item."No." <> Line."No." then Item.Get(...)` cache,
Dictionary, урьдчилсан ачаалалт.

### BC-PERF-002 [HIGH] — Filter-гүй scan том хүснэгт дээр
Item Ledger Entry, G/L Entry, Value Entry, Cust./Vendor Ledger Entry, Warehouse
Entry дээр filter-гүй FindSet/Count; filter-ийг loop доторх if-ээр хийх.
**Засвар:** SetRange/SetFilter + CalcSums/Query; тохирох key.

### BC-PERF-003 [MEDIUM] — Existence шалгалтын буруу хэлбэр
`Count() > 0`, утга ашиглахгүй FindFirst/FindSet → `IsEmpty()`.

### BC-PERF-004 [MEDIUM] — SetLoadFields дутуу/буруу
Том хүснэгтээс цөөн талбар уншихад SetLoadFields байхгүй; эсвэл жагсаалтад ороогүй
талбар ашиглаж implicit reload (давхар query!). Modify хийх record-д бүрэн ачаалал
хэрэгтэйг анхаар.

### BC-PERF-005 [MEDIUM] — Давтан CalcFields
Loop дотор мөр бүрт CalcFields; SIFT-гүй FlowField-ийн CalcFields. **Засвар:**
CalcSums, Query, нэг CalcFields-д нэгтгэх, хувьсагчид хадгалах.

### BC-PERF-006 [LOW] — Loop бичилт vs ModifyAll/DeleteAll
Тогтмол утгын bulk update loop-оор → ModifyAll (trigger хэрэггүй бол RunTrigger=false).

### BC-PERF-007 [LOW] — Шаардлагагүй Modify
Өөрчлөлт шалгалгүй Modify; давхар Modify; xRec харьцуулалтгүй дахин бичилт.

### BC-PERF-008 [MEDIUM] — Key/индексийн зөрүү
Filter-ийн багц key-тэй таарахгүй том хүснэгт; SumIndexFields-гүй CalcSums;
unbounded өсөлттэй шинэ хүснэгтэд хэрэгцээт key байхгүй.

### BC-PERF-009 [MEDIUM] — ReadIsolation
Бичилт шийдвэрлэх уншилтад ReadUncommitted = буруу өгөгдлийн эрсдэл [HIGH тал руу];
лүүкап/report уншилтад ашиглаагүй бол сайжруулалт санал болго [LOW].

## Ялгаж салгах

- Journal/document мөрийн боловсруулалтад temp table copy (FillTempLines загвар) —
  зөв, дэмж.
- ReadIsolation(ReadUncommitted) + SetLoadFields хосолсон лүүкап (Customer.OnInsert-ийн
  давхардал шалгалт шиг) — стандарт сайн хэлбэр.
- FindSet(true) зөвхөн бичилт хийх loop-д; уншилтын loop-д FindSet().
