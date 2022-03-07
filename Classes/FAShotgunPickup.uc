//=============================================================================
// FAShotgunPickup
//=============================================================================
// Steampunk Shotgun Pickup.
//=============================================================================
// Killing Floor Source
// Copyright (C) 2013 Tripwire Interactive LLC
// - John "Ramm-Jaeger" Gibson
//=============================================================================
class FAShotgunPickup extends KFWeaponPickup;

function bool CheckCanCarry(KFHumanPawn Hm)
{
  local KFPlayerReplicationInfo KFPRI;
  KFPRI = KFPlayerReplicationInfo(Hm.PlayerReplicationInfo);
  if (KFPRI != none)
   {
     if (KFPRI.ClientVeteranSkill.Name == 'MutSR_SRVetFirebug' && KFPRI.ClientVeteranSkillLevel >= 6 )
       return Super.CheckCanCarry(Hm);
   }
  return false;
}

defaultproperties
{
     Weight=10.000000
     cost=5500
     AmmoCost=60
     BuyClipSize=15
     PowerValue=60
     SpeedValue=50
     RangeValue=20
     Description="Flame MCZ, FlameAutoShotgun for Pyro."
     ItemName="Flame MCZ AutoShotgun"
     ItemShortName="Flame MCZ AutoShotgun"
     AmmoItemName="M.C.Z. Drum"
     CorrespondingPerkIndex=5
     EquipmentCategoryID=3
     InventoryType=Class'MutSR.FAShotgun'
     PickupMessage="You got the Flame MCZ AutoShotgun."
     PickupSound=Sound'KF_SP_ZEDThrowerSnd.KFO_Shotgun_Pickup'
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KF_IJC_Summer_Weps.Jackhammer'
     CollisionRadius=35.000000
     CollisionHeight=5.000000
}
