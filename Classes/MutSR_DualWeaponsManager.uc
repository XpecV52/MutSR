// Just a helper class to help manage dual wield weapons.
class MutSR_DualWeaponsManager extends Object
	abstract;

struct FDualList
{
	var class<KFWeapon> Single,Dual;
};
var array<FDualList> DualMap;

static final function bool IsDualWeapon( class<Weapon> W, optional out class<KFWeapon> SingleType )
{
	local int i;
	
	if( W.Default.DemoReplacement!=None )
	{
		SingleType = class<KFWeapon>(W.Default.DemoReplacement);
		return true;
	}
	for( i=(Default.DualMap.Length-1); i>=0; --i )
		if( W==Default.DualMap[i].Dual )
		{
			SingleType = Default.DualMap[i].Single;
			return true;
		}
	return false;
}

static final function bool HasDualies( class<Weapon> W, Inventory InvList, optional out class<KFWeapon> DualType )
{
	local int i;
	local Inventory In;
	
	for ( In=InvList; In!=None; In=In.Inventory )
		if( Weapon(In)!=None && Weapon(In).DemoReplacement==W )
		{
			DualType = class<KFWeapon>(In.Class);
			return true;
		}

	for( i=(Default.DualMap.Length-1); i>=0; --i )
		if( W==Default.DualMap[i].Single )
		{
			DualType = Default.DualMap[i].Dual;
			W = Default.DualMap[i].Dual;
			for ( In=InvList; In!=None; In=In.Inventory )
				if( In.Class==W )
					return true;
			return false;
		}
	return false;
}

defaultproperties
{
	DualMap(0)=(Single=Class'Single',Dual=Class'Dualies')
	DualMap(1)=(Single=Class'Magnum44Pistol',Dual=Class'Dual44Magnum')
	DualMap(2)=(Single=Class'Deagle',Dual=Class'DualDeagle')
	DualMap(3)=(Single=Class'FlareRevolver',Dual=Class'DualFlareRevolver')
	DualMap(4)=(Single=Class'MK23Pistol',Dual=Class'DualMK23Pistol')
	DualMap(5)=(Single=Class'GoldenDeagle',Dual=Class'GoldenDualDeagle')
}