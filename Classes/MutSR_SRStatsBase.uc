// Template class.
Class MutSR_SRStatsBase extends KFSteamStatsAndAchievements
	Abstract;

var MutSR_ClientPerkRepLink Rep;
var KFPlayerController PlayerOwner;
var bool bStatsReadyNow;

function int GetID();
function SetID( int ID );
function ChangeCharacter( string CN );
function ApplyCharacter( string CN );
function AddHeadshotKills(int Amount);
function AddStalkerKills(int Amount);

function ServerSelectPerkName( name N );
function ServerSelectPerk( Class<MutSR_SRVeterancyTypes> VetType );

function NotifyStatChanged();

defaultproperties
{
	bNetNotify=false
	bUsedCheats=true
	bFlushStatsToClient=false
	bInitialized=true
	RemoteRole=ROLE_None
}