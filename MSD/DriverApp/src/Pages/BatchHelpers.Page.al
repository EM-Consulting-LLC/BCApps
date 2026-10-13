namespace EMC.MSD.Delivery;

/// <summary>
/// Helpers chosen by the driver before START (DEL-003). Editable only while the batch is Loaded.
/// On the phone the page opens in view mode: tap ✎ first, then "+ New" and pick one helper at a time.
/// </summary>
page 50105 "MSD Batch Helpers"
{
    PageType = ListPart;
    Caption = 'Туслах';
    SourceTable = "MSD Delivery Batch Helper";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Worker No."; Rec."Worker No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Туслах ажилтан (Role = Helper).';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Нэр.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Утас.';
                }
            }
        }
    }
}
