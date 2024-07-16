tableextension 50000 "Project Desc." extends "Sales Header"
{
    fields
    {
        field(50000; "Project Desc"; Text[200])
        {
            Caption = 'Project Desc';
            DataClassification = ToBeClassified;
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
