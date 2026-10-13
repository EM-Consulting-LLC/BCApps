namespace EMC.MSD.Delivery;

/// <summary>
/// One role per distribution worker (WMS-048, WMS-049).
/// </summary>
enum 50102 "MSD Worker Role"
{
    Extensible = true;
    Caption = 'Worker Role';

    value(0; Driver) { Caption = 'Driver'; }
    value(1; Helper) { Caption = 'Helper'; }
    value(2; Picker) { Caption = 'Picker'; }
    value(3; Packer) { Caption = 'Packer'; }
    value(4; Supervisor) { Caption = 'Supervisor'; }
}
