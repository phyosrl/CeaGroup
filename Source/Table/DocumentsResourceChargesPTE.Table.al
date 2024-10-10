// table 50000 "Documents Resource Charges PTE"
// {
//     Caption = 'Spese risorse documenti';
//     DataClassification = CustomerContent;

//     fields
//     {
//         field(1; "Tipo Documento"; Enum "Tipo Documento Mov. risorsa")
//         {
//             Caption = 'Tipo Documento';
//         }
//         field(2; "Nr. documento"; Code[20])
//         {
//             Caption = 'Nr. documento';
//         }
//         field(3; "Nr. riga documento"; Integer)
//         {
//             Caption = 'Nr. riga documento';
//         }
//         field(10; "Nr. risorsa"; code[20])
//         {
//             Caption = 'Nr. risorsa', Locked = true;
//             TableRelation = Resource;
//         }
//         field(20; Quantità; Decimal)
//         {
//             Caption = 'Quantità', Locked = true;
//             DecimalPlaces = 0 : 5;
//         }
//         field(21; "Costo unitario"; Decimal)
//         {
//             Caption = 'Costo unitario', Locked = true;
//             DecimalPlaces = 0 : 5;
//         }
//         field(22; Totale; Decimal)
//         {
//             Caption = 'Totale', Locked = true;
//             DecimalPlaces = 0 : 5;
//             Editable = false;
//         }
//         field(29; "Shortcut Dimension 1 Code"; Code[20])
//         {
//             CaptionClass = '1,2,1';
//             Caption = 'Codice tipologia ordine';
//             TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
//                                                           Blocked = const(false));

//             trigger OnValidate()
//             begin
//                 Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
//             end;
//         }
//         field(30; "Shortcut Dimension 2 Code"; Code[20])
//         {
//             CaptionClass = '1,2,2';
//             Caption = 'Shortcut Dimension 2 Code';
//             TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
//                                                           Blocked = const(false));
//             trigger OnValidate()
//             begin
//                 Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
//             end;
//         }
//         field(5407; "Unit of Measure Code"; Code[10])
//         {
//             Caption = 'Unit of Measure Code';
//             TableRelation = "Resource Unit of Measure".Code where("Resource No." = field("Resource No."));
//         }
//         field(50; "Work Type Code"; code[20])
//         {
//             Caption = 'Cod. tipo lavorazione', Locked = true;
//             TableRelation = "Work Type";
//             trigger OnValidate()
//             var
//                 L_RWorkType: record "Work Type";
//             begin
//                 IF L_RWorkType.get(rec."Work Type Code") then begin
//                     Description := L_RWorkType.Description;
//                     if L_RWorkType."Unit of Measure Code" <> '' THEN
//                         Rec.Validate("Unit of Measure Code", L_RWorkType."Unit of Measure Code");
//                 end;

//             end;
//         }
//         field(60; "Description"; Text[200])
//         {
//             Caption = 'Descrizione', Locked = true;
//         }
//         field(480; "Dimension Set ID"; Integer)
//         {
//             Caption = 'Dimension Set ID';
//             Editable = false;
//             TableRelation = "Dimension Set Entry";

//             trigger OnLookup()
//             begin
//                 Rec.ShowDocDim();
//             end;

//             trigger OnValidate()
//             begin
//                 DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
//             end;
//         }
//     }
//     keys
//     {
//         key(Key1; "Table Name", "No.", "Line No.")
//         {
//             Clustered = true;
//         }
//     }
//     procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
//     var
//         OldDimSetID: Integer;
//         IsHandled: Boolean;
//     begin
//         OldDimSetID := "Dimension Set ID";
//         DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
//         Modify();
//         if OldDimSetID <> "Dimension Set ID" then begin
//             if not IsNullGuid(Rec.SystemId) then
//                 Modify();

//         end;
//     end;

//     procedure ShowDocDim()
//     var
//         OldDimSetID: Integer;
//         IsHandled: Boolean;
//     begin


//         OldDimSetID := "Dimension Set ID";
//         "Dimension Set ID" :=
//           DimMgt.EditDimensionSet(
//             Rec, "Dimension Set ID", '',
//             "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
//         if OldDimSetID <> "Dimension Set ID" then
//             Modify();
//     end;

//     var
//         DimMgt: Codeunit DimensionManagement;
// }

