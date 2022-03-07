//=============================================================================
// The trader menu's list with items for sale
//=============================================================================
class MutSR_SRBuyMenuSaleList extends KFBuyMenuSaleList;

#exec obj load file="KF_InterfaceArt_tex.utx"

var int ActiveCategory,SelectionOffset;
var localized string WeaponGroupText;
var string FavoriteGroupName;
var() Material CategoryTex,CategoryPerkTex,SelectedCatPerkTex,CategoryArrow,CategoryArrowSel;
var array<Material> ListPerkIcons;

event Opened(GUIComponent Sender)
{
	super(GUIVertList).Opened(Sender);

	// Get localized string
	FavoriteGroupName = Class'KFBuyMenuFilter'.Default.PerkSelectIcon8.Hint;

	// Fixed script warnings.
	UpdateForSaleBuyables();
}
final function GUIBuyable GetSelectedBuyable()
{
	if( Index<0 || Index>=CanBuys.Length || CanBuys[Index]>1 || (Index-SelectionOffset)<0 || (Index-SelectionOffset)>=ForSaleBuyables.Length )
		return None;
	return ForSaleBuyables[Index-SelectionOffset];
}
final function CopyAllBuyables()
{
	local MutSR_ClientPerkRepLink L;
	local int i;

	L = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
	if( L==None )
		return;
	for( i=0; i<ForSaleBuyables.Length; ++i )
		if( ForSaleBuyables[i]!=None )
			L.AllocatedObjects[L.AllocatedObjects.Length] = ForSaleBuyables[i];
}
final function GUIBuyable AllocateEntry( MutSR_ClientPerkRepLink L )
{
	local GUIBuyable G;

	if( L.AllocatedObjects.Length==0 )
		return new Class'GUIBuyable';
	G = L.AllocatedObjects[0];
	L.ResetItem(G);
	L.AllocatedObjects.Remove(0,1);
	return G;
}

final function SetCategoryNum( int N, optional bool bScrollTo )
{
	if( ActiveCategory==N )
		ActiveCategory = -2;
	else ActiveCategory = N;
	SelectionOffset = (N+2);
	UpdateForSaleBuyables();
	Index = N+1;
	if( bScrollTo )
		SetTopItem(Index);
}
event Closed(GUIComponent Sender, bool bCancelled)
{
	CopyAllBuyables();
	ForSaleBuyables.Length = 0;
	super.Closed(Sender, bCancelled);
}
final function bool DualIsInInventory( Class<Weapon> WC )
{
	local Inventory I;
	
	for( I=PlayerOwner().Pawn.Inventory; I!=None; I=I.Inventory )
	{
		if( Weapon(I)!=None && Weapon(I).DemoReplacement==WC )
			return true;
	}
	return false;
}
final function bool IsInInventoryWep( Class<Weapon> WC )
{
	local Inventory I;
	
	for( I=PlayerOwner().Pawn.Inventory; I!=None; I=I.Inventory )
		if( I.Class==WC )
			return true;
	return false;
}

final function bool CheckGoldGunAvailable( class<KFWeaponPickup> WC )
{
	local int i;
	local Inventory Inv;
	local class<KFWeaponPickup> WPC;

	for( Inv=PlayerOwner().Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		if( KFWeapon(Inv)==None || Inv.PickupClass==None )
			continue;
		WPC = class<KFWeaponPickup>(Inv.PickupClass);
		if( WPC!=None && WPC.Default.VariantClasses.Length>0 )
		{
			for( i=(WC.Default.VariantClasses.Length-1); i>=0; --i )
			{
				if( WC.Default.VariantClasses[i]==Inv.PickupClass )
					return true;
			}
			for( i=(WPC.Default.VariantClasses.Length-1); i>=0; --i )
			{
				if( WPC.Default.VariantClasses[i]==WC )
					return true;
			}
		}
	}
	return false;
}

final function KFShopVolume_Story GetCurrentShop()
{
	local KFPlayerController_Story	StoryPC;

	StoryPC = KFPlayerController_Story(PlayerOwner());
	if(StoryPC != none)
		return StoryPC.CurrentShopVolume;
	return none;
}

function FilterBuyablesList();
function int PopulateBuyables()
{
	return 0;
}

