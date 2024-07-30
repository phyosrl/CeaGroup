pageextension 50004 "Dimension Values PTE" extends "Dimension Values"
{

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if GlobalDimCode <> '' then
            Rec."Dimension Code" := GlobalDimCode;
    end;

    var
        GlobalDimCode: Code[20];

    procedure SetDimCode(P_DimCode: Code[20])
    begin
        GlobalDimCode := P_DimCode;
    end;
}
