pageextension 50004 "Dimension Values PTE" extends "Dimension Values"
{
    var
        GlobalDimCode: code[20];

    procedure SetDimCode(P_DimCode: code[20])
    begin
        GlobalDimCode := P_DimCode;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if GlobalDimCode <> '' then
            Rec."Dimension Code" := GlobalDimCode;
    end;
}
