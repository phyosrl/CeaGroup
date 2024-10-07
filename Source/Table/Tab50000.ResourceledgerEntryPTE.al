table 50000 "Resource ledger Entry PTE"
{
    Caption = 'Resource ledger Entry PTE';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(10; "Resource No."; code[20])
        {
            Caption = 'Nr. risorsa', Locked = true;
            TableRelation = Resource;
        }
        field(20; Quantity; Decimal)
        {
            Caption = 'Quantità', Locked = true;
            DecimalPlaces = 0 : 5;
        }
        field(21; Cost; Decimal)
        {
            Caption = 'Costo', Locked = true;
            DecimalPlaces = 0 : 5;
        }
        field(22; Total; Decimal)
        {
            Caption = 'Costo', Locked = true;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        Modify();
        if OldDimSetID <> "Dimension Set ID" then begin
            if not IsNullGuid(Rec.SystemId) then
                Modify();

        end;
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin


        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", '',
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then
            Modify();
    end;

    var
        DimMgt: Codeunit DimensionManagement;
}
// doamnde:
// costo unitario da anagrafica risorsa : fisso o posso cambiarlo?
// UM dalla risorsa : fisso o posso cambiarlo
// COD TIPO LAVORO = codice da tabella generica?
// ID ATTIVITA = COdice da tabella generica?
// DESCRIZIONE ATTIVITA = descrizione "ID ATTIVITA", fissa e calcolata o campo libero editabile?