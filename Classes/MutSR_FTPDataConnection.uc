Class MutSR_FTPDataConnection extends TcpLink;

var bool bUpload,bWasOpened;
var string Data;

delegate OnCompleted();
delegate OnProgress();

function PostBeginPlay()
{
	LinkMode = MODE_Text;
}
event Opened()
{
	BeginUpload();
}
event Closed()
{
	OnCompleted();
	Destroy();
}
event ReceivedText( string Text )
{
	if( bUpload )
		Log(Text,'FTPD');
	else
	{
		Data $= Text;
		OnProgress();
	}
}
function BeginUpload()
{
	if( bWasOpened )
		GoToState('Uploading');
	else bWasOpened = true;
}

state Uploading
{
	function BeginState()
	{
		Tick(0.f);
	}
	function Tick( float Delta )
	{
		if( Data!="" )
		{
			SendText(Left(Data,250));
			Data = Mid(Data,250);
		}
		else Close();
	}
}
