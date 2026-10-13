namespace EMC.MSD.Delivery;

using Microsoft.Sales.Document;

/// <summary>
/// Reference from an automatically created Sales Return Order line to the posted invoice line (DEL-010).
/// </summary>
tableextension 50102 "MSD Sales Line" extends "Sales Line"
{
    fields
    {
        field(50100; "MSD Ref. Invoice No."; Code[20])
        {
            Caption = 'Ref. Posted Invoice No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50101; "MSD Ref. Invoice Line No."; Integer)
        {
            Caption = 'Ref. Posted Invoice Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50102; "MSD Delivery Batch No."; Code[20])
        {
            Caption = 'Delivery Batch No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
