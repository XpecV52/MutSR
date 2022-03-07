//=============================================================================
// BenelliEPickup
//=============================================================================
// BenelliEe shotgun pickup class
//=============================================================================
// Killing Floor Source
// Copyright (C) 2011 Tripwire Interactive LLC
// - John "Ramm-Jaeger" Gibson
//=============================================================================
class BenelliEPickup extends KFWeaponPickup;

defaultproperties
{
     Weight=8.000000
     cost=1400
     BuyClipSize=6
     PowerValue=70
     SpeedValue=60
     RangeValue=15
     Description="A military tactical shotgun with semi automatic fire capability. Holds up to 6 shells. "
     ItemName="Benelli M4"
     ItemShortName="Benelli M4"
     AmmoItemName="12-gauge shells"
     CorrespondingPerkIndex=1
     EquipmentCategoryID=2
     InventoryType=Class'MutSR.BenelliEShotgun'
     PickupMessage="You got the Benelli M4."
     PickupSound=Sound'KF_M4ShotgunSnd.foley.WEP_Benelli_Foley_Pickup'
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KF_pickups3_Trip.Rifles.Benelli_Pickup'
     CollisionRadius=35.000000
     CollisionHeight=5.000000
}
