Class MutSR_UI_Window extends FloatingWindow;

struct FComponentData
{
	var GUIComponent Component;
	var string OldData;
	var byte Type;
	var bool bInstantUpdate,bLocked;
};
var name WindowID;
var array<FComponentData> MyComponents;
var MutSR_UI_Replication RepNotify;
var bool bSecureChanges;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController,MyOwner);
	if( Default.RepNotify!=None )
	{
		Default.RepNotify.TempNewMenu = Self;
		Default.RepNotify = None;
	}
}
function HandleParameters(string Param1, string Param2)
{
	t_WindowTitle.SetCaption(Param1);
	WindowName = Param1;
}
function Closed( GUIComponent Sender, bool bCancelled )
{
	if( RepNotify!=None )
		RepNotify.WindowClosed(Self);
	RepNotify = None;
	Super.Closed(Sender, bCancelled);
}
final function InitFloatValue( moFloatEdit C, string V )
{
	local string S;
	local float FA,FB,FC;
	
	Divide(V,":",S,V);
	FA = float(S);
	Divide(V,":",S,V);
	FB = float(S);
	Divide(V,":",S,V);
	FC = float(S);
	C.Setup(FA,FB,FC);
	C.SetComponentValue(V,true);
}
final function InitIntValue( moNumericEdit C, string V )
{
	local string S;
	local int FA,FB,FC;
	
	Divide(V,":",S,V);
	FA = int(S);
	Divide(V,":",S,V);
	FB = int(S);
	Divide(V,":",S,V);
	FC = int(S);
	C.Setup(FA,FB,FC);
	C.SetComponentValue(V,true);
}
final function InitComboBox( moComboBox C, string V )
{
	local string S;
	local array<string> AR;
	local int i;
	
	Divide(V,";",S,V);
	Split(V,":",AR);
	
	if( C.ItemCount()>0 )
		C.ResetComponent();
	for( i=0; i<AR.Length; ++i )
		C.AddItem(AR[i]);
	C.SilentSetIndex(int(S));
}
final function bool AddCompID( int ID, byte Type, bool bInstant, bool bLock, float X, float Y, float XS, float YS, string Value, string ToolTipS )
{
	local GUIComponent NC;

	bSecureChanges = true;
	if( MyComponents.Length<=ID )
		MyComponents.Length = (ID+1);
	NC = MyComponents[ID].Component;
	MyComponents[ID].OldData = "";
	
	if( NC!=None && MyComponents[ID].Type!=Type )
	{
		RemoveComponent(NC);
		NC = None;
	}

	switch( Type )
	{
	case 0: // Button.
	case 1: // Submit.
	case 2: // Close.
		if( NC==None )
			NC = AddComponent(string(Class'GUIButton'));
		GUIButton(NC).Caption = Value;
		GUIButton(NC).OnClick = InternalOnClick;
		break;
	case 3: // Editbox
		if( NC==None )
			NC = AddComponent(string(Class'moEditBox'));
		moEditBox(NC).SetComponentValue(Value,true);
		moEditBox(NC).OnChange = ValueChange;
		MyComponents[ID].OldData = Value;
		break;
	case 4: // Floating point editbox
		if( NC==None )
			NC = AddComponent(string(Class'moFloatEdit'));
		InitFloatValue(moFloatEdit(NC),Value);
		moFloatEdit(NC).OnChange = ValueChange;
		break;
	case 5: // Numeric editbox
		if( NC==None )
			NC = AddComponent(string(Class'moNumericEdit'));
		InitIntValue(moNumericEdit(NC),Value);
		moNumericEdit(NC).OnChange = ValueChange;
		break;
	case 6: // Combo box.
		if( NC==None )
			NC = AddComponent(string(Class'moComboBox'));
		InitComboBox(moComboBox(NC),Value);
		moComboBox(NC).OnChange = ValueChange;
		break;
	case 7: // Checkbox
		if( NC==None )
			NC = AddComponent(string(Class'moCheckBox'));
		moCheckBox(NC).SetComponentValue(Value,true);
		moCheckBox(NC).OnChange = ValueChange;
		break;
	case 8: // Textbox.
		if( NC==None )
			NC = AddComponent(string(Class'GUIScrollTextBox'));
		GUIScrollTextBox(NC).SetContent(Value);
		break;
	default:
		Warn("Unknown component ID.");
		bSecureChanges = false;
		return false;
	}
	MyComponents[ID].bLocked = bLock;
	MyComponents[ID].bInstantUpdate = bInstant;
	MyComponents[ID].Component = NC;
	MyComponents[ID].Type = Type;
	NC.WinTop = Y;
	NC.WinLeft = X;
	NC.WinWidth = XS;
	NC.WinHeight = YS;
	
	if( bLock )
		NC.DisableMe();
	else NC.EnableMe();

	if( ToolTipS!="" )
	{
		if( NC.ToolTip!=None )
			NC.SetToolTipText(ToolTipS);
		if( GUIMenuOption(NC)!=None )
			GUIMenuOption(NC).SetCaption(ToolTipS);
	}
	bSecureChanges = false;
	return true;
}
final function string GetComponentData( int Index )
{
	if( MyComponents.Length<=Index || MyComponents[Index].Component==None )
		return "";
	switch( MyComponents[Index].Type )
	{
	case 0: // Button.
	case 1: // Submit.
	case 2: // Close.
	case 8: // Textbox
		return "";
	case 6:
		return string(moComboBox(MyComponents[Index].Component).GetIndex());
	case 7:
		return Eval(moCheckBox(MyComponents[Index].Component).IsChecked(),"1","0");
	default:
		return GUIMenuOption(MyComponents[Index].Component).GetComponentValue();
	}
}
final function bool SetComponentData( int Index, string Data )
{
	if( MyComponents.Length<=Index || MyComponents[Index].Component==None )
		return false;
	bSecureChanges = true;
	switch( MyComponents[Index].Type )
	{
	case 0: // Button.
	case 1:
	case 2:
		GUIButton(MyComponents[Index].Component).Caption = Data;
		break;
	case 6:
		moComboBox(MyComponents[Index].Component).SilentSetIndex(int(Data));
		break;
	case 8:
		GUIScrollTextBox(MyComponents[Index].Component).SetContent(Data);
		break;
	default:
		MyComponents[Index].OldData = Data;
		GUIMenuOption(MyComponents[Index].Component).SetComponentValue(Data,true);
	}
	bSecureChanges = false;
	return true;
}
final function bool SetComponentLock( int Index, bool bLocked )
{
	if( MyComponents.Length<=Index || MyComponents[Index].Component==None || MyComponents[Index].bLocked==bLocked )
		return false;
	bSecureChanges = true;
	MyComponents[Index].bLocked = bLocked;
	if( bLocked )
		MyComponents[Index].Component.DisableMe();
	else MyComponents[Index].Component.EnableMe();
	bSecureChanges = false;
	return true;
}
final function SendChanges()
{
	local string S;
	local int i;

	for( i=0; i<MyComponents.Length; ++i )
		if( MyComponents[i].Component!=None && MyComponents[i].Type>=3 )
		{
			S = GetComponentData(i);
			if( S!=MyComponents[i].OldData )
			{
				RepNotify.ServerSubmitValue(WindowID,i,S);
				MyComponents[i].OldData = S;
			}
		}
}

