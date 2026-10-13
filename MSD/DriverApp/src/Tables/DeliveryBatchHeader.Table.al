namespace EMC.MSD.Delivery;

using Microsoft.Foundation.NoSeries;

/// <summary>
/// Delivery Batch (WMS-052..054). Only the fields needed by the Mobile Execution Layer are modelled here.
/// </summary>
table 50102 "MSD Delivery Batch Header"
{
    Caption = 'Delivery Batch';
    DataClassification = CustomerContent;
    LookupPageId = "MSD Delivery Batch List";
    DrillDownPageId = "MSD Delivery Batch List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Delivery Date"; Date)
        {
            Caption = 'Огноо';
        }
        field(3; Status; Enum "MSD Delivery Batch Status")
        {
            Caption = 'Төлөв';
            Editable = false;
        }
        field(4; "Route Description"; Text[100])
        {
            Caption = 'Маршрут';
        }
        field(10; "Driver No."; Code[20])
        {
            Caption = 'Түгээгч';
            TableRelation = "MSD Distribution Worker" where(Role = const(Driver), Active = const(true));

            trigger OnValidate()
            var
                Worker: Record "MSD Distribution Worker";
                Line: Record "MSD Delivery Batch Line";
            begin
                if "Driver No." = '' then begin
                    "Driver Name" := '';
                    "Driver Phone No." := '';
                    "Vehicle No." := '';
                end else begin
                    Worker.Get("Driver No.");
                    "Driver Name" := Worker.Name;
                    "Driver Phone No." := Worker."Phone No.";
                    "Vehicle No." := Worker."Vehicle No.";
                end;
                Line.SetRange("Batch No.", "No.");
                Line.ModifyAll("Driver No.", "Driver No.");
            end;
        }
        field(11; "Driver Name"; Text[100])
        {
            Caption = 'Түгээгчийн нэр';
            Editable = false;
        }
        field(12; "Driver Phone No."; Text[30])
        {
            Caption = 'Түгээгчийн утас';
            Editable = false;
            ExtendedDatatype = PhoneNo;
        }
        field(13; "Vehicle No."; Code[20])
        {
            Caption = 'Машин';
        }
        field(14; "Picker No."; Code[20])
        {
            Caption = 'Цуглуулагч';
            TableRelation = "MSD Distribution Worker" where(Role = const(Picker), Active = const(true));
        }
        field(15; "Packer No."; Code[20])
        {
            Caption = 'Савлагч';
            TableRelation = "MSD Distribution Worker" where(Role = const(Packer), Active = const(true));
        }
        field(20; "Loaded At"; DateTime)
        {
            Caption = 'Ачсан цаг';
            Editable = false;
        }
        field(21; "Started At"; DateTime)
        {
            Caption = 'Эхэлсэн цаг';
            Editable = false;
        }
        field(22; "Finished At"; DateTime)
        {
            Caption = 'Дууссан цаг';
            Editable = false;
        }
        field(23; "Delivered Confirmed"; Boolean)
        {
            Caption = 'DELIVERED бүртгэсэн';
            Editable = false;
        }
        field(24; "Delivered Confirmed At"; DateTime)
        {
            Caption = 'DELIVERED бүртгэсэн цаг';
            Editable = false;
        }
        field(30; "No. of Stops"; Integer)
        {
            Caption = 'Захиалгын тоо';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Line" where("Batch No." = field("No.")));
            Editable = false;
        }
        field(31; "No. of Loaded Stops"; Integer)
        {
            Caption = 'Ачсан захиалга';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Line" where("Batch No." = field("No."), Loaded = const(true)));
            Editable = false;
        }
        field(32; "No. of Open Stops"; Integer)
        {
            Caption = 'Үлдсэн цэг';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Line" where("Batch No." = field("No."), Loaded = const(true), "Delivery Status" = filter(Pending | Skipped)));
            Editable = false;
        }
        field(33; "Total Amount"; Decimal)
        {
            Caption = 'Нийт дүн';
            FieldClass = FlowField;
            CalcFormula = sum("MSD Delivery Batch Line"."Amount Incl. VAT" where("Batch No." = field("No.")));
            AutoFormatType = 1;
            Editable = false;
        }
        field(34; "Total Quantity"; Decimal)
        {
            Caption = 'Нийт тоо';
            FieldClass = FlowField;
            CalcFormula = sum("MSD Delivery Batch Line"."Total Quantity" where("Batch No." = field("No.")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(35; "No. of Helpers"; Integer)
        {
            Caption = 'Туслахын тоо';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Helper" where("Batch No." = field("No.")));
            Editable = false;
        }
        field(36; "No. of Posting Errors"; Integer)
        {
            Caption = 'Posting алдаа';
            FieldClass = FlowField;
            CalcFormula = count("MSD Delivery Batch Line" where("Batch No." = field("No."), "Posting Status" = const(Error)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Driver; "Driver No.", Status, "Delivery Date") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Delivery Date", "Driver Name", Status) { }
        fieldgroup(Brick; "No.", "Route Description", "Vehicle No.", Status, "Delivery Date", "No. of Stops") { }
    }

    trigger OnInsert()
    var
        DeliverySetup: Record "MSD Delivery Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            DeliverySetup.GetSetup();
            DeliverySetup.TestField("Delivery Batch Nos.");
            "No." := NoSeries.GetNextNo(DeliverySetup."Delivery Batch Nos.");
        end;
        if "Delivery Date" = 0D then
            "Delivery Date" := WorkDate();
    end;

    trigger OnDelete()
    var
        Line: Record "MSD Delivery Batch Line";
        Helper: Record "MSD Delivery Batch Helper";
    begin
        if Status.AsInteger() > Status::"Ready to Load".AsInteger() then
            FieldError(Status);
        Line.SetRange("Batch No.", "No.");
        Line.DeleteAll(true);
        Helper.SetRange("Batch No.", "No.");
        Helper.DeleteAll();
    end;

    /// <summary>
    /// Sets the batch status and keeps the denormalized status on the lines in sync (used by cues and filters).
    /// </summary>
    procedure SetStatus(NewStatus: Enum "MSD Delivery Batch Status")
    var
        Line: Record "MSD Delivery Batch Line";
    begin
        Status := NewStatus;
        Modify(true);
        Line.SetRange("Batch No.", "No.");
        Line.ModifyAll("Batch Status", NewStatus);
    end;

    procedure IsBeforeStart(): Boolean
    begin
        exit(Status in [Status::"Ready to Load", Status::Loaded]);
    end;
}
