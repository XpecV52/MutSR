//=============================================================================
// The Trader menu with a tab for the store and the perks
//=============================================================================
class MutSR_SRGUIBuyMenu extends GUIBuyMenu;

function bool NotifyLevelChange()
{
	bPersistent = false;
	return true;
}
function InitTabs()
{
	local MutSR_SRKFTab_BuyMenu B;

	B = MutSR_SRKFTab_BuyMenu(c_Tabs.AddTab(PanelCaption[0], string(Class'MutSR_SRKFTab_BuyMenu'),, PanelHint[0]));
	c_Tabs.AddTab(PanelCaption[1], string(Class'MutSR_SRKFTab_Perks'),, PanelHint[1]);

	MutSR_SRBuyMenuFilter(BuyMenuFilter).SaleListBox = MutSR_SRBuyMenuSaleList(B.SaleSelect.List);
}

defaultproperties
{
	Begin Object class=MutSR_SRKFQuickPerkSelect Name=QS
		WinTop=0.011906
		WinLeft=0.008008
		WinWidth=0.316601
		WinHeight=0.082460
	End Object
	QuickPerkSelect=QS
	
	Begin Object Class=MutSR_SRWeightBar Name=WeightB
		WinTop=0.945302
		WinLeft=0.055266
		WinWidth=0.443888
		WinHeight=0.053896
	End Object
	WeightBar=WeightB
	
	Begin Object class=MutSR_SRBuyMenuFilter Name=MutSR_SRFilter
		WinTop=0.051
		WinLeft=0.67
		WinWidth=0.305
		WinHeight=0.082460
		RenderWeight=0.5
	End Object
	BuyMenuFilter=MutSR_SRFilter
}