/*
MutSR_ServerPerks webadmin interface
*/
class MutSR_ServerPerkWebAdmin extends xWebQueryHandler;

var MutSR_ServerPerksMut Mut;
var string HomeURL,PerksURL,TraderCatURL,TraderInvURL;

function bool Init()
{
	foreach Level.AllActors( class'MutSR_ServerPerksMut', Mut )
		break;
	return true;
}
function Cleanup()
{
	Mut = None;
}

function bool Query(WebRequest Request, WebResponse Response)
{
	switch (Mid(Request.URI, 1))
	{
	case DefaultPage:
		RequestFrame(Request, Response);
		return true;
	case HomeURL:
		RequestMain(Request, Response);
		return true;
	case PerksURL:
		RequestPerks(Request, Response);
		return true;
	case TraderCatURL:
		TradetCat(Request, Response);
		return true;
	case TraderInvURL:
		RequestInventory(Request, Response);
		return true;
	}
	return false;
}

function RequestFrame(WebRequest Request, WebResponse Response)
{
	Response.SendText("<html><head><title>SP</title><meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\"></head>");
	Response.SendText("<frameset cols=\"*\" rows=\"*\" border=\"0\" scrolling=\"No\" frameborder=\"no\" noresize framespacing=\"0\" marginheight=\"0\">");
	Response.SendText("<frame src=\""$HomeURL$"\" name=\"main\" border=\"0\" frameborder=\"no\" noresize framespacing=\"0\" marginheight=\"0\"></frameset>");
	Response.SendText("<noframes><body bgcolor=\"#FFFFFF\"></body></noframes></html>");
}

final function SendHeader( WebResponse Response, optional bool bNoSettings )
{
	Response.SendText("<html><head><title>SP</title><meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\"><link rel=\"stylesheet\" type=\"text/css\" href=\""$SiteCSSFile$"\"></head><body bgcolor=\""$SiteBG$"\" topmargin=\"0\" leftmargin=\"0\" marginheight=\"0\" marginwidth=\"0\"><body><div align=\"center\"><table cellpadding=\"1\" cellspacing=\"2\" style=\"width:600px\">");
	if( !bNoSettings )
		Response.SendText("<form method=\"post\">");
}
final function SendSubmitButton( WebResponse Response )
{
	Response.SendText("<tr><td colspan=\"2\"><input type=\"submit\" name=\"submit\" value=\"Submit\" class=\"button\"></td></tr></form>");
}
final function SendFooter( WebResponse Response )
{
	Response.SendText("</table></div></body></html>");
}
final function SendHeaderLine( WebResponse Response, string S )
{
	Response.SendText("<tr><th colspan=\"2\">"$S$"</th></tr>");
}
final function SendURLLine( WebResponse Response, string URL, string DisplayStr )
{
	Response.SendText("<tr><td colspan=\"2\"><a href=\""$URL$"\">"$DisplayStr$"</a></td></tr>");
}
final function SendTableLine( WebResponse Response, string S )
{
	Response.SendText("<tr>"$S$"</tr>");
}

