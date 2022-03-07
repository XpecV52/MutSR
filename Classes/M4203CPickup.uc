//=============================================================================
// M4203CPickup
//=============================================================================
// M4 203 Assault Rifle pickup class
//=============================================================================
// Killing Floor Source
// Copyright (C) 2011 Tripwire Interactive LLC
// - John "Ramm-Jaeger" Gibson
//=============================================================================
class M4203CPickup extends M4Pickup;

defaultproperties
{
     cost=2500
     BuyClipSize=1
     PowerValue=90
     RangeValue=75
     Description="An assault rifle with an attached grenade launcher."
     ItemName="M4 203 GrenadeAssaultRifle"
     ItemShortName="M4 203 GrenadeAssaultRifle"
     SecondaryAmmoShortName="M4 203 Grenades"
     PrimaryWeaponPickup=Class'KFMod.M4Pickup'
     CorrespondingPerkIndex=6
     InventoryType=Class'MutSR.M4203CAssaultRifle'
     PickupMessage="You got the M4 203 GrenadeAssaultRifle"
     StaticMesh=StaticMesh'KF_pickups3_Trip.Rifles.M4M203_Pickup'
}
