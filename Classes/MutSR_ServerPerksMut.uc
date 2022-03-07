// Written by .:..: (2009)
Class MutSR_ServerPerksMut extends Mutator
	Config(MutSR_ServerPerks);


#exec OBJ LOAD FILE="Textures\CountryFlagsTex.utx" PACKAGE=MutSR

#exec OBJ LOAD FILE="KFSXHud.utx" PACKAGE=MutSR
#exec OBJ LOAD FILE="SXShopArrow.usx" PACKAGE=MutSR
#exec OBJ LOAD FILE="SXKEND.utx" PACKAGE=MutSR

struct ChatIconType
{
	var() config string IconTexture,IconTag;
	var() config bool bCaseInsensitive;
};
var() globalconfig array<string> Perks,TraderInventory,WeaponCategories,CustomCharacters;
var() globalconfig int MinPerksLevel,MaxPerksLevel,RemotePort,MidGameSaveWaves,FTPKeepAliveSec;
var() globalconfig float RequirementScaling;
var() globalconfig string RemoteDatabaseURL,RemotePassword,RemoteFTPUser,RemoteFTPDir,ServerNewsURL,FTPUploadAllIgnoreDate;
var() globalconfig array<ChatIconType> SmileyTags;

var array<MutSR_ClientPerkRepLink.FShopCategoryIndex> LoadedCategories;
var array<byte> LoadInvCategory;
var array< class<MutSR_SRVeterancyTypes> > LoadPerks;
var array< class<Pickup> > LoadInventory;
var array<PlayerController> PendingPlayers;
var array<MutSR_StatsObject> ActiveStats;
var localized string MutSR_ServerPerksGroup;
var transient InternetLink Link;
var KFGameType KFGT;
var int LastSavedWave,WaveCounter;
var MutSR_SRGameRules RulesMod;
var transient array<name> AddedServerPackages;
var transient float NextCheckTimer;
var array<MutSR_SRHUDKillingFloor.SmileyMessageType> SmileyMsgs;
var class<Object> SRScoreboardType,SRHudType,SRMenuType;
var class<PlayerController> SRControllerType;


struct SPickupReplacement {
    var class<Pickup> oldClass;
    var class<Pickup> newClass;
};
var array<SPickupReplacement> pickupReplaceArray;
var globalconfig bool bReplacePickups;//, bReplacePickupsStory;

var() globalconfig bool bUploadAllStats,bForceGivePerk,bNoSavingProgress,bUseRemoteDatabase,bUsePlayerNameAsID,bMessageAnyPlayerLevelUp,bNoPerkChanges
						,bUseLowestRequirements,bBWZEDTime,bUseEnhancedScoreboard,bOverrideUnusedCustomStats,bAllowAlwaysPerkChanges,bEnableWebAdmin
						,bForceCustomChars,bEnableChatIcons,bEnhancedShoulderView,bFixGrenadeExploit,bAdminEditStats,bUseFTPLink,bDebugDatabase;
var bool bEnabledEmoIcons;
var() config array<string> Mutator;
var bool bInitialized;

function PreBeginPlay()
{
	local int i;
	Super.PreBeginPlay();
	
	if (bInitialized) return;
        bInitialized = True;
		
	for( i=(Mutator.Length-1); i>=0; --i )
	{
		if ((Mutator[i] == "") || (Mutator[i] == "MutSR.MutSR_ServerPerksMut"))
			continue;
		else
			Level.Game.AddMutator(Mutator[i],true);
	}
    return;
}

