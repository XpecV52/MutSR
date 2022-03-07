//=============================================================================
// DwarfAxeZFireB
//=============================================================================
// Dwarf AxeZ secondary fire class
//=============================================================================
// Killing Floor Source
// Copyright (C) 2011 Tripwire Interactive LLC
// - John "Ramm-Jaeger" Gibson
//=============================================================================
// class DwarfAxeZFire extends DwarfAxeFire;
class DwarfAxeZFire extends KFMeleeFire;

var float MomentumTransfer;
var() InterpCurve AppliedMomentumCurve;
var Vector HeadLoc;


simulated event ModeDoFire()
{
    local float Rec;

    Rec = GetFireSpeed();
    SetTimer(DamagedelayMin / Rec, false);
    FireRate = default.FireRate / Rec;
    FireAnimRate = default.FireAnimRate * Rec;
    ReloadAnimRate = default.ReloadAnimRate * Rec;
    if(MaxHoldTime > 0.0)
    {
        HoldTime = FMin(HoldTime, MaxHoldTime);
    }
    if(Weapon.Role == ROLE_Authority)
    {
        DoFireEffect();
        HoldTime = 0.0;
        if((Instigator == none) || Instigator.Controller == none)
        {
            return;
        }
        if(AIController(Instigator.Controller) != none)
        {
            AIController(Instigator.Controller).WeaponFireAgain(BotRefireRate, true);
        }
        Instigator.DeactivateSpawnProtection();
    }
    if(Instigator.IsLocallyControlled())
    {
        PlayFiring();
        FlashMuzzleFlash();
        StartMuzzleSmoke();
        ClientPlayForceFeedback(FireForce);
    }
    else
    {
        ServerPlayFiring();
    }
    Weapon.IncrementFlashCount(ThisModeNum);
    if(bFireOnRelease)
    {
        if(bIsFiring)
        {
            NextFireTime += (MaxHoldTime + FireRate);
        }
        else
        {
            NextFireTime = Level.TimeSeconds + FireRate;
        }
    }
    else
    {
        NextFireTime += FireRate;
        NextFireTime = FMax(NextFireTime, Level.TimeSeconds);
    }
    HoldTime = 0.0;
    if((Instigator.PendingWeapon != Weapon) && Instigator.PendingWeapon != none)
    {
        bIsFiring = false;
        Weapon.PutDown();
    }
    if((Weapon.Owner != none) && Weapon.Owner.Physics != PHYS_Falling)
    {
        Weapon.Owner.Velocity.X *= KFMeleeGun(Weapon).ChopSlowRate;
        Weapon.Owner.Velocity.Y *= KFMeleeGun(Weapon).ChopSlowRate;
    }
}

