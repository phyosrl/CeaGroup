pageextension 50010 "Email Related Attachments PTE" extends "Email Related Attachments"
{
    layout
    {
        addlast(Content) // definire posizione su riga!!!!!!!!!!!!!!!!
        {
            field("Tipo Documento"; Rec."Type Document")
            {
                ApplicationArea = All;
                Caption = 'Tipo Documento';
                Visible = true;
            }

            field("Revisione"; Rec."Revision")
            {
                ApplicationArea = All;
                Caption = 'Revisione';
                Visible = true;
            }

            field("Data Revisione"; Rec."Date Revision")
            {
                ApplicationArea = All;
                Caption = 'Data Revisione';
                Visible = false;
            }
        }
    }
}

