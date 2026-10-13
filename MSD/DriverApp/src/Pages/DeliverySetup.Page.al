namespace EMC.MSD.Delivery;

using System.Threading;

page 50111 "MSD Delivery Setup"
{
    PageType = Card;
    Caption = 'MSD Delivery Setup';
    SourceTable = "MSD Delivery Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Delivery Batch Nos."; Rec."Delivery Batch Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Delivery Batch-ийн дугаарлалт.';
                }
                field("Max. Helpers per Batch"; Rec."Max. Helpers per Batch")
                {
                    ApplicationArea = All;
                    ToolTip = 'Нэг batch-д сонгох туслахын дээд тоо (DEL-003).';
                }
                field("Require Delivered Confirm"; Rec."Require Delivered Confirm")
                {
                    ApplicationArea = All;
                    ToolTip = 'Өмнөх batch-д DELIVERED бөглөөгүй бол дараагийн START-ыг хориглоно (DEL-013).';
                }
            }
            group(Geofence)
            {
                Caption = 'Geofence';

                field("Geofence Enabled"; Rec."Geofence Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Харилцагчийн бүсэд байгаа эсэхийг шалгана (DEL-016). Идэвхгүй үед ч байршлыг бүртгэнэ (DEL-015).';
                }
                field("Default Geofence Radius (m)"; Rec."Default Geofence Radius (m)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Харилцагч дээр радиус тохируулаагүй үед хэрэглэх радиус, метрээр.';
                }
                field("Allow Missing Coordinates"; Rec."Allow Missing Coordinates")
                {
                    ApplicationArea = All;
                    ToolTip = 'Координатгүй харилцагч дээр шалгалтыг алгасах эсэх.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';

                field("Post via Job Queue"; Rec."Post via Job Queue")
                {
                    ApplicationArea = All;
                    ToolTip = 'Нэхэмжлэлийг Job Queue-ээр (service user) post хийнэ. Унтраавал жолоочийн session-д шууд post хийнэ (демо).';
                }
                field("Cash Payment Method"; Rec."Cash Payment Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Бэлэн гэж сонгоход нэхэмжлэлд тавих Payment Method.';
                }
                field("Non-Cash Payment Method"; Rec."Non-Cash Payment Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Бэлэн бус гэж сонгоход нэхэмжлэлд тавих Payment Method.';
                }
                field("Credit Payment Method"; Rec."Credit Payment Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Зээл гэж сонгоход нэхэмжлэлд тавих Payment Method.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ScheduleJobQueue)
            {
                ApplicationArea = All;
                Caption = 'Job Queue үүсгэх';
                Image = Setup;
                ToolTip = 'Queued цэгүүдийг минут тутам post хийх Job Queue Entry үүсгэнэ. Posting эрхтэй service user-ээр ажиллуулна.';

                trigger OnAction()
                var
                    DeliveryPosting: Codeunit "MSD Delivery Posting";
                begin
                    DeliveryPosting.ScheduleJobQueueEntry();
                    Page.Run(Page::"Job Queue Entries");
                end;
            }
            action(PostQueuedNow)
            {
                ApplicationArea = All;
                Caption = 'Queued-ийг одоо post хийх';
                Image = Post;
                ToolTip = 'Job Queue хүлээлгүйгээр Queued цэгүүдийг post хийнэ.';

                trigger OnAction()
                var
                    DeliveryPosting: Codeunit "MSD Delivery Posting";
                begin
                    DeliveryPosting.ProcessQueue();
                end;
            }
        }
        area(Navigation)
        {
            action(Workers)
            {
                ApplicationArea = All;
                Caption = 'Distribution Workers';
                Image = Users;
                RunObject = page "MSD Distribution Workers";
                ToolTip = 'Агуулахын ажилчдын бүртгэл.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
