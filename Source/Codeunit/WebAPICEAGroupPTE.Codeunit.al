codeunit 50001 "Web API CEAGroup PTE"
{

    procedure ImportBOMFromCSVText(P_CSV_Content: Text; P_CSV_FileContent: Text) Result: Text;
    var
        L_RLog: Record "Activity Log";
        L_CCode: Codeunit "BOM Import Mgt. PTE";
        L_CBlob: Codeunit "Temp Blob";
        L_Instream: InStream;
        L_Text: Text;
    begin
        L_CCode.ImportBOMFromCSVText(P_CSV_Content, true, P_CSV_FileContent, L_RLog);
        L_RLog.CalcFields(L_RLog."Detailed Info");
        if not L_RLog."Detailed Info".HasValue() then
            exit(L_RLog."Activity Message");
        L_CBlob.FromRecord(L_RLog, L_RLog.FieldNo("Detailed Info"));
        L_CBlob.CreateInStream(L_Instream);
        while not L_Instream.EOS do begin
            L_Instream.ReadText(L_Text);
            Result += L_Text;
        end;
    end;

    procedure POSTItemJLine(TemplateName: Code[10]; BatchName: Code[10]; LineNo: Integer);
    var
        L_RItemJnl: Record "Item Journal Line";
    begin
        L_RItemJnl.Get(TemplateName, BatchName, LineNo);
        L_RItemJnl.SetRecFilter();
        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", L_RItemJnl);
    end;
}
