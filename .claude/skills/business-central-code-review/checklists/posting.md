# Posting Checklist — Posting/journal/ledger өөрчлөлтийн шалгах хуудас

Diff-д posting routine, journal боловсруулалт, ledger бичилт, дугаар олголт,
posting event-ийн subscriber байвал энэ хуудсыг бүрэн гүйлгэ.

## Урсгалын бүтэц
- [ ] Validation бүгд бичилт эхлэхээс өмнө (Check фаз тусдаа) (BC-POST-003)
- [ ] Ledger бичилт зөвхөн стандарт Post Line codeunit-ээр (BC-POST-002)
- [ ] Custom бичилтэд Posting Date-ийн Allow Posting From/To шалгалт бий
- [ ] Dimension шалгалт + Dimension Set ID дамжуулалт бий (BC-BIZ-004)
- [ ] Document lifecycle зөв: Open биш баримт бичигдэхгүй, Released мөр өөрчлөгдөхгүй

## Идемпотенц (хамгийн чухал)
- [ ] "Аль хэдийн бичигдсэн" шалгалт бий (existence/status/Entry No.) (BC-POST-001)
- [ ] Дугаар No. Series-ээс, олгосныг эх баримтад хадгалдаг (BC-POST-004)
- [ ] Давтан post хийхэд posted хүснэгтэд conflict шалгалт бий
- [ ] Job Queue/API-аас дуудагдах бол статус хамгаалалт (Scheduled/Posting) бий

## Transaction
- [ ] Posting дундуур Commit байхгүй (BC-TXN-001)
- [ ] SuppressCommit/PreviewMode параметрүүд хүндэтгэгдсэн (BC-TXN-005)
- [ ] Preview зам бодит дугаар авдаггүй, бодит бичилт үлдээдэггүй
- [ ] LockTable validation-ий дараа, бичилтийн өмнө (BC-POST-005)

## Subscriber (posting event-д)
- [ ] OnBefore/OnAfterPost* subscriber-т Commit/UI/HTTP/unrelated Error байхгүй (BC-POST-006)
- [ ] PreviewMode параметр шалгагдсан
- [ ] Хүнд ажил queue + Job Queue-ээр тусгаарлагдсан

## Batch
- [ ] Нэг баримтын алдаа бусдыг зогсоохгүй (Codeunit.Run + лог) (BC-POST-007)
- [ ] Алдаатай баримт бүртгэгддэг, чимээгүй алгасагддаггүй

## Санхүүгийн зөв байдал
- [ ] Debit/credit тэнцвэр стандарт engine-ээр хангагдана (гараар GL дүн үүсгэдэггүй)
- [ ] Rounding: нийт дүн нэг удаа Round, remainder дамжуулалттай (BC-BIZ-003)
- [ ] Валюттай бол гүйлгээний огнооны ханш, LCY+ACY зэрэгцээ
- [ ] Хэсэгчилсэн ship/invoice-ийн quantity талбарууд зөв сонгогдсон (BC-BIZ-007)

## Тест
- [ ] Амжилттай бичилтийн ledger шалгалттай тест
- [ ] asserterror + юу ч бичигдээгүйг шалгах тест
- [ ] Давтан post хийх идемпотенц тест
