pageextension 50004 "Dimension Values PTE" extends "Dimension Values"
{

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if GlobalDimCode <> '' then
            Rec."Dimension Code" := GlobalDimCode;
        // if L_RNoSeries.Get('DIMENSIONI') then
        //     Rec.Code := L_NoSeriesMgt.GetNextNo('DIMENSIONI', Today, true);
    end;

    var
        GlobalDimCode: Code[20];

    procedure SetDimCode(P_DimCode: Code[20])
    begin
        GlobalDimCode := P_DimCode;
    end;
}

