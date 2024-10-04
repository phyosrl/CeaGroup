pageextension 50011 "Item CardPTE" extends "Item Card"
{

    layout
    {
        addafter(Item)
        {
            group("Cea Group")
            {
                Caption = 'Cea Group', Locked = true;
                field("StatusItem"; Rec."StatusItem")
                {
                    ApplicationArea = All;
                    Caption = 'Stato Articolo';
                    Visible = true;
                }

                field("Nr. Produttore"; Rec."Nr. Produttore")
                {
                    ApplicationArea = All;
                }
                field("Produttore"; Rec."Produttore")
                {
                    ApplicationArea = All;
                }


                field("Specifica 1"; Rec."Specifica 1")
                {
                    ApplicationArea = All;
                }
                field("Specifica 2"; Rec."Specifica 2")
                {
                    ApplicationArea = All;
                }
                field("Specifica 3"; Rec."Specifica 3")
                {
                    ApplicationArea = All;
                }
                field("Specifica 4"; Rec."Specifica 4")
                {
                    ApplicationArea = All;
                }
                field("Specifica 5"; Rec."Specifica 5")
                {
                    ApplicationArea = All;
                }
                field("Specifica 6"; Rec."Specifica 6")
                {
                    ApplicationArea = All;
                }
                field("Specifica 7"; Rec."Specifica 7")
                {
                    ApplicationArea = All;
                }
                field("Specifica 8"; Rec."Specifica 8")
                {
                    ApplicationArea = All;
                }
                field("Specifica 9"; Rec."Specifica 9")
                {
                    ApplicationArea = All;
                }
                field("Specifica 10"; Rec."Specifica 10")
                {
                    ApplicationArea = All;
                }

            }
        }
        addafter("Description 2")
        {
            field("Materiale PTE"; Rec."Materiale PTE")
            {
                ApplicationArea = All;
            }
        }
    }
}

