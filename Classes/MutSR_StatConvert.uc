class MutSR_StatConvert extends Commandlet;

const MagicNumber="76561197960265728";
const MagicLength=12;

function int Main( string Parms )
{
	local array<string> List;
	local int i,j,z;
	local MutSR_StatsObject A,B;
	local string NewID;

	List = GetPerObjectNames("MutSR_ServerPerksStat","MutSR_StatsObject",9999999);
	for( i=0; i<List.Length; ++i )
	{
		if( !IsLinuxID(List[i]) )
		{
			Log("Skip "$List[i],'Log');
			continue;
		}
		NewID = ToWindowsID(List[i]);
		if( NewID=="" )
		{
			Log("Skip Unknown ID "$List[i],'Log');
			continue;
		}
		A = new(None,List[i]) Class'MutSR_StatsObject';
		B = new(None,NewID) Class'MutSR_StatsObject';
		Log("Port "$List[i]$" ("$A.PlayerName$") -> "$NewID$" ("$B.PlayerName$")",'Log');
		if( B.PlayerName=="" )
		{
			B.PlayerName = A.PlayerName;
			B.PlayerIP = A.PlayerIP;
			B.SelectedVeterancy = A.SelectedVeterancy;
			B.SelectedChar = A.SelectedChar;
		}
		B.DamageHealedStat+=A.DamageHealedStat;
		B.WeldingPointsStat+=A.WeldingPointsStat;
		B.ShotgunDamageStat+=A.ShotgunDamageStat;
		B.HeadshotKillsStat+=A.HeadshotKillsStat;
		B.StalkerKillsStat+=A.StalkerKillsStat;
		B.BullpupDamageStat+=A.BullpupDamageStat;
		B.MeleeDamageStat+=A.MeleeDamageStat;
		B.FlameThrowerDamageStat+=A.FlameThrowerDamageStat;
		B.SelfHealsStat+=A.SelfHealsStat;
		B.SoleSurvivorWavesStat+=A.SoleSurvivorWavesStat;
		B.CashDonatedStat+=A.CashDonatedStat;
		B.FeedingKillsStat+=A.FeedingKillsStat;
		B.BurningCrossbowKillsStat+=A.BurningCrossbowKillsStat;
		B.GibbedFleshpoundsStat+=A.GibbedFleshpoundsStat;
		B.StalkersKilledWithExplosivesStat+=A.StalkersKilledWithExplosivesStat;
		B.GibbedEnemiesStat+=A.GibbedEnemiesStat;
		B.BloatKillsStat+=A.BloatKillsStat;
		B.SirenKillsStat+=A.SirenKillsStat;
		B.KillsStat+=A.KillsStat;
		B.ExplosivesDamageStat+=A.ExplosivesDamageStat;
		B.TotalPlayTime+=A.TotalPlayTime;
		B.WinsCount+=A.WinsCount;
		B.LostsCount+=A.LostsCount;
		B.TotalZedTimeStat+=A.TotalZedTimeStat;
		// Merge custom stats.
		for( j=(A.CC.Length-1); j>=0; --j )
		{
			for( z=(B.CC.Length-1); z>=0; --z )
				if( B.CC[z].N==A.CC[j].N )
					break;
			if( z==-1 )
			{
				z = B.CC.Length;
				B.CC.Length = z+1;
				B.CC[z].N = A.CC[j].N;
				B.CC[z].V = A.CC[j].V;
			}
			else if( IsDigitStr(B.CC[z].V) && IsDigitStr(A.CC[j].V) )
				B.CC[z].V = string(int(B.CC[z].V) + int(A.CC[j].V));
			else B.CC[z].V = A.CC[j].V;
		}
		A.ClearConfig();
		B.SaveConfig();
	}
	return 0;
}
static final function bool IsLinuxID( string S )
{
	return (Len(S)<MagicLength);
}
static final function string ToWindowsID( string S )
{
	local int i,la,lb,rest,p;
	local string Result;
	
	la = Len(S);
	lb = Len(MagicNumber);
	for( i=1; i<=lb; ++i )
	{
		if( i<=la )
		{
			if( !IsDigit(Asc(Mid(S,la-i,1))) ) // Not a SteamID, something else here.
				return "";
			p = int(Mid(S,la-i,1));
		}
		else p = 0;
		p += rest + int(Mid(MagicNumber,lb-i,1));
		if( p>=10 )
		{
			rest = p/10;
			p -= rest*10;
		}
		else rest = 0;
		Result = string(p)$Result;
	}
	if( rest>0 )
		Result = string(rest)$Result;
	return Result;
}
static final function bool IsDigit( int S )
{
	return (S>=48 && S<=57);
}
static final function bool IsDigitStr( string S )
{
	return (string(int(S))==S);
}

defaultproperties
{
	HelpCmd="Convert MutSR_ServerPerks stats LinuxID to WindowsID."
	HelpWebLink="http://forums.tripwireinteractive.com/showthread.php?t=36065"
	HelpUsage="Run UCC.exe MutSR.MutSR_StatConvert /norunaway"
	IsServer=false
	IsClient=false
	IsEditor=true
}