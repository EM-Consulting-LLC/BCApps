namespace EMC.MSD.Delivery;

using Microsoft.Sales.Document;

/// <summary>
/// Supervisor side needed to run the driver app prototype end to end.
/// In the full solution the batch is built in the Delivery Planning Worksheet (WMS-042..047) and reaches
/// Ready to Load when the Warehouse Shipment is posted (DEL-001); here "Release to Driver" stands in for that.
/// </summary>
codeunit 50105 "MSD Delivery Batch Mgt."
{
    Permissions = tabledata "Sales Header" = rm;

    var
        NoOrdersMsg: Label 'Released, Shipment Date = %1 нөхцөлтэй batch-д ороогүй захиалга олдсонгүй.', Comment = '%1 = date';
        OrdersAddedMsg: Label '%1 захиалга нэмэгдлээ.', Comment = '%1 = count';
        NoLinesErr: Label 'Batch-д захиалга алга.';
        ReleaseQst: Label '%1 batch-ийг %2 түгээгчид Ready to Load төлөвтэй илгээх үү?', Comment = '%1 = batch no., %2 = driver name';
        StatusChangeTxt: Label '%1 → %2', Comment = '%1 = from status, %2 = to status';

    procedure GetSalesOrders(var Header: Record "MSD Delivery Batch Header")
    var
        SalesHeader: Record "Sales Header";
        Line: Record "MSD Delivery Batch Line";
        Added: Integer;
    begin
        if Header.Status.AsInteger() >= Header.Status::"Ready to Load".AsInteger() then
            Header.FieldError(Status);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.SetRange("Shipment Date", Header."Delivery Date");
        SalesHeader.SetRange("MSD Delivery Batch No.", '');
        if SalesHeader.FindSet() then
            repeat
                Line.Init();
                Line."Batch No." := Header."No.";
                Line."Line No." := 0;
                Line."Sequence No." := 0;
                Line.Validate("Sales Order No.", SalesHeader."No.");
                Line.Insert(true);
                SetSalesOrderPlanned(SalesHeader."No.", Header."No.");
                Added += 1;
            until SalesHeader.Next() = 0;

        if Added = 0 then
            Message(NoOrdersMsg, Header."Delivery Date")
        else
            Message(OrdersAddedMsg, Added);
    end;

    procedure ReleaseToDriver(var Header: Record "MSD Delivery Batch Header")
    var
        Line: Record "MSD Delivery Batch Line";
        DriverMgt: Codeunit "MSD Driver Mgt.";
        OldStatus: Enum "MSD Delivery Batch Status";
    begin
        Header.TestField("Driver No.");
        if Header.Status.AsInteger() >= Header.Status::"Ready to Load".AsInteger() then
            Header.FieldError(Status);
        Line.SetRange("Batch No.", Header."No.");
        if Line.IsEmpty() then
            Error(NoLinesErr);
        if not Confirm(ReleaseQst, true, Header."No.", Header."Driver Name") then
            exit;

        if Line.FindSet() then
            repeat
                SetSalesOrderPlanned(Line."Sales Order No.", Header."No.");
            until Line.Next() = 0;

        OldStatus := Header.Status;
        Header.SetStatus(Header.Status::"Ready to Load");
        DriverMgt.LogBatchEvent(Header, Enum::"MSD Delivery Log Event"::"Status Change", StrSubstNo(StatusChangeTxt, OldStatus, Header.Status));
    end;

    procedure SetReviewed(var Header: Record "MSD Delivery Batch Header")
    begin
        Header.TestField(Status, Header.Status::Completed);
        ChangeStatus(Header, Header.Status::Reviewed);
    end;

    procedure CloseBatch(var Header: Record "MSD Delivery Batch Header")
    var
        Line: Record "MSD Delivery Batch Line";
    begin
        Header.TestField(Status, Header.Status::Reviewed);
        Line.SetRange("Batch No.", Header."No.");
        Line.SetFilter("Posting Status", '%1|%2', Line."Posting Status"::Queued, Line."Posting Status"::Error);
        if Line.FindFirst() then
            Line.FieldError("Posting Status");
        ChangeStatus(Header, Header.Status::Closed);
    end;

    local procedure ChangeStatus(var Header: Record "MSD Delivery Batch Header"; NewStatus: Enum "MSD Delivery Batch Status")
    var
        DriverMgt: Codeunit "MSD Driver Mgt.";
        OldStatus: Enum "MSD Delivery Batch Status";
    begin
        OldStatus := Header.Status;
        Header.SetStatus(NewStatus);
        DriverMgt.LogBatchEvent(Header, Enum::"MSD Delivery Log Event"::"Status Change", StrSubstNo(StatusChangeTxt, OldStatus, NewStatus));
    end;

    local procedure SetSalesOrderPlanned(SalesOrderNo: Code[20]; BatchNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        if not SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo) then
            exit;
        SalesHeader."MSD Delivery Status" := SalesHeader."MSD Delivery Status"::Planned;
        SalesHeader."MSD Delivery Batch No." := BatchNo;
        SalesHeader.Modify();
    end;
}
