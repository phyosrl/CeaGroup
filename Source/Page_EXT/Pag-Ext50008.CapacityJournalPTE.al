pageextension 50008 "Capacity JournalPTE" extends "Capacity Journal"
{
    layout
    {
        addlast(Control1)
        {
            field("Run Time"; Rec."Run Time")
            {
                ApplicationArea = Manufacturing;
                Visible = true;
            }
        }
    }
}
