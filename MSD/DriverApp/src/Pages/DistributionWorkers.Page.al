namespace EMC.MSD.Delivery;

page 50110 "MSD Distribution Workers"
{
    PageType = List;
    Caption = 'Distribution Workers';
    SourceTable = "MSD Distribution Worker";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Workers)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Ажилтны код.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Нэр.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Утас.';
                }
                field(Role; Rec.Role)
                {
                    ApplicationArea = All;
                    ToolTip = 'Үүрэг: Driver, Helper, Picker, Packer, Supervisor. Нэг ажилтан нэг үүрэгтэй.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Business Central хэрэглэгч. Жолоочийн апп энэ холбоосоор түгээгчийг танина.';
                }
                field("Vehicle No."; Rec."Vehicle No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Жолоочид оноосон машин.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Идэвхтэй эсэх.';
                }
            }
        }
    }
}
