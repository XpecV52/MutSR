class MutSR_SRTab_MidGamePerks extends MutSR_SRTab_Base;

// begin KFTab_MidGamePerks
var automated GUISectionBackground	i_BGPerks;
var	automated MutSR_SRPerkSelectListBox	lb_PerkSelect;

var automated GUISectionBackground	i_BGPerkEffects;
var automated GUIScrollTextBox		lb_PerkEffects;

var automated GUISectionBackground	i_BGPerkNextLevel;
var	automated MutSR_SRPerkProgressListBox	lb_PerkProgress;

var	automated GUIButton	b_Save;
// end KFTab_MidGamePerks

var localized string NextInfoStr,PleaseWaitStr;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	// Init localized
	i_BGPerks.Caption = Class'KFTab_MidGamePerks'.Default.i_BGPerks.Caption;
	i_BGPerkEffects.Caption = Class'KFTab_MidGamePerks'.Default.i_BGPerkEffects.Caption;
	i_BGPerkNextLevel.Caption = Class'KFTab_MidGamePerks'.Default.i_BGPerkNextLevel.Caption;
	b_Save.Caption = Class'KFTab_MidGamePerks'.Default.b_Save.Caption;
	b_Save.Hint = Class'KFTab_MidGamePerks'.Default.b_Save.Hint;
	
	Super.InitComponent(MyController, MyOwner);

	lb_PerkSelect.List.OnChange = OnPerkSelected;
}

function ShowPanel(bool bShow)
{
	Super.ShowPanel(bShow);

	if ( bShow )
	{
		if ( Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner())!=none )
		{
			// Initialize the List
			lb_PerkSelect.List.InitList(None);
			lb_PerkProgress.List.InitList();
		}
	}
}

function OnPerkSelected(GUIComponent Sender)
{
	local MutSR_ClientPerkRepLink ST;
	local byte Idx;

	ST = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
	if ( ST==None || ST.CachePerks.Length==0 )
	{
		if( ST!=None )
			ST.ServerRequestPerks();
		lb_PerkEffects.SetContent(PleaseWaitStr);
	}
	else
	{
		Idx = lb_PerkSelect.GetIndex();
		if( ST.CachePerks[Idx].CurrentLevel==0 )
			lb_PerkEffects.SetContent(ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(0,1));
		else if( ST.CachePerks[Idx].CurrentLevel==ST.MaximumLevel )
			lb_PerkEffects.SetContent(ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel-1,1));
		else lb_PerkEffects.SetContent(ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel-1,1)$NextInfoStr$ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel,1));
		lb_PerkProgress.List.PerkChanged(None, Idx);
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
	// Begin KFTab
	Begin Object class=GUISectionBackground Name=BGPerks
		WinWidth=0.457166
		WinHeight=0.796032
		WinLeft=0.019240
		WinTop=0.012063
		bFillClient=true
	End Object
	i_BGPerks=BGPerks
	
	Begin Object class=GUISectionBackground Name=BGPerkEffects
		WinWidth=0.491566
		WinHeight=0.366816
		WinLeft=0.486700
		WinTop=0.012063
		bFillClient=true
	End Object
	i_BGPerkEffects=BGPerkEffects
	
	Begin Object class=GUISectionBackground Name=BGPerksNextLevel
		WinWidth=0.490282
		WinHeight=0.415466
		WinLeft=0.486700
		WinTop=0.392889
		bFillClient=true
	End Object
	i_BGPerkNextLevel=BGPerksNextLevel
	
	Begin Object Class=GUIButton Name=SaveButton
		StyleName="SquareButton"
		WinWidth=0.363829
		WinHeight=0.042757
		WinLeft=0.302670
		WinTop=0.822807
		TabOrder=2
		bBoundToParent=True
		OnClick=OnSaveButtonClicked
	End Object
	b_Save=SaveButton
	// End KFTab

	Begin Object Class=GUIScrollTextBox Name=PerkEffectsScroll
		WinWidth=0.465143
		WinHeight=0.313477
		WinLeft=0.500554
		WinTop=0.057760
		CharDelay=0.0025
		EOLDelay=0.1
		TabOrder=9
		StyleName="NoBackground"
	End Object
	lb_PerkEffects=PerkEffectsScroll

	Begin Object class=MutSR_SRPerkSelectListBox Name=PerkSelectList
		WinWidth=0.437166
		WinHeight=0.742836
		WinLeft=0.029240
		WinTop=0.057760
	End Object
	lb_PerkSelect=PerkSelectList

	Begin Object class=MutSR_SRPerkProgressListBox Name=PerkProgressList
		WinWidth=0.463858
		WinHeight=0.341256
		WinLeft=0.499269
		WinTop=0.476850
	End Object
	lb_PerkProgress=PerkProgressList

	NextInfoStr="||Next level effects:|"
	PleaseWaitStr="Please wait while your client is loading the perks..."
}