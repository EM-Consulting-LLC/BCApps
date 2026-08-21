namespace EMC.Rebate;

using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.History;

codeunit 50101 "Rebate Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; SalesInvHdrNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        RebatePost: Codeunit "Rebate Post";
    begin
        SalesInvHeader.Get(SalesInvHdrNo);
        RebatePost.PostRebateForInvoice(SalesInvHeader);
        Commit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'Quantity', false, false)]
    local procedure OnValidateQuantity(var Rec: Record "Sales Line")
    var
        SalesLine2: Record "Sales Line";
    begin
        SalesLine2.SetRange("Document Type", Rec."Document Type");
        SalesLine2.SetRange("Document No.", Rec."Document No.");
        if SalesLine2.FindSet() then
            repeat
                SalesLine2.Validate("Line Discount %", CalcVolumeDiscount(Rec));
                SalesLine2.Modify(true);
            until SalesLine2.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeUpdatePostingNo', '', false, false)]
    local procedure OnBeforeUpdatePostingNo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        SalesHeader."Posting No." := 'RB-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24><Minutes,2><Seconds,2>');
        IsHandled := true;
    end;

    local procedure CalcVolumeDiscount(SalesLine: Record "Sales Line"): Decimal
    begin
        if SalesLine.Quantity > 100 then
            exit(5);
        exit(0);
    end;
}
