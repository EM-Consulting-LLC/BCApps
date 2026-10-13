namespace EMC.MSD.Delivery;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.NoSeries;

table 50100 "MSD Delivery Setup"
{
    Caption = 'MSD Delivery Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Delivery Batch Nos."; Code[20])
        {
            Caption = 'Delivery Batch Nos.';
            TableRelation = "No. Series";
        }
        field(20; "Geofence Enabled"; Boolean)
        {
            Caption = 'Geofence Enabled';
        }
        field(21; "Default Geofence Radius (m)"; Integer)
        {
            Caption = 'Default Geofence Radius (m)';
            MinValue = 0;
            InitValue = 150;
        }
        field(22; "Allow Missing Coordinates"; Boolean)
        {
            Caption = 'Allow Missing Customer Coordinates';
            InitValue = true;
        }
        field(30; "Post via Job Queue"; Boolean)
        {
            Caption = 'Post Invoices via Job Queue';
            InitValue = true;
        }
        field(40; "Cash Payment Method"; Code[10])
        {
            Caption = 'Cash Payment Method';
            TableRelation = "Payment Method";
        }
        field(41; "Non-Cash Payment Method"; Code[10])
        {
            Caption = 'Non-Cash Payment Method';
            TableRelation = "Payment Method";
        }
        field(42; "Credit Payment Method"; Code[10])
        {
            Caption = 'Credit Payment Method';
            TableRelation = "Payment Method";
        }
        field(50; "Max. Helpers per Batch"; Integer)
        {
            Caption = 'Max. Helpers per Batch';
            MinValue = 1;
            InitValue = 2;
        }
        field(51; "Require Delivered Confirm"; Boolean)
        {
            Caption = 'Require DELIVERED before next Start';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;

    procedure GetPaymentMethodCode(PaymentType: Enum "MSD Delivery Payment Type"): Code[10]
    begin
        case PaymentType of
            PaymentType::Cash:
                exit("Cash Payment Method");
            PaymentType::NonCash:
                exit("Non-Cash Payment Method");
            PaymentType::Credit:
                exit("Credit Payment Method");
        end;
    end;
}
