class MutSR_KFPCServ extends KFPlayerController_Story;

var transient vector CamPos;
var transient rotator CamRot;
var transient Actor CamActor;
var bool bUseAdvBehindview;

replication
{
	reliable if( Role==ROLE_Authority )
		bUseAdvBehindview;
}

simulated function UpdateHintManagement(bool bUseHints)
{
	if( KF_StoryGRI(Level.GRI)!=None )
		Super.UpdateHintManagement(bUseHints);
	else Super(KFPlayerController).UpdateHintManagement(bUseHints);
}
exec function ThrowWeapon()
{
	if( KF_StoryGRI(Level.GRI)!=None )
		Super.ThrowWeapon();
	else Super(KFPlayerController).ThrowWeapon();
}

function rotator AdjustAim(FireProperties FiredAmmunition, vector projStart, int aimerror)
{
	local Actor Other;
	local float TraceRange;
	local vector HitLocation,HitNormal;

	if( Pawn==None || !bBehindview || !bUseAdvBehindview || Vehicle(Pawn)!=None )
		return Super.AdjustAim(FiredAmmunition,projStart,aimerror);
	if ( FiredAmmunition.bInstantHit )
		TraceRange = 10000.f;
	else TraceRange = 4000.f;

	PlayerCalcView(CamActor,CamPos,CamRot);
	foreach Pawn.TraceActors(Class'Actor',Other,HitLocation,HitNormal,CamPos+TraceRange*vector(CamRot),CamPos)
	{
		if( Other!=Pawn && (Other==Level || Other.bBlockActors || Other.bProjTarget || Other.bWorldGeometry)
		 && KFPawn(Other)==None && KFBulletWhipAttachment(Other)==None )
			break;
	}
	if( FiredAmmunition.bInstantHit && Other!=None )
		InstantWarnTarget(Other,FiredAmmunition,vector(Rotation));
	if( Other!=None )
		return rotator(HitLocation-projStart);
	return Rotation;
}
simulated function rotator GetViewRotation()
{
    if( (bBehindView && !bUseAdvBehindview && Pawn!=None) || (bBehindView && Vehicle(Pawn)!=None) )
        return Pawn.Rotation;
    return Rotation;
}
simulated final function bool GetShoulderCam( out vector Pos, Pawn Other )
{
	local vector HL,HN;

	if( Vehicle(Other)!=None )
		return false;
	Pos = Other.Location + Other.EyePosition();
	CamPos = vect(-40,20,10) >> Rotation;
	
	if( Pawn.Trace(HL,HN,Pos+Normal(CamPos)*(VSize(CamPos)+10.f),Pos,false)!=None )
		Pos = Pos+Normal(CamPos)*(VSize(HL-Pos)-10.f);
	else Pos += CamPos;

	return true;
}
event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
    local Pawn PTarget;

	if( Base!=None )
		SetBase(None); // This error may happen on client, causing major desync.

	if ( LastPlayerCalcView == Level.TimeSeconds && CalcViewActor != None && CalcViewActor.Location == CalcViewActorLocation )
	{
		ViewActor	= CalcViewActor;
		CameraLocation	= CalcViewLocation;
		CameraRotation	= CalcViewRotation;
		return;
	}

	// If desired, call the pawn's own special callview
	if( Pawn != None && Pawn.bSpecialCalcView && (ViewTarget == Pawn) )
	{
		// try the 'special' calcview. This may return false if its not applicable, and we do the usual.
		if ( Pawn.SpecialCalcView(ViewActor, CameraLocation, CameraRotation) )
		{
			CacheCalcView(ViewActor,CameraLocation,CameraRotation);
			return;
		}
	}

    if ( (ViewTarget == None) || ViewTarget.bDeleteMe )
    {
		if ( (Pawn != None) && !Pawn.bDeleteMe )
			SetViewTarget(Pawn);
		else if ( RealViewTarget != None )
			SetViewTarget(RealViewTarget);
		else
			SetViewTarget(self);
    }

    ViewActor = ViewTarget;
    CameraLocation = ViewTarget.Location;

	if ( ViewTarget == Pawn )
	{
		if( bBehindView ) // up and behind
		{
			if( !bUseAdvBehindview || !GetShoulderCam(CameraLocation,Pawn) )
				CalcBehindView(CameraLocation, CameraRotation, CameraDist * Pawn.Default.CollisionRadius);
			else CameraRotation = Rotation;
		}
		else CalcFirstPersonView( CameraLocation, CameraRotation );

		CacheCalcView(ViewActor,CameraLocation,CameraRotation);
        return;
    }
	if ( ViewTarget == self )
	{
		CameraRotation = Rotation;
		CacheCalcView(ViewActor,CameraLocation,CameraRotation);
		return;
	}

    if ( ViewTarget.IsA('Projectile') )
    {
        if ( Projectile(ViewTarget).bSpecialCalcView && Projectile(ViewTarget).SpecialCalcView(ViewActor, CameraLocation, CameraRotation, bBehindView) )
        {
            CacheCalcView(ViewActor,CameraLocation,CameraRotation);
            return;
        }

        if ( !bBehindView )
        {
            CameraLocation += (ViewTarget.CollisionHeight) * vect(0,0,1);
            CameraRotation = Rotation;

    		CacheCalcView(ViewActor,CameraLocation,CameraRotation);
            return;
        }
    }

    CameraRotation = ViewTarget.Rotation;
    PTarget = Pawn(ViewTarget);
    if ( PTarget != None )
    {
        if ( (Level.NetMode == NM_Client) || (bDemoOwner && (Level.NetMode != NM_Standalone)) )
        {
            PTarget.SetViewRotation(TargetViewRotation);
            CameraRotation = BlendedTargetViewRotation;

            PTarget.EyeHeight = TargetEyeHeight;
        }
        else if ( PTarget.IsPlayerPawn() )
            CameraRotation = PTarget.GetViewRotation();

		if (PTarget.bSpecialCalcView && PTarget.SpectatorSpecialCalcView(self, ViewActor, CameraLocation, CameraRotation))
		{
			CacheCalcView(ViewActor, CameraLocation, CameraRotation);
			return;
		}

        if ( !bBehindView )
            CameraLocation += PTarget.EyePosition();
    }
    if ( bBehindView )
    {
        CameraLocation = CameraLocation + (ViewTarget.Default.CollisionHeight - ViewTarget.CollisionHeight) * vect(0,0,1);
        CalcBehindView(CameraLocation, CameraRotation, CameraDist * ViewTarget.Default.CollisionRadius);
    }

	CacheCalcView(ViewActor,CameraLocation,CameraRotation);
}

