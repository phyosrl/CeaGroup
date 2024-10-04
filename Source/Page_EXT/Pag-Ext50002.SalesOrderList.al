pageextension 50002 "Sales Order List PTE" extends "Sales Order List"
{
    layout
    {
        addbefore("No.")
        {
            field("Tipo Ordine"; Rec."Shortcut Dimension 1 Code")
            {
                ApplicationArea = All;
            }
            field(Commessa; Rec."Shortcut Dimension 2 Code")
            {
                ApplicationArea = All;
            }
            field(DimName; DimName)
            {
                ApplicationArea = All;
                Caption = 'Nome Progetto', Locked = true;
                Editable = false;
            }
        }
        addafter("No.")
        {
            field("Project Desc"; Rec."Project Desc")
            {
                ApplicationArea = All;
                Editable = false;
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
    trigger OnAfterGetRecord()
    begin
        if RDimValue.Get(RGenLedSetup."Global Dimension 2 Code", Rec."Shortcut Dimension 2 Code") then
            DimName := RDimValue.Name
        else
            DimName := '';
    end;

    var
        RDimValue: Record "Dimension Value";
        RGenLedSetup: Record "General Ledger Setup";
        DimName: Text;

    trigger OnOpenPage()
    begin
        RGenLedSetup.Get();
    end;
}