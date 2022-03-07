Class MutSR_SRSteamStatsGet extends KFSteamStatsAndAchievements
	transient;

var MutSR_ClientPerkRepLink Link;
var bool bNoInit;

simulated event PostBeginPlay()
{
	if( bNoInit )
		return;
	PCOwner = Level.GetLocalPlayerController();
	Initialize(PCOwner);
	GetStatsAndAchievements();
}
simulated event PostNetBeginPlay();

simulated event OnStatsAndAchievementsReady()
{
	local int i,d;

	InitStatInt(OwnedWeaponDLC, GetOwnedWeaponDLC());
	for( i=(Link.ShopInventory.Length-1); i>=0; --i )
		if( Link.ShopInventory[i].bDLCLocked!=0 )
		{
			d = class<KFWeapon>(Link.ShopInventory[i].PC.Default.InventoryType).Default.AppID;
			if( d!=0 )
			{
				if( PlayerOwnsWeaponDLC(d) )
					Link.ShopInventory[i].bDLCLocked = 0;
				else if( class<KFWeapon>(Link.ShopInventory[i].PC.Default.InventoryType).Default.UnlockedByAchievement!=-1 )
					Link.ShopInventory[i].bDLCLocked = 0; // Special hack for dwarf axe.
				else Link.ShopInventory[i].bDLCLocked = 1;
				continue;
			}
			d = class<KFWeapon>(Link.ShopInventory[i].PC.Default.InventoryType).Default.UnlockedByAchievement;
			if( Achievements[d].bCompleted==1 )
				Link.ShopInventory[i].bDLCLocked = 0;
			else Link.ShopInventory[i].bDLCLocked = 0;
		}
	for ( i = 0; i < Achievements.Length; i++ )
		GetAchievementDescription(Achievements[i].SteamName, Default.Achievements[i].DisplayName, Default.Achievements[i].Description);
	Destroy();
}

defaultproperties
{
	RemoteRole=ROLE_None
	LifeSpan=10
}