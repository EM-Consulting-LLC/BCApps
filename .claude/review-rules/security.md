# Security Review Rules — BC-SEC

---

## BC-SEC-001 — Hardcoded нууц / нууцын алдагдал

- **Severity:** CRITICAL
- **Rule:** API key, token, password, connection string код дотор literal-аар;
  нууц утга ердийн Text төрлөөр хадгалагдаж/дамжуулагдаж/логлогдож байвал илрүүлнэ.
- **Why:** Base App нууцыг SecretText, `SecretStrSubstNo('Bearer %1', Token)`,
  Isolated Storage, Azure Key Vault-аар зохицуулдаг; telemetry-д нууц ордоггүй.
- **Risk:** Эх код/лог/telemetry-ээс нууц алдагдах; extension-ий .app файлаас
  сэргээгдэх.
- **Detection:** `'Bearer '`, `'sk-'`, base64 маягийн literal; Password/Token
  нэртэй Text хувьсагч Session.LogMessage/Error текстэд орох; Isolated Storage-д
  Encrypt-гүй хадгалалт.
- **Suggested Fix:** SecretText төрөл; Isolated Storage (DataScope тохируулж);
  тохиргооны нууцыг setup хүснэгтийн масктай талбар + Isolated Storage-д.

---

## BC-SEC-002 — Authorization шалгалтгүй мэдрэмтгий үйлдэл

- **Severity:** CRITICAL
- **Rule:** Төлбөр илгээх, банкны файл экспортлох, эрх олгох, өгөгдөл бөөнөөр
  устгах зэрэг үйлдэл public procedure/API/web service-ээр ямар ч нэмэлт
  шалгалтгүй ил байвал илрүүлнэ.
- **Why:** Стандартад мэдрэмтгий үйлдэлд нэмэлт шалгалт байдаг
  (CheckPermissionToSendICTransaction; approval workflow-ийн Post restriction).
- **Risk:** Unauthorized access — permission set-ийн тохиргооноос үл хамааран
  дуудаж болдог зам үүсэх.
- **Detection:** [ServiceEnabled], API page action, public procedure-ээр ил гарсан
  үйлдлүүдийн жагсаалт → үйлдэл бүрд ямар permission/шалгалт үйлчлэхийг үнэл.
- **Suggested Fix:** Тусгай permission set/setup туг, approval урсгал, эсвэл
  Access = Internal болгож хүрээг хумь.

---

## BC-SEC-003 — Injection ба гадаад оролтын баталгаажуулалт

- **Severity:** HIGH
- **Rule:** Гадаад оролт (API параметр, файл, HTTP хариулт) шалгалтгүйгээр:
  filter руу (`SetFilter(Field, UserInput)`), URL руу, RecordRef/FieldRef рүү
  очиж байвал илрүүлнэ.
- **Why:** SetFilter-ийн оролтод `&|<>*@` тэмдэгтүүд filter синтакс болдог —
  халдагч шүүлтийг өргөсгөж чадна; URL-д encode хийгдээгүй утга request-ийг эвднэ.
- **Risk:** Өгөгдлийн ил гарц, буруу record дээр үйлдэл.
- **Detection:** SetFilter-т хэрэглэгчийн оролт шууд; StrSubstNo-оор угсарсан URL
  дэх encode-гүй утга; XML/JSON-оос ирсэн утыг validate-гүй ашиглах.
- **Suggested Fix:** SetRange (literal утгад filter синтакс үйлчилдэггүй) ашигла;
  `'%1'` биш `'@%1'`/quote-лох хэлбэрийг судал; UriBuilder/TypeHelper-ээр encode хий.

---

## BC-SEC-004 — Устгасан/нууцлалтай өгөгдлийн зохицуулалт (GDPR)

- **Severity:** MEDIUM
- **Rule:** Хувь хүний өгөгдөлтэй шинэ талбар DataClassification буруу
  (SystemMetadata/ToBeClassified) байвал; Privacy Blocked харилцагчтай гүйлгээ
  үүсгэж байвал илрүүлнэ.
- **Why:** BC-ийн Data Classification framework GDPR тайлагналд ашиглагддаг;
  Customer."Privacy Blocked" стандарт validation-д шалгагддаг.
- **Detection:** Table diff — нэр, утас, имэйл, хаяг маягийн талбарууд
  CustomerContent/EndUserIdentifiableInformation биш; Privacy Blocked шалгалт
  алгассан бичилт.
- **Suggested Fix:** Зөв ангилал; Privacy Blocked шалгалт нэм.

---

## BC-SEC-005 — Криптограф ба протоколын дадал

- **Severity:** HIGH
- **Rule:** Custom шифрлэлт/хэшийг гараар хэрэгжүүлэх, http:// endpoint,
  сертификат шалгалтыг унтраах оролдлого, эмзэг алгоритм (MD5/SHA1-ийг нууцад)
  ашиглаж байвал илрүүлнэ.
- **Why:** System Application-д Cryptography Management, X.509 модулиуд бэлэн;
  Base App гадагшаа зөвхөн https харьцдаг.
- **Detection:** 'http://' literal (localhost-оос бусад), өөрөө бичсэн XOR/base64
  "шифрлэлт", HashAlgorithmType сонголт.
- **Suggested Fix:** Cryptography Management facade ашигла; https шаард.
