tableextension 50000 "Project Desc." extends "Sales Header"
{
    fields
    {
        field(50000; "Project Desc PTE"; Text[200])
        {
            Caption = 'Descrizione Progetto', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50001; "Disegno PTE"; Text[200])
        {
            Caption = 'Disegno', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50002; "Manager Vendite PTE"; Text[200])
        {
            Caption = 'Manager Vendite', Locked = true;
            DataClassification = CustomerContent;
        }
    }
}
