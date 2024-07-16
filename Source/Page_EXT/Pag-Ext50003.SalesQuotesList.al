pageextension 50003 "Sales Quotes List_EXT" extends "Sales Quotes"
{
    layout
    {
        addbefore("No.")
        {
            field("Tipo Ordine"; Rec."Shortcut Dimension 1 Code")
            {
                ApplicationArea = All;
            }
            field("Commessa"; Rec."Shortcut Dimension 2 Code")
            {
                ApplicationArea = All;
            }

        }
        addafter("No.")
        {
            field("Project Desc"; Rec."Project Desc")
            {
                ApplicationArea = All;
                Editable = false;
                Caption = 'Descrizione Progetto';
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
}