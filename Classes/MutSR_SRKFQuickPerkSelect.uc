//=============================================================================
// Quick Perk Select Menu for the trader
//=============================================================================
class MutSR_SRKFQuickPerkSelect extends KFQuickPerkSelect;

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local MutSR_ClientPerkRepLink S;

	Super(GUIMultiComponent).InitComponent(MyController, MyOwner);

	if ( PlayerOwner() != none )
	{
		S = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
		if ( S!=none )
			CheckPerksX(S);
	}
}
function bool MyOnDraw(Canvas C)
{                                                                                                         
	local int i, j;
	local MutSR_ClientPerkRepLink S;
	local Material M,SM;

	super(GUIMultiComponent).OnDraw(C);
	
	C.SetDrawColor(255, 255, 255, 255);
	
	// make em square
	if ( !bResized )
	{
		ResizeIcons(C);
	}	
		
	// Current perk background
	C.SetPos(WinLeft * C.ClipX , WinTop * C.ClipY);
	C.DrawTileScaled(CurPerkBack, (WinHeight * C.ClipY) / CurPerkBack.USize, (WinHeight * C.ClipY) / CurPerkBack.USize);

	S = Class'MutSR_ClientPerkRepLink'.Static.FindStats(C.Viewport.Actor);
	if( S!=None )
	{
		// check if the current perk has changed recently
		CheckPerksX(S);

		j = 0;
	
		// Draw the available perks
		for ( i=0; i<MaxPerks; i++ )
		{
			if ( i != CurPerk )
			{
				S.CachePerks[i].PerkClass.Static.PreDrawPerk(C,Max(S.CachePerks[i].CurrentLevel,1)-1,M,SM);
				PerkSelectIcons[j].Image = M;
				PerkSelectIcons[j].Index = i;
				PerkSelectIcons[j].ImageColor = C.DrawColor;
				PerkSelectIcons[j].ImageColor.A = 255;
				j++;
			}
		}

		// Draw current perk
		if( CurPerk!=255 )
			DrawCurrentPerkX(S, C, CurPerk);
	}
	
	return false;
}

function bool InternalOnClick(GUIComponent Sender)
{
	local MutSR_ClientPerkRepLink S;

	if ( Sender.IsA('KFIndexedGUIImage') && KFIndexedGUIImage(Sender).Index>=0 )
	{
		S = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
		if ( S!=None )
			S.ServerSelectPerk(S.CachePerks[KFIndexedGUIImage(Sender).Index].PerkClass);
		bPerkChange = true;
	}
	return false;	
}

function DrawCurrentPerkX( MutSR_ClientPerkRepLink S, Canvas C, Int PerkIndex)
{
	local Class<MutSR_SRVeterancyTypes> V;
	local Material M,SM;

	V = S.CachePerks[PerkIndex].PerkClass;
	C.SetPos(WinLeft * C.ClipX , WinTop * C.ClipY);
	V.Static.PreDrawPerk(C,Max(S.CachePerks[PerkIndex].CurrentLevel,1)-1,M,SM);
	if( M!=None )
		C.DrawTileScaled(M, (WinHeight * C.ClipY) / M.MaterialUSize(), (WinHeight * C.ClipY) / M.MaterialVSize());
}

function CheckPerksX( MutSR_ClientPerkRepLink S )
{
	local int i;
	local KFPlayerReplicationInfo PRI;

	// Grab the Player Controller for later use
	PRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);
                                                                                         
	// Hold onto our reference
	if( S==None )
		return;

	if( S.CachePerks.Length==0 )
	{
		S.ServerRequestPerks();
		return;
	}

	// Update the ItemCount and select the first item
	MaxPerks = Min(S.CachePerks.Length,ArrayCount(PerkSelectIcons)+1);
	CurPerk = 255;

	for( i=0; i<S.CachePerks.Length; i++ )
	{
		if ( PRI!=none && S.CachePerks[i].PerkClass==PRI.ClientVeteranSkill )
		{
			CurPerk = i;
			break;
		}
	}
	
	bPerkChange = false;
}

defaultproperties
{
	MaxPerks=10
}