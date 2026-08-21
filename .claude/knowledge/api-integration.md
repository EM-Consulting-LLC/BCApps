# API & Integration — API ба интеграцийн мэдлэгийн сан

## 1. Зарчим

BC-ийн интеграцийн загвар гурван суурьтай:

1. **API page-ууд** — OData v4 гэрээ: SystemId дээр суурилсан, буфер/aggregate
   хүснэгттэй, contract тогтвортой.
2. **Гадагшаа HTTP** — transaction-ээс тусгаарлагдсан, нууцыг SecretText-ээр,
   алдааг барьж логлодог.
3. **Идемпотенц** — давтан ирсэн хүсэлт, давтан sync давхар өгөгдөл үүсгэдэггүй
   (coupling бүртгэл, external id, status шалгалт).

## 2. Source code дээрх ажиглалт

### API Page pattern (APIV2 - Sales Invoices, page 30012)
- `PageType = API; APIVersion = 'v2.0'; EntityName/EntitySetName` — camelCase нэршил.
- `ODataKeyFields = Id` — **SystemId GUID түлхүүр**, No. биш.
- `DelayedInsert = true` — бүх талбар ирснийг нэг Insert болгоно.
- `ChangeTrackingAllowed = true`, `Extensible = false`.
- `SourceTable = "Sales Invoice Entity Aggregate"` — шууд Sales Header биш,
  draft + posted-ыг нэгтгэсэн буфер хүснэгт.
- Талбар бүрийн OnValidate-д `RegisterFieldSet` — DelayedInsert-ийн үед ямар талбар
  ирснийг бүртгэж, template default-уудтай зөв нэгтгэдэг.
- Reference талбар: `if not SellToCustomer.GetBySystemId(Rec."Customer Id") then
  Error(CouldNotFindSellToCustomerErr)` — GUID-ээр лүүкап + ойлгомжтой алдаа;
  зөрсөн утга ирвэл (`SellToCustomerValuesDontMatchErr`) reject.
- Үйлдлүүд bound action-аар: `[ServiceEnabled] procedure Post(var ActionContext:
  WebServiceActionContext)`; PostAndSend дотор **Post → Commit → Send** дараалал —
  илгээлт унасан ч posting хадгалагдана.

### Гадагшаа HTTP (ImportConsolidationFromAPI)
- `HttpHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', Token))`.
- Статус код, reason phrase-ийг барьж, хүсэлт/хариултыг Log Entry хүснэгтэд
  Commit-тэйгээр хадгалдаг (алдаа гарсан ч лог үлдэнэ).

### Sync engine (IntegrationRecSynchInvoke, IntegrationTableSynch)
- Бичлэг бүр амжилттай sync хийгдмэгц **coupling** (Integration Record мэппинг)
  шинэчлэгдэж Commit хийгдэнэ — тасалдсан sync дахин эхлэхэд хийгдсэн хэсэг
  давхардахгүй (checkpoint идемпотенц).
- `[TryFunction]`-ууд DB бичилтгүй, туслах үйлдлүүдэд л.
- Modified On timestamp + filter — зөвхөн өөрчлөгдсөнийг зөөдөг (delta sync).

### API webhooks
- `APIWebhookNotificationMgt` — subscription-д notification үүсгэдэг,
  батчаар илгээдэг, Commit-той checkpoint-уудтай.

## 3. Яагаад ингэж хийсэн бэ (analysis)

- SystemId түлхүүр: No. өөрчлөгдөж/дахин ашиглагдаж болно, GUID тогтмол — гадаад
  систем тогтвортой reference-тэй болно.
- Entity Aggregate: гадаад хэрэглэгч draft/posted ялгааг мэдэх шаардлагагүй нэг
  гадаргуу; мөн API contract нь дотоод schema-аас тусгаарлагдана.
- Post → Commit → Send: гадаад үйлдэл (email) transaction дотор байсан бол email
  явчихаад rollback хийгдэх, эсвэл email унахад posting rollback хийгдэх зөрүү үүсэх байсан.
- Coupling + Commit checkpoint: интеграцид "exactly once"-ийг локал transaction-аар
  баталгаажуулах боломжгүй тул "at least once + идемпотенц бүртгэл"-ээр шийдсэн.

## 4. Зөв хэрэгжилт

