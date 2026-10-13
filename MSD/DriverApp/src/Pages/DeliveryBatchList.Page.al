namespace EMC.MSD.Delivery;

/// <summary>
/// Driver's own batches (DEL-001). Drivers only see their batches from Ready to Load until Completed;
/// completed batches stay visible until the supervisor reviews them, so DELIVERED can be filled in (DEL-013).
/// </summary>
page 50102 "MSD Delivery Batch List"
{
    PageType = List;
    Caption = 'Миний Delivery Batch';
    SourceTable = "MSD Delivery Batch Header";
    CardPageId = "MSD Delivery Batch Card";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Driver No.", Status, "Delivery Date") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Batches)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Delivery Batch-ийн дугаар.';
                }
                field("Route Description"; Rec."Route Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Маршрут.';
                }
                field("Vehicle No."; Rec."Vehicle No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Машины дугаар.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Batch-ийн төлөв.';
                }
                field("Delivery Date"; Rec."Delivery Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Түгээлтийн огноо.';
                }
                field("No. of Stops"; Rec."No. of Stops")
                {
                    ApplicationArea = All;
                    ToolTip = 'Захиалгын тоо.';
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Нийт тоо.';
                }
                field("Delivered Confirmed"; Rec."Delivered Confirmed")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'DELIVERED бүртгэсэн эсэх.';
                }
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnOpenPage()
    var
        DriverMgt: Codeunit "MSD Driver Mgt.";
        DriverNo: Code[20];
    begin
        DriverNo := DriverMgt.GetCurrentDriverNo();
        if DriverNo <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetRange("Driver No.", DriverNo);
            Rec.FilterGroup(0);
        end;
        if Rec.GetFilter(Status) = '' then
            Rec.SetRange(Status, Rec.Status::"Ready to Load", Rec.Status::Completed);
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::"In Transit":
                StatusStyle := 'Ambiguous';
            Rec.Status::Completed:
                if Rec."Delivered Confirmed" then
                    StatusStyle := 'Favorable'
                else
                    StatusStyle := 'Unfavorable';
            else
                StatusStyle := 'StrongAccent';
        end;
    end;
}
