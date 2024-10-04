reportextension 50001 "Standard Sales - Order ConfEXT" extends "Standard Sales - Order Conf."
{
    dataset
    {
        add(Header)
        {
            column(No__of_Archived_Versions; "No. of Archived Versions") { }
            column(Shortcut_Dimension_1_Code; "Shortcut Dimension 1 Code") { }
            column(Shortcut_Dimension_2_Code; "Shortcut Dimension 2 Code") { }
            column(BillToContact; "Bill-to Contact") { }
            column(shipToContact; "ship-to Contact") { }
            column(sellToContact; "sell-to Contact") { }
            column(Bill_to_County; "Bill-to County") { }
            column(Sell_to_Country_Region_Code; "Sell-to Country/Region Code") { }
            column(Ship_to_Country_Region_Code; "Ship-to Country/Region Code") { }
            column(Bill_to_City; "Bill-to City") { }
            column(Ship_to_City; "Ship-to City") { }
            column(Sell_to_City; "Sell-to City") { }
            column(Bill_to_Address; "Bill-to Address") { }
            column(Ship_to_Address; "Ship-to Address") { }
            column(Sell_to_Address; "Sell-to Address") { }
            column(Sell_to_Address_2; "Sell-to Address 2") { }
            column(Ship_to_Address_2; "Ship-to Address 2") { }
            column(Bill_to_Address_2; "Bill-to Address 2") { }
            column(Ship_to_Post_Code; "Ship-to Post Code") { }
            column(Sell_to_Post_Code; "Sell-to Post Code") { }
            column(Bill_to_Post_Code; "Bill-to Post Code") { }
            column(Bill_to_Name; "Bill-to Name") { }
            column(Ship_to_Name; "Ship-to Name") { }
            column(Sell_to_Customer_Name; "Sell-to Customer Name") { }
        }
    }
}
