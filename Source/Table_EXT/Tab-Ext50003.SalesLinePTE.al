tableextension 50003 "Sales Line" extends "Sales Line"
{
    fields
    {
        field(50000; "Stato Riga"; Text[50])
        {
            Caption = 'Stato Riga';
            DataClassification = CustomerContent;
        }
        field(50001; "Quantita prenotata"; Decimal)
        {
            Caption = 'Quantita prenotata';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }

    }


    trigger OnInsert()
    begin
        UpdateStatoRiga();
    end;


    local procedure UpdateStatoRiga()
    begin
        if "Quantita prenotata" = 0 then
            "Stato Riga" := 'Da Gestire'
        else if "Quantita prenotata" < Quantity then
            "Stato Riga" := 'Gestito Parzialmente'
        else if "Quantita prenotata" >= Quantity then
            "Stato Riga" := 'Gestito Totale';
    end;
}
