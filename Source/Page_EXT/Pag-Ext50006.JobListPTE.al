pageextension 50006 JobList_PTE extends "Job List"
{
    layout
    {
        addbefore("No.")
        {
            field("Tipo Ordine"; Rec."Global Dimension 1 Code")
            {
                ApplicationArea = All;
            }
            field("Commessa"; Rec."Global Dimension 2 Code")
            {
                ApplicationArea = All;
            }
        }
        addafter("No.")
        {
            field("Project Desc"; Rec."Project Desc PTE")
            {
                ApplicationArea = All;
                Editable = false;
                Caption = 'Descrizione Progetto';
            }
            field("Disegno"; Rec."Disegno PTE")
            {
                ApplicationArea = All;
            }
            field("Manager Vendite"; Rec."Manager Vendite PTE")
            {
                ApplicationArea = All;
            }

        }
    }
}
