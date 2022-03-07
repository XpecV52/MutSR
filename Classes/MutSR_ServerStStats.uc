// Written by .:..: (2009)
Class MutSR_ServerStStats extends MutSR_SRStatsBase;

var MutSR_StatsObject MyStatsObject;
var MutSR_ServerPerksMut MutatorOwner;
var byte SelectingIndex;
var bool bHasChanged,bStatsChecking,bStHasInit,bHadSwitchedVet,bSwitchIsOKNow;

var class<MutSR_SRVeterancyTypes> SelectingPerk;

function int GetID()
{
	return MyStatsObject.ID;
}
function SetID( int ID )
{
	MyStatsObject.ID = ID;
}
function PreBeginPlay()
{
	local LinkedReplicationInfo L;

	PlayerOwner = KFPlayerController(Owner);
	if( Rep==None )
	{
		Rep = Spawn(Class'MutSR_ClientPerkRepLink',Owner);
		Rep.StatObject = Self;
		
		if( PlayerOwner.PlayerReplicationInfo.CustomReplicationInfo==None )
			PlayerOwner.PlayerReplicationInfo.CustomReplicationInfo = Rep;
		else
		{
			for( L=PlayerOwner.PlayerReplicationInfo.CustomReplicationInfo; L!=None; L=L.NextReplicationInfo )
				if( L.NextReplicationInfo==None )
				{
					L.NextReplicationInfo = Rep;
					break;
				}
		}
	}
	Super.PreBeginPlay();
}
function PostBeginPlay()
{
	if( Rep!=None )
		Rep.SpawnCustomLinks();

	bStatsReadyNow = MutatorOwner.bNoSavingProgress || !MutatorOwner.bUseRemoteDatabase;
	MyStatsObject = MutatorOwner.GetStatsForPlayer(PlayerOwner);
	if( MyStatsObject!=None && MyStatsObject.bStatsChanged )
		bStatsReadyNow = true; // Server has already the most fresh stats for this client.
	KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).ClientVeteranSkill = None;
	if( !bStatsReadyNow )
	{
		Timer();
		SetTimer(1+FRand(),true);
		return;
	}
	bSwitchIsOKNow = true;
	if( MyStatsObject!=None )
	{
		// Apply selected character.
		if( MyStatsObject.SelectedChar!="" )
			ApplyCharacter(MyStatsObject.SelectedChar);
		else if( Rep.bNoStandardChars && Rep.CustomChars.Length>0 )
		{
			MyStatsObject.SelectedChar = Rep.PickRandomCustomChar();
			ApplyCharacter(MyStatsObject.SelectedChar);
		}

		RepCopyStats();
		bHasChanged = true;
		CheckPerks(true);
		SelectingIndex = MyStatsObject.PerkIndex;
		if( MutatorOwner.bNoPerkChanges && MyStatsObject.ChosenPerk!=None )
			ServerSelectPerk(MyStatsObject.ChosenPerk);
		else ServerSelectPerkName(MyStatsObject.GetSelectedPerk());
		SelectingIndex = 255;
	}
	else CheckPerks(true);
	if( MutatorOwner.bForceGivePerk && KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).ClientVeteranSkill==None )
		ServerSelectPerk(Rep.PickRandomPerk());
	bSwitchIsOKNow = false;
	bHadSwitchedVet = false;
	SetTimer(0.1,false);
}
function ApplyCharacter( string CN )
{
	PlayerOwner.PawnSetupRecord = class'xUtil'.static.FindPlayerRecord(CN);
	if( PlayerOwner.PawnSetupRecord.VoiceClassName!="" )
		PlayerOwner.PlayerReplicationInfo.SetCharacterVoice(PlayerOwner.PawnSetupRecord.VoiceClassName);
	PlayerOwner.PlayerReplicationInfo.SetCharacterName(CN);
}
function ChangeCharacter( string CN )
{
	local bool bCustom;

	bCustom = Rep.IsCustomCharacter(CN);
	if( !bCustom )
	{
		if( Rep.bNoStandardChars && Rep.CustomChars.Length>0 ) // Prevent from switching to a standard character.
		{
			CN = Rep.PickRandomCustomChar();
			bCustom = true;
		}
		else CN = Class'KFGameType'.Static.GetValidCharacter(CN); // Make sure client doesn't chose some invalid character.
	}

	ApplyCharacter(CN);

	if( !bCustom ) // Was not a custom character, don't save client char on server.
		CN = "";
	if( MyStatsObject!=None )
		MyStatsObject.SetSelectedChar(CN);
}