function PostBeginPlay()
{
	local int i,j;
	local class<MutSR_SRVeterancyTypes> V;
	local class<Pickup> P;
	local string S;
	local byte Cat;
	local class<PlayerRecordClass> PR;
	local Texture T;
	local KFLevelRules R;

	class'KFMod.FlareRevolver'.default.AppID = 0;
	class'KFMod.DualFlareRevolver'.default.AppID = 0;
	class'KFMod.Scythe'.default.AppID = 0;
	class'KFMod.ThompsonSMG'.default.AppID = 0;
	class'KFMod.Crossbuzzsaw'.default.AppID = 0;
	class'KFMod.GoldenKatana'.default.AppID = 0;
	class'KFMod.GoldenAK47AssaultRifle'.default.AppID = 0;
	class'KFMod.GoldenM79GrenadeLauncher'.default.AppID = 0;
	class'KFMod.GoldenBenelliShotgun'.default.AppID = 0;
	class'KFMod.ZEDGun'.default.AppID=0;
	class'KFMod.ZEDGun'.default.UnlockedByAchievement=-1;
	class'KFMod.DwarfAxe'.default.AppID=0;
	class'KFMod.DwarfAxe'.default.UnlockedByAchievement=-1;
	class'KFMod.SPAutoShotgun'.default.AppID=0;
	class'KFMod.SPGrenadeLauncher'.default.AppID=0;
	class'KFMod.SPSniperRifle'.default.AppID=0;
	class'KFMod.SPThompsonSMG'.default.AppID=0;
	class'KFMod.ThompsonDrumSMG'.default.AppID=0;
	class'KFMod.GoldenFlamethrower'.default.AppID=0;
	class'KFMod.GoldenDualDeagle'.default.AppID=0;
	class'KFMod.GoldenDeagle'.default.AppID=0;
	class'KFMod.GoldenChainsaw'.default.AppID=0;
	class'KFMod.GoldenAA12AutoShotgun'.default.AppID=0;

	if( RulesMod==None )
		RulesMod = Spawn(Class'MutSR_SRGameRules');

	KFGT = KFGameType(Level.Game);
	if( Level.Game.HUDType~=Class'KFGameType'.Default.HUDType || Level.Game.HUDType~=Class'KFStoryGameInfo'.Default.HUDType )
	{
		bEnabledEmoIcons = bEnableChatIcons;
		Level.Game.HUDType = string(SRHudType);
	}

	if( bUseEnhancedScoreboard && (Level.Game.ScoreBoardType~=Class'KFGameType'.Default.ScoreBoardType || Level.Game.ScoreBoardType~=Class'KFStoryGameInfo'.Default.ScoreBoardType) )
		Level.Game.ScoreBoardType = string(SRScoreboardType);

	// Use own playercontroller class for security reasons.
	if( Level.Game.PlayerControllerClass==Class'KFPlayerController' || Level.Game.PlayerControllerClass==Class'KFPlayerController_Story' )
	{
		Level.Game.PlayerControllerClass = SRControllerType;
		Level.Game.PlayerControllerClassName = string(SRControllerType);
	}
	DeathMatch(Level.Game).LoginMenuClass = string(SRMenuType);

	// Load perks.
	for( i=0; i<Perks.Length; i++ )
	{
		V = class<MutSR_SRVeterancyTypes>(DynamicLoadObject(Perks[i],Class'Class'));
		if( V!=None )
		{
			LoadPerks[LoadPerks.Length] = V;
			ImplementPackage(V);
		}
	}
	
	// Setup categories
	LoadedCategories.Length = WeaponCategories.Length;
	for( i=0; i<WeaponCategories.Length; ++i )
	{
		S = WeaponCategories[i];
		j = InStr(S,":");
		if( j==-1 )
		{
			LoadedCategories[i].Name = S;
			LoadedCategories[i].PerkIndex = 255;
		}
		else
		{
			LoadedCategories[i].Name = Mid(S,j+1);
			LoadedCategories[i].PerkIndex = int(Left(S,j));
		}
	}
	if( LoadedCategories.Length==0 )
	{
		LoadedCategories.Length = 1;
		LoadedCategories[0].Name = "All";
		LoadedCategories[0].PerkIndex = 255;
	}

	// Init rules
	foreach AllActors(class'KFLevelRules',R)
		break;
	if( R==None && KFGT!=None )
	{
		R = KFGT.KFLRules;
		if( R==None )
		{
			R = Spawn(class'KFLevelRules');
			KFGT.KFLRules = R;
		}
	}
	if( R!=None )
	{
		// Empty all stock weapons first.
		R.MediItemForSale.Length = 0;
		R.SuppItemForSale.Length = 0;
		R.ShrpItemForSale.Length = 0;
		R.CommItemForSale.Length = 0;
		R.BersItemForSale.Length = 0;
		R.FireItemForSale.Length = 0;
		R.DemoItemForSale.Length = 0;
		R.NeutItemForSale.Length = 0;
	}

	// Load up trader inventory.
	for( i=0; i<TraderInventory.Length; i++ )
	{
		S = TraderInventory[i];
		j = InStr(S,":");
		if( j>0 )
		{
			Cat = Min(int(Left(S,j)),LoadedCategories.Length-1);
			S = Mid(S,j+1);
		}
		else Cat = 0;
		P = class<Pickup>(DynamicLoadObject(S,Class'Class'));
		if( P!=None )
		{
			// Inform bots.
			if( R!=None )
				R.MediItemForSale[R.MediItemForSale.Length] = P;

			LoadInventory[LoadInventory.Length] = P;
			LoadInvCategory[LoadInvCategory.Length] = Cat;
			if( P.Outer.Name!='KFMod' )
				ImplementPackage(P);
		}
	}

	// Load custom chars.
	for( i=0; i<CustomCharacters.Length; ++i )
	{
		// Separate group from actual skin.
		S = CustomCharacters[i];
		j = InStr(S,":");
		if( j>=0 )
			S = Mid(S,j+1);
		PR = class<PlayerRecordClass>(DynamicLoadObject(S$"Mod."$S,class'Class',true));
		if( PR!=None )
		{
			if( PR.Default.MeshName!="" ) // Add mesh package.
				ImplementPackage(DynamicLoadObject(PR.Default.MeshName,class'Mesh',true));
			if( PR.Default.BodySkinName!="" ) // Add skin package.
				ImplementPackage(DynamicLoadObject(PR.Default.BodySkinName,class'Material',true));
			ImplementPackage(PR);
		}
	}
	
	// Load chat icons
	if( bEnabledEmoIcons )
	{
		j = 0;
		for( i=0; i<SmileyTags.Length; ++i )
		{
			if( SmileyTags[i].IconTexture=="" || SmileyTags[i].IconTag=="" )
				continue;
			T = Texture(DynamicLoadObject(SmileyTags[i].IconTexture,class'Texture',true));
			if( T==None )
				continue;
			ImplementPackage(T);
			SmileyMsgs.Length = j+1;
			SmileyMsgs[j].SmileyTex = T;
			if( SmileyTags[i].bCaseInsensitive )
				SmileyMsgs[j].SmileyTag = Caps(SmileyTags[i].IconTag);
			else SmileyMsgs[j].SmileyTag = SmileyTags[i].IconTag;
			SmileyMsgs[j].bInCAPS = SmileyTags[i].bCaseInsensitive;
			++j;
		}
		bEnabledEmoIcons = (j!=0);
	}

	Log("Adding"@AddedServerPackages.Length@"additional serverpackages",Class.Outer.Name);
	for( i=0; i<AddedServerPackages.Length; i++ )
		AddToPackageMap(string(AddedServerPackages[i]));
	AddedServerPackages.Length = 0;
	
	if( bUseEnhancedScoreboard || (Level.Game.HUDType~=string(SRHudType)) )
		AddToPackageMap("MutSR");

	if( bFixGrenadeExploit )
		Class'Frag'.Default.FireModeClass[0] = Class'MutSR_FragFireFix';

	if( bUseRemoteDatabase )
	{
		Log("Using remote database:"@RemoteDatabaseURL$":"$RemotePort,Class.Outer.Name);
		RespawnNetworkLink();
	}
}

function Tick( float Delta )
{
	Disable('Tick');
	if( bEnableWebAdmin && Level.NetMode!=NM_StandAlone )
		InitWebServer();
}
function InitWebServer()
{
	local WebServer W;
	local int i;
	local UTServerAdmin U;
	
	// Must increase the limit size.
	class'WebConnection'.default.MaxValueLength = Max(class'WebConnection'.default.MaxValueLength,9999);
	class'WebConnection'.default.MaxLineLength = Max(class'WebConnection'.default.MaxLineLength,10100);

	foreach DynamicActors(class'WebServer',W)
	{
		for( i=0; i<10; ++i )
		{
			U = UTServerAdmin(W.ApplicationObjects[i]);
			if( U!=None )
			{
				for( i=0; i<U.QueryHandlers.Length; ++i )
					if( U.QueryHandlers[i].Class==Class'MutSR_ServerPerkWebAdmin' )
						return; // Already implemented.
				U.QueryHandlers.Length = i+1;
				U.QueryHandlers[i] = New(U)Class'MutSR_ServerPerkWebAdmin';
				U.QueryHandlers[i].Init();
				return;
			}
		}
		Log("MutSR_ServerPerks WebAdmin interface failed to init: Missing UTServerAdmin application.",Class.Outer.Name);
		return;
	}
	Log("MutSR_ServerPerks WebAdmin interface failed to init: Missing WebServer object.",Class.Outer.Name);
}

function RespawnNetworkLink()
{
	if( Link!=None )
		Link.Destroy();
	if( !bUseFTPLink )
	{
		Link = Spawn(Class'MutSR_DatabaseUdpLink');
		MutSR_DatabaseUdpLink(Link).Mut = Self;
	}
	else
	{
		Link = Spawn(Class'MutSR_FTPTcpLink');
		MutSR_FTPTcpLink(Link).Mut = Self;
	}
	Link.BeginEvent();
}

