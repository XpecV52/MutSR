//-----------------------------------------------------------
//
//-----------------------------------------------------------
class MutSR_SRKFTab_Perks extends KFTab_Perks;

function ShowPanel(bool bShow)
{
	super(UT2K4TabPanel).ShowPanel(bShow);

	if ( bShow )
	{
		if ( Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner())!=None )
		{
			// Initialize the List
			lb_PerkSelect.List.InitList(None);
			lb_PerkProgress.List.InitList();
		}
		l_ChangePerkOncePerWave.SetVisibility(false);
	}
}
function OnPerkSelected(GUIComponent Sender)
{
	local MutSR_ClientPerkRepLink ST;
	local byte Idx;
	local string S;

	ST = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
	if ( ST==None || ST.CachePerks.Length==0 )
	{
		if( ST!=None )
			ST.ServerRequestPerks();
		lb_PerkEffects.SetContent("Please wait while your client is loading the perks...");
	}
	else
	{
		Idx = lb_PerkSelect.GetIndex();
		if( ST.CachePerks[Idx].CurrentLevel==0 )
			S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(0,1);
		else if( ST.CachePerks[Idx].CurrentLevel==ST.MaximumLevel )
			S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel-1,1);
		else S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel-1,1)$Class'MutSR_SRTab_MidGamePerks'.Default.NextInfoStr$ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel,1);
		lb_PerkEffects.SetContent(S);
		lb_PerkProgress.List.PerkChanged(KFStatsAndAchievements, Idx);
	}
}

function bool OnSaveButtonClicked(GUIComponent Sender)
{
	local MutSR_ClientPerkRepLink ST;

	ST = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
	if ( ST!=None && lb_PerkSelect.GetIndex()>=0 )
		ST.ServerSelectPerk(ST.CachePerks[lb_PerkSelect.GetIndex()].PerkClass);
	return true;
}

defaultproperties
{
	Begin Object class=MutSR_SRPerkSelectListBox Name=PerkSelectList
		WinWidth=0.437166
		WinHeight=0.742836  //0.772836
		WinLeft=0.029240
		WinTop=0.091627
	End Object
	lb_PerkSelect=PerkSelectList

	Begin Object class=MutSR_SRPerkProgressListBox Name=PerkProgressList
		WinWidth=0.463858
		WinHeight=0.341256
		WinLeft=0.499269
		WinTop=0.476850
	End Object
	lb_PerkProgress=PerkProgressList
}

