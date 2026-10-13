namespace EMC.MSD.Delivery;

/// <summary>
/// Supervisor / administrator and the Job Queue service user that posts the invoices.
/// Combine with the standard sales posting permission sets.
/// </summary>
permissionset 50101 "MSD DELIVERY ADMIN"
{
    Assignable = true;
    Caption = 'MSD Delivery Admin';
    IncludedPermissionSets = "MSD DRIVER";

    Permissions =
        tabledata "MSD Delivery Setup" = RIMD,
        tabledata "MSD Distribution Worker" = RIMD,
        tabledata "MSD Delivery Batch Header" = RIMD,
        tabledata "MSD Delivery Batch Line" = RIMD,
        tabledata "MSD Delivery Log Entry" = RIMD,
        codeunit "MSD Delivery Invoice Post" = X,
        codeunit "MSD Delivery Posting" = X,
        codeunit "MSD Delivery Return Order" = X,
        codeunit "MSD Delivery Batch Mgt." = X,
        page "MSD Distribution Workers" = X,
        page "MSD Delivery Setup" = X,
        page "MSD Supervisor Batches" = X,
        page "MSD Supervisor Batch" = X,
        page "MSD Supervisor Batch Lines" = X;
}
