# General Checklist — Бүх review-д хэрэглэх ерөнхий шалгах хуудас

Файл бүрд дор хаяж нэг удаа гүйлгэж шалга. "Тийм" гэж хариулагдах ёстой асуултууд.

## Архитектур
- [ ] Ledger/register/posted хүснэгтэд шууд бичилт байхгүй (BC-ARCH-001)
- [ ] Page-д бизнес логик байхгүй, codeunit рүү delegate хийсэн (BC-ARCH-002)
- [ ] Стандарт engine-ийн код хуулбарлаагүй, event/interface ашигласан (BC-ARCH-004)

## Кодын түвшин
- [ ] Confirm/Message/Dialog бүр GuiAllowed()-тэй эсвэл UI-гүй замд гарахгүй (BC-AL-001)
- [ ] Хэрэглэгчийн текст бүгд Label(+Comment) (BC-AL-002)
- [ ] Урт утга → богино талбарт CopyStr/MaxStrLen (BC-AL-003)
- [ ] OnValidate-тэй талбарт Validate ашигласан (шууд `:=` биш) эсвэл зориудынх
      нь тайлбартай (BC-BIZ-006)
- [ ] Public гадаргуугийн өөрчлөлт Obsolete lifecycle-тэй (BC-AL-006)
- [ ] Данс/journal/location зэрэг тохиргооны утга hardcode хийгдээгүй, Setup-аас
      TestField-тэй уншигдсан (BC-AL-008)

## Transaction
- [ ] Commit() бүр legitimate шалтгаантай (5 шалтгааны нэг) (BC-TXN-002)
- [ ] Commit бүрийн өмнөх төлөв бүрэн; дараах алдааны зам аюулгүй (BC-TXN-001/003)
- [ ] Uncommitted бичилттэй үед гадаад HTTP байхгүй (BC-TXN-004)
- [ ] Subscriber дотор Commit байхгүй (BC-EVT-001)

## Өгөгдөл ба бизнес
- [ ] Released/Posted өгөгдөлд статус шалгалтгүй өөрчлөлт байхгүй (BC-BIZ-001/002)
- [ ] Дүн тооцоололд Round + Currency precision + зөв огнооны ханш (BC-BIZ-003)
- [ ] Бичилтэд Dimension Set ID дамжсан (BC-BIZ-004)
- [ ] Давтан ажиллахад давхардахгүй (идемпотенц) (BC-POST-001 / BC-INT-001)

## Performance
- [ ] Loop дотор давтан Get/FindFirst/CalcFields байхгүй (BC-PERF-001/005)
- [ ] Том хүснэгтэд filter-тэй хандсан, existence-д IsEmpty (BC-PERF-002/003)
- [ ] Том уншилтад SetLoadFields-ийг зөв (бүрэн жагсаалттай) хэрэглэсэн (BC-PERF-004)

## Эрх ба аюулгүй байдал
- [ ] Permission set-д ledger-ийн direct бичих эрх байхгүй (BC-PERM-001)
- [ ] Codeunit Permissions property бодит хэрэгцээтэй тэнцүү (BC-PERM-002)
- [ ] Нууц утга SecretText/Isolated Storage-д, логт ил гараагүй (BC-SEC-001)
- [ ] Шинэ объектууд permission set-д орсон (BC-PERM-003)

## Event
- [ ] Subscriber-т guard (IsTemporary, хоосон түлхүүр, PreviewMode) байгаа (BC-EVT-002)
- [ ] IsHandled := true нарийн нөхцөлтэй (BC-EVT-003)

## Тест
- [ ] Өөрчлөлтөд тохирсон тест бий/нэмэгдсэн (BC-TEST-001)
- [ ] Negative + rollback тест бий (BC-TEST-002)
