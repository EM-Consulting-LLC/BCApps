namespace EMC.MSD.Delivery;

page 50112 "MSD Delivery Log Entries"
{
    PageType = List;
    Caption = 'Түгээлтийн лог';
    SourceTable = "MSD Delivery Log Entry";
    SourceTableView = sorting("Entry No.") order(descending);
    ApplicationArea = All;
    UsageCategory = History;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Хэзээ.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Юу болсон.';
                }
                field("Event"; Rec."Event")
                {
                    ApplicationArea = All;
                    ToolTip = 'Үйлдлийн төрөл.';
                }
                field("Batch No."; Rec."Batch No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Delivery Batch.';
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Борлуулалтын захиалга.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Хэрэглэгч.';
                }
                field(Latitude; Rec.Latitude)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Latitude.';
                }
                field(Longitude; Rec.Longitude)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Longitude.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Entry No.';
                }
            }
        }
    }
}
