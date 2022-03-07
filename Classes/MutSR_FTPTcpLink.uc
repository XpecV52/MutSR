Class MutSR_FTPTcpLink extends TcpLink;

var string TempFileName;
var array<MutSR_ServerStStats> PendingLoaders;
var array<MutSR_StatsObject> ToSave;
var MutSR_ServerPerksMut Mut;
var IpAddr SiteAddress;
var MutSR_FTPDataConnection DataConnection;
var transient float WelcomeTimer;
var array<string> TotalList;
var PlayerController WebAdminController;
var int IgnoreDateNum;
var byte RetryCounter;
var bool bConnectionBroken,bFullVerbose,bUploadAllStats,bTotalUpload,bFileInProgress,bLogAllCommands,bCheckedWeb,bPostUploadCheck,bIsAsciiMode,bObtainDir;

function BeginEvent()
{
	Mut.SaveAllStats = SaveAllStats;
	Mut.RequestStats = RequestStats;
	if( Mut.bDebugDatabase )
	{
		bLogAllCommands = true;
		bFullVerbose = true;
	}

	LinkMode = MODE_Line;
	ReceiveMode = RMODE_Event;
	Resolve(Mut.RemoteDatabaseURL);
}
final function ReportError( int Code, string InEr )
{
	if( !bConnectionBroken )
	{
		Level.Game.Broadcast(Self,Code$" FTP Error: "$InEr);
		Log(Code$" FTP Error: "$InEr,Class.Name);
	}
	bConnectionBroken = true;
	GoToState('ErrorState');
}
event Resolved( IpAddr Addr )
{
	SiteAddress = Addr;
	SiteAddress.Port = Mut.RemotePort;
	GoToState('Idle');
}
event ResolveFailed()
{
	ReportError(0,"Couldn't resolve address, aborting...");
}
event Closed()
{
	ReportError(1,"Connection was closed by FTP server!");
}
final function DebugLog( string Str )
{
	if( !bCheckedWeb )
	{
		bCheckedWeb = true;
		foreach DynamicActors(class'PlayerController',WebAdminController)
			if( WebAdminController.IsA('MessagingSpectator') )
				break;
		//if( Level.NetMode==NM_StandAlone )
		//	WebAdminController = Level.GetLocalPlayerController();
	}
	if( WebAdminController!=None )
		WebAdminController.ClientMessage(Str,'FTP');
	Log(Str,'FTP');
}
event ReceivedLine( string Text )
{
	if( bLogAllCommands )
		DebugLog("ReceiveFTP "$GetStateName()$":"@Text);
	ProcessResponse(int(Left(Text,3)),Mid(Text,4));
}
final function SendFTPLine( string Text )
{
	if( bLogAllCommands )
		DebugLog("SendFTP "$GetStateName()$":"@Text);
	SendText(Text);
}

