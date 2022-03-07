class LAWDFire extends LAWFire;

function bool AllowFire()
{
	return ( Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);
}


defaultproperties
{
     CrouchedAccuracyBonus=0.100000
     KickMomentum=(X=-45.000000,Z=25.000000)
     maxVerticalRecoilAngle=1000
     maxHorizontalRecoilAngle=250
     bRandomPitchFireSound=False
     FireSoundRef="KF_LAWSnd.LAW_Fire"
     StereoFireSoundRef="KF_LAWSnd.LAW_FireST"
     NoAmmoSoundRef="KF_LAWSnd.LAW_DryFire"
     ProjPerFire=2
     ProjSpawnOffset=(X=50.000000,Z=0.000000)
     bSplashDamage=True
     bRecommendSplashDamage=True
     bWaitForRelease=True
     TransientSoundVolume=1.800000
     FireAnim="AimFire"
     FireForce="redeemer_shoot"
    //  FireRate=3.250000
     FireAnimRate=1.600000
     FireRate=2.031250
     AmmoClass=Class'MutSR.LAWDAmmo'
     ShakeRotMag=(X=50.000000,Y=50.000000,Z=400.000000)
     ShakeRotRate=(X=12500.000000,Y=12500.000000,Z=12500.000000)
     ShakeRotTime=5.000000
     ShakeOffsetMag=(X=6.000000,Y=2.000000,Z=10.000000)
     ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
     ShakeOffsetTime=3.000000
     ProjectileClass=Class'MutSR.LAWDProj'
     BotRefireRate=3.250000
     FlashEmitterClass=Class'ROEffects.MuzzleFlash1stKar'
     Spread=0.100000
}
