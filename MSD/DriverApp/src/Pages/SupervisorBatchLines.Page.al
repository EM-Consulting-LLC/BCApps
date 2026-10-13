namespace EMC.MSD.Delivery;

using Microsoft.Sales.Document;

page 50115 "MSD Supervisor Batch Lines"
{
    PageType = ListPart;
    Caption = 'Захиалгууд';
    SourceTable = "MSD Delivery Batch Line";
    SourceTableView = sorting("Batch No.", "Sequence No.");
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Sequence No."; Rec."Sequence No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Түгээх дараалал.';
                }
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
                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    ToolTip = 'Хаяг.';
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Нийт тоо.';
                }
                field("Amount Incl. VAT"; Rec."Amount Incl. VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Дүн.';
                }
                field(Loaded; Rec.Loaded)
                {
                    ApplicationArea = All;
                    ToolTip = 'LOADED.';
                }
                field("Delivery Status"; Rec."Delivery Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Хүргэлтийн төлөв.';
                }
                field("Payment Type"; Rec."Payment Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Төлбөрийн нөхцөл.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cancel шалтгаан.';
                }
                field("Registered At"; Rec."Registered At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Бүртгэсэн цаг.';
                }
                field("Distance (m)"; Rec."Distance (m)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Харилцагчаас зай.';
                }
                field("Posting Status"; Rec."Posting Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Posting-ийн төлөв.';
                }
                field("Posting Error"; Rec."Posting Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Алдааны мэдээлэл.';
                }
                field("Posted Invoice No."; Rec."Posted Invoice No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Нэхэмжлэл.';
                }
                field("Return Order No."; Rec."Return Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Буцаалтын захиалга.';

                    trigger OnDrillDown()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        if SalesHeader.Get(SalesHeader."Document Type"::"Return Order", Rec."Return Order No.") then
                            Page.Run(Page::"Sales Return Order", SalesHeader);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetryPosting)
            {
                ApplicationArea = All;
                Caption = 'Retry Posting';
                Image = Post;
                Scope = Repeater;
                ToolTip = 'Алдааны шалтгааныг зассаны дараа нэхэмжлэлийг дахин post хийнэ.';

                trigger OnAction()
                var
                    DeliveryPosting: Codeunit "MSD Delivery Posting";
                begin
                    DeliveryPosting.RetryPosting(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