function Mutate(string MutateString, PlayerController Sender)
{
	if( MutateString~="SPHelp" )
		Sender.ClientMessage("MutSR_ServerPerksMut mutate CMDs: EditStats, SetPerk, Debug, GetID");
	if( Sender.PlayerReplicationInfo.bAdmin || Sender.PlayerReplicationInfo.bSilentAdmin || Viewport(Sender.Player)!=None )
	{
		if( bAdminEditStats && MutateString~="EditStats" )
			Spawn(Class'MutSR_AdminMenuHandle',Sender).MutatorOwner = Self;
		else if( MutateString~="GetID" )
			ListID(Sender);
		else if( Left(MutateString,7)~="SetPerk" )
			AdminChangePerk(Sender,Mid(MutateString,8));
	}
	if( NextCheckTimer<Level.TimeSeconds && MutateString~="Debug" ) // Allow developer to lookup bugs.
	{
		NextCheckTimer = Level.TimeSeconds+0.25;
		Sender.ClientMessage("Debug info: "$Sender.SteamStatsAndAchievements);
		if( MutSR_ServerStStats(Sender.SteamStatsAndAchievements)!=None )
		{
			Sender.ClientMessage("Ready:"@MutSR_ServerStStats(Sender.SteamStatsAndAchievements).bStatsReadyNow@MutSR_ServerStStats(Sender.SteamStatsAndAchievements).bStatsChecking);
			Sender.ClientMessage("MyStatsObject:"@MutSR_ServerStStats(Sender.SteamStatsAndAchievements).MyStatsObject);
			Sender.ClientMessage("Timer:"@Sender.SteamStatsAndAchievements.TimerCounter@Sender.SteamStatsAndAchievements.TimerRate);
		}
		Sender.ClientMessage("Perk info:");
		DebugMessageProgress(Sender);
	}
	if ( NextMutator != None )
		NextMutator.Mutate(MutateString, Sender);
}
final function AdminChangePerk( PlayerController Sender, string Cmd )
{
	local int i,ID;
	local Controller C;
	local class<MutSR_SRVeterancyTypes> V;
	local bool bAll;
	
	i = InStr(Cmd," ");
	if( i==-1 )
	{
		Sender.ClientMessage("Usage: SetPerk <ID/All> <PerkName>");
		return;
	}
	if( Left(Cmd,i)~="All" )
		bAll = true;
	else ID = int(Left(Cmd,i));
	
	Cmd = Mid(Cmd,i+1);
	for( i=0; i<LoadPerks.Length; ++i )
		if( string(LoadPerks[i].Name)~=Cmd || LoadPerks[i].Default.VeterancyName~=Cmd )
		{
			V = LoadPerks[i];
			break;
		}
	if( V==None )
	{
		Sender.ClientMessage("Unknown perk name: "$Cmd);
		return;
	}
	
	for( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		if( C.bIsPlayer && C.PlayerReplicationInfo!=None && (bAll || C.PlayerReplicationInfo.PlayerID==ID) && xPlayer(C)!=None && MutSR_ServerStStats(xPlayer(C).SteamStatsAndAchievements)!=None )
		{
			MutSR_ServerStStats(xPlayer(C).SteamStatsAndAchievements).ForcePerkChange(V);
			xPlayer(C).ClientMessage("An admin has forced to change your perk to "$V.Default.VeterancyName);
			if( !bAll )
			{
				Sender.ClientMessage("Changed "$C.PlayerReplicationInfo.PlayerName$" perk to: "$V);
				break;
			}
		}
	}
	if( bAll )
		Sender.ClientMessage("Changed everyones perk to: "$V);
}
final function ListID( PlayerController PC )
{
	local Controller C;
	
	PC.ClientMessage("Player IDs:");
	for( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		if( C.bIsPlayer && C.PlayerReplicationInfo!=None && xPlayer(C)!=None && MutSR_ServerStStats(xPlayer(C).SteamStatsAndAchievements)!=None )
			PC.ClientMessage("ID="$C.PlayerReplicationInfo.PlayerID$", Name="$C.PlayerReplicationInfo.PlayerName);
	}
}
final function DebugMessageProgress( PlayerController PC )
{
	local KFPlayerReplicationInfo PRI;
	local class<MutSR_SRVeterancyTypes> VC;
	local int i,Req,Cur,NumR;
	local byte Lvl;
	local MutSR_ClientPerkRepLink Rep;
	
	PRI = KFPlayerReplicationInfo(PC.PlayerReplicationInfo);
	if( PRI==None || Class<MutSR_SRVeterancyTypes>(PRI.ClientVeteranSkill)==None )
		return;
	VC = Class<MutSR_SRVeterancyTypes>(PRI.ClientVeteranSkill);
	Lvl = PRI.ClientVeteranSkillLevel+1;
	
	Rep = Class'MutSR_SRGameRules'.Static.FindStatsFor(PC);
	if( Rep==None )
		return;

	PC.ClientMessage("Perk: "$VC.Default.VeterancyName$" NextLevel: "$Lvl);
	NumR = VC.Static.GetRequirementCount(Rep,Lvl);
	for( i=0; i<NumR; ++i )
	{
		Cur = VC.Static.GetPerkProgressInt(Rep,Req,Lvl,i);
		PC.ClientMessage("Requirement '"$i$"' GetPerkProgressInt: Current:"$Cur$" Final:"$Req);
		VC.Static.GetPerkProgress(Rep,Lvl,i,Cur,Req);
		PC.ClientMessage("GetPerkProgress: Current:"$Cur$" Final:"$Req);
	}
}
final function ImplementPackage( Object O )
{
	local int i;
	
	if( O==None )
		return;
	while( O.Outer!=None )
		O = O.Outer;
	if( O.Name=='KFMod' )
		return;
	for( i=(AddedServerPackages.Length-1); i>=0; --i )
		if( AddedServerPackages[i]==O.Name )
			return;
	AddedServerPackages[AddedServerPackages.Length] = O.Name;
}

function int FindPickupReplacementIndex( Pickup item )
{
    local int i;

    // pickupReplaceArray contains only KFMod items, so no need to cycle the entire array too look for items
    // that cannot be there, such as ScrN or custom weapons
    if ( item.class.outer.name != 'KFMod' )
        return -1;

    for ( i=0; i<pickupReplaceArray.length; ++i ) {
        if ( pickupReplaceArray[i].oldClass == item.class )
            return i;
    }
    return -1;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local int i;
    // first check classes that need to be replaced
    if ( Other.class == class'KFRandomItemSpawn' ) {
        if ( !bReplacePickups )
            return true;
        ReplaceWith(Other, string(class'MutSR_RandomItemSpawn'));
        return false;
    }
    
    else if ( bReplacePickups && Pickup(Other) != none && KFGT.IsInState('MatchInProgress') ) 
	{
        // don't replace pickups placed on the map by the author - replace only dropped ones
        // or spawned by KFRandomItemSpawn
        i = FindPickupReplacementIndex(Pickup(Other));
        if ( i != -1 ) 
		{
            ReplaceWith(Other, string(pickupReplaceArray[i].NewClass));
            return false;
        }
        return true; // no need to replace
    }
	
	else if( PlayerController(Other)!=None )
	{
		PendingPlayers[PendingPlayers.Length] = PlayerController(Other);
		SetTimer(0.1,false);
	}
	else if( Bot(Other)!=None && Bot(Other).PawnClass==Class'KFHumanPawn' )
	{
		Bot(Other).PawnClass = Class'MutSR_SRHumanPawn';
		Bot(Other).PreviousPawnClass = Class'MutSR_SRHumanPawn';
	}
	else if( MutSR_ServerStStats(Other)!=None )
		SetMutSR_ServerPerks(MutSR_ServerStStats(Other));
	else if( MutSR_ClientPerkRepLink(Other)!=None )
		SetupRepLink(MutSR_ClientPerkRepLink(Other));


    /* else if ( KFMonster(Other) != none ) {
        SetupMonster(KFMonster(Other));
    }
    else if ( SRStatsBase(Other) != none ) {
        SetupRepLink(SRStatsBase(Other).Rep);
    } */
    /* else if ( bStoryMode ) 
	{
        if ( KFLevelRules_Story(Other) != none  ) 
		{
            if ( bReplacePickupsStory )
                SetupStoryRules(KFLevelRules_Story(Other));
        }
        else if ( KF_StoryNPC(Other) != none ) 
		{
            if ( Other.class == class'KF_BreakerBoxNPC' ) // don't alter subclasses
                KF_StoryNPC(Other).BaseAIThreatRating = 20;
            else if ( Other.class == class'KF_RingMasterNPC' )
                KF_StoryNPC(Other).BaseAIThreatRating = 40;
        }
    } */

    return true;
}

