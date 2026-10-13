namespace EMC.MSD.Delivery;

/// <summary>
/// Delivery Batch lifecycle (WMS-053). The driver app works with Ready to Load .. Completed.
/// </summary>
enum 50100 "MSD Delivery Batch Status"
{
    Extensible = true;
    Caption = 'Delivery Batch Status';

    value(0; Planning) { Caption = 'Planning'; }
    value(1; "Ready to Pick") { Caption = 'Ready to Pick'; }
    value(2; Picking) { Caption = 'Picking'; }
    value(3; Picked) { Caption = 'Picked'; }
    value(4; Packing) { Caption = 'Packing'; }
    value(5; Packed) { Caption = 'Packed'; }
    value(6; "Ready to Load") { Caption = 'Ready to Load'; }
    value(7; Loaded) { Caption = 'Loaded'; }
    value(8; "In Transit") { Caption = 'In Transit'; }
    value(9; Completed) { Caption = 'Completed'; }
    value(10; Reviewed) { Caption = 'Reviewed'; }
    value(11; Closed) { Caption = 'Closed'; }
}