function SaveAllStats()
{
	local int i;

	if( bTotalUpload )
		return;
	ToSave = Mut.ActiveStats;
	for( i=0; i<ToSave.Length; ++i )
	{
		if( !ToSave[i].bStatsChanged )
			ToSave.Remove(i--,1);
	}
	if( ToSave.Length>0 )
		bUploadAllStats = true;
}
function RequestStats( MutSR_ServerStStats Other )
{
	local int i;
	
	if( bTotalUpload )
		return;
	for( i=0; i<PendingLoaders.Length; ++i )
	{
		if( PendingLoaders[i]==None )
			PendingLoaders.Remove(i--,1);
		else if( PendingLoaders[i]==Other )
			return;
	}
	PendingLoaders[PendingLoaders.Length] = Other;
}
final function FullUpload()
{
	if( Class'MutSR_ServerPerksMut'.Default.FTPUploadAllIgnoreDate!="" )
	{
		bObtainDir = true;
		IgnoreDateNum = GetDateInt(int(Mid(Class'MutSR_ServerPerksMut'.Default.FTPUploadAllIgnoreDate,6,2)),int(Mid(Class'MutSR_ServerPerksMut'.Default.FTPUploadAllIgnoreDate,4,2)),int(Mid(Class'MutSR_ServerPerksMut'.Default.FTPUploadAllIgnoreDate,0,4)));
	}

	TotalList = GetPerObjectNames("MutSR_ServerPerksStat","StatsObject",9999999);
	bTotalUpload = true;
	bUploadAllStats = true;
	bFullVerbose = true;
	HasMoreStats();
	SaveAllStats();
}
final function bool HasMoreStats()
{
	local byte i;
	local int j;
	
	if( TotalList.Length==0 )
		return false;
	j = ToSave.Length;
	for( i=0; i<Min(20,TotalList.Length); ++i )
	{
		ToSave.Length = j+1;
		ToSave[j] = new(None,TotalList[i]) Class'MutSR_StatsObject';
		++j;
	}
	TotalList.Remove(0,20);
	return true;
}
final function CheckNextCommand()
{
	if( bObtainDir )
	{
		GoToState('GetDir');
		return;
	}
	while( PendingLoaders.Length>0 && PendingLoaders[0]==None )
		PendingLoaders.Remove(0,1);

	if( bUploadAllStats || (bTotalUpload && HasMoreStats()) )
		GoToState('UploadStats','Begin');
	else if( PendingLoaders.Length>0 )
		GoToState('DownloadStats','Begin');
	else
	{
		if( bFullVerbose )
			Level.Game.Broadcast(Self,"FTP: All done!");
		if( Mut.FTPKeepAliveSec>0 && !Level.Game.bGameEnded )
			GoToState('KeepAlive');
		else GoToState('EndConnection');
	}
}
function ProcessResponse( int Code, string Line )
{
	switch( Code )
	{
	case 220: // Welcome
		if( WelcomeTimer<Level.TimeSeconds )
		{
			SendFTPLine("USER "$Mut.RemoteFTPUser);
			WelcomeTimer = Level.TimeSeconds+0.2;
		}
		break;
	case 331: // Password required
		SendFTPLine("PASS "$Mut.RemotePassword);
		break;
	case 230: // User logged in.
		if( Mut.RemoteFTPDir!="" )
			SendFTPLine("CWD "$Mut.RemoteFTPDir);
		else
		{
			SendFTPLine("TYPE A");
			bIsAsciiMode = true;
		}
		break;
	case 250: // CWD command successful.
		SendFTPLine("TYPE A");
		bIsAsciiMode = true;
		break;
	case 200: // Type set to A
		CheckNextCommand();
		break;
	case 226: // File successfully transferred
	case 150: // Opening ASCII mode data connection
	case 221: // Good-bye
		break;
	case 421: // No transfer timeout: closing control connection
		if( bFullVerbose )
			Level.Game.Broadcast(Self,"FTP: Connection timed out, reconnecting!");
		GoToState('EndConnection');
		break;
	case 221: // Good-bye
		Close();
		break;
	default:
		if( bFullVerbose )
			Level.Game.Broadcast(Self,"FTP: Unknown FTP code '"$Code$"': "$Line);
		Log("Unknown FTP code '"$Code$"': "$Line,Class.Name);
	}
}
function DataReceived();

function DataProgress()
{
	SetTimer(60,false);
}

final function bool OpenDataConnection( string S, bool bUpload )
{
	local int i,j;
	local IpAddr A;

	A = SiteAddress;
	
	// Get destination port
	S = Mid(S,InStr(S,"(")+1);
	for( i=0; i<4; ++i ) // Skip IP address
		S = Mid(S,InStr(S,",")+1);
	i = InStr(S,",");
	A.Port = int(Left(S,i))*256 + int(Mid(S,i+1));
	
	// Now attempt to bind port and open connection.
	for( j=0; j<20; ++j )
	{
		if( DataConnection!=None )
			DataConnection.Destroy();
		DataConnection = Spawn(Class'MutSR_FTPDataConnection',Self);
		DataConnection.bUpload = bUpload;
		DataConnection.BindPort();
		if( DataConnection.Open(A) )
		{
			DataConnection.OnCompleted = DataReceived;
			DataConnection.OnProgress = DataProgress;
			return true;
		}
	}
	DataConnection.Destroy();
	DataConnection = None;
	ReportError(2,"Couldn't bind port for upload data connection!");
	return false;
}

