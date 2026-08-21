# Permissions & Security — Эрх ба аюулгүй байдлын мэдлэгийн сан

## 1. Зарчим

BC-ийн permission загвар **least privilege + indirect permission** дээр тогтдог:

- Хэрэглэгчид ledger хүснэгтийн шууд бичих эрх байдаггүй.
- Posting codeunit-ууд `Permissions` property-оор өөртөө түр эрх олгодог —
  хэрэглэгч зөвхөн тухайн codeunit-ийг Execute хийх эрхтэй байхад хангалттай.
- Permission set-үүд жижиг нэгжээс composition-оор угсарддаг.

## 2. Source code дээрх ажиглалт

### Codeunit-ийн Permissions property
`Sales-Post` (CU 80):
```al
Permissions = TableData "Sales Shipment Header" = rimd,
              TableData "Sales Invoice Header" = rimd,
              ...
              TableData "G/L Entry" = r,
              Tabledata Job = r;
```
- Зөвхөн бичих шаардлагатай posted/ledger хүснэгтүүд, шаардлагатай үйлдлээ (rimd)
  нарийн зааж өгсөн. G/L Entry-д зөвхөн `r` — GL бичилт нь CU 12-ийн эрхээр хийгддэг.
- `Item Jnl.-Post Line` (CU 22) — Item, ILE, Value Entry гэх мэт өөрийн domain-ий
  хүснэгтэд rimd.

### Permission set-ийн бүтэц
`D365 ACC. RECEIVABLE`:
```al
Access = Public;
Assignable = true;
IncludedPermissionSets = "D365 JOURNALS, POST", "D365 SALES DOC, POST";
Permissions = tabledata "Bank Account Statement" = RimD, ...
```
- **Том үсэг = direct эрх, жижиг үсэг = indirect эрх.** `RimD` гэдэг нь Read/Delete
  шууд, insert/modify зөвхөн объектоор (codeunit-ийн Permissions-оор) дамжина гэсэн утга.
- Composition: том багц жижиг багцуудаа Include хийдэг.

### System Application
- Бүх объект `InherentEntitlements = X; InherentPermissions = X;` зарлаж, дараа нь
  шаардлагатайг нь permission set-ээр нээдэг.
- `Access = Internal` — модулиас гадуур ашиглагдах ёсгүй Impl. codeunit-ууд.

### Нууц утга
- `SecretText` төрөл, `SecretStrSubstNo('Bearer %1', Token)` — token/password-ийг
  ердийн Text-ээр дамжуулдаггүй, debugger/telemetry-д ил гардаггүй.
- Azure Key Vault / Isolated Storage-д хадгалдаг, hardcoded нууц байхгүй.

### Бусад
- `[SecurityFiltering(SecurityFilter::Ignored)]` — маш цөөн, зориудын газарт
  (Sales-Post-ийн GLEntry variable — хэрэглэгчийн security filter-ээс үл хамааран
  дотоод шалгалт хийх). Комментгүй санамсаргүй хэрэглээ байхгүй.
- Мэдрэмтгий үйлдэлд нэмэлт шалгалт: `ICInboxOutboxMgt.CheckPermissionToSendICTransaction`.

## 3. Яагаад ингэж хийсэн бэ (analysis)

- Indirect permission нь "хэрэглэгч ямар бизнес үйлдэл хийж чадах вэ" гэдгийг
  удирдана — өгөгдлийн түвшний эрх биш процессын түвшний эрх.
  Хэрэглэгч G/L Entry-д bичих эрхтэй байсан бол UI-гүйгээр ч тэнцвэргүй бичилт
  хийж чадах байсан.
- Codeunit-ийн Permissions нь тухайн codeunit-ийн хүрээнд Л үйлчилдэг тул эрхийн
  өргөтгөл нь тодорхой, аудитлагдахуйц цэгээр хязгаарлагддаг.

## 4. Зөв хэрэгжилт

```al
// Custom posting codeunit — өөрийн ledger-т нарийн эрх
codeunit 50110 "Loyalty Post"
{
    Permissions = TableData "Loyalty Ledger Entry" = rim; // d байхгүй — устгах эрх огт хэрэггүй
    ...
}

// Permission set — composition + нарийн эрх
permissionset 50100 "Loyalty - Edit"
{
    Assignable = true;
    IncludedPermissionSets = "Loyalty - Read";
    Permissions =
        tabledata "Loyalty Setup" = IMD,
        tabledata "Loyalty Ledger Entry" = imd; // зөвхөн objects-оор бичигдэнэ
}
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: бүх хүснэгтэд шууд бүрэн эрх
permissionset 50101 "My App - All"
{
    Permissions =
        tabledata "G/L Entry" = RIMD,          // хэрэглэгч ledger шууд засаж чадна!
        tabledata "Cust. Ledger Entry" = RIMD,
        tabledata "My Log" = RIMD;
}

// БУРУУ: шаардлагагүй өргөн codeunit permission
codeunit 50111 "My Helper"
{
    Permissions = TableData "G/L Entry" = rimd,  // энэ codeunit GL уншдаг л юм бол
                  TableData "Vendor Ledger Entry" = rimd; // r хангалттай
}

// БУРУУ: hardcoded нууц
ApiKey := 'sk-abc123...';
HttpHeaders.Add('Authorization', 'Bearer ' + ApiKey); // SecretText биш, код дотор нууц
```

## 6. Code review хийх дүрэм

1. **[CRITICAL]** Permission set хэрэглэгчид ledger/posted хүснэгтийн шууд (том үсэг)
   Insert/Modify/Delete эрх өгч байвал — санхүүгийн өгөгдөл гуйвуулах боломж.
2. **[CRITICAL]** Hardcoded API key/password/token; нууцыг Text-ээр хадгалах,
   логт хэвлэх — SecretText/Isolated Storage ашиглах ёстой.
3. **[HIGH]** Codeunit-ийн Permissions property уг codeunit-ийн бодит хэрэгцээнээс
   өргөн (ашигладаггүй хүснэгт, шаардлагагүй rimd) — тайлбар шаард, багасга.
4. **[HIGH]** `[SecurityFiltering(SecurityFilter::Ignored)]` шинээр нэмэгдэж байвал —
   яагаад хэрэглэгчийн security filter-ийг алгасах ёстойг нотлуулах.
5. **[HIGH]** Мэдрэмтгий бизнес үйлдэл (төлбөр, банкны экспорт, эрхийн өөрчлөлт)
   ямар ч нэмэлт authorization шалгалтгүй public procedure-ээр ил байвал.
6. **[MEDIUM]** `Assignable = true` permission set нь бодит хэрэглэгчийн role биш
   зөвхөн дотоод хэрэглээний бол Assignable=false байх ёстой.
7. **[MEDIUM]** Permission set том, monolith болсон бол composition
   (IncludedPermissionSets) санал болго.
8. **[MEDIUM]** Шинэ хүснэгт нэмэгдсэн мөртлөө ямар ч permission set-д ороогүй
   (SUPER-ээс бусад хэн ч ашиглаж чадахгүй) эсвэл бүх багцад RIMD орсон.
9. **[LOW]** DataClassification талбар бүрт зөв эсэх (CustomerContent vs
   SystemMetadata) — GDPR ангилал.
