# API Checklist — API page / web service өөрчлөлтийн шалгах хуудас

Diff-д PageType = API, [ServiceEnabled], web service бүртгэл байвал гүйлгэ.

## Contract
- [ ] Одоо байгаа талбар устгаагүй/нэр солиогүй (эсвэл шинэ version гаргасан) (BC-API-001)
- [ ] EntityName/EntitySetName camelCase, өөрчлөгдөөгүй
- [ ] ODataKeyFields = SystemId (custom key бол үндэслэлтэй) (BC-API-002)
- [ ] Custom API-д APIPublisher, APIGroup, APIVersion зарлагдсан

## Бүтэц
- [ ] DelayedInsert = true
- [ ] Талбар бүрийн OnValidate-д RegisterFieldSet (template нэгтгэлт хэрэглэдэг бол)
- [ ] Том/нийлмэл баримтад aggregate/буфер хүснэгт (түүхий баримт биш)
- [ ] UI page-ийг web service болгоогүй (BC-API-005)

## Validation
- [ ] Reference GUID бүр GetBySystemId шалгалттай + тодорхой Error (BC-API-003)
- [ ] Id + No. зэрэг ирэхэд зөрүүг reject хийдэг
- [ ] Required талбаруудын шалгалт API замд ажиллана (page validation-д найдаагүй)

## Transaction ба идемпотенц
- [ ] Bound action: posting дараа, гадаад үйлдлийн өмнө Commit (BC-API-004)
- [ ] Давтан дуудлага давхар үйлдэл үүсгэхгүй (draft олдохгүй бол зөв алдаа)
- [ ] Клиент retry сценарио бодогдсон

## Permission
- [ ] API-ийн source table + үйлдлүүдэд тохирох permission set шинэчлэгдсэн
- [ ] Мэдрэмтгий үйлдэл нэмэлт шалгалттай (BC-SEC-002)

## Тест
- [ ] CRUD + bound action-ий тест
- [ ] Давтан дуудлагын идемпотенц тест
- [ ] Буруу reference/дутуу талбарын negative тест
