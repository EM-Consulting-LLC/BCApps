# Object Responsibility — Объектын хариуцлагын мэдлэгийн сан

## 1. Зарчим

Object type бүр тодорхой, хязгаарлагдмал хариуцлагатай. Логик "хаана байх ёстой вэ"
гэдэг асуултад эх код тодорхой хариулт өгдөг: **өгөгдлийн дүрэм Table-д, процесс
Codeunit-д, харагдац Page-д, солигдох algorithm Interface-д.**

## 2. Source code дээрх ажиглалт

| Object | Хариуцлага (эх кодын жишээ) |
|---|---|
| **Table** | Талбарын validation (`SalesLine.Quantity` OnValidate: TestStatusOpen, FieldError, base qty тооцоолол); мастер өгөгдлийн lifecycle (`Customer.OnInsert` — No. Series олгох, `OnDelete` — нээлттэй Job байвал Error, MoveEntries, холбогдох өгөгдөл цэвэрлэх) |
| **Table Extension** | Зөвхөн нэмэлт талбар + богино validation; урсгалын логик агуулдаггүй |
| **Page** | Layout, action delegate, visibility. `SalesOrder.Page.al` Post action → codeunit |
| **Page Extension** | UI өргөтгөл; logic байхгүй |
| **Codeunit (posting)** | `TableNo=` + `Permissions=` зарлалттай; Check → Post → Finalize фазтай |
| **Codeunit (Mgt.)** | Домэйн туслах логик (`Unit of Measure Management`, `Batch Processing Mgt.`) |
| **Codeunit (Yes/No)** | Хэрэглэгчийн баталгаажуулалт + delegate (`Sales-Post (Yes/No)`) |
| **Codeunit (Subscribers)** | Модулиуд холбох event subscriber-ууд (`BusinessSetupSubscribers`) |
| **Codeunit (Install/Upgrade)** | `Subtype = Install/Upgrade`, Upgrade Tag хамгаалалттай, идемпотент |
| **Report** | Тайлан + batch process; өөрийн request page-тэй |
| **Query** | Aggregate уншилт (`QtyReservedFromItemLedger`), telemetry |
| **XMLPort** | Импорт/экспорт формат |
| **Enum** | Extensible сонголт; interface-тэй хослож implementation сонгодог |
| **Interface** | Гэрээ: `Invoice Posting`, `Price Calculation`, `No. Series - Single` |
| **Permission Set** | Composition (`IncludedPermissionSets`); RIMD том/жижиг үсгээр direct/indirect ялгадаг |

Мөн ажиглагдсан нь: Table trigger дотор ч `OnBefore...` + `IsHandled` event зарлагддаг;
документын validation нь Table (интерактив үед) + posting Check codeunit (эцсийн
баталгаа) гэсэн **давхар** түвшинд байдаг.

## 3. Яагаад ингэж хийсэн бэ (analysis)

- Table-д validation байрлуулснаар UI, API, code — аль ч сувгаар өгөгдөл орсон
  ижил дүрэм үйлчилнэ (Validate дуудагдвал).
- Гэхдээ Table validation нь `CurrFieldNo`, статусаас хамаарч нөхцөлт байдаг тул
  **posting-ийн өмнө Check codeunit бүх баримтыг бүрэн дахин шалгадаг** —
  интерактив бус зам (API, өөр код)-аар орж ирсэн буруу өгөгдлөөс хамгаална.
- (Yes/No) codeunit-ууд нь GUI dialog-ийг бизнес логикоос салгаснаар background
  session, web service-ээс posting дуудах боломж бүрддэг.

## 4. Зөв хэрэгжилт

```al
// Талбарын дүрэм Table дээр
field(50100; "Loyalty Points"; Integer)
{
    trigger OnValidate()
    begin
        TestStatusOpen();
        if "Loyalty Points" < 0 then
            FieldError("Loyalty Points", NegativePointsErr);
    end;
}

// Процесс Codeunit дээр, баримтын бүрэн шалгалт posting-ийн өмнө
codeunit 50100 "Loyalty Mgt."
{
    procedure ApplyPoints(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
        ...
    end;
}
```

## 5. Буруу хэрэгжилт

```al
// БУРУУ: validation зөвхөн Page дээр — API-аар орж ирвэл шалгагдахгүй
// MyItemCard.PageExt.al
field("Min Stock"; Rec."Min Stock")
{
    trigger OnValidate()
    begin
        if Rec."Min Stock" < 0 then
            Error(MinStockErr); // Table-д байх ёстой байсан
    end;
}

// БУРУУ: бизнес урсгал Table Extension-ий OnValidate дотор
field(50101; "Auto Ship"; Boolean)
{
    trigger OnValidate()
    var
        WhseShipment: Codeunit "Whse.-Post Shipment";
    begin
        WhseShipment.Run(...); // талбар validate хийхэд агуулах бичилт хийж байна!
    end;
}
```

## 6. Code review хийх дүрэм

1. **[HIGH]** Validation зөвхөн Page/Page Extension дээр байвал: Table руу нүүлгэ —
   API, code-оос ирэх өгөгдөлд үйлчлэхгүй байгааг тайлбарла.
2. **[HIGH]** Table талбарын OnValidate дотор бичилт/posting/HTTP дуудлага байвал:
   validation нь side-effect-гүй байх ёстой (дагалдах талбарын шинэчлэл зөвшөөрнө,
   posting үйлдэл хориглоно).
3. **[MEDIUM]** Том процессын логик Report/Page trigger дотор шигтгэсэн байвал
   codeunit болгож салгахыг зөвлө (тест хийх, дахин ашиглах боломж).
4. **[MEDIUM]** Мастер өгөгдлийн OnDelete-д хамааралтай нээлттэй гүйлгээ шалгадаг эсэх
   (Customer.OnDelete-ийн Job шалгалт шиг) — шалгаагүй бол orphan өгөгдлийн эрсдэл.
5. **[MEDIUM]** Интерактив validation дээр тулгуурласан posting логик байвал: posting
   зам дээрх бүрэн шалгалт (Check codeunit төрлийн) байгаа эсэхийг шалга.
6. **[LOW]** Codeunit-ийн нэршил үүргээ илэрхийлж байгаа эсэх (Mgt., Post, Check,
   Subscribers гэх мэт конвенц).