exec function ChangeCharacter(string newCharacter, optional string inClass)
{
	local MutSR_ClientPerkRepLink S;

	S = Class'MutSR_ClientPerkRepLink'.Static.FindStats(Self);
	if( S!=None )
		S.SelectedCharacter(newCharacter);
	else Super.ChangeCharacter(newCharacter,inClass);
}

function SetPawnClass(string inClass, string inCharacter)
{
	if( MutSR_SRStatsBase(SteamStatsAndAchievements)!=none )
		MutSR_SRStatsBase(SteamStatsAndAchievements).ChangeCharacter(inCharacter);
	else
	{
		PawnSetupRecord = class'xUtil'.static.FindPlayerRecord(inCharacter);
		PlayerReplicationInfo.SetCharacterName(inCharacter);
	}
}
function SendSelectedVeterancyToServer(optional bool bForceChange)
{
	if( Level.NetMode!=NM_Client && MutSR_SRStatsBase(SteamStatsAndAchievements)!=none )
		MutSR_SRStatsBase(SteamStatsAndAchievements).WaveEnded();
}
function SelectVeterancy(class<KFVeterancyTypes> VetSkill, optional bool bForceChange)
{
	if( MutSR_SRStatsBase(SteamStatsAndAchievements)!=none )
		MutSR_SRStatsBase(SteamStatsAndAchievements).ServerSelectPerk(Class<MutSR_SRVeterancyTypes>(VetSkill));
}

// Allow clients fix the behindview bug themself
exec function BehindView( Bool B )
{
	if ( Vehicle(Pawn)==None || Vehicle(Pawn).bAllowViewChange ) // Allow vehicles to limit view changes
	{
		ClientSetBehindView(B);
		bBehindView = B;
	}
}
exec function ToggleBehindView()
{
	ServerToggleBehindview();
}
function ServerToggleBehindview()
{
	local bool B;

	if( Vehicle(Pawn)==None || Vehicle(Pawn).bAllowViewChange )
	{
		B = !bBehindView;
		ClientSetBehindView(B);
		bBehindView = B;
	}
}

function ShowBuyMenu(string wlTag,float maxweight)
{
	StopForceFeedback();
	ClientOpenMenu(string(Class'MutSR_SRGUIBuyMenu'),,wlTag,string(maxweight));
}

