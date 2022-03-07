class MutSR_SRPerkSelectListBox extends KFPerkSelectListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(Class'MutSR_SRPerkSelectList');
	Super.InitComponent(MyController,MyOwner);
}

defaultproperties
{
}