function UpdateForSaleBuyables()
{
	local class<KFVeterancyTypes> PlayerVeterancy;
	local KFPlayerReplicationInfo KFPRI;
	local MutSR_ClientPerkRepLink CPRL;
	local GUIBuyable ForSaleBuyable;
	local class<KFWeaponPickup> ForSalePickup;
	local int j, DualDivider, i, Num, z, PerkSaleOffset;
	local class<KFWeapon> ForSaleWeapon,SecType;
	local class<MutSR_SRVeterancyTypes> Blocker;
	local KFShopVolume_Story CurrentShop;
	local byte DLCLocked;

	// Clear the ForSaleBuyables array
	CopyAllBuyables();
	ForSaleBuyables.Length = 0;

	// Grab the items for sale
	CPRL = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());
	if( CPRL==None )
		return; // Hmmmm?

	KFPRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);

	// Grab Players Veterancy for quick reference
	if ( KFPRI!=none )
		PlayerVeterancy = KFPRI.ClientVeteranSkill;
	if( PlayerVeterancy==None )
		PlayerVeterancy = class'KFVeterancyTypes';
	CurrentShop = GetCurrentShop();

	// Grab the weapons!
	if( ActiveCategory>=-1 )
	{
		if( CurrentShop!=None )
			Num = CurrentShop.SaleItems.Length;
		else Num = CPRL.ShopInventory.Length;
		for ( z=0; z<Num; z++ )
		{
			if( CurrentShop!=None )
			{
				// Allow story mode volume limit weapon availability.
				ForSalePickup = class<KFWeaponPickup>(CurrentShop.SaleItems[z]);
				if( ForSalePickup==None )
					continue;
				for ( j=(CPRL.ShopInventory.Length-1); j>=CPRL.ShopInventory.Length; --j )
					if( CPRL.ShopInventory[j].PC==ForSalePickup )
						break;
				if( j<0 )
					continue;
			}
			else
			{
				ForSalePickup = class<KFWeaponPickup>(CPRL.ShopInventory[z].PC);
				j = z;
			}

			if ( ForSalePickup==None || class<KFWeapon>(ForSalePickup.default.InventoryType)==None || class<KFWeapon>(ForSalePickup.default.InventoryType).default.bKFNeverThrow
				 || IsInInventory(ForSalePickup) )
				continue;
			if( ActiveCategory==-1 )
			{
				if( !Class'MutSR_SRClientSettings'.Static.IsFavorite(ForSalePickup) )
					continue;
			}
			else if( ActiveCategory!=CPRL.ShopInventory[j].CatNum )
				continue;
				
			ForSaleWeapon = class<KFWeapon>(ForSalePickup.default.InventoryType);

			// Remove single weld.
			if( class'MutSR_DualWeaponsManager'.Static.HasDualies(ForSaleWeapon,PlayerOwner().Pawn.Inventory) || (ForSalePickup.Default.VariantClasses.Length>0 && CheckGoldGunAvailable(ForSalePickup)) )
				continue;

			DualDivider = 1;

			// Make cheaper.
			if( ForSaleWeapon!=class'Dualies' && class'MutSR_DualWeaponsManager'.Static.IsDualWeapon(ForSaleWeapon,SecType) && IsInInventoryWep(SecType) )
				DualDivider = 2;

			Blocker = None;
			for( i=0; i<CPRL.CachePerks.Length; ++i )
				if( !CPRL.CachePerks[i].PerkClass.Static.AllowWeaponInTrader(ForSalePickup,KFPRI,CPRL.CachePerks[i].CurrentLevel) )
				{
					Blocker = CPRL.CachePerks[i].PerkClass;
					break;
				}
			if( Blocker!=None && Blocker.Default.DisableTag=="" )
				continue;

			ForSaleBuyable = AllocateEntry(CPRL);

			ForSaleBuyable.ItemName 		= ForSalePickup.default.ItemName;
			ForSaleBuyable.ItemDescription 		= ForSalePickup.default.Description;
			ForSaleBuyable.ItemImage		= ForSaleWeapon.default.TraderInfoTexture;
			ForSaleBuyable.ItemWeaponClass		= ForSaleWeapon;
			ForSaleBuyable.ItemAmmoClass		= ForSaleWeapon.default.FireModeClass[0].default.AmmoClass;
			ForSaleBuyable.ItemPickupClass		= ForSalePickup;
			ForSaleBuyable.ItemCost			= int((float(ForSalePickup.default.Cost)
												  * PlayerVeterancy.static.GetCostScaling(KFPRI, ForSalePickup)) / DualDivider);
			ForSaleBuyable.ItemAmmoCost		= 0;
			ForSaleBuyable.ItemFillAmmoCost		= 0;

			ForSaleBuyable.ItemWeight	= ForSaleWeapon.default.Weight;
			if( DualDivider==2 )
				ForSaleBuyable.ItemWeight -= SecType.Default.Weight;

			ForSaleBuyable.ItemPower		= ForSalePickup.default.PowerValue;
			ForSaleBuyable.ItemRange		= ForSalePickup.default.RangeValue;
			ForSaleBuyable.ItemSpeed		= ForSalePickup.default.SpeedValue;
			ForSaleBuyable.ItemAmmoMax		= 0;
			ForSaleBuyable.ItemPerkIndex		= ForSalePickup.default.CorrespondingPerkIndex;

			// Make sure we mark the list as a sale list
			ForSaleBuyable.bSaleList = true;

			// Sort same perk weapons in front.
			if( ForSalePickup.default.CorrespondingPerkIndex == PlayerVeterancy.default.PerkIndex )
			{
				ForSaleBuyables.Insert(PerkSaleOffset, 1);
				i = PerkSaleOffset++;
			}
			else
			{
				i = ForSaleBuyables.Length;
				ForSaleBuyables.Length = i+1;
			}
			ForSaleBuyables[i] = ForSaleBuyable;
			DLCLocked = CPRL.ShopInventory[j].bDLCLocked;
			if( DLCLocked==0 && Blocker!=None )
			{
				ForSaleBuyable.ItemCategorie = Blocker.Default.DisableTag$":"$Blocker.Default.DisableDescription;
				DLCLocked = 3;
			}
			ForSaleBuyable.ItemAmmoCurrent = DLCLocked; // DLC info.
		}
	}

	// Now Update the list
	UpdateList();
}

