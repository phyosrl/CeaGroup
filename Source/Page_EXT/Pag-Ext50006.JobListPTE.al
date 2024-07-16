pageextension 50006 "Job List PTE" extends "Job List"
{
    layout
    {
        addbefore("No.")
        {
            field("Tipo Ordine"; Rec."Global Dimension 1 Code")
            {
                ApplicationArea = All;
            }
            field(Commessa; Rec."Global Dimension 2 Code")
            {
                ApplicationArea = All;
            }
        }
        addafter("No.")
        {
            field("Project Desc"; Rec."Desc. Progetto PTE")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field(Disegno; Rec."Disegno PTE")
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
