reportextension 50002 "Standard Purchase - OrderEXT" extends "Standard Purchase - Order"
{
    dataset
    {
        add("Purchase Line")
        {
            // add field from table extending Customer
            column(Shortcut_Dimension_1_Code; "Shortcut Dimension 1 Code") { }
            column(Shortcut_Dimension_2_Code; "Shortcut Dimension 2 Code") { }
            column(Nr__Produttore; "Nr. Produttore") { }
            column(Produttore; "Produttore") { }

        }

    }
}
