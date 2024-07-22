codeunit 50000 "CEA General PTE"
{
    procedure GetDefaultLocationCode() O_Code: Code[10]
    begin
        exit('SEDE')
    end;

    procedure GetDefalutRoutingLink() O_Code: Code[10]
    begin
        exit('AUTO')
    end;

    procedure GetDefalutUM() O_Code: Code[10]
    begin
        exit('NR')
    end;

    procedure GetDefaultItemJournalNameAPI(): Text[10]
    begin
        exit('WEBAPI');
    end;

    procedure GetDefaultOperationNo(): Text[10]
    begin
        exit('10');
    end;

    procedure GetDefaultWorkCenterCode(): Text[10]
    var
        L_RWorkCenter: Record "Work Center";
    begin
        if not L_RWorkCenter.Get('A1') then begin
            L_RWorkCenter."No." := 'A1';
            L_RWorkCenter.Name := 'Reparto Assemblaggio';
            L_RWorkCenter.Insert();
        end;
        exit('A1');
    end;

    procedure GetDefaultCLItemCategoryCode(): Text[10]
    // articolo per articoli conto lavoro
    begin
        exit('CL');
    end;

    procedure GetDefaultMPItemCategoryCode(): Text[10]
    // articolo per articoli conto lavoro
    begin
        exit('MP');
    end;

    procedure GetDefaultItemCategoryCode(): Text[10]
    // articolo per articoli conto lavoro
    begin
        exit('IT');
    end;
}