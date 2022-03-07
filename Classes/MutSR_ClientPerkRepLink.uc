Class MutSR_ClientPerkRepLink extends LinkedReplicationInfo
	DependsOn(MutSR_SRHUDKillingFloor);

var int RDamageHealedStat, RWeldingPointsStat, RShotgunDamageStat, RHeadshotKillsStat, RChainsawKills,
		RStalkerKillsStat, RBullpupDamageStat, RMeleeDamageStat, RFlameThrowerDamageStat,RTotalZedTimeStat,
		RSelfHealsStat, RSoleSurvivorWavesStat, RCashDonatedStat, RFeedingKillsStat,RHuntingShotgunKills,
		RBurningCrossbowKillsStat, RGibbedFleshpoundsStat, RStalkersKilledWithExplosivesStat,
		RGibbedEnemiesStat, RBloatKillsStat, RSirenKillsStat, RKillsStat, RMedicKnifeKills, RExplosivesDamageStat,
		TotalPlayTime, WinsCount, LostsCount;
var byte MinimumLevel,MaximumLevel;
var float NextRepTime,RequirementScaling;
var int ClientAccknowledged[2],SendIndex,ClientAckSkinNum;

struct FPerksListType
{
	var class<MutSR_SRVeterancyTypes> PerkClass;
	var byte CurrentLevel;
};
var array<FPerksListType> CachePerks;

var MutSR_SRStatsBase StatObject;

struct FShopItemIndex
{
	var class<Pickup> PC;
	var byte CatNum,bDLCLocked;
};
struct FShopCategoryIndex
{
	var string Name;
	var byte PerkIndex;
};
var array<FShopItemIndex> ShopInventory;
var array<Material> ShopPerkIcons;
var array<FShopCategoryIndex> ShopCategories;
var array<string> CustomChars;
var array<GUIBuyable> AllocatedObjects;
var array<MutSR_SRHUDKillingFloor.SmileyMessageType> SmileyTags;
var int CurrentPerkProgress;
var KFPlayerReplicationInfo OwnerPRI;

var MutSR_SRCustomProgress CustomLink;
var string ServerWebSite,UserID;

var bool bMinimalRequirements,bBWZEDTime,bNoStandardChars,bReceivedURL,bRepCompleted;

replication
{
	reliable if( Role==ROLE_Authority && bNetOwner )
		RDamageHealedStat, RWeldingPointsStat, RShotgunDamageStat, RHeadshotKillsStat, RChainsawKills,
		RStalkerKillsStat, RBullpupDamageStat, RMeleeDamageStat, RFlameThrowerDamageStat,
		RSelfHealsStat, RSoleSurvivorWavesStat, RCashDonatedStat, RFeedingKillsStat, RHuntingShotgunKills,
		RBurningCrossbowKillsStat, RGibbedFleshpoundsStat, RStalkersKilledWithExplosivesStat, RExplosivesDamageStat,
		RGibbedEnemiesStat, RBloatKillsStat, RTotalZedTimeStat, RSirenKillsStat, RKillsStat, RMedicKnifeKills,
		TotalPlayTime, WinsCount, LostsCount, bBWZEDTime, bNoStandardChars,
		MinimumLevel, RequirementScaling, MaximumLevel, bMinimalRequirements,CustomLink;

	// Functions server can call.
	reliable if( Role == ROLE_Authority )
		ClientReceivePerk,ClientPerkLevel,ClientReceiveWeapon,ClientSendAcknowledge,ClientReceiveCategory,
		ClientReceiveChar,ClientReceiveTag,ClientAllReceived,ClientReceiveURL;

	reliable if( Role < ROLE_Authority )
		ServerSelectPerk,ServerRequestPerks,ServerAcnowledge,ServerSetCharacter,ServerAckSkin;
}

function Destroyed()
{
	local MutSR_SRCustomProgress S,NS;

	for( S=CustomLink; S!=None; S=NS )
	{
		NS = S.NextLink;
		S.Destroy();
	}
	Super.Destroyed();
}

