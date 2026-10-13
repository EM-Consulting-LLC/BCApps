namespace EMC.MSD.Delivery;

/// <summary>
/// Driver: works on the delivery tables only. Invoice posting runs in the Job Queue under a service user,
/// so the driver gets no posting permissions (WMS-089). The Sales Header status is written through
/// the codeunit's inherent permissions.
/// </summary>
permissionset 50100 "MSD DRIVER"
{
    Assignable = true;
    Caption = 'MSD Driver';

    Permissions =
        tabledata "MSD Delivery Setup" = R,
        tabledata "MSD Distribution Worker" = R,
        tabledata "MSD Delivery Batch Header" = RM,
        tabledata "MSD Delivery Batch Line" = RM,
        tabledata "MSD Delivery Batch Helper" = RIMD,
        tabledata "MSD Delivery Return Line" = RIMD,
        tabledata "MSD Delivery Log Entry" = RI,
        tabledata "MSD Driver Cue" = RIM,
        table "MSD Delivery Setup" = X,
        table "MSD Distribution Worker" = X,
        table "MSD Delivery Batch Header" = X,
        table "MSD Delivery Batch Line" = X,
        table "MSD Delivery Batch Helper" = X,
        table "MSD Delivery Return Line" = X,
        table "MSD Delivery Log Entry" = X,
        table "MSD Driver Cue" = X,
        codeunit "MSD Driver Mgt." = X,
        codeunit "MSD Geofence Mgt." = X,
        page "MSD Driver Role Center" = X,
        page "MSD Driver Activities" = X,
        page "MSD Delivery Batch List" = X,
        page "MSD Delivery Batch Card" = X,
        page "MSD Delivery Stops" = X,
        page "MSD Batch Helpers" = X,
        page "MSD Delivery Stop Card" = X,
        page "MSD Stop Order Lines" = X,
        page "MSD Partial Delivery" = X,
        page "MSD Return Lines Part" = X,
        page "MSD Delivery Log Entries" = X;
}
