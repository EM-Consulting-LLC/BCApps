namespace EMC.MSD.Delivery;

/// <summary>
/// Events written to the Delivery Log (DEL-002 LOG, WMS-100 history).
/// </summary>
enum 50106 "MSD Delivery Log Event"
{
    Extensible = true;
    Caption = 'Delivery Log Event';

    value(0; "Status Change") { Caption = 'Status Change'; }
    value(1; "Stop Loaded") { Caption = 'Stop Loaded'; }
    value(2; "Sequence Change") { Caption = 'Sequence Change'; }
    value(3; "Helper Added") { Caption = 'Helper Added'; }
    value(4; "Helper Removed") { Caption = 'Helper Removed'; }
    value(5; "Stop Registered") { Caption = 'Stop Registered'; }
    value(6; "Stop Skipped") { Caption = 'Stop Skipped'; }
    value(7; "Payment Type Change") { Caption = 'Payment Type Change'; }
    value(8; "Invoice Posted") { Caption = 'Invoice Posted'; }
    value(9; "Posting Error") { Caption = 'Posting Error'; }
    value(10; "Return Order Created") { Caption = 'Return Order Created'; }
    value(11; "Geofence Rejected") { Caption = 'Geofence Rejected'; }
    value(12; "Delivered Confirmed") { Caption = 'Delivered Confirmed'; }
}