function Timer()
{
	ReportError(3,"FTP connection timed out!");
}

state Idle
{
Ignores Timer;

	final function StartConnection()
	{
		local int i;
		
		for( i=0; i<40; ++i )
		{
			BindPort();
			if( Open(SiteAddress) )
			{
				GoToState('InitConnection');
				return;
			}
		}
		ReportError(4,"Port couldn't be bound or connection failed to open!");
	}
	function SaveAllStats()
	{
		Global.SaveAllStats();
		if( bUploadAllStats )
			StartConnection();
	}
	function RequestStats( MutSR_ServerStStats Other )
	{
		Global.RequestStats(Other);
		StartConnection();
	}
Begin:
	Sleep(0.1f);
	if( bUploadAllStats || PendingLoaders.Length>0 )
		StartConnection();
}
state InitConnection
{
	function BeginState()
	{
		SetTimer(10,false);
	}
	event Closed()
	{
		ReportError(5,"Connection was closed by FTP server!");
	}
Begin:
	Sleep(5.f);
	SendFTPLine("USER "$Mut.RemoteFTPUser);
}
state ConnectionBase
{
	event Closed()
	{
		GoToState('Idle');
	}
Begin:
	while( true )
	{
		if( bUploadAllStats && Level.bLevelChange ) // Delay mapchange until all stats are uploaded.
			Level.NextSwitchCountdown = FMax(Level.NextSwitchCountdown,1.f);
		Sleep(0.5);
	}
}
state EndConnection extends ConnectionBase
{
	function BeginState()
	{
		SendFTPLine("QUIT");
		SetTimer(4,false);
	}
}
state KeepAlive extends ConnectionBase
{
Ignores Timer;

	function SaveAllStats()
	{
		Global.SaveAllStats();
		if( bUploadAllStats )
			StartConnection();
	}
	function RequestStats( MutSR_ServerStStats Other )
	{
		Global.RequestStats(Other);
		StartConnection();
	}
	final function StartConnection()
	{
		CheckNextCommand();
	}
Begin:
	while( true )
	{
		if( bUploadAllStats || PendingLoaders.Length>0 )
			StartConnection();
		Sleep(Mut.FTPKeepAliveSec);
		SendFTPLine("NOOP");
	}
}
state UploadStats extends ConnectionBase
{
	function BeginState()
	{
		bUploadAllStats = false;
		SetTimer(10,false);
	}
	function SaveAllStats();
	
	final function InitDataConnection( string S )
	{
		if( bFullVerbose )
			Level.Game.Broadcast(Self,"FTP: Upload stats for "$ToSave[0].PlayerName$" ("$(ToSave.Length-1+TotalList.Length)$" remains)");
		if( OpenDataConnection(S,true) )
		{
			DataConnection.Data = ToSave[0].GetSaveData();
			TempFileName = ToSave[0].Name$".txt.tmp";
			SendFTPLine("STOR "$TempFileName);
			bFileInProgress = true;
		}
	}
	final function NextPackage()
	{
		RetryCounter = 0;
		ToSave[0].bStatsChanged = false;
		ToSave.Remove(0,1);
		if( ToSave.Length==0 )
			CheckNextCommand();
		else if( !bIsAsciiMode )
		{
			bIsAsciiMode = true;
			SendFTPLine("TYPE A");
		}
		else SendFTPLine("PASV");
	}
	function ProcessResponse( int Code, string Line )
	{
		switch( Code )
		{
		case 200: // Type set to A/I
			if( bPostUploadCheck )
			{
				SetTimer(5,false);
				SendFTPLine("SIZE "$TempFileName);
			}
			else SendFTPLine("PASV");
			break;
		case 227: // Entering passive mode
			if( !bFileInProgress )
				InitDataConnection(Line);
			break;
		case 150: // Opening ASCII mode data connection for file
			SetTimer(60,false);
			if( DataConnection!=None )
				DataConnection.BeginUpload();
			break;
		case 226: // File transfer completed.
			if( bFileInProgress )
			{
				SetTimer(5,false);
				bFileInProgress = false;
				bPostUploadCheck = true;
				SendFTPLine("TYPE I");
				bIsAsciiMode = false;
			}
			break;
		case 213: // File size response.
			if( bPostUploadCheck )
			{
				SetTimer(5,false);
				if( int(Line)<=5 )
				{
					bPostUploadCheck = false;
					if( ++RetryCounter>=5 )
						NextPackage();
					else
					{
						if( bFullVerbose )
							Level.Game.Broadcast(Self,"213 FTP Error: Stats upload failed for "$ToSave[0].PlayerName$" retrying...");
						SendFTPLine("PASV");
					}
				}
				else SendFTPLine("RNFR "$TempFileName);
			}
			break;
		case 350: // Rename accepted.
			if( bPostUploadCheck )
			{
				SetTimer(5,false);
				SendFTPLine("RNTO "$Left(TempFileName,Len(TempFileName)-4));
			}
			break;
		case 250: // File successfully renamed or moved
			NextPackage();
			break;
		case 550: // Sorry, but that file doesn't exist
			if( bPostUploadCheck )
			{
				SetTimer(5,false);
				bPostUploadCheck = false;
				if( ++RetryCounter>=5 )
					NextPackage();
				else
				{
					if( bFullVerbose )
						Level.Game.Broadcast(Self,"550 FTP Error: Stats upload failed for "$ToSave[0].PlayerName$" retrying...");
					SendFTPLine("PASV");
				}
			}
			break;
		default:
			Global.ProcessResponse(Code,Line);
		}
	}
Begin:
	if( !bIsAsciiMode )
	{
		SendFTPLine("TYPE A");
		bIsAsciiMode = true;
	}
	else SendFTPLine("PASV");
	while( true )
	{
		if( Level.bLevelChange ) // Delay mapchange until all stats are uploaded.
		{
			bFullVerbose = true;
			Level.NextSwitchCountdown = FMax(Level.NextSwitchCountdown,1.f);
		}
		Sleep(0.5);
	}
}
state DownloadStats extends ConnectionBase
{
	function BeginState()
	{
		SetTimer(10,false);
	}
	final function InitDataConnection( string S )
	{
		while( PendingLoaders.Length>0 && PendingLoaders[0]==None )
			PendingLoaders.Remove(0,1);
		if( PendingLoaders.Length==0 )
		{
			CheckNextCommand();
			return;
		}

		if( bFullVerbose )
			Level.Game.Broadcast(Self,"FTP: Download stats for "$PendingLoaders[0].MyStatsObject.PlayerName$" ("$(PendingLoaders.Length-1)$" remains)");

		if( OpenDataConnection(S,false) )
		{
			SendFTPLine("RETR "$PendingLoaders[0].MyStatsObject.Name$".txt");
			bFileInProgress = true;
		}
	}
	function DataReceived()
	{
		bFileInProgress = false;
		if( PendingLoaders[0]!=None )
		{
			if( DataConnection!=None )
				PendingLoaders[0].GetData(DataConnection.Data);
			else PendingLoaders[0].GetData("");
		}
		PendingLoaders.Remove(0,1);
		while( PendingLoaders.Length>0 && PendingLoaders[0]==None )
			PendingLoaders.Remove(0,1);

		if( bUploadAllStats ) // Saving has higher priority.
			GoToState('UploadStats');
		else if( PendingLoaders.Length>0 )
			SendFTPLine("PASV");
		else CheckNextCommand();
	}
	function ProcessResponse( int Code, string Line )
	{
		switch( Code )
		{
		case 200: // Type set to A
			SendFTPLine("PASV");
			break;
		case 227: // Entering passive mode
			if( !bFileInProgress )
				InitDataConnection(Line);
			break;
		case 150: // Opening ASCII mode data connection for file
			SetTimer(60,false);
			break;
		case 550: // No such file or directory
			SetTimer(10,false);
			if( bFileInProgress )
			{
				if( DataConnection!=None )
					DataConnection.Destroy();
				DataReceived();
			}
			break;
		default:
			Global.ProcessResponse(Code,Line);
		}
	}
Begin:
	if( !bIsAsciiMode )
	{
		bIsAsciiMode = true;
		SendFTPLine("TYPE A");
	}
	else SendFTPLine("PASV");
	while( true )
	{
		if( bUploadAllStats && Level.bLevelChange ) // Delay mapchange until all stats are uploaded.
		{
			bFullVerbose = true;
			Level.NextSwitchCountdown = FMax(Level.NextSwitchCountdown,1.f);
		}
		Sleep(0.5);
	}
}
state ErrorState
{
Ignores SaveAllStats,RequestStats;
Begin:
	Sleep(1.f);
	Mut.RespawnNetworkLink();
}

