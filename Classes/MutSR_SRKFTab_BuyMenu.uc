//=============================================================================
// The actual trader menu
//=============================================================================
class MutSR_SRKFTab_BuyMenu extends KFTab_BuyMenu;

var Class<Pickup> SelectedItem;
var() localized string ArchivementGetInfo;
struct FIDPair
{
	var int ID;
	var string Name;
};
var array<FIDPair> DLCMap;
var int InventoryHash,iFrameCounter;
var class<KFVeterancyTypes> OldPerkClass;

function Timer()
{
	local int i;
	
	++iFrameCounter;
	i = GetInventoryHash();
	if( i!=InventoryHash )
	{
		InventoryHash = i;
		MoneyLabel.Caption = MoneyCaption $ int(PlayerOwner().PlayerReplicationInfo.Score);
		UpdateAll();
	}
}
function UpdateCheck();

final function int GetInventoryHash() // Get Inventory ID hash to check for changes.
{
	local int i,n;
	local Inventory Inv;
	local KFWeapon W;
	local PlayerController PC;
	local class<KFVeterancyTypes> V;
	
	PC = PlayerOwner();
	if( PC.Pawn==None || KFPlayerReplicationInfo(PC.PlayerReplicationInfo)==None )
		return (iFrameCounter>>3);
	
	// Force update hash if perk is changed.
	if( KFPlayerReplicationInfo(PC.PlayerReplicationInfo)!=None )
		V = KFPlayerReplicationInfo(PC.PlayerReplicationInfo).ClientVeteranSkill;
	if( OldPerkClass!=V )
	{
		OldPerkClass = V;
		InventoryHash = 0;
	}

	i = (int(PC.PlayerReplicationInfo.Score) << 6) ^ (iFrameCounter>>7) ^ int(PC.Pawn.ShieldStrength);
	for( Inv=PC.Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		++n;
		W = KFWeapon(Inv);
		if( W!=None )
		{
			n += 15;
			i = i ^ (int(W.Weight)>>1) ^ (W.SleeveNum<<3) ^ (int(W.PlayerViewOffset.X)<<4) ^ (W.AmmoAmount(0)<<16);
		}
	}
	return (i ^ n);
}
final function RefreshSelection()
{
	if( SaleSelect.List.Index==-1 )
	{
		if( InvSelect.List.Index!=-1 )
			TheBuyable = InvSelect.GetSelectedBuyable();
		else TheBuyable = None;
	}
	else TheBuyable = SaleSelect.GetSelectedBuyable();
}
function OnAnychange()
{
	RefreshSelection();
	Super.OnAnychange();
}
function bool InternalOnClick(GUIComponent Sender)
{
	RefreshSelection();
	return Super.InternalOnClick(Sender);
}
function UpdateAll()
{
	InvSelect.List.UpdateMyBuyables();
	SaleSelect.List.UpdateForSaleBuyables();

	RefreshSelection();
	GetUpdatedBuyable();
	UpdatePanel();
}
function UpdateBuySellButtons()
{
	RefreshSelection();
	if ( InvSelect.List.Index==-1 || TheBuyable==None || !TheBuyable.bSellable )
		SaleButton.DisableMe();
	else SaleButton.EnableMe();

	if ( SaleSelect.List.Index==-1 || TheBuyable==None || SaleSelect.List.CanBuys[SaleSelect.List.Index]!=1 )
		PurchaseButton.DisableMe();
	else PurchaseButton.EnableMe();
}
function GetUpdatedBuyable(optional bool bSetInvIndex)
{
	InvSelect.List.UpdateMyBuyables();
	RefreshSelection();
}
function UpdateAutoFillAmmo()
{
	Super.UpdateAutoFillAmmo();
	RefreshSelection();
}

function SaleChange(GUIComponent Sender)
{
	InvSelect.List.Index = -1;
	
	TheBuyable = SaleSelect.GetSelectedBuyable();

	if( TheBuyable==None ) // Selected category.
	{
		GUIBuyMenu(OwnerPage()).WeightBar.NewBoxes = 0;
		if( SaleSelect.List.Index>=0 && SaleSelect.List.CanBuys[SaleSelect.List.Index]>1 )
		{
			MutSR_SRBuyMenuSaleList(SaleSelect.List).SetCategoryNum(SaleSelect.List.CanBuys[SaleSelect.List.Index]-3);
		}
	}
	else GUIBuyMenu(OwnerPage()).WeightBar.NewBoxes = TheBuyable.ItemWeight;
	OnAnychange();
}
function bool SaleDblClick(GUIComponent Sender)
{
	InvSelect.List.Index = -1;
	
	TheBuyable = SaleSelect.GetSelectedBuyable();

	if( TheBuyable==None ) // Selected category.
	{
		GUIBuyMenu(OwnerPage()).WeightBar.NewBoxes = 0;
	}
	else
	{
		GUIBuyMenu(OwnerPage()).WeightBar.NewBoxes = TheBuyable.ItemWeight;
		if ( SaleSelect.List.CanBuys[SaleSelect.List.Index]==1 )
		{
			DoBuy();
   			TheBuyable = none;
		}
	}
	OnAnychange();
	return false;
}

