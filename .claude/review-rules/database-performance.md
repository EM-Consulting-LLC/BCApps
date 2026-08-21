# Database Performance Review Rules — BC-PERF

---

## BC-PERF-001 — Get/Find inside loop (loop доторх давтан уншилт)

- **Severity:** HIGH (том хүснэгт/урт loop), MEDIUM (бусад)
- **Rule:** Loop дотор түлхүүр нь өөрчлөгдөхгүй эсвэл цөөн утгатай Get/FindFirst/
  FindSet давтагдаж байвал илрүүлнэ.
- **Why:** Мөр бүрт SQL round-trip — N+1 асуудал. Base App нь ийм уншилтыг loop-ийн
  гадна cache хийдэг (`if Item."No." <> Line."No." then Item.Get(...)`).
- **Risk:** Том баримт/журнал дээр posting минутаар удаашрах; lock хугацаа уртсах.
- **Detection:** `repeat ... Rec.Get(...) ... until` бүтэц; SetRange+FindFirst
  loop дотор; Setup.Get loop дотор.
- **Example — Bad:**
  ```al
  repeat
      Customer.Get(SalesLine."Sell-to Customer No."); // ихэвчлэн ижил customer
  until SalesLine.Next() = 0;
  ```
- **Example — Good:**
  ```al
  repeat
      if Customer."No." <> SalesLine."Sell-to Customer No." then
          Customer.Get(SalesLine."Sell-to Customer No.");
  until SalesLine.Next() = 0;
  ```
- **Suggested Fix:** Түлхүүр харьцуулах cache, Dictionary, эсвэл урьдчилан
  temp table-д ачаалах.

---

## BC-PERF-002 — Filter-гүй scan том хүснэгт дээр

- **Severity:** HIGH
- **Rule:** Ledger төрлийн том хүснэгт (Item Ledger Entry, G/L Entry, Value Entry,
  Cust./Vendor Ledger Entry, Warehouse Entry, Change Log Entry) дээр filter-гүй/
  сул filter-тэй FindSet/Count/loop илрүүлнэ; filter-ийг AL талд if-ээр хийж байвал мөн.
- **Why:** Эдгээр хүснэгт сая мөртэй байдаг; бүрэн scan нь DB-г дарамтална.
- **Risk:** Timeout, table scan lock, production удаашрал.
- **Detection:** SetRange/SetFilter-гүй FindSet(); loop дотор `if Entry."Item No." = X then` хэлбэрийн шүүлт.
- **Example — Good:**
  ```al
  ItemLedgEntry.SetRange("Item No.", ItemNo);
  ItemLedgEntry.SetRange("Posting Date", FromDate, ToDate);
  ItemLedgEntry.CalcSums(Quantity);
  ```
- **Suggested Fix:** Бүх шүүлтийг SetRange/SetFilter-ээр; нийлбэрт CalcSums/Query;
  тохирох key байгаа эсэхийг шалга.

---

## BC-PERF-003 — Existence шалгалтын буруу хэлбэр

- **Severity:** MEDIUM
- **Rule:** "Байгаа эсэх"-ийг Count() > 0, FindFirst + утга ашиглахгүй, FindSet +
  утга ашиглахгүй хэлбэрээр шалгаж байвал илрүүлнэ.
- **Why:** IsEmpty() нь хамгийн хөнгөн (TOP 1, талбар уншихгүй). Base App-д
  системтэй ашиглагддаг (`if not Job.IsEmpty() then Error(...)`).
- **Risk:** Шаардлагагүй өгөгдөл уншилт; Count бол бүрэн тоолол.
- **Detection:** `Count() > 0`, `Count() <> 0`, эсвэл Find*-ийн дараа record-ын
  утга ашиглаагүй if.
- **Example — Good:** `if not CustLedgEntry.IsEmpty() then Error(...);`
- **Suggested Fix:** IsEmpty()-гээр соль.

---

## BC-PERF-004 — SetLoadFields дутуу том уншилтад

- **Severity:** MEDIUM
- **Rule:** Том/өргөн хүснэгтээс (Sales Line, Item, Customer, ledger-үүд) цөөн
  талбар ашиглах Get/Find-д SetLoadFields байхгүй бол; мөн SetLoadFields-д
  ороогүй талбар дараа нь ашиглагдаж implicit reload үүсгэж байвал илрүүлнэ.
- **Why:** Base App шинэ кодод тогтмол хэрэглэдэг (994 газар): багана цөөрөх нь
  I/O болон memory багасгана; JIT reload нь харин ДАВХАР уншилт үүсгэдэг.
- **Risk:** Удаашрал; buruu SetLoadFields нь nuгасан давхар query.
- **Detection:** Loop/олон удаагийн Get-тэй, 1-3 талбар ашигладаг уншилт;
  SetLoadFields жагсаалт vs хэрэглэсэн талбаруудын зөрүү.
