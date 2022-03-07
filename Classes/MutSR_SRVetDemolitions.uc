class MutSR_SRVetDemolitions extends MutSR_SRVeterancyTypes
	abstract;

static function int GetPerkProgressInt( MutSR_ClientPerkRepLink StatOther, out int FinalInt, byte CurLevel, byte ReqNum )
{
	switch( CurLevel )
	{
	case 0:
		FinalInt = 10000;
		break;
	case 1:
		FinalInt = 25000;
		break;
	case 2:
		FinalInt = 100000;
		break;
	case 3:
		FinalInt = 500000;
		break;
	case 4:
		FinalInt = 1500000;
		break;
	case 5:
		FinalInt = 3500000;
		break;
	case 6:
		FinalInt = 5500000;
		break;
	default:
		FinalInt = 5500000+GetDoubleScaling(CurLevel,500000);
	}
	return Min(StatOther.RExplosivesDamageStat,FinalInt);
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
	if ( AmmoType == class'FragAmmo' )
		// Up to 6 extra Grenades
		return 1.0 + (0.20 * float(KFPRI.ClientVeteranSkillLevel));
	else if ( AmmoType == class'PipeBombAmmo' )
		// Up to 6 extra for a total of 8 Remote Explosive Devices
		return 1.0 + (0.5 * float(KFPRI.ClientVeteranSkillLevel));
	else if ( AmmoType == class'LAWAmmo' )
		// Modified in Balance Round 5 to be up to 100% extra ammo
		return 1.0 + (0.20 * float(KFPRI.ClientVeteranSkillLevel));
	return 1.0;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
	if ( class<DamTypeFrag>(DmgType) != none || class<DamTypePipeBomb>(DmgType) != none ||
		 class<DamTypeM79Grenade>(DmgType) != none || class<DamTypeM32Grenade>(DmgType) != none
         || class<DamTypeM203Grenade>(DmgType) != none || class<DamTypeRocketImpact>(DmgType) != none || class<DamTypeDRocketImpact>(DmgType) != none
         || class<DamTypeSPGrenade>(DmgType) != none || class<DamTypeSealSquealExplosion>(DmgType) != none
         || class<DamTypeSeekerSixRocket>(DmgType) != none)
	{
		if ( KFPRI.ClientVeteranSkillLevel == 0 )
			return float(InDamage) * 1.05;
		return float(InDamage) * 1.9; //  Up to 90% extra damage
	}

	return InDamage;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
	if ( class<DamTypeFrag>(DmgType) != none || class<DamTypePipeBomb>(DmgType) != none ||
		 class<DamTypeM79Grenade>(DmgType) != none || class<DamTypeM32Grenade>(DmgType) != none
         || class<DamTypeM203Grenade>(DmgType) != none || class<DamTypeRocketImpact>(DmgType) != none|| class<DamTypeDRocketImpact>(DmgType) != none
         || class<DamTypeSPGrenade>(DmgType) != none || class<DamTypeSealSquealExplosion>(DmgType) != none
         || class<DamTypeSeekerSixRocket>(DmgType) != none)
		return float(InDamage) * FMax(0.75 - (0.05 * float(KFPRI.ClientVeteranSkillLevel)),0.05f);
	return InDamage;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
	if ( Item == class'PipeBombPickup' )
		// Todo, this won't need to be so extreme when we set up the system to only allow him to buy it perhaps
		return FMax(0.5 - (0.04 * float(KFPRI.ClientVeteranSkillLevel)),0.01f); // Up to 93% discount on PipeBomb
	if ( Item == class'M79Pickup' || Item == class 'M32Pickup'
        || Item == class 'LawPickup'|| Item == class 'LawDPickup' || Item == class 'M4203Pickup'|| Item == class 'M4203CPickup'
        || Item == class'GoldenM79Pickup' || Item == class'SPGrenadePickup'
        || Item == class'CamoM32Pickup' || Item == class'SealSquealPickup'
        || Item == class'SeekerSixPickup' )
		return FMax(0.90 - (0.10 * float(KFPRI.ClientVeteranSkillLevel)),0.1f); // Up to 70% discount on M79/M32
	return 1.0;
}