function UpdateList()
{
	local int i,j;
	local MutSR_ClientPerkRepLink CPRL;

	CPRL = Class'MutSR_ClientPerkRepLink'.Static.FindStats(PlayerOwner());

	// Update the ItemCount and select the first item
	ItemCount = CPRL.ShopCategories.Length + ForSaleBuyables.Length + 1;

	// Clear the arrays
	if ( ForSaleBuyables.Length < PrimaryStrings.Length )
	{
		PrimaryStrings.Length = ItemCount;
		SecondaryStrings.Length = ItemCount;
		CanBuys.Length = ItemCount;
		ListPerkIcons.Length = ItemCount;
	}

	// Update categories
	if( ActiveCategory>=-1 )
	{
		for( i=-1; i<(ActiveCategory+1); ++i )
		{
			if( i==-1 )
			{
				PrimaryStrings[j] = FavoriteGroupName;
				ListPerkIcons[j] = None;
			}
			else
			{
				PrimaryStrings[j] = CPRL.ShopCategories[i].Name;
				if( CPRL.ShopCategories[i].PerkIndex<CPRL.ShopPerkIcons.Length )
					ListPerkIcons[j] = CPRL.ShopPerkIcons[CPRL.ShopCategories[i].PerkIndex];
				else ListPerkIcons[j] = None;
			}
			CanBuys[j] = 3+i;
			++j;
		}
	}
	else
	{
		PrimaryStrings[j] = FavoriteGroupName;
		CanBuys[j] = 2;
		++j;
		for( i=0; i<CPRL.ShopCategories.Length; ++i )
		{
			PrimaryStrings[j] = CPRL.ShopCategories[i].Name;
			if( CPRL.ShopCategories[i].PerkIndex<CPRL.ShopPerkIcons.Length )
				ListPerkIcons[j] = CPRL.ShopPerkIcons[CPRL.ShopCategories[i].PerkIndex];
			else ListPerkIcons[j] = None;
			CanBuys[j] = 3+i;
			++j;
		}
	}

	// Update the players inventory list
	for ( i=0; i<ForSaleBuyables.Length; i++ )
	{
		PrimaryStrings[j] = ForSaleBuyables[i].ItemName;
		SecondaryStrings[j] = "$" @ int(ForSaleBuyables[i].ItemCost);

		if( ForSaleBuyables[i].ItemPerkIndex<CPRL.ShopPerkIcons.Length )
			ListPerkIcons[j] = CPRL.ShopPerkIcons[ForSaleBuyables[i].ItemPerkIndex];
		else ListPerkIcons[j] = None;

		if( ForSaleBuyables[i].ItemAmmoCurrent!=0 )
		{
			CanBuys[j] = 0;
			if( ForSaleBuyables[i].ItemAmmoCurrent==1 )
				SecondaryStrings[j] = "DLC";
			else if( ForSaleBuyables[i].ItemAmmoCurrent==2 )
				SecondaryStrings[j] = "LOCKED";
			else SecondaryStrings[j] = Left(ForSaleBuyables[i].ItemCategorie,InStr(ForSaleBuyables[i].ItemCategorie,":"));
		}
		else if ( ForSaleBuyables[i].ItemCost > PlayerOwner().PlayerReplicationInfo.Score ||
			 ForSaleBuyables[i].ItemWeight + KFHumanPawn(PlayerOwner().Pawn).CurrentWeight > KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight )
		{
			CanBuys[j] = 0;
		}
		else
		{
			CanBuys[j] = 1;
		}
		++j;
	}

	if( ActiveCategory>=-1 )
	{
		for( i=(ActiveCategory+1); i<CPRL.ShopCategories.Length; ++i )
		{
			PrimaryStrings[j] = CPRL.ShopCategories[i].Name;
			if( CPRL.ShopCategories[i].PerkIndex<CPRL.ShopPerkIcons.Length )
				ListPerkIcons[j] = CPRL.ShopPerkIcons[CPRL.ShopCategories[i].PerkIndex];
			else ListPerkIcons[j] = None;
			CanBuys[j] = 3+i;
			++j;
		}
	}

	if ( bNotify )
 	{
		CheckLinkedObjects(Self);
	}

	if ( MyScrollBar != none )
	{
		MyScrollBar.AlignThumb();
	}

	bNeedsUpdate = false;
}

