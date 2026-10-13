namespace EMC.MSD.Delivery;

/// <summary>
/// Background invoice posting state of a stop (DEL-008).
/// </summary>
enum 50103 "MSD Posting Status"
{
    Extensible = true;
    Caption = 'Posting Status';

    value(0; " ") { Caption = ' '; }
    value(1; Queued) { Caption = 'Queued'; }
    value(2; Posted) { Caption = 'Posted'; }
    value(3; Error) { Caption = 'Error'; }
}
