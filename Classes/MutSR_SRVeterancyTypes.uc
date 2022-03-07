// Written by .:..: (2009)
// Base class of all server veterancy types
class MutSR_SRVeterancyTypes extends KFVeterancyTypes
	abstract;

var() localized string CustomLevelInfo;
var() localized array<string> SRLevelEffects; // Added in ver 5.00, dynamic array for level effects.
var() byte NumRequirements;
var() localized string DisableTag,DisableDescription; // Can be set as a reason to hide inventory from specific players.

// Can be used to add in custom stats.
static function AddCustomStats( MutSR_ClientPerkRepLink Other );

// Return the level of perk that is available, 0 = perk is n/a.
static function byte PerkIsAvailable( MutSR_ClientPerkRepLink StatOther )
{
	local byte i,a,b;

	b = StatOther.MaximumLevel+1;
	a = Min(StatOther.MinimumLevel,b);

	while( true )
	{
		if( a==b || (a+1)==b )
		{
			if( a<StatOther.MaximumLevel && LevelIsFinished(StatOther,a) )
				++a;
			break;
		}
		i = a+((b-a)>>1);
		if( !LevelIsFinished(StatOther,i) ) // Lower!
			b = i;
		else a = i; // Higher!
	}
	return Clamp(a,StatOther.MinimumLevel,StatOther.MaximumLevel);

	// Check which level it fits in to.
	/*for( i=0; i<StatOther.MaximumLevel; i++ )
	{
		if( !LevelIsFinished(StatOther,i) )
			return Clamp(i,StatOther.MinimumLevel,StatOther.MaximumLevel);
	}
	return StatOther.MaximumLevel;*/
}

// Return the number of different requirements this level has.
static function byte GetRequirementCount( MutSR_ClientPerkRepLink StatOther, byte CurLevel )
{
	if( CurLevel==StatOther.MaximumLevel )
		return 0;
	return default.NumRequirements;
}

// Return 0-1 % of how much of the progress is done to gain this perk (for menu GUI).
static function float GetTotalProgress( MutSR_ClientPerkRepLink StatOther, byte CurLevel )
{
	local byte i,rc,Minimum;
	local int R,V,NegReq;
	local float RV;

	if( CurLevel==StatOther.MaximumLevel )
		return 1.f;
	if( StatOther.bMinimalRequirements )
	{
		Minimum = 0;
		CurLevel = Max(CurLevel-StatOther.MinimumLevel,0);
	}
	else Minimum = StatOther.MinimumLevel;

	rc = GetRequirementCount(StatOther,CurLevel);
	for( i=0; i<rc; i++ )
	{
		V = GetPerkProgressInt(StatOther,R,CurLevel,i);
		if( StatOther.RequirementScaling!=1 )
			R*=StatOther.RequirementScaling;
		if( CurLevel>Minimum )
		{
			GetPerkProgressInt(StatOther,NegReq,(CurLevel-1),i);
			if( StatOther.RequirementScaling!=1 )
				NegReq*=StatOther.RequirementScaling;
			R-=NegReq;
			V-=NegReq;
		}
		if( R<=0 ) // Avoid division by zero error.
			RV+=1.f;
		else RV+=FClamp(float(V)/(float(R)),0.f,1.f);
	}
	return RV/float(rc);
}

// Return true if this level is earned.
static function bool LevelIsFinished( MutSR_ClientPerkRepLink StatOther, byte CurLevel )
{
	local byte i,rc;
	local int R,V;

	if( CurLevel==StatOther.MaximumLevel )
		return false;
	if( StatOther.bMinimalRequirements )
		CurLevel = Max(CurLevel-StatOther.MinimumLevel,0);
	rc = GetRequirementCount(StatOther,CurLevel);
	for( i=0; i<rc; i++ )
	{
		V = GetPerkProgressInt(StatOther,R,CurLevel,i);
		if( StatOther.RequirementScaling!=1 )
			R*=StatOther.RequirementScaling;
		if( R>V )
			return false;
	}
	return true;
}

