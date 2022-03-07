class MutSR_SRPerkProgressList extends KFPerkProgressList;

function PerkChanged(KFSteamStatsAndAchievements KFStatsAndAchievements, int NewPerkIndex)
{
	local byte i,lvl;
	local int Numerator, Denominator;
	local float Progress;
	local MutSR_ClientPerkRepLink ST;

	// Update the ItemCount and select the first item
	ST = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
	lvl = ST.CachePerks[NewPerkIndex].CurrentLevel;
	ItemCount = ST.CachePerks[NewPerkIndex].PerkClass.Static.GetRequirementCount(ST,lvl);
	SetIndex(0);

	RequirementString.Remove(0, RequirementString.Length);
	RequirementProgressString.Remove(0, RequirementProgressString.Length);
	RequirementProgress.Remove(0, RequirementProgress.Length);
	for ( i = 0; i < ItemCount; i++ )
	{
		Progress = ST.CachePerks[NewPerkIndex].PerkClass.Static.GetPerkProgress(ST,lvl,i,Numerator,Denominator);

		RequirementString[RequirementString.Length] = Repl(ST.CachePerks[NewPerkIndex].PerkClass.Static.GetVetInfoText(lvl,2,i), "%x", AddCommas(Denominator));
		RequirementProgressString[RequirementProgressString.Length] = FormatNumber(Numerator)$"/"$FormatNumber(Denominator);
		RequirementProgress[RequirementProgress.Length] = Progress;
	}

	if ( MyScrollBar != none )
		MyScrollBar.AlignThumb();
}

defaultproperties
{
}