function GetData( string D )
{
	bStatsReadyNow = true;
	MyStatsObject.SetSaveData(D);
	RepCopyStats();
	bHasChanged = true;
	bSwitchIsOKNow = true;

	// Apply selected character.
	if( MyStatsObject.SelectedChar!="" )
		ApplyCharacter(MyStatsObject.SelectedChar);
	else if( Rep.bNoStandardChars && Rep.CustomChars.Length>0 )
	{
		MyStatsObject.SelectedChar = Rep.PickRandomCustomChar();
		ApplyCharacter(MyStatsObject.SelectedChar);
	}

	CheckPerks(true);
	SelectingIndex = MyStatsObject.PerkIndex;
	ServerSelectPerkName(MyStatsObject.GetSelectedPerk());
	SelectingIndex = 255;
	Rep.SendClientPerks();
	if( MutatorOwner.bForceGivePerk && KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).ClientVeteranSkill==None )
		ServerSelectPerk(Rep.PickRandomPerk());
	bHadSwitchedVet = false;
	bSwitchIsOKNow = false;
	SetTimer(0.1,false);
}
function Timer()
{
	if( !bStatsReadyNow )
	{
		MutatorOwner.RequestStats(Self);
		return;
	}
	if( !bStHasInit )
	{
		if( PlayerOwner.SteamStatsAndAchievements!=None && PlayerOwner.SteamStatsAndAchievements!=Self )
			PlayerOwner.SteamStatsAndAchievements.Destroy();
		PlayerOwner.SteamStatsAndAchievements = Self;
		PlayerOwner.PlayerReplicationInfo.SteamStatsAndAchievements = Self;
		bStHasInit = true;
		Rep.SendClientPerks();
	}
	if( bStatsChecking )
	{
		bStatsChecking = false;
		CheckPerks(false);
	}
}
function RepCopyStats()
{
	// Copy all stats from data object for client replication
	Rep.RDamageHealedStat = MyStatsObject.DamageHealedStat;
	Rep.RWeldingPointsStat = MyStatsObject.WeldingPointsStat;
	Rep.RShotgunDamageStat = MyStatsObject.ShotgunDamageStat;
	Rep.RHeadshotKillsStat = MyStatsObject.HeadshotKillsStat;
	Rep.RStalkerKillsStat = MyStatsObject.StalkerKillsStat;
	Rep.RBullpupDamageStat = MyStatsObject.BullpupDamageStat;
	Rep.RMeleeDamageStat = MyStatsObject.MeleeDamageStat;
	Rep.RFlameThrowerDamageStat = MyStatsObject.FlameThrowerDamageStat;
	Rep.RSelfHealsStat = MyStatsObject.SelfHealsStat;
	Rep.RSoleSurvivorWavesStat = MyStatsObject.SoleSurvivorWavesStat;
	Rep.RCashDonatedStat = MyStatsObject.CashDonatedStat;
	Rep.RFeedingKillsStat = MyStatsObject.FeedingKillsStat;
	Rep.RBurningCrossbowKillsStat = MyStatsObject.BurningCrossbowKillsStat;
	Rep.RGibbedFleshpoundsStat = MyStatsObject.GibbedFleshpoundsStat;
	Rep.RStalkersKilledWithExplosivesStat = MyStatsObject.StalkersKilledWithExplosivesStat;
	Rep.RGibbedEnemiesStat = MyStatsObject.GibbedEnemiesStat;
	Rep.RBloatKillsStat = MyStatsObject.BloatKillsStat;
	Rep.RTotalZedTimeStat = MyStatsObject.TotalZedTimeStat;
	Rep.RSirenKillsStat = MyStatsObject.SirenKillsStat;
	Rep.RKillsStat = MyStatsObject.KillsStat;
	Rep.RExplosivesDamageStat = MyStatsObject.ExplosivesDamageStat;
	Rep.TotalPlayTime = MyStatsObject.TotalPlayTime;
	Rep.WinsCount = MyStatsObject.WinsCount;
	Rep.LostsCount = MyStatsObject.LostsCount;
	MyStatsObject.GetCustomValues(Rep.CustomLink);
}

