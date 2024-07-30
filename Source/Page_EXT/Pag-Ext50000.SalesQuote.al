pageextension 50000 "Sales Quote PTE" extends "Sales Quote"
{
    layout
    {
        addafter(General)
        {
            group(CeaGroup)
            {

                Caption = 'Cea Group', Locked = true;

                field(DimName; DimName)
                {
                    ApplicationArea = All;
                    Caption = 'Nome Commessa', Locked = true;
                    Editable = false;
                }
                field("Desc. Progetto"; Rec."Project Desc")
                {
                    ApplicationArea = All;
                }
                field(Disegno; Rec.Disegno)
                {
                    ApplicationArea = All;
                }
                field("Manager Vendite"; Rec."Manager Vendite")
                {
                    ApplicationArea = All;
                }
            }
        }

        movebefore(DimName; "Shortcut Dimension 1 Code")
        moveafter("Shortcut Dimension 1 Code"; "Shortcut Dimension 2 Code")
        modify("Shortcut Dimension 1 Code")
        {

            trigger OnAfterValidate()
            begin
                CalcDimName();
            end;

            trigger OnLookup(var Text: Text) Ok: Boolean;
            var
                L_RDimValue: Record "Dimension Value";
                L_RGenLedSetup: Record "General Ledger Setup";
                L_Page: Page "Dimension Values";
                L_Action: Action;
            begin
                if Rec."No." = '' then
                    exit;
                L_RGenLedSetup.Get();
                L_RDimValue.FilterGroup(10);
                L_RDimValue.SetRange("Dimension Code", L_RGenLedSetup."Global Dimension 1 Code");
                L_RDimValue.FilterGroup(0);
                L_Page.SetTableView(L_RDimValue);
                L_Page.SetDimCode(L_RGenLedSetup."Global Dimension 1 Code");
                L_Page.Editable := true;
                L_Page.LookupMode := true;
                L_Action := L_Page.RunModal;
                if L_Action in [Action::LookupOK, Action::OK, Action::Yes] then begin
                    L_Page.GetRecord(L_RDimValue);
                    Rec.Validate("Shortcut Dimension 1 Code", L_RDimValue.Code);
                end;
                CalcDimName;
            end;
        }
        modify("Shortcut Dimension 2 Code")
        {

            trigger OnAfterValidate()
            begin
                CalcDimName;
            end;

            trigger OnLookup(var Text: Text) Ok: Boolean;
            var
                L_RDimValue: Record "Dimension Value";
                L_RGenLedSetup: Record "General Ledger Setup";
                L_Page: Page "Dimension Values";
                L_Action: Action;
            begin
                if Rec."No." = '' then
                    exit;
                L_RGenLedSetup.Get();
                L_RDimValue.FilterGroup(10);
                L_RDimValue.SetRange("Dimension Code", L_RGenLedSetup."Global Dimension 2 Code");
                L_RDimValue.FilterGroup(0);
                L_Page.SetTableView(L_RDimValue);
                L_Page.SetDimCode(L_RGenLedSetup."Global Dimension 2 Code");
                L_Page.Editable := true;
                L_Page.LookupMode := true;
                L_Action := L_Page.RunModal;
                if L_Action in [Action::LookupOK, Action::OK, Action::Yes] then begin
                    L_Page.GetRecord(L_RDimValue);
                    Rec.Validate("Shortcut Dimension 2 Code", L_RDimValue.Code);
                end;
                CalcDimName;
            end;

        }
    }
    trigger OnAfterGetRecord()
    begin
        CalcDimName;
    end;

    var
        RDimValue: Record "Dimension Value";
        DimName: Text;

    local procedure CalcDimName()
    begin
        if RDimValue.Get(Rec."Shortcut Dimension 1 Code", Rec."Shortcut Dimension 2 Code") then
            DimName := RDimValue.Name
        else
            DimName := '';
    end;
}
