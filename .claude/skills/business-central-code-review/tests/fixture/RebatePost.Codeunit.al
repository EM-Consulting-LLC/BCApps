namespace EMC.Rebate;

using Microsoft.Sales.History;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Sales.Customer;

codeunit 50100 "Rebate Post"
{
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "Sales Invoice Header" = rimd,
                  TableData "Rebate Ledger Entry" = rimd;

    procedure PostRebateForInvoice(SalesInvHeader: Record "Sales Invoice Header")
    var
        Customer: Record Customer;
        RebateLedgerEntry: Record "Rebate Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        RebateAmount: Decimal;
    begin
        Customer.Get(SalesInvHeader."Sell-to Customer No.");

        RebateAmount := SalesInvHeader.Amount * Customer."Rebate %" / 100;

        RebateLedgerEntry.Init();
        RebateLedgerEntry."Entry No." := GetLastEntryNo() + 1;
        RebateLedgerEntry."Customer No." := Customer."No.";
        RebateLedgerEntry."Invoice No." := SalesInvHeader."No.";
        RebateLedgerEntry.Amount := RebateAmount;
        RebateLedgerEntry."Posting Date" := WorkDate();
        RebateLedgerEntry.Insert();

        Commit();

        GenJnlLine.Init();
        GenJnlLine."Posting Date" := WorkDate();
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Account No." := GetRebateAccount();
        GenJnlLine.Amount := -RebateAmount;
        GenJnlLine."Document No." := SalesInvHeader."No.";
        GenJnlPostLine.RunWithCheck(GenJnlLine);

        if not Confirm('Rebate амжилттай бичигдлээ. Имэйл илгээх үү?') then
            exit;
        SendRebateEmail(Customer, RebateAmount);
    end;

    local procedure GetLastEntryNo(): Integer
    var
        RebateLedgerEntry: Record "Rebate Ledger Entry";
    begin
        if RebateLedgerEntry.FindLast() then
            exit(RebateLedgerEntry."Entry No.");
        exit(0);
    end;

    procedure RecalculateAllRebates()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        Total: Decimal;
    begin
        if SalesInvHeader.FindSet() then
            repeat
                Customer.SetRange("No.", SalesInvHeader."Sell-to Customer No.");
                Customer.FindFirst();
                Customer.CalcFields("Balance (LCY)");
                if Customer."Rebate %" > 0 then
                    Total += SalesInvHeader.Amount * Customer."Rebate %" / 100;
            until SalesInvHeader.Next() = 0;
    end;

    local procedure GetRebateAccount(): Code[20]
    begin
        exit('998877');
    end;

    local procedure SendRebateEmail(Customer: Record Customer; Amount: Decimal)
    begin
        // email logic
    end;
}
