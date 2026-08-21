# Security Reference — Аюулгүй байдлын шалгалт

## Суурь зарчим

- Нууц утга: `SecretText`, `SecretStrSubstNo('Bearer %1', Token)`, Isolated
  Storage, Azure Key Vault — хэзээ ч plain Text/код/лог/telemetry-д байхгүй.
- Мэдрэмтгий үйлдэлд нэмэлт authorization (стандарт жишээ:
  CheckPermissionToSendICTransaction; approval-ийн post restriction event).
- Гадаад оролт баталгаажуулалттай; гадагшаа зөвхөн https.
- Криптод System Application-ий Cryptography Management facade.
- Telemetry: Session.LogMessage üргэлж DataClassification::SystemMetadata,
  хэрэглэгчийн өгөгдөлгүй.

## Дүрмүүд

### BC-SEC-001 [CRITICAL] — Hardcoded нууц / нууцын алдагдал
Literal API key/token/password; нууц Text төрлөөр; нууц Error текст, лог,
telemetry-д орох; Isolated Storage-д encrypt-гүй. **Detection:** `'Bearer '`,
`'sk-'`, base64 literal, Password нэртэй Text хувьсагч LogMessage-д.
**Засвар:** SecretText + Isolated Storage/Key Vault.

### BC-SEC-002 [CRITICAL] — Authorization-гүй мэдрэмтгий үйлдэл
Төлбөр илгээх, банк файл экспорт, эрх олгох, бөөнөөр устгах үйлдэл public
procedure/[ServiceEnabled]/API-аар шалгалтгүй ил. **Засвар:** тусгай permission,
setup туг, approval урсгал, эсвэл Access = Internal.

### BC-SEC-003 [HIGH] — Injection / оролтын баталгаажуулалт
Хэрэглэгч/гадаад оролт шууд `SetFilter(Field, Input)` руу (`&|<>*@` filter синтакс
болно — шүүлт өргөсдөнө), encode-гүй URL угсралт, validate-гүй RecordRef хандалт.
**Засвар:** SetRange (literal-д синтакс үйлчлэхгүй); UriBuilder/encode.

### BC-SEC-004 [MEDIUM] — GDPR / өгөгдлийн ангилал
Хувь хүний өгөгдөлтэй талбар DataClassification буруу; Privacy Blocked шалгалт
алгассан гүйлгээ.

### BC-SEC-005 [HIGH] — Криптограф/протокол
Өөрөө бичсэн "шифрлэлт", нууцад MD5/SHA1, http:// endpoint (localhost-оос бусад),
cert шалгалт унтраах. **Засвар:** Cryptography Management; https.

## Шалгах фокус цэгүүд

- HttpClient DefaultRequestHeaders-д юу нэмэгдэж байна (Authorization ямар төрлөөр)?
- Error/LogMessage-ийн текстэд ямар өгөгдөл орж байна?
- Web service болгож ил гаргасан объект бүр: хэн, юуг дуудаж чадах вэ?
- Config/Setup хүснэгтийн нууц талбарууд: ExtendedDatatype = Masked +
  Isolated Storage уу, эсвэл plain талбар уу?