final function ForcePerkChange( Class<MutSR_SRVeterancyTypes> VetType )
{
	bSwitchIsOKNow = true;
	ServerSelectPerk(VetType);
	bSwitchIsOKNow = false;
}
function ServerSelectPerkName( name N )
{
	local byte i,Index;

	if( N=='' )
		return;

	Index = 255;
	for( i=0; i<Rep.CachePerks.Length; i++ )
	{
		if( Rep.CachePerks[i].PerkClass.Name==N )
		{
			ServerSelectPerk(Rep.CachePerks[i].PerkClass);
			return;
		}
		else if( Rep.CachePerks[i].PerkClass.Default.PerkIndex==SelectingIndex )
			Index = i;
	}
	if( Index!=255 )
		ServerSelectPerk(Rep.CachePerks[Index].PerkClass); // Fallback to using saved index.
}
function ServerSelectPerk( Class<MutSR_SRVeterancyTypes> VetType )
{
	local byte i;

	if( !bStatsReadyNow )
		return;
	if( VetType==None || !SelectionOK(VetType) )
	{
		if( !bSwitchIsOKNow )
			PlayerOwner.ClientMessage("Your desired perk is unavailable.");
		return;
	}
	else if( KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).ClientVeteranSkill==VetType )
	{
		if( SelectingPerk!=None )
		{
			SelectingPerk = None;
			PlayerOwner.ClientMessage("You will remain the same perk now.");
		}
		return;
	}
	if( MyStatsObject!=None )
	{
		MyStatsObject.ChosenPerk = VetType;
		MyStatsObject.SetSelectedPerk(VetType.Name);
		MyStatsObject.PerkIndex = VetType.Default.PerkIndex;
	}
	if( !Level.Game.bWaitingToStartMatch && !bSwitchIsOKNow && !MutatorOwner.bAllowAlwaysPerkChanges )
	{
		if( MutatorOwner.bNoPerkChanges && KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).ClientVeteranSkill!=None )
		{
			PlayerOwner.ClientMessage("You are not allowed to change perk during game.");
			return;
		}
		if( PlayerOwner.Pawn!=None )
		{
			if( KFGameReplicationInfo(Level.GRI).bWaveInProgress || bHadSwitchedVet )
				i = 1;
			else
			{
				bHadSwitchedVet = true;
				i = 0;
			}
			if( i==1 )
			{
				PlayerOwner.ClientMessage(Repl(PlayerOwner.YouWillBecomePerkString, "%Perk%", VetType.Default.VeterancyName));
				SelectingPerk = VetType;
				PlayerOwner.SelectedVeterancy = VetType; // Force KFGameType update this.
				return;
			}
		}
	}
	SelectingPerk = None;
	for( i=0; i<Rep.CachePerks.Length; i++ )
	{
		if( Rep.CachePerks[i].PerkClass==VetType )
		{
			if( Rep.CachePerks[i].CurrentLevel==0 )
				return;
			PlayerOwner.SelectedVeterancy = VetType;
			KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).ClientVeteranSkill = VetType;
			KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).ClientVeteranSkillLevel = Rep.CachePerks[i].CurrentLevel-1;
			if( KFHumanPawn(PlayerOwner.Pawn)!=None )
			{
				KFHumanPawn(PlayerOwner.Pawn).VeterancyChanged();
				DropToCarryLimit(KFHumanPawn(PlayerOwner.Pawn));
			}
		}
	}
}
function DropToCarryLimit( KFHumanPawn P )
{
	local byte c;
	local Inventory I;

	while( P.CurrentWeight>P.MaxCarryWeight && ++c<6 )
	{
		for ( I = P.Inventory; I != none; I = I.Inventory )
		{
			if ( KFWeapon(I) != none && !KFWeapon(I).bKFNeverThrow )
			{
				I.Velocity = P.Velocity;
				I.DropFrom(P.Location + VRand() * 10);
				break; // Drop weapons until player is capable of carrying them all.
			}
		}
	}
}

