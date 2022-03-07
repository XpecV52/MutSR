// subclassing ROBallisticProjectile so we can do the ambient volume scaling
class LAWDProj extends LAWProj;

defaultproperties
{
     ImpactDamageType=Class'MutSR.DamTypeLawDRocketImpact'
     MyDamageType=Class'MutSR.DamTypeLAWD'
	Damage=1050 // Changed in Balance Round 4
	DamageRadius=675 // Changed in Balance Round 4
}