// Return 0-1 % of how much of the progress is done to gain this individual task (for menu GUI).
static function float GetPerkProgress( MutSR_ClientPerkRepLink StatOther, byte CurLevel, byte ReqNum, out int Numerator, out int Denominator )
{
	local byte Minimum;
	local int Reduced,Cur,Fin;

	if( CurLevel==StatOther.MaximumLevel )
	{
		Denominator = 1;
		Numerator = 1;
		return 1.f;
	}
	if( StatOther.bMinimalRequirements )
	{
		Minimum = 0;
		CurLevel = Max(CurLevel-StatOther.MinimumLevel,0);
	}
	else Minimum = StatOther.MinimumLevel;
	Numerator = GetPerkProgressInt(StatOther,Denominator,CurLevel,ReqNum);
	if( StatOther.RequirementScaling!=1 )
		Denominator*=StatOther.RequirementScaling;
	if( CurLevel>Minimum )
	{
		GetPerkProgressInt(StatOther,Reduced,CurLevel-1,ReqNum);
		if( StatOther.RequirementScaling!=1 )
			Reduced*=StatOther.RequirementScaling;
		Cur = Max(Numerator-Reduced,0);
		Fin = Max(Denominator-Reduced,0);
	}
	else
	{
		Cur = Numerator;
		Fin = Denominator;
	}
	if( Fin<=0 ) // Avoid division by zero.
		return 1.f;
	return FMin(float(Cur)/float(Fin),1.f);
}

// Return int progress for this perk level up.
static function int GetPerkProgressInt( MutSR_ClientPerkRepLink StatOther, out int FinalInt, byte CurLevel, byte ReqNum )
{
	FinalInt = 1;
	return 1;
}
static final function int GetDoubleScaling( byte CurLevel, int InValue )
{
	CurLevel-=6;
	return CurLevel*CurLevel*InValue;
}

// Get display info text for menu GUI
static function string GetVetInfoText( byte Level, byte Type, optional byte RequirementNum )
{
	switch( Type )
	{
	case 0:
		return Default.LevelNames[Min(Level,ArrayCount(Default.LevelNames)-1)]; // This was left in the void of unused...
	case 1:
		if( Level>=Default.SRLevelEffects.Length )
			return GetCustomLevelInfo(Level);
		return Default.SRLevelEffects[Level];
	case 2:
		return Default.Requirements[RequirementNum];
	default:
		return Default.VeterancyName;
	}
}

static function string GetCustomLevelInfo( byte Level )
{
	return Default.CustomLevelInfo;
}
static final function string GetPercentStr( float InValue )
{
	return int(InValue*100.f)$"%";
}

// This function is called for every weapon with and every perk every time trader menu is shown.
// If returned false on any perk, weapon is hidden from the buyable list.
static function bool AllowWeaponInTrader( class<KFWeaponPickup> Pickup, KFPlayerReplicationInfo KFPRI, byte Level )
{
	return true;
}

static function byte PreDrawPerk( Canvas C, byte Level, out Material PerkIcon, out Material StarIcon )
{
	if ( Level>15 )
	{
		PerkIcon = Default.OnHUDGoldIcon;
		StarIcon = Class'HUDKillingFloor'.Default.VetStarGoldMaterial;
		Level-=15;
		C.SetDrawColor(64, 64, 255, C.DrawColor.A);
	}
	else if ( Level>10 )
	{
		PerkIcon = Default.OnHUDGoldIcon;
		StarIcon = Class'HUDKillingFloor'.Default.VetStarGoldMaterial;
		Level-=10;
		C.SetDrawColor(0, 255, 0, C.DrawColor.A);
	}
	else if ( Level>5 )
	{
		PerkIcon = Default.OnHUDGoldIcon;
		StarIcon = Class'HUDKillingFloor'.Default.VetStarGoldMaterial;
		Level-=5;
		C.SetDrawColor(255, 255, 255, C.DrawColor.A);
	}
	else
	{
		PerkIcon = Default.OnHUDIcon;
		StarIcon = Class'HUDKillingFloor'.Default.VetStarMaterial;
		C.SetDrawColor(255, 255, 255, C.DrawColor.A);
	}
	return Min(Level,15);
}

static final function AddPerkedWeapon( class<KFWeapon> W, KFPlayerReplicationInfo KFPRI, Pawn P )
{
	local float C;
	local class<KFWeaponPickup> WC;
	
	WC = class<KFWeaponPickup>(W.Default.PickupClass);
	if( WC==None )
		KFHumanPawn(P).CreateInventory(string(W));
	else
	{
		C = float(WC.Default.cost) * GetCostScaling(KFPRI,WC) * 0.75f;
		KFHumanPawn(P).CreateInventoryVeterancy(string(W),C);
	}
}

defaultproperties
{
	NumRequirements=1
	DisableTag="LOCKED"
	DisableDescription="Can't buy this weapon because the perk says no."
}