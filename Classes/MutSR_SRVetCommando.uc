class MutSR_SRVetCommando extends MutSR_SRVeterancyTypes
	abstract;

static function int GetPerkProgressInt( MutSR_ClientPerkRepLink StatOther, out int FinalInt, byte CurLevel, byte ReqNum )
{
	switch( CurLevel )
	{
	case 0:
		if( ReqNum==0 )
			FinalInt = 10;
		else FinalInt = 10000;
		break;
	case 1:
		if( ReqNum==0 )
			FinalInt = 30;
		else FinalInt = 25000;
		break;
	case 2:
		if( ReqNum==0 )
			FinalInt = 100;
		else FinalInt = 100000;
		break;
	case 3:
		if( ReqNum==0 )
			FinalInt = 350;
		else FinalInt = 500000;
		break;
	case 4:
		if( ReqNum==0 )
			FinalInt = 1200;
		else FinalInt = 1500000;
		break;
	case 5:
		if( ReqNum==0 )
			FinalInt = 2300;
		else FinalInt = 3500000;
		break;
	case 6:
		if( ReqNum==0 )
			FinalInt = 3600;
		else FinalInt = 5500000;
		break;
	default:
		if( ReqNum==0 )
			FinalInt = 3600+GetDoubleScaling(CurLevel,350);
		else FinalInt = 5500000+GetDoubleScaling(CurLevel,500000);
	}
	if( ReqNum==0 )
		return Min(StatOther.RStalkerKillsStat,FinalInt);
	return Min(StatOther.RBullpupDamageStat,FinalInt);
}

// Display enemy health bars
static function SpecialHUDInfo(KFPlayerReplicationInfo KFPRI, Canvas C)
{
	local KFMonster KFEnemy;
	local HUDKillingFloor HKF;
	local Pawn P;

	if ( KFPRI.ClientVeteranSkillLevel > 0 )
	{
		HKF = HUDKillingFloor(C.ViewPort.Actor.myHUD);
		P = Pawn(C.ViewPort.Actor.ViewTarget);
		if ( HKF==none || P==none || P.Health<=0 )
			return;

		foreach P.CollidingActors(class'KFMonster',KFEnemy,FMin(160*KFPRI.ClientVeteranSkillLevel,800.f))
		{
			if ( KFEnemy.Health > 0 && (!KFEnemy.Cloaked() || KFEnemy.bZapped || KFEnemy.bSpotted) )
				HKF.DrawHealthBar(C, KFEnemy, KFEnemy.Health, KFEnemy.HealthMax , 50.0);
		}
	}
}

static function bool ShowStalkers(KFPlayerReplicationInfo KFPRI)
{
	return true;
}

static function float GetStalkerViewDistanceMulti(KFPlayerReplicationInfo KFPRI)
{
	switch ( KFPRI.ClientVeteranSkillLevel )
	{
		case 0:
			return 0.0625; // 25%
		case 1:
			return 0.25; // 50%
		case 2:
			return 0.36; // 60%
		case 3:
			return 0.49; // 70%
		case 4:
			return 0.64; // 80%
	}

	return 1.0; // 100% of Standard Distance(800 units or 16 meters)
}

static function float GetMagCapacityMod(KFPlayerReplicationInfo KFPRI, KFWeapon Other)
{
	if (Bullpup(Other) != none || AK47AssaultRifle(Other) != none ||
        SCARMK17AssaultRifle(Other) != none || M4AssaultRifle(Other) != none
        || FNFAL_ACOG_AssaultRifle(Other) != none || MKb42AssaultRifle(Other) != none)
	{
		return 1.50; // 40% increase in assault rifle ammo carry
	}
	else if ( ThompsonSMG(Other) != none || ThompsonDrumSMG(Other) != none
        || SPThompsonSMG(Other) != none)
		return 1.38;
	return 1.0;
}