/* function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if( PlayerController(Other)!=None )
	{
		PendingPlayers[PendingPlayers.Length] = PlayerController(Other);
		SetTimer(0.1,false);
	}
	else if( Bot(Other)!=None && Bot(Other).PawnClass==Class'KFHumanPawn' )
	{
		Bot(Other).PawnClass = Class'MutSR_SRHumanPawn';
		Bot(Other).PreviousPawnClass = Class'MutSR_SRHumanPawn';
	}
	else if( MutSR_ServerStStats(Other)!=None )
		SetMutSR_ServerPerks(MutSR_ServerStStats(Other));
	else if( MutSR_ClientPerkRepLink(Other)!=None )
		SetupRepLink(MutSR_ClientPerkRepLink(Other));

	return true;
} */


function bool ShouldReplacePickups()
{
    return bReplacePickups;
}

function SetMutSR_ServerPerks( MutSR_ServerStStats Stat )
{
	local int i;

	Stat.MutatorOwner = Self;
	Stat.Rep.ServerWebSite = ServerNewsURL;
	Stat.Rep.MinimumLevel = MinPerksLevel+1;
	Stat.Rep.MaximumLevel = MaxPerksLevel+1;
	Stat.Rep.RequirementScaling = RequirementScaling;
	Stat.Rep.CachePerks.Length = LoadPerks.Length;
	for( i=0; i<LoadPerks.Length; i++ )
		Stat.Rep.CachePerks[i].PerkClass = LoadPerks[i];
}
function SetupRepLink( MutSR_ClientPerkRepLink R )
{
	local int i;

	R.bMinimalRequirements = bUseLowestRequirements;
	R.bBWZEDTime = bBWZEDTime;
	R.bNoStandardChars = bForceCustomChars;

	R.ShopInventory.Length = LoadInventory.Length;
	for( i=0; i<LoadInventory.Length; ++i )
	{
		R.ShopInventory[i].PC = LoadInventory[i];
		R.ShopInventory[i].CatNum = LoadInvCategory[i];
	}
	R.ShopCategories = LoadedCategories;
	R.CustomChars = CustomCharacters;
	if( bEnabledEmoIcons )
		R.SmileyTags = SmileyMsgs;
}

function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
	local int i,l;

	Super.GetServerDetails( ServerState );
	l = ServerState.ServerInfo.Length;
	ServerState.ServerInfo.Length = l+1;
	ServerState.ServerInfo[l].Key = "Current Game Status";
	ServerState.ServerInfo[l].Value = GetServerStatus();
	l++;
	ServerState.ServerInfo.Length = l+1;
	ServerState.ServerInfo[l].Key = "Whitelisted";
	ServerState.ServerInfo[l].Value = "FALSE";
	l++;
	For( i=0; i<Mutator.Length; i++ )
	{
		ServerState.ServerInfo.Length = l+1;
		ServerState.ServerInfo[l].Key = "Mutator"$(i+1);
		ServerState.ServerInfo[l].Value = GetItem2Name();
		l++;
	}
	// return GetItem2Name();
}

function string GetServerStatus()
{
	local KFGameReplicationInfo KFGRI;
	
	KFGRI = KFGameReplicationInfo(Level.Game.GameReplicationInfo);
	
	if( KFGRI.bMatchHasBegun )
	{
		if( KFGRI.bWaveInProgress )
		{
			return "WAVE ["$KFGameReplicationInfo(Level.Game.GameReplicationInfo).WaveNumber+1$"/"$KFGameReplicationInfo(Level.Game.GameReplicationInfo).FinalWave$"]";
		}
		else
		{
			return "TRADER TIME ["$KFGameReplicationInfo(Level.Game.GameReplicationInfo).WaveNumber+1$"/"$KFGameReplicationInfo(Level.Game.GameReplicationInfo).FinalWave$"]";
		}
	}
	else
	{
		return "[-- AWAITING... --]";
	}
}

simulated static function String GetItem2Name()
{
    return "FUCK OFF";
}

function Timer()
{
	local int i;

	KFGT.ZEDTimeDuration = 6.0;
	KFGT.ZedTimeSlomoScale = 0.3;
	
	for( i=(PendingPlayers.Length-1); i>=0; --i )
	{
		if( MutSR_KFPCServ(PendingPlayers[i])!=None )
			MutSR_KFPCServ(PendingPlayers[i]).bUseAdvBehindview = bEnhancedShoulderView;
		if( PendingPlayers[i]!=None && PendingPlayers[i].Player!=None && MutSR_ServerStStats(PendingPlayers[i].SteamStatsAndAchievements)==None )
		{
			if( PendingPlayers[i].SteamStatsAndAchievements!=None )
				PendingPlayers[i].SteamStatsAndAchievements.Destroy();
			PendingPlayers[i].SteamStatsAndAchievements = Spawn(Class'MutSR_ServerStStats',PendingPlayers[i]);
			PendingPlayers[i].PlayerReplicationInfo.SteamStatsAndAchievements = PendingPlayers[i].SteamStatsAndAchievements;
		}
	}
	PendingPlayers.Length = 0;
}

final function string GetPlayerID( PlayerController PC )
{
	if( bUsePlayerNameAsID )
		return PC.PlayerReplicationInfo.PlayerName;
	return PC.GetPlayerIDHash();
}
function MutSR_StatsObject GetStatsForPlayer( PlayerController PC )
{
	local MutSR_StatsObject S;
	local string SId;
	local int i;

	if( Level.Game.bGameEnded )
		return None;
	SId = GetPlayerID(PC);
	for( i=0; i<ActiveStats.Length; ++i )
		if( string(ActiveStats[i].Name)~=SId )
		{
			S = ActiveStats[i];
			break;
		}
	if( S==None )
	{
		S = new(None,SId) Class'MutSR_StatsObject';
		S.bStatsChanged = false;
		ActiveStats[ActiveStats.Length] = S;
	}
	S.PlayerName = PC.PlayerReplicationInfo.PlayerName;
	S.PlayerIP = PC.GetPlayerNetworkAddress();
	return S;
}