// Fix for vehicle mod crashes.
simulated function postfxon(int i)
{
	if( Viewport(Player)!=None )
		Super.postfxon(i);
}
simulated function postfxoff(int i)
{
	if( Viewport(Player)!=None )
		Super.postfxoff(i);
}
simulated function postfxblur(float f)
{
	if( Viewport(Player)!=None )
		Super.postfxblur(f);
}
simulated function postfxbw(float f, optional bool bDoNotTurnOffFadeFromBlackEffect)
{
	if( Viewport(Player)!=None )
		Super.postfxbw(f,bDoNotTurnOffFadeFromBlackEffect);
}

// Hide weapon highlight when using this shortcut key.
exec function SwitchWeapon(byte F)
{
	local Weapon W;

	if ( Pawn!=None )
	{
		W = Pawn.PendingWeapon;
		Pawn.SwitchWeapon(F);
		if( W!=Pawn.PendingWeapon && HudKillingFloor(MyHUD)!=None )
		{
			HudKillingFloor(MyHUD).SelectedInventory = Pawn.PendingWeapon;
			HudKillingFloor(MyHUD).HideInventory();
		}
	}
}

// Poosh's preloading code fix.===================================
simulated function PreloadFireModeAssets(class<WeaponFire> WF)
{
	local class<Projectile> P;

	if ( WF == none || WF == Class'KFMod.NoFire' ) 
		return;

	if ( class<KFFire>(WF) != none && class<KFFire>(WF).default.FireSoundRef != "" )
		class<KFFire>(WF).static.PreloadAssets(Level);
	else if ( class<KFMeleeFire>(WF) != none && class<KFMeleeFire>(WF).default.FireSoundRef != "" )
		class<KFMeleeFire>(WF).static.PreloadAssets();
	else if ( class<KFShotgunFire>(WF) != none && class<KFShotgunFire>(WF).default.FireSoundRef != "" )
		class<KFShotgunFire>(WF).static.PreloadAssets(Level);

	// preload projectile assets
	P = WF.default.ProjectileClass;
	//log("Projectile =" @ P, default.class.outer.name);
	if ( P == none )
		return;
        
	if ( class<CrossbuzzsawBlade>(P) != none )
		class<CrossbuzzsawBlade>(P).static.PreloadAssets();
	else if ( class<LAWProj>(P) != none && class<LAWProj>(P).default.StaticMeshRef != "" )
		class<LAWProj>(P).static.PreloadAssets();
	else if ( class<M79GrenadeProjectile>(P) != none && class<M79GrenadeProjectile>(P).default.StaticMeshRef != "" )
		class<M79GrenadeProjectile>(P).static.PreloadAssets();
	else if ( class<SPGrenadeProjectile>(P) != none && class<SPGrenadeProjectile>(P).default.StaticMeshRef != "" )
		class<SPGrenadeProjectile>(P).static.PreloadAssets();
	else if ( class<HealingProjectile>(P) != none && class<HealingProjectile>(P).default.StaticMeshRef != "" )
		class<HealingProjectile>(P).static.PreloadAssets();
	else if ( class<CrossbowArrow>(P) != none && class<CrossbowArrow>(P).default.MeshRef != "" )
		class<CrossbowArrow>(P).static.PreloadAssets();
	else if ( class<M99Bullet>(P) != none )
		class<M99Bullet>(P).static.PreloadAssets();
	else if ( class<PipeBombProjectile>(P) != none && class<PipeBombProjectile>(P).default.StaticMeshRef != "" )
		class<PipeBombProjectile>(P).static.PreloadAssets();
	// More DLC
	else if ( class<SealSquealProjectile>(P) != none && class<SealSquealProjectile>(P).default.StaticMeshRef != "" )
		class<SealSquealProjectile>(P).static.PreloadAssets();
}

