namespace EMC.MSD.Delivery;

page 50113 "MSD Supervisor Batches"
{
    PageType = List;
    Caption = 'Delivery Batches';
    SourceTable = "MSD Delivery Batch Header";
    CardPageId = "MSD Supervisor Batch";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

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
                field("Delivery Date"; Rec."Delivery Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Түгээлтийн огноо.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Төлөв.';
                }
                field("Driver Name"; Rec."Driver Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Түгээгч.';
                }
                field("Vehicle No."; Rec."Vehicle No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Машин.';
                }
                field("No. of Stops"; Rec."No. of Stops")
                {
                    ApplicationArea = All;
                    ToolTip = 'Захиалгын тоо.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Нийт дүн.';
                }
                field("No. of Posting Errors"; Rec."No. of Posting Errors")
                {
                    ApplicationArea = All;
                    ToolTip = 'Posting алдаатай цэг.';
                }
                field("Delivered Confirmed"; Rec."Delivered Confirmed")
                {
                    ApplicationArea = All;
                    ToolTip = 'DELIVERED бүртгэсэн эсэх.';
                }
            }
        }
    }
}
