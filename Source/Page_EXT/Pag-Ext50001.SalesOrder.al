pageextension 50001 "Sales Order PTE" extends "Sales Order"
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
                    Caption = 'Nome Progetto', Locked = true;
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
                field("Project Manager"; Rec."Project Manager")
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
                L_Page: Page "Dimension Values";
                L_Action: Action;
            begin
                if Rec."No." = '' then
                    exit;
                RGenLedSetup.Get();
                L_RDimValue.FilterGroup(10);
                L_RDimValue.SetRange("Dimension Code", RGenLedSetup."Global Dimension 1 Code");
                L_RDimValue.FilterGroup(0);
                L_Page.SetTableView(L_RDimValue);
                L_Page.SetDimCode(RGenLedSetup."Global Dimension 1 Code");
                L_Page.Editable := true;
                L_Page.LookupMode := true;
                L_Action := L_Page.RunModal;
                if L_Action in [Action::LookupOK, Action::OK, Action::Yes] then begin
                    L_Page.GetRecord(L_RDimValue);
                    Rec.Validate("Shortcut Dimension 1 Code", L_RDimValue.Code);
                    CalcDimName;
                end;
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
                L_Page: Page "Dimension Values";
                L_Action: Action;
            begin
                if Rec."No." = '' then
                    exit;
                RGenLedSetup.Get();
                L_RDimValue.FilterGroup(10);
                L_RDimValue.SetRange("Dimension Code", RGenLedSetup."Global Dimension 2 Code");
                L_RDimValue.FilterGroup(0);
                L_Page.SetTableView(L_RDimValue);
                L_Page.SetDimCode(RGenLedSetup."Global Dimension 2 Code");
                L_Page.Editable := true;
                L_Page.LookupMode := true;
                L_Action := L_Page.RunModal;
                if L_Action in [Action::LookupOK, Action::OK, Action::Yes] then begin
                    L_Page.GetRecord(L_RDimValue);
                    Rec.Validate("Shortcut Dimension 2 Code", L_RDimValue.Code);
                    CalcDimName;
                end;
            end;

        }
    }
    trigger OnAfterGetRecord()
    begin
        CalcDimName;
    end;

    var
        RDimValue: Record "Dimension Value";
        RGenLedSetup: Record "General Ledger Setup";
        DimName: Text;

    trigger OnOpenPage()
    begin
        RGenLedSetup.Get();
    end;

    local procedure CalcDimName()
    begin
        if RDimValue.Get(RGenLedSetup."Global Dimension 2 Code", Rec."Shortcut Dimension 2 Code") then
            DimName := RDimValue.Name
        else
            DimName := '';
    end;
}
