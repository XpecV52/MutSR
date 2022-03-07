class MutSR_SRPerkProgressListBox extends KFPerkProgressListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(Class'MutSR_SRPerkProgressList');
	Super.InitComponent(MyController,MyOwner);
}

defaultproperties
{
}
