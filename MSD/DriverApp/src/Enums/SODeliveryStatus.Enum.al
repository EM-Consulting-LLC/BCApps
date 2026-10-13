namespace EMC.MSD.Delivery;

/// <summary>
/// Delivery status mirrored on the Sales Order (WMS-091: all SOs of the batch follow the batch to In Transit).
/// </summary>
enum 50104 "MSD SO Delivery Status"
{
    Extensible = true;
    Caption = 'SO Delivery Status';

    value(0; " ") { Caption = ' '; }
    value(1; Planned) { Caption = 'Planned'; }
    value(2; Loaded) { Caption = 'Loaded'; }
    value(3; "In Transit") { Caption = 'In Transit'; }
    value(4; Fully) { Caption = 'Fully'; }
    value(5; Partially) { Caption = 'Partially'; }
    value(6; Cancelled) { Caption = 'Cancel'; }
}
