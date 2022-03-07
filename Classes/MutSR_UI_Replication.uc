// Written by Marco
Class MutSR_UI_Replication extends ReplicationInfo;

var transient array<MutSR_UI_Window> ClientWindows;
var transient MutSR_UI_Window TempNewMenu;
var transient string PendingData;

replication
{
	reliable if ( Role==ROLE_Authority )
		ClientPendingData,ClientOpenWindow,ClientCloseWindow,ClientAddComponent,ClientSetCompValue,ClientGetValues,ClientSetCompLock;
	
	reliable if( Role<ROLE_Authority )
		ServerSendCloseW,ServerSubmitValue;
}

simulated final function DisplayError( string S )
{
	Level.GetLocalPlayerController().ClientMessage("ServerPerks_UI warning: "$S);
}
simulated final function MutSR_UI_Window FindWindow( name ID )
{
	local int i;
	
	for( i=(ClientWindows.Length-1); i>=0; --i )
		if( ClientWindows[i].WindowID==ID )
			return ClientWindows[i];
	return None;
}

simulated final function ClientPendingData( string Data )
{
	PendingData = PendingData$Data;
}

// WARNING: Use ID with a known name entry on networking.
simulated final function ClientOpenWindow( name ID, float XS, float YS, string Caption )
{
	local MutSR_UI_Window W;
	local PlayerController PC;

	PC = Level.GetLocalPlayerController();
	if( Level.NetMode!=NM_Client && PC!=Owner )
		return;

	W = FindWindow(ID);
	if( W!=None )
	{
		DisplayError("Tried to open a second window with same ID!");
		return;
	}
	
	// Big hack in order to easily access newly created menu.
	Class'MutSR_UI_Window'.Default.RepNotify = Self;
	PC.Player.GUIController.OpenMenu(string(Class'MutSR_UI_Window'),Caption);
	Class'MutSR_UI_Window'.Default.RepNotify = None;
	W = TempNewMenu;
	TempNewMenu = None;
	if( W==None )
	{
		DisplayError("Window couldn't be created!");
		return;
	}
	ClientWindows[ClientWindows.Length] = W;
	W.RepNotify = Self;
	W.WindowID = ID;
	W.WinTop = (1.f-YS) * 0.5f;
	W.WinLeft = (1.f-XS) * 0.5f;
	W.WinWidth = XS;
	W.WinHeight = YS;
	W.DefaultLeft = W.WinLeft;
	W.DefaultTop = W.WinTop;
	W.DefaultWidth = W.WinWidth;
	W.DefaultHeight = W.WinHeight;
}
simulated final function ClientCloseWindow( name ID )
{
	local int i;

	for( i=(ClientWindows.Length-1); i>=0; --i )
	{
		if( ClientWindows[i].WindowID==ID )
		{
			ClientWindows[i].RepNotify = None;
			GUIController(Level.GetLocalPlayerController().Player.GUIController).RemoveMenu(ClientWindows[i],true);
			ClientWindows.Remove(i,1);
			break;
		}
	}
}

/* Component ID:
0 - Normal button, will callback ServerSubmitValue when pressed.
1 - Submit button, will send all changed values when pressed.
2 - Close button, will close menu.
3 - String editbox.
4 - Float editbox, MinValue:MaxValue:StepValue:CurrentValue
5 - Int editbox, same as above.
6 - Combo box, CurrentItemIndex;Item Value1:Item Value2:Item Value3:etc
7 - Checkbox, 0 = false, 1 = true
8 - Textbox, Value = text to draw.
*/
simulated final function ClientAddComponent( name ID, int CompID, byte Type, bool bInstant, bool bLock, float X, float Y, float XS, float YS, string Value, optional string ToolTip )
{
	local MutSR_UI_Window W;

	W = FindWindow(ID);
	if( W!=None )
		W.AddCompID(CompID,Type,bInstant,bLock,X,Y,XS,YS,PendingData$Value,ToolTip);
	PendingData = "";
}
simulated final function ClientSetCompValue( name ID, int CompID, string Value )
{
	local MutSR_UI_Window W;

	W = FindWindow(ID);
	if( W!=None )
		W.SetComponentData(CompID,PendingData$Value);
	PendingData = "";
}
simulated final function ClientSetCompLock( name ID, int CompID, bool bLocked )
{
	local MutSR_UI_Window W;

	W = FindWindow(ID);
	if( W!=None )
		W.SetComponentLock(CompID,bLocked);
}
simulated final function ClientGetValues( name ID )
{
	local MutSR_UI_Window W;

	W = FindWindow(ID);
	if( W!=None )
		W.SendChanges();
}
simulated final function WindowClosed( MutSR_UI_Window W )
{
	local int i;
	
	for( i=(ClientWindows.Length-1); i>=0; --i )
		if( ClientWindows[i]==W )
		{
			ClientWindows.Remove(i,1);
			break;
		}
	ServerSendCloseW(W.WindowID);
	W.RepNotify = None;
}
simulated function Destroyed()
{
	local int i;
	local PlayerController PC;
	
	if( Level.NetMode!=NM_DedicatedServer )
	{
		PC = Level.GetLocalPlayerController();
		
		// Close all windows to prevent memory access errors.
		for( i=(ClientWindows.Length-1); i>=0; --i )
		{
			ClientWindows[i].RepNotify = None;
			GUIController(PC.Player.GUIController).RemoveMenu(ClientWindows[i],true);
		}
		ClientWindows.Length = 0;
	}
}

final function ServerSendCloseW( name ID )
{
	DlgWindowClosed(ID);
}
final function ServerSubmitValue( name ID, int CompID, string Value )
{
	DlgSubmittedValue(ID,CompID,Value);
}
delegate DlgWindowClosed( name ID );
delegate DlgSubmittedValue( name ID, int CompID, string Value );

defaultproperties
{
	bAlwaysRelevant=false
	bOnlyRelevantToOwner=true
}