# API Review Rules — BC-API

---

## BC-API-001 — API contract breaking change

- **Severity:** HIGH
- **Rule:** Одоо байгаа API page-ээс талбар устгах, нэр солих (field name,
  EntityName/EntitySetName), төрлийн семантик өөрчлөх, ODataKeyFields солих
  өөрчлөлт илрүүлнэ.
- **Why:** API page нь гадаад гэрээ: APIV2 нь Extensible=false, тогтвортой
  camelCase нэршилтэй; өөрчлөлт нь хувилбар нэмэх замаар хийгддэг (v1.0 → v2.0).
- **Risk:** Гадаад интеграцууд нэг дор эвдэрнэ.
- **Detection:** *.Page.al (PageType = API) diff-д field(...) устгал/нэр өөрчлөлт;
  APIVersion өөрчлөлт.
- **Suggested Fix:** Шинэ талбар нэмэх (backward compatible) эсвэл шинэ API
  version/entity гарга; хуучныг deprecate хий.

---

## BC-API-002 — API page-ийн бүтцийн стандарт

- **Severity:** MEDIUM
- **Rule:** Шинэ API page дараах стандартаас гажсан бол илрүүлнэ:
  `ODataKeyFields = SystemId` биш; `DelayedInsert = true` байхгүй; EntityName/
  EntitySetName camelCase биш; APIVersion, APIPublisher/APIGroup (custom API-д)
  байхгүй; том баримтад Entity/aggregate буфер биш шууд түүхий хүснэгт.
- **Why:** APIV2-ийн бүх page ижил хэлбэртэй: SystemId түлхүүр (дугаар өөрчлөгдөхөөс
  хамгаална), DelayedInsert (талбарууд бүрэн ирсний дараа Insert), RegisterFieldSet
  (template-тэй зөв нэгтгэх).
- **Risk:** Тогтворгүй түлхүүр, талбар дутуу Insert, template зөрчил.
- **Detection:** PageType = API объектын property-уудыг чеклистээр тулга.
- **Suggested Fix:** APIV2 pattern-аар засах (APIV2SalesInvoices.Page.al лавлагаа).

---

## BC-API-003 — API validation ба алдааны чанар

- **Severity:** MEDIUM
- **Rule:** API талбарын OnValidate reference утгыг шалгахгүй (GetBySystemId-ийн
  үр дүн шалгаагүй), зөрчилтэй хос утгыг (Id + No. хоёулаа ирэхэд) reject хийхгүй,
  алдаа нь ойлгомжгүй бол илрүүлнэ.
- **Why:** APIV2: `if not SellToCustomer.GetBySystemId(...) then
  Error(CouldNotFindSellToCustomerErr)`; зөрсөн утгад
  `SellToCustomerValuesDontMatchErr`.
- **Risk:** 500 алдаа эсвэл чимээгүй буруу холбоос.
- **Detection:** API page-ийн OnValidate-уудад Get/GetBySystemId шалгалтгүй
  assignment.
- **Suggested Fix:** Reference бүрд лүүкап + тодорхой Error; хос талбарын
  зөрчлийг шалга.

---

## BC-API-004 — Bound action-ийн transaction дэг

- **Severity:** HIGH
- **Rule:** [ServiceEnabled] action дотор: posting хийгээд Commit-гүйгээр гадаад
  үйлдэл (email, HTTP) хийх; эсвэл давтан дуудлагад давхар үйлдэл хийх боломж
  илрүүлнэ.
- **Why:** APIV2 PostAndSend: Post → **Commit** → Send — илгээлт унасан ч posting
  үлдэнэ; Post action давтан дуудагдвал GetDraftInvoice олдохгүй тул давхардахгүй.
- **Risk:** Клиент retry хийхэд давхар posting/илгээлт; хагас үр дүн.
- **Detection:** [ServiceEnabled] procedure-ийн бие: Post* дуудлагын дараах гадаад
  үйлдлийн өмнө Commit байгаа эсэх; давтан дуудлагын идемпотенц.
- **Suggested Fix:** Commit-ийг гадаад үйлдлийн өмнө; статус/existence-ээр идемпотенц.

---

## BC-API-005 — Query/хуудаслалтын хамгаалалт

- **Severity:** MEDIUM
- **Rule:** API-гаас том хэмжээний child өгөгдөл ачаалахад хязгаар/шүүлтгүй,
  Deferred биш бүх expand хийх; API-д зориулаагүй page-ийг web service болгон
  ил гаргах тохиолдол илрүүлнэ.
- **Why:** APIV2 line-ууд тусдаа entity, парент id-аар шүүгддэг; UI page-ийг
  OData болгох нь trigger-ийн gazillion дуудлага үүсгэдэг.
- **Risk:** Timeout, өндөр ачаалал.
- **Detection:** Web service бүртгэлд UI page; API page-д parent filter-гүй
  бүх өгөгдлийн уншилт.
- **Suggested Fix:** Зориулалтын API page/query ашигла; шүүлтийг ил болго.
