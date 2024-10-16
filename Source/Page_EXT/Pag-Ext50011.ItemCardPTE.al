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

                field("ItemGroup"; Rec."ItemGroup")
                {
                    ApplicationArea = All;
                    Caption = 'Famiglia Articolo';
                    Visible = true;
                }

                field("Nr. Produttore"; Rec."Nr. Produttore")
                {
                    ApplicationArea = All;
                    Caption = 'Codice Produttore';
                    Visible = true;
                }

                field("Nr. Produttore 2"; Rec."Nr. Produttore 2")
                {
                    ApplicationArea = All;
                    Caption = 'Codice Produttore Secondario';
                    Visible = true;
                }

                field("Produttore"; Rec."Produttore")
                {
                    ApplicationArea = All;
                    Visible = true;
                }


                field("Specifica 1"; Rec."Specifica 1")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Specifica 2"; Rec."Specifica 2")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Specifica 3"; Rec."Specifica 3")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Specifica 4"; Rec."Specifica 4")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Specifica 5"; Rec."Specifica 5")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Specifica 6"; Rec."Specifica 6")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Specifica 7"; Rec."Specifica 7")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Specifica 8"; Rec."Specifica 8")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Specifica 9"; Rec."Specifica 9")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Specifica 10"; Rec."Specifica 10")
                {
                    ApplicationArea = All;
                    Visible = true;
                }

            }
        }
        addafter("Description 2")
        {
            field("Materiale PTE"; Rec."Materiale PTE")
            {
                ApplicationArea = All;
                Visible = true;
            }
        }
    }
}

