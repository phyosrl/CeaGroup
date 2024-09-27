pageextension 50007 "Sales Order SubformPTE" extends "Sales Order Subform"
{
    layout
    {
        addafter("Quantity")
        {
            field("Stato Riga"; Rec."Stato Riga")
            {
                ApplicationArea = All;
                Caption = 'Stato Riga';
                Editable = False;
                Visible = false;
            }
            field("Quantita prenotata"; Rec."Quantita prenotata")
            {
                ApplicationArea = All;
                Caption = 'Quantita prenotata';
                Editable = False;
                Visible = false;
            }
            field(GStatoRiga; GStatoRiga)
            {
                ApplicationArea = All;
                Caption = 'Stato Riga', Locked = true;
                Editable = False;
                Visible = true;
                trigger OnDrillDown()
                var
                    L_ResEntry: record "Reservation Entry";
                begin
                    L_ResEntry.SetRange("Source Type", Database::"Sales Line");
                    L_ResEntry.SetRange("Source ID", Rec."Document No.");
                    L_ResEntry.SetRange("Source Subtype", Rec."Document Type");
                    L_ResEntry.SetRange("Reservation Status", L_ResEntry."Reservation Status"::Reservation);
                    if L_ResEntry.FindSet() then
                        page.Run(page::"Reservation Entries", L_ResEntry);
                end;
            }
        }
    }
    var
        GStatoRiga: Text;

    trigger OnAfterGetRecord()
    begin
        F_CalcStatoRiga();
    end;

    local procedure F_CalcStatoRiga()
    begin
        // Verifica le condizioni per impostare lo Stato Riga
        case true of
            Rec."Reserved Quantity" = 0:
                GStatoRiga := 'Da Gestire';
            Rec."Reserved Quantity" < Rec.Quantity:
                GStatoRiga := 'Gestito Parzialmente';
            Rec."Reserved Quantity" >= Rec.Quantity:
                GStatoRiga := 'Gestito Totale';
        end;
    end;
}
