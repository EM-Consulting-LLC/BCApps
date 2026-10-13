namespace EMC.MSD.Delivery;

using System.Threading;

/// <summary>
/// Job Queue handler that posts all queued stops (DEL-008).
/// Schedule it under a service user that holds posting permissions, so drivers never need them (WMS-089).
/// A failing stop is marked Error with the message and does not stop the other stops.
/// </summary>
codeunit 50103 "MSD Delivery Posting"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        ProcessQueue();
    end;

    var
        PostingErrorTxt: Label '%1: %2', Comment = '%1 = sales order no., %2 = error message';

    procedure ProcessQueue()
    var
        Line: Record "MSD Delivery Batch Line";
        TempLine: Record "MSD Delivery Batch Line" temporary;
    begin
        Line.SetRange("Posting Status", Line."Posting Status"::Queued);
        if Line.FindSet() then
            repeat
                TempLine := Line;
                TempLine.Insert();
            until Line.Next() = 0;

        if TempLine.FindSet() then
            repeat
                if Line.Get(TempLine."Batch No.", TempLine."Line No.") then
                    PostLine(Line);
            until TempLine.Next() = 0;
    end;

    procedure PostLine(var Line: Record "MSD Delivery Batch Line")
    var
        DriverMgt: Codeunit "MSD Driver Mgt.";
        ErrorText: Text;
    begin
        Commit();
        ClearLastError();
        if Codeunit.Run(Codeunit::"MSD Delivery Invoice Post", Line) then
            exit;

        ErrorText := GetLastErrorText();
        Line.Get(Line."Batch No.", Line."Line No.");
        Line."Posting Status" := Line."Posting Status"::Error;
        Line."Posting Error" := CopyStr(ErrorText, 1, MaxStrLen(Line."Posting Error"));
        Line.Modify(true);
        DriverMgt.LogEvent(Line, Enum::"MSD Delivery Log Event"::"Posting Error", StrSubstNo(PostingErrorTxt, Line."Sales Order No.", ErrorText));
        Commit();
    end;

    /// <summary>
    /// Supervisor: re-post a stop after the cause of the error was fixed (e.g. missing dimension).
    /// </summary>
    procedure RetryPosting(var Line: Record "MSD Delivery Batch Line")
    begin
        Line.TestField("Posting Status", Line."Posting Status"::Error);
        Line."Posting Status" := Line."Posting Status"::Queued;
        Line.Modify(true);
        PostLine(Line);
    end;

    procedure ScheduleJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        EmptyRecordId: RecordId;
    begin
        JobQueueEntry.ScheduleRecurrentJobQueueEntryWithFrequency(
            JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"MSD Delivery Posting", EmptyRecordId, 1);
    end;
}
