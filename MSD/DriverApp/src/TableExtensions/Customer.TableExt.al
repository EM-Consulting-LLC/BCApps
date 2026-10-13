namespace EMC.MSD.Delivery;

using Microsoft.Sales.Customer;

/// <summary>
/// Customer delivery point coordinates and geofence radius (DEL-015, DEL-016).
/// </summary>
tableextension 50100 "MSD Customer" extends Customer
{
    fields
    {
        field(50100; "MSD Latitude"; Decimal)
        {
            Caption = 'Latitude';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 7;
            MinValue = -90;
            MaxValue = 90;
        }
        field(50101; "MSD Longitude"; Decimal)
        {
            Caption = 'Longitude';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 7;
            MinValue = -180;
            MaxValue = 180;
        }
        field(50102; "MSD Geofence Radius (m)"; Integer)
        {
            Caption = 'Geofence Radius (m)';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
    }
}
