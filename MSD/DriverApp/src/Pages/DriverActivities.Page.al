namespace EMC.MSD.Delivery;

page 50101 "MSD Driver Activities"
{
    PageType = CardPart;
    Caption = 'Миний түгээлт';
    SourceTable = "MSD Driver Cue";
    RefreshOnActivate = true;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            cuegroup(Today)
            {
                Caption = 'Миний түгээлт';

                field("Batches to Load"; Rec."Batches to Load")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "MSD Delivery Batch List";
                    ToolTip = 'Ready to Load эсвэл Loaded төлөвтэй batch.';
                }
                field("Batches In Transit"; Rec."Batches In Transit")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "MSD Delivery Batch List";
                    ToolTip = 'Түгээлт хийгдэж буй batch.';
                }
                field("Open Stops"; Rec."Open Stops")
                {
                    ApplicationArea = All;
                    ToolTip = 'Бүртгэгдээгүй үлдсэн цэг.';

                    trigger OnDrillDown()
                    begin
                        OpenActiveBatch();
                    end;
                }
                field("Skipped Stops"; Rec."Skipped Stops")
                {
                    ApplicationArea = All;
                    StyleExpr = SkippedStyle;
                    ToolTip = 'Алгасаж, дараа нь бүртгэх цэг.';

                    trigger OnDrillDown()
                    begin
                        OpenActiveBatch();
                    end;
                }
            }
            cuegroup(Attention)
            {
                Caption = 'Анхааруулга';

                field("Delivered Not Confirmed"; Rec."Delivered Not Confirmed")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "MSD Delivery Batch List";
                    StyleExpr = DeliveredStyle;
                    ToolTip = 'Дууссан боловч DELIVERED бөглөөгүй batch. Бөглөөгүй бол дараагийн түгээлтийг START хийх боломжгүй.';
                }
                field("Posting Errors"; Rec."Posting Errors")
                {
                    ApplicationArea = All;
                    StyleExpr = ErrorStyle;
                    ToolTip = 'Нэхэмжлэл post хийхэд алдаа гарсан цэг. Супервайзер засна.';

                    trigger OnDrillDown()
                    begin
                        OpenActiveBatch();
                    end;
                }
            }
            cuegroup(Actions)
            {
                Caption = 'Үйлдэл';
                CuegroupLayout = Wide;

                actions
                {
                    action(OpenMyBatches)
                    {
                        ApplicationArea = All;
                        Caption = 'Миний Delivery Batch';
                        Image = TileBrickCalendar;
                        RunObject = page "MSD Delivery Batch List";
                        ToolTip = 'Танд хуваарилагдсан batch-уудыг нээх.';
                    }
                }
            }
        }
    }

    var
        SkippedStyle: Text;
        DeliveredStyle: Text;
        ErrorStyle: Text;

    trigger OnOpenPage()
    var
        DriverMgt: Codeunit "MSD Driver Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        Rec.SetRange("Driver Filter", DriverMgt.GetCurrentDriverNo());
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Skipped Stops", "Delivered Not Confirmed", "Posting Errors");
        SkippedStyle := 'Standard';
        DeliveredStyle := 'Favorable';
        ErrorStyle := 'Favorable';
        if Rec."Skipped Stops" > 0 then
            SkippedStyle := 'Ambiguous';
        if Rec."Delivered Not Confirmed" > 0 then
            DeliveredStyle := 'Unfavorable';
        if Rec."Posting Errors" > 0 then
            ErrorStyle := 'Unfavorable';
    end;

    local procedure OpenActiveBatch()
    var
        Header: Record "MSD Delivery Batch Header";
        DriverMgt: Codeunit "MSD Driver Mgt.";
    begin
        Header.SetRange("Driver No.", DriverMgt.GetCurrentDriverNo());
        Header.SetRange(Status, Header.Status::"In Transit");
        if Header.FindFirst() then
            Page.Run(Page::"MSD Delivery Batch Card", Header)
        else
            Page.Run(Page::"MSD Delivery Batch List");
    end;
}
