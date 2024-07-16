tableextension 50002 "Item PTE" extends Item
{
    fields
    {
        field(50000; "Materiale PTE"; Text[200])
        {
            Caption = 'Materiale', Locked = true;
            DataClassification = CustomerContent;
        }
    }
}