simulated function Timer()
{
	local Actor HitActor;
	local Vector StartTrace, EndTrace, HitLocation, HitNormal;
	local Rotator PointRot;
	local int MyDamage;
	local bool bBackStabbed;
	local Pawn Victims;
	local Vector Dir;
    local float VictimDist, AppliedMomentum;
    // local Vector PushForceVar;
    local float PushForce;
    local Vector PushAdd, Momentum;
	// local float DiffAngle, VictimDist;
	// local float AppliedMomentum;

    PushForce = 1000.0;
    PushAdd = vect(0.0, 0.0, 250.0);
	MyDamage = MeleeDamage;
	if( !KFWeapon(Weapon).bNoHit )
	{
		MyDamage = MeleeDamage;
		StartTrace = Instigator.Location + Instigator.EyePosition();

		if( Instigator.Controller!=None && PlayerController(Instigator.Controller)==None && Instigator.Controller.Enemy!=None )
		{
        	PointRot = rotator(Instigator.Controller.Enemy.Location-StartTrace); // Give aimbot for bots.
        }
		else
        {
            PointRot = Instigator.GetViewRotation();
        }

		EndTrace = StartTrace + vector(PointRot)*weaponRange;
		HitActor = Instigator.Trace( HitLocation, HitNormal, EndTrace, StartTrace, true);

		if (HitActor!=None)
		{
			ImpactShakeView();

			if( HitActor.IsA('ExtendedZCollision') && HitActor.Base != none &&
                HitActor.Base.IsA('KFMonster') )
            {
                HitActor = HitActor.Base;
            }

			if ( (HitActor.IsA('KFMonster') || HitActor.IsA('KFHumanPawn')) && KFMeleeGun(Weapon).BloodyMaterial!=none )
			{
				Weapon.Skins[KFMeleeGun(Weapon).BloodSkinSwitchArray] = KFMeleeGun(Weapon).BloodyMaterial;
				Weapon.texture = Weapon.default.Texture;
			}
			if( Level.NetMode==NM_Client )
            {
                Return;
            }

			if( HitActor.IsA('Pawn') && !HitActor.IsA('Vehicle')
			 && (Normal(HitActor.Location-Instigator.Location) dot vector(HitActor.Rotation))>0 ) // Fixed in Balance Round 2
			{
				bBackStabbed = true;
				MyDamage *= 2; // Backstab >:P
			}
			if(KFMonster(HitActor) != none)
			{
				KFMonster(HitActor).bBackstabbed = bBackStabbed;
				HeadLoc = KFMonster(HitActor).GetBoneCoords(KFMonster(HitActor).HeadBone).Origin + ((KFMonster(HitActor).HeadHeight * KFMonster(HitActor).HeadScale) * KFMonster(HitActor).GetBoneCoords(KFMonster(HitActor).HeadBone).XAxis);
                HeadLoc.Z += float(80);
                // Spawn(class'EfRasho', Owner,, HeadLoc);
                HeadLoc.Z -= float(90);
                // Spawn(class'EfRashoB', Owner,, HeadLoc);
                HitActor.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass);
                Weapon.PlaySound(MeleeHitSounds[Rand(MeleeHitSounds.length)], SLOT_None, MeleeHitVolume,,,, false);
                Weapon.ConsumeAmmo(ThisModeNum, 1.0);
                Dir = Normal((HitActor.Location + KFMonster(HitActor).EyePosition()) - Instigator.Location);
                AppliedMomentum = InterpCurveEval(AppliedMomentumCurve,HitActor.Mass);
				Momentum = (Dir * AppliedMomentum) / float(300);
                KFMonster(HitActor).AddVelocity(Momentum);
                HitActor.TakeDamage(MyDamage, Instigator, HitLocation, Dir * AppliedMomentum, hitDamageClass) ;

                // Break thier grapple if you are knocking them back!
                if( KFMonster(HitActor) != none )
                {
                    KFMonster(HitActor).BreakGrapple();
                }

            	if(MeleeHitSounds.Length > 0)
            	{
            		Weapon.PlaySound(MeleeHitSounds[Rand(MeleeHitSounds.length)],SLOT_None,MeleeHitVolume,,,,false);
            	}

				if(VSize(Instigator.Velocity) > 300 && KFMonster(HitActor).Mass <= Instigator.Mass)
				{
				    KFMonster(HitActor).FlipOver();
				}

			}
			else
			{
				HitActor.TakeDamage(MyDamage, Instigator, HitLocation, Normal(vector(PointRot)) * MomentumTransfer, hitDamageClass) ;
				Spawn(HitEffectClass,,, HitLocation, rotator(HitLocation - StartTrace));
				//if( KFWeaponAttachment(Weapon.ThirdPersonActor)!=None )
		        //  KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(HitActor,HitLocation,HitNormal);

		        //Weapon.IncrementFlashCount(ThisModeNum);
			}
			// Spawn(class'KF2HeliosRiflePush',,, HitLocation, PointRot); // Flame
		}

		if( WideDamageMinHitAngle > 0 )
		{
            if(HitActor == none)
            {
                return;
            }
    		foreach Weapon.VisibleCollidingActors( class 'Pawn', Victims, (weaponRange * 2), StartTrace ) //, RadiusHitLocation
    		{
                if( (HitActor != none && Victims == HitActor) || Victims.Health <= 0 )
                {
                    continue;
                }

            	if( Victims != Instigator )
    			{
    				VictimDist = VSizeSquared(Instigator.Location - Victims.Location);

                    //log("VictimDist = "$VictimDist$" Weaponrange = "$(weaponRange*Weaponrange));

                    if( VictimDist > (((weaponRange * 1.2) * (weaponRange * 1.2)) + (Victims.CollisionRadius * Victims.CollisionRadius)) )
                    {
                        continue;
                    }

    	  			// lookdir = Normal(Vector(Instigator.GetViewRotation()));
    				// dir = Normal(Victims.Location - Instigator.Location);

    	           	// DiffAngle = lookdir dot dir;

    	           	// dir = Normal((Victims.Location + Victims.EyePosition()) - Instigator.Location);

    	           	// if( DiffAngle > WideDamageMinHitAngle )
    	           	// {
                    //     AppliedMomentum = InterpCurveEval(AppliedMomentumCurve,Victims.Mass);

    	           	// 	Victims.TakeDamage(MyDamage*DiffAngle, Instigator, (Victims.Location + Victims.CollisionHeight * vect(0,0,0.7)), dir * AppliedMomentum, hitDamageClass) ;

                    //     // Break thier grapple if you are knocking them back!
                    //     if( KFMonster(Victims) != none )
                    //     {
                    //         KFMonster(Victims).BreakGrapple();
                    //     }
					
                    Victims.TakeDamage(MyDamage, Instigator, Victims.Location + (Victims.CollisionHeight * vect(0.0, 0.0, 0.70)), vector(PointRot), hitDamageClass);
                    if(KFMonster(Victims) != none)
                    {
                        KFMonster(Victims).BreakGrapple();
                        Victims.TakeDamage(MyDamage / 2, Instigator, HitLocation, Dir * AppliedMomentum, hitDamageClass/* class'DamTypeZEDGunMKII' */);
                        // KFMonster(Victims).SetZapped(3.0, Instigator);
                        Dir = Normal((Victims.Location + KFMonster(Victims).EyePosition()) - Instigator.Location);
                        AppliedMomentum = InterpCurveEval(AppliedMomentumCurve, Victims.Mass);
                        Momentum = (Dir * AppliedMomentum) / float(300);
                        KFMonster(Victims).AddVelocity(Momentum);
                    }

                    if(MeleeHitSounds.Length > 0)
                    {
                        Victims.PlaySound(MeleeHitSounds[Rand(MeleeHitSounds.length)],SLOT_None,MeleeHitVolume,,,,false);
                    }
                }
            }
        }
    }
}


defaultproperties
{
     MeleeDamage=238
     ProxySize=0.150000
     weaponRange=100.000000
     hitDamageClass=Class'MutSR.DamTypeDwarfAxeZ'
     FireRate=1.350000
     DamagedelayMin=0.79
     DamagedelayMax=0.79
     BotRefireRate=1.00000
     MeleeHitSounds(0)=Sound'KF_AxeSnd.Axe_HitFlesh'
     HitEffectClass=class'AxeHitEffect'
     WideDamageMinHitAngle=0.6
	 MomentumTransfer=800000
     AppliedMomentumCurve=(Points=((OutVal=10000.000000),(InVal=350.000000,OutVal=175000.000000),(InVal=600.000000,OutVal=250000.000000)))     
}
