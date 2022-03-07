//=============================================================================
// FAShotgunFireB
//=============================================================================
// Steampunk Shotgun Primary fire class
//=============================================================================
// Killing Floor Source
// Copyright (C) 2013 Tripwire Interactive LLC
// - John "Ramm-Jaeger" Gibson
//=============================================================================
class FAShotgunFireB extends ZEDMKIIAltFire;

simulated function bool AllowFire()
{
	// if(KFWeapon(Weapon).bIsReloading)
	// 	return false;
	// // if(KFPawn(Instigator).SecondaryItem!=none)
	// // 	return false;
	// if(KFPawn(Instigator).bThrowingNade)
	// 	return false;

	// if(KFWeapon(Weapon).MagAmmoRemaining < AmmoPerFire)
	// {
    // 	if( Level.TimeSeconds - LastClickTime>FireRate )
    // 	{
    // 		LastClickTime = Level.TimeSeconds;
    // 	}

	// 	if( AIController(Instigator.Controller)!=None )
	// 		KFWeapon(Weapon).ReloadMeNow();
	// 	return false;
	// }

	return super(WeaponFire).AllowFire();
}

// Overridden to force just 1 projectile, while using more ammo per shot
function DoFireEffect()
{
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator R, Aim;
    local Vector HitLocation, HitNormal;
    local Actor Other;
    local int p;
    local int SpawnCount;
    local float theta;

    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);

    StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;
    StartProj = StartTrace + X*ProjSpawnOffset.X;
    if ( !Weapon.WeaponCentered() && !KFWeap.bAimingRifle )
	    StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;

    // check if projectile would spawn through a wall and adjust start location accordingly
    Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);

// Collision attachment debugging
 /*   if( Other.IsA('ROCollisionAttachment'))
    {
    	log(self$"'s trace hit "$Other.Base$" Collision attachment");
    }*/

    if (Other != None)
    {
        StartProj = HitLocation;
    }

    Aim = AdjustAim(StartProj, AimError);

    SpawnCount = ProjPerFire;

    switch (SpreadStyle)
    {
    case SS_Random:
        X = Vector(Aim);
        for (p = 0; p < SpawnCount; p++)
        {
            R.Yaw = Spread * (FRand()-0.5);
            R.Pitch = Spread * (FRand()-0.5);
            R.Roll = Spread * (FRand()-0.5);
            SpawnProjectile(StartProj, Rotator(X >> R));
        }
        break;
    case SS_Random:
        for (p = 0; p < SpawnCount; p++)
        {
            theta = Spread*PI/32768*(p - float(SpawnCount-1)/2.0);
            X.X = Cos(theta);
            X.Y = Sin(theta);
            X.Z = 0.0;
            SpawnProjectile(StartProj, Rotator(X >> Aim));
        }
        break;
    default:
        SpawnProjectile(StartProj, Aim);
    }

	if (Instigator != none )
	{
        if( Instigator.Physics != PHYS_Falling  )
        {
            Instigator.AddVelocity(KickMomentum >> Instigator.GetViewRotation());
		}
		// Really boost the momentum for low grav
        else if( Instigator.Physics == PHYS_Falling
            && Instigator.PhysicsVolume.Gravity.Z > class'PhysicsVolume'.default.Gravity.Z)
        {
            Instigator.AddVelocity((KickMomentum * LowGravKickMomentumScale) >> Instigator.GetViewRotation());
        }
	}
}

defaultproperties
{
     KickMomentum=(X=-35.000000,Z=5.000000)
     RecoilRate=0.070000
     bRandomPitchFireSound=False
     FireSoundRef="KF_SP_ZEDThrowerSnd.KFO_Shotgun_Primary_Fire_M"
     StereoFireSoundRef="KF_SP_ZEDThrowerSnd.KFO_Shotgun_Primary_Fire_S"
     NoAmmoSoundRef="KF_AA12Snd.AA12_DryFire"
     bWaitForRelease=False
     bAttachSmokeEmitter=True
     FireRate=0.500000
     AmmoClass=Class'MutSR.FAShotgunAmmoB'
     AmmoPerFire=1
     ShakeRotMag=(Z=250.000000)
     ShakeOffsetMag=(Z=6.000000)
     ShakeOffsetTime=1.250000
     ProjectileClass=Class'MutSR.FAShotgunFireBProj'
     FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSPShotgun'
     aimerror=1.000000
}