function bool InternalOnClick(GUIComponent Sender)
{
	local int i;
	local string S;
	
	if( !bSecureChanges )
	{
		for( i=0; i<MyComponents.Length; ++i )
			if( MyComponents[i].Component==Sender )
			{
				if( MyComponents[i].Type==1 && !MyComponents[i].bLocked )
				{
					SendChanges();
					RepNotify.ServerSubmitValue(WindowID,i,"");
				}
				else if( MyComponents[i].Type==2 && !MyComponents[i].bLocked )
				{
					Controller.RemoveMenu(Self);
				}
				else if( MyComponents[i].bInstantUpdate && !MyComponents[i].bLocked )
				{
					S = GetComponentData(i);
					if( MyComponents[i].Type==0 || S!=MyComponents[i].OldData )
					{
						RepNotify.ServerSubmitValue(WindowID,i,S);
						MyComponents[i].OldData = S;
					}
				}
				Return True;
			}
	}
	Return False;
}
function ValueChange(GUIComponent Sender)
{
	InternalOnClick(Sender);
}

defaultproperties
{
	Begin Object Class=FloatingImage Name=FloatingFrameBg
		Image=Texture'KF_InterfaceArt_tex.Menu.Thin_border'
		DropShadow=None
		ImageStyle=ISTY_Stretched
		ImageRenderStyle=MSTY_Normal
		WinTop=0.040000
		WinLeft=0.000000
		WinWidth=1.000000
		WinHeight=0.960000
		RenderWeight=0.000003
	End Object
	i_FrameBG=FloatingFrameBg

	bPersistent=false
	bAllowedAsLast=true
}