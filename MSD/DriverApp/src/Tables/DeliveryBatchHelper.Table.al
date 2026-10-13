namespace EMC.MSD.Delivery;

/// <summary>
/// Helpers riding with the driver (WMS-092, DEL-003: at least 1, at most 2 by setup).
/// </summary>
table 50104 "MSD Delivery Batch Helper"
{
    Caption = 'Delivery Batch Helper';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            TableRelation = "MSD Delivery Batch Header";
        }
        field(2; "Worker No."; Code[20])
        {
            Caption = 'Туслах';
            NotBlank = true;
            TableRelation = "MSD Distribution Worker" where(Role = const(Helper), Active = const(true));

            trigger OnValidate()
            var
                Worker: Record "MSD Distribution Worker";
            begin
                Worker.Get("Worker No.");
                Worker.TestField(Role, Worker.Role::Helper);
                Worker.TestField(Active, true);
                Name := Worker.Name;
                "Phone No." := Worker."Phone No.";
            end;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Нэр';
            Editable = false;
        }
        field(4; "Phone No."; Text[30])
        {
            Caption = 'Утас';
            ExtendedDatatype = PhoneNo;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Batch No.", "Worker No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; Name, "Worker No.", "Phone No.") { }
    }

    trigger OnInsert()
    var
        DriverMgt: Codeunit "MSD Driver Mgt.";
    begin
        DriverMgt.CheckCanAddHelper("Batch No.");
        DriverMgt.LogHelperChange(Rec, true);
    end;

    trigger OnDelete()
    var
        Header: Record "MSD Delivery Batch Header";
        DriverMgt: Codeunit "MSD Driver Mgt.";
    begin
        Header.Get("Batch No.");
        Header.TestField(Status, Header.Status::Loaded);
        DriverMgt.LogHelperChange(Rec, false);
    end;

    trigger OnRename()
    begin
        Error(RenameNotAllowedErr);
    end;

    var
        RenameNotAllowedErr: Label 'Туслахыг солихын тулд мөрийг устгаад шинээр нэмнэ үү.';
}
