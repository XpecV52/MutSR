//=============================================================================
// DamTypeM4203AssaultRifle
//=============================================================================
// Damage type for the M4 with M203 launcher assault rifle primary fire
//=============================================================================
// Killing Floor Source
// Copyright (C) 2011 Tripwire Interactive LLC
// - John "Ramm-Jaeger" Gibson
//=============================================================================
class DamTypeM4203CAssaultRifle extends DamTypeM4AssaultRifle
	abstract;

defaultproperties
{
     HeadShotDamageMult=1.2500000
     WeaponClass=Class'MutSR.M4203CAssaultRifle'
     DeathString="%k killed %o (M4 203 AssaultRifle)."
     FemaleSuicide="%o shot herself in the foot."
     MaleSuicide="%o shot himself in the foot."
}
