namespace EMC.MSD.Delivery;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;

/// <summary>
/// Posts the invoice of one Fully / Partially delivered stop (DEL-008) and, for Partially,
/// creates the Sales Return Order that references the posted invoice lines (DEL-010).
/// The warehouse shipment is already posted (WMS-086), so only Invoice is posted here.
/// Run it with Codeunit.Run so that a posting error is caught and written back to the stop.
/// </summary>
codeunit 50102 "MSD Delivery Invoice Post"
{
    TableNo = "MSD Delivery Batch Line";

    trigger OnRun()
    var
        DeliveryReturnOrder: Codeunit "MSD Delivery Return Order";
        DriverMgt: Codeunit "MSD Driver Mgt.";
    begin
        if not (Rec."Delivery Status" in [Rec."Delivery Status"::Fully, Rec."Delivery Status"::Partially]) then
            exit;
        if Rec."Posting Status" = Rec."Posting Status"::Posted then
            exit;

        if Rec."Posted Invoice No." = '' then begin
            Rec."Posted Invoice No." := PostInvoice(Rec);
            Rec.Modify(true);
            DriverMgt.LogEvent(Rec, Enum::"MSD Delivery Log Event"::"Invoice Posted", StrSubstNo(InvoicePostedTxt, Rec."Posted Invoice No.", Rec."Sales Order No."));
            // Sales-Post has already committed the invoice; keep its number even if the return order fails below.
            Commit();
        end;

        if (Rec."Delivery Status" = Rec."Delivery Status"::Partially) and (Rec."Return Order No." = '') then begin
            Rec."Return Order No." := DeliveryReturnOrder.CreateFromBatchLine(Rec);
            Rec.Modify(true);
            DriverMgt.LogEvent(Rec, Enum::"MSD Delivery Log Event"::"Return Order Created", StrSubstNo(ReturnCreatedTxt, Rec."Return Order No.", Rec."Posted Invoice No."));
        end;

        Rec."Posting Status" := Rec."Posting Status"::Posted;
        Rec."Posting Error" := '';
        Rec.Modify(true);
    end;

    var
        NothingToInvoiceErr: Label 'Захиалга %1 дээр нэхэмжлэх (shipped, not invoiced) тоо алга. Warehouse Shipment post хийгдсэн эсэхийг шалгана уу.', Comment = '%1 = sales order no.';
        InvoicePostedTxt: Label '%1 post хийгдлээ (%2)', Comment = '%1 = posted invoice no., %2 = sales order no.';
        ReturnCreatedTxt: Label '%1 үүслээ · %2 нэхэмжлэлийн мөрүүдэд reference хийв', Comment = '%1 = return order no., %2 = posted invoice no.';

    local procedure PostInvoice(BatchLine: Record "MSD Delivery Batch Line"): Code[20]
    var
        DeliverySetup: Record "MSD Delivery Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentMethodCode: Code[10];
        DeliveryDate: Date;
        HasQtyToInvoice: Boolean;
    begin
        DeliverySetup.GetSetup();
        SalesHeader.Get(SalesHeader."Document Type"::Order, BatchLine."Sales Order No.");
        SalesHeader.SetHideValidationDialog(true);

        DeliveryDate := DT2Date(BatchLine."Registered At");
        if (DeliveryDate <> 0D) and (SalesHeader."Posting Date" <> DeliveryDate) then
            SalesHeader.Validate("Posting Date", DeliveryDate);

        PaymentMethodCode := DeliverySetup.GetPaymentMethodCode(BatchLine."Payment Type");
        if PaymentMethodCode <> '' then
            SalesHeader.Validate("Payment Method Code", PaymentMethodCode);

        SalesHeader.Ship := false;
        SalesHeader.Invoice := true;
        SalesHeader.Modify(true);

        // Invoice exactly what the warehouse shipped. Returns of a Partially stop are handled by the return order.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        if SalesLine.FindSet(true) then
            repeat
                if SalesLine."Qty. to Invoice" <> SalesLine."Qty. Shipped Not Invoiced" then begin
                    SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. Shipped Not Invoiced");
                    SalesLine.Modify(true);
                end;
                if SalesLine."Qty. Shipped Not Invoiced" <> 0 then
                    HasQtyToInvoice := true;
            until SalesLine.Next() = 0;
        if not HasQtyToInvoice then
            Error(NothingToInvoiceErr, SalesHeader."No.");

        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);

        if SalesHeader."Last Posting No." <> '' then
            exit(SalesHeader."Last Posting No.");
        SalesInvoiceHeader.SetRange("Order No.", BatchLine."Sales Order No.");
        SalesInvoiceHeader.FindLast();
        exit(SalesInvoiceHeader."No.");
    end;
}