function DrawInvItem(Canvas Canvas, int CurIndex, float X, float Y, float Width, float Height, bool bSelected, bool bPending)
{
	local float TempX, TempY, TempHeight;
	local float StringHeight, StringWidth;
	local Material M;

	OnClickSound = CS_Click;

	// Offset for the Background
	TempX = X;
	TempY = Y + ItemSpacing / 2.0;

	// Initialize the Canvas
	Canvas.Style = 1;
	//Canvas.Font = class'ROHUD'.Static.GetSmallMenuFont(Canvas);
	Canvas.SetDrawColor(255, 255, 255, 255);

	// Draw Item Background
	Canvas.SetPos(TempX, TempY);

	if ( CanBuys[CurIndex]>1 )
	{
		bSelected = (ActiveCategory==(CanBuys[CurIndex]-3));

		TempHeight = Height - 12;
		TempY += 6;
		if( ListPerkIcons[CurIndex]!=None )
		{
			Canvas.SetPos(X, Y+5);
			if( bSelected )
				M = SelectedCatPerkTex;
			else M = CategoryPerkTex;
			Canvas.DrawTileStretched(M, Height - 10, Height - 10);
			TempX += (Height-10);
			Width -= (Height-10);
		}
		Canvas.SetPos(TempX, TempY);
		Canvas.DrawTileStretched(CategoryTex, Width, Height - 12);
		
		// Draw category selection arrow.
		Canvas.SetPos(TempX+Width-Height+7, Y+8);
		if( bSelected )
			M = CategoryArrowSel;
		else M = CategoryArrow;
		Canvas.DrawTile(M, Height - 16, Height - 16, 0, 0, M.MaterialUSize(), M.MaterialVSize());
		
		// Draw perk icon
		M = ListPerkIcons[CurIndex];
		if( M!=None )
		{
			Canvas.SetPos(X + 2, Y + 7);
			Canvas.DrawTile(M, Height - 14, Height - 14, 0, 0, M.MaterialUSize(), M.MaterialVSize());
		}
	}
	else
	{
		if ( CanBuys[CurIndex]==0 )
		{
			Canvas.DrawTileStretched(DisabledItemBackgroundLeft, Height - ItemSpacing, Height - ItemSpacing);

			TempX += ((Height - ItemSpacing) - 1);
			TempHeight = Height - 12;
			TempY += 6;//(Height - TempHeight) / 2;

			Canvas.SetPos(TempX, TempY);

			Canvas.DrawTileStretched(DisabledItemBackgroundRight, Width - (Height - ItemSpacing), Height - 12);
		}
		else if ( bSelected )
		{
			Canvas.DrawTileStretched(SelectedItemBackgroundLeft, Height - ItemSpacing, Height - ItemSpacing);

			TempX += ((Height - ItemSpacing) - 1);
			TempHeight = Height - 12;
			TempY += 6;//(Height - TempHeight) / 2;

			Canvas.SetPos(TempX, TempY);
			Canvas.DrawTileStretched(SelectedItemBackgroundRight, Width - (Height - ItemSpacing), Height - 12);
		}
		else
		{
			Canvas.DrawTileStretched(ItemBackgroundLeft, Height - ItemSpacing, Height - ItemSpacing);

			TempX += ((Height - ItemSpacing) - 1);
			TempHeight = Height - 12;
			TempY += 6;//(Height - TempHeight) / 2;

			Canvas.SetPos(TempX, TempY);

			Canvas.DrawTileStretched(ItemBackgroundRight, Width - (Height - ItemSpacing), Height - 12);
		}

		M = ListPerkIcons[CurIndex];
		if( M!=None )
		{
			Canvas.SetPos(X + 4, Y + 4);
			Canvas.DrawTile(M, Height - 8, Height - 8, 0, 0, M.MaterialUSize(), M.MaterialVSize());
		}
	}

	// Select Text color
	if ( CurIndex == MouseOverIndex )
	{
		Canvas.SetDrawColor(255, 255, 255, 255);
	}
	else
	{
		Canvas.SetDrawColor(0, 0, 0, 255);
	}

	// Draw the item's name or category
	Canvas.TextSize(PrimaryStrings[CurIndex], StringWidth, StringHeight);
	Canvas.SetPos(TempX + (0.2 * Height), TempY + ((TempHeight - StringHeight) / 2));
	Canvas.DrawText(PrimaryStrings[CurIndex]);

	// Draw the item's price
	if ( CanBuys[CurIndex] <2 )
	{
		Canvas.TextSize(SecondaryStrings[CurIndex], StringWidth, StringHeight);
		Canvas.SetPos((TempX - Height) + Width - (StringWidth + (0.2 * Height)), TempY + ((TempHeight - StringHeight) / 2));
		Canvas.DrawText(SecondaryStrings[CurIndex]);
	}
	/* else
	{
		Canvas.TextSize(WeaponGroupText, StringWidth, StringHeight);
		Canvas.SetPos((TempX - Height) + Width - (StringWidth + (0.2 * Height)), TempY + ((TempHeight - StringHeight) / 2));
		Canvas.DrawText(WeaponGroupText);
	}*/

	Canvas.SetDrawColor(255, 255, 255, 255);
}

