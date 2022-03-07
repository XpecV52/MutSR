Class MutSR_SRCustomProgressInt extends MutSR_SRCustomProgress
	Abstract;

var int CurrentValue;

replication
{
	reliable if( Role==ROLE_Authority && bNetOwner )
		CurrentValue;
}

simulated function string GetProgress()
{
	return string(CurrentValue);
}

simulated function int GetProgressInt()
{
	return CurrentValue;
}

function SetProgress( string S )
{
	CurrentValue = int(S);
}

function IncrementProgress( int Count )
{
	CurrentValue+=Count;
	ValueUpdated();
}

defaultproperties
{
}