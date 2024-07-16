page 50006 DimensioniAPI2
{
    APIGroup = 'api';
    APIPublisher = 'phyo';
    APIVersion = 'v2.0';
    ApplicationArea = All;
    Caption = 'dimensioniAPI2';
    DelayedInsert = true;
    EntityName = 'DimensioniAPI2';
    EntitySetName = 'DimensioniAPI2';
    PageType = API;
    SourceTable = "Dimension Value";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(dimensionCode; Rec."Dimension Code")
                {
                    Caption = 'Dimension Code';
                }
                field("code"; Rec."Code")
                {
                    Caption = 'Code';
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
            }
        }
    }
}