```al
// Гадаад дуудлага — transaction-ийн гадна, идемпотенц түлхүүртэй
procedure SendInvoiceToTaxAuthority(SalesInvHeader: Record "Sales Invoice Header")
var
    TaxDocLog: Record "Tax Doc. Log";
begin
    // Идемпотенц: аль хэдийн илгээгдсэн бол дахин илгээхгүй
    if TaxDocLog.Get(SalesInvHeader."No.") and (TaxDocLog.Status = TaxDocLog.Status::Sent) then
        exit;

    TaxDocLog.InitFor(SalesInvHeader);
    TaxDocLog.Status := TaxDocLog.Status::Sending;
    TaxDocLog.Insert();
    Commit(); // төлөв хадгалагдсан — давхар илгээлтээс хамгаална

    if TrySend(SalesInvHeader, ResponseText) then begin
        TaxDocLog.Status := TaxDocLog.Status::Sent;
        TaxDocLog."External Id" := GetExternalId(ResponseText);
    end else begin
        TaxDocLog.Status := TaxDocLog.Status::Error;
        TaxDocLog."Error Text" := CopyStr(GetLastErrorText(), 1, MaxStrLen(TaxDocLog."Error Text"));
    end;
    TaxDocLog.Modify();
end;
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: API page стандарт зөрчилтэй
page 50120 "My Orders API"
{
    PageType = API;
    SourceTable = "Sales Header";      // aggregate биш шууд баримт
    ODataKeyFields = "No.";            // SystemId биш — дугаар өөрчлөгдвөл гадаад холбоос тасарна
    // DelayedInsert байхгүй — талбар бүрт Insert оролдоно
}

// БУРУУ: retry нь давхар өгөгдөл үүсгэнэ
procedure ImportPayments()
begin
    foreach PaymentJson in ResponseArray do begin
        GenJnlLine.Init();             // гадаад ID-гаар давхардлыг шалгаагүй —
        CreatePaymentLine(PaymentJson); // timeout болоод дахин дуудвал
        GenJnlLine.Insert();           // ижил төлбөр 2 удаа орно
    end;
end;

// БУРУУ: HTTP статус шалгахгүй
HttpClient.Post(Url, Content, Response);            // Send-ийн boolean үр дүн ч шалгаагүй
Response.Content().ReadAs(ResponseText);
ProcessResponse(ResponseText);                      // 500 ирсэн ч "амжилттай" боловсруулна

// БУРУУ: transaction дотор гадаад дуудлага
SalesHeader.Modify();
HttpClient.Post(WebhookUrl, ...);   // унавал Modify rollback, гэвч webhook явчихсан
SalesLine.Modify();
```

## 6. Code review хийх дүрэм

1. **[HIGH]** Retry/давтан дуудлагад идемпотенц хамгаалалтгүй импорт/бичилт
   (external id, status, existence шалгалт байхгүй) — давхар өгөгдөл.
2. **[HIGH]** HTTP хариултын амжилт (`Send`-ийн үр дүн + `IsSuccessStatusCode`/статус
   код) шалгалгүй үргэлжлэх код.
3. **[HIGH]** DB transaction дотор (bичилт хийгээд Commit-гүй байхад) гадаад HTTP
   дуудлага — хоёр системийн зөрүү + удаан түгжээ.
4. **[HIGH]** Нууц (token, key) ердийн Text-ээр, эсвэл лог/telemetry руу орж байвал.
5. **[MEDIUM]** API page: ODataKeyFields нь SystemId биш, DelayedInsert байхгүй,
   Entity нэршил camelCase биш, breaking change (талбар устгах/нэр солих) —
   гадаад contract эвдэрнэ.
6. **[MEDIUM]** Timeout, richtige error handling байхгүй: HttpClient.Timeout
   тохируулаагүй удаан endpoint, TryFunction-гүй Send.
7. **[MEDIUM]** JSON боловсруулалт: талбар байхгүй үед crash (`GetValue` шууд),
   `JsonToken.AsValue().AsText()` null шалгалтгүй.
8. **[MEDIUM]** Их хэмжээний өгөгдөлд pagination ($top/$skip, nextLink, batch)
   байхгүй бүрэн уншилт.
9. **[LOW]** Rate limit (429) үед exponential backoff байхгүй шууд давтан оролдлого.