simulated final function string GetCustomValue( class<MutSR_SRCustomProgress> C )
{
	local MutSR_SRCustomProgress S;

	for( S=CustomLink; S!=None; S=S.NextLink )
		if( S.Class.Name==C.Name )
			return S.GetProgress();
	return "";
}
simulated final function int GetCustomValueInt( class<MutSR_SRCustomProgress> C )
{
	local MutSR_SRCustomProgress S;

	for( S=CustomLink; S!=None; S=S.NextLink )
		if( S.Class.Name==C.Name )
			return S.GetProgressInt();
	return 0;
}
final function MutSR_SRCustomProgress AddCustomValue( class<MutSR_SRCustomProgress> C )
{
	local MutSR_SRCustomProgress S,Last;

	for( S=CustomLink; S!=None; S=S.NextLink )
	{
		Last = S;
		if( S.Class.Name==C.Name )
			return S;
	}
	S = Spawn(C,Owner);
	S.RepLink = Self;

	// Add new one in the end of the chain.
	if( Last!=None )
		Last.NextLink = S;
	else CustomLink = S;
	return S;
}
final function ProgressCustomValue( class<MutSR_SRCustomProgress> C, int Count )
{
	local MutSR_SRCustomProgress S;

	for( S=CustomLink; S!=None; S=S.NextLink )
	{
		if( S.Class.Name==C.Name )
		{
			S.IncrementProgress(Count);
			break;
		}
	}
}

final function SpawnCustomLinks()
{
	local int i;

	for( i=0; i<CachePerks.Length; ++i )
		CachePerks[i].PerkClass.Static.AddCustomStats(Self);
}

simulated static final function MutSR_ClientPerkRepLink FindStats( PlayerController Other )
{
	local LinkedReplicationInfo L;
	local MutSR_ClientPerkRepLink C;

	if( Other.PlayerReplicationInfo==None )
	{
		foreach Other.DynamicActors(Class'MutSR_ClientPerkRepLink',C)
			if( C.Owner==Other )
			{
				C.RepLinkBroken();
				return C;
			}
		return None; // Not yet init.
	}
	for( L=Other.PlayerReplicationInfo.CustomReplicationInfo; L!=None; L=L.NextReplicationInfo )
		if( MutSR_ClientPerkRepLink(L)!=None )
			return MutSR_ClientPerkRepLink(L);
	if( Other.Level.NetMode!=NM_Client )
		return None; // Not yet init.
	foreach Other.DynamicActors(Class'MutSR_ClientPerkRepLink',C)
		if( C.Owner==Other )
		{
			C.RepLinkBroken();
			return C;
		}
	return None;
}

simulated function Tick( float DeltaTime )
{
	local PlayerController PC;
	local LinkedReplicationInfo L;

	if( Level.NetMode==NM_DedicatedServer )
	{
		Disable('Tick');
		return;
	}
	PC = Level.GetLocalPlayerController();
	if( Level.NetMode!=NM_Client && PC!=Owner )
	{
		Disable('Tick');
		return;
	}
	if( PC.PlayerReplicationInfo==None )
		return;
	Disable('Tick');
	Class'MutSR_SRLevelCleanup'.Static.AddSafeCleanup(PC);

	if( PC.PlayerReplicationInfo.CustomReplicationInfo!=None )
	{
		for( L=PC.PlayerReplicationInfo.CustomReplicationInfo; L!=None; L=L.NextReplicationInfo )
			if( L==Self )
				return; // Make sure not already added.

		NextReplicationInfo = None;
		for( L=PC.PlayerReplicationInfo.CustomReplicationInfo; L!=None; L=L.NextReplicationInfo )
			if( L.NextReplicationInfo==None )
			{
				L.NextReplicationInfo = Self; // Add to the end of the chain.
				return;
			}
	}
	PC.PlayerReplicationInfo.CustomReplicationInfo = Self;
}
simulated final function RepLinkBroken() // Called by GUI when this is noticed.
{
	Enable('Tick');
	Tick(0);
}