function bool SelectionOK( Class<MutSR_SRVeterancyTypes> VetType )
{
	local byte i;

	for( i=0; i<Rep.CachePerks.Length; i++ )
	{
		if( Rep.CachePerks[i].PerkClass==VetType )
			return (Rep.CachePerks[i].CurrentLevel>0);
	}
	return false;
}
function CheckPerks( bool bInit )
{
	local byte i,NewLevel;

	if( !bStatsReadyNow )
		return;
	if( bInit )
	{
		for( i=0; i<Rep.CachePerks.Length; i++ )
			Rep.CachePerks[i].CurrentLevel = Rep.CachePerks[i].PerkClass.Static.PerkIsAvailable(Rep);
		return;
	}
	for( i=0; i<Rep.CachePerks.Length; i++ )
	{
		NewLevel = Rep.CachePerks[i].CurrentLevel;
		while( NewLevel<Rep.MaximumLevel && Rep.CachePerks[i].PerkClass.Static.LevelIsFinished(Rep,NewLevel) )
			++NewLevel;
		if( NewLevel>Rep.CachePerks[i].CurrentLevel )
		{
			if( KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).ClientVeteranSkill==Rep.CachePerks[i].PerkClass )
				KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).ClientVeteranSkillLevel = NewLevel-1;
			Rep.CachePerks[i].CurrentLevel = NewLevel;
			Rep.ClientPerkLevel(i,NewLevel);
			if( MutatorOwner.bMessageAnyPlayerLevelUp )
				BroadcastLocalizedMessage(Class'MutSR_KFVetEarnedMessagePL',(NewLevel-1),PlayerOwner.PlayerReplicationInfo,,Rep.CachePerks[i].PerkClass);
		}
	}
}

final function DelayedStatCheck()
{
	if( MyStatsObject!=None )
		MyStatsObject.bStatsChanged = true;
	if( bStatsChecking || !bStatsReadyNow )
		return;
	bStatsChecking = true;
	SetTimer(1,false);
}
function NotifyStatChanged()
{
	bHasChanged = true;
	DelayedStatCheck();
}

function MatchEnded()
{
}
function AddDamageHealed(int Amount, optional bool bMP7MHeal, optional bool bMP5MHeal)
{
	bHasChanged = true;
	Rep.RDamageHealedStat+=Amount;
	if( MyStatsObject!=None )
		MyStatsObject.DamageHealedStat+=Amount;
	DelayedStatCheck();
}
function AddWeldingPoints(int Amount)
{
	bHasChanged = true;
	Rep.RWeldingPointsStat+=Amount;
	if( MyStatsObject!=None )
		MyStatsObject.WeldingPointsStat+=Amount;
	DelayedStatCheck();
}
function AddShotgunDamage(int Amount)
{
	bHasChanged = true;
	Rep.RShotgunDamageStat+=Amount;
	if( MyStatsObject!=None )
		MyStatsObject.ShotgunDamageStat+=Amount;
	DelayedStatCheck();
}
function AddHeadshotKill(bool bLaserSightedEBRHeadshot)
{
	bHasChanged = true;
	Rep.RHeadshotKillsStat++;
	if( MyStatsObject!=None )
		MyStatsObject.HeadshotKillsStat++;
	DelayedStatCheck();
}
function AddStalkerKill()
{
	bHasChanged = true;
	Rep.RStalkerKillsStat++;
	if( MyStatsObject!=None )
		MyStatsObject.StalkerKillsStat++;
	DelayedStatCheck();
}
function AddBullpupDamage(int Amount)
{
	bHasChanged = true;
	Rep.RBullpupDamageStat+=Amount;
	if( MyStatsObject!=None )
		MyStatsObject.BullpupDamageStat+=Amount;
	DelayedStatCheck();
}

