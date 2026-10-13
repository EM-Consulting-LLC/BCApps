namespace EMC.MSD.Delivery;

using Microsoft.Sales.Document;

/// <summary>
/// Read-only Sales Order lines of a stop. After the invoice is posted the order is gone and the part is empty.
/// </summary>
page 50107 "MSD Stop Order Lines"
{
    PageType = ListPart;
    Caption = 'Мөрүүд';
    SourceTable = "Sales Line";
    SourceTableView = where("Document Type" = const(Order), Type = const(Item));
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Барааны нэр.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Барааны код.';
                }
                field("Quantity Shipped"; Rec."Quantity Shipped")
                {
                    ApplicationArea = All;
                    Caption = 'Ачсан тоо';
                    ToolTip = 'Агуулахаас гаргасан тоо.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Хэмжих нэгж.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Дүн (НӨАТ-тай).';
                }
            }
        }
    }
}