final function Class<MutSR_SRVeterancyTypes> PickRandomPerk()
{
	local array< class<MutSR_SRVeterancyTypes> > CA;
	local int i;

	for( i=0; i<CachePerks.Length; i++ )
	{
		if( CachePerks[i].PerkClass!=None && CachePerks[i].CurrentLevel>0 )
			CA[CA.Length] = CachePerks[i].PerkClass;
	}
	if( CA.Length==0 )
		return None;
	return CA[Rand(CA.Length)];
}
final function ServerSelectPerk( Class<MutSR_SRVeterancyTypes> VetType )
{
	StatObject.ServerSelectPerk(VetType);
}
final function ServerRequestPerks()
{
	if( NextRepTime<Level.TimeSeconds )
		SendClientPerks();
}
final function SendClientPerks()
{
	local byte i;

	if( !StatObject.bStatsReadyNow )
		return;
	NextRepTime = Level.TimeSeconds+2.f;
	for( i=0; i<CachePerks.Length; i++ )
		ClientReceivePerk(i,CachePerks[i].PerkClass,CachePerks[i].CurrentLevel);
}
simulated function ClientReceivePerk( int Index, class<MutSR_SRVeterancyTypes> V, byte Level )
{
	// Setup correct icon for trader.
	if( V.Default.PerkIndex<255 && V.Default.OnHUDIcon!=None )
	{
		if( ShopPerkIcons.Length<=V.Default.PerkIndex )
			ShopPerkIcons.Length = V.Default.PerkIndex+1;
		ShopPerkIcons[V.Default.PerkIndex] = V.Default.OnHUDIcon;
	}

	if( CachePerks.Length<=Index )
		CachePerks.Length = (Index+1);
	CachePerks[Index].PerkClass = V;
	CachePerks[Index].CurrentLevel = Level;
}
simulated function ClientPerkLevel( int Index, byte CurLevel )
{
	Level.GetLocalPlayerController().ReceiveLocalizedMessage(Class'MutSR_KFVetEarnedMessageSR',(CurLevel-1),,,CachePerks[Index].PerkClass);
	CachePerks[Index].CurrentLevel = CurLevel;
}

simulated function ClientReceiveWeapon( int Index, class<Pickup> P, byte Categ )
{
	ShopInventory.Length = Max(ShopInventory.Length,Index+1);
	if( ShopInventory[Index].PC==None )
	{
		ShopInventory[Index].PC = P;
		ShopInventory[Index].CatNum = Categ;
		if( class<KFWeapon>(P.Default.InventoryType)!=none
		 && (class<KFWeapon>(P.Default.InventoryType).Default.AppID>0
		 || class<KFWeapon>(P.Default.InventoryType).Default.UnlockedByAchievement!=-1) )
			ShopInventory[Index].bDLCLocked = 1;
		++ClientAccknowledged[0];
	}
}
simulated function ClientReceiveCategory( byte Index, FShopCategoryIndex S )
{
	ShopCategories.Length = Max(ShopCategories.Length,Index+1);
	if( ShopCategories[Index].Name=="" )
	{
		ShopCategories[Index] = S;
		++ClientAccknowledged[1];
	}
}
simulated function ClientReceiveURL( string S, string ID )
{
	ServerWebSite = S;
	UserID = ID;
	bReceivedURL = true;
}
simulated function ClientSendAcknowledge()
{
	ServerAcnowledge(ClientAccknowledged[0],ClientAccknowledged[1]);
}
function ServerAcnowledge( int A, int B )
{
	ClientAccknowledged[0] = A;
	ClientAccknowledged[1] = B;
}
simulated function ClientReceiveChar( string CharName, int Num )
{
	CustomChars.Length = Num+1;
	CustomChars[Num] = CharName;
	ServerAckSkin(Num+1);
}
simulated function ClientReceiveTag( Texture T, string Tag, bool bInCaps )
{
	local int i;
	
	i = SmileyTags.Length;
	SmileyTags.Length = i+1;
	SmileyTags[i].SmileyTex = T;
	SmileyTags[i].SmileyTag = Tag;
	SmileyTags[i].bInCAPS = bInCaps;
}
simulated function ClientAllReceived()
{
	local PlayerController PC;
	local int i;

	bRepCompleted = true;
	PC = Level.GetLocalPlayerController();
	
	if( (PC!=None && PC==Owner) || Level.NetMode==NM_Client )
	{
		// Check if a DLC check is required.
		for( i=(ShopInventory.Length-1); i>=0; --i )
			if( ShopInventory[i].bDLCLocked!=0 )
			{
				Spawn(Class'MutSR_SRSteamStatsGet',Owner).Link = Self;
				break;
			}
	}

	if( SmileyTags.Length==0 )
		return;
	if( PC!=None && MutSR_SRHUDKillingFloor(PC.MyHUD)!=None )
		MutSR_SRHUDKillingFloor(PC.MyHUD).SmileyMsgs = SmileyTags;
}