// Change the cost of particular ammo
static function float GetAmmoCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
	if ( Item == class'PipeBombPickup' )
		// Todo, this won't need to be so extreme when we set up the system to only allow him to buy it perhaps
		return FMax(0.5 - (0.04 * float(KFPRI.ClientVeteranSkillLevel)),0.01f); // Up to 93% discount on PipeBomb
	if ( Item == class'M79Pickup' || Item == class'M32Pickup'
        || Item == class'LAWPickup'|| Item == class'LAWDPickup' || Item == class'M4203Pickup'|| Item == class'M4203CPickup'
        || Item == class'GoldenM79Pickup' || Item == class'SPGrenadePickup'
        || Item == class'CamoM32Pickup' || Item == class'SealSquealPickup'
        || Item == class'SeekerSixPickup' )
		return FMax(1.0 - (0.05 * float(KFPRI.ClientVeteranSkillLevel)),0.1f); // Up to 30% discount on Grenade Launcher and LAW Ammo(Balance Round 5)
	return 1.0;
}

// Give Extra Items as default
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
	// If Level 5, give them a pipe bomb
	if ( KFPRI.ClientVeteranSkillLevel >= 5 )
		KFHumanPawn(P).CreateInventoryVeterancy(string(class'PipeBombExplosive'), default.StartingWeaponSellPriceLevel5);
	// If Level 6, give them a M79Grenade launcher and pipe bomb
	if ( KFPRI.ClientVeteranSkillLevel >= 6 )
		KFHumanPawn(P).CreateInventoryVeterancy(string(class'M79GrenadeLauncher'), default.StartingWeaponSellPriceLevel6);
}

static function string GetCustomLevelInfo( byte Level )
{
	local string S;

	S = Default.CustomLevelInfo;
	S = Repl(S,"%s",GetPercentStr(0.1 * float(Level)));
	S = Repl(S,"%r",GetPercentStr(FMin(0.25f+0.05 * float(Level),0.95f)));
	S = Repl(S,"%d",GetPercentStr(FMin(0.5+0.04 * float(Level),0.99f)));
	S = Repl(S,"%x",string(2+Level));
	S = Repl(S,"%y",GetPercentStr(0.1+FMin(0.1 * float(Level),0.8f)));
	return S;
}


static function float GetFireSpeedMod(KFPlayerReplicationInfo KFPRI, Weapon Other)
{
	if(M79GrenadeLauncher(Other)!=None || GoldenM79GrenadeLauncher(Other)!=None ||SPGrenadeLauncher(Other)!=None)
		return 1.15;
	return 1.0;
}

static function float GetReloadSpeedModifier(KFPlayerReplicationInfo KFPRI, KFWeapon Other)
{
	return 1.12; // Up to 12% faster reload speed
}

defaultproperties
{
	PerkIndex=6

	OnHUDIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Demolition'
	OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Demolition_Gold'
	VeterancyName="Blaster"
	Requirements(0)="Deal %x damage with the Explosives"

	StartingWeaponSellPriceLevel5=0

	SRLevelEffects(0)="5% extra Explosives damage|25% resistance to Explosives|10% discount on Explosives|50% off Remote Explosives"
	SRLevelEffects(1)="10% extra Explosives damage|30% resistance to Explosives|20% increase in grenade capacity|Can carry 3 Remote Explosives|20% discount on Explosives|54% off Remote Explosives"
	SRLevelEffects(2)="20% extra Explosives damage|35% resistance to Explosives|40% increase in grenade capacity|Can carry 4 Remote Explosives|30% discount on Explosives|58% off Remote Explosives"
	SRLevelEffects(3)="30% extra Explosives damage|40% resistance to Explosives|60% increase in grenade capacity|Can carry 5 Remote Explosives|40% discount on Explosives|62% off Remote Explosives"
	SRLevelEffects(4)="40% extra Explosives damage|45% resistance to Explosives|80% increase in grenade capacity|Can carry 6 Remote Explosives|50% discount on Explosives|66% off Remote Explosives"
	SRLevelEffects(5)="50% extra Explosives damage|50% resistance to Explosives|100% increase in grenade capacity|Can carry 7 Remote Explosives|60% discount on Explosives|70% off Remote Explosives|Spawn with a Pipe Bomb"
	SRLevelEffects(6)="90% extra Explosives damage|55% resistance to Explosives|120% increase in grenade capacity|Can carry 8 Remote Explosives|70% discount on Explosives|74% off Remote Explosives|Spawn with an M79 and Pipe Bomb"
	CustomLevelInfo="%s extra Explosives damage|%r resistance to Explosives|120% increase in grenade capacity|Can carry %x Remote Explosives|%y discount on Explosives|%d off Remote Explosives|Spawn with an M79 and Pipe Bomb"
}
