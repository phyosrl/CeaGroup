pageextension 50012 "Item List PTE" extends "Item List"
{
    layout
    {
        addafter("Description 2")
        {
            field("Materiale PTE"; Rec."Materiale PTE")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        addafter("Item Refe&rences")
        {
            action(ImportLog)
            {
                ApplicationArea = All;
                Caption = 'Log importazione BOM', Locked = true;
                Image = Log;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Visualizza i log di importazioni dei file per le distinte di produzione.', Locked = true;
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
                ApplicationArea = All;
                Caption = 'Importa Distinta Base', Locked = true;
                Image = ImportDatabase;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Importa una distita base di produzione da file esterno. Le modifiche vengono storicizzate in "Log importazione BOM"', Locked = true;
                trigger OnAction()
                var
                    L_RLog: Record "Activity Log";
                    L_CCode: Codeunit "BOM Import Mgt. PTE";
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