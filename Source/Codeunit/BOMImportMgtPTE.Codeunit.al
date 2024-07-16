codeunit 50002 "BOM Import Mgt. PTE"
{
    var
        RActivityLog: Record "Activity Log";
        RInventorySetup: Record "Inventory Setup";
        CBase64: Codeunit "Base64 Convert";
        CCEA: Codeunit "CEA General PTE";
        CEIExp: Codeunit "Export FatturaPA Document FLE";
        CFileMgt: Codeunit "File Management";
        Lbl_DeLBOM: Label 'Cancellata riga distinta base produzione %1 - Articolo %2 UM %3 Qty per %4';
        LBL_Err1: Label 'Errore : Codice modello articolo %1 non trovato, impossibile creare articolo nr %2';
        LBL_Err3: Label 'Errore : materia prima nr "%1" non trovata in riga nr %2';
        Lbl_Err2: Label 'Errore : In riga nr. %1 il codice articolo "%2" supera la lunghezza massima di 20 caratteri';
        LBL_NewBOMH: Label 'Inserita nuova distinta base produzione  : %1';
        Lbl_NewBOML: Label 'Inserita nuova riga distinta base produzione %1 : Articolo %2 UM %3 Quantita per %4';
        Lbl_BOMUpdate: Label 'Aggiornata distinta produzione articolo conto lavoro nr %1';
        LBL_NewRoutingH: Label 'Inserita nuovo ciclo :  %1 ';
        Lbl_QtyPer: Label '"Quantità per" in distinta produzione nr %1 riga %2 aggiornata da "%3" ad "%4"';
        Lbl_Reopen: Label 'Stato in Distinta Base Nr. %1 Impostato come "In sviluppo"';
        LBLImportBOMContest: Label 'IMPORT BOM', Locked = true;
        ActivityMessage: Text;
        FileName: Text;
        LogMsg: Text;
        CRLF: Text[2];

    trigger OnRun()
    begin

    end;

    procedure ImportBOMFromCSVText(P_CSVContent: Text; P_Base64: Boolean; P_CSFileName: Text; var V_RActivityLog: Record "Activity Log");
    var
        L_CSVBuffer: Record "CSV Buffer" temporary;
        L_TempLines: Record "FLEX Work File FLE" temporary;
        L_RItem: Record Item;
        L_RBOM: Record "Production BOM Header";
        L_RRoutingH: Record "Routing Header";
        L_RSKU: Record "Stockkeeping Unit";
        L_OK: Boolean;
        L_WorkCenterNo: Code[20];
    begin
        ClearLastError();
        if not InitCSVBuffer(P_CSVContent, P_Base64, L_CSVBuffer) then begin
            Error('Impossibile elaborare il contenuto file', false);
        end;
        InitImportBOMLog();
        FileName := CFileMgt.GetFileNameWithoutExtension(FileName);
        // verifica dal articolo/variante da elaborare, in caso da segnare come errore
        if L_RItem.Get(FileName) then begin

            if L_RItem."Base Unit of Measure" = '' then begin
                L_RItem."Base Unit of Measure" := CCEA.GetDefalutUM();
                L_RItem.Modify();
            end;

        end else begin
            //TODO creazione articolo
        end;
        //assegno il log all'articolo 
        RActivityLog."Record ID" := L_RItem.RecordId;
        RActivityLog.Modify();
        // creo la DB
        if not L_RBOM.Get(L_RItem."No.") then begin
            ClearLastError();
            L_OK := F_CreateNewBOMH(L_RBOM, FileName, F_GetDesc());
            AddMsgLine(StrSubstNo(LBL_NewBOMH, FileName), L_OK);
            if not L_OK then begin
                V_RActivityLog.Get(RActivityLog.ID);
                exit;
            end;
        end;

        // creo il ciclo
        if not L_RRoutingH.Get(FileName) then begin
            ClearLastError();
            if (L_RItem."Replenishment System" = L_RItem."Replenishment System"::"Prod. Order") and (L_RItem."Item Category Code" <> CCEA.GetDefaultCLItemCategoryCode) then
                L_WorkCenterNo := CCEA.GetDefaultWorkCenterCode();
            L_OK := F_CreateNewRoutingH(L_RRoutingH, FileName, F_GetDesc(), L_WorkCenterNo);
            AddMsgLine(StrSubstNo(LBL_NewRoutingH, FileName), L_OK);
            if not L_OK then begin
                V_RActivityLog.Get(RActivityLog.ID);
                exit;
            end;
        end;
        // verifico lo stato se rilasciata 
        if L_RBOM.Status = L_RBOM.Status::Certified then begin
            AddMsgLine('Attenzione : La distinta base produzione nr. ' + L_RBOM."No." + ' è certificata. Prima di procedere aggiornare lo stato come "In sviluppo"', true);
            exit;
        end;
        //Raggruppo per item no
        // in questa funzione inserirsco / aggiorno anagrafica articoli
        F_GroupChangesByItem(L_CSVBuffer, L_TempLines);
        // elaboro le righe conto lavoro
        F_ElabCLLines(L_TempLines);
        L_TempLines.Reset();
        // elaboro le righe della distinta 
        F_UpdateBOMLines(L_TempLines);

        if RActivityLog."Record ID".TableNo = Database::Item then begin
            ClearLastError();
            L_OK := F_ValidateItem(L_RItem, L_RBOM, L_RRoutingH);
            if not L_OK then
                AddMsgLine('Impossibile assegnare distinta e ciclo ad articolo nr. ' + L_RItem."No.", false);
        end;
        V_RActivityLog.Get(RActivityLog.ID);
        V_RActivityLog.Status := V_RActivityLog.Status::Success;
        V_RActivityLog.Modify();
    end;

    [TryFunction]
    local procedure F_AddSKU(P_RVariant: Record "Item Variant"; var V_RSKU: Record "Stockkeeping Unit")
    var
        L_RItem: Record Item;
    begin
        if not V_RSKU.Get(CCEA.GetDefaultLocationCode, P_RVariant."Item No.", P_RVariant.Code) then begin
            L_RItem.Get(P_RVariant."Item No.");
            V_RSKU.Init();
            V_RSKU.Validate("Location Code", CCEA.GetDefaultLocationCode());
            V_RSKU.Validate("Item No.", P_RVariant."Item No.");
            V_RSKU.Validate("Variant Code", P_RVariant.Code);
            V_RSKU.Insert(true);
            // flowfield L_RSKU.Validate(Description, F_GetDesc());
            V_RSKU.CopyFromItem(L_RItem);
        end;
        V_RSKU.Validate("Replenishment System", V_RSKU."Replenishment System"::"Prod. Order");
        V_RSKU.Validate("Production BOM No.", FileName);
        V_RSKU.Validate("Routing No.", FileName);
        V_RSKU.Modify(true);
    end;

    local procedure InitImportBOMLog();
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        LogMsg := '';
        RActivityLog."Activity Date" := CurrentDateTime;
        RActivityLog."User ID" := UserId;
        RActivityLog.Status := RActivityLog.Status::Failed;
        RActivityLog.Context := GETImportBOMContext;
        RActivityLog.Description := FileName;
        RActivityLog."Activity Message" := '';
        RActivityLog."Table No Filter" := Database::"Item";
        RActivityLog.Insert(true);
        Commit;
    end;

    [TryFunction]
    local procedure InitCSVBuffer(P_CSVContent: Text; P_Base64: Boolean; var V_CSVBuffer: Record "CSV Buffer" temporary)
    var
        L_TempBLOB: Codeunit "Temp Blob";
        L_InStream: InStream;
        L_OutStream: OutStream;
        L_FileDialogTxt: Label 'Allegati (%1)|%1', Locked = true;
        L_Filter: Label '*.CSV', Locked = true;
        L_ImportTxt: Label 'Seleziona File', Locked = true;
        L_Content: Text;
        L_Text: Text;
    begin
        Clear(V_CSVBuffer);
        V_CSVBuffer.DeleteAll();
        if P_CSVContent <> '' then begin
            L_TempBLOB.CreateOutStream(L_OutStream);
            if P_Base64 then
                P_CSVContent := CBase64.FromBase64(P_CSVContent);
            L_OutStream.WriteText(P_CSVContent);
            L_TempBLOB.CreateInStream(L_InStream);
        end else begin
            if not GuiAllowed then
                Error('Interfaccia utente richiesta');
            if not UploadIntoStream(L_ImportTxt, '', StrSubstNo(L_FileDialogTxt, L_Filter), FileName, L_InStream) then
                Error('File non selezionato');
        end;
        V_CSVBuffer.LoadDataFromStream(L_InStream, ',');
        // cancello la prima riga
        V_CSVBuffer.FindFirst();
    end;

    local procedure F_GroupChangesByItem(var V_CSVBuffer: Record "CSV Buffer" temporary; var V_TempLines: Record "FLEX Work File FLE" temporary): Boolean;
    var
        L_TempLines: Record "FLEX Work File FLE" temporary;
        L_RUM: Record "Unit of Measure";
        L_Key: Integer;
        L_Debug: Boolean;
        L_BOnlyMP: Boolean;
        L_Deleted: Boolean;
    begin
        //  1   N°                        Order
        //  2   T - Articolo distinta     Code01
        //  3   Nr.                       Code02
        //  4   Um                        Code03
        //  5   Descrizione               Text01
        //  6   Sistema di rifornimento   opt01
        //  7   Codice categoria articolo Code04
        //  8   Cod sottogruppo           Code05
        //  9   Kit                       Bool01
        //  10  Ricambio                  Bool01
        //  11  Quantità per              Number01
        //  12  MP_Nr.                    Code06
        //  13  MP_Um                     Code07
        //  14  MP_Peso                   Number02
        //  15  MP_Materiale              Text02
        V_TempLines.Reset();
        V_TempLines.DeleteAll();
        // intestazione
        V_CSVBuffer.SetRange("Line No.", 1);
        V_CSVBuffer.DeleteAll();
        V_CSVBuffer.Reset;
        if not V_CSVBuffer.FindSet() then
            exit(false);
        repeat
            if L_TempLines.Key <> V_CSVBuffer."Line No." then begin
                L_TempLines.Init();
                L_TempLines.Key := V_CSVBuffer."Line No.";
                L_TempLines.Insert;
                L_TempLines.Int10 := V_CSVBuffer."Line No.";
            end;
            case V_CSVBuffer."Field No." of
                1:
                    L_TempLines.Order := V_CSVBuffer.Value;
                2:
                    L_TempLines.Code01 := V_CSVBuffer.Value;
                3:
                    L_TempLines.Code02 := V_CSVBuffer.Value;
                4:
                    if L_RUM.Get(V_CSVBuffer.Value) then
                        L_TempLines.Code03 := V_CSVBuffer.Value
                    else begin
                        AddMsgLine('"UM"  non riconosciuto in riga ' + Format(V_CSVBuffer."Line No."), true);
                        L_TempLines.Code03 := CCEA.GetDefalutUM();
                    end;

                5:
                    L_TempLines.Text01 := CEIExp.EI_WindowsToASCII(V_CSVBuffer.Value, true);
                6:
                    begin
                        case V_CSVBuffer.Value of
                            'Acquisto':
                                L_TempLines.Opt01 := 0;
                            'Ordine di produzione':
                                L_TempLines.Opt01 := 1;
                            'Assemblaggio':
                                L_TempLines.Opt01 := 2
                            else
                                AddMsgLine('"Sistema di rifornimento"  non riconosciuto in riga ' + Format(V_CSVBuffer."Line No."), true);
                        end;

                    end;
                7:
                    L_TempLines.Code04 := V_CSVBuffer.Value;
                8:
                    L_TempLines.Code05 := V_CSVBuffer.Value;
                9:
                    if UpperCase(V_CSVBuffer.Value) = 'SI' then
                        L_TempLines.Bool01 := true;
                10:
                    if UpperCase(V_CSVBuffer.Value) = 'SI' then
                        L_TempLines.Bool02 := true;
                11:
                    if not Evaluate(L_TempLines.Num01, V_CSVBuffer.Value, 9) then
                        AddMsgLine('"Quantita per" non riconosciuta in riga ' + Format(V_CSVBuffer."Line No."), true);
                12:
                    begin
                        L_TempLines.Code06 := V_CSVBuffer.Value;
                        // if L_TempLines.Code06 = '5242' then
                        //     L_Debug := true;
                    end;
                13:
                    L_TempLines.Code07 := V_CSVBuffer.Value;
                14:
                    if not Evaluate(L_TempLines.Num02, V_CSVBuffer.Value, 9) then
                        AddMsgLine('"Peso" non riconosciuta in riga ' + Format(V_CSVBuffer."Line No."), true);
                15:
                    L_TempLines.Text02 := V_CSVBuffer.Value;
            end;
            L_TempLines.Modify();
        until V_CSVBuffer.Next() = 0;
        AddMsgLine('Totale righe analizzate ' + Format(L_TempLines.Count), true);
        // elimino codice articolo troppo lunghi
        L_TempLines.Reset();
        if not L_TempLines.FindSet() then
            exit(false);
        repeat
            L_Deleted := false;
            if StrLen(L_TempLines.Code02) > 20 then begin
                AddMsgLine(StrSubstNo(Lbl_Err2, Format(L_TempLines.Int10), L_TempLines.Code02), true);
                L_TempLines.Delete();
                L_Deleted := true;
            end;
            // ordine produzione & conto lavoro & MP_Nr. = ''
            if (L_TempLines.Opt01 = 1) and (L_TempLines.Code04 <> 'CL') and (L_TempLines.Code06 = '') and (not L_Deleted) then
                L_TempLines.Delete();
        until L_TempLines.Next() = 0;
        L_TempLines.FindSet();
        L_Key := 1;
        RInventorySetup.SetLoadFields("Default Costing Method");
        RInventorySetup.Get();
        repeat
            // se ordine di produzione e non conto lavoro -->
            // non devo importare l'articolo e la riga di distinta ma devo importare la materia prima
            if (L_TempLines.Opt01 = 1) and (L_TempLines.Code04 <> 'CL') then
                L_BOnlyMP := true
            else
                L_BOnlyMP := false;
            if not L_BOnlyMP then begin
                V_TempLines.Reset();
                V_TempLines.SetRange(Code02, L_TempLines.Code02);
                V_TempLines.SetRange(Code03, L_TempLines.Code03);
                if not V_TempLines.FindFirst() then begin
                    V_TempLines.Init();
                    V_TempLines.AddRecord(L_Key);
                    V_TempLines.Order := L_TempLines.Order;
                    V_TempLines.Code01 := '';
                    V_TempLines.Code02 := L_TempLines.Code02;
                    V_TempLines.Code03 := L_TempLines.Code03;
                    V_TempLines.Text01 := L_TempLines.Text01;
                    V_TempLines.Opt01 := L_TempLines.Opt01;
                    V_TempLines.Code04 := L_TempLines.Code04;
                    V_TempLines.Code05 := L_TempLines.Code05;
                    V_TempLines.Bool01 := L_TempLines.Bool01;
                    V_TempLines.Bool02 := L_TempLines.Bool02;
                    V_TempLines.Num01 := L_TempLines.Num01;
                    F_CheckItemUpdate(V_TempLines);
                end else begin
                    V_TempLines.Num01 += L_TempLines.Num01;
                    V_TempLines.Modify();
                end;
                V_TempLines.Modify();
            end;
            //materia prima
            if F_CheckItemMateriaPrima(L_TempLines) then begin
                // conto lavoro
                // V_TempLines.Code01 = nuova distinta
                if L_TempLines.Code04 = 'CL' then begin
                    V_TempLines.Reset();
                    V_TempLines.SetRange(Code01, L_TempLines.Code02);
                    if not V_TempLines.FindFirst() then begin
                        V_TempLines.Init();
                        V_TempLines.AddRecord(L_Key);
                        V_TempLines.Order := L_TempLines.Order;
                        V_TempLines.Code01 := L_TempLines.Code02;
                        V_TempLines.Code02 := L_TempLines.Code06;
                        V_TempLines.Code03 := L_TempLines.Code07;
                        V_TempLines.Code04 := 'MP';
                        V_TempLines.Text01 := L_TempLines.Text02;
                        V_TempLines.Num01 := L_TempLines.Num02;
                        V_TempLines.Modify();
                    end;
                end else begin
                    // artcoli materia prima normali
                    // V_TempLines.Code01 = distinta articolo importato
                    V_TempLines.Reset();
                    V_TempLines.SetRange(Code02, L_TempLines.Code06);
                    V_TempLines.SetRange(Code03, L_TempLines.Code07);
                    if not V_TempLines.FindFirst() then begin
                        V_TempLines.Init();
                        V_TempLines.AddRecord(L_Key);
                        V_TempLines.Order := L_TempLines.Order;
                        V_TempLines.Code01 := '';
                        V_TempLines.Code02 := L_TempLines.Code06;
                        V_TempLines.Code03 := L_TempLines.Code07;
                        V_TempLines.Code04 := 'MP';
                        V_TempLines.Text01 := L_TempLines.Text02;
                        V_TempLines.Num01 := (L_TempLines.Num01 * L_TempLines.Num02); //Qty per * Peso
                        V_TempLines.Modify();
                    end else begin
                        V_TempLines.Num01 += (L_TempLines.Num01 * L_TempLines.Num02); //Qty per * Peso
                        V_TempLines.Modify();
                    end;
                end;
            end;
        until L_TempLines.Next = 0;
        V_TempLines.Reset();
    end;

    procedure AddMsgLine(P_Msg: Text; P_SkipError: Boolean)
    begin
        if ActivityMessage <> '' then
            ActivityMessage += CRLF;
        if not P_SkipError then begin
            ActivityMessage += ' - Errore : ' + P_Msg;
            if GetLastErrorText <> '' then
                ActivityMessage += CRLF + ' - - ' + GetLastErrorText();
        end else
            ActivityMessage += ' - ' + P_Msg;
        RActivityLog."Activity Message" := CopyStr(ActivityMessage, 1, MaxStrLen(RActivityLog."Activity Message"));
        if StrLen(ActivityMessage) > MaxStrLen(RActivityLog."Activity Message") then
            RActivityLog.SetDetailedInfoFromText(ActivityMessage);
        RActivityLog.Modify();
        Commit();
    end;

    [TryFunction]
    local procedure F_CreateNewBOMH(var V_RBOM: Record "Production BOM Header"; P_No: Code[20]; P_Desc: Text)
    begin
        V_RBOM.Init;
        V_RBOM.Validate("No.", P_No);
        V_RBOM.Insert(true);
        V_RBOM."Unit of Measure Code" := F_GetUM();
        V_RBOM.Validate(Description, CopyStr(P_Desc, 1, MaxStrLen(V_RBOM.Description)));
        V_RBOM.Status := V_RBOM.Status::New;
        V_RBOM.Modify();
    end;

    [TryFunction]
    local procedure F_CreateNewRoutingH(var V_RRoutingH: Record "Routing Header"; P_No: Code[20]; P_Desc: Text; P_WorkCenter: Code[20])
    var
        L_RRoutingL: Record "Routing Line";
    begin
        V_RRoutingH.Init;
        V_RRoutingH.Validate("No.", P_No);
        V_RRoutingH.Insert(true);
        V_RRoutingH.Type := V_RRoutingH.Type::Serial;
        V_RRoutingH.Status := V_RRoutingH.Status::New;
        V_RRoutingH.Validate(Description, CopyStr(P_Desc, 1, MaxStrLen(V_RRoutingH.Description)));
        V_RRoutingH.Modify();
        L_RRoutingL."Routing No." := V_RRoutingH."No.";
        L_RRoutingL."Operation No." := CCEA.GetDefaultOperationNo;
        L_RRoutingL.Insert(false);
        L_RRoutingL.Validate(Type, L_RRoutingL.Type::"Work Center");
        if P_WorkCenter <> '' then
            L_RRoutingL.Validate("No.", P_WorkCenter);
        L_RRoutingL.Validate("Routing Link Code", CCEA.GetDefalutRoutingLink());
        L_RRoutingL.Modify(false);
    end;

    local procedure F_GetUM() O_Code: Code[20];
    var
        L_RItem: Record Item;
        L_RVariant: Record "Item Variant";
    begin
        case RActivityLog."Record ID".TableNo of
            Database::Item:
                begin
                    RActivityLog."Record ID".GetRecord.SetTable(L_RItem);
                    O_Code := L_RItem."Base Unit of Measure";
                end;
            Database::"Item Variant":
                begin
                    RActivityLog."Record ID".GetRecord.SetTable(L_RVariant);
                    if L_RItem.Get(L_RVariant."Item No.") then
                        O_Code := L_RItem."Base Unit of Measure";
                end;
        end;
        if O_Code = '' then
            exit(CCEA.GetDefalutUM());
    end;

    local procedure F_GetDesc(): Text
    var
        L_RItem: Record Item;
        L_RVariant: Record "Item Variant";
    begin
        // TODO _ Da rifare
        case RActivityLog."Record ID".TableNo of
            Database::Item:
                begin
                    RActivityLog."Record ID".GetRecord.SetTable(L_RItem);
                    exit(L_RItem.Description);
                end;
            Database::"Item Variant":
                begin
                    RActivityLog."Record ID".GetRecord.SetTable(L_RVariant);
                    if L_RItem.Get(L_RVariant."Item No.") then
                        exit(L_RItem.Description);
                end;
            else
                Error(Format(RActivityLog."Record ID") + ' non supportato.');
        end;
    end;

    procedure GETImportBOMContext(): Text
    begin
        exit(LBLImportBOMContest);
    end;

    local procedure F_CheckItemUpdate(P_TempLines: Record "FLEX Work File FLE" temporary);
    var
        L_RItem: Record Item;
        L_OK: Boolean;
        L_Text: Text;
    begin
        // se non esiste creo l'articolo
        if not L_RItem.Get(P_TempLines.Code02) then begin
            ClearLastError();
            L_OK := F_CreateNewItem(P_TempLines, L_RItem);
            AddMsgLine('Nuovo articolo creato : ' + L_RItem."No.", L_OK);
            ClearLastError();
            if not F_ApplytemTemplate(P_TempLines, L_RItem) then
                AddMsgLine('Applicazione template  ' + P_TempLines.Code04 + ' in ' + L_RItem."No.", false);
        end;
        ClearLastError();
        // materia prima non aggiorno la descrizione
        if P_TempLines.Code04 <> 'MP' then begin
            L_Text := L_RItem.Description;
            L_OK := F_UpdateItem(P_TempLines, L_RItem);
            if (not L_OK) or (L_Text <> P_TempLines.Text01) then
                AddMsgLine('Aggiornata descrizione articolo nr. ' + L_RItem."No.", true);
        end;
    end;

    [TryFunction]
    local procedure F_CreateNewItem(P_TempLines: Record "FLEX Work File FLE" temporary; var V_RItem: Record Item);
    var
    begin
        V_RItem.Init();
        V_RItem."No." := P_TempLines.Code02;
        V_RItem."Costing Method" := RInventorySetup."Default Costing Method";
        V_RItem.Insert(true);
    end;

    [TryFunction]
    local procedure F_ApplytemTemplate(P_TempLines: Record "FLEX Work File FLE" temporary; var V_RItem: Record Item);
    var
        L_RItemTempl: Record "Item Templ.";
        L_CItemTmpMgt: Codeunit "Item Templ. Mgt.";
    begin
        if not L_RItemTempl.Get(P_TempLines.Code04) then begin
            Error(StrSubstNo(LBL_Err1, P_TempLines.Code04, P_TempLines.Code02), true);
            exit;
        end;
        L_CItemTmpMgt.ApplyItemTemplate(V_RItem, L_RItemTempl, true);
        V_RItem.Modify(true);
    end;

    [TryFunction]
    local procedure F_UpdateItem(P_TempLines: Record "FLEX Work File FLE" temporary; var V_RItem: Record Item);
    var
        L_Modify: Boolean;
    begin
        if (P_TempLines.Code03 <> '') and (P_TempLines.Code03 <> V_RItem."Base Unit of Measure") then begin
            V_RItem.Validate("Base Unit of Measure", P_TempLines.Code03);
            L_Modify := true;
        end;

        if (V_RItem.Description <> P_TempLines.Text01) and (V_RItem."Item Category Code" <> 'MP') and (P_TempLines.Text01 <> '') then begin
            V_RItem.Validate(Description, CopyStr(P_TempLines.Text01, 1, MaxStrLen(V_RItem.Description)));
            L_Modify := true;
        end;
        if P_TempLines.Opt01 <> V_RItem."Replenishment System".AsInteger() then begin
            V_RItem.Validate("Replenishment System", P_TempLines.Opt01);
            L_Modify := true;
        end;
        if L_Modify then
            V_RItem.Modify(true);
    end;

    local procedure F_CheckItemMateriaPrima(P_TempLines: Record "FLEX Work File FLE" temporary): Boolean;
    var
        L_RItem: Record Item;
    begin
        if P_TempLines.Code06 = '' then
            exit(false);
        if L_RItem.Get(P_TempLines.Code06) then
            exit(true);
        AddMsgLine(StrSubstNo(LBL_Err3, P_TempLines.Code06, P_TempLines.Int10), true);
        exit(false);
    end;

    local procedure F_UpdateBOMLines(var V_TempLines: Record "FLEX Work File FLE" temporary);
    var
        L_RBOM: Record "Production BOM Header";
        L_RBomLine: Record "Production BOM Line";
        L_OK: Boolean;
        L_LineNo: Decimal;
        L_Qty: Decimal;
    begin
        // elaboro le righe della BOM
        L_RBOM.Get(FileName);
        L_RBomLine.SetRange("Production BOM No.", FileName);
        L_RBomLine.SetRange("Version Code", '');
        // elimino le righe non articolo
        L_RBomLine.SetFilter(Type, '%1|%2', L_RBomLine.Type::"Production BOM", L_RBomLine.Type::" ");
        L_RBomLine.DeleteAll();
        L_RBomLine.SetRange(Type);
        // elaboro le modifiche 
        if L_RBomLine.FindSet() then
            repeat
                V_TempLines.SetRange(Code02, L_RBomLine."No.");
                V_TempLines.SetRange(Code03, L_RBomLine."Unit of Measure Code");
                if V_TempLines.FindFirst() then begin
                    // verifico update
                    if F_BomLineCheckChanges(L_RBomLine, V_TempLines) then begin
                        // riapro la testata
                        if L_RBOM.Status in [L_RBOM.Status::Closed] then begin
                            ClearLastError();
                            AddMsgLine(StrSubstNo(Lbl_Reopen, L_RBOM."No."), F_OpenBOM(L_RBOM));
                        end;
                        // aggiorno la riga di DB
                        ClearLastError();
                        L_Qty := L_RBomLine."Quantity per";
                        L_OK := F_UpdateBomLine(L_RBomLine, V_TempLines);
                        if (not L_OK) or (L_Qty <> V_TempLines.Num01) then
                            AddMsgLine(StrSubstNo(Lbl_QtyPer, L_RBomLine."Production BOM No.", L_RBomLine."Line No.", L_Qty, V_TempLines.Num01), true);
                    end;
                    V_TempLines.Delete();
                end else begin
                    // se non trovo la riga di distinta la devo eliminare - per adesso le marko
                    L_RBomLine.Mark(true);
                end;
            until L_RBomLine.Next() = 0;
        //elimino le righe in ecceso
        L_RBomLine.MarkedOnly(true);
        if L_RBomLine.FindSet() then
            repeat
                AddMsgLine(StrSubstNo(Lbl_DeLBOM, L_RBomLine."Production BOM No.", L_RBomLine."No.", L_RBomLine."Unit of Measure Code", L_RBomLine."Quantity per"), true);
                L_RBomLine.Delete(true);
            until L_RBomLine.Next = 0;
        // inserisco le nuove righe
        L_RBomLine.MarkedOnly(false);
        V_TempLines.SetRange(Code02);
        V_TempLines.SetRange(Code03);
        if L_RBomLine.FindLast() then
            L_LineNo := L_RBomLine."Line No.";
        if V_TempLines.FindSet() then
            repeat
                L_RBomLine.Init();
                L_RBomLine."Production BOM No." := FileName;
                L_RBomLine."Version Code" := '';
                L_LineNo += 10000;
                L_RBomLine."Line No." := L_LineNo;
                L_RBomLine.Insert(true);
                ClearLastError();
                L_OK := F_CalcNewBomLine(V_TempLines, L_RBomLine);
                AddMsgLine(StrSubstNo(Lbl_NewBOML, L_RBomLine."Production BOM No.", L_RBomLine."No.", L_RBomLine."Unit of Measure Code", L_RBomLine."Quantity per"), L_OK);
            until V_TempLines.Next() = 0;
    end;

    local procedure F_ElabCLLines(var V_TempLines: Record "FLEX Work File FLE" temporary);
    var
        L_RItem: Record Item;
        L_RItemMP: Record Item;
        L_RBOM: Record "Production BOM Header";
        L_RBomLine: Record "Production BOM Line";
        L_RBomLine2: Record "Production BOM Line";
        L_RRoutingH: Record "Routing Header";
        L_OK: Boolean;
        L_Skip: Boolean;
        L_Debug: Boolean;
    begin
        V_TempLines.Reset();
        V_TempLines.SetFilter(Code01, '<>%1', '');
        if not V_TempLines.FindSet() then
            exit;
        // per ogniuno di questi articoli devo creare/aggiornare la distinta con il materiale loro
        repeat
            L_Skip := false;
            if not L_RItem.Get(V_TempLines.Code01) then begin
                AddMsgLine('Articolo nr. ' + L_RItem."No." + ' non trovato.', true);
                L_Skip := true;
            end;
            // if L_RItem."No." = 'C13-E-295-DX' then
            //     L_Debug := true; //test
            if not L_RItemMP.Get(V_TempLines.Code02) then begin
                AddMsgLine('Articolo nr. ' + L_RItemMP."No." + ' non trovato.', true);
                L_Skip := true;
            end;
            if not L_Skip then begin
                if (L_RItem."Production BOM No." = '') or (not L_RBOM.Get(L_RItem."Production BOM No.")) then begin
                    // creo la DB
                    if not L_RBOM.Get(L_RItem."No.") then begin
                        ClearLastError();
                        L_OK := F_CreateNewBOMH(L_RBOM, L_RItem."No.", L_RItem.Description);
                        AddMsgLine(StrSubstNo(LBL_NewBOMH, L_RItem."No."), L_OK);
                        if not L_OK then
                            exit;
                    end;
                end;
                if (L_RItem."Routing No." = '') or (not L_RRoutingH.Get(L_RItem."Routing No.")) then begin
                    // creo il ciclo
                    if not L_RRoutingH.Get(L_RItem."No.") then begin
                        ClearLastError();
                        L_OK := F_CreateNewRoutingH(L_RRoutingH, L_RItem."No.", L_RItem.Description, '');
                        AddMsgLine(StrSubstNo(LBL_NewRoutingH, L_RItem."No."), L_OK);
                        if not L_OK then
                            exit;
                    end;
                end;
                L_RBomLine.SetRange("Production BOM No.", L_RBOM."No.");
                if L_RBomLine.FindFirst() then begin
                    if F_BomLineCheckChanges(L_RBomLine, V_TempLines) then begin
                        if L_RBOM.Status in [L_RBOM.Status::Closed, L_RBOM.Status::Certified] then begin
                            ClearLastError();
                            AddMsgLine(StrSubstNo(Lbl_Reopen, L_RBOM."No."), F_OpenBOM(L_RBOM));
                        end;
                        ClearLastError();
                        AddMsgLine(StrSubstNo(Lbl_BOMUpdate, L_RBOM."No."), F_UpdateBomLine(L_RBomLine, V_TempLines));
                        // tengo solo la prima riga
                        L_RBomLine2.SetRange("Production BOM No.", L_RBomLine."Production BOM No.");
                        L_RBomLine2.SetRange("Version Code", L_RBomLine."Version Code");
                        L_RBomLine2.SetFilter("Line No.", '<> %1', L_RBomLine."Line No.");
                        L_RBomLine2.DeleteAll();
                    end;
                end else begin
                    if L_RBOM.Status in [L_RBOM.Status::Closed, L_RBOM.Status::Certified] then begin
                        ClearLastError();
                        AddMsgLine(StrSubstNo(Lbl_Reopen, L_RBOM."No."), F_OpenBOM(L_RBOM));
                    end;
                    L_RBomLine.Init();
                    L_RBomLine."Production BOM No." := L_RBOM."No.";
                    L_RBomLine."Version Code" := '';
                    L_RBomLine."Line No." := 10000;
                    L_RBomLine.Insert(true);
                    ClearLastError();
                    L_OK := F_CalcNewBomLine(V_TempLines, L_RBomLine);
                    AddMsgLine(StrSubstNo(Lbl_NewBOML, L_RBomLine."Production BOM No.", L_RBomLine."No.", L_RBomLine."Unit of Measure Code", L_RBomLine."Quantity per"), L_OK);
                end;
                ClearLastError();
                L_OK := F_ValidateItem(L_RItem, L_RBOM, L_RRoutingH);
                if not L_OK then
                    AddMsgLine('Impossibile assegnare distinta e ciclo ad articolo nr. ' + L_RItem."No.", false);
                V_TempLines.Delete();
            end;
        until V_TempLines.Next() = 0;
    end;

    local procedure F_BomLineCheckChanges(P_RBomLine: Record "Production BOM Line"; P_TempLines: Record "FLEX Work File FLE" temporary): Boolean;
    begin
        if P_RBomLine."No." <> P_TempLines.Code02 then
            exit(true);
        if P_TempLines.Code03 <> 'MP' then
            if P_RBomLine.Description <> P_TempLines.Text01 then
                exit(true);
        if P_RBomLine."Quantity per" <> P_TempLines.Num01 then
            exit(true);
        exit(false);
    end;

    [TryFunction]
    local procedure F_UpdateBomLine(var V_RBomLine: Record "Production BOM Line"; P_TempLines: Record "FLEX Work File FLE" temporary);
    var
        L_BValidate: Boolean;
    begin
        if V_RBomLine.Type <> V_RBomLine.Type::Item then
            V_RBomLine.Validate(Type, V_RBomLine.Type::Item);
        if V_RBomLine."No." <> P_TempLines.Code02 then begin
            V_RBomLine.Validate("No.", P_TempLines.Code02);
            L_BValidate := true;
        end;
        if (V_RBomLine."Unit of Measure Code" <> P_TempLines.Code03) and (P_TempLines.Code03 <> '') then begin
            V_RBomLine.Validate("Unit of Measure Code", P_TempLines.Code03);
            L_BValidate := true;
        end;
        if P_TempLines.Code03 <> 'MP' then
            if V_RBomLine.Description <> P_TempLines.Text01 then
                V_RBomLine.Validate(Description, CopyStr(P_TempLines.Text01, 1, MaxStrLen(V_RBomLine.Description)));
        if (V_RBomLine."Quantity per" <> P_TempLines.Num01) or L_BValidate then
            V_RBomLine.Validate("Quantity per", P_TempLines.Num01);
        if (V_RBomLine."Routing Link Code" <> CCEA.GetDefalutRoutingLink()) or L_BValidate then
            V_RBomLine.Validate(V_RBomLine."Routing Link Code", CCEA.GetDefalutRoutingLink());
        V_RBomLine.Modify(true);
    end;

    [TryFunction]
    local procedure F_OpenBOM(var V_RBOM: Record "Production BOM Header")
    begin
        V_RBOM.Validate(Status, V_RBOM.Status::"Under Development");
        V_RBOM.Modify(true);
    end;

    [TryFunction]

    local procedure F_ValidateItem(var V_RItem: Record Item; P_RBOM: Record "Production BOM Header"; P_RRoutingH: Record "Routing Header")
    var
        L_Modify: Boolean;
    begin
        if (V_RItem."Production BOM No." <> P_RBOM."No.") and (P_RBOM."No." <> '') then begin
            V_RItem.Validate("Production BOM No.", P_RBOM."No.");
            L_Modify := true;
        end;
        if (V_RItem."Routing No." <> P_RRoutingH."No.") and (P_RRoutingH."No." <> '') then begin
            V_RItem.Validate("Routing No.", P_RRoutingH."No.");
            L_Modify := true;
        end;
        if L_Modify then
            V_RItem.Modify(true);
        if V_RItem.Description <> P_RBOM.Description then begin
            P_RBOM.Description := V_RItem.Description;
            P_RBOM.Modify(false);
        end;
        if V_RItem.Description <> P_RRoutingH.Description then begin
            P_RRoutingH.Description := V_RItem.Description;
            P_RRoutingH.Modify(false);
        end;
    end;

    [TryFunction]
    local procedure F_CalcNewBomLine(P_TempLines: Record "FLEX Work File FLE" temporary; var V_RBomLine: Record "Production BOM Line")
    var
    begin
        V_RBomLine.Validate(Type, V_RBomLine.Type::Item);
        V_RBomLine.Validate("No.", P_TempLines.Code02);
        V_RBomLine.Validate("Unit of Measure Code", P_TempLines.Code03);
        V_RBomLine.Validate("Quantity per", P_TempLines.Num01);
        V_RBomLine.Validate("Routing Link Code", CCEA.GetDefalutRoutingLink());
        V_RBomLine.Modify();
    end;

}