- **Example — Good:**
  ```al
  Item.SetLoadFields(Blocked, "Sales Blocked");
  Item.Get(No);
  Item.TestField(Blocked, false); // зөвхөн ачаалсан талбар
  ```
- **Suggested Fix:** SetLoadFields нэм; ашиглах бүх талбарыг жагсаалтад оруул;
  Modify хийх record-д SetLoadFields болгоомжтой (бүрэн ачаалал хэрэгтэй).

---

## BC-PERF-005 — Давтан CalcFields / loop доторх FlowField

- **Severity:** MEDIUM
- **Rule:** Loop дотор мөр бүрт CalcFields, эсвэл нэг record-д ижил CalcFields
  олон удаа дуудагдаж байвал илрүүлнэ.
- **Why:** FlowField бүр тусдаа SUM/COUNT query. Base App нийлбэрийг CalcSums эсвэл
  Query-ээр, нэг дор бодуулдаг.
- **Risk:** N query — удаашрал.
- **Detection:** `repeat ... CalcFields(...) ... until`; SIFT байхгүй талбар дээрх
  CalcFields (бүр удаан).
- **Suggested Fix:** CalcSums (source хүснэгт дээр), Query, эсвэл нэг удаа CalcFields
  хийгээд хувьсагчид хадгал; олон FlowField-ийг нэг CalcFields дуудлагад нэгтгэ.

---

## BC-PERF-006 — Loop бичилт vs ModifyAll/DeleteAll

- **Severity:** LOW
- **Rule:** Trigger логик шаардлагагүй bulk update/delete-ийг loop-оор Modify/Delete
  хийж байвал илрүүлнэ.
- **Why:** ModifyAll/DeleteAll нэг SQL statement болдог (RunTrigger=false үед).
- **Detection:** `repeat Rec.Field := X; Rec.Modify(); until` — Field утга тогтмол бол.
- **Suggested Fix:** `Rec.ModifyAll(Field, X)`; trigger хэрэгтэй бол loop үлдээж
  тайлбарла. Upgrade кодод үргэлж ModifyAll(..., false) сонго.

---

## BC-PERF-007 — Шаардлагагүй Modify / хоосон бичилт

- **Severity:** LOW
- **Rule:** Утга өөрчлөгдөөгүй байхад Modify дуудах, xRec-тэй харьцуулалгүй OnModify
  дахин бичилт, давхар Modify илрүүлнэ.
- **Why:** Бичилт бүр lock + version bump — өөрчлөлтгүй бичилт зөвхөн зардал.
- **Detection:** if-гүй Modify; `Rec.Modify(true)` дараалан хоёр удаа.
- **Suggested Fix:** Өөрчлөлтийг шалгаад Modify; нэг Modify-д нэгтгэ.

---

## BC-PERF-008 — Key/индексийн зөрүү

- **Severity:** MEDIUM
- **Rule:** Их өгөгдөлтэй хүснэгтэд filter-ийн багц нь ямар ч key-тэй таарахгүй,
  эсвэл SetCurrentKey нь filter-тэй үл нийцэж байвал; шинэ хүснэгтэд unbounded
  өсөлттэй атлаа хэрэгцээт key/SIFT байхгүй бол илрүүлнэ.
- **Why:** Base App filter бүрд тохирсон key ашигладаг
  (`VendLedgEntry.SetCurrentKey("External Document No.")` шиг).
- **Risk:** Table scan; SIFT-гүй CalcSums бүрэн уншилт.
- **Detection:** SetRange-ийн талбарууд table key-үүдтэй харьцуул; CalcSums-ийн
  талбар SumIndexFields-д байгаа эсэх.
- **Suggested Fix:** Тохирох key нэм (том хүснэгтэд болгоомжтой — bичилтийн зардал),
  эсвэл одоо байгаа key-д таарах filter бүтэц ашигла.

---

## BC-PERF-009 — ReadIsolation-ийн зохисгүй хэрэглээ

- **Severity:** MEDIUM
- **Rule:** (a) Бичилт шийдвэрлэх уншилтад ReadUncommitted; (b) хурц concurrency
  цэг дэх лүүкапд default isolation (lock оруулах шаардлагагүй байхад) — хоёуланг үнэл.
- **Why:** Base App: лүүкап уншилтад ReadUncommitted (ItemJnlCheckLine-ийн Item.Get),
  харин идемпотенц/balance шалгалтад хэзээ ч үгүй.
- **Risk:** (a) dirty read-ээр буруу шийдвэр; (b) шаардлагагүй блок.
- **Detection:** ReadIsolation(ReadUncommitted)-ийн дараах утга бичилтийн нөхцөлд
  ашиглагдаж байгаа эсэх.
- **Suggested Fix:** Зөвхөн report/лүүкап/telemetry уншилтад ReadUncommitted;
  шийдвэрлэх уншилтад UpdLock хүртэл авч үзэх.
