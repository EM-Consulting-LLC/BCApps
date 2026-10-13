namespace EMC.MSD.Delivery;

using Microsoft.Sales.Document;

tableextension 50101 "MSD Sales Header" extends "Sales Header"
{
    fields
    {
        field(50100; "MSD Delivery Status"; Enum "MSD SO Delivery Status")
        {
            Caption = 'Delivery Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50101; "MSD Delivery Batch No."; Code[20])
        {
            Caption = 'Delivery Batch No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "MSD Delivery Batch Header";
        }
    }
}
