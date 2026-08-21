# Permissions Reference — Эрхийн шалгалт

## Суурь зарчим

- **Least privilege + indirect permission:** хэрэглэгч ledger-т шууд бичих эрхгүй;
  posting codeunit `Permissions = TableData ... = rimd` property-оор өөртөө эрх авдаг.
- **Том/жижиг үсэг utга ялгана:** `RIMD` = direct эрх (хэрэглэгч шууд), `rimd` =
  indirect (зөвхөн объектоор дамжина). Жишээ: D365 ACC. RECEIVABLE-д
  `"Bank Account Statement" = RimD` — Read/Delete шууд, insert/modify indirect.
- Permission set composition: `IncludedPermissionSets`-ээр угсарна.
- System App стандарт: `InherentEntitlements = X; InherentPermissions = X`.
- CU 80-ийн жишээ: G/L Entry-д зөвхөн `r` — GL бичилтийг CU 12 өөрийн эрхээр хийдэг:
  codeunit бүр өөрийн domain-ий бичилтийн эрхийг л зарладаг.

## Дүрмүүд

### BC-PERM-001 [CRITICAL] — Хэрэглэгчид ledger-ийн direct бичих эрх
Assignable permission set-д `tabledata "G/L Entry" = RIMD` маягийн мөр (ledger,
register, posted document-д том үсгийн I/M/D). Хэрэглэгч API/config package-ээр
ledger шууд засаж чадна. **Засвар:** жижиг үсэгт шилжүүлж бичдэг codeunit-д
Permissions property.

### BC-PERM-002 [HIGH] — Codeunit-ийн Permissions хэт өргөн
Property-д зарласан эрх бодит хэрэглээнээс өргөн (d зарлаад Delete байхгүй г.м.).
Уг codeunit-ээр дамжсан БҮХ код (subscriber-ууд ч!) энэ эрхтэй ажиллана —
escalation цэг. **Засвар:** ашиглаагүй эрхийг хас.

### BC-PERM-003 [MEDIUM] — Шинэ объектын permission бүрхэлт
Шинэ table/page/codeunit аль ч permission set-д ороогүй (SUPER-т л ажиллана)
эсвэл бүх багцад RIMD. **Засвар:** Read/Edit/Admin түвшний багцад тохируул.

### BC-PERM-005 [HIGH] — InherentPermissions / SecurityFiltering
`[InherentPermissions(...)]`, `[SecurityFiltering(SecurityFilter::Ignored)]`
тайлбаргүй нэмэгдэх — хэрэглэгчийн эрх/шүүлт алгасах онцгой механизм. Base App
маш цөөн, зориудын газарт л хэрэглэдэг. **Засвар:** хүрээг хамгийн жижиг болгож
шалтгаа baримтжуул, эсвэл устга.

### BC-PERM-004 [LOW] — Permission тест
Permission set өөрчлөгдсөн ч permission тест байхгүй; бүх тест
TestPermissions = Disabled.

## Шалгах асуултууд

1. Энэ permission үнэхээр шаардлагатай юу? (объектын бодит үйлдэлтэй тулга)
2. Permission хэт өргөн байна уу? (RIMD → бодит хэрэгцээ)
3. TableData = rimd-ийг шаардлагагүй ашигласан уу? (өөр codeunit-ийн үүрэг бол хас)
4. Security bypass үүсэж байна уу? (Ignored filtering, inherent permissions)
5. Sensitive үйлдэл authorization-тай юу? (мэдрэмтгий үйлдэлд нэмэлт шалгалт)
