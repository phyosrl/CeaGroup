pageextension 50012 "Item List PTE" extends "Item List"
{
    actions
    {
        addafter("Item Refe&rences")
        {
            action(ImportLog)
            {
                Caption = 'Log importazione BOM', Locked = true;
                Image = Log;
                ApplicationArea = All;
                ToolTip = 'Visualizza i log di importazioni dei file per le distinte di produzione.', Locked = true;
                PromotedIsBig = true;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    L_Rec: Record "Activity Log";
                    L_CBOMImport: Codeunit "BOM Import Mgt. PTE";
                begin
                    L_Rec.FilterGroup(10);
                    L_Rec.SetRange(Context, L_CBOMImport.GETImportBOMContext());
                    L_Rec.FilterGroup(0);
                    Page.Run(Page::"Activity Log", L_Rec);
                end;
            }
            action(ImportCSV)
            {
                Caption = 'Importa Distinta Base', Locked = true;
                ToolTip = 'Importa una distita base di produzione da file esterno. Le modifiche vengono storicizzate in "Log importazione BOM"', Locked = true;
                Image = ImportDatabase;
                PromotedIsBig = true;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    L_RLog: Record "Activity Log";
                    L_CCode: Codeunit "BOM Import Mgt. PTE";
                    L_Instream: InStream;
                    L_Content: Text;
                    L_FileName: Text;
                    L_Text: Text;
                begin
                    L_CCode.ImportBOMFromCSVText(L_Content, false, L_FileName, L_RLog);
                    if L_RLog.Status = L_RLog.Status::Success then
                        L_Text := 'Distinta base di produzione importata con successo. '
                    else
                        L_Text := 'È stato riscontato un errore durante la elaborazione del file . ';
                    Message(L_Text + 'Visualizza i dettagli della esportazione in "Log importazione BOM"')
                end;
            }
        }
    }
}