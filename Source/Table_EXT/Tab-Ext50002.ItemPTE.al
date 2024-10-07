tableextension 50002 "Item PTE" extends Item
{
    fields
    {
        field(50000; "Materiale PTE"; Text[200])
        {
            Caption = 'Materiale', Locked = true;
            DataClassification = CustomerContent;
        }

        field(50001; "Nr. Produttore"; Text[200])
        {
            Caption = 'Nr. Produttore', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50002; "Produttore"; Text[200])
        {
            Caption = 'Produttore', Locked = true;
            DataClassification = CustomerContent;
            TableRelation = "General Table FLE".Code where(TableCode = const('PRODUTTORE'),
                                                            TableCode02 = const(''));
        }
        field(50003; "Specifica 1"; Text[200])
        {
            Caption = 'Specifica 1', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50004; "Specifica 2"; Text[200])
        {
            Caption = 'Specifica 2', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50005; "Specifica 3"; Text[200])
        {
            Caption = 'Specifica 3', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50006; "Specifica 4"; Text[200])
        {
            Caption = 'Specifica 4', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50007; "Specifica 5"; Text[200])
        {
            Caption = 'Specifica 5', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50008; "Specifica 6"; Text[200])
        {
            Caption = 'Specifica 6', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50009; "Specifica 7"; Text[200])
        {
            Caption = 'Specifica 7', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50010; "Specifica 8"; Text[200])
        {
            Caption = 'Specifica 8', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50011; "Specifica 9"; Text[200])
        {
            Caption = 'Specifica 9', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50012; "Specifica 10"; Text[200])
        {
            Caption = 'Specifica 10', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50013; "StatusItem"; Enum "StatusItem")
        {
            Caption = 'StatusItem';
            DataClassification = CustomerContent;
        }



    }
}
