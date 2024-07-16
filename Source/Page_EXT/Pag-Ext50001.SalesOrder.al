pageextension 50001 "Sales Order_Ext" extends "Sales Order"
{
    layout
    {
        addafter(General)
        {
            group(CeaGroup)
            {
                Caption = 'CeaGroup', Locked = true;
                field("ProjectDesc"; Rec."Project Desc")
                {
                    ApplicationArea = All;
                    Caption = 'Descrizione Progetto', Locked = true;
                }
                field("Disegno"; Rec."Disegno")
                {
                    ApplicationArea = All;
                }
                field("Manager Vendite"; Rec."Manager Vendite")
                {
                    ApplicationArea = All;
                }
            }
        }

        movebefore(ProjectDesc; "Shortcut Dimension 1 Code")
        moveafter("Shortcut Dimension 1 Code"; "Shortcut Dimension 2 Code")
        modify("Shortcut Dimension 1 Code")
        {
            trigger OnLookup(var Text: Text) Ok: Boolean;
            var
                L_RDimValue: record "Dimension Value";
                L_Page: page "Dimension Values";
                L_Action: Action;
                L_RGenLedSetup: record "General Ledger Setup";
            begin
                if rec."No." = '' then
                    exit;
                L_RGenLedSetup.GET();
                L_RDimValue.FilterGroup(10);
                L_RDimValue.SETRANGE("Dimension Code", L_RGenLedSetup."Global Dimension 1 Code");
                L_RDimValue.FilterGroup(0);
                L_Page.SetTableView(L_RDimValue);
                L_Page.SetDimCode(L_RGenLedSetup."Global Dimension 1 Code");
                L_Page.Editable := true;
                L_Page.LookupMode := true;
                L_Action := L_Page.RunModal;
                if L_Action in [Action::LookupOK, Action::OK, Action::Yes] then begin
                    L_Page.GetRecord(L_RDimValue);
                    rec.Validate("Shortcut Dimension 1 Code", L_RDimValue.Code);
                end;
            end;
        }
        modify("Shortcut Dimension 2 Code")
        {
            trigger OnLookup(var Text: Text) Ok: Boolean;
            var
                L_RDimValue: record "Dimension Value";
                L_Page: page "Dimension Values";
                L_Action: Action;
                L_RGenLedSetup: record "General Ledger Setup";
            begin
                if rec."No." = '' then
                    exit;
                L_RGenLedSetup.GET();
                L_RDimValue.FilterGroup(10);
                L_RDimValue.SETRANGE("Dimension Code", L_RGenLedSetup."Global Dimension 2 Code");
                L_RDimValue.FilterGroup(0);
                L_Page.SetTableView(L_RDimValue);
                L_Page.SetDimCode(L_RGenLedSetup."Global Dimension 2 Code");
                L_Page.Editable := true;
                L_Page.LookupMode := true;
                L_Action := L_Page.RunModal;
                if L_Action in [Action::LookupOK, Action::OK, Action::Yes] then begin
                    L_Page.GetRecord(L_RDimValue);
                    rec.Validate("Shortcut Dimension 2 Code", L_RDimValue.Code);
                end;
            end;
        }
    }
}
