pageextension 50003 "Sales Quotes List PTE" extends "Sales Quotes"
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
                Caption = 'Nome Commessa', Locked = true;
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
        }
    }
    trigger OnAfterGetRecord()
    begin
        if RDimValue.Get(Rec."Shortcut Dimension 1 Code", Rec."Shortcut Dimension 2 Code") then
            DimName := RDimValue.Name
        else
            DimName := '';
    end;

    var
        RDimValue: Record "Dimension Value";
        DimName: Text;
}