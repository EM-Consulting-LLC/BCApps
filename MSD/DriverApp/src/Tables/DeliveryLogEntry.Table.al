namespace EMC.MSD.Delivery;

/// <summary>
/// Delivery activity log (DEL-002 LOG, WMS-100). Every driver action and background posting result is written here.
/// </summary>
table 50106 "MSD Delivery Log Entry"
{
    Caption = 'Delivery Log Entry';
    DataClassification = CustomerContent;
    LookupPageId = "MSD Delivery Log Entries";
    DrillDownPageId = "MSD Delivery Log Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
        }
        field(3; "Batch Line No."; Integer)
        {
            Caption = 'Batch Line No.';
        }
        field(4; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
        }
        field(5; "Event"; Enum "MSD Delivery Log Event")
        {
            Caption = 'Event';
        }
        field(6; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(7; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(8; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; Latitude; Decimal)
        {
            Caption = 'Latitude';
            DecimalPlaces = 0 : 7;
        }
        field(10; Longitude; Decimal)
        {
            Caption = 'Longitude';
            DecimalPlaces = 0 : 7;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Batch; "Batch No.", "Batch Line No.") { }
    }
}
