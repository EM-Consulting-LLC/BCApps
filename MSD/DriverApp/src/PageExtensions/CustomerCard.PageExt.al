namespace EMC.MSD.Delivery;

using Microsoft.Sales.Customer;

pageextension 50100 "MSD Customer Card" extends "Customer Card"
{
    layout
    {
        addlast(Shipping)
        {
            group(MSDDeliveryPoint)
            {
                Caption = 'Delivery Point (Geofence)';

                field("MSD Latitude"; Rec."MSD Latitude")
                {
                    ApplicationArea = All;
                    ToolTip = 'Хүргэлтийн цэгийн Latitude (DEL-015).';
                }
                field("MSD Longitude"; Rec."MSD Longitude")
                {
                    ApplicationArea = All;
                    ToolTip = 'Хүргэлтийн цэгийн Longitude (DEL-015).';
                }
                field("MSD Geofence Radius (m)"; Rec."MSD Geofence Radius (m)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Төлөв өөрчлөхийг зөвшөөрөх радиус, метрээр (DEL-016). 0 бол Setup-ийн утгыг хэрэглэнэ.';
                }
            }
        }
    }
}
