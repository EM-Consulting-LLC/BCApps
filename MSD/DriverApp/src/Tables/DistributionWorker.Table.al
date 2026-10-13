namespace EMC.MSD.Delivery;

using System.Security.User;

/// <summary>
/// Distribution Worker Master (WMS-048). One role per worker (WMS-049), vehicle on driver (WMS-050).
/// </summary>
table 50101 "MSD Distribution Worker"
{
    Caption = 'Distribution Worker';
    DataClassification = CustomerContent;
    LookupPageId = "MSD Distribution Workers";
    DrillDownPageId = "MSD Distribution Workers";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Нэр';
        }
        field(3; "Phone No."; Text[30])
        {
            Caption = 'Утас';
            ExtendedDatatype = PhoneNo;
        }
        field(4; Role; Enum "MSD Worker Role")
        {
            Caption = 'Үүрэг';

            trigger OnValidate()
            begin
                if Role <> Role::Driver then
                    "Vehicle No." := '';
            end;
        }
        field(5; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Worker: Record "MSD Distribution Worker";
            begin
                if "User ID" = '' then
                    exit;
                Worker.SetRange("User ID", "User ID");
                Worker.SetFilter("No.", '<>%1', "No.");
                if not Worker.IsEmpty() then
                    Error(UserAlreadyLinkedErr, "User ID");
            end;
        }
        field(6; "Vehicle No."; Code[20])
        {
            Caption = 'Машины дугаар';

            trigger OnValidate()
            begin
                if "Vehicle No." <> '' then
                    TestField(Role, Role::Driver);
            end;
        }
        field(7; Active; Boolean)
        {
            Caption = 'Active';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(User; "User ID") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, "Phone No.") { }
        fieldgroup(Brick; Name, "No.", "Phone No.", Role) { }
    }

    var
        UserAlreadyLinkedErr: Label 'Хэрэглэгч %1 өөр ажилтантай холбогдсон байна. Нэг хэрэглэгч нэг л үүрэгтэй байна.', Comment = '%1 = User ID';
}
