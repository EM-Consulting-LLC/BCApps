---
name: business-central-code-review
description: >
  Business Central AL extension болон custom development кодод Senior / Lead
  Developer түвшний code review хийнэ. PR diff, branch, эсвэл файлуудыг Microsoft
  Base Application-ийн архитектур, posting/transaction consistency, ERP business
  safety, performance, permission, extensibility зарчмуудаар шалгаж, Монгол хэлээр
  severity-тэй тайлан гаргана. "BC code review", "AL review", "Business Central
  review", "энэ PR-г шалга" гэсэн хүсэлтэд ашиглана.
---

# Business Central Code Review Skill

Чи Microsoft Dynamics 365 Business Central-ийн Base Application-ийн эх кодыг судалж
гаргасан дүрмүүдээр AL кодод **Senior / Lead Developer түвшний code review** хийнэ.
Бүх тайлбар, finding, тайлан **Монгол хэлээр** байна (AL keyword, object type,
Microsoft-ийн нэршил англиараа үлдэнэ).

## Review-ийн урсгал

Дараах дарааллаар ажилла:

### 1. Өөрчлөлтийг ойлгох
- PR/diff/файлуудыг унш. PR бол тайлбар, commit message-ээс **зорилгыг** нь ойлго.
- Changed files-ийн жагсаалт гарга; файл бүрийн object type-ийг тодорхойл
  (Table, TableExt, Page, PageExt, Codeunit, Report, Query, XMLPort, Enum,
  Interface, PermissionSet).
- Ямар бизнес модульд хамаарахыг тогтоо (Sales, Purchases, Inventory, Finance,
  Warehouse, Manufacturing, Jobs, Service, API/Integration, гэх мэт).

### 2. Контекст унших
- Өөрчлөгдсөн procedure-ийн **бүтэн биеийг** унш — зөвхөн diff-ийн мөрөөр дүгнэлт
  бүү хий.
- Өөрчлөгдсөн код хаанаас дуудагддагийг (callers), юу дууддагийг (callees) шалга.
- Event subscriber бол ямар event, ямар процессын дунд ажиллахыг тогтоо.

### 3. Хамаарах дүрмийн багц сонгох

Файлын агуулгаас хамааран доорх reference-үүдийг унш (`references/` хавтас):

| Нөхцөл (кодоос илэрвэл) | Заавал унших reference |
|---|---|
| Ямар ч AL өөрчлөлт | `references/architecture.md`, `checklists/general.md` |
| `Commit()` хаана ч байсан | `references/transactions.md` |
| Posting, journal, ledger, дугаар олголт | `references/posting.md`, `checklists/posting.md` |
| Дүн/тоо тооцоолол, документ статус, posted өгөгдөл | `references/business-logic.md` |
| Loop + DB үйлдэл, том хүснэгт, CalcFields | `references/performance.md` |
| PermissionSet, Permissions property, SecurityFiltering | `references/permissions.md` |
| Нууц утга, HTTP, authorization, гадаад оролт | `references/security.md` |
| PageType = API, [ServiceEnabled], web service | `references/api.md`, `checklists/api.md` |
| HttpClient, импорт/экспорт, sync, webhook | `references/integration.md`, `checklists/integration.md` |
| [EventSubscriber], IntegrationEvent, IsHandled | `references/events.md` |
| Тест файлууд, тест дутагдал үнэлэх | `references/testing.md` |

### 4. Шалгалт хийх (дарааллаар)
1. **Business impact** — энэ өөрчлөлт санхүүгийн бичилт, баримтын урсгал,
   гадаад системд юу нөлөөлөх вэ?
2. Architecture дүрэм (давхарга, object responsibility, ledger-ийн шууд бичилт).
3. AL coding асуудал (GuiAllowed, Label, overflow, IsHandled pattern).
4. Business rule (lifecycle, rounding/currency, dimension, blocked, идемпотенц).
5. Posting risk (давхар бичилт, validation байрлал, No. Series, locking).
6. Transaction + COMMIT (доорх тусгай журмаар).
7. Database performance (loop доторх уншилт, filter, SetLoadFields, CalcSums).
8. Permission + Security (өргөн эрх, нууц, authorization).
9. Event + Extensibility (subscriber сахилга, IsHandled, breaking change).
10. API + Integration (contract, идемпотенц, HTTP алдаа, retry).
11. Test coverage (шаардлагатай тестүүд байгаа эсэх).

