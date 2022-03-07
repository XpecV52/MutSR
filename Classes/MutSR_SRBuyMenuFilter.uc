//=============================================================================
// Buy Menu Filter for the trader
//=============================================================================
// Killing Floor Source
// Copyright (C) 2013 Tripwire Interactive LLC
// Jeff "Captain Mallard" Robinson
//=============================================================================
class MutSR_SRBuyMenuFilter extends KFBuyMenuFilter;

var MutSR_SRBuyMenuSaleList SaleListBox;
var array<KFIndexedGUIImage> SmallButtons;
var array<GUIImage> ButtonBGImg;
var() Texture NonSelectedBack;
var int OldPerkIndex,OldGroupIndex;
var bool bHasInit;

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super(GUIMultiComponent).InitComponent(MyController, MyOwner);
	if( !bHasInit )
		UpdatePerkIcons();
}

event Opened(GUIComponent Sender)
{
    super(GUIMultiComponent).Opened( Sender );
	if( !bHasInit )
		UpdatePerkIcons();
}

final function KFIndexedGUIImage AddButton( int Index )
{
	local KFIndexedGUIImage S;
	local GUIImage B;
	
	if( SmallButtons.Length==9 ) // Can't add more or menu will look ugly.
		return None;
	
	S = KFIndexedGUIImage(AddComponent(string(Class'KFIndexedGUIImage')));
	S.WinWidth = 0.04;
	S.WinHeight = 0.04;
	S.WinLeft = 0.98;
	S.WinTop = 0.052;
	S.ImageStyle = ISTY_Scaled;
	S.Renderweight = 0.6;
	S.OnClick = InternalOnClick;
	S.Index = Index;
	S.bBoundToParent = true;
	SmallButtons[SmallButtons.Length] = S;
	
	B = GUIImage(AddComponent(string(Class'GUIImage')));
	B.WinWidth = 0.04;
	B.WinHeight = 0.04;
	B.WinLeft = 0.98;
	B.WinTop = 0.05;
	B.Image = NonSelectedBack;
	B.ImageStyle = ISTY_Scaled;
	B.Renderweight = 0.5;
	B.bBoundToParent = true;
	ButtonBGImg[ButtonBGImg.Length] = B;
	
	return S;
}
final function UpdatePerkIcons()
{
	local MutSR_ClientPerkRepLink CPRL;
	local int i,j,Index;
	local KFIndexedGUIImage S;

	CPRL = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
	if( CPRL==None || !CPRL.bRepCompleted )
		return;
	bHasInit = true;
	
	AddButton(-1); // Add favorites button.
	for( i=0; i<CPRL.ShopCategories.Length; ++i )
	{
		Index = CPRL.ShopCategories[i].PerkIndex;
		if( Index<CPRL.ShopPerkIcons.Length )
		{
			for( j=(SmallButtons.Length-1); j>=0; --j )
				if( SmallButtons[j].Index==Index )
					break;
			if( j>=0 )
				continue; // Already added.
			
			S = AddButton(Index);
			if( S==None )
				continue;
			
			for( j=(CPRL.CachePerks.Length-1); j>=0; --j )
				if( Index==CPRL.CachePerks[j].PerkClass.Default.PerkIndex )
				{
					S.Hint = CPRL.CachePerks[j].PerkClass.Default.VeterancyName;
					S.Image = CPRL.CachePerks[j].PerkClass.Default.OnHUDIcon;
					break;
				}
			
			if( j==-1 )
			{
				S.Hint = Class'KFBuyMenuFilter'.Default.PerkSelectIcon7.Hint;
				S.Image = NoPerkIcon;
			}
		}
	}
	
	// Name em approprietly.
	SmallButtons[0].Hint = Class'KFBuyMenuFilter'.Default.PerkSelectIcon8.Hint;
	SmallButtons[0].Image = FavoritesIcon;
	bResized = false;
}
final function int GroupToPerkIndex( int In )
{
	return Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner()).ShopCategories[In].PerkIndex;
}
function bool MyOnDraw(Canvas C)
{
	local int i,CurIndex,CurGroup;
	local KFPlayerReplicationInfo KFPRI;

	if( !bHasInit )
	{
		UpdatePerkIcons();
		if( !bHasInit )
			return false;
	}

	// make em square
	if ( !bResized )
	{
		ResizeIcons(C);
		RealignIcons();
	}
	
	KFPRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);
	CurIndex = -2;
	if( KFPRI!=None && KFPRI.ClientVeteranSkill!=None )
		CurIndex = KFPRI.ClientVeteranSkill.Default.PerkIndex;
	
	CurGroup = SaleListBox.ActiveCategory;
	
	if( OldPerkIndex!=CurIndex || OldGroupIndex!=CurGroup )
	{
		OldPerkIndex = CurIndex;
		OldGroupIndex = CurGroup;
		if( CurGroup>=0 )
			CurGroup = GroupToPerkIndex(CurGroup);
		
		// Draw the available perks
		for( i=0; i<SmallButtons.Length; ++i )
		{
			// Check if current perk player uses now.
			if( SmallButtons[i].Index==CurIndex )
				SmallButtons[i].ImageColor.A = 255;
			else SmallButtons[i].ImageColor.A = 95;
			
			// Check if corresponding group index is open on buy menu.
			if( SmallButtons[i].Index==CurGroup )
				ButtonBGImg[i].Image = CurPerkBack;
			else ButtonBGImg[i].Image = NonSelectedBack;
		}
	}
	return false;
}

