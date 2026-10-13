namespace EMC.MSD.Delivery;

/// <summary>
/// Partially delivered stop: the driver enters the returned quantity and reason per line (DEL-009).
/// A Card with a ListPart is used because Worksheet pages do not open on the phone.
/// </summary>
page 50108 "MSD Partial Delivery"
{
    PageType = Card;
    Caption = 'Буцаалтын мөрүүд';
    SourceTable = "MSD Delivery Batch Line";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Захиалга';
                Editable = false;

                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Борлуулалтын захиалга.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Харилцагч.';
                }
                field(Hint; HintTxt)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    MultiLine = true;
                    Style = Subordinate;
                    ToolTip = 'Заавар.';
                }
            }
            part(ReturnLines; "MSD Return Lines Part")
            {
                ApplicationArea = All;
                Caption = 'Буцаах бараа';
                SubPageLink = "Batch No." = field("Batch No."), "Batch Line No." = field("Line No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ConfirmPartially)
            {
                ApplicationArea = All;
                Caption = 'Баталгаажуулах';
                Image = Approve;
                ToolTip = 'Partially гэж бүртгэнэ. Нэхэмжлэл post хийгдэж буцаалтын захиалга автоматаар үүснэ.';

                trigger OnAction()
                var
                    DriverMgt: Codeunit "MSD Driver Mgt.";
                begin
                    Rec.Get(Rec."Batch No.", Rec."Line No.");
                    DriverMgt.RegisterPartially(Rec);
                    if not Rec.IsOpen() then
                        CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ConfirmPartially_Promoted; ConfirmPartially) { }
        }
    }

    var
        HintTxt: Label 'Мөр дээр дарж буцаах тоо, шалтгаанаа оруулна. ✎ дарж засах горимд шилжинэ. Бүх барааг буцааж байгаа бол Cancel ашиглана.';
}
