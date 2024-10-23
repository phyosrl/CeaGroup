pageextension 50009 "Document Attachment DetailsPTE" extends "Document Attachment Details"
{

    layout
    {
        addafter("File Extension")
        {
            field("Tipo Documento"; Rec."Type Document")
            {
                ApplicationArea = All;
                Caption = 'Tipo Documento';
                Visible = true;
            }
            field("Description Document PTE"; Rec."Description Document PTE")
            {
                ApplicationArea = All;
                Caption = 'Descrizione Documento';
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
