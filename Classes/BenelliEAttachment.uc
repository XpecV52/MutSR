//=============================================================================
// BenelliAttachment
//=============================================================================
// Benelli M4 Shotgun third person attachment class
//=============================================================================
// Killing Floor Source
// Copyright (C) 2011 Tripwire Interactive LLC
// - John "Ramm-Jaeger" Gibson
//=============================================================================

class BenelliEAttachment extends KFWeaponAttachment;

defaultproperties
{
     mMuzFlashClass=Class'ROEffects.MuzzleFlash3rdKar'
     mShellCaseEmitterClass=Class'KFMod.KFShotgunShellSpewer'
     MovementAnims(0)="JogF_Shotgun"
     MovementAnims(1)="JogB_Shotgun"
     MovementAnims(2)="JogL_Shotgun"
     MovementAnims(3)="JogR_Shotgun"
     TurnLeftAnim="TurnL_Shotgun"
     TurnRightAnim="TurnR_Shotgun"
     CrouchAnims(0)="CHwalkF_Shotgun"
     CrouchAnims(1)="CHwalkB_Shotgun"
     CrouchAnims(2)="CHwalkL_Shotgun"
     CrouchAnims(3)="CHwalkR_Shotgun"
     WalkAnims(0)="WalkF_Shotgun"
     WalkAnims(1)="WalkB_Shotgun"
     WalkAnims(2)="WalkL_Shotgun"
     WalkAnims(3)="WalkR_Shotgun"
     CrouchTurnRightAnim="CH_TurnR_Shotgun"
     CrouchTurnLeftAnim="CH_TurnL_Shotgun"
     IdleCrouchAnim="CHIdle_Shotgun"
     IdleWeaponAnim="Idle_Shotgun"
     IdleRestAnim="Idle_Shotgun"
     IdleChatAnim="Idle_Shotgun"
     IdleHeavyAnim="Idle_Shotgun"
     IdleRifleAnim="Idle_Shotgun"
     FireAnims(0)="Fire_Benelli"
     FireAnims(1)="Fire_Benelli"
     FireAnims(2)="Fire_Benelli"
     FireAnims(3)="Fire_Benelli"
     FireAltAnims(0)="Fire_Benelli"
     FireAltAnims(1)="Fire_Benelli"
     FireAltAnims(2)="Fire_Benelli"
     FireAltAnims(3)="Fire_Benelli"
     FireCrouchAnims(0)="CHFire_Benelli"
     FireCrouchAnims(1)="CHFire_Benelli"
     FireCrouchAnims(2)="CHFire_Benelli"
     FireCrouchAnims(3)="CHFire_Benelli"
     FireCrouchAltAnims(0)="CHFire_Benelli"
     FireCrouchAltAnims(1)="CHFire_Benelli"
     FireCrouchAltAnims(2)="CHFire_Benelli"
     FireCrouchAltAnims(3)="CHFire_Benelli"
     HitAnims(0)="HitF_Shotgun"
     HitAnims(1)="HitB_Shotgun"
     HitAnims(2)="HitL_Shotgun"
     HitAnims(3)="HitR_Shotgun"
     PostFireBlendStandAnim="Blend_Shotgun"
     PostFireBlendCrouchAnim="CHBlend_Shotgun"
     MeshRef="KF_Weapons3rd3_Trip.Benelli_3rd"
}
