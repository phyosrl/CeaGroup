tableextension 50006 "Purchase LinePTE" extends "Purchase Line"
{
    fields
    {
        field(50001; "Nr. Produttore"; Text[200])
        {
            Caption = 'Nr. Produttore', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50002; "Produttore"; Text[200])
        {
            Caption = 'Produttore', Locked = true;
            DataClassification = CustomerContent;
        }

    }

    trigger OnModify()
    var
        Item: Record "Item";
    begin
        if "Type" = "Type"::Item then begin
            codiceproduttore(Item);

        end;
    end;

    local procedure codiceproduttore(var Item: Record "Item")
    var
        ItemNo: Code[20];
    begin
        ItemNo := "No.";
        if Item.Get(ItemNo) then begin
            "Nr. Produttore" := Item."Nr. Produttore";
            "Produttore" := Item.Produttore;
        end else begin
            "Nr. Produttore" := ''; // Se non trovato, assegnare valore vuoto
            "Produttore" := ''; // Se non trovato, assegnare valore vuoto
        end;
    end;
}
