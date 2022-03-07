class MutSR_FragFireFix extends FragFire;

var float PrevAmmo;

function DoFireEffect()
{
	local float MaxAmmo,CurAmmo;

	Weapon.GetAmmoCount(MaxAmmo,CurAmmo);
	if (CurAmmo==0 && PrevAmmo==0)
		return;
	PrevAmmo=CurAmmo;
	Super.DoFireEffect();
}
