pageextension 50004 "Dimension Values PTE" extends "Dimension Values"
{
    actions
    {
        addlast(Creation)
        {
            action(A_New_PTE)
            {
                ApplicationArea = All;
                Caption = 'Nuovo con numerazione', Locked = true;
                Image = SerialNo;
                Promoted = true;
                PromotedIsBig = true;
                trigger OnAction()
                var
                    L_Rec: Record "Dimension Value";
                    L_NoSeriesMgt: Codeunit "No. Series";
                    L_RNoSeries: record "No. Series";
                begin
                    L_RNoSeries.Get('COMMESSA');
                    L_Rec.Init();
                    L_Rec."Dimension Code" := rec."Dimension Code";
                    L_Rec.Code := L_NoSeriesMgt.GetNextNo('COMMESSA', Today, true);
                    L_Rec.Insert(true);
                    CurrPage.Update();
                end;
            }
        }
    }

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