function IndexChanged(GUIComponent Sender)
{
	if ( Index>=0 && CanBuys[Index]==0 && (Index-SelectionOffset)>=0 && ForSaleBuyables[Index-SelectionOffset].ItemAmmoCurrent==0 )
	{
		if ( ForSaleBuyables[Index-SelectionOffset].ItemCost > PlayerOwner().PlayerReplicationInfo.Score )
			PlayerOwner().Pawn.DemoPlaySound(TraderSoundTooExpensive, SLOT_Interface, 2.0);
		else if ( ForSaleBuyables[Index-SelectionOffset].ItemWeight + KFHumanPawn(PlayerOwner().Pawn).CurrentWeight > KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight )
			PlayerOwner().Pawn.DemoPlaySound(TraderSoundTooHeavy, SLOT_Interface, 2.0);
	}
	Super(GUIVertList).IndexChanged(Sender);
}

defaultproperties
{
	ActiveCategory=-2
	WeaponGroupText="Weapon group"
	CategoryTex=Texture'KF_InterfaceArt_tex.Menu.Thin_border'
	CategoryPerkTex=Texture'KF_InterfaceArt_tex.Menu.button_Highlight'
	SelectedCatPerkTex=Texture'KF_InterfaceArt_tex.Menu.button_pressed'
	CategoryArrow=Texture'KF_InterfaceArt_tex.Menu.LeftMark'
	CategoryArrowSel=Texture'KF_InterfaceArt_tex.Menu.DownMark'
}