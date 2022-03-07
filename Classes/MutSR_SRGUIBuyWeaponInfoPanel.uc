class MutSR_SRGUIBuyWeaponInfoPanel extends GUIBuyWeaponInfoPanel;

function Opened( GUIComponent Sender )
{
    super(GUIBuyDescInfoPanel).Opened( Sender );
}

function Display(GUIBuyable NewBuyable)
{
	if ( NewBuyable == none || NewBuyable.bIsFirstAidKit || NewBuyable.bIsVest )
	{
		b_power.SetValue(0);
		b_power.SetVisibility(false);
		b_speed.SetValue(0);
		b_speed.SetVisibility(false);
		b_range.SetValue(0);
		b_range.SetVisibility(false);

		ItemPower.SetVisibility(false);
		ItemRange.SetVisibility(false);
		ItemSpeed.SetVisibility(false);

		WeightLabel.SetVisibility(false);
		WeightLabelBG.SetVisibility(false);

		FavoriteButton.SetVisibility(false);
	}
	else
	{
		b_power.SetValue(NewBuyable.ItemPower);
		b_speed.SetValue(NewBuyable.ItemSpeed);
		b_range.SetValue(NewBuyable.ItemRange);

		b_power.SetVisibility(true);
		b_speed.SetVisibility(true);
		b_range.SetVisibility(true);

		ItemPower.SetVisibility(true);
		ItemRange.SetVisibility(true);
		ItemSpeed.SetVisibility(true);

		WeightLabel.SetVisibility(true);
		WeightLabelBG.SetVisibility(true);

        if( NewBuyable.bSaleList )
        {
    		FavoriteButton.SetVisibility(true);
    	}
    	else
    	{
    	   FavoriteButton.SetVisibility(false);
    	}
		bFavorited = (NewBuyable.ItemPickupClass!=None && Class'MutSR_SRClientSettings'.Static.IsFavorite( NewBuyable.ItemPickupClass ));
    	RefreshFavoriteButton();
	}

	if ( NewBuyable != none )
	{
		ItemName.Caption = NewBuyable.ItemName;
		ItemNameBG.bVisible = true;
		ItemImage.Image = NewBuyable.ItemImage;
		WeightLabel.Caption = Repl(Weight, "%i", int(NewBuyable.ItemWeight));

		OldPickupClass = NewBuyable.ItemPickupClass;
	}
	else
	{
		ItemName.Caption = "";
		ItemNameBG.bVisible = false;
		ItemImage.Image = none;
		WeightLabel.Caption = "";
	}

	Super(GUIBuyDescInfoPanel).Display(NewBuyable);
}

function bool InternalOnClick( GUIComponent Sender )
{
    if( Sender == FavoriteButton )
    {
        if( OldPickupClass != none )
        {
            if( bFavorited )
				Class'MutSR_SRClientSettings'.Static.RemoveFavorite(OldPickupClass);
            else Class'MutSR_SRClientSettings'.Static.AddFavorite(OldPickupClass);
			bFavorited = !bFavorited;
            RefreshFavoriteButton();
        }
    }

    return true;
}

defaultproperties
{
}