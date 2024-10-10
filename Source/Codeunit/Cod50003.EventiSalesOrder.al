codeunit 50003 "EventiSalesOrder"
{
    var
        LblMAIL: label 'MAIL-ORDINE', Locked = true;
        L_CSingleEvent: Codeunit "Single Events FLE";

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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", OnBeforeReleaseSalesDoc, '', false, false)]
    local procedure "Release Sales Document_OnBeforeReleaseSalesDoc"(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean; var SkipCheckReleaseRestrictions: Boolean; SkipWhseRequestOperations: Boolean)
    begin
        //Per ora su tutti i documenti
        SalesHeader.TestField("Shortcut Dimension 1 Code");
        SalesHeader.TestField("Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Print", OnBeforeDoPrintSalesHeader, '', false, false)]
    local procedure "Document-Print_OnBeforeDoPrintSalesHeader"(var SalesHeader: Record "Sales Header"; ReportUsage: Integer; SendAsEmail: Boolean; var IsPrinted: Boolean)
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            L_CSingleEvent.SetText(LblMAIL, SalesHeader."No.");
    end;



    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeSendRecords, '', false, false)]
    local procedure "Purchase Header_OnBeforeSendRecords"(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            L_CSingleEvent.SetText(LblMAIL, PurchaseHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, OnFindRelatedAttachments, '', false, false)]
    local procedure Email_OnFindRelatedAttachments(SourceTableId: Integer; SourceSystemID: Guid; var EmailRelatedAttachments: Record "Email Related Attachment" temporary)
    var
        L_CIEvent: Codeunit "Single Events FLE";
        L_DocNo: Text;
        L_RSalesL: record "Sales Line";
        L_RPurchL: Record "Purchase Line";
        L_RDocAtt: record "Document Attachment";
        Temp_LBuffer: record "Name/Value Buffer" temporary;
    begin
        // inserisco allegati articoli come allegati selezionabili in anteprima mail ordini 
        L_DocNo := L_CIEvent.GetTextAndDelete(LblMAIL);
        if L_DocNo = '' then
            exit;
        L_RDocAtt.SetRange("Table ID", Database::Item);
        // ordini vendita
        L_RSalesL.SetRange("Document Type", L_RSalesL."Document Type"::Order);
        L_RSalesL.SetRange("Document No.", L_DocNo);
        L_RSalesL.setrange(Type, L_RSalesL.Type::Item);
        L_RSalesL.SetFilter(Quantity, '<>0');
        if L_RSalesL.FindSet() then begin
            L_RDocAtt.SetRange("Document Flow Sales", true);
            repeat
                Temp_LBuffer.SetRange(Name, L_RSalesL."No.");
                if not Temp_LBuffer.FindFirst() then begin
                    L_RDocAtt.SetRange("No.", L_RSalesL."No.");
                    if L_RDocAtt.FindSet() then
                        repeat
                            EmailRelatedAttachments."Attachment Name" := L_RDocAtt."File Name" + '.' + L_RDocAtt."File Extension";
                            EmailRelatedAttachments."Attachment Table ID" := Database::"Document Attachment";
                            EmailRelatedAttachments."Attachment System ID" := L_RDocAtt.SystemId;
                            EmailRelatedAttachments."Type Document" := L_RDocAtt."Type Document";
                            EmailRelatedAttachments."Date Revision" := L_RDocAtt."Date Revision";
                            EmailRelatedAttachments.Revision := L_RDocAtt.Revision;
                            EmailRelatedAttachments.Insert();
                        until L_RDocAtt.Next() = 0;
                end;
                Temp_LBuffer.AddNewEntry(L_RSalesL."No.", '');
            until L_RSalesL.next = 0;
            L_RDocAtt.SetRange("Document Flow Sales");
        end;
        // ordini acquisto
        L_RPurchL.SetRange("Document Type", L_RPurchL."Document Type"::Order);
        L_RPurchL.SetRange("Document No.", L_DocNo);
        L_RPurchL.setrange(Type, L_RPurchL.Type::Item);
        L_RPurchL.SetFilter(Quantity, '<>0');
        if L_RPurchL.FindSet() then begin
            L_RDocAtt.SetRange("Document Flow Purchase", true);
            repeat
                Temp_LBuffer.SetRange(Name, L_RPurchL."No.");
                if not Temp_LBuffer.FindFirst() then begin
                    L_RDocAtt.SetRange("No.", L_RPurchL."No.");
                    if L_RDocAtt.FindSet() then
                        repeat
                            EmailRelatedAttachments."Attachment Name" := L_RDocAtt."File Name" + '.' + L_RDocAtt."File Extension";
                            EmailRelatedAttachments."Attachment Table ID" := Database::"Document Attachment";
                            EmailRelatedAttachments."Attachment System ID" := L_RDocAtt.SystemId;
                            EmailRelatedAttachments."Type Document" := L_RDocAtt."Type Document";
                            EmailRelatedAttachments."Date Revision" := L_RDocAtt."Date Revision";
                            EmailRelatedAttachments.Revision := L_RDocAtt.Revision;
                            EmailRelatedAttachments.Insert();
                        until L_RDocAtt.Next() = 0;
                end;
                Temp_LBuffer.AddNewEntry(L_RPurchL."No.", '');
            until L_RPurchL.next = 0;
        end;
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeEmailFileInternal', '', false, false)]
    // local procedure OnBeforeEmailFileInternal(var TempEmailItem: Record "Email Item" temporary; var HtmlBodyFilePath: Text[250]; var EmailSubject: Text[250]; var ToEmailAddress: Text[250]; var PostedDocNo: Code[20]; var EmailDocName: Text[250]; var HideDialog: Boolean; var ReportUsage: Integer; var IsFromPostedDoc: Boolean; var SenderUserID: Code[50]; var EmailScenario: Enum "Email Scenario"; var EmailSentSuccessfully: Boolean; var IsHandled: Boolean)
    // var
    //     L_RDocAttc: record "Document Attachment";
    //     L_OutStream: OutStream;
    //     L_CTempBLob: Codeunit "Temp Blob";
    // begin
    //     if PostedDocNo = '' then
    //         exit;
    //     L_RDocAttc.SetRange("No.", PostedDocNo);
    //     IF L_RDocAttc.FindSet() then
    //         repeat
    //             CLEAR(L_OutStream);
    //             CLEAR(L_CTempBLob);
    //             L_CTempBLob.CreateOutStream(L_OutStream);
    //             L_RDocAttc.ExportToStream(L_OutStream);
    //             TempEmailItem.AddAttachment(L_CTempBLob.CreateInStream, L_RDocAttc."File Name");
    //         until L_RDocAttc.Next() = 0;
    //     end;

}
