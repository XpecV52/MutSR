class LAWD extends LAW;

var     float               ForceIdleTime;        //time at which weapon will play idle anim
var     float               ForceIdleOnFireTime;  //time after firing for weapon to play idle anim

//added this to make the HRL rocket draw smaller
simulated function PostBeginPlay()
{
    if ( default.mesh == none )
    {
        PreloadAssets(self, true);
    }

    // Weapon will handle FireMode instantiation
    Super.PostBeginPlay();

    if ( Level.NetMode == NM_DedicatedServer )
        return;

    SetBoneScale(1, 0.70, 'Rocket'); //make the LAW rocket smoler by 30%

    if( !bHasScope )
    {
        KFScopeDetail = KF_None;
    }

    InitFOV();
}

//added to support tweening from new idle position to ironsights
simulated function ZoomIn(bool bAnimateTransition)
{
    if( Level.TimeSeconds < FireMode[0].NextFireTime )
    {
        return;
    }

    super.ZoomIn(bAnimateTransition);

    if( bAnimateTransition )
    {
        if( bZoomOutInterrupted )
        {
            TweenAnim(IdleAimAnim,ZoomTime/2);
        }
        else
        {
            TweenAnim(IdleAimAnim,ZoomTime/2);
        }
    }
}

//overwriting to add ForceIdleTime
simulated function bool StartFire(int Mode)
{
    local bool RetVal;

    RetVal = super.StartFire(Mode);

    if( RetVal )
    {
        if( Mode == 0 && ForceZoomOutOnFireTime > 0 )
        {
            ForceZoomOutTime = Level.TimeSeconds + ForceZoomOutOnFireTime;
        }
        else if( Mode == 1 && ForceZoomOutOnAltFireTime > 0 )
        {
            ForceZoomOutTime = Level.TimeSeconds + ForceZoomOutOnAltFireTime;
        }
        if( Mode == 0 && ForceIdleOnFireTime > 0 )
        {
            ForceIdleTime = Level.TimeSeconds + ForceIdleOnFireTime;
        }
        NumClicks=0;

        InterruptReload();
    }

    return RetVal;
}

//adds a force idle time
simulated function WeaponTick(float dt)
{
    Super.WeaponTick(dt);
    if( ForceIdleTime > 0 )
    {
        if( Level.TimeSeconds - ForceIdleTime > 0 )
        {
            ForceIdleTime = 0;
            PlayIdle();
        }
    }
}

defaultproperties
{    
     IdleAnim=AimIdle //added this for new idle position
     ForceIdleOnFireTime=2.25
     ForceZoomOutOnFireTime=0.100000
     MagCapacity=1
     ReloadRate=3.000000
     WeaponReloadAnim="Reload_LAW"
     MinimumFireRange=300
     Weight=11.000000
     bHasAimingMode=True
     IdleAimAnim="AimIdle"
     StandardDisplayFOV=75.000000
     SleeveNum=3
     TraderInfoTexture=Texture'KillingFloorHUD.Trader_Weapon_Images.Trader_Law'
     bIsTier3Weapon=True
     MeshRef="KF_Weapons_Trip.LAW_Trip"
     SkinRefs(0)="KF_Weapons_Trip_T.Supers.law_cmb"
     SkinRefs(1)="KF_Weapons_Trip_T.Supers.law_reddot_shdr"
     SkinRefs(2)="KF_Weapons_Trip_T.Supers.rocket_cmb"
     SelectSoundRef="KF_LAWSnd.LAW_Select"
     HudImageRef="KillingFloorHUD.WeaponSelect.LAW_unselected"
     SelectedHudImageRef="KillingFloorHUD.WeaponSelect.LAW"
     SelectAnimRate=0.500000
     PutDownAnimRate=2.000000
     PutDownTime=0.200000
     BringUpTime=0.200000
     PlayerIronSightFOV=90.000000
     ZoomTime=0.260000
     ZoomedDisplayFOV=65.000000
     FireModeClass(0)=Class'MutSR.LAWDFire'
    //  FireModeClass(1)=Class'KFMod.NoFire'
     PutDownAnim="PutDown"
     SelectForce="SwitchToRocketLauncher"
     AIRating=1.500000
     CurrentRating=1.500000
     bSniping=False
     Description="The Light Anti Tank Weapon is, as its name suggests, a military grade heavy weapons platform designed to disable or outright destroy armored vehicles."
     EffectOffset=(X=50.000000,Y=1.000000,Z=10.000000)
     DisplayFOV=75.000000
     Priority=195
     HudColor=(G=0)
     InventoryGroup=4
     GroupOffset=9
     PickupClass=Class'MutSR.LAWDPickup'
     PlayerViewOffset=(X=20.0,Y=15.0,Z=-17.000000)
     // PlayerViewOffset=(X=30.000000,Y=30.000000)
     BobDamping=7.000000
     AttachmentClass=Class'MutSR.LAWDAttachment'
     IconCoords=(X1=429,Y1=212,X2=508,Y2=251)
     ItemName="L.A.W"
     AmbientGlow=2
}
