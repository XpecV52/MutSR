class MutSR_SRStatListBox extends GUIListBoxBase;

var MutSR_SRStatList List;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(Class'MutSR_SRStatList');
	Super.InitComponent(MyController,MyOwner);
	List = MutSR_SRStatList(AddComponent(DefaultListClass));
	if (List == None)
	{
		Warn(Class$".InitComponent - Could not create default list ["$DefaultListClass$"]");
		return;
	}
	InitBaseList(List);
}

function int GetIndex()
{
	return List.Index;
}

defaultproperties
{
}
