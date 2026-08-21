# Integration Review Rules — BC-INT

---

## BC-INT-001 — Идемпотенцгүй импорт/синк (давхар өгөгдөл)

- **Severity:** CRITICAL
- **Rule:** Гадаад системээс өгөгдөл татаж бичдэг урсгал (импорт, webhook хүлээн
  авалт, scheduled sync) давтан ажиллахад давхар бичлэг үүсгэхээс хамгаалагдаагүй
  бол илрүүлнэ.
- **Why:** Стандарт sync engine бичлэг бүрийг coupling (Integration Record мэппинг)
  бүртгэлээр таньж, боловсруулсан хэсгээ Commit checkpoint-оор тэмдэглэдэг —
  тасалдсан sync дахин эхлэхэд давхардахгүй.
- **Risk:** Давхар төлбөр, давхар баримт, давхар журнал мөр — санхүүгийн зөрүү.
- **Detection:** Импортын loop-д external id-аар existence шалгалт байгаа эсэх;
  timeout/алдааны дараа дахин дуудахад юу болохыг мөрд; "Get-then-Insert"-ийн
  хооронд өөр session орж болох эсэх (LockTable).
- **Example — Good:** api-integration.md-ийн TaxDocLog жишээ (status машин +
  external id + Commit checkpoint).
- **Suggested Fix:** External Id/Document Id талбар + unique key эсвэл existence
  шалгалт; боловсруулсан хэсгээ checkpoint-лох; source талын cursor/Modified On
  filter хадгалах.

---

## BC-INT-002 — HTTP алдаа/статусын боловсруулалт

- **Severity:** HIGH
- **Rule:** HttpClient үйлдлийн (a) Send-ийн boolean үр дүн, (b) IsSuccessStatusCode/
  StatusCode шалгагдахгүй, (c) алдааны хариултын мэдээлэл логлогдохгүй бол илрүүлнэ.
- **Why:** Стандарт код статус код, reason phrase-ийг барьж лог хүснэгтэд
  Commit-тэйгээр хадгалдаг (ImportConsolidationFromAPI).
- **Risk:** 4xx/5xx хариултыг амжилт мэт боловсруулж эвдэрхий өгөгдөл орох;
  оношилгоо боломжгүй.
- **Detection:** `HttpClient.Send(...)`/Get/Post дуудлагын дараах шалгалтууд;
  Content.ReadAs-ийг статус шалгалгүй ашиглах.
- **Suggested Fix:** Send үр дүн + StatusCode шалга; алдааны body-г логло
  (нууцгүйгээр); Retry-After/429-д backoff.

---

## BC-INT-003 — Retry стратеги ба давталт

- **Severity:** MEDIUM
- **Rule:** (a) Транзиент алдаанд (timeout, 429, 503) ямар ч retry байхгүй чухал
  илгээлт; (b) эсрэгээр — идемпотенц баталгаагүй үйлдлийг автоматаар retry хийх —
  хоёуланг илрүүлнэ.
- **Why:** Retry нь зөвхөн идемпотенц үйлдэлд аюулгүй. Bичилт үүсгэдэг гадаад
  үйлдлийг (payment) retry хийхийн өмнө BC-INT-001-ийн хамгаалалт заавал.
- **Risk:** (a) транзиент алдаагаар мэдээлэл алдагдах; (b) давхар гүйлгээ.
- **Detection:** Try/if-ийн else салаанд: юу ч хийхгүй (a) эсвэл шууд дахин
  дуудалт (b); Job Queue-ийн rerun тохиргоог хамт үнэл (Job Queue өөрөө retry
  хийдэг — код давхар retry хэрэггүй байж болно).
- **Suggested Fix:** Идемпотенц түлхүүр + хязгаартай exponential backoff; эсвэл
  Job Queue-ийн Maximum No. of Attempts-д даатга.

---

## BC-INT-004 — Event-subscriber синк дэх алдааны тархалт

- **Severity:** HIGH
- **Rule:** OnAfterInsert/OnAfterModify/OnAfterPost subscriber дотроос гадаад систем
  рүү синхрон илгээлт хийж, гадаад алдаа нь бизнес үйлдлийг унагаж байвал илрүүлнэ.
- **Why:** Стандарт: subscriber зөвхөн queue/log бичлэг үүсгээд Job Queue
  боловсруулдаг (API webhook notification pattern). Гадаад систем унавал бизнес
  үргэлжлэх ёстой.
- **Risk:** Гадаад системийн доголдол BC-ийн posting/хадгалалтыг блоклоно.
- **Detection:** Subscriber биед HttpClient; TryFunction-гүй илгээлт; алдаа
  дамжуулдаг эсэх.
- **Suggested Fix:** Outbox pattern: subscriber → queue table → Job Queue →
  илгээлт + статус; илгээлтийн алдаа зөвхөн queue-д тэмдэглэгдэнэ.

---

## BC-INT-005 — Хагас интеграцийн төлөв (partial failure)

- **Severity:** MEDIUM
- **Rule:** Олон бичлэгийн батч илгээлт/татал нэг бичлэгийн алдаанд бүхэлдээ
  зогсдог эсвэл алдаатай бичлэгийн статус тэмдэглэгдэхгүй бол илрүүлнэ.
- **Why:** IntegrationTableSynch бичлэг бүрд амжилт/алдааг Integration Synch. Job
  Errors-т бүртгэж үргэлжилдэг.
- **Risk:** Нэг эвдэрхий бичлэг бүх синкийг блоклох; аль нь ороогүйг мэдэхгүй болох.
- **Detection:** Батч loop-д бичлэг тус бүрийн try/status байгаа эсэх.
- **Suggested Fix:** Бичлэг бүрд TryFunction/Codeunit.Run + алдааны бүртгэл +
  үргэлжлүүлэлт; батчийн summary статус.

---

## BC-INT-006 — Данс/мастер мэппингийн баталгаа

- **Severity:** MEDIUM
- **Rule:** Гадаад кодыг BC-ийн мастер (Item, Customer, G/L Account) руу
  мэппингдэхдээ олдоогүй тохиолдлыг чимээгүй алгасах, default данс руу нуух
  байдлаар шийдэж байвал илрүүлнэ.
- **Risk:** Гүйлгээ буруу данс/харилцагч дээр бүртгэгдэх — илрэхэд хэцүү зөрүү.
- **Detection:** `if not Item.Get(ExternalCode) then exit;` (лог-гүй) эсвэл
  `... then ItemNo := DefaultItem;`
- **Suggested Fix:** Мэппинг олдоогүйг алдаа/queue-д тодорхой бүртгэж хэрэглэгчид
  шийдвэрлүүлэх урсгал гарга.
