page 50009 noserie2
{
    APIGroup = 'api';
    APIPublisher = 'phyo';
    APIVersion = 'v2.0';
    ApplicationArea = All;
    Caption = 'noserie2';
    DelayedInsert = true;
    EntityName = 'noserie2';
    EntitySetName = 'noserie2';
    PageType = API;
    SourceTable = "No. Series Line";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(allowGapsInNos; Rec."Allow Gaps in Nos.")
                {
                    Caption = 'Allow Gaps in Nos.';
                }
                field(endingNo; Rec."Ending No.")
                {
                    Caption = 'Ending No.';
                }
                field(incrementByNo; Rec."Increment-by No.")
                {
                    Caption = 'Increment-by No.';
                }
                field(lastDateUsed; Rec."Last Date Used")
                {
                    Caption = 'Last Date Used';
                }
                field(lastNoUsed; Rec."Last No. Used")
                {
                    Caption = 'Last No. Used';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(open; Rec.Open)
                {
                    Caption = 'Open';
                }
                field(sequenceName; Rec."Sequence Name")
                {
                    Caption = 'Sequence Name';
                }
                field(seriesCode; Rec."Series Code")
                {
                    Caption = 'Series Code';
                }
                field(startingDate; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                }
                field(startingNo; Rec."Starting No.")
                {
                    Caption = 'Starting No.';
                }
                field(startingSequenceNo; Rec."Starting Sequence No.")
                {
                    Caption = 'Starting Sequence No.';
                }
                field(systemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'SystemCreatedAt';
                }
                field(systemCreatedBy; Rec.SystemCreatedBy)
                {
                    Caption = 'SystemCreatedBy';
                }
                field(systemId; Rec.SystemId)
                {
                    Caption = 'SystemId';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'SystemModifiedAt';
                }
                field(systemModifiedBy; Rec.SystemModifiedBy)
                {
                    Caption = 'SystemModifiedBy';
                }
                field(warningNo; Rec."Warning No.")
                {
                    Caption = 'Warning No.';
                }
            }
        }
    }
}