final function int GetNextCategory( int Index )
{
	local MutSR_ClientPerkRepLink C;
	local int i,First;
	local bool bFoundCurrent;
	
	C = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
	First = -1;
	for( i=0; i<C.ShopCategories.Length; ++i )
	{
		if( Index==C.ShopCategories[i].PerkIndex )
		{
			if( First==-1 )
				First = i;
			if( OldGroupIndex==i )
				bFoundCurrent = true;
			else if( bFoundCurrent )
				return i;
		}
	}
	return First;
}
function bool InternalOnClick(GUIComponent Sender)
{
	local int Index;

	if ( Sender.IsA('KFIndexedGUIImage') )
	{
		Index = KFIndexedGUIImage(Sender).Index;
		if( Index>=0 )
			Index = GetNextCategory(Index);
		SaleListBox.SetCategoryNum(Index,true);
	}
	return false;
}

function ResizeIcons(Canvas C)
{
    local float sizeX, sizeY;
	local int i;

    sizeX = (C.ClipY / C.ClipX) * BoxSizeX;
    sizeY = (C.ClipY / C.ClipX) * BoxSizeY;

	for( i=0; i<SmallButtons.Length; ++i )
	{
		ButtonBGImg[i].WinWidth = sizeX;
		SmallButtons[i].WinWidth = sizeY;
	}
	bResized = true;
}

function RealignIcons()
{
    local int i;
    local float IconWidth, TotalWidth, WidthLeft, WidthLeftForEachIcon, IconPadding;

    IconWidth = SmallButtons[0].WinWidth;
    TotalWidth = IconWidth * SmallButtons.Length;
    WidthLeft = 1.f - TotalWidth;
    WidthLeftForEachIcon = WidthLeft / SmallButtons.Length;
    IconPadding = WidthLeftForEachIcon / 2.f;
    for( i = 0; i <SmallButtons.Length; ++i ) // size of PerkSelectIcons
    {
        SmallButtons[i].WinLeft = IconPadding + (IconPadding + IconWidth + IconPadding) * i;
        ButtonBGImg[i].WinLeft = IconPadding + (IconPadding + IconWidth + IconPadding) * i;
    }
}

defaultproperties
{
	NonSelectedBack=Texture'KF_InterfaceArt_tex.Menu.Perk_box_unselected'
	OldPerkIndex=9999
	OldGroupIndex=9999

	PerkBack0=None
	PerkBack1=None
	PerkBack2=None
	PerkBack3=None
	PerkBack4=None
	PerkBack5=None
	PerkBack6=None
	PerkBack7=None
	PerkBack8=None

	PerkSelectIcon0=None
	PerkSelectIcon1=None
	PerkSelectIcon2=None
	PerkSelectIcon3=None
	PerkSelectIcon4=None
	PerkSelectIcon5=None
	PerkSelectIcon6=None
	PerkSelectIcon7=None
	PerkSelectIcon8=None
}