function ServerAckSkin( int Index )
{
	ClientAckSkinNum = Index;
}

simulated final function string PickRandomCustomChar()
{
	local string S;
	local int i;
	
	if( CustomChars.Length==0 )
		return "";
	S = CustomChars[Rand(CustomChars.Length)];
	i = InStr(S,":");
	if( i>=0 )
		S = Mid(S,i+1);
	return S;
}
simulated final function bool IsCustomCharacter( string CN )
{
	local int i;

	for( i=0; i<CustomChars.Length; ++i )
		if( CustomChars[i]~=CN || Right(CustomChars[i],Len(CN)+1)~=(":"$CN) )
			return true;
	return false;
}
simulated final function SelectedCharacter( string CN )
{
	if( !IsCustomCharacter(CN) ) // Was not a custom character, update URL too.
	{
		if( bNoStandardChars && CustomChars.Length>0 ) // Denied.
			return;
		Level.GetLocalPlayerController().UpdateURL("Character", CN, True);
	}
	ServerSetCharacter(CN);
}

function ServerSetCharacter( string CN )
{
	if( xPlayer(Owner)!=None )
		StatObject.ChangeCharacter(CN);
}

final function bool CanBuyPickup( class<KFWeaponPickup> WC )
{
	local int i;
	local KFPlayerReplicationInfo K;
	
	for( i=(ShopInventory.Length-1); i>=0; --i )
		if( ShopInventory[i].PC==WC )
		{
			K = KFPlayerReplicationInfo(StatObject.PlayerOwner.PlayerReplicationInfo);
			for( i=(CachePerks.Length-1); i>=0; --i )
				if( !CachePerks[i].PerkClass.Static.AllowWeaponInTrader(WC,K,CachePerks[i].CurrentLevel) )
					return false;
			return true;
		}
	return false;
}

