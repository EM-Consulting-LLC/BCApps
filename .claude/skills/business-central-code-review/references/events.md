# Events Reference — Event ба subscriber-ийн шалгалт

## Суурь зарчим

- Event нэршил: `OnBefore<Action>` (+IsHandled = орлуулах боломж), `OnAfter<Action>`,
  `On<Proc>On<SubStep>` (процессын дундах цэг). Signature-т SuppressCommit,
  PreviewMode зэрэг төлөв дамждаг.
- **Subscriber бол зочин:** богино, guard-тай, host-ийн transaction/урсгалыг
  эвдэхгүй. Base App-ийн subscriber-ууд бүгд: хоосон түлхүүр + `IsTemporary()`
  guard, нэг зорилго, өөрийн domain-д л нөлөөлнө.
- Түр subscriber: `EventSubscriberInstance = Manual` + BindSubscription/
  UnbindSubscription хос (Sales-Post, Posting Preview).

## Дүрмүүд

### BC-EVT-001 [CRITICAL] — Subscriber доторх Commit
Host transaction-ийн rollback хил эвдэрнэ (Microsoft posting-оо
CommitBehavior::Ignore-оор хамгаалдаг нь subscriber Commit дизайны хувьд хориотойн
нотолгоо). **Засвар:** устга; тусдаа transaction хэрэгтэй бол queue + Job Queue.

### BC-EVT-002 [MEDIUM] — Guard дутуу
`Rec.IsTemporary()`, хоосон түлхүүр, posting event-д PreviewMode шалгалт байхгүй.
Temp/буфер record-оос бодит side-effect, preview-ээс бодит бичилт үүсч болно.

### BC-EVT-003 [HIGH] — IsHandled-ийг болзолгүй эзэмших
`IsHandled := true` нөхцөлгүй/өргөн нөхцөлд — стандарт логик + бусад extension
унтарна. **Засвар:** нөхцөлөө нарийсга; орлуулах логикоо бүрэн хэрэгжүүл.

### BC-EVT-004 [HIGH] — Өндөр давтамжийн event-д хүнд үйлдэл
OnAfterValidateEvent г.м. дотор олон record Modify, гинжин Validate (рекурс!),
bulk уншилт, тайлан. **Засвар:** хөнгөн флаг тавьж бодит ажлыг OnAfterModify/
posting/Job Queue-д нэг удаа.

### BC-EVT-005 [MEDIUM] — Дарааллаас хамааралтай subscriber-ууд
Нэг event-ийн subscriber-ууд бие биеийн үр дүнд найдах / нэг өгөгдлийг зэрэг
өөрчлөх — execution order баталгаагүй.

### BC-EVT-006 [LOW] — Manual binding-ийн дэг
Bind хийгээд Unbind байхгүй (алдааны замд ч); түр зуурын subscriber static байх.

### BC-POST-006-тай уялдаа
Posting event-ийн subscriber-т: Commit, UI, HTTP, өөр posting, unrelated Error —
posting reference-ээр давхар шалга.

## Extensibility үнэлгээ (өөрчлөлт бүрд)

1. Энэ logic-ийг event-ээр extension хийх боломжтой байсан уу? (base object
   өөрчлөлт шаардлагагүй байсан уу)
2. Existing event аль хэдийн байна уу? (шинээр нэхэхийн өмнө хай)
3. Interface ашиглах нь илүү зөв үү? (algorithm бүхэлдээ солигдож байвал — тийм)
4. Event handler transaction consistency-д нөлөөлөх үү? (Commit, Error, бичилт)
5. Subscriber unexpected side effect үүсгэх үү? (өөр domain-ий өгөгдөл, давтамж)
