namespace EMC.MSD.Delivery;

using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

/// <summary>
/// Creates the Sales Return Order for a Partially delivered stop (DEL-010).
/// Every return line references the Posted Sales Invoice line and is applied to the original
/// item ledger entry, so the return is valued at the original cost.
/// The return order is not posted: the supervisor receives the goods (WMS-102).
/// </summary>
codeunit 50104 "MSD Delivery Return Order"
{
    var
        InvoiceLineNotFoundErr: Label 'Нэхэмжлэл %1 дээр захиалгын %2 мөр олдсонгүй.', Comment = '%1 = posted invoice no., %2 = sales order line no.';

    procedure CreateFromBatchLine(BatchLine: Record "MSD Delivery Batch Line"): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReturnHeader: Record "Sales Header";
        ReturnLine: Record "MSD Delivery Return Line";
        LineNo: Integer;
    begin
        BatchLine.TestField("Posted Invoice No.");
        SalesInvoiceHeader.Get(BatchLine."Posted Invoice No.");

        ReturnHeader.Init();
        ReturnHeader."Document Type" := ReturnHeader."Document Type"::"Return Order";
        ReturnHeader."No." := '';
        ReturnHeader.Insert(true);
        ReturnHeader.SetHideValidationDialog(true);
        ReturnHeader.Validate("Sell-to Customer No.", SalesInvoiceHeader."Sell-to Customer No.");
        if SalesInvoiceHeader."Ship-to Code" <> '' then
            ReturnHeader.Validate("Ship-to Code", SalesInvoiceHeader."Ship-to Code");
        ReturnHeader.Validate("External Document No.", BatchLine."Sales Order No.");
        ReturnHeader."MSD Delivery Batch No." := BatchLine."Batch No.";
        SalesInvoiceHeader.CalcFields("Remaining Amount");
        if (SalesInvoiceHeader."Remaining Amount" <> 0) and (ReturnHeader."Bal. Account No." = '') then begin
            ReturnHeader.Validate("Applies-to Doc. Type", ReturnHeader."Applies-to Doc. Type"::Invoice);
            ReturnHeader.Validate("Applies-to Doc. No.", SalesInvoiceHeader."No.");
        end;
        ReturnHeader.Modify(true);

        ReturnLine.SetRange("Batch No.", BatchLine."Batch No.");
        ReturnLine.SetRange("Batch Line No.", BatchLine."Line No.");
        ReturnLine.SetFilter("Return Quantity", '>0');
        if ReturnLine.FindSet() then
            repeat
                LineNo += 10000;
                CreateReturnLine(ReturnHeader, SalesInvoiceHeader, BatchLine, ReturnLine, LineNo);
            until ReturnLine.Next() = 0;

        exit(ReturnHeader."No.");
    end;

    local procedure CreateReturnLine(ReturnHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; BatchLine: Record "MSD Delivery Batch Line"; DeliveryReturnLine: Record "MSD Delivery Return Line"; LineNo: Integer)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        ItemLedgerEntryNo: Integer;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("Order No.", BatchLine."Sales Order No.");
        SalesInvoiceLine.SetRange("Order Line No.", DeliveryReturnLine."Sales Line No.");
        if not SalesInvoiceLine.FindFirst() then
            Error(InvoiceLineNotFoundErr, SalesInvoiceHeader."No.", DeliveryReturnLine."Sales Line No.");

        SalesLine.Init();
        SalesLine."Document Type" := ReturnHeader."Document Type";
        SalesLine."Document No." := ReturnHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.SetHideValidationDialog(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", SalesInvoiceLine."No.");
        SalesLine.Validate("Variant Code", SalesInvoiceLine."Variant Code");
        SalesLine.Validate("Location Code", SalesInvoiceLine."Location Code");
        SalesLine.Validate("Unit of Measure Code", SalesInvoiceLine."Unit of Measure Code");
        SalesLine.Validate(Quantity, DeliveryReturnLine."Return Quantity");
        SalesLine.Validate("Unit Price", SalesInvoiceLine."Unit Price");
        SalesLine.Validate("Line Discount %", SalesInvoiceLine."Line Discount %");
        // Return reason may redirect to a QC / damaged location (WMS-105).
        SalesLine.Validate("Return Reason Code", DeliveryReturnLine."Return Reason Code");
        ItemLedgerEntryNo := FindItemLedgerEntryNo(SalesInvoiceLine);
        if ItemLedgerEntryNo <> 0 then
            SalesLine.Validate("Appl.-from Item Entry", ItemLedgerEntryNo);
        SalesLine."MSD Ref. Invoice No." := SalesInvoiceLine."Document No.";
        SalesLine."MSD Ref. Invoice Line No." := SalesInvoiceLine."Line No.";
        SalesLine."MSD Delivery Batch No." := BatchLine."Batch No.";
        SalesLine.Insert(true);
    end;

    local procedure FindItemLedgerEntryNo(SalesInvoiceLine: Record "Sales Invoice Line"): Integer
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.SetRange("Document No.", SalesInvoiceLine."Document No.");
        ValueEntry.SetRange("Document Line No.", SalesInvoiceLine."Line No.");
        ValueEntry.SetRange("Item No.", SalesInvoiceLine."No.");
        if ValueEntry.FindFirst() then
            exit(ValueEntry."Item Ledger Entry No.");
    end;
}