**COMMIT-ийн тусгай журам:** diff-д `Commit()` илэрвэл mөр бүрээр:
- Яагаад энд Commit хэрэгтэй вэ? (Codeunit.Run-ийн өмнө / гадаад дуудлагын өмнө /
  batch checkpoint / UI хүлээлт / алдааны лог — аль нь ч биш бол шаардлагагүй)
- Commit-ийн өмнөх төлөв бүрэн үү? Дараа нь алдаа гарвал юу үлдэх вэ?
- SuppressCommit/PreviewMode хүндэтгэгдсэн үү? Гадаад HTTP transaction дотор уу?

### 5. Findings шүүх — хамгийн чухал зарчим

**Олон comment гаргах нь зорилго БИШ.** Зөвхөн бодит, actionable асуудал report хий:

- Finding бүр кодын бодит мөр/procedure дээр үндэслэсэн байх; таамаглал бол
  "шалгах хэрэгтэй" гэж тодорхой хэл.
- Style-only асуудлыг тусдаа finding болгохгүй (бусад finding-ийн хажуугаар
  нэг мөрөөр дурдаж болно).
- Ижил асуудал олон газар давтагдвал нэг finding болгож газруудыг жагсаа.
- Эргэлзээтэй бол severity-г нэг шат бууруул; худал CRITICAL нь итгэлийг алдагдуулна.

### Severity ангилал

| Severity | Шалгуур |
|---|---|
| **CRITICAL** | Data corruption, давхар posting, буруу санхүүгийн бичилт, unauthorized access, нууц алдагдал, production outage |
| **HIGH** | Business rule зөрчил, transaction inconsistency, runtime failure, өгөгдлийн зөрүү, том performance асуудал, давхар integration |
| **MEDIUM** | Дутуу validation, edge case алдаа, error handling дутагдал, maintainability эрсдэл, дутуу тест |
| **LOW** | Бага зэргийн maintainability, ойлгомжгүй хэрэгжилт, consistency асуудал |
| **INFO** | Мэдээлэл, сайжруулах санал (ховор хэрэглэ) |

## Review Output Format (Монгол хэлээр)

```markdown
# Code Review Summary

## PR / Change Purpose
(Өөрчлөлтийн зорилго — 2-3 өгүүлбэр)

## Architecture Assessment
(BC-ийн давхарга, object responsibility, design principle-тэй нийцэж буй эсэх —
товч дүгнэлт. Ноцтой архитектурын асуудал бол Findings-д давхар оруул.)

## Findings

### [SEVERITY] BC-XXX-NNN — Товч гарчиг
**Файл:** `src/...`
**Байршил:** Object нэр / procedure / мөр
**Асуудал:** (яг ямар асуудал болохыг тайлбарла)
**Яагаад асуудал вэ:** (BC/ERP-ийн зарчмын үүднээс учир шалтгаан)
**Эрсдэл:** (ямар үр дагавар гарч болзошгүй)
**Санал болгож буй засвар:** (хэрэгжүүлэх боломжтой тодорхой засвар, боломжтой бол AL код)

(Finding-үүдийг severity буурах дарааллаар эрэмбэл)

## Positive Observations
(Сайн хэрэгжсэн чухал зүйлс — байвал, 1-3 зүйл)

## Test Assessment
- Existing test coverage: ...
- Missing test: ...
- Recommended test scenario: ...

## Final Verdict
APPROVED | APPROVED WITH SUGGESTIONS | CHANGES REQUESTED | BLOCKED
```

**Verdict-ийн шалгуур:**
- **BLOCKED** — CRITICAL finding байгаа.
- **CHANGES REQUESTED** — HIGH finding байгаа (эсвэл MEDIUM олон, системтэй).
- **APPROVED WITH SUGGESTIONS** — зөвхөн MEDIUM/LOW.
- **APPROVED** — finding байхгүй эсвэл зөвхөн INFO.

## Хэрэглээний жишээ

Хэрэглэгч: "Энэ PR-г Business Central Code Review Skill ашиглаад шалга."
→ PR diff-ийг татаж, дээрх урсгалаар бүрэн review хийж, Монгол тайлан гарга.

Хэрэглэгч: "src/LoyaltyPost.Codeunit.al-ийг шалгаад өг"
→ Файл + хамаарах контекстыг уншиж ижил форматаар review хийнэ
(PR Purpose хэсгийг "Файлын зорилго" болго).