function AddMeleeDamage(int Amount)
{
	bHasChanged = true;
	Rep.RMeleeDamageStat+=Amount;
	if( MyStatsObject!=None )
		MyStatsObject.MeleeDamageStat+=Amount;
	DelayedStatCheck();
}

function AddFlameThrowerDamage(int Amount)
{
	bHasChanged = true;
	Rep.RFlameThrowerDamageStat+=Amount;
	if( MyStatsObject!=None )
		MyStatsObject.FlameThrowerDamageStat+=Amount;
	DelayedStatCheck();
}
function WaveEnded()
{
	if( SelectingPerk!=None )
	{
		bSwitchIsOKNow = true;
		ServerSelectPerk(SelectingPerk);
		bSwitchIsOKNow = false;
		bHadSwitchedVet = true;
	}
	else bHadSwitchedVet = false;
}
function MatchStarting()
{
	bHadSwitchedVet = false;
}

function AddKill(bool bLaserSightedEBRM14Headshotted, bool bMeleeKill, bool bZEDTimeActive, bool bM4Kill, bool bBenelliKill, bool bRevolverKill, bool bMK23Kill, bool bFNFalKill, bool bBullpupKill, string MapName)
{
	bHasChanged = true;
	Rep.RKillsStat++;
	if( MyStatsObject!=None )
		MyStatsObject.KillsStat++;
	DelayedStatCheck();
}
function AddBloatKill(bool bWithBullpup)
{
	bHasChanged = true;
	Rep.RBloatKillsStat++;
	if( MyStatsObject!=None )
		MyStatsObject.BloatKillsStat++;
	DelayedStatCheck();
}

function AddSirenKill(bool bLawRocketImpact)
{
	bHasChanged = true;
	Rep.RSirenKillsStat++;
	if( MyStatsObject!=None )
		MyStatsObject.SirenKillsStat++;
	DelayedStatCheck();
}

function AddStalkerKillWithExplosives()
{
	bHasChanged = true;
	Rep.RStalkersKilledWithExplosivesStat++;
	if( MyStatsObject!=None )
		MyStatsObject.StalkersKilledWithExplosivesStat++;
	DelayedStatCheck();
}

function AddFireAxeKill();
function AddChainsawScrakeKill();

function AddBurningCrossbowKill()
{
	bHasChanged = true;
	Rep.RBurningCrossbowKillsStat++;
	if( MyStatsObject!=None )
		MyStatsObject.BurningCrossbowKillsStat++;
	DelayedStatCheck();
}

function AddFeedingKill()
{
	bHasChanged = true;
	Rep.RFeedingKillsStat++;
	if( MyStatsObject!=None )
		MyStatsObject.FeedingKillsStat++;
	DelayedStatCheck();
}

function OnGrenadeExploded();
function AddGrenadeKill();
function OnShotHuntingShotgun();
function AddHuntingShotgunKill();
function KilledEnemyWithBloatAcid();
function KilledFleshpound(bool bWithMeleeAttack, bool bWithAA12, bool bWithKnife, bool bWithClaymore);
function AddMedicKnifeKill();

function AddGibKill(bool bWithM79)
{
	bHasChanged = true;
	Rep.RGibbedEnemiesStat++;
	if( MyStatsObject!=None )
		MyStatsObject.GibbedEnemiesStat++;
	DelayedStatCheck();
}

function AddFleshpoundGibKill()
{
	bHasChanged = true;
	Rep.RGibbedFleshpoundsStat++;
	if( MyStatsObject!=None )
		MyStatsObject.GibbedFleshpoundsStat++;
	DelayedStatCheck();
}

function AddSelfHeal()
{
	bHasChanged = true;
	Rep.RSelfHealsStat++;
	if( MyStatsObject!=None )
		MyStatsObject.SelfHealsStat++;
	DelayedStatCheck();
}

function AddOnlySurvivorOfWave()
{
	bHasChanged = true;
	Rep.RSoleSurvivorWavesStat++;
	if( MyStatsObject!=None )
		MyStatsObject.SoleSurvivorWavesStat++;
	DelayedStatCheck();
}

