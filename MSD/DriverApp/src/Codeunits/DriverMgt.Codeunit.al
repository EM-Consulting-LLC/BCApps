namespace EMC.MSD.Delivery;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Sales.Document;

/// <summary>
/// Business logic behind every driver action of the Mobile Execution Layer (DEL-001..DEL-016).
/// Pages only call into this codeunit so that the rules are the same on phone, tablet and desktop.
/// </summary>
codeunit 50100 "MSD Driver Mgt."
{
    Permissions = tabledata "Sales Header" = rm;

    var
        NotYourBatchErr: Label 'Энэ batch %1 түгээгчид хуваарилагдсан байна.', Comment = '%1 = driver name';
        NoLoadedStopsErr: Label 'Дор хаяж нэг захиалгыг ачсан гэж тэмдэглэнэ үү (LOADED).';
        ConfirmLoadedQst: Label 'Ачсан %1 захиалгыг LOADED бүртгэх үү?\\Ачаагүй %2 захиалга түгээгдэхгүй.\Нийт дүн (ачсан): %3', Comment = '%1 = loaded count, %2 = not loaded count, %3 = amount';
        NoHelperErr: Label 'START хийхийн өмнө хамгийн багадаа нэг туслах нэмнэ үү.';
        TooManyHelpersErr: Label 'Туслах хамгийн ихдээ %1 байна.', Comment = '%1 = max helpers';
        HelperOnlyWhenLoadedErr: Label 'Туслахыг зөвхөн Loaded төлөвтэй batch дээр нэмнэ.';
        OtherInTransitErr: Label 'Таны %1 batch түгээлт хийгдэж байна. Нэг удаад нэг batch түгээнэ.', Comment = '%1 = batch no.';
        DeliveredMissingErr: Label 'Өмнөх %1 batch-д DELIVERED статус бөглөөгүй байна. Бөглөсний дараа START хийнэ.', Comment = '%1 = batch no.';
        StartQst: Label '%1 захиалгыг %2 туслахтай түгээж эхлэх үү?\\Эхэлсний дараа туслах болон дарааллыг өөрчлөх боломжгүй.', Comment = '%1 = stop count, %2 = helper count';
        NotInTransitErr: Label 'Түгээлт эхлээгүй байна. Эхлээд LOADED, дараа нь START дарна уу.';
        AlreadyRegisteredErr: Label 'Энэ цэг бүртгэгдсэн байна. Өөрчлөх боломжгүй.';
        NotLoadedErr: Label 'Энэ захиалга ачигдаагүй (LOADED биш) тул түгээх боломжгүй.';
        NotNextStopErr: Label 'Маршрутын дарааллаар явна уу. Дараагийн цэг: %1 · %2.', Comment = '%1 = sequence no., %2 = customer name';
        FullyQst: Label '%1 (%2)-ийг Fully гэж бүртгэх үү?\\Нэхэмжлэл автоматаар post хийгдэх ба дараа нь өөрчлөх боломжгүй.', Comment = '%1 = sales order no., %2 = customer name';
        CancelQst: Label '%1 (%2)-ийг Cancel гэж бүртгэх үү?\\Шалтгаан: %3. Нэхэмжлэл үүсэхгүй. Дараа нь өөрчлөх боломжгүй.', Comment = '%1 = sales order no., %2 = customer name, %3 = reason';
        PartiallyQst: Label '%1 (%2)-ийг Partially гэж бүртгэх үү?\\Нэхэмжлэл post хийгдэж, %3 тооны буцаалтын захиалга (SRO) автоматаар үүснэ. Дараа нь өөрчлөх боломжгүй.', Comment = '%1 = sales order no., %2 = customer name, %3 = return qty';
        ReasonRequiredErr: Label 'Cancel хийхэд шалтгаан заавал сонгоно.';
        NoReturnQtyErr: Label 'Дор хаяж нэг мөрөнд буцаах тоо оруулна уу.';
        ReturnReasonRequiredErr: Label '%1 барааны буцаах шалтгааныг сонгоно уу.', Comment = '%1 = item description';
        EverythingReturnedErr: Label 'Бүх бараа буцаж байна. Энэ тохиолдолд Cancel ашиглана уу.';
        SkipQst: Label 'Энэ цэгийг түр алгасах уу?\\Жагсаалтын төгсгөлд шилжих ба FINISH-ийн өмнө заавал бүртгэнэ.';
        OpenStopsErr: Label 'Дуусгах боломжгүй. %1 цэг бүртгэгдээгүй байна (Pending эсвэл Skipped).', Comment = '%1 = open stop count';
        FinishQst: Label 'Түгээлтийг дуусгах уу?\\Fully: %1\Partially: %2\Cancel: %3\Posting алдаа: %4', Comment = '%1..%4 = counts';
        DeliveredQst: Label 'Өнөөдрийн бүх захиалгын түгээлт дууссан гэж DELIVERED бүртгэх үү?';
        OnlyBeforeStartErr: Label 'Дарааллыг зөвхөн START хийхээс өмнө өөрчилнө.';
        PaymentOnlyOpenErr: Label 'Төлбөрийн нөхцөлийг зөвхөн бүртгэгдээгүй цэг дээр өөрчилнө.';
        LoadedTxt: Label '%1: LOADED = %2', Comment = '%1 = sales order no., %2 = yes/no';
        StatusChangeTxt: Label '%1 → %2', Comment = '%1 = from status, %2 = to status';
        SequenceTxt: Label '%1: дараалал %2 → %3', Comment = '%1 = sales order no., %2 = old sequence, %3 = new sequence';
        HelperAddedTxt: Label 'Туслах нэмэгдлээ: %1', Comment = '%1 = helper name';
        HelperRemovedTxt: Label 'Туслах хасагдлаа: %1', Comment = '%1 = helper name';
        RegisteredTxt: Label '%1: Delivery Status = %2 · %3 м', Comment = '%1 = sales order no., %2 = status, %3 = distance';
        SkippedTxt: Label '%1: Skipped · дарааллын төгсгөлд шилжлээ', Comment = '%1 = sales order no.';
        PaymentTxt: Label '%1: Төлбөрийн нөхцөл = %2', Comment = '%1 = sales order no., %2 = payment type';
        NotLoadedStopsTxt: Label 'Ачаагүй %1 захиалга түгээгдээгүй. Супервайзер шийднэ.', Comment = '%1 = count';

    #region Identity

    procedure GetCurrentDriverNo(): Code[20]
    var
        Worker: Record "MSD Distribution Worker";
    begin
        Worker.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(Worker."User ID")));
        Worker.SetRange(Role, Worker.Role::Driver);
        Worker.SetRange(Active, true);
        if Worker.FindFirst() then
            exit(Worker."No.");
    end;

    /// <summary>
    /// A driver can only work on his own batch. Users that are not drivers (supervisor, admin) are not restricted.
    /// </summary>
    procedure CheckDriver(Header: Record "MSD Delivery Batch Header")
    var
        DriverNo: Code[20];
    begin
        DriverNo := GetCurrentDriverNo();
        if (DriverNo <> '') and (Header."Driver No." <> DriverNo) then
            Error(NotYourBatchErr, Header."Driver Name");
    end;

    #endregion

    #region Before start: load, sequence, helpers (DEL-001, DEL-003, DEL-004, DEL-014)

    procedure ToggleLoaded(var Line: Record "MSD Delivery Batch Line")
    var
        Header: Record "MSD Delivery Batch Header";
    begin
        Header.Get(Line."Batch No.");
        CheckDriver(Header);
        Header.TestField(Status, Header.Status::"Ready to Load");
        Line.Loaded := not Line.Loaded;
        Line.Modify(true);
        LogEvent(Line, Enum::"MSD Delivery Log Event"::"Stop Loaded", StrSubstNo(LoadedTxt, Line."Sales Order No.", Line.Loaded));
    end;

    procedure ConfirmLoaded(var Header: Record "MSD Delivery Batch Header")
    var
        Line: Record "MSD Delivery Batch Line";
        LoadedCount: Integer;
        LoadedAmount: Decimal;
    begin
        CheckDriver(Header);
        Header.TestField(Status, Header.Status::"Ready to Load");
        Line.SetRange("Batch No.", Header."No.");
        Line.SetRange(Loaded, true);
        LoadedCount := Line.Count();
        if LoadedCount = 0 then
            Error(NoLoadedStopsErr);
        Line.CalcSums("Amount Incl. VAT");
        LoadedAmount := Line."Amount Incl. VAT";
        Header.CalcFields("No. of Stops");
        if not Confirm(ConfirmLoadedQst, true, LoadedCount, Header."No. of Stops" - LoadedCount, Format(LoadedAmount)) then
            exit;

        Header."Loaded At" := CurrentDateTime();
        ChangeBatchStatus(Header, Header.Status::Loaded);
        UpdateSalesOrders(Header."No.", true, Enum::"MSD SO Delivery Status"::Loaded);
    end;

    procedure MoveStop(var Line: Record "MSD Delivery Batch Line"; Direction: Integer)
    var
        Header: Record "MSD Delivery Batch Header";
        Neighbour: Record "MSD Delivery Batch Line";
        OldSequence: Integer;
    begin
        Header.Get(Line."Batch No.");
        CheckDriver(Header);
        if not Header.IsBeforeStart() then
            Error(OnlyBeforeStartErr);

        Neighbour.SetCurrentKey("Batch No.", "Sequence No.");
        Neighbour.SetRange("Batch No.", Line."Batch No.");
        if Direction < 0 then begin
            Neighbour.SetFilter("Sequence No.", '<%1', Line."Sequence No.");
            if not Neighbour.FindLast() then
                exit;
        end else begin
            Neighbour.SetFilter("Sequence No.", '>%1', Line."Sequence No.");
            if not Neighbour.FindFirst() then
                exit;
        end;

        OldSequence := Line."Sequence No.";
        Line."Sequence No." := Neighbour."Sequence No.";
        Line.Modify(true);
        Neighbour."Sequence No." := OldSequence;
        Neighbour.Modify(true);
        LogEvent(Line, Enum::"MSD Delivery Log Event"::"Sequence Change", StrSubstNo(SequenceTxt, Line."Sales Order No.", OldSequence, Line."Sequence No."));
    end;

    procedure CheckCanAddHelper(BatchNo: Code[20])
    var
        Header: Record "MSD Delivery Batch Header";
        DeliverySetup: Record "MSD Delivery Setup";
    begin
        Header.Get(BatchNo);
        CheckDriver(Header);
        if Header.Status <> Header.Status::Loaded then
            Error(HelperOnlyWhenLoadedErr);
        DeliverySetup.GetSetup();
        Header.CalcFields("No. of Helpers");
        if Header."No. of Helpers" >= DeliverySetup."Max. Helpers per Batch" then
            Error(TooManyHelpersErr, DeliverySetup."Max. Helpers per Batch");
    end;

    procedure LogHelperChange(Helper: Record "MSD Delivery Batch Helper"; Added: Boolean)
    var
        Header: Record "MSD Delivery Batch Header";
    begin
        Header.Get(Helper."Batch No.");
        if Added then
            LogBatchEvent(Header, Enum::"MSD Delivery Log Event"::"Helper Added", StrSubstNo(HelperAddedTxt, Helper.Name))
        else
            LogBatchEvent(Header, Enum::"MSD Delivery Log Event"::"Helper Removed", StrSubstNo(HelperRemovedTxt, Helper.Name));
    end;

    #endregion

    #region Start (DEL-002, DEL-003, DEL-013, WMS-091)

    procedure StartDelivery(var Header: Record "MSD Delivery Batch Header")
    var
        OtherBatch: Record "MSD Delivery Batch Header";
        Line: Record "MSD Delivery Batch Line";
        DeliverySetup: Record "MSD Delivery Setup";
    begin
        CheckDriver(Header);
        Header.TestField(Status, Header.Status::Loaded);
        DeliverySetup.GetSetup();

        Header.CalcFields("No. of Helpers", "No. of Loaded Stops");
        if Header."No. of Helpers" = 0 then
            Error(NoHelperErr);
        if Header."No. of Loaded Stops" = 0 then
            Error(NoLoadedStopsErr);

        OtherBatch.SetRange("Driver No.", Header."Driver No.");
        OtherBatch.SetFilter("No.", '<>%1', Header."No.");
        OtherBatch.SetRange(Status, OtherBatch.Status::"In Transit");
        if OtherBatch.FindFirst() then
            Error(OtherInTransitErr, OtherBatch."No.");

        if DeliverySetup."Require Delivered Confirm" then begin
            OtherBatch.SetRange(Status, OtherBatch.Status::Completed);
            OtherBatch.SetRange("Delivered Confirmed", false);
            if OtherBatch.FindFirst() then
                Error(DeliveredMissingErr, OtherBatch."No.");
        end;

        if not Confirm(StartQst, true, Header."No. of Loaded Stops", Header."No. of Helpers") then
            exit;

        // Loaded stops first in the chosen order, not loaded stops at the end.
        Line.SetRange("Batch No.", Header."No.");
        Line.SetRange(Loaded, false);
        if Line.FindSet(true) then
            repeat
                Line."Sequence No." += 100000;
                Line.Modify(true);
            until Line.Next() = 0;
        Renumber(Header."No.");

        Header."Started At" := CurrentDateTime();
        ChangeBatchStatus(Header, Header.Status::"In Transit");
        UpdateSalesOrders(Header."No.", true, Enum::"MSD SO Delivery Status"::"In Transit");
    end;

    local procedure Renumber(BatchNo: Code[20])
    var
        Line: Record "MSD Delivery Batch Line";
        TempLine: Record "MSD Delivery Batch Line" temporary;
        Sequence: Integer;
    begin
        Line.SetCurrentKey("Batch No.", "Sequence No.");
        Line.SetRange("Batch No.", BatchNo);
        if Line.FindSet() then
            repeat
                TempLine := Line;
                TempLine.Insert();
            until Line.Next() = 0;

        TempLine.SetCurrentKey("Batch No.", "Sequence No.");
        if TempLine.FindSet() then
            repeat
                Sequence += 1;
                Line.Get(TempLine."Batch No.", TempLine."Line No.");
                Line."Sequence No." := Sequence;
                Line.Modify(true);
            until TempLine.Next() = 0;
    end;

    #endregion

    #region Stops (DEL-005..DEL-011, DEL-015, DEL-016)

    procedure GetNextStop(BatchNo: Code[20]; var NextLine: Record "MSD Delivery Batch Line"): Boolean
    begin
        NextLine.Reset();
        NextLine.SetCurrentKey("Batch No.", "Sequence No.");
        NextLine.SetRange("Batch No.", BatchNo);
        NextLine.SetRange(Loaded, true);
        NextLine.SetFilter("Delivery Status", '%1|%2', NextLine."Delivery Status"::Pending, NextLine."Delivery Status"::Skipped);
        exit(NextLine.FindFirst());
    end;

    procedure IsNextStop(Line: Record "MSD Delivery Batch Line"): Boolean
    var
        NextLine: Record "MSD Delivery Batch Line";
    begin
        if not GetNextStop(Line."Batch No.", NextLine) then
            exit(false);
        exit(NextLine."Line No." = Line."Line No.");
    end;

    /// <summary>
    /// DEL-007: a stop can only be handled when the batch is In Transit and it is the next stop on the route.
    /// </summary>
    procedure CheckCanRegister(Line: Record "MSD Delivery Batch Line")
    var
        Header: Record "MSD Delivery Batch Header";
        NextLine: Record "MSD Delivery Batch Line";
    begin
        Header.Get(Line."Batch No.");
        CheckDriver(Header);
        if Header.Status <> Header.Status::"In Transit" then
            Error(NotInTransitErr);
        if not Line.IsOpen() then
            Error(AlreadyRegisteredErr);
        if not Line.Loaded then
            Error(NotLoadedErr);
        if GetNextStop(Line."Batch No.", NextLine) then
            if NextLine."Line No." <> Line."Line No." then
                Error(NotNextStopErr, NextLine."Sequence No.", NextLine."Customer Name");
    end;

    procedure RegisterFully(var Line: Record "MSD Delivery Batch Line")
    var
        GeofenceMgt: Codeunit "MSD Geofence Mgt.";
        Latitude: Decimal;
        Longitude: Decimal;
        DistanceM: Decimal;
    begin
        CheckCanRegister(Line);
        if not Confirm(FullyQst, false, Line."Sales Order No.", Line."Customer Name") then
            exit;
        GeofenceMgt.CaptureAndCheck(Line, Latitude, Longitude, DistanceM);

        Line."Delivery Status" := Line."Delivery Status"::Fully;
        CompleteRegistration(Line, Latitude, Longitude, DistanceM);
        SetSalesOrderStatus(Line, Enum::"MSD SO Delivery Status"::Fully);
        QueuePosting(Line);
    end;

    procedure RegisterCancel(var Line: Record "MSD Delivery Batch Line")
    var
        ReturnReason: Record "Return Reason";
        GeofenceMgt: Codeunit "MSD Geofence Mgt.";
        Latitude: Decimal;
        Longitude: Decimal;
        DistanceM: Decimal;
    begin
        CheckCanRegister(Line);
        if Page.RunModal(Page::"Return Reasons", ReturnReason) <> Action::LookupOK then
            exit;
        if ReturnReason.Code = '' then
            Error(ReasonRequiredErr);
        if not Confirm(CancelQst, false, Line."Sales Order No.", Line."Customer Name", ReturnReason.Description) then
            exit;
        GeofenceMgt.CaptureAndCheck(Line, Latitude, Longitude, DistanceM);

        Line."Delivery Status" := Line."Delivery Status"::Cancelled;
        Line."Reason Code" := ReturnReason.Code;
        CompleteRegistration(Line, Latitude, Longitude, DistanceM);
        SetSalesOrderStatus(Line, Enum::"MSD SO Delivery Status"::Cancelled);
        // No invoice (DEL-011). The supervisor undoes the posted shipment (WMS-101) outside the app.
    end;

    /// <summary>
    /// Prepares the return lines from the Sales Order and opens the Partially page (DEL-009).
    /// </summary>
    procedure OpenPartialDelivery(var Line: Record "MSD Delivery Batch Line")
    begin
        CheckCanRegister(Line);
        InitReturnLines(Line);
        Commit();
        Page.Run(Page::"MSD Partial Delivery", Line);
    end;

    procedure InitReturnLines(Line: Record "MSD Delivery Batch Line")
    var
        ReturnLine: Record "MSD Delivery Return Line";
        SalesLine: Record "Sales Line";
        DeliveredQty: Decimal;
    begin
        ReturnLine.SetRange("Batch No.", Line."Batch No.");
        ReturnLine.SetRange("Batch Line No.", Line."Line No.");
        if not ReturnLine.IsEmpty() then
            exit;

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", Line."Sales Order No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                // Shipped by the warehouse and not invoiced yet = what is on the truck for this customer.
                DeliveredQty := SalesLine."Qty. Shipped Not Invoiced";
                if DeliveredQty = 0 then
                    DeliveredQty := SalesLine."Qty. to Ship";
                if DeliveredQty <> 0 then begin
                    ReturnLine.Init();
                    ReturnLine."Batch No." := Line."Batch No.";
                    ReturnLine."Batch Line No." := Line."Line No.";
                    ReturnLine."Sales Line No." := SalesLine."Line No.";
                    ReturnLine."Item No." := SalesLine."No.";
                    ReturnLine.Description := SalesLine.Description;
                    ReturnLine."Unit of Measure Code" := SalesLine."Unit of Measure Code";
                    ReturnLine."Delivered Quantity" := DeliveredQty;
                    ReturnLine."Handed Over Quantity" := DeliveredQty;
                    ReturnLine.Insert();
                end;
            until SalesLine.Next() = 0;
    end;

    procedure RegisterPartially(var Line: Record "MSD Delivery Batch Line")
    var
        ReturnLine: Record "MSD Delivery Return Line";
        GeofenceMgt: Codeunit "MSD Geofence Mgt.";
        Latitude: Decimal;
        Longitude: Decimal;
        DistanceM: Decimal;
        TotalReturnQty: Decimal;
        AllReturned: Boolean;
    begin
        CheckCanRegister(Line);

        AllReturned := true;
        ReturnLine.SetRange("Batch No.", Line."Batch No.");
        ReturnLine.SetRange("Batch Line No.", Line."Line No.");
        if ReturnLine.FindSet() then
            repeat
                if ReturnLine."Return Quantity" > 0 then begin
                    if ReturnLine."Return Reason Code" = '' then
                        Error(ReturnReasonRequiredErr, ReturnLine.Description);
                    TotalReturnQty += ReturnLine."Return Quantity";
                end;
                if ReturnLine."Return Quantity" <> ReturnLine."Delivered Quantity" then
                    AllReturned := false;
            until ReturnLine.Next() = 0;
        if TotalReturnQty = 0 then
            Error(NoReturnQtyErr);
        if AllReturned then
            Error(EverythingReturnedErr);

        if not Confirm(PartiallyQst, false, Line."Sales Order No.", Line."Customer Name", TotalReturnQty) then
            exit;
        GeofenceMgt.CaptureAndCheck(Line, Latitude, Longitude, DistanceM);

        Line."Delivery Status" := Line."Delivery Status"::Partially;
        CompleteRegistration(Line, Latitude, Longitude, DistanceM);
        SetSalesOrderStatus(Line, Enum::"MSD SO Delivery Status"::Partially);
        QueuePosting(Line);
    end;

    procedure SkipStop(var Line: Record "MSD Delivery Batch Line")
    var
        LastLine: Record "MSD Delivery Batch Line";
    begin
        CheckCanRegister(Line);
        if not Confirm(SkipQst, true) then
            exit;
        LastLine.SetCurrentKey("Batch No.", "Sequence No.");
        LastLine.SetRange("Batch No.", Line."Batch No.");
        LastLine.SetRange(Loaded, true);
        LastLine.FindLast();
        Line."Sequence No." := LastLine."Sequence No." + 1;
        Line."Delivery Status" := Line."Delivery Status"::Skipped;
        Line.Modify(true);
        LogEvent(Line, Enum::"MSD Delivery Log Event"::"Stop Skipped", StrSubstNo(SkippedTxt, Line."Sales Order No."));
    end;

    procedure ValidatePaymentType(var Line: Record "MSD Delivery Batch Line")
    begin
        if not Line.IsOpen() then
            Error(PaymentOnlyOpenErr);
        LogEvent(Line, Enum::"MSD Delivery Log Event"::"Payment Type Change", StrSubstNo(PaymentTxt, Line."Sales Order No.", Line."Payment Type"));
    end;

    local procedure CompleteRegistration(var Line: Record "MSD Delivery Batch Line"; Latitude: Decimal; Longitude: Decimal; DistanceM: Decimal)
    begin
        Line."Registered At" := CurrentDateTime();
        Line."Registered By" := CopyStr(UserId(), 1, MaxStrLen(Line."Registered By"));
        Line.Latitude := Latitude;
        Line.Longitude := Longitude;
        Line."Distance (m)" := DistanceM;
        Line.Modify(true);
        LogEventWithPosition(Line, Enum::"MSD Delivery Log Event"::"Stop Registered",
            StrSubstNo(RegisteredTxt, Line."Sales Order No.", Line."Delivery Status", DistanceM), Latitude, Longitude);
    end;

    local procedure QueuePosting(var Line: Record "MSD Delivery Batch Line")
    var
        DeliverySetup: Record "MSD Delivery Setup";
        DeliveryPosting: Codeunit "MSD Delivery Posting";
    begin
        Line."Posting Status" := Line."Posting Status"::Queued;
        Line.Modify(true);
        DeliverySetup.GetSetup();
        if DeliverySetup."Post via Job Queue" then
            exit;
        // Demo mode: post right away in the driver's session (requires posting permissions for the driver).
        Commit();
        DeliveryPosting.PostLine(Line);
    end;

    #endregion

    #region Finish (DEL-012, DEL-013)

    procedure FinishDelivery(var Header: Record "MSD Delivery Batch Header")
    var
        Line: Record "MSD Delivery Batch Line";
    begin
        CheckDriver(Header);
        Header.TestField(Status, Header.Status::"In Transit");
        Header.CalcFields("No. of Open Stops", "No. of Posting Errors");
        if Header."No. of Open Stops" > 0 then
            Error(OpenStopsErr, Header."No. of Open Stops");

        if not Confirm(FinishQst, true,
            CountStops(Header."No.", Line."Delivery Status"::Fully),
            CountStops(Header."No.", Line."Delivery Status"::Partially),
            CountStops(Header."No.", Line."Delivery Status"::Cancelled),
            Header."No. of Posting Errors")
        then
            exit;

        Header."Finished At" := CurrentDateTime();
        ChangeBatchStatus(Header, Header.Status::Completed);

        Line.SetRange("Batch No.", Header."No.");
        Line.SetRange(Loaded, false);
        if not Line.IsEmpty() then
            LogBatchEvent(Header, Enum::"MSD Delivery Log Event"::"Status Change", StrSubstNo(NotLoadedStopsTxt, Line.Count()));
    end;

    procedure ConfirmDelivered(var Header: Record "MSD Delivery Batch Header")
    begin
        CheckDriver(Header);
        Header.TestField(Status, Header.Status::Completed);
        Header.TestField("Delivered Confirmed", false);
        if not Confirm(DeliveredQst, true) then
            exit;
        Header."Delivered Confirmed" := true;
        Header."Delivered Confirmed At" := CurrentDateTime();
        Header.Modify(true);
        LogBatchEvent(Header, Enum::"MSD Delivery Log Event"::"Delivered Confirmed", Header."No.");
    end;

    local procedure CountStops(BatchNo: Code[20]; DeliveryStatus: Enum "MSD Stop Delivery Status"): Integer
    var
        Line: Record "MSD Delivery Batch Line";
    begin
        Line.SetRange("Batch No.", BatchNo);
        Line.SetRange("Delivery Status", DeliveryStatus);
        exit(Line.Count());
    end;

    #endregion

    #region Helpers

    local procedure ChangeBatchStatus(var Header: Record "MSD Delivery Batch Header"; NewStatus: Enum "MSD Delivery Batch Status")
    var
        OldStatus: Enum "MSD Delivery Batch Status";
    begin
        OldStatus := Header.Status;
        Header.SetStatus(NewStatus);
        LogBatchEvent(Header, Enum::"MSD Delivery Log Event"::"Status Change", StrSubstNo(StatusChangeTxt, OldStatus, NewStatus));
    end;

    local procedure UpdateSalesOrders(BatchNo: Code[20]; LoadedOnly: Boolean; NewStatus: Enum "MSD SO Delivery Status")
    var
        Line: Record "MSD Delivery Batch Line";
    begin
        Line.SetRange("Batch No.", BatchNo);
        if LoadedOnly then
            Line.SetRange(Loaded, true);
        if Line.FindSet() then
            repeat
                SetSalesOrderStatus(Line, NewStatus);
            until Line.Next() = 0;
    end;

    local procedure SetSalesOrderStatus(Line: Record "MSD Delivery Batch Line"; NewStatus: Enum "MSD SO Delivery Status")
    var
        SalesHeader: Record "Sales Header";
    begin
        if not SalesHeader.Get(SalesHeader."Document Type"::Order, Line."Sales Order No.") then
            exit;
        SalesHeader."MSD Delivery Status" := NewStatus;
        SalesHeader."MSD Delivery Batch No." := Line."Batch No.";
        SalesHeader.Modify();
    end;

    procedure LogEvent(Line: Record "MSD Delivery Batch Line"; EventType: Enum "MSD Delivery Log Event"; Description: Text)
    begin
        LogEventWithPosition(Line, EventType, Description, 0, 0);
    end;

    procedure LogEventWithPosition(Line: Record "MSD Delivery Batch Line"; EventType: Enum "MSD Delivery Log Event"; Description: Text; Latitude: Decimal; Longitude: Decimal)
    var
        LogEntry: Record "MSD Delivery Log Entry";
    begin
        LogEntry.Init();
        LogEntry."Batch No." := Line."Batch No.";
        LogEntry."Batch Line No." := Line."Line No.";
        LogEntry."Sales Order No." := Line."Sales Order No.";
        InsertLogEntry(LogEntry, EventType, Description, Latitude, Longitude);
    end;

    procedure LogBatchEvent(Header: Record "MSD Delivery Batch Header"; EventType: Enum "MSD Delivery Log Event"; Description: Text)
    var
        LogEntry: Record "MSD Delivery Log Entry";
    begin
        LogEntry.Init();
        LogEntry."Batch No." := Header."No.";
        InsertLogEntry(LogEntry, EventType, Description, 0, 0);
    end;

    local procedure InsertLogEntry(var LogEntry: Record "MSD Delivery Log Entry"; EventType: Enum "MSD Delivery Log Event"; Description: Text; Latitude: Decimal; Longitude: Decimal)
    begin
        LogEntry."Entry No." := 0;
        LogEntry."Event" := EventType;
        LogEntry.Description := CopyStr(Description, 1, MaxStrLen(LogEntry.Description));
        LogEntry."Created At" := CurrentDateTime();
        LogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(LogEntry."User ID"));
        LogEntry.Latitude := Latitude;
        LogEntry.Longitude := Longitude;
        LogEntry.Insert(true);
    end;

    #endregion
}
