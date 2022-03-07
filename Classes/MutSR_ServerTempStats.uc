// Because this is most likely going to fail on init, spawn the real stats actor here...
Class MutSR_ServerTempStats extends KFSteamStatsAndAchievements;

function PostBeginPlay()
{
	local KFPlayerController PlayerOwner;

	PlayerOwner = KFPlayerController(Owner);
	if( PlayerOwner.Player==None )
		return; // very bad...
	Spawn(Class'MutSR_ServerStStats',PlayerOwner);
}

defaultproperties
{
	bNetNotify=false
	bUsedCheats=true
	bFlushStatsToClient=false
	RemoteRole=ROLE_None
	LifeSpan=0.1
}
