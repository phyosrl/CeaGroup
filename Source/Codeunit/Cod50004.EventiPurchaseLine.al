codeunit 50004 "EventiPurchaseLine"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInsertEvent', '', true, true)]
    local procedure OnAfterInsertPurchaseLine(var Rec: Record "Purchase Line")
    var
        Item: Record Item;
    begin
        if Rec."Type" = Rec."Type"::Item then begin
            // Check and copy the extended description
            if Item.Get(Rec."No.") then begin
                Rec."Nr. Produttore" := Item."Nr. Produttore";
                Rec."Produttore" := Item."Produttore";
            end else begin
                Rec."Nr. Produttore" := '';
                Rec."Produttore" := '';
            end;

            Rec.Modify(true);
        end;
    end;
}