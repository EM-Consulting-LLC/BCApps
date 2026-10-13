namespace EMC.MSD.Delivery;

using Microsoft.Sales.Document;

pageextension 50101 "MSD Sales Order" extends "Sales Order"
{
    layout
    {
        addlast("Shipping and Billing")
        {
            field("MSD Delivery Status"; Rec."MSD Delivery Status")
            {
                ApplicationArea = All;
                ToolTip = 'Түгээлтийн төлөв (Planned, Loaded, In Transit, Fully, Partially, Cancel).';
            }
            field("MSD Delivery Batch No."; Rec."MSD Delivery Batch No.")
            {
                ApplicationArea = All;
                ToolTip = 'Захиалга орсон Delivery Batch.';
            }
        }
    }
}
