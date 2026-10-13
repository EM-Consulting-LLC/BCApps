namespace EMC.MSD.Delivery;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;

/// <summary>
/// Returned items registered by the driver for a Partially delivered stop (DEL-009).
/// Initialized from the Sales Order lines; drives the automatic Sales Return Order (DEL-010).
/// </summary>
table 50105 "MSD Delivery Return Line"
{
    Caption = 'Delivery Return Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
        }
        field(2; "Batch Line No."; Integer)
        {
            Caption = 'Batch Line No.';
        }
        field(3; "Sales Line No."; Integer)
        {
            Caption = 'Sales Line No.';
            Editable = false;
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Бараа';
            TableRelation = Item;
            Editable = false;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Барааны нэр';
            Editable = false;
        }
        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Хэмжих нэгж';
            Editable = false;
        }
        field(7; "Delivered Quantity"; Decimal)
        {
            Caption = 'Ачсан тоо';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(8; "Return Quantity"; Decimal)
        {
            Caption = 'Буцаах тоо';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Return Quantity" > "Delivered Quantity" then
                    Error(ReturnQtyTooHighErr, "Delivered Quantity");
                if "Return Quantity" = 0 then
                    "Return Reason Code" := '';
                "Handed Over Quantity" := "Delivered Quantity" - "Return Quantity";
            end;
        }
        field(9; "Return Reason Code"; Code[10])
        {
            Caption = 'Шалтгаан';
            TableRelation = "Return Reason";
        }
        field(10; "Handed Over Quantity"; Decimal)
        {
            Caption = 'Хүлээлгэсэн тоо';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Batch No.", "Batch Line No.", "Sales Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; Description, "Item No.", "Delivered Quantity", "Return Quantity", "Return Reason Code") { }
    }

    var
        ReturnQtyTooHighErr: Label 'Буцаах тоо ачсан тооноос (%1) их байж болохгүй.', Comment = '%1 = delivered quantity';
}