final function string InitNewDLCName( int ID )
{
	local int i;
	local MutSR_SRSteamStatsGet ST;
	local string S;
	
	// Grab DLC name through an ugly hack.
	Class'MutSR_SRSteamStatsGet'.Default.bNoInit = true;
	ST = PlayerOwner().Spawn(Class'MutSR_SRSteamStatsGet');
	Class'MutSR_SRSteamStatsGet'.Default.bNoInit = false;
	S = ST.GetWeaponDLCPackName(ID);
	ST.Destroy();
	
	if( S=="" ) // Misc, unnamed.
		S = "Unknown";

	// Cache result.
	i = DLCMap.Length;
	DLCMap.Length = i+1;
	DLCMap[i].ID = ID;
	DLCMap[i].Name = S;
	return S;
}
final function string GetDLCName( int ID )
{
	local int i;

	// See if already cached.
	for( i=0; i<DLCMap.Length; ++i )
		if( DLCMap[i].ID==ID )
			return DLCMap[i].Name;
			
	// Cache new one.
	return InitNewDLCName(ID);
}
function SetInfoText()
{
	local string TempString;

	if ( TheBuyable == none && !bDidBuyableUpdate )
	{
		InfoScrollText.SetContent(InfoText[0]);
		bDidBuyableUpdate = true;

		return;
	}

	if ( TheBuyable != none && OldPickupClass != TheBuyable.ItemPickupClass )
	{
		// Unowned Weapon DLC
		if( TheBuyable.bSaleList && TheBuyable.ItemAmmoCurrent>0 )
		{
			if( TheBuyable.ItemAmmoCurrent==1 )
				InfoScrollText.SetContent(Repl(InfoText[4], "%1", GetDLCName(TheBuyable.ItemWeaponClass.Default.AppID)));
			else if( TheBuyable.ItemAmmoCurrent==2 )
				InfoScrollText.SetContent(Repl(ArchivementGetInfo, "%1", Class'MutSR_SRSteamStatsGet'.Default.Achievements[TheBuyable.ItemWeaponClass.Default.UnlockedByAchievement].DisplayName));
			else InfoScrollText.SetContent(Mid(TheBuyable.ItemCategorie,InStr(TheBuyable.ItemCategorie,":")+1));
		}
		// Too expensive
		else if ( TheBuyable.ItemCost > PlayerOwner().PlayerReplicationInfo.Score && TheBuyable.bSaleList )
		{
			InfoScrollText.SetContent(InfoText[2]);
		}
		// Too heavy
		else if ( TheBuyable.ItemWeight + KFHumanPawn(PlayerOwner().Pawn).CurrentWeight > KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight && TheBuyable.bSaleList )
		{
			TempString = Repl(Infotext[1], "%1", int(TheBuyable.ItemWeight));
			TempString = Repl(TempString, "%2", int(KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight - KFHumanPawn(PlayerOwner().Pawn).CurrentWeight));
			InfoScrollText.SetContent(TempString);
		}
		// default
		else if( TheBuyable.ItemWeaponClass!=None )
			InfoScrollText.SetContent(TheBuyable.ItemWeaponClass.Default.Description);
		else InfoScrollText.SetContent(InfoText[0]);

		bDidBuyableUpdate = false;
		OldPickupClass = TheBuyable.ItemPickupClass;
	}
}

defaultproperties
{
	InfoText(4)="This weapon requires '%1' DLC pack."
	ArchivementGetInfo="This weapon requires archivement '%1' to be unlocked."

	Begin Object class=MutSR_SRKFBuyMenuInvListBox Name=InventoryBox
		WinTop=0.070841
		WinLeft=0.000108
		WinWidth=0.328204
		WinHeight=0.521856
	End Object
	InvSelect=InventoryBox

	Begin Object class=MutSR_SRBuyMenuSaleListBox Name=SaleBox
		WinTop=0.064312
		WinLeft=0.672632
		WinWidth=0.325857
		WinHeight=0.674039
	End Object
	SaleSelect=SaleBox
	
	Begin Object class=MutSR_SRGUIBuyWeaponInfoPanel Name=ItemInf
		WinTop=0.193730
		WinLeft=0.332571
		WinWidth=0.333947
		WinHeight=0.489407
		Hint=""
	End Object
	ItemInfo=ItemInf
	
	// Default DLC weapons.
	DLCMap(0)=(ID=258751,Name="IJC Weapons 3")
	DLCMap(1)=(ID=210944,Name="Golden Weapons 2")
	DLCMap(2)=(ID=210938,Name="Golden Weapons")
	DLCMap(3)=(ID=210934,Name="IJC Weapons")
	DLCMap(4)=(ID=210943,Name="IJC Weapons 2")
	DLCMap(5)=(ID=258752,Name="Camo Weapons")
	DLCMap(6)=(ID=309991,Name="Neon Weapons")
}