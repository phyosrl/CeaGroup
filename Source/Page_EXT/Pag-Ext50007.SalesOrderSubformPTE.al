pageextension 50007 "Sales Order SubformPTE" extends "Sales Order Subform"
{
    layout
    {
        addafter("Quantity")
        {
            field("Stato Riga"; Rec."Stato Riga")
            {
                ApplicationArea = All;
                Caption = 'Stato Riga';
                Editable = False;
                Visible = true;
            }
            field("Quantita prenotata"; Rec."Quantita prenotata")
            {
                ApplicationArea = All;
                Caption = 'Quantita prenotata';
                Editable = False;
                Visible = true;
            }

        }
    }
}
