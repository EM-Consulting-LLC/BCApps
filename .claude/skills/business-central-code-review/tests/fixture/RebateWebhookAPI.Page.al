namespace EMC.Rebate;

using Microsoft.Finance.GeneralLedger.Journal;

page 50102 "Rebate Payment API"
{
    PageType = API;
    APIPublisher = 'emc';
    APIGroup = 'rebate';
    APIVersion = 'v1.0';
    EntityName = 'rebatePayment';
    EntitySetName = 'rebatePayments';
    SourceTable = "Gen. Journal Line";
    ODataKeyFields = "Line No.";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(lineNo; Rec."Line No.") { }
                field(customerNo; Rec."Account No.") { }
                field(amount; Rec.Amount) { }
                field(externalPaymentId; Rec."External Document No.") { }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        HttpClient: HttpClient;
        Response: HttpResponseMessage;
        Token: Text;
    begin
        Token := 'Bearer sk-live-9f8e7d6c5b4a';
        HttpClient.DefaultRequestHeaders().Add('Authorization', Token);

        Rec."Journal Template Name" := 'GENERAL';
        Rec."Journal Batch Name" := 'REBATE';
        Rec."Line No." := GetNextLineNo();
        Rec.Insert(true);

        HttpClient.Post('http://payments.example.mn/confirm', PrepareContent(), Response);

        exit(false);
    end;

    local procedure GetNextLineNo(): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", 'GENERAL');
        GenJnlLine.SetRange("Journal Batch Name", 'REBATE');
        if GenJnlLine.FindLast() then
            exit(GenJnlLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure PrepareContent(): HttpContent
    var
        Content: HttpContent;
    begin
        exit(Content);
    end;
}
