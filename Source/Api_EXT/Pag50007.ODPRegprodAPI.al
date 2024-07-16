page 50007 ODPRegprodAPI
{
    APIGroup = 'api';
    APIPublisher = 'phyo';
    APIVersion = 'v2.0';
    ApplicationArea = All;
    Caption = 'odpRegprodAPI';
    DelayedInsert = true;
    EntityName = 'ODPRegprodAPI';
    EntitySetName = 'ODPRegprodAPI';
    PageType = API;
    SourceTable = "Item Journal Line";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(journalTemplateName; Rec."Journal Template Name")
                {
                    Caption = 'Journal Template Name';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(entryType; Rec."Entry Type")
                {
                    Caption = 'Entry Type';
                }
                field(sourceNo; Rec."Source No.")
                {
                    Caption = 'Source No.';
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(inventoryPostingGroup; Rec."Inventory Posting Group")
                {
                    Caption = 'Inventory Posting Group';
                }
                field(sourceCode; Rec."Source Code")
                {
                    Caption = 'Source Code';
                }
                field(sourceType; Rec."Source Type")
                {
                    Caption = 'Source Type';
                }
                field(outputQuantity; Rec."Output Quantity")
                {
                    Caption = 'Output Quantity';
                }
                field(runTime; Rec."Run Time")
                {
                    Caption = 'Run Time';
                }
                field(Type; Rec."Type")
                {
                    Caption = 'Type';
                }
                field(operationNo; Rec."Operation No.")
                {
                    Caption = 'Operation No.';
                }
                field(workCenterNo; Rec."Work Center No.")
                {
                    Caption = 'Work Center No.';
                }
            }
        }
    }
}
