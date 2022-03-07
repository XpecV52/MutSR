class MutSR_SRVetSupportSpec extends MutSR_SRVeterancyTypes
	abstract;

static function int GetPerkProgressInt( MutSR_ClientPerkRepLink StatOther, out int FinalInt, byte CurLevel, byte ReqNum )
{
	switch( CurLevel )
	{
	case 0:
		if( ReqNum==0 )
			FinalInt = 1000;
		else FinalInt = 1000;
		break;
	case 1:
		if( ReqNum==0 )
			FinalInt = 2000;
		else FinalInt = 5000;
		break;
	case 2:
		if( ReqNum==0 )
			FinalInt = 7000;
		else FinalInt = 100000;
		break;
	case 3:
		if( ReqNum==0 )
			FinalInt = 35000;
		else FinalInt = 500000;
		break;
	case 4:
		if( ReqNum==0 )
			FinalInt = 120000;
		else FinalInt = 1500000;
		break;
	case 5:
		if( ReqNum==0 )
			FinalInt = 250000;
		else FinalInt = 3500000;
		break;
	case 6:
		if( ReqNum==0 )
			FinalInt = 370000;
		else FinalInt = 5500000;
		break;
	default:
		if( ReqNum==0 )
			FinalInt = 370000+GetDoubleScaling(CurLevel,35000);
		else FinalInt = 5500000+GetDoubleScaling(CurLevel,500000);
		break;
	}
	if( ReqNum==0 )
		return Min(StatOther.RWeldingPointsStat,FinalInt);
	return Min(StatOther.RShotgunDamageStat,FinalInt);
}

static function int AddCarryMaxWeight(KFPlayerReplicationInfo KFPRI)
{
	
	return 9; // 9 more carry slots
}

static function float GetWeldSpeedModifier(KFPlayerReplicationInfo KFPRI)
{
	if ( KFPRI.ClientVeteranSkillLevel <= 3 )
		return 1.0 + (0.25 * float(KFPRI.ClientVeteranSkillLevel));
	return 3.0; // 200% increase in speed
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
	if ( AmmoType == class'FragAmmo' )
		// Up to 6 extra Grenades
		return 1.0 + (0.20 * float(KFPRI.ClientVeteranSkillLevel));
	if ( AmmoType == class'ShotgunAmmo' ||   AmmoType == class'BenelliAmmo' || AmmoType == class'KSGAmmo' || AmmoType == class'NailGunAmmo'
        || AmmoType == class'GoldenBenelliAmmo' || AmmoType == class'SPShotgunAmmo'
        || AmmoType == class'CamoShotgunAmmo' || AmmoType == class'NeonKSGAmmo' )
	{
		return 1.35; // 35% increase in shotgun ammo carried
	}
	else if (AmmoType == class'DBShotgunAmmo' ) return 1.25;

	else if (AmmoType == class'AA12Ammo' || AmmoType == class'GoldenAA12Ammo') return 1.50;
	return 1.0;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
	if ( DmgType == class'DamTypeShotgun' || DmgType == class'DamTypeDBShotgun' || DmgType == class'DamTypeAA12Shotgun'
        || DmgType == class'DamTypeBenelli'|| DmgType == class'DamTypeBenelliE' || DmgType == class'DamTypeKSGShotgun' || DmgType == class'DamTypeNailgun'
        || DmgType == class'DamTypeSPShotgun' )
	{
		if ( KFPRI.ClientVeteranSkillLevel == 0 )
			return float(InDamage) * 1.10;
		return InDamage * 1.70; // Up to 80% more damage with Shotguns
	}
	else if ( DmgType == class'DamTypeFrag' && KFPRI.ClientVeteranSkillLevel > 0 )
	{
		return float(InDamage) * 1.525; // Up to 50% more damage with Nades
	}
	return InDamage;
}

// Reduce Penetration damage with Shotgun slower
static function float GetShotgunPenetrationDamageMulti(KFPlayerReplicationInfo KFPRI, float DefaultPenDamageReduction)
{
	local float PenDamageInverse;

	PenDamageInverse = 1.0 - FMax(0,DefaultPenDamageReduction);

	if ( KFPRI.ClientVeteranSkillLevel == 0 )
		return DefaultPenDamageReduction + (PenDamageInverse / 9.0);

	return DefaultPenDamageReduction + ((PenDamageInverse / 5.5555) * float(Min(KFPRI.ClientVeteranSkillLevel, 5)));
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
	if ( Item == class'ShotgunPickup' || Item == class'BoomstickPickup' || Item == class'AA12Pickup'
        || Item == class'BenelliPickup'|| Item == class'BenelliEPickup' || Item == class'KSGPickup' || Item == class'NailGunPickup'
        || Item == class'GoldenBenelliPickup' || Item == class'SPShotgunPickup' || Item == class'GoldenAA12Pickup'
        || Item == class'CamoShotgunPickup' || Item == class'NeonKSGPickup' )
		return FMax(0.9 - (0.10 * float(KFPRI.ClientVeteranSkillLevel)),0.1f); // Up to 70% discount on Shotguns
	return 1.0;
}