simulated final function UnloadFireModeAssets(class<WeaponFire> WF)
{
	local class<Projectile> P;

	if ( WF==none || WF==Class'KFMod.NoFire' ) 
		return;

	if ( class<KFFire>(WF) != none && class<KFFire>(WF).default.FireSoundRef != "" )
		class<KFFire>(WF).static.UnloadAssets();
	else if ( class<KFMeleeFire>(WF) != none && class<KFMeleeFire>(WF).default.FireSoundRef != "" )
		class<KFMeleeFire>(WF).static.UnloadAssets();
	else if ( class<KFShotgunFire>(WF) != none && class<KFShotgunFire>(WF).default.FireSoundRef != "" )
		class<KFShotgunFire>(WF).static.UnloadAssets();

	// Unload projectile assets only if refs aren't empty (i.e. they have been dynamically loaded)
	P = WF.default.ProjectileClass;
	if ( P == none || P.default.StaticMesh != none )
		return;

	if ( class<CrossbuzzsawBlade>(P) != none )
		class<CrossbuzzsawBlade>(P).static.UnloadAssets();
	else if ( class<LAWProj>(P) != none && class<LAWProj>(P).default.StaticMeshRef != "" )
		class<LAWProj>(P).static.UnloadAssets();
	else if ( class<M79GrenadeProjectile>(P) != none && class<M79GrenadeProjectile>(P).default.StaticMeshRef != "" )
		class<M79GrenadeProjectile>(P).static.UnloadAssets();
	else if ( class<SPGrenadeProjectile>(P) != none && class<SPGrenadeProjectile>(P).default.StaticMeshRef != "" )
		class<SPGrenadeProjectile>(P).static.UnloadAssets();
	else if ( class<HealingProjectile>(P) != none && class<HealingProjectile>(P).default.StaticMeshRef != "" )
		class<HealingProjectile>(P).static.UnloadAssets();
	else if ( class<CrossbowArrow>(P) != none && class<CrossbowArrow>(P).default.MeshRef != "" )
		class<CrossbowArrow>(P).static.UnloadAssets();
	else if ( class<M99Bullet>(P) != none )
		class<M99Bullet>(P).static.UnloadAssets();
	else if ( class<PipeBombProjectile>(P) != none && class<PipeBombProjectile>(P).default.StaticMeshRef != "" )
		class<PipeBombProjectile>(P).static.UnloadAssets();
	// More DLC
	else if ( class<SealSquealProjectile>(P) != none && class<SealSquealProjectile>(P).default.StaticMeshRef != "" )
		class<SealSquealProjectile>(P).static.UnloadAssets();
}

simulated function ClientWeaponSpawned(class<Weapon> WClass, Inventory Inv)
{
	local class<KFWeapon> W;
	local class<KFWeaponAttachment> Att;

	// log("ScrnPlayerController.ClientWeaponSpawned()" @ WClass $ ". Default Mesh = " $ WClass.default.Mesh, default.class.outer.name);
	// super.ClientWeaponSpawned(WClass, Inv);

	W = class<KFWeapon>(WClass);
	// preload assets only for weapons that have no static ones
	// damned Tripwire's code doesn't bother for cheking is there ref set or not!
	if ( W != none)
	{
		// preload weapon assets
		if ( W.default.Mesh == none )
			W.static.PreloadAssets(Inv);
		Att = class<KFWeaponAttachment>(W.default.AttachmentClass);
		// 2013/01/22 EDIT: bug fix 
		if ( Att != none && Att.default.Mesh == none )
		{
			if ( Inv != none )
				Att.static.PreloadAssets(KFWeaponAttachment(Inv.ThirdPersonActor));    
			else
				Att.static.PreloadAssets();
		}
		PreloadFireModeAssets(W.default.FireModeClass[0]);
		PreloadFireModeAssets(W.default.FireModeClass[1]);
	}
}

simulated function ClientWeaponDestroyed(class<Weapon> WClass)
{
	local class<KFWeapon> W;
	local class<KFWeaponAttachment> Att;

	// log(default.class @ "ClientWeaponDestroyed()" @ WClass, default.class.outer.name);
	// super.ClientWeaponDestroyed(WClass); 

	W = class<KFWeapon>(WClass);
	// if default mesh is set, then count that weapon has static assets, so don't unload them
	// that's lame, but not so lame as Tripwire's original code
	if ( W != none && W.default.MeshRef != "" && W.static.UnloadAssets() )
	{
		Att = class<KFWeaponAttachment>(W.default.AttachmentClass);
		if ( Att != none && Att.default.Mesh == none )
			Att.static.UnloadAssets();
		UnloadFireModeAssets(W.default.FireModeClass[0]);
		UnloadFireModeAssets(W.default.FireModeClass[1]);
	}
}

defaultproperties
{
	LobbyMenuClassString="MutSR.MutSR_SRLobbyMenu"
	PawnClass=Class'MutSR.MutSR_SRHumanPawn'
}