static final function int GetDateInt( int Day, int Month, int Year )
{
	return Day + (Month*31) + (Year*366);
}
state GetDir
{
	function BeginState()
	{
		SendFTPLine("TYPE I");
		bObtainDir = false;
	}
	final function BeginPassiveCon( string S )
	{
		if( bFullVerbose )
			Level.Game.Broadcast(Self,"FTP: Get directory");

		if( OpenDataConnection(S,false) )
			SendFTPLine("MLSD");
	}
	function DataReceived()
	{
		local array<string> SA;
		local string S;
		local int i,j,Da,Mo,Ye,ol;

		if( DataConnection!=None )
		{
			Split(DataConnection.Data,Chr(13)$Chr(10),SA);
			ol = TotalList.Length;
			for( i=0; i<SA.Length; ++i )
			{
				S = SA[i];
				j = InStr(S,"modify=");
				if( j==-1 )
					continue;
				S = Mid(S,j+7);
				j = InStr(S,";");
				if( j==-1 )
					continue;
				Ye = int(Mid(S,0,4));
				Mo = int(Mid(S,4,2));
				Da = int(Mid(S,6,2));
				j = InStr(S," ");
				if( j==-1 )
					continue;
				S = Mid(S,j+1);
				if( Right(S,4)!=".txt" )
					continue;
				if( IgnoreDateNum<=GetDateInt(Da,Mo,Ye) )
					Log(S@"is newer: "$Da$"."$Mo$"."$Ye);
				else
				{
					S = Left(S,Len(S)-4);
					for( j=0; j<TotalList.Length; ++j )
						if( TotalList[j]==S )
						{
							TotalList.Remove(j,1);
							break;
						}
				}
			}
			Level.Game.Broadcast(Self,"Reduced list size: "$ol$" -> "$TotalList.Length);
		}
		CheckNextCommand();
	}
	function ProcessResponse( int Code, string Line )
	{
		switch( Code )
		{
		case 200: // Type set to I
			bIsAsciiMode = false;
			SendFTPLine("PASV");
			break;
		case 227: // Entering passive mode
			BeginPassiveCon(Line);
			break;
		case 150: // Opening ASCII mode data connection for file
			SetTimer(120,false);
			break;
		case 550: // No such file or directory
			SetTimer(10,false);
			if( bFileInProgress )
			{
				if( DataConnection!=None )
					DataConnection.Destroy();
				DataReceived();
			}
			break;
		default:
			Global.ProcessResponse(Code,Line);
		}
	}
}

defaultproperties
{
}