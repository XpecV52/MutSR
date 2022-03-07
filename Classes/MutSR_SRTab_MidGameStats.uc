class MutSR_SRTab_MidGameStats extends MutSR_SRTab_Base;

var automated GUISectionBackground	i_BGPerks;
var	automated MutSR_SRStatListBox	lb_PerkSelect;

function ShowPanel(bool bShow)
{
	local MutSR_ClientPerkRepLink L;

	super.ShowPanel(bShow);

	if ( bShow )
	{
		L = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
		if ( L!=None )
			lb_PerkSelect.List.InitList(L);
	}
}

defaultproperties
{
	Begin Object class=GUISectionBackground Name=BGPerks
		WinWidth=0.96152
		WinHeight=0.796032
		WinLeft=0.019240
		WinTop=0.012063
		Caption="Stats"
		bFillClient=true
	End Object
	i_BGPerks=BGPerks

	Begin Object class=MutSR_SRStatListBox Name=StatSelectList
		WinWidth=0.94152
		WinHeight=0.742836
		WinLeft=0.029240
		WinTop=0.057760
	End Object
	lb_PerkSelect=StatSelectList
}