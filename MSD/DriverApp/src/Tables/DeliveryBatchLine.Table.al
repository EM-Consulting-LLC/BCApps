namespace EMC.MSD.Delivery;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

/// <summary>
/// One stop of a Delivery Batch = one Sales Order (WMS-055).
/// </summary>
table 50103 "MSD Delivery Batch Line"
{
    Caption = 'Delivery Batch Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            TableRelation = "MSD Delivery Batch Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Sequence No."; Integer)
        {
            Caption = 'Дараалал';
            MinValue = 0;
        }
        field(4; "Sales Order No."; Code[20])
        {
            Caption = 'Борлуулалтын захиалга';
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));

            trigger OnValidate()
            begin
                FillFromSalesOrder();
            end;
        }
        field(5; "Customer No."; Code[20])
        {
            Caption = 'Харилцагч';
            TableRelation = Customer;
            Editable = false;
        }
        field(6; "Customer Name"; Text[100])
        {
            Caption = 'Харилцагчийн нэр';
            Editable = false;
        }
        field(7; Address; Text[100])
        {
            Caption = 'Хаяг';
            Editable = false;
        }
        field(8; City; Text[30])
        {
            Caption = 'Хот / Дүүрэг';
            Editable = false;
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Утас';
            ExtendedDatatype = PhoneNo;
            Editable = false;
        }
        field(10; "Amount Incl. VAT"; Decimal)
        {
            Caption = 'Дүн (НӨАТ-тай)';
            AutoFormatType = 1;
            Editable = false;
        }
        field(11; "Total Quantity"; Decimal)
        {
            Caption = 'Нийт тоо';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(12; "Driver No."; Code[20])
        {
            Caption = 'Driver No.';
            Editable = false;
        }
        field(13; "Batch Status"; Enum "MSD Delivery Batch Status")
        {
            Caption = 'Batch Status';
            Editable = false;
        }
        field(20; Loaded; Boolean)
        {
            Caption = 'LOADED';
            Editable = false;
        }
        field(21; "Delivery Status"; Enum "MSD Stop Delivery Status")
        {
            Caption = 'Delivery Status';
            Editable = false;
        }
        field(22; "Payment Type"; Enum "MSD Delivery Payment Type")
        {
            Caption = 'Төлбөрийн нөхцөл';

            trigger OnValidate()
            var
                DriverMgt: Codeunit "MSD Driver Mgt.";
            begin
                if "Payment Type" <> xRec."Payment Type" then
                    DriverMgt.ValidatePaymentType(Rec);
            end;
        }
        field(23; "Reason Code"; Code[10])
        {
            Caption = 'Шалтгаан';
            TableRelation = "Return Reason";
            Editable = false;
        }
        field(24; "Registered At"; DateTime)
        {
            Caption = 'Бүртгэсэн цаг';
            Editable = false;
        }
        field(25; "Registered By"; Code[50])
        {
            Caption = 'Бүртгэсэн хэрэглэгч';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(30; Latitude; Decimal)
        {
            Caption = 'Latitude';
            DecimalPlaces = 0 : 7;
            Editable = false;
        }
        field(31; Longitude; Decimal)
        {
            Caption = 'Longitude';
            DecimalPlaces = 0 : 7;
            Editable = false;
        }
        field(32; "Distance (m)"; Decimal)
        {
            Caption = 'Харилцагчаас зай (м)';
            DecimalPlaces = 0 : 0;
            Editable = false;
        }
        field(40; "Posting Status"; Enum "MSD Posting Status")
        {
            Caption = 'Posting Status';
            Editable = false;
        }
        field(41; "Posting Error"; Text[2048])
        {
            Caption = 'Алдааны мэдээлэл';
            Editable = false;
        }
        field(42; "Posted Invoice No."; Code[20])
        {
            Caption = 'Нэхэмжлэл';
            Editable = false;
        }
        field(43; "Return Order No."; Code[20])
        {
            Caption = 'Буцаалтын захиалга';
            Editable = false;
        }
        field(44; "Return Quantity"; Decimal)
        {
            Caption = 'Буцаах тоо';
            FieldClass = FlowField;
            CalcFormula = sum("MSD Delivery Return Line"."Return Quantity" where("Batch No." = field("Batch No."), "Batch Line No." = field("Line No.")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Batch No.", "Line No.")
        {
            Clustered = true;
        }
        key(Sequence; "Batch No.", "Sequence No.") { }
        key(Driver; "Driver No.", "Batch Status", "Delivery Status") { }
        key(SalesOrder; "Sales Order No.") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Sequence No.", "Customer Name", "Sales Order No.", "Delivery Status") { }
        fieldgroup(Brick; "Sequence No.", "Customer Name", "Sales Order No.", "Amount Incl. VAT", "Delivery Status") { }
    }

    trigger OnInsert()
    var
        Header: Record "MSD Delivery Batch Header";
        Line: Record "MSD Delivery Batch Line";
    begin
        Header.Get("Batch No.");
        "Driver No." := Header."Driver No.";
        "Batch Status" := Header.Status;
        if "Line No." = 0 then begin
            Line.SetRange("Batch No.", "Batch No.");
            if Line.FindLast() then
                "Line No." := Line."Line No.";
            "Line No." += 10000;
        end;
        if "Sequence No." = 0 then begin
            Line.Reset();
            Line.SetCurrentKey("Batch No.", "Sequence No.");
            Line.SetRange("Batch No.", "Batch No.");
            if Line.FindLast() then
                "Sequence No." := Line."Sequence No.";
            "Sequence No." += 1;
        end;
    end;

    trigger OnDelete()
    var
        ReturnLine: Record "MSD Delivery Return Line";
    begin
        TestField("Delivery Status", "Delivery Status"::Pending);
        ReturnLine.SetRange("Batch No.", "Batch No.");
        ReturnLine.SetRange("Batch Line No.", "Line No.");
        ReturnLine.DeleteAll();
    end;

    local procedure FillFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Line: Record "MSD Delivery Batch Line";
    begin
        if "Sales Order No." = '' then begin
            "Customer No." := '';
            "Customer Name" := '';
            Address := '';
            City := '';
            "Phone No." := '';
            "Amount Incl. VAT" := 0;
            "Total Quantity" := 0;
            exit;
        end;

        Line.SetRange("Sales Order No.", "Sales Order No.");
        Line.SetFilter("Batch Status", '<%1', Line."Batch Status"::Completed);
        Line.SetFilter("Batch No.", '<>%1', "Batch No.");
        if Line.FindFirst() then
            Error(AlreadyInBatchErr, "Sales Order No.", Line."Batch No.");

        SalesHeader.Get(SalesHeader."Document Type"::Order, "Sales Order No.");
        SalesHeader.CalcFields("Amount Including VAT");
        "Customer No." := SalesHeader."Sell-to Customer No.";
        "Customer Name" := SalesHeader."Ship-to Name";
        if "Customer Name" = '' then
            "Customer Name" := SalesHeader."Sell-to Customer Name";
        Address := SalesHeader."Ship-to Address";
        City := SalesHeader."Ship-to City";
        "Phone No." := SalesHeader."Sell-to Phone No.";
        "Amount Incl. VAT" := SalesHeader."Amount Including VAT";

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.CalcSums(Quantity);
        "Total Quantity" := SalesLine.Quantity;
    end;

    procedure IsOpen(): Boolean
    begin
        exit("Delivery Status" in ["Delivery Status"::Pending, "Delivery Status"::Skipped]);
    end;

    var
        AlreadyInBatchErr: Label 'Захиалга %1 аль хэдийн %2 batch-д орсон байна.', Comment = '%1 = Sales Order No., %2 = Delivery Batch No.';
}
