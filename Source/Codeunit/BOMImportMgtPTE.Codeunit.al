codeunit 50002 "BOM Import Mgt. PTE"
{
    TableNo = "FLEX Work File FLE";

    trigger OnRun()
    // codeunit.run serve da tryfuntion with rollback
    begin
        case Rec.Order of
            'CreateBOMH':
                begin
                    F_CreateBOMH(Rec);
                end;
            'CreateRoutingH':
                begin
                    F_CreateRoutingH(Rec);
                end;
            'CreateItem':
                begin
                    F_CreateItem(Rec);
                end;
            'ApplyItemTemplate':
                begin
                    F_ApplyItemTemplate(Rec);
                end;
            'UpdateBomLine':
                begin
                    F_UpdateBomLine(Rec);
                end;
            'UpdateItem':
                begin
                    F_UpdateItem(Rec);
                end;
            'OpenBOM':
                begin
                    F_OpenBOM(Rec);
                end;
            'ValidateItem':
                begin
                    F_ValidateItem(Rec);
                end;
            'CreateBOML':
                begin
                    F_CreateBOML(Rec);
                end;
            'GetNextNo':
                begin
                    F_GetNextNo(Rec);
                end;
            'CreateUM':
                begin
                    F_CreateUM(Rec);
                end;
            '':
                F_TEST();
        end
    end;

    var
        RActivityLog: Record "Activity Log";
        TempRec: Record "FLEX Work File FLE" temporary;
        RInventorySetup: Record "Inventory Setup";
        Ritem: Record Item;
        CBase64: Codeunit "Base64 Convert";
        CCEA: Codeunit "CEA General PTE";
        CEIExp: Codeunit "Export FatturaPA Document FLE";
        CFileMgt: Codeunit "File Management";
        Lbl_DeLBOM: Label 'Cancellata riga distinta base produzione %1 - Articolo %2 UM %3 Qty per %4';
        Lbl_Err2: Label 'Errore : In riga nr. %1 il codice articolo "%2" supera la lunghezza massima di 20 caratteri';
        LBL_NewBOMH: Label 'Inserita nuova distinta base produzione  : %1';
        Lbl_NewBOML: Label 'Inserita nuova riga distinta base produzione %1 : Articolo %2 UM %3 Quantita per %4';
        LBL_NewRoutingH: Label 'Inserita nuovo ciclo :  %1 ';
        Lbl_Reopen: Label 'Stato in Distinta Base Nr. %1 Impostato come "In sviluppo"';
        LBLImportBOMContest: Label 'IMPORT BOM', Locked = true;
        ActivityMessage: Text;
        FileName: Text;
        LogMsg: Text;
        CRLF: Text[2];

    procedure ImportBOMFromCSVText(P_CSVContent: Text; P_Base64: Boolean; P_CSFileName: Text; var V_RActivityLog: Record "Activity Log");
    var
        L_CSVBuffer: Record "CSV Buffer" temporary;
        L_TempLines: Record "FLEX Work File FLE" temporary;
        L_RBOM: Record "Production BOM Header";
        L_RRoutingH: Record "Routing Header";
        L_OK: Boolean;
    begin
        ClearLastError();
        FileName := P_CSFileName;
        if not InitCSVBuffer(P_CSVContent, P_Base64, L_CSVBuffer) then begin
            Error('Impossibile elaborare il contenuto file', false);
        end;
        if FileName = '' then
            error('Nome file deve avere un valore.');
        if CFileMgt.GetFileNameWithoutExtension(FileName) <> '' then
            FileName := CFileMgt.GetFileNameWithoutExtension(FileName);
        if StrLen(FileName) > 20 then
            Error('Nome file ' + FileName + 'maggiore di 20 caratteri');
        if FileName = '' then
            error('Nome file deve avere un valore.');
        InitImportBOMLog();
        // verifica dal articolo/variante da elaborare, 
        if not Ritem.Get(FileName) then begin
            ClearLastError();
            L_OK := CreateItem(CCEA.GetDefaultItemCategoryCode(), FileName, Ritem);
            AddMsgLine('Nuovo articolo creato : ' + FileName, L_OK);
            ClearLastError();
            if not ApplyItemTemplate(CCEA.GetDefaultItemCategoryCode(), Ritem) then
                AddMsgLine('Applicazione template  ' + CCEA.GetDefaultItemCategoryCode() + ' in ' + Ritem."No.", false);
        end;
        //assegno il log all'articolo 
        RActivityLog."Record ID" := Ritem.RecordId;
        RActivityLog.Modify();
        // creo la DB
        if not L_RBOM.Get(Ritem."No.") then begin
            ClearLastError();
            L_OK := CreateBOMH(L_RBOM, FileName, F_GetDesc());
            AddMsgLine(StrSubstNo(LBL_NewBOMH, FileName), L_OK);
            if not L_OK then begin
                V_RActivityLog.Get(RActivityLog.ID);
                exit;
            end;
        end;

        // creo il ciclo
        if not L_RRoutingH.Get(FileName) then begin
            ClearLastError();
            L_OK := CreateRoutingH(L_RRoutingH, FileName, F_GetDesc(), CCEA.GetDefaultWorkCenterCode());
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
        //Preparo un foglio di lavoro
        F_FillTempContent(L_CSVBuffer, L_TempLines);
        repeat // in questa funzione inserirsco / aggiorno anagrafica articoli
            F_CheckItem(L_TempLines);
        until L_TempLines.Next() = 0;
        // elaboro le righe con materia prima
        F_ElabMPLines(L_TempLines);
        L_TempLines.Reset();
        // elaboro le righe della distinta 
        F_UpdateBOMLines(L_TempLines);
        if RActivityLog."Record ID".TableNo = Database::Item then begin
            ClearLastError();
            L_OK := ValidateItem(Ritem, L_RBOM, L_RRoutingH);
            if not L_OK then
                AddMsgLine('Impossibile assegnare distinta e ciclo ad articolo nr. ' + Ritem."No.", false);
        end;
        V_RActivityLog.Get(RActivityLog.ID);
        V_RActivityLog.Status := V_RActivityLog.Status::Success;
        V_RActivityLog.Modify();
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
        RActivityLog."Table No Filter" := Database::Item;
        RActivityLog.Insert(true);
    end;

    [TryFunction]
    local procedure InitCSVBuffer(P_CSVContent: Text; P_Base64: Boolean; var V_CSVBuffer: Record "CSV Buffer" temporary)
    var
        L_TempBLOB: Codeunit "Temp Blob";
        L_InStream: InStream;
        L_FileDialogTxt: Label 'Allegati (%1)|%1', Locked = true;
        L_Filter: Label '*.CSV', Locked = true;
        L_ImportTxt: Label 'Seleziona File', Locked = true;
        L_OutStream: OutStream;
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
        V_CSVBuffer.LoadDataFromStream(L_InStream, ';');
        // cancello la prima riga
        V_CSVBuffer.FindFirst();
    end;

    local procedure F_FillTempContent(var V_CSVBuffer: Record "CSV Buffer" temporary; var V_TempLines: Record "FLEX Work File FLE" temporary): Boolean;
    var
        L_RItemTmpl: Record "Item Templ.";
    begin
        // 1    ITEM                Order //TODO da salvere sulla riga di BOM
        // 2    DESCRIZ IT          Text01
        // 3    DESCRIP EN          Text02
        // 4    TYPE                Txt01
        // 5    MATERIAL            txt02
        // 6    QTY                 Num01
        // 7    MASS                Num02
        // 8    Part  number        Code02
        // 9    BC - Template       Code03
        // 10   STOCK NUMBER        Code04
        // 11   BASE QTY            Num03
        // 12   BASE UNIT           Code05
        RInventorySetup.SetLoadFields("Default Costing Method");
        RInventorySetup.Get();
        V_CSVBuffer.SetRange("Line No.", 1);
        V_CSVBuffer.DeleteAll();
        V_CSVBuffer.Reset;
        if not V_CSVBuffer.FindSet() then
            exit(false);
        repeat
            if V_TempLines.Key <> V_CSVBuffer."Line No." then begin
                V_TempLines.Init();
                V_TempLines.Key := V_CSVBuffer."Line No.";
                V_TempLines.Insert;
                V_TempLines.Int10 := V_CSVBuffer."Line No.";
            end;
            case V_CSVBuffer."Field No." of
                1:
                    V_TempLines.Order := V_CSVBuffer.Value;
                2:
                    V_TempLines.Text01 := CopyStr(CEIExp.EI_WindowsToASCII(V_CSVBuffer.Value, true), 1, 100);
                3:
                    V_TempLines.Text02 := CopyStr(CEIExp.EI_WindowsToASCII(V_CSVBuffer.Value, true), 1, 50);
                4:
                    V_TempLines.Txt01 := CEIExp.EI_WindowsToASCII(V_CSVBuffer.Value, true);
                5:
                    V_TempLines.Txt02 := V_CSVBuffer.Value;
                6:
                    if V_CSVBuffer.Value <> '' then
                        if not Evaluate(V_TempLines.Num01, V_CSVBuffer.Value) then
                            AddMsgLine('"Quantita" non riconosciuta in riga ' + Format(V_CSVBuffer."Line No."), true);
                7:
                    if V_CSVBuffer.Value <> '' then
                        if not Evaluate(V_TempLines.Num02, V_CSVBuffer.Value) then
                            AddMsgLine('"Peso" non riconosciuta in riga ' + Format(V_CSVBuffer."Line No."), true);
                8:
                    V_TempLines.Code02 := V_CSVBuffer.Value;
                9:
                    if L_RItemTmpl.Get(V_CSVBuffer.Value) then
                        V_TempLines.Code03 := V_CSVBuffer.Value
                    else
                        AddMsgLine('Errore : "BC - Template" nr ' + V_CSVBuffer.Value + ' non riconosciuto in riga nr ' + Format(V_CSVBuffer."Line No."), false);
                10:
                    V_TempLines.Code04 := V_CSVBuffer.Value;
                11:
                    if V_CSVBuffer.Value <> '' then
                        if not Evaluate(V_TempLines.Num03, V_CSVBuffer.Value) then
                            AddMsgLine('"Quantita Base" non riconosciuta in riga ' + Format(V_CSVBuffer."Line No."), true);
                12:
                    begin
                        V_TempLines.Code05 := CopyStr(V_CSVBuffer.Value, 1, 10);
                    end;
            end;
            V_TempLines.Modify();
        until V_CSVBuffer.Next() = 0;
        AddMsgLine('Totale righe analizzate ' + Format(V_TempLines.Count), true);
        // elimino codice articolo troppo lunghi
        V_TempLines.Reset();
        if not V_TempLines.FindSet() then
            exit(false);
        if V_TempLines.FindFirst() then;
    end;

    procedure AddMsgLine(P_Msg: Text;
        P_SkipError: Boolean)
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

    procedure CreateBOMH(var V_RBOM: Record "Production BOM Header"; P_No: Code[20]; P_Desc: Text) O_OK: Boolean
    begin
        TempRec.Init;
        TempRec.Text01 := P_Desc;
        TempRec.Code01 := P_No;
        TempRec.Order := 'CreateBOMH';
        Commit;
        O_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        if O_OK then
            O_OK := V_RBOM.Get(TempRec.Code01);
    end;

    local procedure F_CreateBOMH(var V_Rec: Record "FLEX Work File FLE" temporary)
    var
        L_RITEM: Record Item;
        L_RBOM: Record "Production BOM Header";
    begin
        L_RBOM.Init;
        L_RBOM.Validate("No.", V_Rec.Code01);
        L_RBOM.Insert(true);
        if L_RITEM.Get(V_Rec.Code01) then
            L_RBOM.Validate("Unit of Measure Code", L_RITEM."Base Unit of Measure")
        else
            L_RBOM.Validate("Unit of Measure Code", F_GetUM());
        L_RBOM.Validate(Description, CopyStr(V_Rec.Text01, 1, MaxStrLen(L_RBOM.Description)));
        L_RBOM.Status := L_RBOM.Status::New;
        L_RBOM.Modify();
        V_Rec.Code01 := L_RBOM."No.";
    end;

    procedure CreateRoutingH(var V_RRoutingH: Record "Routing Header"; P_No: Code[20]; P_Desc: Text; P_WorkCenter: Code[20]) O_OK: Boolean
    begin
        TempRec.Init;
        TempRec.Text01 := P_Desc;
        TempRec.Code01 := P_No;
        TempRec.Code02 := P_WorkCenter;
        TempRec.Order := 'CreateRoutingH';
        Commit;
        O_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        if O_OK then
            O_OK := V_RRoutingH.Get(TempRec.Code01);
    end;

    local procedure F_CreateRoutingH(var V_Rec: Record "FLEX Work File FLE" temporary)
    var
        L_RRoutingH: Record "Routing Header";
        L_RRoutingL: Record "Routing Line";
    begin
        L_RRoutingH.Init;
        L_RRoutingH.Validate("No.", V_Rec.Code01);
        L_RRoutingH.Insert(true);
        L_RRoutingH.Type := L_RRoutingH.Type::Serial;
        L_RRoutingH.Status := L_RRoutingH.Status::New;
        L_RRoutingH.Validate(Description, CopyStr(V_Rec.Text01, 1, MaxStrLen(L_RRoutingH.Description)));
        L_RRoutingH.Modify();
        L_RRoutingL."Routing No." := L_RRoutingH."No.";
        L_RRoutingL."Operation No." := CCEA.GetDefaultOperationNo; // CHECK DA eliminare?
        L_RRoutingL.Insert(false);
        L_RRoutingL.Validate(Type, L_RRoutingL.Type::"Work Center");
        if V_Rec.Code02 <> '' then
            L_RRoutingL.Validate("No.", V_Rec.Code02);
        L_RRoutingL.Validate("Routing Link Code", CCEA.GetDefalutRoutingLink()); // CHECK DA eliminare?
        L_RRoutingL.Modify(false);
        V_Rec.Code01 := L_RRoutingH."No.";
    end;

    local procedure F_GetUM() O_Code: Code[20];
    var
        L_RItem: Record Item;
    begin
        case RActivityLog."Record ID".TableNo of
            Database::Item:
                begin
                    RActivityLog."Record ID".GetRecord.SetTable(L_RItem);
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

    local procedure F_CheckItem(var V_TempLines: Record "FLEX Work File FLE" temporary);
    var
        L_RItem: Record Item;
        L_RUM: Record "Unit of Measure";
        L_Modify: Boolean;
        L_OK: Boolean;
    begin
        // verifico articolo
        if StrLen(V_TempLines.Code02) > 20 then begin
            AddMsgLine(StrSubstNo(Lbl_Err2, Format(V_TempLines.Int10), V_TempLines.Code02), true);
            V_TempLines.Delete();
            exit;
        end;
        // se non esiste creo l'articolo
        if not L_RItem.Get(V_TempLines.Code02) then begin
            ClearLastError();
            L_OK := CreateItem(V_TempLines.Code03, V_TempLines.Code02, L_RItem);
            if L_RItem."No." <> V_TempLines.Code03 then begin
                V_TempLines.Code02 := L_RItem."No.";
                V_TempLines.Modify();
            end;
            AddMsgLine('Nuovo articolo creato : ' + L_RItem."No.", L_OK);
            if L_OK then begin
                ClearLastError();
                if not ApplyItemTemplate(V_TempLines.Code03, L_RItem) then
                    AddMsgLine('Applicazione template  ' + V_TempLines.Code03 + ' in ' + L_RItem."No.", false);
            end;
        end;
        ClearLastError();
        // Aggiorno l'articolo
        if L_RItem.StatusItem IN [L_RItem.StatusItem::"In Sviluppo", L_RItem.StatusItem::Nuovo] then begin
            L_OK := UpdateItem(L_RItem, V_TempLines.Text01, V_TempLines.Txt01, V_TempLines.Text02, V_TempLines.Txt02, V_TempLines.Num02, L_Modify);
            if L_OK then begin
                if L_RItem.Blocked then begin
                    L_RItem.Get(L_RItem."No.");
                    L_RItem.Blocked := false;
                    L_RItem.Modify();
                    AddMsgLine('Sbloccato articolo nr. ' + L_RItem."No.", true);
                end;
            end;
        end;
        if L_Modify or (not L_OK) then
            AddMsgLine('Aggiornati dati articolo nr. ' + L_RItem."No.", L_OK);
        // aggiorno / creo la materia Prima
        // 10   STOCK NUMBER        Code04
        // 11   BASE QTY            Num03
        // 12   BASE UNIT           Code05
        if StrLen(V_TempLines.Code04) > 20 then begin
            AddMsgLine(StrSubstNo(Lbl_Err2, Format(V_TempLines.Int10), V_TempLines.Code04), true);
            exit;
        end;
        // se non esiste creo l'articolo
        if (not L_RItem.Get(V_TempLines.Code04)) and (V_TempLines.Code04 <> '') then begin
            ClearLastError();
            // creo unità di misura
            if (V_TempLines.Code05 <> '') and (not L_RUM.Get(V_TempLines.Code05)) then begin
                L_OK := CreateUM(V_TempLines.Code05);
                AddMsgLine('Creata nuova unità di misura : ' + V_TempLines.Code05, L_OK);
            end;
            L_OK := CreateItem(CCEA.GetDefaultMPItemCategoryCode(), V_TempLines.Code04, L_RItem);
            AddMsgLine('Nuovo articolo creato : ' + L_RItem."No.", L_OK);
            ClearLastError();
            if not ApplyItemTemplate(CCEA.GetDefaultMPItemCategoryCode(), L_RItem) then
                AddMsgLine('Applicazione template  ' + CCEA.GetDefaultMPItemCategoryCode() + ' in ' + L_RItem."No.", false);
            if (V_TempLines.Code05 <> '') and (L_RUM.Get(V_TempLines.Code05)) then begin
                L_RItem.Validate("Base Unit of Measure", L_RUM.Code);
                L_RItem.Modify(true);
            end;
        end;
    end;

    local procedure AddItemENUTrnsl(P_RItem: Record Item; P_Text: Text)
    var
        L_RItemTransl: Record "Item Translation";
    begin
        L_RItemTransl.SetRange("Item No.", P_RItem."No.");
        L_RItemTransl.SetRange("Language Code", 'ENU');
        if not L_RItemTransl.FindFirst() then begin
            L_RItemTransl."Item No." := P_RItem."No.";
            L_RItemTransl."Language Code" := 'ENU';
            L_RItemTransl.Insert();
        end;
        if L_RItemTransl.Description <> P_Text then begin
            L_RItemTransl.Description := CopyStr(P_Text, 1, MaxStrLen(L_RItemTransl.Description));
            L_RItemTransl.Modify();
        end;
    end;

    procedure CreateItem(P_TemplateCode: Code[20]; P_ItemNo: Code[20]; var V_RItem: Record Item) B_Ok: Boolean;
    var
        L_RItemtmpl: Record "Item Templ.";
    begin
        if P_TemplateCode <> CCEA.GetDefaultMPItemCategoryCode() then
            if P_ItemNo = '' then
                if L_RItemtmpl.Get(P_TemplateCode) then
                    if not GetNextNo(L_RItemtmpl."No. Series", P_ItemNo) then begin
                        exit;
                    end;
        exit(CreateItem(P_ItemNo, V_RItem));
    end;

    procedure GetNextNo(P_SeriesNo: Code[20]; var V_Code: Code[20]) B_OK: Boolean;
    begin
        TempRec.Init;
        TempRec.Code01 := P_SeriesNo;
        TempRec.Order := 'GetNextNo';
        Commit;
        B_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        V_Code := TempRec.Code02;
        if B_OK then
            B_OK := V_Code <> '';
    end;

    local procedure F_GetNextNo(var V_Rec: Record "FLEX Work File FLE" temporary);
    var
        L_RNoSeries: Record "No. Series";
        L_CSeries: Codeunit "No. Series";
    begin
        L_RNoSeries.Get(V_Rec.Code01);
        V_Rec.Code02 := L_CSeries.GetNextNo(L_RNoSeries.Code);
    end;

    procedure CreateItem(P_ItemNo: Code[20]; var V_RItem: Record Item) B_OK: Boolean;
    begin
        TempRec.Init;
        TempRec.Code01 := P_ItemNo;
        TempRec.Order := 'CreateItem';
        Commit;
        B_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        if B_OK then
            B_OK := V_RItem.Get(TempRec.Code01);
    end;

    local procedure F_CreateItem(var V_Rec: Record "FLEX Work File FLE" temporary);
    var
        L_RItem: Record Item;
    begin
        if V_Rec.Code01 = '' then
            Error('Nr. articolo deve avere un valore');
        L_RItem.Init();
        L_RItem."No." := V_Rec.Code01;
        L_RItem."Costing Method" := RInventorySetup."Default Costing Method";
        L_RItem.Insert(true);
        L_RItem.Validate("Base Unit of Measure", CCEA.GetDefalutUM());
        L_RItem.Description := V_Rec.Code01;
        L_RItem.Modify();
        V_Rec.Code01 := L_RItem."No.";
    end;

    procedure ApplyItemTemplate(P_Template: Code[20]; var V_RItem: Record Item) B_OK: Boolean;
    begin
        if (P_Template = '') or (V_RItem."No." = '') then
            exit;
        TempRec.Init;
        TempRec.Code01 := P_Template;
        TempRec.Code02 := V_RItem."No.";
        TempRec.Order := 'ApplyItemTemplate';
        Commit;
        B_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        if B_OK then
            if V_RItem.Get(V_RItem."No.") then;
    end;

    local procedure F_ApplyItemTemplate(var V_Rec: Record "FLEX Work File FLE" temporary);
    var
        L_RItem: Record Item;
        L_RItemTempl: Record "Item Templ.";
        L_CItemTmpMgt: Codeunit "Item Templ. Mgt.";
    begin
        L_RItemTempl.Get(V_Rec.Code01);
        L_RItem.Get(V_Rec.Code02);
        L_CItemTmpMgt.ApplyItemTemplate(L_RItem, L_RItemTempl, true);
        L_RItem.Modify(true);
    end;

    procedure UpdateItem(var V_RItem: Record Item; P_Des: Text; P_Des2: Text; P_Transl: Text; P_Mat: Text; P_Weight: Decimal; V_BModify: Boolean) B_OK: Boolean;
    begin
        TempRec.Init;
        TempRec.Order := 'UpdateItem';
        TempRec.Code01 := V_RItem."No.";
        TempRec.Text01 := P_Des;
        TempRec.Text02 := P_Transl;
        TempRec.Txt01 := P_Des2;
        TempRec.Txt02 := P_Mat;
        TempRec.Num01 := P_Weight;
        Commit;
        B_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        V_BModify := TempRec.Bool01;
        V_RItem.Get(V_RItem."No.");
    end;

    local procedure F_UpdateItem(var V_Rec: Record "FLEX Work File FLE" temporary);
    var
        L_RItem: Record Item;
    begin
        L_RItem.Get(V_Rec.Code01);
        if (L_RItem.Description <> V_Rec.Text01) and (V_Rec.Text01 <> '') then begin
            L_RItem.Validate(Description, CopyStr(V_Rec.Text01, 1, MaxStrLen(L_RItem.Description)));
            V_Rec.Bool01 := true;
        end;
        if (L_RItem."Description 2" <> V_Rec.Txt01) and (V_Rec.Txt01 <> '') then begin
            L_RItem.Validate("Description 2", CopyStr(V_Rec.Txt01, 1, MaxStrLen(L_RItem."Description 2")));
            V_Rec.Bool01 := true;
        end;
        if (L_RItem."Materiale PTE" <> V_Rec.Txt02) and (V_Rec.Txt02 <> '') then begin
            L_RItem.Validate("Materiale PTE", CopyStr(V_Rec.Txt02, 1, MaxStrLen(L_RItem."Materiale PTE")));
            V_Rec.Bool01 := true;
        end;
        if (L_RItem."Net Weight" <> V_Rec.Num01) and (V_Rec.Num01 <> 0) then begin
            L_RItem.Validate("Net Weight", V_Rec.Num01);
            V_Rec.Bool01 := true;
        end;
        if V_Rec.Bool01 then
            L_RItem.Modify(true);
        AddItemENUTrnsl(L_RItem, V_Rec.Text02);
    end;

    local procedure F_UpdateBOMLines(var V_TempLines: Record "FLEX Work File FLE" temporary);
    var
        L_RBOM: Record "Production BOM Header";
        L_RBomLine: Record "Production BOM Line";
        L_BModify: Boolean;
        L_OK: Boolean;
        L_LineNo: Decimal;
    begin
        // elaboro le righe della BOM
        L_RBOM.Get(FileName);
        L_RBomLine.SetRange("Production BOM No.", FileName);
        L_RBomLine.SetRange("Version Code", '');
        // elimino le righe non articolo
        L_RBomLine.SetFilter(Type, '%1|%2', L_RBomLine.Type::"Production BOM", L_RBomLine.Type::" ");
        L_RBomLine.DeleteAll();
        L_RBomLine.SetRange(Type);
        L_RBomLine.SetFilter(Position, '%1', '');
        L_RBomLine.DeleteAll();
        L_RBomLine.SetRange(Position);
        // elaboro le modifiche 
        if L_RBomLine.FindSet() then
            repeat
                V_TempLines.SetRange(Order, L_RBomLine.Position);
                // TODO da capire come filtrare qui 
                if V_TempLines.FindFirst() then begin
                    // verifico update
                    if F_CheckBOMLChanges(L_RBomLine, V_TempLines.Code02, V_TempLines.Code03, V_TempLines.Text01, V_TempLines.Num01) then begin
                        // riapro la testata
                        if L_RBOM.Status in [L_RBOM.Status::Closed] then begin
                            ClearLastError();
                            AddMsgLine(StrSubstNo(Lbl_Reopen, L_RBOM."No."), OpenBOM(L_RBOM));
                        end;
                        // aggiorno la riga di DB
                        ClearLastError();
                        L_BModify := false;
                        L_OK := false;
                        L_OK := UpdateBomLine(L_RBomLine, V_TempLines.Code02, V_TempLines.Text01, V_TempLines.Num01, '', L_BModify);
                        if L_BModify or (not L_OK) then
                            AddMsgLine('Aggiornata distinta produzione articolo nr ' + L_RBOM."No.", L_OK);
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
        V_TempLines.SetRange(Order);
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
                L_OK := CreateBOML(L_RBomLine, V_TempLines.Order, V_TempLines.Code02, V_TempLines.Text01, V_TempLines.Num01, '');
                AddMsgLine(StrSubstNo(Lbl_NewBOML, L_RBomLine."Production BOM No.", L_RBomLine."No.", L_RBomLine."Unit of Measure Code", L_RBomLine."Quantity per"), L_OK);
            until V_TempLines.Next() = 0;
    end;

    local procedure F_ElabMPLines(var V_TempLines: Record "FLEX Work File FLE" temporary);
    var
        L_RItem: Record Item;
        L_RItemMP: Record Item;
        L_RBOM: Record "Production BOM Header";
        L_RBomLine: Record "Production BOM Line";
        L_RBomLine2: Record "Production BOM Line";
        L_RRoutingH: Record "Routing Header";
        L_BModify: Boolean;
        L_OK: Boolean;
        L_Skip: Boolean;
    begin
        V_TempLines.Reset();
        V_TempLines.SetFilter(Code04, '<>%1', '');
        if not V_TempLines.FindSet() then begin
            V_TempLines.Reset();
            exit;
        end;
        // per ogniuno di questi articoli devo creare/aggiornare la distinta con il materiale materiale MP
        repeat
            L_Skip := false;
            if not L_RItem.Get(V_TempLines.Code02) then begin
                AddMsgLine('Articolo nr. ' + L_RItem."No." + ' non trovato.', true);
                L_Skip := true;
            end;
            if not L_RItemMP.Get(V_TempLines.Code04) then begin
                AddMsgLine('Articolo nr. ' + L_RItemMP."No." + ' non trovato.', true);
                L_Skip := true;
            end;
            if not L_Skip then begin
                if (L_RItem."Production BOM No." = '') or (not L_RBOM.Get(L_RItem."Production BOM No.")) then begin
                    // creo la DB
                    if not L_RBOM.Get(L_RItem."No.") then begin
                        ClearLastError();
                        L_OK := CreateBOMH(L_RBOM, L_RItem."No.", L_RItem.Description);
                        AddMsgLine(StrSubstNo(LBL_NewBOMH, L_RItem."No."), L_OK);
                        if not L_OK then
                            exit;
                    end;
                end;
                if (L_RItem."Routing No." = '') or (not L_RRoutingH.Get(L_RItem."Routing No.")) then begin
                    // creo il ciclo
                    if not L_RRoutingH.Get(L_RItem."No.") then begin
                        ClearLastError();
                        L_OK := CreateRoutingH(L_RRoutingH, L_RItem."No.", L_RItem.Description, CCEA.GetDefaultWorkCenterCode());
                        AddMsgLine(StrSubstNo(LBL_NewRoutingH, L_RItem."No."), L_OK);
                        if not L_OK then
                            exit;
                    end;
                end;
                L_RBomLine.SetRange("Production BOM No.", L_RBOM."No.");
                if L_RBomLine.FindFirst() then begin
                    if F_CheckBOMLChanges(L_RBomLine, V_TempLines.Code04, CCEA.GetDefaultMPItemCategoryCode(), '', V_TempLines.Num02) then begin
                        if L_RBOM.Status in [L_RBOM.Status::Closed, L_RBOM.Status::Certified] then begin
                            ClearLastError();
                            AddMsgLine(StrSubstNo(Lbl_Reopen, L_RBOM."No."), OpenBOM(L_RBOM));
                        end;

                        ClearLastError();
                        L_BModify := false;
                        L_OK := false;
                        //L_OK := UpdateBomLine(L_RBomLine, V_TempLines.Code04, '', V_TempLines.Num03, V_TempLines.Code05, L_BModify);
                        L_OK := UpdateBomLine(L_RBomLine, V_TempLines.Code04, '', V_TempLines.Num03, '', L_BModify);
                        if L_BModify or (not L_OK) then
                            AddMsgLine('Aggiornata distinta produzione articolo MP nr ' + L_RBOM."No.", L_OK);
                        // tengo solo la prima riga
                        L_RBomLine2.SetRange("Production BOM No.", L_RBomLine."Production BOM No.");
                        L_RBomLine2.SetRange("Version Code", L_RBomLine."Version Code");
                        L_RBomLine2.SetFilter("Line No.", '<> %1', L_RBomLine."Line No.");
                        L_RBomLine2.DeleteAll();
                    end;
                end else begin
                    if L_RBOM.Status in [L_RBOM.Status::Closed, L_RBOM.Status::Certified] then begin
                        ClearLastError();
                        AddMsgLine(StrSubstNo(Lbl_Reopen, L_RBOM."No."), OpenBOM(L_RBOM));
                    end;
                    L_RBomLine.Init();
                    L_RBomLine."Production BOM No." := L_RBOM."No.";
                    L_RBomLine."Version Code" := '';
                    L_RBomLine."Line No." := 10000;
                    L_RBomLine.Insert(true);
                    ClearLastError();
                    //L_OK := CreateBOML(L_RBomLine, V_TempLines.Code04, '', V_TempLines.Num03, V_TempLines.Code05);
                    L_OK := CreateBOML(L_RBomLine, '', V_TempLines.Code04, '', V_TempLines.Num03, '');
                    AddMsgLine(StrSubstNo(Lbl_NewBOML, L_RBomLine."Production BOM No.", L_RBomLine."No.", L_RBomLine."Unit of Measure Code", L_RBomLine."Quantity per"), L_OK);
                end;
                ClearLastError();
                L_OK := ValidateItem(L_RItem, L_RBOM, L_RRoutingH);
                if not L_OK then
                    AddMsgLine('Impossibile assegnare distinta e ciclo ad articolo nr. ' + L_RItem."No.", false);
            end;
        until V_TempLines.Next() = 0;
    end;

    local procedure F_CheckBOMLChanges(P_RBomLine: Record "Production BOM Line"; P_ItemNo: Code[20]; P_ItemCat: Code[20]; P_Desc: Text; P_Qty: Decimal): Boolean;
    begin
        if P_RBomLine."No." <> P_ItemNo then
            exit(true);
        //if P_ItemCat <> CCEA.GetDefaultMPItemCategoryCode then
        if P_RBomLine.Description <> P_Desc then
            exit(true);
        if P_RBomLine."Quantity per" <> P_Qty then
            exit(true);
        exit(false);
    end;

    procedure UpdateBomLine(var V_RBomLine: Record "Production BOM Line"; P_ItemNo: Code[20]; P_Desc: Text; P_Qty: Decimal; P_UM: Code[10]; V_BModify: Boolean) B_OK: Boolean;
    begin
        TempRec.Init;
        TempRec.Order := 'UpdateBomLine';
        TempRec.Code01 := V_RBomLine."Production BOM No.";
        TempRec.Code02 := V_RBomLine."Version Code";
        TempRec.Int01 := V_RBomLine."Line No.";
        TempRec.Code03 := P_ItemNo;
        TempRec.Code04 := P_UM;
        TempRec.Text01 := P_Desc;
        TempRec.Num01 := P_Qty;
        Commit();
        B_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        V_BModify := TempRec.Bool01;
        V_RBomLine.Get(TempRec.Code01, TempRec.Code02, TempRec.Int01);
    end;

    local procedure F_UpdateBomLine(var V_Rec: Record "FLEX Work File FLE" temporary);
    var
        L_RItem: Record Item;
        L_RBomLine: Record "Production BOM Line";
        L_RUM: Record "Unit of Measure";
    begin
        L_RBomLine.Get(V_Rec.Code01, V_Rec.Code02, V_Rec.Int01);
        if L_RBomLine.Type <> L_RBomLine.Type::Item then
            L_RBomLine.Validate(Type, L_RBomLine.Type::Item);
        if L_RBomLine."No." <> V_Rec.Code03 then begin
            L_RBomLine.Validate("No.", V_Rec.Code03);
            V_Rec.Bool01 := true;
        end;
        if (L_RBomLine.Description <> V_Rec.Text01) and (V_Rec.Text01 <> '') then begin
            L_RBomLine.Validate(Description, CopyStr(V_Rec.Text01, 1, MaxStrLen(L_RBomLine.Description)));
            V_Rec.Bool01 := true;
        end;
        if L_RBomLine."Quantity per" <> V_Rec.Num01 then begin
            L_RBomLine.Validate("Quantity per", V_Rec.Num01);
            V_Rec.Bool01 := true;
        end;
        if V_Rec.Code04 <> '' then begin
            if (L_RBomLine."Unit of Measure Code" <> V_Rec.Code04) and (L_RUM.Get(V_Rec.Code04)) then begin
                L_RBomLine.Validate("Unit of Measure Code", L_RUM.Code);
                V_Rec.Bool01 := true;
            end;
        end else begin
            if L_RItem.Get(V_Rec.Code03) then
                if (L_RItem."Base Unit of Measure" <> '') and (L_RItem."Base Unit of Measure" <> L_RBomLine."Unit of Measure Code") and (L_RUM.Get(L_RItem."Base Unit of Measure")) then begin
                    L_RBomLine.Validate("Unit of Measure Code", L_RUM.Code);
                    V_Rec.Bool01 := true;
                end;
        end;
        if V_Rec.Bool01 then
            L_RBomLine.Modify(true);
    end;

    procedure OpenBOM(var V_RBOM: Record "Production BOM Header") B_OK: Boolean
    begin
        TempRec.Init;
        TempRec.Order := 'OpenBOM';
        TempRec.Code01 := V_RBOM."No.";
        Commit;
        B_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        V_RBOM.Get(V_RBOM."No.");

    end;

    local procedure F_OpenBOM(var V_Rec: Record "FLEX Work File FLE" temporary);
    var
        L_RBOM: Record "Production BOM Header";
    begin
        L_RBOM.Get(V_Rec.Code01);
        L_RBOM.Validate(Status, L_RBOM.Status::"Under Development");
        L_RBOM.Modify(true);
    end;

    procedure ValidateItem(var V_RItem: Record Item; P_RBOM: Record "Production BOM Header"; P_RRoutingH: Record "Routing Header") B_OK: Boolean;
    begin
        TempRec.Init;
        TempRec.Order := 'ValidateItem';
        TempRec.Code01 := V_RItem."No.";
        TempRec.Code02 := P_RBOM."No.";
        TempRec.Code03 := P_RRoutingH."No.";
        Commit;
        B_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        if B_OK then
            V_RItem.Get(V_RItem."No.");
    end;


    local procedure F_ValidateItem(var V_Rec: Record "FLEX Work File FLE" temporary);
    var
        L_RItem: Record Item;
        L_RBOM: Record "Production BOM Header";
        L_RRoutingH: Record "Routing Header";
    begin
        L_RItem.Get(V_Rec.Code01);
        L_RBOM.Get(V_Rec.Code02);
        L_RRoutingH.Get(V_Rec.Code03);
        if (L_RItem."Production BOM No." <> L_RBOM."No.") and (L_RBOM."No." <> '') then begin
            L_RItem.Validate("Production BOM No.", L_RBOM."No.");
            V_Rec.Bool01 := true;
        end;
        if (L_RItem."Routing No." <> L_RRoutingH."No.") and (L_RRoutingH."No." <> '') then begin
            L_RItem.Validate("Routing No.", L_RRoutingH."No.");
            V_Rec.Bool01 := true;
        end;
        if V_Rec.Bool01 then
            V_Rec.Bool01 := L_RItem.Modify(true);
        if L_RItem.Description <> L_RBOM.Description then begin
            L_RBOM.Description := L_RItem.Description;
            L_RBOM.Modify(false);
        end;
        if L_RItem.Description <> L_RRoutingH.Description then begin
            L_RRoutingH.Description := L_RItem.Description;
            L_RRoutingH.Modify(false);
        end;
    end;

    [Obsolete]
    procedure CreateBOML(var V_RBomLine: Record "Production BOM Line"; P_Item: Code[20]; P_Desc: Text[100]; P_Qty: Decimal; P_UM: Code[10]) B_OK: Boolean;
    begin
        // Obsolete : aggiunto Order as Position
        TempRec.Init;
        TempRec.Order := 'CreateBOML';
        TempRec.Code01 := V_RBomLine."Production BOM No.";
        TempRec.Code02 := V_RBomLine."Version Code";
        TempRec.Int01 := V_RBomLine."Line No.";
        TempRec.Code03 := P_Item;
        TempRec.Code04 := P_UM;
        TempRec.Text01 := P_Desc;
        TempRec.Num01 := P_Qty;
        Commit;
        B_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        if B_OK then
            V_RBomLine.Get(V_RBomLine."Production BOM No.", V_RBomLine."Version Code", V_RBomLine."Line No.");
    end;

    procedure CreateBOML(var V_RBomLine: Record "Production BOM Line"; P_Order: Code[20]; P_Item: Code[20]; P_Desc: Text[100]; P_Qty: Decimal; P_UM: Code[10]) B_OK: Boolean;
    var
    begin
        TempRec.Init;
        TempRec.Order := 'CreateBOML';
        TempRec.Code01 := V_RBomLine."Production BOM No.";
        TempRec.Code02 := V_RBomLine."Version Code";
        TempRec.Int01 := V_RBomLine."Line No.";
        TempRec.Code03 := P_Item;
        TempRec.Code04 := P_UM;
        TempRec.Code05 := P_Order;
        TempRec.Text01 := P_Desc;
        TempRec.Num01 := P_Qty;
        Commit;
        B_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
        if B_OK then
            V_RBomLine.Get(V_RBomLine."Production BOM No.", V_RBomLine."Version Code", V_RBomLine."Line No.");
    end;

    local procedure F_CreateBOML(var V_Rec: Record "FLEX Work File FLE" temporary);
    var
        L_RBomLine: Record "Production BOM Line";
        L_RUM: Record "Unit of Measure";
    begin
        L_RBomLine.Get(V_Rec.Code01, V_Rec.Code02, V_Rec.Int01);
        L_RBomLine.Validate(Type, L_RBomLine.Type::Item);
        L_RBomLine.Validate("No.", V_Rec.Code03);
        if (L_RBomLine.Description <> V_Rec.Text01) and (V_Rec.Text01 <> '') then
            L_RBomLine.Validate(Description, V_Rec.Text01);
        if (V_Rec.Code04 <> '') and (L_RUM.Get(V_Rec.Code04)) then L_RBomLine.Validate("Unit of Measure Code", V_Rec.Code04);
        L_RBomLine.Validate("Quantity per", V_Rec.Num01);
        L_RBomLine.Validate("Routing Link Code", CCEA.GetDefalutRoutingLink());
        if V_Rec.Code05 <> '' then
            L_RBomLine.Validate(Position, V_Rec.Code05);
        L_RBomLine.Modify();
    end;

    procedure CreateUM(P_Code: Code[10]) B_OK: Boolean
    var
    begin
        TempRec.Init;
        TempRec.Order := 'CreateUM';
        TempRec.Code01 := P_Code;
        TempRec.Text01 := P_Code;
        Commit;
        B_OK := Codeunit.Run(Codeunit::"BOM Import Mgt. PTE", TempRec);
    end;

    local procedure F_CreateUM(var V_Rec: Record "FLEX Work File FLE" temporary);
    var
        L_RUM: Record "Unit of Measure";
    begin
        L_RUM.Init();
        L_RUM.Code := V_Rec.Code01;
        L_RUM.Description := V_Rec.Text01;
        L_RUM.Insert(true);
    end;

    local procedure F_TEST()
    var
        L_CAPI: Codeunit "Web API CEAGroup PTE";
        L_test64: Label 'SVRFTTtERVNDUklaIElUO0RFU0NSSVAgRU47VFlQRTtNQVRFUklBTDtRVFk7TUFTUztQYXJ0ICBudW1iZXI7QkMgLSBUZW1wbGF0ZTtTVE9DSyBOVU1CRVI7QkFTRSBRVFk7QkFTRSBVTklUCjEwMDtST05ERUxMQSBJU09MQU5URTtJTlNVTEFUSU5HIFdBU0hFUjs7RzExIERJTjc3MzU7MjswLjA4NjtJTS0wNDQ4MjtJTTs7MTtDaWFzY3VubwoxMDE7U1VQUE9SVE87U1VQUE9SVDs7UzI3NUpSIEVOMTAwMjU7MTs3Ljc1NTtJTS0wOTU3MDtJTTtDSCAxMjAgeCAxMjs0NjA7bW0KMTAyO0lTT0xBTlRFO0lOU1VMQVRJTkc7O0cxMSBESU43NzM1OzI7Mi44NDk7SU0tMDk1Njc7SU07OzE7Q2lhc2N1bm8KMTAzO0lTT0xBTlRFO0lOU1VMQVRJTkc7O0cxMSBESU43NzM1OzI7MC4yODY7SU0tMDk1Njg7SU07OzE7Q2lhc2N1bm8KMTA0O1RJUkFOVEU7Uk9EOzs4Ljg7MjswLjU3NztJTS0wOTU2OTtJTTs7MTtDaWFzY3VubwoxMDU7UFJPRklMTyBBIFUgLSBVUE4gKGZsYW5naWEgcmFzdHJlbWF0YSk7VSBQUk9GSUxFIC0gVVBOIFNURUVMIEJFQU07O1MyNzVKUiBFTjEwMDI1OzE7NS44ODk7SU0tMDk1NzE7SU07VSAxMjA7NDUwO21tCjMwMDtEQURPIEVTQUcuIFRJUE8gMTtIRVggTlVUIFR5cGUgMTtVTkkgRU4gMjQwMzIgLSBNMTY7ODs4OzAuMDQ7VkktMDAwMTtDTzs7MTtDaWFzY3VubwozMDE7REFETyBFU0FHLiBCQVNTTztIRVggVEhJTiBOVVQ7VU5JIEVOIDI0MDM1IC0gTTE2Ozg7MjswLjAyMTtWSS0wMDAyO0NPOzsxO0NpYXNjdW5vCjMwMjtST05ELiAgUElBTkEgKExBUkdBKTtQTEFJTiBXQVNIRVIoTEFSR0UgU0VSSUVTKTtVTkkgNjU5MyAtIDE4IHggNDg7Q0FSQk9OIFNURUVMOzQ7MC4wNDk7VkktMDAwMztDTzs7MTtDaWFzY3VubwozMDM7VklURSBURSBQRiAtIFBBU1NPIEdST1NTTztIRVggSEVBRCBTQ1JFVyBQVCAtIENPQVJTRSBQSVRDSDtVTkkgRU4gMjQwMTcgKGV4LiBVTkkgNTczOSlfTTE2IHggNzA7OC44OzQ7MC4xNDk7VkktMDAwNDtDTzs7MTtDaWFzY3VubwozMDQ7Uk9ORC4gIFBJQU5BO0ZMQVQgV0FTSEVSO1VOSSA2NTkyIC0gMTcgeCAzMDtDQVJCT04gU1RFRUw7ODswLjAxMTtWSS0wMDA1O0NPOzsxO0NpYXNjdW5v';
        L_test642: Label 'SVRFTTtERVNDUklaIElUO0RFU0NSSVAgRU47VFlQRTtNQVRFUklBTDtRVFk7TUFTUztQYXJ0ICBudW1iZXI7QkMgLSBUZW1wbGF0ZTtTVE9DSyBOVU1CRVI7QkFTRSBRVFk7QkFTRSBVTklUCjEwMTtJU09MQU5URTtJTlNVTEFUSU5HOztHMTEgRElONzczNTsyOzAsNTQ2O0lNLTA5MjkwO0lNOzsxO0VhY2gKMTAyO1RJUkFOVEU7Uk9EOzs4Ljg7MjswLDkwMTtJTS0wOTI5MTtJTTs7MTtFYWNoCjMwMTtEQURPIEVTQUcuIFRJUE8gMTtIRVggTlVUIFR5cGUgMTtVTkkgRU4gMjQwMzIgLSBNMTY7ODs2OzAsMDQ7VlQwMDEtMDAwMDI7Q087OzE7RWFjaAozMDI7Uk9ORC4gIFBJQU5BIChMQVJHQSk7UExBSU4gV0FTSEVSKExBUkdFIFNFUklFUyk7VU5JIDY1OTMgLSAxOCB4IDQ4O0NBUkJPTiBTVEVFTDsyOzAsMDQ5O1ZUMDAxLTAwMDAzO0NPOzsxO0VhY2gKMTAwO1JPTkRFTExBIElTT0xBTlRFO0lOU1VMQVRJTkcgV0FTSEVSOztHMTEgRElONzczNTsyOzAsMDg2O0lNLTAxMjAzMDtJTTtDSCAyMDAgeCAyMDsxO21tCjEwNjsiUFJPRklMTyBBICIiVSIiIjtVIFBST0ZJTEU7O1MyNzVKUiBFTjEwMDI1OzE7NSw5ODk7SU0tMDkyOTU7SU07Q0ggMTQwIHggMTU7NDA1O21tCjEwNTtJU09MQU5URTtJTlNVTEFUSU5HOztHMTEgRElONzczNTsyOzQsNjUyO0lNLTA5Mjk0O0lNOzsxO0VhY2gKMTA0O0lTT0xBTlRFO0lOU1VMQVRJTkc7O0cxMSBESU43NzM1OzE7NywwNDE7SU0tMDkyOTM7SU07OzE7RWFjaAoxMDM7UElBU1RSQTtQTEFURTs7UzI3NUpSIEVOMTAwMjU7MTsxMSw5NTg7SU0tMDEyMzQ7SU07OzE7RWFjaAozMDA7TU9MTEEgR0lBTExBIEVYVFJBRk9SVEU7RVhUUkFTVFJPTkcgWUVMTE9XIFNQUklORztDMDAzNyAtIERIMjAgQz02OSw1IE4vbW0gTDA9ODk7U1BSSU5HIFNURUVMOzg7MCwwNTU7VlQwMDEtMDAwMDE7Q087OzE7RWFjaAozMDM7VklURSBURSBQRiAtIFBBU1NPIEdST1NTTztIRVggSEVBRCBTQ1JFVyBQVCAtIENPQVJTRSBQSVRDSDtVTkkgRU4gMjQwMTcgKGV4LiBVTkkgNTczOSlfTTE2IHggNzA7OC44OzQ7MCwxNDk7VlQwMDItMDAwMDE7Q087OzE7RWFjaAo=';
    begin
        L_CAPI.ImportBOMFromCSVText(L_test642, 'C8888-RFBPRH01-A000')
    end;

}