function AddDonatedCash(int Amount)
{
	bHasChanged = true;
	Rep.RCashDonatedStat+=Amount;
	if( MyStatsObject!=None )
		MyStatsObject.CashDonatedStat+=Amount;
	DelayedStatCheck();
}

function AddZedTime(float Amount)
{
	bHasChanged = true;
	Rep.RTotalZedTimeStat+=Amount;
	if( MyStatsObject!=None )
		MyStatsObject.TotalZedTimeStat+=Amount;
}

function AddExplosivesDamage(int Amount)
{
	bHasChanged = true;
	Rep.RExplosivesDamageStat+=Amount;
	if( MyStatsObject!=None )
		MyStatsObject.ExplosivesDamageStat+=Amount;
}

function AddHeadshotKills(int Amount)
{
	bHasChanged = true;
	Rep.RHeadshotKillsStat+= Amount;
	if( MyStatsObject!=None )
		MyStatsObject.HeadshotKillsStat+= Amount;
	DelayedStatCheck();
}
function AddStalkerKills(int Amount)
{
	bHasChanged = true;
	Rep.RStalkerKillsStat+=Amount;
	if( MyStatsObject!=None )
		MyStatsObject.StalkerKillsStat+= Amount;
	DelayedStatCheck();
}

function WonLostGame( bool bDidWin )
{
	if( bDidWin )
	{
		++Rep.WinsCount;
		if( MyStatsObject!=None )
			++MyStatsObject.WinsCount;
	}
	else
	{
		++Rep.LostsCount;
		if( MyStatsObject!=None )
			++MyStatsObject.LostsCount;
	}
	bHasChanged = true;
	DelayedStatCheck();
	GoToState('');
}

// Allow no default functionality with the stats.
function OnStatsAndAchievementsReady();
function PostNetBeginPlay();
function InitializeSteamStatInt(int Index, int Value);
function SetSteamAchievementCompleted(int Index);
event SetLocalAchievementCompleted(int Index);
function ServerSteamStatsAndAchievementsInitialized();
function UpdateAchievementProgress();
function int GetAchievementCompletedCount();
event OnPerkAvailable();
function WonLongGame(string MapName, float Difficulty);
function AddDemolitionsPipebombKill();
function AddSCARKill();
function AddCrawlerKilledInMidair();
function Killed8ZedsWithGrenade();
function Killed10ZedsWithPipebomb();
function KilledHusk(bool bDamagedFriendly);
function AddMac10BurnDamage(int Amount);
function AddGorefastBackstab();
function ScrakeKilledByFire();
function KilledCrawlerWithCrossbow();
function OnLARReloaded();
function AddStalkerKillWithLAR();
function KilledHuskWithPistol();
function AddDroppedTier3Weapon();
function Survived10SecondsAfterVomit();
function CheckChristmasAchievementsCompleted();
function PlayerDied();
function KilledPatriarch(bool bPatriarchHealed, bool bKilledWithLAW, bool bSuicidalDifficulty, bool bOnlyUsedCrossbows, bool bClaymore, string MapName);
function WonGame(string MapName, float Difficulty, bool bLong);

function Destroyed()
{
	if( Rep!=None )
	{
		if( MyStatsObject!=None )
			MyStatsObject.SetCustomValues(Rep.CustomLink);
		Rep.Destroy();
		Rep = None;
	}
	if( PlayerOwner!=None && !PlayerOwner.bDeleteMe )
	{
		// Was destroyed mid-game for random reason, respawn.
		MutatorOwner.PendingPlayers[MutatorOwner.PendingPlayers.Length] = PlayerOwner;
		MutatorOwner.SetTimer(0.1,false);
	}
	Super.Destroyed();
}

Auto state PlaytimeTimer
{
Begin:
	while( true )
	{
		Sleep(1.f);
		if( bStatsReadyNow && !PlayerOwner.PlayerReplicationInfo.bOnlySpectator )
		{
			++Rep.TotalPlayTime;
			if( MyStatsObject!=None )
				++MyStatsObject.TotalPlayTime;
		}
	}
}

defaultproperties
{
	SelectingIndex=255
}