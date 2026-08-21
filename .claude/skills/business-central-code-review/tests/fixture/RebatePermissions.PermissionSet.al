namespace EMC.Rebate;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.History;

permissionset 50100 "EMC Rebate"
{
    Assignable = true;
    Caption = 'EMC Rebate - All users';

    Permissions =
        tabledata "Rebate Ledger Entry" = RIMD,
        tabledata "G/L Entry" = RIMD,
        tabledata "Cust. Ledger Entry" = RIMD,
        tabledata "Sales Invoice Header" = RIMD,
        codeunit "Rebate Post" = X,
        page "Rebate Payment API" = X;
}
