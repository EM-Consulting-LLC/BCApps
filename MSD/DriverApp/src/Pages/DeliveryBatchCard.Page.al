namespace EMC.MSD.Delivery;

/// <summary>
/// Driver's Delivery Batch. On the phone only promoted actions are shown in the action bar, so every
/// driver action is promoted. The visible action changes with the status:
/// Ready to Load → LOADED → Loaded → START → In Transit → FINISH → Completed → DELIVERED.
/// </summary>
page 50103 "MSD Delivery Batch Card"
{
    PageType = Document;
    Caption = 'Delivery Batch';
    SourceTable = "MSD Delivery Batch Header";
    InsertAllowed = false;
    DeleteAllowed = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Ерөнхий';
                Editable = false;

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Batch-ийн төлөв.';
                }
                field(Progress; ProgressText)
                {
                    ApplicationArea = All;
                    Caption = 'Явц';
                    Visible = IsInTransit;
                    ToolTip = 'Бүртгэгдсэн цэг / нийт ачсан цэг.';
                }
                field("Delivery Date"; Rec."Delivery Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Түгээлтийн огноо.';
                }
                field("Vehicle No."; Rec."Vehicle No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Машины дугаар.';
                }
                field("Route Description"; Rec."Route Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Маршрут.';
                }
                field("Driver Name"; Rec."Driver Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Түгээгч.';
                }
            }
            group(Summary)
            {
                Caption = 'Хураангуй';
                Editable = false;

                field("No. of Stops"; Rec."No. of Stops")
                {
                    ApplicationArea = All;
                    ToolTip = 'Захиалгын тоо.';
                }
                field("No. of Loaded Stops"; Rec."No. of Loaded Stops")
                {
                    ApplicationArea = All;
                    ToolTip = 'LOADED тэмдэглэсэн захиалга.';
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Нийт тоо.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Нийт дүн (НӨАТ-тай).';
                }
                field("No. of Helpers"; Rec."No. of Helpers")
                {
                    ApplicationArea = All;
                    ToolTip = 'Туслахын тоо.';
                }
                field("No. of Posting Errors"; Rec."No. of Posting Errors")
                {
                    ApplicationArea = All;
                    Visible = HasPostingErrors;
                    Style = Unfavorable;
                    ToolTip = 'Нэхэмжлэл post хийхэд алдаа гарсан цэг. Супервайзерт мэдэгдсэн.';
                }
            }
            group(DeliveredInfo)
            {
                Caption = 'DELIVERED';
                Editable = false;
                Visible = IsCompleted;

                field(DeliveredMessage; DeliveredText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    StyleExpr = DeliveredStyle;
                    MultiLine = true;
                    ToolTip = 'DELIVERED статусын мэдээлэл.';
                }
            }
            part(Helpers; "MSD Batch Helpers")
            {
                ApplicationArea = All;
                Caption = 'Туслах';
                SubPageLink = "Batch No." = field("No.");
                Visible = HelpersVisible;
                Editable = Rec.Status = Rec.Status::Loaded;
                UpdatePropagation = Both;
            }
            part(Stops; "MSD Delivery Stops")
            {
                ApplicationArea = All;
                Caption = 'Цэгүүд';
                SubPageLink = "Batch No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Loaded)
            {
                ApplicationArea = All;
                Caption = 'LOADED';
                Image = Shipment;
                Enabled = Rec.Status = Rec.Status::"Ready to Load";
                ToolTip = 'Ачсан захиалгуудыг LOADED бүртгэнэ (DEL-004). Ачаагүй захиалга түгээгдэхгүй.';

                trigger OnAction()
                begin
                    DriverMgt.ConfirmLoaded(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Start)
            {
                ApplicationArea = All;
                Caption = 'START';
                Image = Start;
                Enabled = Rec.Status = Rec.Status::Loaded;
                ToolTip = 'Туслах сонгосны дараа түгээлтийг эхлүүлнэ (DEL-002, DEL-003).';

                trigger OnAction()
                begin
                    DriverMgt.StartDelivery(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(NextStop)
            {
                ApplicationArea = All;
                Caption = 'Дараагийн цэг';
                Image = NextRecord;
                Enabled = Rec.Status = Rec.Status::"In Transit";
                ToolTip = 'Маршрутын дараагийн цэгийг нээнэ (DEL-007).';

                trigger OnAction()
                var
                    Line: Record "MSD Delivery Batch Line";
                begin
                    if DriverMgt.GetNextStop(Rec."No.", Line) then
                        Page.Run(Page::"MSD Delivery Stop Card", Line)
                    else
                        Message(NoOpenStopsMsg);
                end;
            }
            action(Finish)
            {
                ApplicationArea = All;
                Caption = 'FINISH';
                Image = Completed;
                Enabled = Rec.Status = Rec.Status::"In Transit";
                ToolTip = 'Бүх цэг бүртгэгдсэн бол түгээлтийг дуусгана (DEL-012).';

                trigger OnAction()
                begin
                    DriverMgt.FinishDelivery(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Delivered)
            {
                ApplicationArea = All;
                Caption = 'DELIVERED';
                Image = Approve;
                Enabled = (Rec.Status = Rec.Status::Completed) and (not Rec."Delivered Confirmed");
                ToolTip = 'Өдрийн түгээлт бүрэн дууссаныг бүртгэнэ. Бөглөөгүй бол дараагийн түгээлт эхлэхгүй (DEL-013).';

                trigger OnAction()
                begin
                    DriverMgt.ConfirmDelivered(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Log)
            {
                ApplicationArea = All;
                Caption = 'Лог';
                Image = Log;
                RunObject = page "MSD Delivery Log Entries";
                RunPageLink = "Batch No." = field("No.");
                ToolTip = 'Энэ batch-ийн үйлдлийн түүх.';
            }
        }
        area(Promoted)
        {
            actionref(Loaded_Promoted; Loaded) { }
            actionref(Start_Promoted; Start) { }
            actionref(NextStop_Promoted; NextStop) { }
            actionref(Finish_Promoted; Finish) { }
            actionref(Delivered_Promoted; Delivered) { }
            actionref(Log_Promoted; Log) { }
        }
    }

    var
        DriverMgt: Codeunit "MSD Driver Mgt.";
        StatusStyle: Text;
        ProgressText: Text;
        DeliveredText: Text;
        DeliveredStyle: Text;
        HelpersVisible: Boolean;
        IsInTransit: Boolean;
        IsCompleted: Boolean;
        HasPostingErrors: Boolean;
        ProgressTxt: Label '%1 / %2', Locked = true;
        NoOpenStopsMsg: Label 'Бүртгэх цэг үлдсэнгүй. FINISH дарж түгээлтийг дуусгана уу.';
        DeliveredDoneTxt: Label 'DELIVERED бүртгэгдсэн. Дараагийн түгээлтийг START хийх боломжтой.';
        DeliveredMissingTxt: Label 'DELIVERED статус бөглөөгүй байна. Бөглөөгүй бол дараагийн өдрийн түгээлтийг START хийх боломжгүй.';

    trigger OnOpenPage()
    begin
        DriverMgt.CheckDriver(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("No. of Loaded Stops", "No. of Open Stops", "No. of Posting Errors");
        ProgressText := StrSubstNo(ProgressTxt, Rec."No. of Loaded Stops" - Rec."No. of Open Stops", Rec."No. of Loaded Stops");
        HelpersVisible := Rec.Status.AsInteger() >= Rec.Status::Loaded.AsInteger();
        IsInTransit := Rec.Status = Rec.Status::"In Transit";
        IsCompleted := Rec.Status = Rec.Status::Completed;
        HasPostingErrors := Rec."No. of Posting Errors" <> 0;

        case Rec.Status of
            Rec.Status::"In Transit":
                StatusStyle := 'Ambiguous';
            Rec.Status::Completed:
                StatusStyle := 'Favorable';
            else
                StatusStyle := 'StrongAccent';
        end;

        if Rec."Delivered Confirmed" then begin
            DeliveredText := DeliveredDoneTxt;
            DeliveredStyle := 'Favorable';
        end else begin
            DeliveredText := DeliveredMissingTxt;
            DeliveredStyle := 'Unfavorable';
        end;
    end;
}
