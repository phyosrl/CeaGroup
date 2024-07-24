pageextension 50005 "Job Card PTE" extends "Job Card"
{
    layout
    {
        addafter(General)
        {
            group(CeaGroup)
            {
                Caption = 'Cea Group', Locked = true;
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
                field(ProjectDesc; Rec."Project Desc")
                {
                    ApplicationArea = All;
                }
                field(Disegno; Rec."Disegno")
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
