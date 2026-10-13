namespace EMC.MSD.Delivery;

using Microsoft.Sales.Customer;
using System.Device;
using System.Utilities;

/// <summary>
/// Reads the device location and checks it against the customer's allowed zone (DEL-015, DEL-016).
/// Must be called before any database write in the same action: Geolocation opens a modal page.
/// </summary>
codeunit 50101 "MSD Geofence Mgt."
{
    var
        NoLocationErr: Label 'Төхөөрөмжийн байршлыг авч чадсангүй. Утасны тохиргоонд Business Central-д байршил ашиглах зөвшөөрөл өгнө үү.';
        NoCoordinatesErr: Label 'Харилцагч %1 дээр байршлын координат бүртгэгдээгүй байна. Супервайзерт хандана уу.', Comment = '%1 = Customer No.';
        OutsideZoneErr: Label 'Байршил зөвшөөрөгдсөн бүсээс гадуур байна (харилцагчаас %1 м, радиус %2 м). Төлөв өөрчлөх боломжгүй.', Comment = '%1 = distance in meters, %2 = radius in meters';
        OutsideZoneLogTxt: Label 'Geofence: %1 м (радиус %2 м)', Comment = '%1 = distance, %2 = radius';

    /// <summary>
    /// Captures the device position and validates it. Returns the position and distance for the audit trail.
    /// When the geofence is disabled in setup, the position is still captured when the device can provide it.
    /// </summary>
    procedure CaptureAndCheck(BatchLine: Record "MSD Delivery Batch Line"; var Latitude: Decimal; var Longitude: Decimal; var DistanceM: Decimal)
    var
        DeliverySetup: Record "MSD Delivery Setup";
        Customer: Record Customer;
        DriverMgt: Codeunit "MSD Driver Mgt.";
        HasLocation: Boolean;
        RadiusM: Integer;
    begin
        DeliverySetup.GetSetup();
        HasLocation := TryGetDeviceLocation(Latitude, Longitude);
        DistanceM := 0;

        if not DeliverySetup."Geofence Enabled" then
            exit;

        if not HasLocation then
            Error(NoLocationErr);

        Customer.Get(BatchLine."Customer No.");
        if (Customer."MSD Latitude" = 0) and (Customer."MSD Longitude" = 0) then begin
            if DeliverySetup."Allow Missing Coordinates" then
                exit;
            Error(NoCoordinatesErr, Customer."No.");
        end;

        RadiusM := Customer."MSD Geofence Radius (m)";
        if RadiusM = 0 then
            RadiusM := DeliverySetup."Default Geofence Radius (m)";

        DistanceM := Round(DistanceInMeters(Latitude, Longitude, Customer."MSD Latitude", Customer."MSD Longitude"), 1);
        if DistanceM > RadiusM then begin
            DriverMgt.LogEventWithPosition(BatchLine, Enum::"MSD Delivery Log Event"::"Geofence Rejected",
                StrSubstNo(OutsideZoneLogTxt, DistanceM, RadiusM), Latitude, Longitude);
            Commit(); // keep the rejected attempt in the log
            Error(OutsideZoneErr, DistanceM, RadiusM);
        end;
    end;

    local procedure TryGetDeviceLocation(var Latitude: Decimal; var Longitude: Decimal): Boolean
    var
        Geolocation: Codeunit Geolocation;
    begin
        Latitude := 0;
        Longitude := 0;
        Geolocation.SetHighAccuracy(true);
        Geolocation.SetTimeout(15000);
        if not Geolocation.RequestGeolocation() then
            exit(false);
        Geolocation.GetGeolocation(Latitude, Longitude);
        exit(true);
    end;

    /// <summary>
    /// Haversine great-circle distance in meters.
    /// </summary>
    procedure DistanceInMeters(Lat1: Decimal; Lon1: Decimal; Lat2: Decimal; Lon2: Decimal): Decimal
    var
        Math: Codeunit Math;
        DLat: Decimal;
        DLon: Decimal;
        A: Decimal;
    begin
        DLat := ToRadians(Lat2 - Lat1);
        DLon := ToRadians(Lon2 - Lon1);
        A := Math.Sin(DLat / 2) * Math.Sin(DLat / 2) +
             Math.Cos(ToRadians(Lat1)) * Math.Cos(ToRadians(Lat2)) * Math.Sin(DLon / 2) * Math.Sin(DLon / 2);
        exit(2 * 6371000 * Math.Asin(Math.Sqrt(A)));
    end;

    local procedure ToRadians(Degrees: Decimal): Decimal
    var
        Math: Codeunit Math;
    begin
        exit(Degrees * Math.Pi() / 180);
    end;
}
