namespace EMC.MSD.Delivery;

page 50114 "MSD Supervisor Batch"
{
    PageType = Document;
    Caption = 'Delivery Batch (Supervisor)';
    SourceTable = "MSD Delivery Batch Header";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Delivery Batch-ийн дугаар.';
                }
                field("Delivery Date"; Rec."Delivery Date")
                {
                    ApplicationArea = All;
                    Editable = IsPlanning;
                    ToolTip = 'Түгээлтийн огноо.';
                }
                field("Route Description"; Rec."Route Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Маршрут.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Төлөв.';
                }
                field("Driver No."; Rec."Driver No.")
                {
                    ApplicationArea = All;
                    Editable = IsPlanning;
                    ToolTip = 'Түгээгч (WMS-046).';
                }
                field("Driver Name"; Rec."Driver Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Түгээгчийн нэр.';
                }
                field("Driver Phone No."; Rec."Driver Phone No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Түгээгчийн утас.';
                }
                field("Vehicle No."; Rec."Vehicle No.")
                {
                    ApplicationArea = All;
                    Editable = IsPlanning;
                    ToolTip = 'Машин.';
                }
                field("Picker No."; Rec."Picker No.")
                {
                    ApplicationArea = All;
                    Editable = IsPlanning;
                    ToolTip = 'Цуглуулагч.';
                }
                field("Packer No."; Rec."Packer No.")
                {
                    ApplicationArea = All;
                    Editable = IsPlanning;
                    ToolTip = 'Савлагч.';
                }
            }
            group(Execution)
            {
                Caption = 'Execution';
                Editable = false;

                field("Loaded At"; Rec."Loaded At")
                {
                    ApplicationArea = All;
                    ToolTip = 'LOADED бүртгэсэн цаг.';
                }
                field("Started At"; Rec."Started At")
                {
                    ApplicationArea = All;
                    ToolTip = 'START дарсан цаг.';
                }
                field("Finished At"; Rec."Finished At")
                {
                    ApplicationArea = All;
                    ToolTip = 'FINISH дарсан цаг.';
                }
                field("Delivered Confirmed"; Rec."Delivered Confirmed")
                {
                    ApplicationArea = All;
                    ToolTip = 'DELIVERED бүртгэсэн эсэх.';
                }
                field("No. of Helpers"; Rec."No. of Helpers")
                {
                    ApplicationArea = All;
                    ToolTip = 'Туслахын тоо.';
                }
                field("No. of Posting Errors"; Rec."No. of Posting Errors")
                {
                    ApplicationArea = All;
                    ToolTip = 'Posting алдаатай цэг.';
                }
            }
            part(Lines; "MSD Supervisor Batch Lines")
            {
                ApplicationArea = All;
                Caption = 'Захиалгууд';
                SubPageLink = "Batch No." = field("No.");
                UpdatePropagation = Both;
            }
            part(Helpers; "MSD Batch Helpers")
            {
                ApplicationArea = All;
                Caption = 'Туслах';
                Editable = false;
                SubPageLink = "Batch No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetSalesOrders)
            {
                ApplicationArea = All;
                Caption = 'Get Sales Orders';
                Image = SelectEntries;
                Enabled = IsPlanning;
                ToolTip = 'Released, Shipment Date = Delivery Date захиалгуудыг batch-д нэмнэ (WMS-042 хялбаршуулсан).';

                trigger OnAction()
                begin
                    BatchMgt.GetSalesOrders(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ReleaseToDriver)
            {
                ApplicationArea = All;
                Caption = 'Release to Driver';
                Image = ReleaseDoc;
                Enabled = IsPlanning;
                ToolTip = 'Ready to Load төлөвт шилжүүлж жолоочийн апп дээр харагдуулна. Бодит урсгалд Warehouse Shipment post хийгдэхэд автоматаар болно (DEL-001).';

                trigger OnAction()
                begin
                    BatchMgt.ReleaseToDriver(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Reviewed)
            {
                ApplicationArea = All;
                Caption = 'Reviewed';
                Image = Approve;
                Enabled = Rec.Status = Rec.Status::Completed;
                ToolTip = 'Түгээлтийн үр дүнг хянаж дууссан.';

                trigger OnAction()
                begin
                    BatchMgt.SetReviewed(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CloseBatch)
            {
                ApplicationArea = All;
                Caption = 'Close';
                Image = Close;
                Enabled = Rec.Status = Rec.Status::Reviewed;
                ToolTip = 'Batch-ийг хаана (WMS-103).';

                trigger OnAction()
                begin
                    BatchMgt.CloseBatch(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Log)
            {
                ApplicationArea = All;
                Caption = 'Log';
                Image = Log;
                RunObject = page "MSD Delivery Log Entries";
                RunPageLink = "Batch No." = field("No.");
                ToolTip = 'Batch-ийн үйлдлийн түүх.';
            }
            action(DriverView)
            {
                ApplicationArea = All;
                Caption = 'Driver View';
                Image = Navigate;
                ToolTip = 'Жолоочийн апп дээрх харагдацыг нээнэ.';

                trigger OnAction()
                begin
                    Page.Run(Page::"MSD Delivery Batch Card", Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(GetSalesOrders_Promoted; GetSalesOrders) { }
            actionref(ReleaseToDriver_Promoted; ReleaseToDriver) { }
            actionref(Reviewed_Promoted; Reviewed) { }
            actionref(CloseBatch_Promoted; CloseBatch) { }
        }
    }

    var
        BatchMgt: Codeunit "MSD Delivery Batch Mgt.";
        IsPlanning: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        IsPlanning := Rec.Status.AsInteger() < Rec.Status::"Ready to Load".AsInteger();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsPlanning := true;
    end;
}
