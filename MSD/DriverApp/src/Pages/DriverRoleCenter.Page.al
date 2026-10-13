namespace EMC.MSD.Delivery;

/// <summary>
/// Driver Role Center for the Business Central mobile app (phone).
/// Cues count batches and stops by status; the ≡ menu on the phone shows the area(Embedding) links.
/// </summary>
page 50100 "MSD Driver Role Center"
{
    PageType = RoleCenter;
    Caption = 'Түгээгч';
    ApplicationArea = All;

    layout
    {
        area(RoleCenter)
        {
            part(Activities; "MSD Driver Activities")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Embedding)
        {
            action(MyBatches)
            {
                ApplicationArea = All;
                Caption = 'Миний Delivery Batch';
                RunObject = page "MSD Delivery Batch List";
                ToolTip = 'Танд хуваарилагдсан Delivery Batch-ууд.';
            }
            action(DeliveryLog)
            {
                ApplicationArea = All;
                Caption = 'Түгээлтийн лог';
                RunObject = page "MSD Delivery Log Entries";
                ToolTip = 'Түгээлтийн үйлдлүүдийн түүх.';
            }
        }
    }
}
