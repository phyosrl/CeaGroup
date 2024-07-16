pageextension 50005 "Job Card_PTE" extends "Job Card"
{
    layout
    {
        addafter(General)
        {
            group(CeaGroup)
            {
                Caption = 'CeaGroup', Locked = true;
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
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

    }
}
