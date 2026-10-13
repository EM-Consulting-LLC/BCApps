namespace EMC.MSD.Delivery;

using Microsoft.Sales.Customer;

/// <summary>
/// One stop at the customer. Fully / Partially / Cancel are promoted (phone shows only promoted actions);
/// Skip, Map and Log are in the ··· menu. A registered stop is read-only (DEL-005, DEL-007, DEL-011).
/// </summary>
page 50106 "MSD Delivery Stop Card"
{
    PageType = Card;
    Caption = 'Цэг';
    DataCaptionExpression = Rec."Customer Name";
    SourceTable = "MSD Delivery Batch Line";
    InsertAllowed = false;
    DeleteAllowed = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(Banner)
            {
                ShowCaption = false;
                Visible = HasBanner;

                field(BannerField; BannerText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    StyleExpr = BannerStyle;
                    MultiLine = true;
                    ToolTip = 'Цэгийн төлөвийн мэдээлэл.';
                }
            }
            group(General)
            {
                Caption = 'Ерөнхий';

                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Борлуулалтын захиалга.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Харилцагч.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Хүргэх хаяг.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Хот / дүүрэг.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Утас. Дарахад утасны дуудлага эхэлнэ.';
                }
                field("Payment Type"; Rec."Payment Type")
                {
                    ApplicationArea = All;
                    Editable = IsOpenStop;
                    ToolTip = 'Төлбөрийн нөхцөл: Бэлэн, Бэлэн бус, Зээл (DEL-006). Нэхэмжлэл post хийхэд хэрэглэгдэнэ.';
                }
                field("Amount Incl. VAT"; Rec."Amount Incl. VAT")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Дүн (НӨАТ-тай).';
                }
                field("Delivery Status"; Rec."Delivery Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Хүргэлтийн төлөв.';
                }
            }
            group(Registration)
            {
                Caption = 'Бүртгэл';
                Editable = false;
                Visible = not IsOpenStop;

                field("Registered At"; Rec."Registered At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Бүртгэсэн цаг.';
                }
                field(Position; PositionText)
                {
                    ApplicationArea = All;
                    Caption = 'Байршил (GPS)';
                    ToolTip = 'Бүртгэх үеийн төхөөрөмжийн байршил (DEL-015).';
                }
                field("Distance (m)"; Rec."Distance (m)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Харилцагчийн байршлаас зай.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    Visible = HasReason;
                    ToolTip = 'Cancel хийсэн шалтгаан (DEL-011).';
                }
                field("Posting Status"; Rec."Posting Status")
                {
                    ApplicationArea = All;
                    StyleExpr = PostingStyle;
                    ToolTip = 'Queued → Posted эсвэл Error. Алдааг супервайзер засаад дахин post хийнэ.';
                }
                field("Posting Error"; Rec."Posting Error")
                {
                    ApplicationArea = All;
                    Visible = HasPostingError;
                    MultiLine = true;
                    Style = Unfavorable;
                    ToolTip = 'Post хийх үеийн алдааны мэдээлэл.';
                }
                field("Posted Invoice No."; Rec."Posted Invoice No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Post хийгдсэн нэхэмжлэл.';
                }
                field("Return Order No."; Rec."Return Order No.")
                {
                    ApplicationArea = All;
                    Visible = IsPartially;
                    ToolTip = 'Автоматаар үүссэн буцаалтын захиалга (DEL-010).';
                }
                field("Return Quantity"; Rec."Return Quantity")
                {
                    ApplicationArea = All;
                    Visible = IsPartially;
                    ToolTip = 'Буцаасан нийт тоо.';
                }
            }
            part(OrderLines; "MSD Stop Order Lines")
            {
                ApplicationArea = All;
                Caption = 'Мөрүүд';
                SubPageLink = "Document No." = field("Sales Order No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Fully)
            {
                ApplicationArea = All;
                Caption = 'Fully';
                Image = Approve;
                Enabled = IsOpenStop;
                ToolTip = 'Захиалгыг бүрэн хүлээлгэн өгсөн. Нэхэмжлэл автоматаар post хийгдэнэ (DEL-008).';

                trigger OnAction()
                begin
                    DriverMgt.RegisterFully(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Partially)
            {
                ApplicationArea = All;
                Caption = 'Partially';
                Image = ReturnOrder;
                Enabled = IsOpenStop;
                ToolTip = 'Зарим барааг буцаасан. Буцаах тоо, шалтгааныг оруулна (DEL-009). Буцаалтын захиалга автоматаар үүснэ (DEL-010).';

                trigger OnAction()
                begin
                    DriverMgt.OpenPartialDelivery(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Cancel)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                Image = Cancel;
                Enabled = IsOpenStop;
                ToolTip = 'Захиалгыг хүлээлгэн өгөөгүй. Шалтгаан заавал, нэхэмжлэл үүсэхгүй (DEL-011).';

                trigger OnAction()
                begin
                    DriverMgt.RegisterCancel(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Skip)
            {
                ApplicationArea = All;
                Caption = 'Skip';
                Image = NextRecord;
                Enabled = IsOpenStop;
                ToolTip = 'Цэгийг түр алгасна. Жагсаалтын төгсгөлд шилжих ба FINISH-ийн өмнө заавал бүртгэнэ.';

                trigger OnAction()
                begin
                    DriverMgt.SkipStop(Rec);
                    CurrPage.Close();
                end;
            }
            action(Map)
            {
                ApplicationArea = All;
                Caption = 'Газрын зураг';
                Image = Map;
                ToolTip = 'Харилцагчийн байршлыг газрын зургийн апп-д нээнэ.';

                trigger OnAction()
                begin
                    OpenMap();
                end;
            }
        }
        area(Navigation)
        {
            action(Log)
            {
                ApplicationArea = All;
                Caption = 'Лог';
                Image = Log;
                RunObject = page "MSD Delivery Log Entries";
                RunPageLink = "Batch No." = field("Batch No."), "Batch Line No." = field("Line No.");
                ToolTip = 'Энэ цэгийн үйлдлийн түүх.';
            }
        }
        area(Promoted)
        {
            actionref(Fully_Promoted; Fully) { }
            actionref(Partially_Promoted; Partially) { }
            actionref(Cancel_Promoted; Cancel) { }
        }
    }

    var
        DriverMgt: Codeunit "MSD Driver Mgt.";
        IsOpenStop: Boolean;
        HasBanner: Boolean;
        HasReason: Boolean;
        HasPostingError: Boolean;
        IsPartially: Boolean;
        BannerText: Text;
        BannerStyle: Text;
        StatusStyle: Text;
        PostingStyle: Text;
        PositionText: Text;
        PositionTxt: Label '%1, %2', Locked = true;
        MapByCoordinatesTxt: Label 'https://www.google.com/maps/search/?api=1&query=%1,%2', Locked = true;
        MapByAddressTxt: Label 'https://www.google.com/maps/search/?api=1&query=%1', Locked = true;
        SkippedBannerTxt: Label 'Өмнө нь Skip хийсэн цэг. Одоо бүртгэнэ үү.';
        RegisteredBannerTxt: Label 'Бүртгэгдсэн. Засах боломжгүй.';
        ErrorBannerTxt: Label 'Нэхэмжлэл post хийхэд алдаа гарлаа. Супервайзерт мэдэгдсэн.';
        NotStartedBannerTxt: Label 'Түгээлт эхлээгүй. Зөвхөн харах горим.';

    trigger OnAfterGetCurrRecord()
    begin
        IsOpenStop := Rec.IsOpen() and (Rec."Batch Status" = Rec."Batch Status"::"In Transit");
        PositionText := '';
        if (Rec.Latitude <> 0) or (Rec.Longitude <> 0) then
            PositionText := StrSubstNo(PositionTxt, Format(Rec.Latitude, 0, 9), Format(Rec.Longitude, 0, 9));

        BannerText := '';
        BannerStyle := 'Standard';
        case true of
            Rec."Posting Status" = Rec."Posting Status"::Error:
                begin
                    BannerText := ErrorBannerTxt;
                    BannerStyle := 'Unfavorable';
                end;
            not Rec.IsOpen():
                BannerText := RegisteredBannerTxt;
            Rec."Batch Status" <> Rec."Batch Status"::"In Transit":
                BannerText := NotStartedBannerTxt;
            Rec."Delivery Status" = Rec."Delivery Status"::Skipped:
                begin
                    BannerText := SkippedBannerTxt;
                    BannerStyle := 'Ambiguous';
                end;
        end;

        HasBanner := BannerText <> '';
        HasReason := Rec."Reason Code" <> '';
        HasPostingError := Rec."Posting Status" = Rec."Posting Status"::Error;
        IsPartially := Rec."Delivery Status" = Rec."Delivery Status"::Partially;

        case Rec."Delivery Status" of
            Rec."Delivery Status"::Fully:
                StatusStyle := 'Favorable';
            Rec."Delivery Status"::Partially, Rec."Delivery Status"::Skipped:
                StatusStyle := 'Ambiguous';
            Rec."Delivery Status"::Cancelled:
                StatusStyle := 'Unfavorable';
            else
                StatusStyle := 'Standard';
        end;

        case Rec."Posting Status" of
            Rec."Posting Status"::Posted:
                PostingStyle := 'Favorable';
            Rec."Posting Status"::Error:
                PostingStyle := 'Unfavorable';
            else
                PostingStyle := 'Subordinate';
        end;
    end;

    local procedure OpenMap()
    var
        Customer: Record Customer;
    begin
        if Customer.Get(Rec."Customer No.") then
            if (Customer."MSD Latitude" <> 0) or (Customer."MSD Longitude" <> 0) then begin
                Hyperlink(StrSubstNo(MapByCoordinatesTxt, Format(Customer."MSD Latitude", 0, 9), Format(Customer."MSD Longitude", 0, 9)));
                exit;
            end;
        Hyperlink(StrSubstNo(MapByAddressTxt, ConvertStr(Rec.Address + ' ' + Rec.City, ' ', '+')));
    end;
}