function RequestMain(WebRequest Request, WebResponse Response)
{
	SendHeader(Response,true);
	SendHeaderLine(Response,"MutSR_ServerPerks settings");
	SendURLLine(Response,PerksURL,"Edit perk classes");
	SendURLLine(Response,TraderCatURL,"Edit trader categories");
	SendURLLine(Response,TraderInvURL,"Edit trader inventory");
	SendFooter(Response);
}
function RequestPerks(WebRequest Request, WebResponse Response)
{
	local string S,Er;
	local array<string> PA;
	local int i,j;
	local class<MutSR_SRVeterancyTypes> VC;

	// Process response.
	if( Request.GetVariable("submit") == "Submit" )
	{
		S = Request.GetVariable("Perks", "");
		if( S!="" )
		{
			Split(S,Chr(13)$Chr(10),PA);
			if( PA.Length<=1 )
			{
				PA.Length = 0;
				Split(S,Chr(10),PA);
			}
			Class'MutSR_ServerPerksMut'.Default.Perks.Length = 0;
			for( i=0; i<PA.Length; ++i )
			{
				VC = class<MutSR_SRVeterancyTypes>(DynamicLoadObject(PA[i],Class'Class'));
				if( VC!=None )
				{
					Class'MutSR_ServerPerksMut'.Default.Perks.Length = j+1;
					Class'MutSR_ServerPerksMut'.Default.Perks[j++] = string(VC);
				}
				else if( Er=="" )
					Er = PA[i];
				else Er $= ", "$PA[i];
			}
			Class'MutSR_ServerPerksMut'.Static.StaticSaveConfig();
		}
	}

	SendHeader(Response);
	SendHeaderLine(Response,"Perk classes:");
	if( Er!="" )
		SendHeaderLine(Response,"<font color=\"red\">[Warning] Perk classes failed to load:<BR>"$Er$"</font>");
	
	// Send perk list
	for( i=0; i<Class'MutSR_ServerPerksMut'.Default.Perks.Length; ++i )
	{
		if( i==0 )
			S = Class'MutSR_ServerPerksMut'.Default.Perks[0];
		else S = S$Chr(10)$Class'MutSR_ServerPerksMut'.Default.Perks[i];
	}
	SendTableLine(Response,"<td colspan=\"3\"><textarea name=\"Perks\" rows=\"25\" cols=\"80\">"$S$"</textarea></td>");

	SendSubmitButton(Response);
	SendURLLine(Response,HomeURL,"Return to home");
	SendFooter(Response);
}
function TradetCat(WebRequest Request, WebResponse Response)
{
	local string S,D,A,B;
	local int i,j;

	// Process response.
	if( Request.GetVariable("submit") == "Submit" )
	{
		for( i=Class'MutSR_ServerPerksMut'.Default.WeaponCategories.Length; i>=0; --i )
		{
			j = int(Request.GetVariable("WI"$i, "-2"));
			if( j==-2 )
				continue;
			S = Request.GetVariable("WC"$i, "");
			
			if( S=="" || S=="NEW" )
			{
				if( i<Class'MutSR_ServerPerksMut'.Default.WeaponCategories.Length )
					Class'MutSR_ServerPerksMut'.Default.WeaponCategories.Remove(i,1);
			}
			else
			{
				if( j>=0 )
					S = string(j)$":"$S;
				if( i>=Class'MutSR_ServerPerksMut'.Default.WeaponCategories.Length )
					Class'MutSR_ServerPerksMut'.Default.WeaponCategories.Length = i+1;
				Class'MutSR_ServerPerksMut'.Default.WeaponCategories[i] = S;
			}
		}
		Class'MutSR_ServerPerksMut'.Static.StaticSaveConfig();
	}
	
	SendHeader(Response);
	SendHeaderLine(Response,"Trader categories:");
	
	// gather perks
	D = " ><option value=\"-1\">None</option>";
	for( i=0; i<Class'MutSR_ServerPerksMut'.Default.Perks.Length; ++i )
		D = D$"<option value=\""$i$"\">"$Class'MutSR_ServerPerksMut'.Default.Perks[i]$"</option>";
	D $= "<option value=\""$i$"\">Unperked</option></select>";

	// categories
	Response.SendText("<tr>"$S$"</tr>");
	for( i=0; i<=Class'MutSR_ServerPerksMut'.Default.WeaponCategories.Length; ++i )
	{
		S = "<tr><td><select class=\"mini\" name=\"WI"$i$"\""$D;
		if( i==Class'MutSR_ServerPerksMut'.Default.WeaponCategories.Length )
			B = "NEW";
		else
		{
			if( Divide(Class'MutSR_ServerPerksMut'.Default.WeaponCategories[i],":",A,B) )
			{
				j = int(A);
				if( j<Class'MutSR_ServerPerksMut'.Default.Perks.Length )
					A = ">"$Class'MutSR_ServerPerksMut'.Default.Perks[j]$"<";
				else A = ">Unperked<";
				S = Repl(S,A," selected=\"selected\""$A); // Shitty hack.
			}
			else B = Class'MutSR_ServerPerksMut'.Default.WeaponCategories[i];
		}
		S $= "</td><td><input class=\"textbox\" type=\"text\" name=\"WC"$i$"\" value=\""$B$"\" size=\"16\" maxlength=\"32\">";
		Response.SendText(S$"</td></tr>");
	}

	SendSubmitButton(Response);
	SendURLLine(Response,HomeURL,"Return to home");
	SendFooter(Response);
}
function RequestInventory(WebRequest Request, WebResponse Response)
{
	local string S,Er,A,B;
	local array<string> PA;
	local int i,j;
	local class<Pickup> PC;

	// Process response.
	if( Request.GetVariable("submit") == "Submit" )
	{
		S = Request.GetVariable("Inv", "");
		if( S!="" )
		{
			Split(S,Chr(13)$Chr(10),PA);
			if( PA.Length<=1 )
			{
				PA.Length = 0;
				Split(S,Chr(10),PA);
			}
			Class'MutSR_ServerPerksMut'.Default.TraderInventory.Length = 0;
			for( i=0; i<PA.Length; ++i )
			{
				if( !Divide(PA[i],":",A,B) )
				{
					A = "";
					B = PA[i];
				}
				else A $= ":";

				PC = class<Pickup>(DynamicLoadObject(B,Class'Class'));
				if( PC!=None )
				{
					Class'MutSR_ServerPerksMut'.Default.TraderInventory.Length = j+1;
					Class'MutSR_ServerPerksMut'.Default.TraderInventory[j++] = A$string(PC);
				}
				else if( Er=="" )
					Er = PA[i];
				else Er $= ", "$PA[i];
			}
			Class'MutSR_ServerPerksMut'.Static.StaticSaveConfig();
		}
	}

	SendHeader(Response);
	SendHeaderLine(Response,"Inventory classes:");
	if( Er!="" )
		SendHeaderLine(Response,"<font color=\"red\">[Warning] Pickup classes failed to load:<BR>"$Er$"</font>");
	
	// Send perk list
	for( i=0; i<Class'MutSR_ServerPerksMut'.Default.TraderInventory.Length; ++i )
	{
		if( i==0 )
			S = Class'MutSR_ServerPerksMut'.Default.TraderInventory[0];
		else S = S$Chr(10)$Class'MutSR_ServerPerksMut'.Default.TraderInventory[i];
	}
	SendTableLine(Response,"<td colspan=\"3\"><textarea name=\"Inv\" rows=\"25\" cols=\"80\">"$S$"</textarea></td>");

	SendSubmitButton(Response);
	SendURLLine(Response,HomeURL,"Return to home");
	SendFooter(Response);
}

defaultproperties
{
	DefaultPage="MutSR_ServerPerkWebAdmin"
	HomeURL="MutSR_ServerPerkMain"
	PerksURL="MutSR_ServerPerksPerks"
	TraderCatURL="MutSR_ServerPerksTraderCat"
	TraderInvURL="MutSR_ServerPerksTraderInv"
	Title="MutSR_ServerPerk"
}