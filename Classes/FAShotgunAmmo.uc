//=============================================================================
// FAShotgunAmmo
//=============================================================================
// Steampunk Shotgun Ammo
//=============================================================================
// Killing Floor Source
// Copyright (C) 2013 Tripwire Interactive LLC
// - John "Ramm-Jaeger" Gibson
//=============================================================================
class FAShotgunAmmo extends KFAmmunition;

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

defaultproperties
{
     AmmoPickupAmount=10
     MaxAmmo=140
     InitialAmount=60
     IconMaterial=Texture'KillingFloorHUD.Generic.HUD'
     IconCoords=(X1=451,Y1=445,X2=510,Y2=500)
}
