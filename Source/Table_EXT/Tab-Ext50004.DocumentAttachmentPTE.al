tableextension 50004 "Document AttachmentPTE" extends "Document Attachment"
{
    fields
    {
        field(50000; "Type Document"; Enum "Type Document PTE")
        {
            Caption = 'Type Document';
            DataClassification = CustomerContent;
        }
        field(50001; Revision; Text[30])
        {
            Caption = 'Revision';
            DataClassification = CustomerContent;
        }
        field(50002; "Date Revision"; Date)
        {
            Caption = 'Date Revision';
            DataClassification = CustomerContent;
        }
    }
}