Auto state RepSetup
{
	final function InitDLCCheck()
	{
		local int i;
		
		for( i=(ShopInventory.Length-1); i>=0; --i )
		{
			if( class<KFWeapon>(ShopInventory[i].PC.Default.InventoryType)!=none
			 && (class<KFWeapon>(ShopInventory[i].PC.Default.InventoryType).Default.AppID>0
			 || class<KFWeapon>(ShopInventory[i].PC.Default.InventoryType).Default.UnlockedByAchievement!=-1) )
				ShopInventory[i].bDLCLocked = 1;
		}
	}
Begin:
	if( Level.NetMode==NM_Client )
		Stop;
	Sleep(1.f);
	NetUpdateFrequency = 0.5f;

	if( NetConnection(StatObject.PlayerOwner.Player)!=None ) // Network client.
	{
		ClientReceiveURL(ServerWebSite,StatObject.PlayerOwner.GetPlayerIDHash());

		// Now MAKE SURE client receives the full inventory list.
		while( ClientAccknowledged[0]<ShopInventory.Length || ClientAccknowledged[1]<ShopCategories.Length )
		{
			for( SendIndex=0; SendIndex<ShopInventory.Length; ++SendIndex )
			{
				ClientReceiveWeapon(SendIndex,ShopInventory[SendIndex].PC,ShopInventory[SendIndex].CatNum);
				Sleep(0.1f);
			}
			for( SendIndex=0; SendIndex<ShopCategories.Length; ++SendIndex )
			{
				ClientReceiveCategory(SendIndex,ShopCategories[SendIndex]);
				Sleep(0.1f);
			}
			ClientSendAcknowledge();
			Sleep(1.f);
		}

		// Send client all the custom characters.
		while( ClientAckSkinNum<CustomChars.Length )
		{
			ClientReceiveChar(CustomChars[ClientAckSkinNum],ClientAckSkinNum);
			Sleep(0.15f);
		}
		
		// Send all chat icons.
		for( SendIndex=0; SendIndex<SmileyTags.Length; ++SendIndex )
		{
			ClientReceiveTag(SmileyTags[SendIndex].SmileyTex,SmileyTags[SendIndex].SmileyTag,SmileyTags[SendIndex].bInCAPS);
			Sleep(0.1f);
		}
		SmileyTags.Length = 0;
	}
	else
	{
		bReceivedURL = true;
		InitDLCCheck();
	}

	ClientAllReceived();

	GoToState('UpdatePerkProgress');
}
state UpdatePerkProgress
{
	final function UpdateProgression()
	{
		local class<MutSR_SRVeterancyTypes> SV;
		local byte Lv;
		local float V;

		SV = Class<MutSR_SRVeterancyTypes>(OwnerPRI.ClientVeteranSkill);
		Lv = OwnerPRI.ClientVeteranSkillLevel+1;
		if( Lv<MaximumLevel && SV!=None )
		{
			V = SV.Static.GetTotalProgress(Self,Lv) * 10000.f;
			CurrentPerkProgress = V;
		}
		else CurrentPerkProgress = -1;
		ForceValue();
	}
	final function ForceValue()
	{
		if( CurrentPerkProgress!=OwnerPRI.ThreeSecondScore )
		{
			OwnerPRI.ThreeSecondScore = CurrentPerkProgress;
			OwnerPRI.NetUpdateTime = Level.TimeSeconds-1;
		}
	}
Begin:
	Sleep(FRand());
	OwnerPRI = KFPlayerReplicationInfo(StatObject.PlayerOwner.PlayerReplicationInfo);
	if( OwnerPRI==None )
		Stop;
	while( true )
	{
		Sleep(0.5);
		UpdateProgression();
		Sleep(1);
		ForceValue();
		Sleep(1);
		ForceValue();
		Sleep(1);
		ForceValue();
	}
}

simulated final function ResetItem( GUIBuyable Item )
{
	Item.ItemName = "";
	Item.ItemDescription = "";
	Item.ItemCategorie = "";
	Item.ItemImage = None;
	Item.ItemWeaponClass = None;
	Item.ItemAmmoClass = None;
	Item.ItemPickupClass = None;
	Item.ItemCost = 0;
	Item.ItemAmmoCost = 0;
	Item.ItemFillAmmoCost = 0;
	Item.ItemWeight = 0;
	Item.ItemPower = 0;
	Item.ItemRange = 0;
	Item.ItemSpeed = 0;
	Item.ItemAmmoCurrent = 0;
	Item.ItemAmmoMax = 0;
	Item.bSaleList = false;
	Item.bSellable = false;
	Item.bMelee = false;
	Item.bIsVest = false;
	Item.bIsFirstAidKit = false;
	Item.ItemPerkIndex = 0;
	Item.ItemSellValue = 0;
}

defaultproperties
{
	bAlwaysRelevant=false
	bOnlyRelevantToOwner=true
	bOnlyDirtyReplication=true
	RequirementScaling=1
	MaximumLevel=7
	UserID="Local"
	ShopPerkIcons(0)=Texture'KillingFloorHUD.Perks.Perk_Medic'
	ShopPerkIcons(1)=Texture'KillingFloorHUD.Perks.Perk_Support'
	ShopPerkIcons(2)=Texture'KillingFloorHUD.Perks.Perk_SharpShooter'
	ShopPerkIcons(3)=Texture'KillingFloorHUD.Perks.Perk_Commando'
	ShopPerkIcons(4)=Texture'KillingFloorHUD.Perks.Perk_Berserker'
	ShopPerkIcons(5)=Texture'KillingFloorHUD.Perks.Perk_Firebug'
	ShopPerkIcons(6)=Texture'KillingFloor2HUD.Perk_Icons.Perk_Demolition'
	ShopPerkIcons(7)=Texture'KillingFloor2HUD.Perk_Icons.No_Perk_Icon'
}