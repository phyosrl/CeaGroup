pageextension 50013 "Purchase Order SubformPTE" extends "Purchase Order Subform"
{

    layout
    {
        addafter("Description")
        {
            field("Nr. Produttore"; Rec."Nr. Produttore")
            {
                ApplicationArea = All;
                Caption = 'Codice Produttore';
                Visible = false;
            }
            field("Produttore"; Rec."Produttore")
            {
                ApplicationArea = All;
                Caption = 'Produttore';
                Visible = false;
            }

        }
    }
}
