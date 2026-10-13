namespace EMC.MSD.Delivery;

/// <summary>
/// Delivery status of one stop (one Sales Order) on a Delivery Batch (DEL-005).
/// The driver can only choose Fully, Partially or Cancelled; Skipped is a temporary state.
/// </summary>
enum 50101 "MSD Stop Delivery Status"
{
    Extensible = true;
    Caption = 'Stop Delivery Status';

    value(0; Pending) { Caption = 'Pending'; }
    value(1; Fully) { Caption = 'Fully'; }
    value(2; Partially) { Caption = 'Partially'; }
    value(3; Cancelled) { Caption = 'Cancel'; }
    value(4; Skipped) { Caption = 'Skipped'; }
}
