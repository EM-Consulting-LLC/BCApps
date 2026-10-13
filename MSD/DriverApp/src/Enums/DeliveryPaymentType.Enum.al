namespace EMC.MSD.Delivery;

/// <summary>
/// Payment type chosen by the driver at the customer (DEL-006).
/// Mapped to a Payment Method Code in MSD Delivery Setup when the invoice is posted.
/// </summary>
enum 50105 "MSD Delivery Payment Type"
{
    Extensible = true;
    Caption = 'Delivery Payment Type';

    value(0; Credit) { Caption = 'Зээл'; }
    value(1; Cash) { Caption = 'Бэлэн'; }
    value(2; NonCash) { Caption = 'Бэлэн бус'; }
}
