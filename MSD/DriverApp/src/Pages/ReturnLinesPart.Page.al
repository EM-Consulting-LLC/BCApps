namespace EMC.MSD.Delivery;

page 50109 "MSD Return Lines Part"
{
    PageType = ListPart;
    Caption = 'Буцаах бараа';
    SourceTable = "MSD Delivery Return Line";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Барааны нэр.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Барааны код.';
                }
                field("Delivered Quantity"; Rec."Delivered Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Ачсан тоо.';
                }
                field("Return Quantity"; Rec."Return Quantity")
                {
                    ApplicationArea = All;
                    Style = StrongAccent;
                    ToolTip = 'Буцаах тоо. 0-ээс ачсан тооны хооронд.';
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = Rec."Return Quantity" <> 0;
                    ToolTip = 'Буцаах тоо 0-ээс их бол шалтгаан заавал.';
                }
                field("Handed Over Quantity"; Rec."Handed Over Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Харилцагчид хүлээлгэсэн тоо.';
                }
            }
        }
    }
}
