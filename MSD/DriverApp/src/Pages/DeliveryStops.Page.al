namespace EMC.MSD.Delivery;

/// <summary>
/// Stops of the batch in route order.
/// Before START: mark LOADED (DEL-004) and change the order with Up / Down (DEL-014).
/// In Transit: only the next stop can be opened (DEL-007).
/// </summary>
page 50104 "MSD Delivery Stops"
{
    PageType = ListPart;
    Caption = 'Цэгүүд';
    SourceTable = "MSD Delivery Batch Line";
    SourceTableView = sorting("Batch No.", "Sequence No.");
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Sequence No."; Rec."Sequence No.")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                    ToolTip = 'Түгээх дараалал.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    StyleExpr = LineStyle;
                    ToolTip = 'Харилцагч. Дарж цэгийг нээнэ.';

                    trigger OnDrillDown()
                    begin
                        OpenStop();
                    end;
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Борлуулалтын захиалга.';
                }
                field("Amount Incl. VAT"; Rec."Amount Incl. VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Дүн (НӨАТ-тай).';
                }
                field(Loaded; Rec.Loaded)
                {
                    ApplicationArea = All;
                    ToolTip = 'Машинд ачсан эсэх.';
                }
                field(StatusText; StatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Төлөв';
                    StyleExpr = LineStyle;
                    ToolTip = 'Хүргэлтийн төлөв.';
                }
                field("Posting Status"; Rec."Posting Status")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Нэхэмжлэлийн post-ын төлөв.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Open)
            {
                ApplicationArea = All;
                Caption = 'Нээх';
                Image = ShowList;
                Scope = Repeater;
                ToolTip = 'Цэгийн дэлгэрэнгүйг нээнэ.';

                trigger OnAction()
                begin
                    OpenStop();
                end;
            }
            action(ToggleLoaded)
            {
                ApplicationArea = All;
                Caption = 'LOADED тэмдэглэх';
                Image = Shipment;
                Scope = Repeater;
                ToolTip = 'Захиалгыг ачсан / ачаагүй гэж тэмдэглэнэ (DEL-004).';

                trigger OnAction()
                begin
                    DriverMgt.ToggleLoaded(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(MoveUp)
            {
                ApplicationArea = All;
                Caption = 'Дээш';
                Image = MoveUp;
                Scope = Repeater;
                ToolTip = 'Түгээх дарааллыг нэгээр урагшлуулна (DEL-014).';

                trigger OnAction()
                begin
                    DriverMgt.MoveStop(Rec, -1);
                    CurrPage.Update(false);
                end;
            }
            action(MoveDown)
            {
                ApplicationArea = All;
                Caption = 'Доош';
                Image = MoveDown;
                Scope = Repeater;
                ToolTip = 'Түгээх дарааллыг нэгээр хойшлуулна (DEL-014).';

                trigger OnAction()
                begin
                    DriverMgt.MoveStop(Rec, 1);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        DriverMgt: Codeunit "MSD Driver Mgt.";
        LineStyle: Text;
        StatusText: Text;
        NotLoadedTxt: Label 'Ачаагүй';
        NextTxt: Label 'Дараагийн';
        PostingErrorTxt: Label '%1 · алдаа', Comment = '%1 = delivery status';
        PostingQueuedTxt: Label '%1 · post…', Comment = '%1 = delivery status';

    trigger OnAfterGetRecord()
    begin
        SetStatusText();
    end;

    local procedure SetStatusText()
    var
        IsNext: Boolean;
    begin
        StatusText := Format(Rec."Delivery Status");
        LineStyle := 'Standard';

        if (Rec."Batch Status" = Rec."Batch Status"::"In Transit") and Rec.IsOpen() then
            IsNext := DriverMgt.IsNextStop(Rec);

        case true of
            not Rec.Loaded and (Rec."Delivery Status" = Rec."Delivery Status"::Pending):
                begin
                    StatusText := NotLoadedTxt;
                    LineStyle := 'Subordinate';
                end;
            IsNext:
                begin
                    StatusText := NextTxt;
                    LineStyle := 'StrongAccent';
                end;
            Rec."Delivery Status" = Rec."Delivery Status"::Fully:
                LineStyle := 'Favorable';
            Rec."Delivery Status" = Rec."Delivery Status"::Partially,
            Rec."Delivery Status" = Rec."Delivery Status"::Skipped:
                LineStyle := 'Ambiguous';
            Rec."Delivery Status" = Rec."Delivery Status"::Cancelled:
                LineStyle := 'Unfavorable';
        end;

        case Rec."Posting Status" of
            Rec."Posting Status"::Queued:
                StatusText := StrSubstNo(PostingQueuedTxt, StatusText);
            Rec."Posting Status"::Error:
                begin
                    StatusText := StrSubstNo(PostingErrorTxt, StatusText);
                    LineStyle := 'Unfavorable';
                end;
        end;
    end;

    local procedure OpenStop()
    begin
        // In Transit the driver may only open the next stop; registered stops open read-only.
        if (Rec."Batch Status" = Rec."Batch Status"::"In Transit") and Rec.IsOpen() then
            DriverMgt.CheckCanRegister(Rec);
        Page.Run(Page::"MSD Delivery Stop Card", Rec);
    end;
}