// Give Extra Items as Default
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
	// If Level 5, give them Assault Shotgun
	if ( KFPRI.ClientVeteranSkillLevel == 5 )
		KFHumanPawn(P).CreateInventoryVeterancy(string(class'Shotgun'), default.StartingWeaponSellPriceLevel5);
	// If Level 6, give them Hunting Shotgun
	if ( KFPRI.ClientVeteranSkillLevel >= 6 )
		KFHumanPawn(P).CreateInventoryVeterancy(string(class'BoomStick'), default.StartingWeaponSellPriceLevel6);
}

static function string GetCustomLevelInfo( byte Level )
{
	local string S;

	S = Default.CustomLevelInfo;
	S = Repl(S,"%s",GetPercentStr(0.1 * float(Level)));
	S = Repl(S,"%g",GetPercentStr(0.1*float(Level)-0.1f));
	S = Repl(S,"%d",GetPercentStr(0.1+FMin(0.1 * float(Level),0.8f)));
	return S;
}


static function float GetReloadSpeedModifier(KFPlayerReplicationInfo KFPRI, KFWeapon Other)
{
	if (BenelliShotgun(Other)!=None || GoldenBenelliShotgun(Other)!=None)
		return 1.25; // Up to 25% faster reload speed
		
	else if (BenelliEShotgun(Other)!=None)
		return 1.0; // Up to 25% faster reload speed
	return 1.12;
}


static function float GetFireSpeedMod(KFPlayerReplicationInfo KFPRI, Weapon Other)
{
	if(M79GrenadeLauncher(Other)!=None || GoldenM79GrenadeLauncher(Other)!=None ||SPGrenadeLauncher(Other)!=None)
		return 1.15;
	return 1.0;
}


defaultproperties
{
	PerkIndex=1

	OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Support'
	OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Support_Gold'
	VeterancyName="Enforcer"
	Requirements[0]="Weld %x door hitpoints"
	Requirements[1]="Deal %x damage with shotguns"
	NumRequirements=2

	SRLevelEffects(0)="10% more damage with Shotguns|10% better Shotgun penetration|10% faster welding/unwelding|10% discount on Shotguns"
	SRLevelEffects(1)="10% more damage with Shotguns|18% better Shotgun penetration|10% extra shotgun ammo|5% more damage with Grenades|20% increase in grenade capacity|15% increased carry weight|25% faster welding/unwelding|20% discount on Shotguns"
	SRLevelEffects(2)="20% more damage with Shotguns|36% better Shotgun penetration|20% extra shotgun ammo|10% more damage with Grenades|40% increase in grenade capacity|20% increased carry weight|50% faster welding/unwelding|30% discount on Shotguns"
	SRLevelEffects(3)="30% more damage with Shotguns|54% better Shotgun penetration|25% extra shotgun ammo|20% more damage with Grenades|60% increase in grenade capacity|25% increased carry weight|75% faster welding/unwelding|40% discount on Shotguns"
	SRLevelEffects(4)="40% more damage with Shotguns|72% better Shotgun penetration|25% extra shotgun ammo|30% more damage with Grenades|80% increase in grenade capacity|30% increased carry weight|100% faster welding/unwelding|50% discount on Shotguns"
	SRLevelEffects(5)="50% more damage with Shotguns|90% better Shotgun penetration|25% extra shotgun ammo|40% more damage with Grenades|100% increase in grenade capacity|50% increased carry weight|150% faster welding/unwelding|60% discount on Shotguns|Spawn with a Shotgun"
	SRLevelEffects(6)="70% more damage with Shotguns|90% better Shotgun penetration|35% extra shotgun ammo|50% more damage with Grenades|120% increase in grenade capacity|60% increased carry weight|200% faster welding/unwelding|70% discount on Shotguns|Spawn with a Hunting Shotgun"
	CustomLevelInfo="%s more damage with Shotguns|90% better Shotgun penetration|30% extra shotgun ammo|%g more damage with Grenades|120% increase in grenade capacity|%s increased carry weight|150% faster welding/unwelding|%d discount on Shotguns|Spawn with a Hunting Shotgun"
}