static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{
	if ( (BullpupAmmo(Other) != none || AK47Ammo(Other) != none ||
        SCARMK17Ammo(Other) != none || M4Ammo(Other) != none
        || FNFALAmmo(Other) != none || MKb42Ammo(Other) != none
        || ThompsonAmmo(Other) != none || GoldenAK47Ammo(Other) != none
        || ThompsonDrumAmmo(Other) != none || SPThompsonAmmo(Other) != none
        || CamoM4Ammo(Other) != none || NeonAK47Ammo(Other) != none ) &&
        KFPRI.ClientVeteranSkillLevel > 0 )
	{
		if ( KFPRI.ClientVeteranSkillLevel == 1 )
			return 1.10;
		else if ( KFPRI.ClientVeteranSkillLevel == 2 )
			return 1.20;
		return 1.30; // 30% increase in assault rifle ammo carry
	}
	return 1.0;
}
static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
	if ( (AmmoType == class'BullpupAmmo' || AmmoType == class'AK47Ammo' ||
        AmmoType == class'SCARMK17Ammo' || AmmoType == class'M4Ammo'
        || AmmoType == class'FNFALAmmo' || AmmoType == class'MKb42Ammo'
        || AmmoType == class'ThompsonAmmo' || AmmoType == class'GoldenAK47Ammo'
        || AmmoType == class'ThompsonDrumAmmo' || AmmoType == class'SPThompsonAmmo'
        || AmmoType == class'CamoM4Ammo' || AmmoType == class'NeonAK47Ammo'
        || AmmoType == class'NeonSCARMK17Ammo' )
        && KFPRI.ClientVeteranSkillLevel > 0 )
	{
		return 1.50; // 50% increase in assault rifle ammo carry
	}
	return 1.0;
}
static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
	if ( DmgType == class'DamTypeBullpup' || DmgType == class'DamTypeAK47AssaultRifle' ||
        DmgType == class'DamTypeSCARMK17AssaultRifle' || DmgType == class'DamTypeM4AssaultRifle'
        || DmgType == class'DamTypeFNFALAssaultRifle' || DmgType == class'DamTypeMKb42AssaultRifle'
        || DmgType == class'DamTypeThompson' || DmgType == class'DamTypeThompsonDrum'
        || DmgType == class'DamTypeSPThompson' )
	{
		if ( ZombieHusk(injured) != none )
			return float(InDamage) * 1.375; // Up to 37.5
		if ( ZombieFleshPound(injured) != none )
			return float(InDamage) * 2.75; // Up to 175% increase in Damage to FP 5.2
		if ( ZombieScrake(injured) != none )
			return float(InDamage) * 2.05; //105%
		if ( ZombieBoss(injured) != none )
			return float(InDamage) * 2.0; //100%
		return float(InDamage) * 1.65; // Up to 65% increase in Damage with Bullpup
	}
	return InDamage;
}

static function float ModifyRecoilSpread(KFPlayerReplicationInfo KFPRI, WeaponFire Other, out float Recoil)
{
	if ( Bullpup(Other.Weapon) != none || AK47AssaultRifle(Other.Weapon) != none ||
        SCARMK17AssaultRifle(Other.Weapon) != none || M4AssaultRifle(Other.Weapon) != none
        || FNFAL_ACOG_AssaultRifle(Other.Weapon) != none || MKb42AssaultRifle(Other.Weapon) != none
        || ThompsonSMG(Other.Weapon) != none || ThompsonDrumSMG(Other.Weapon) != none
        || SPThompsonSMG(Other.Weapon) != none )
	{
		if ( KFPRI.ClientVeteranSkillLevel <= 3 )
			Recoil = 0.95 - (0.05 * float(KFPRI.ClientVeteranSkillLevel));
		else if ( KFPRI.ClientVeteranSkillLevel <= 5 )
			Recoil = 0.70;
		else if ( KFPRI.ClientVeteranSkillLevel == 6 )
			Recoil = 0.55; // Level 6 - 45% recoil reduction
		else Recoil = FMax(0.9 - (0.05 * float(KFPRI.ClientVeteranSkillLevel)),0.f);
		return Recoil;
	}
	Recoil = 1.0;
	return Recoil;
}

static function float GetReloadSpeedModifier(KFPlayerReplicationInfo KFPRI, KFWeapon Other)
{
	return 1.5 / FMin(1.0, (KFPRI.Level.TimeDilation / 1.1)); // Up to 50% faster reload speed
}

// Set number times Zed Time can be extended
static function int ZedTimeExtensions(KFPlayerReplicationInfo KFPRI)
{
	if ( KFPRI.ClientVeteranSkillLevel >= 3 )
		return KFPRI.ClientVeteranSkillLevel + 2; // Up to 8 Zed Time Extensions
	return 0;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
	if ( Item == class'BullpupPickup' || Item == class'AK47Pickup' ||
        Item == class'SCARMK17Pickup' || Item == class'M4Pickup'
        || Item == class'FNFAL_ACOG_Pickup' || Item == class'MKb42Pickup'
        || Item == class'ThompsonPickup' || Item == class'GoldenAK47Pickup'
        || Item == class'ThompsonDrumPickup' || Item == class'SPThompsonPickup'
        || Item == class'CamoM4Pickup' || Item == class'NeonAK47Pickup'
        || Item == class'NeonSCARMK17Pickup'|| Item == class'M4203CPickup' )
		return FMax(0.9 - (0.10 * float(KFPRI.ClientVeteranSkillLevel)),0.1f); // Up to 70% discount on Assault Rifles
	return 1.0;
}

