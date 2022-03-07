//-----------------------------------------------------------
//
//-----------------------------------------------------------
class MutSR_SRBuyMenuSaleListBox extends KFBuyMenuSaleListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(Class'MutSR_SRBuyMenuSaleList');
	Super.InitComponent(MyController,MyOwner);
}
function GUIBuyable GetSelectedBuyable()
{
	return MutSR_SRBuyMenuSaleList(List).GetSelectedBuyable();
}

defaultproperties
{
}