function SaveStats()
{
	local int i;
	local MutSR_ClientPerkRepLink CP;

	if( bNoSavingProgress )
		return;

	Log("*** Saving "$ActiveStats.Length$" stat objects ***",Class.Outer.Name);
	foreach DynamicActors(Class'MutSR_ClientPerkRepLink',CP)
		if( CP.StatObject!=None && MutSR_ServerStStats(CP.StatObject).MyStatsObject!=None )
			MutSR_ServerStStats(CP.StatObject).MyStatsObject.SetCustomValues(CP.CustomLink);

	if( bUseRemoteDatabase )
	{
		SaveAllStats();
		return;
	}
	for( i=0; i<ActiveStats.Length; ++i )
		if( ActiveStats[i].bStatsChanged )
		{
			ActiveStats[i].bStatsChanged = false;
			ActiveStats[i].SaveConfig();
		}
}
function CheckWinOrLose()
{
	local bool bWin;
	local Controller P;
	local PlayerController Player;

	bWin = (KFGameReplicationInfo(Level.GRI)!=None && KFGameReplicationInfo(Level.GRI).EndGameType==2);
	for ( P = Level.ControllerList; P != none; P = P.nextController )
	{
		Player = PlayerController(P);

		if ( Player != none )
		{
			if ( MutSR_ServerStStats(Player.SteamStatsAndAchievements)!=None )
				MutSR_ServerStStats(Player.SteamStatsAndAchievements).WonLostGame(bWin);
		}
	}
}
function InitNextWave()
{
	if( ++WaveCounter>=MidGameSaveWaves )
	{
		WaveCounter = 0;
		SaveStats();
	}
}

Auto state EndGameTracker
{
Begin:
	if( bUploadAllStats && Level.NetMode==NM_StandAlone )
	{
		Sleep(1.f);
		MutSR_FTPTcpLink(Link).FullUpload();
		while( true )
		{
			if( KFGT!=None )
				KFGT.WaveCountDown = 60;
			Sleep(1.f);
		}
	}
	while( !Level.Game.bGameEnded )
	{
		Sleep(1.f);
		if( MidGameSaveWaves>0 && KFGT!=None && KFGT.WaveNum!=LastSavedWave )
		{
			LastSavedWave = KFGT.WaveNum;
			InitNextWave();
		}
		if( Level.bLevelChange )
		{
			SaveStats();
			Stop;
		}
	}
	CheckWinOrLose();
	SaveStats();
}

static final function string GetSafeName( string S )
{
	S = Repl(S,"=","-");
	S = Repl(S,Chr(10),""); // LF
	S = Repl(S,Chr(13),""); // CR
	S = Repl(S,"\"","'"); // " -> '
	return S;
}

delegate SaveAllStats();
delegate RequestStats( MutSR_ServerStStats Other );

static function FillPlayInfo(PlayInfo PlayInfo)
{
	Super.FillPlayInfo(PlayInfo);

	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"MinPerksLevel","Min Perk Level",1,0, "Text", "4;6:6");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"MaxPerksLevel","Max Perk Level",1,0, "Text", "4;6:6");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"RequirementScaling","Req Scaling",1,0, "Text", "6;0.01:4.00");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bForceGivePerk","Force perks",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bNoSavingProgress","No saving",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bAllowAlwaysPerkChanges","Unlimited perk changes",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bNoPerkChanges","No perk changes",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bUseRemoteDatabase","Use remote database",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bUseFTPLink","Use FTP remote database",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"RemoteDatabaseURL","Remote database URL",1,1,"Text","64");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"RemotePort","Remote database port",1,0, "Text", "5;0:65535");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"RemotePassword","Remote database password",1,0, "Text", "64");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"RemoteFTPUser","Remote database user",1,0, "Text", "64");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"RemoteFTPDir","Remote database dir",1,0, "Text", "64");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"FTPKeepAliveSec","FTP Keep alive sec",1,0, "Text", "6;0:600");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"MidGameSaveWaves","MidGame Save Waves",1,0, "Text", "5;0:10");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"ServerNewsURL","Newspage URL",1,0, "Text", "64");

	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bUsePlayerNameAsID","Use PlayerName as ID",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bMessageAnyPlayerLevelUp","Notify any levelup",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bUseLowestRequirements","Use lowest req",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bBWZEDTime","BW ZED-time",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bUseEnhancedScoreboard","Enhanced scoreboard",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bForceCustomChars","Force Custom Chars",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bEnableChatIcons","Enable chat icons",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bEnhancedShoulderView","Shoulder view",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bFixGrenadeExploit","No Grenade Exploit",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bAdminEditStats","Admin edit stats",1,0, "Check");
	PlayInfo.AddSetting(default.MutSR_ServerPerksGroup,"bEnableWebAdmin","SP WebAdmin",1,0, "Check");
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "MinPerksLevel":		return "Minimum perk level players can have.";
		case "MaxPerksLevel":		return "Maximum perk level players can have.";
		case "RequirementScaling":	return "Perk requirements scaling.";
		case "bForceGivePerk":		return "Force all players to get at least a random perk if they have none selected.";
		case "bNoSavingProgress":	return "Server shouldn't save perk progression.";
		case "bUseRemoteDatabase":	return "Instead of storing perk data locally on server, use remote data storeage server.";
		case "bUseFTPLink":			return "Use FTP transmission for remote database.";
		case "RemoteDatabaseURL":	return "URL of the remote database.";
		case "RemotePort":			return "Port of the remote database.";
		case "RemotePassword":		return "Password for server to access the remote database.";
		case "RemoteFTPUser":		return "User name for server to access the remote database (only for FTP mode).";
		case "MidGameSaveWaves":	return "Between how many waves should it mid-game save stats.";
		case "bUsePlayerNameAsID":	return "Use PlayerName's as ID instead of ID Hash.";
		case "bMessageAnyPlayerLevelUp": return "Broadcast a global message anytime someone gains a perk upgrade.";
		case "bUseLowestRequirements":	return "Use lowest form of requirements for perks.";
		case "bBWZEDTime":			return "Make screen go black and white during ZED-time.";
		case "bUseEnhancedScoreboard":	return "Should use serverperk's own scoreboard.";
		case "bAllowAlwaysPerkChanges":	return "Allow unlimited perk changes.";
		case "bForceCustomChars":	return "Force players to use specified custom characters.";
		case "bEnableChatIcons":	return "Should enable chat icons to replace specific tags in chat.";
		case "bEnhancedShoulderView": return "Should enable a more enhanced on shoulder behindview.";
		case "bFixGrenadeExploit":	return "Should fix unlimited grenades glitch/exploit.";
		case "bAdminEditStats":		return "Allow admins edit stats through an admin menu.";
		case "ServerNewsURL":		return "Server newspage menu URL for page contents.";
		case "RemoteFTPDir":		return "Remote FTP database data storage directory.";
		case "FTPKeepAliveSec":		return "Keep FTP database connection alive with this many sec interval.";
		case "bEnableWebAdmin":		return "Enable additional webserver interface.";
		case "bNoPerkChanges":	return "Never allow players change perk during match.";
	}
	return Super.GetDescriptionText(PropName);
}

