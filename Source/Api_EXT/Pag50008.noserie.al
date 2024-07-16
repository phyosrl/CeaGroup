page 50008 noserie
{
    APIGroup = 'api';
    APIPublisher = 'phyo';
    APIVersion = 'v2.0';
    ApplicationArea = All;
    Caption = 'noserie';
    DelayedInsert = true;
    EntityName = 'noserie';
    EntitySetName = 'noserie';
    PageType = API;
    SourceTable = "No. Series Line";
    
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(seriesCode; Rec."Series Code")
                {
                    Caption = 'Series Code';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(lastNoUsed; Rec."Last No. Used")
                {
                    Caption = 'Last No. Used';
                }
            }
        }
    }
}
