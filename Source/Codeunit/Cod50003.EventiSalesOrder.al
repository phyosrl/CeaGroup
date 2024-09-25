codeunit 50003 "EventiSalesOrder"
{
    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure AggiornaQuantitaPrenotataDopoInserimento(Rec: Record "Reservation Entry")
    begin
        AggiornaQuantitaPrenotata(Rec);
    end;


    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AggiornaQuantitaPrenotataDopoCancellazione(Rec: Record "Reservation Entry")
    begin
        AggiornaQuantitaPrenotata(Rec);
    end;

    local procedure AggiornaQuantitaPrenotata(Rec: Record "Reservation Entry")
    var
        SalesLine: Record "Sales Line";
    begin
        // Cerca il record di riga di vendita correlato
        SalesLine.SetRange("Document Type", Rec."Source Subtype");
        SalesLine.SetRange("Document No.", Rec."Source ID");
        SalesLine.SetRange("Line No.", Rec."Source Ref. No.");

        if SalesLine.FindFirst() then begin
            // Calcola il FlowField per aggiornarlo
            SalesLine.CalcFields("Reserved Quantity");

            // Aggiorna il campo Quantita prenotata con il valore del FlowField
            if SalesLine."Quantita prenotata" <> SalesLine."Reserved Quantity" then begin
                SalesLine."Quantita prenotata" := SalesLine."Reserved Quantity";
                SalesLine.Modify(false);
            end;

            // Verifica le condizioni per impostare lo Stato Riga
            if SalesLine."Quantita prenotata" = 0 then begin
                SalesLine."Stato Riga" := 'Da Gestire';
            end else if SalesLine."Quantita prenotata" < SalesLine.Quantity then begin
                SalesLine."Stato Riga" := 'Gestito Parzialmente';
            end else if SalesLine."Quantita prenotata" >= SalesLine.Quantity then begin
                SalesLine."Stato Riga" := 'Gestito Totale';
            end;
            SalesLine.Modify(false); // Salva le modifiche
        end;
    end;

}