defaultproperties
{
	FriendlyName="MutSR_SP"
	Description="MutSR_SP."
	GroupName="KF-MutSR_SP"
	MutSR_ServerPerksGroup="MutSR_ServerPerks"

	Perks(1)="MutSR.MutSR_SRVetSupportSpec"
	Perks(4)="MutSR.MutSR_SRVetBerserker"
	Perks(3)="MutSR.MutSR_SRVetCommando"
	Perks(0)="MutSR.MutSR_SRVetFieldMedic"
	Perks(5)="MutSR.MutSR_SRVetFirebug"
	Perks(2)="MutSR.MutSR_SRVetSharpshooter"
	Perks(6)="MutSR.MutSR_SRVetDemolitions"

	// pickupReplaceArray(0)=(oldClass=Class'KFMod.MP7MPickup',NewClass=class'ScrnMP7MPickup')
    // pickupReplaceArray(1)=(oldClass=Class'KFMod.MP5MPickup',NewClass=class'ScrnMP5MPickup')
    // pickupReplaceArray(2)=(oldClass=Class'KFMod.KrissMPickup',NewClass=class'ScrnKrissMPickup')
    // pickupReplaceArray(3)=(oldClass=Class'KFMod.M7A3MPickup',NewClass=class'ScrnM7A3MPickup')
    // pickupReplaceArray(4)=(oldClass=Class'KFMod.ShotgunPickup',NewClass=class'ScrnShotgunPickup')
    // pickupReplaceArray(5)=(oldClass=Class'KFMod.BoomStickPickup',NewClass=class'ScrnBoomStickPickup')
    // pickupReplaceArray(6)=(oldClass=Class'KFMod.NailGunPickup',NewClass=class'ScrnNailGunPickup')
    // pickupReplaceArray(7)=(oldClass=Class'KFMod.KSGPickup',NewClass=class'ScrnKSGPickup')
	
    bReplacePickups=true
    pickupReplaceArray(0)=(oldClass=Class'KFMod.BenelliPickup',NewClass=class'BenelliEPickup')
    pickupReplaceArray(1)=(oldClass=Class'KFMod.GoldenBenelliPickup',NewClass=class'BenelliEPickup')
    // pickupReplaceArray(9)=(oldClass=Class'KFMod.AA12Pickup',NewClass=class'ScrnAA12Pickup')
    // pickupReplaceArray(10)=(oldClass=Class'KFMod.SinglePickup',NewClass=class'ScrnSinglePickup')
    // pickupReplaceArray(11)=(oldClass=Class'KFMod.Magnum44Pickup',NewClass=class'ScrnMagnum44Pickup')
    // pickupReplaceArray(12)=(oldClass=Class'KFMod.MK23Pickup',NewClass=class'ScrnMK23Pickup')
    // pickupReplaceArray(13)=(oldClass=Class'KFMod.DeaglePickup',NewClass=class'ScrnDeaglePickup')
    // pickupReplaceArray(14)=(oldClass=Class'KFMod.WinchesterPickup',NewClass=class'ScrnWinchesterPickup')
    // pickupReplaceArray(15)=(oldClass=Class'KFMod.SPSniperPickup',NewClass=class'ScrnSPSniperPickup')
    // pickupReplaceArray(16)=(oldClass=Class'KFMod.M14EBRPickup',NewClass=class'ScrnM14EBRPickup')
    // pickupReplaceArray(17)=(oldClass=Class'KFMod.M99Pickup',NewClass=class'ScrnM99Pickup')
    // pickupReplaceArray(18)=(oldClass=Class'KFMod.BullpupPickup',NewClass=class'ScrnBullpupPickup')
    // pickupReplaceArray(19)=(oldClass=Class'KFMod.AK47Pickup',NewClass=class'ScrnAK47Pickup')
    // pickupReplaceArray(20)=(oldClass=Class'KFMod.M4Pickup',NewClass=class'ScrnM4Pickup')
    // pickupReplaceArray(21)=(oldClass=Class'KFMod.SPThompsonPickup',NewClass=class'ScrnSPThompsonPickup')
    // pickupReplaceArray(22)=(oldClass=Class'KFMod.ThompsonDrumPickup',NewClass=class'ScrnThompsonDrumPickup')
    // pickupReplaceArray(23)=(oldClass=Class'KFMod.SCARMK17Pickup',NewClass=class'ScrnSCARMK17Pickup')
    // pickupReplaceArray(24)=(oldClass=Class'KFMod.FNFAL_ACOG_Pickup',NewClass=class'ScrnFNFAL_ACOG_Pickup')
    // pickupReplaceArray(25)=(oldClass=Class'KFMod.MachetePickup',NewClass=class'ScrnMachetePickup')
    // pickupReplaceArray(26)=(oldClass=Class'KFMod.AxePickup',NewClass=class'ScrnAxePickup')
    // pickupReplaceArray(27)=(oldClass=Class'KFMod.ChainsawPickup',NewClass=class'ScrnChainsawPickup')
    // pickupReplaceArray(28)=(oldClass=Class'KFMod.KatanaPickup',NewClass=class'ScrnKatanaPickup')
    // pickupReplaceArray(29)=(oldClass=Class'KFMod.ScythePickup',NewClass=class'ScrnScythePickup')
    // pickupReplaceArray(30)=(oldClass=Class'KFMod.ClaymoreSwordPickup',NewClass=class'ScrnClaymoreSwordPickup')
    // pickupReplaceArray(31)=(oldClass=Class'KFMod.CrossbuzzsawPickup',NewClass=class'ScrnCrossbuzzsawPickup')
    // pickupReplaceArray(32)=(oldClass=Class'KFMod.MAC10Pickup',NewClass=class'ScrnMAC10Pickup')
    // pickupReplaceArray(33)=(oldClass=Class'KFMod.FlareRevolverPickup',NewClass=class'ScrnFlareRevolverPickup')
    // pickupReplaceArray(34)=(oldClass=Class'KFMod.DualFlareRevolverPickup',NewClass=class'ScrnDualFlareRevolverPickup')
    // pickupReplaceArray(35)=(oldClass=Class'KFMod.FlameThrowerPickup',NewClass=class'ScrnFlameThrowerPickup')
    // pickupReplaceArray(36)=(oldClass=Class'KFMod.HuskGunPickup',NewClass=class'ScrnHuskGunPickup')
    // pickupReplaceArray(37)=(oldClass=Class'KFMod.PipeBombPickup',NewClass=class'ScrnPipeBombPickup')
    pickupReplaceArray(2)=(oldClass=Class'KFMod.M4203Pickup',NewClass=class'M4203CPickup')
    // pickupReplaceArray(39)=(oldClass=Class'KFMod.M32Pickup',NewClass=class'ScrnM32Pickup')
    pickupReplaceArray(3)=(oldClass=Class'KFMod.LAWPickup',NewClass=class'LAWDPickup')
    pickupReplaceArray(4)=(oldClass=Class'KFMod.DwarfAxePickup',NewClass=class'DwarfAxeZPickup')
    // pickupReplaceArray(41)=(oldClass=Class'KFMod.Dual44MagnumPickup',NewClass=class'ScrnDual44MagnumPickup')
    // pickupReplaceArray(42)=(oldClass=Class'KFMod.DualMK23Pickup',NewClass=class'ScrnDualMK23Pickup')
    // pickupReplaceArray(43)=(oldClass=Class'KFMod.DualDeaglePickup',NewClass=class'ScrnDualDeaglePickup')
    // pickupReplaceArray(44)=(oldClass=Class'KFMod.SyringePickup',NewClass=class'ScrnSyringePickup')
    // pickupReplaceArray(45)=(oldClass=Class'KFMod.FragPickup',NewClass=class'ScrnFragPickup')
    // pickupReplaceArray(46)=(oldClass=Class'KFMod.M79Pickup',NewClass=class'ScrnM79Pickup')
    // pickupReplaceArray(47)=(oldClass=Class'KFMod.CrossbowPickup',NewClass=class'ScrnCrossbowPickup')
    // pickupReplaceArray(48)=(oldClass=Class'KFMod.KnifePickup',NewClass=class'ScrnKnifePickup')

	MinPerksLevel=6
	MaxPerksLevel=6
	RequirementScaling=1
	RemotePort=5000
	RemoteDatabaseURL="192.168.1.33"
	RemoteFTPUser="User"
	ServerNewsURL=""
	RemoteFTPDir=""
	RemotePassword="Pass"
	bUseEnhancedScoreboard=True
	bEnableChatIcons=True
	bEnhancedShoulderView=False
	bFixGrenadeExploit=True
	bAdminEditStats=True
	SRScoreboardType=class'MutSR_ScoreBoard'
	SRHudType=class'MutSR_SRHUDA'
	SRMenuType=class'MutSR_SRInvasionLoginMenu'
	SRControllerType=class'MutSR_KFPCServ'
	bEnableWebAdmin=True

	// Medic
	TraderInventory(0)="0:KFMod.MP7MPickup"
	TraderInventory(1)="0:KFMod.BlowerThrowerPickup"
	TraderInventory(2)="0:KFMod.MP5MPickup"
	TraderInventory(3)="0:KFMod.M7A3MPickup"
	TraderInventory(4)="0:KFMod.KrissMPickup"
	// Support
	TraderInventory(5)="1:KFMod.ShotgunPickup"
	TraderInventory(6)="1:KFMod.KSGPickup"
	TraderInventory(7)="1:KFMod.BoomStickPickup"
	TraderInventory(8)="1:MutSR.BenelliEPickup"
	TraderInventory(9)="1:KFMod.AA12Pickup"
	TraderInventory(10)="1:KFMod.NailGunPickup"
	TraderInventory(11)="1:KFMod.SPShotGunPickup"
	// Sharpshooter
	TraderInventory(12)="2:KFMod.DualiesPickup"
	TraderInventory(13)="2:KFMod.MK23Pickup"
	TraderInventory(14)="2:KFMod.DualMK23Pickup"
	TraderInventory(15)="2:KFMod.Magnum44Pickup"
	TraderInventory(16)="2:KFMod.Dual44MagnumPickup"
	TraderInventory(17)="2:KFMod.DeaglePickup"
	TraderInventory(18)="2:KFMod.DualDeaglePickup"
	TraderInventory(19)="2:KFMod.WinchesterPickup"
	TraderInventory(20)="2:KFMod.CrossbowPickup"
	TraderInventory(21)="2:KFMod.M14EBRPickup"
	TraderInventory(22)="2:KFMod.M99Pickup"
	TraderInventory(23)="2:KFMod.SPSniperPickup"
	// Commando
	TraderInventory(24)="3:KFMod.BullpupPickup"
	TraderInventory(25)="3:KFMod.AK47Pickup"
	TraderInventory(26)="3:KFMod.MKB42Pickup"
	TraderInventory(27)="3:KFMod.M4Pickup"
	TraderInventory(28)="3:KFMod.SCARMK17Pickup"
	TraderInventory(29)="3:KFMod.FNFAL_ACOG_Pickup"
	TraderInventory(30)="3:KFMod.ThompsonPickup"
	TraderInventory(31)="3:KFMod.SPThompsonPickup"
	TraderInventory(32)="3:KFMod.ThompsonDrumPickup"
	// Berserker
	TraderInventory(33)="4:KFMod.MachetePickup"
	TraderInventory(34)="4:KFMod.AxePickup"
	TraderInventory(35)="4:KFMod.ChainsawPickup"
	TraderInventory(36)="4:KFMod.KatanaPickup"
	TraderInventory(37)="4:KFMod.ClaymoreSwordPickup"
	TraderInventory(38)="4:KFMod.CrossbuzzsawPickup"
	TraderInventory(39)="4:KFMod.ScythePickup"
	TraderInventory(40)="4:MutSR.DwarfAxeZPickup"
	// Firebug
	TraderInventory(41)="5:KFMod.FlameThrowerPickup"
	TraderInventory(42)="5:KFMod.TrenchgunPickup"
	TraderInventory(43)="5:KFMod.FlareRevolverPickup"
	TraderInventory(44)="5:KFMod.DualFlareRevolverPickup"
	TraderInventory(45)="5:KFMod.MAC10Pickup"
	TraderInventory(46)="5:KFMod.HuskGunPickup"
	// Demolition
	TraderInventory(47)="6:KFMod.PipeBombPickup"
	TraderInventory(48)="6:KFMod.M79Pickup"
	TraderInventory(49)="6:KFMod.M32Pickup"
	TraderInventory(50)="6:MutSR.M4203CPickup"
	TraderInventory(51)="6:KFMod.SPGrenadePickup"
	TraderInventory(52)="6:MutSR.LAWDPickup"
	TraderInventory(53)="6:KFMod.SealSquealPickup"
	TraderInventory(54)="6:KFMod.SeekerSixPickup"
	// No perk
	TraderInventory(55)="7:KFMod.ZEDMKIIPickup"
	TraderInventory(56)="7:KFMod.ZEDGUNPickup"
	// Golden
	TraderInventory(57)="1:KFMod.GoldenAA12Pickup"
	TraderInventory(58)="3:KFMod.GoldenAK47Pickup"
	TraderInventory(59)="4:KFMod.GoldenChainsawPickup"
	TraderInventory(60)="2:KFMod.GoldenDeaglePickup"
	TraderInventory(61)="2:KFMod.GoldenDualDeaglePickup"
	TraderInventory(62)="5:KFMod.GoldenFTPickup"
	TraderInventory(63)="4:KFMod.GoldenKatanaPickup"
	TraderInventory(64)="6:KFMod.GoldenM79Pickup"
	// Camo
	TraderInventory(65)="0:KFMod.CamoMP5MPickup"
	TraderInventory(66)="1:KFMod.CamoShotgunPickup"
	TraderInventory(67)="3:KFMod.CamoM4Pickup"
	TraderInventory(68)="6:KFMod.CamoM32Pickup"
	// Neon
	TraderInventory(69)="3:KFMod.NeonAK47Pickup"
	TraderInventory(70)="0:KFMod.NeonKrissMPickup"
	TraderInventory(71)="1:KFMod.NeonKSGPickup"
	TraderInventory(72)="3:KFMod.NeonSCARMK17Pickup"

    WeaponCategories(0)="0:[-PARAMEDIC|医疗-]"
    WeaponCategories(1)="1:[-ENFORCER|支援-]"
    WeaponCategories(2)="2:[-MARKSMAN|神射-]"
    WeaponCategories(3)="3:[-CTROPPER|突击-]"
    WeaponCategories(4)="4:[-BAZERKER|狂战-]"
    WeaponCategories(5)="5:[-ARSONIST|纵火-]"
    WeaponCategories(6)="6:[-BLASTER|爆破-]"
    WeaponCategories(7)="7:[-OFFPERK-]"

	Mutator(0) = ""
	SmileyTags(0)=(IconTag="ah",IconTexture="MutSR.A")
	//  SmileyTags(1)=(IconTag="unhappy",IconTexture="MutSR.BGX")
	//  SmileyTags(2)=(IconTag="fuck",IconTexture="MutSR.BS")
	//  SmileyTags(3)=(IconTag="guai",IconTexture="MutSR.G")
	//  SmileyTags(4)=(IconTag="han",IconTexture="MutSR.H")
	//  SmileyTags(5)=(IconTag="hehe",IconTexture="MutSR.HH")
	//  SmileyTags(6)=(IconTag="heixian",IconTexture="MutSR.HX")
	//  SmileyTags(7)=(IconTag="huaxin",IconTexture="MutSR.HX2")
	//  SmileyTags(8)=(IconTag="jingku",IconTexture="MutSR.JK")
	//  SmileyTags(9)=(IconTag="jingya",IconTexture="MutSR.JY")
	//  SmileyTags(10)=(IconTag="cool",IconTexture="MutSR.K")
	//  SmileyTags(11)=(IconTag="kuanghan",IconTexture="MutSR.KH")
	//  SmileyTags(12)=(IconTag="happy",IconTexture="MutSR.KX")
	//  SmileyTags(13)=(IconTag="tear",IconTexture="MutSR.L")
	//  SmileyTags(14)=(IconTag="mianqiang",IconTexture="MutSR.MQ")
	//  SmileyTags(15)=(IconTag="cold",IconTexture="MutSR.N")
	//  SmileyTags(16)=(IconTag="angry",IconTexture="MutSR.NU")
	//  SmileyTags(17)=(IconTag="pu",IconTexture="MutSR.P")
	//  SmileyTags(18)=(IconTag="dosh",IconTexture="MutSR.Q")
	//  SmileyTags(19)=(IconTag="mad",IconTexture="MutSR.SQ")
	//  SmileyTags(20)=(IconTag="high",IconTexture="MutSR.TKX")
	//  SmileyTags(21)=(IconTag="naive",IconTexture="MutSR.TS")
	//  SmileyTags(22)=(IconTag="smile",IconTexture="MutSR.XY")
	//  SmileyTags(23)=(IconTag="yi",IconTexture="MutSR.Y")
	//  SmileyTags(24)=(IconTag="yiwen",IconTexture="MutSR.YW")
	//  SmileyTags(25)=(IconTag="yinxian",IconTexture="MutSR.YX")
	//  SmileyTags(26)=(IconTag="good",IconTexture="MutSR.ZB")
	//  SmileyTags(27)=(IconTag="haha",IconTexture="MutSR.HH1")
	//  SmileyTags(28)=(IconTag="sleep",IconTexture="MutSR.SJ")
	//  SmileyTags(29)=(IconTag="yuan",IconTexture="MutSR.WQ")
	//  SmileyTags(30)=(IconTag="huaji",IconTexture="MutSR.HJ")
	//  SmileyTags(31)=(IconTag="wmm",IconTexture="MutSR.WMM")
	//  SmileyTags(32)=(IconTag="llxg",IconTexture="MutSR.LLXG")
	//  SmileyTags(33)=(IconTag="seeu",IconTexture="MutSR.KNZB")
	//  SmileyTags(34)=(IconTag="doge",IconTexture="MutSR.DOGE")
	//  SmileyTags(35)=(IconTag="doge1",IconTexture="MutSR.DOGE1")
	//  SmileyTags(36)=(IconTag="nani",IconTexture="MutSR.NN")
	//  SmileyTags(37)=(IconTag="cannian",IconTexture="MutSR.CN")
	//  SmileyTags(38)=(IconTag="chijing",IconTexture="MutSR.CJ")
	//  SmileyTags(39)=(IconTag="233",IconTexture="MutSR.233")
	//  SmileyTags(40)=(IconTag="2333",IconTexture="MutSR.2333")
	//  SmileyTags(41)=(IconTag="23333",IconTexture="MutSR.23333")
	//  SmileyTags(42)=(IconTag="fuckit",IconTexture="MutSR.BYSJSG")
	//  SmileyTags(43)=(IconTag="yeyeye",IconTexture="MutSR.HDZDL")
	//  SmileyTags(44)=(IconTag="huang",IconTexture="MutSR.HHA")
	//  SmileyTags(45)=(IconTag="heihh",IconTexture="MutSR.HHH")
	//  SmileyTags(46)=(IconTag="high1",IconTexture="MutSR.HQL")
	//  SmileyTags(47)=(IconTag="high2",IconTexture="MutSR.QLH")
	//  SmileyTags(48)=(IconTag="note",IconTexture="MutSR.SHZYD")
	//  SmileyTags(49)=(IconTag="gn",IconTexture="MutSR.WA")
	//  SmileyTags(50)=(IconTag="wow",IconTexture="MutSR.WO")
	//  SmileyTags(51)=(IconTag="ttpb",IconTexture="MutSR.ZBKSLM")
	//  SmileyTags(52)=(IconTag="666",IconTexture="MutSR.666")
	//  SmileyTags(53)=(IconTag="2...",IconTexture="MutSR.DDD")
	//  SmileyTags(54)=(IconTag="???",IconTexture="MutSR.Wenhao")
	//  SmileyTags(55)=(IconTag="fan",IconTexture="MutSR.Fan")
	//  SmileyTags(56)=(IconTag="yes",IconTexture="MutSR.Haode")
	//  SmileyTags(57)=(IconTag="trash",IconTexture="MutSR.Laji")
	//  SmileyTags(58)=(IconTag="notfunny",IconTexture="MutSR.Buhaoxiao")
	//  SmileyTags(59)=(IconTag="1...",IconTexture="MutSR.DD")
	//  SmileyTags(60)=(IconTag="yep",IconTexture="MutSR.Keyi")
	//  SmileyTags(61)=(IconTag="great",IconTexture="MutSR.Qiangshi")
}