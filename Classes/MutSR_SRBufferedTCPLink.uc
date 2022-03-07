class MutSR_SRBufferedTCPLink extends BufferedTCPLink;

var IpAddr			ServerIpAddr;
var string          ReceiveState;
var string          ErrorName;

var string			RemoteAddress,RemoteURL;
var int				RemotePort,ContentLength;
var bool			bHasError,bHasData,bReceivedHeader;

final function OnError( string E )
{
	bHasError = true;  // set error flag
	ErrorName = E;
	SetTimer(0,false);
}
final function StartBuffering( string URL )
{
	local int i;
	
	Disable('Tick');
	ResetBuffer();
	i = InStr(URL,"/");
	if( i>0 )
	{
		RemoteAddress = Left(URL,i);
		RemoteURL = Mid(URL,i);
	}
	else
	{
		RemoteAddress = URL;
		RemoteURL = "/index.html";
	}
	i = InStr(RemoteAddress,":");
	if( i==-1 )
		RemotePort = 80; // connect to http port
	else
	{
		RemotePort = int(Mid(RemoteAddress,i+1));
		RemoteAddress = Left(RemoteAddress,i);
	}
	Resolve(RemoteAddress);
}
function ResolveFailed()
{
	OnError("Resolve failure ("$RemoteAddress$")");
}
function Resolved( IpAddr Addr )
{
	// Set the address
	ServerIpAddr.Addr = Addr.Addr;
	ServerIpAddr.Port = RemotePort;

	// Bind the local port.
	if( BindPort() == 0 )
		OnError("Port couldn't be bound");
	else
	{
		OpenNoSteam( ServerIpAddr );
		SetTimer(6,false);
	}
}

function Opened()
{
	local string S;
	
	S = "GET "$RemoteURL$" HTTP/1.1"$CRLF$"Host: "$RemoteAddress$CRLF$"UserID: "$
		Class'MutSR_ClientPerkRepLink'.Static.FindStats(Level.GetLocalPlayerController()).UserID$CRLF$CRLF$CRLF;
	SendText(S);
	SetTimer(20,false); // 20 sec timeout
}

final function ParseHeader( out string S )
{
	local int i;
	
	i = InStr(S,"Content-Length: ");
	if( i==-1 )
	{
		OnError("Received invalid HTML header:|"$S);
		return;
	}
	S = Mid(S,i+16);
	i = InStr(S,CRLF);
	if( i==-1 )
	{
		ContentLength = int(S);
		S = "";
	}
	else
	{
		ContentLength = int(Left(S,i));
		S = Mid(S,i+1);
		i = InStr(S,CRLF$CRLF);
		if( i==-1 )
			S = "";
		else S = Mid(S,i+Len(CRLF$CRLF));
	}
}
function ReceivedText(string Text)
{
	if( !bReceivedHeader )
	{
		bReceivedHeader = true;
		ParseHeader(Text);
	}
	InputBuffer $= Text;
	ContentLength-=Len(Text);
	if( ContentLength<=0 )
	{
		SetTimer(0,false);
		bHasData = true;
	}
}

function DestroyLink()
{
	SetTimer(0.0,False);

	if(IsConnected())
		Close();
	LifeSpan = 5;
}

function Timer()
{
	OnError("Connection timed out.");
}

function Closed()
{
	SetTimer(0.0,False);
	if( InputBuffer!="" )
		bHasData = true;
	else if( !bHasError )
		OnError("Connection closed without data received.");
}

defaultproperties
{
}