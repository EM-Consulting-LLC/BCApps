namespace EMC.MSD.Delivery;

/// <summary>
/// Cue table for the driver Role Center. Filtered by the current driver in the activities page.
/// </summary>
table 50107 "MSD Driver Cue"
{
    Caption = 'Driver Cue';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Driver Filter"; Code[20])
        {
            Caption = 'Driver Filter';
            FieldClass = FlowFilter;
        }
        field(10; "Batches to Load"; Integer)
        {
            Caption = 'Хүлээгдэж буй batch';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Header" where("Driver No." = field("Driver Filter"), Status = filter("Ready to Load" | Loaded)));
            Editable = false;
        }
        field(11; "Batches In Transit"; Integer)
        {
            Caption = 'In Transit';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Header" where("Driver No." = field("Driver Filter"), Status = const("In Transit")));
            Editable = false;
        }
        field(12; "Open Stops"; Integer)
        {
            Caption = 'Үлдсэн цэг';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Line" where("Driver No." = field("Driver Filter"), "Batch Status" = const("In Transit"), Loaded = const(true), "Delivery Status" = filter(Pending | Skipped)));
            Editable = false;
        }
        field(13; "Skipped Stops"; Integer)
        {
            Caption = 'Skipped';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Line" where("Driver No." = field("Driver Filter"), "Batch Status" = const("In Transit"), "Delivery Status" = const(Skipped)));
            Editable = false;
        }
        field(14; "Delivered Not Confirmed"; Integer)
        {
            Caption = 'DELIVERED бөглөөгүй';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Header" where("Driver No." = field("Driver Filter"), Status = const(Completed), "Delivered Confirmed" = const(false)));
            Editable = false;
        }
        field(15; "Posting Errors"; Integer)
        {
            Caption = 'Posting алдаа';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Line" where("Driver No." = field("Driver Filter"), "Posting Status" = const(Error)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