// Give Extra Items as default
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
	// If Level 5, give them Bullpup
	if ( KFPRI.ClientVeteranSkillLevel == 5 )
		KFHumanPawn(P).CreateInventoryVeterancy(string(class'Bullpup'), default.StartingWeaponSellPriceLevel5);
	// If Level 6, give them an AK47
	if ( KFPRI.ClientVeteranSkillLevel >= 6 )
		KFHumanPawn(P).CreateInventoryVeterancy(string(class'AK47AssaultRifle'), default.StartingWeaponSellPriceLevel6);
}

static function string GetCustomLevelInfo( byte Level )
{
	local string S;

	S = Default.CustomLevelInfo;
	S = Repl(S,"%s",GetPercentStr(0.05 * float(Level)+0.05));
	S = Repl(S,"%d",GetPercentStr(0.1+FMin(0.1 * float(Level),0.8f)));
	S = Repl(S,"%z",string(Level-2));
	S = Repl(S,"%r",GetPercentStr(FMin(0.05 * float(Level)+0.1,1.f)));
	return S;
}


static function float GetFireSpeedMod(KFPlayerReplicationInfo KFPRI, Weapon Other)
{
	if(M79GrenadeLauncher(Other)!=None || GoldenM79GrenadeLauncher(Other)!=None ||SPGrenadeLauncher(Other)!=None)
		return 1.15 / FMin(1.0, (KFPRI.Level.TimeDilation / 1.1));
	return 1.0 / FMin(1.0, (KFPRI.Level.TimeDilation / 1.1));
}

defaultproperties
{
	PerkIndex=3

	OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Commando'
	OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Commando_Gold'
	VeterancyName="Trooper"
	Requirements[0]="Kill %x Stalkers with Assault/Battle Rifles"
	Requirements[1]="Deal %x damage with Assault/Battle Rifles"
	NumRequirements=2

	SRLevelEffects(0)="5% more damage with Assault/Battle Rifles|5% less recoil with Assault/Battle Rifles|5% faster reload with all weapons|10% discount on Assault/Battle Rifles|Can see cloaked Stalkers from 4 meters"
	SRLevelEffects(1)="10% more damage with Assault/Battle Rifles|10% less recoil with Assault/Battle Rifles|10% larger Assault/Battle Rifles clip|10% faster reload with all weapons|20% discount on Assault/Battle Rifles|Can see cloaked Stalkers from 8m|Can see enemy health from 4m"
	SRLevelEffects(2)="20% more damage with Assault/Battle Rifles|15% less recoil with Assault/Battle Rifles|20% larger Assault/Battle Rifles clip|15% faster reload with all weapons|30% discount on Assault/Battle Rifles|Can see cloaked Stalkers from 10m|Can see enemy health from 7m"
	SRLevelEffects(3)="30% more damage with Assault/Battle Rifles|20% less recoil with Assault/Battle Rifles|25% larger Assault/Battle Rifles clip|20% faster reload with all weapons|40% discount on Assault/Battle Rifles|Can see cloaked Stalkers from 12m|Can see enemy health from 10m|Zed-Time can be extended by killing an enemy while in slow motion"
	SRLevelEffects(4)="40% more damage with Assault/Battle Rifles|30% less recoil with Assault/Battle Rifles|25% larger Assault/Battle Rifles clip|25% faster reload with all weapons|50% discount on Assault/Battle Rifles|Can see cloaked Stalkers from 14m|Can see enemy health from 13m|Up to 2 Zed-Time Extensions"
	SRLevelEffects(5)="50% more damage with Assault/Battle Rifles|30% less recoil with Assault/Battle Rifles|25% larger Assault/Battle Rifles clip|30% faster reload with all weapons|60% discount on Assault/Battle Rifles|Spawn with a Bullpup|Can see cloaked Stalkers from 16m|Can see enemy health from 16m|Up to 3 Zed-Time Extensions"
	SRLevelEffects(6)="100% more damage with Assault/Battle Rifles|45% less recoil with Assault/Battle Rifles|30% larger Assault/Battle Rifles clip|50% faster reload with all weapons|70% discount on Assault/Battle Rifles|Spawn with an AK47|Can see cloaked Stalkers from 16m|Can see enemy health from 16m|Up to 8 Zed-Time Extensions"
	CustomLevelInfo="100% more damage with Assault/Battle Rifles|%r less recoil with Assault/Battle Rifles|25% larger Assault/Battle Rifles clip|%s faster reload with all weapons|%d discount on Assault/Battle Rifles|Spawn with an AK47|Can see cloaked Stalkers from 16m|Can see enemy health from 16m|Up to %z Zed-Time Extensions"
}