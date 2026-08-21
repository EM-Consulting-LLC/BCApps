# Integration Checklist — Гадаад интеграцийн өөрчлөлтийн шалгах хуудас

Diff-д HttpClient, импорт/экспорт, sync, webhook, гадаад систем рүү илгээлт
байвал гүйлгэ.

## Идемпотенц (хамгийн чухал)
- [ ] Давтан ажиллахад давхар бичлэг үүсэхгүй: external id/existence шалгалт (BC-INT-001)
- [ ] Тасалдсан ажиллагаа дахин эхлэхэд хийсэн хэсэг давхардахгүй (checkpoint/cursor)
- [ ] Гадагшаа илгээлтэд статус машин (Pending → Sent/Error) + Commit checkpoint
- [ ] Webhook хүлээн авагч at-least-once delivery-д бэлэн (давхар мэдэгдэл таньдаг)

## HTTP чанар
- [ ] Send-ийн үр дүн + StatusCode/IsSuccessStatusCode шалгагдсан (BC-INT-002)
- [ ] Алдааны хариулт (нууцгүйгээр) логлогдсон
- [ ] Timeout тохируулсан; 429/503-д backoff (BC-INT-003)
- [ ] Authorization SecretText/SecretStrSubstNo-оор (BC-SEC-001)
- [ ] https (localhost-оос бусад) (BC-SEC-005)

## Transaction
- [ ] Uncommitted бичилттэй үед HTTP байхгүй (BC-TXN-004)
- [ ] Subscriber-ээс синхрон гадаад дуудлага байхгүй — outbox + Job Queue (BC-INT-004)

## Алдааны менежмент
- [ ] Batch-д нэг бичлэгийн алдаа бусдыг зогсоохгүй + бүртгэгддэг (BC-INT-005)
- [ ] Мэппинг олдоогүй тохиолдол тодорхой бүртгэгддэг (default руу нуугдахгүй) (BC-INT-006)
- [ ] TryFunction дотор DB бичилт байхгүй
- [ ] `if not Codeunit.Run(...) then;` хэлбэрийн silent failure байхгүй

## Өгөгдлийн чанар
- [ ] JSON талбар байхгүй/null үед crash хийхгүй
- [ ] Урт утга CopyStr-ээр хамгаалагдсан (BC-AL-003)
- [ ] Огноо/цаг UTC-local хөрвүүлэлт зөв
- [ ] Гадаад ID хадгалагдаж traceability хангагдсан

## Тест
- [ ] Давтан дуудлага/давхар мэдэгдлийн идемпотенц тест
- [ ] HTTP алдааны (4xx/5xx/timeout) сценарионы тест (mock/handler-ээр)
- [ ] Partial failure: N бичлэгийн 1 нь алдаатай үеийн тест
