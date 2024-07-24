tableextension 50001 "Job PTE" extends Job
{
    fields
    {
        field(50000; "Project Desc"; Text[200])
        {
            Caption = 'Descrizione Progetto', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50001; "Disegno"; Text[200])
        {
            Caption = 'Disegno', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50002; "Manager Vendite"; Text[200])
        {
            Caption = 'Manager Vendite', Locked = true;
            DataClassification = CustomerContent;
        }
    }
}
