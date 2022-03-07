//====================================================================
// HTML Text box, written by Marco
// Simply call SetContents to change window contents.
// Only callback available is for LaunchKFURL.
// ====================================================================
class MutSR_GUIHTMLTextBox extends GUIMultiComponent;

struct FTextLine
{
	var string Text,URL;
	var color Color,ALColor;
	var Font Font;
	var byte Align,FontSize;
	var int X,Y,XS,YS,Tab,TOffset;
	var byte LineSkips;
	var array<int> ImgList;
	var bool bHasURL,bSplit;
};
var array<FTextLine> Lines;

struct FImageEntry
{
	var Material Img;
	var int X,Y,XS,YS,YOffset,XOffset;
	var byte Align,Style;
};
var array<FImageEntry> Images;

var FImageEntry BgImage;
var float OldXSize,OldYSize;
var int YSize,HoverOverLinkLine,OldHoverLine;
var() Color BGColor;
var automated GUIScrollBarBase MyScrollBar;
var string TitleString;
var int CurTab;
var byte DefaultFontSize;
var bool bNeedsInit,bHasSplitLines,bNeedScrollbar;

function bool FocusFirst( GUIComponent Sender )
{
	if ( MyScrollBar != None )
		MyScrollBar.SetFocus(None);
	else Super(GUIComponent).SetFocus(None);
	return true;
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
	MyScrollBar.bTabStop = false;
	MyScrollBar.Refocus(Self);
}

final function int AddText( string Input, color TextColor, byte TextAlign, byte FontSize, out byte NumSkips )
{
	local int i;
	
	i = Lines.Length;
	Lines.Length = i+1;
	Lines[i].Text = Input;
	Lines[i].Color = TextColor;
	Lines[i].Align = TextAlign;
	Lines[i].FontSize = FontSize;
	Lines[i].LineSkips = NumSkips;
	Lines[i].Tab = CurTab;
	NumSkips = 0;
	return i;
}
final function string ParseLinkType( string URL )
{
	if( InStr(URL,"//")>0 )
		return URL;
	if( Left(URL,4)~="ftp." )
		return "ftp://"$URL;
	return "http://"$URL;
}
final function AddImage( string Input )
{
	local string Temp;
	local byte Align,Sty;
	local Material M;
	local int X,Y,XS,YS,i,j,z;

	Align = 3;
	Temp = GetOption(Input, "ALIGN=");
	if (Temp != "")
	{
		switch( Caps(Temp) )
		{
		case "LEFT":
		case "0":
			Align = 0;
			break;
		case "CENTER":
		case "1":
			Align = 1;
			break;
		case "RIGHT":
		case "2":
			Align = 2;
			break;
		}
	}
	Temp = GetOption(Input, "STYLE=");
	if (Temp != "")
	{
		switch( Caps(Temp) )
		{
		case "NORMAL":
		case "0":
			Sty = 0;
			break;
		case "STRETCH":
		case "1":
			Sty = 1;
			break;
		case "TILEDX":
		case "2":
			Sty = 2;
			break;
		case "TILEDY":
		case "3":
			Sty = 3;
			break;
		case "TILED":
		case "4":
			Sty = 4;
			break;
		}
	}
	Temp = GetOption(Input, "SRC=");
	if (Temp != "")
		M = Material(DynamicLoadObject(Temp,Class'Material'));
	if( M==None )
		M = Texture'DefaultTexture';
	X = int(GetOption(Input, "VSPACE="));
	Y = int(GetOption(Input, "HSPACE="));
	XS = int(GetOption(Input, "WIDTH="));
	YS = int(GetOption(Input, "HEIGHT="));
	
	if( XS==0 )
		XS = M.MaterialUSize();
	if( YS==0 )
		YS = M.MaterialVSize();
	
	i = Images.Length;
	Images.Length = i+1;
	Images[i].Img = M;
	Images[i].XOffset = X;
	Images[i].YOffset = Y;
	Images[i].XS = XS;
	Images[i].YS = YS;
	Images[i].Style = Sty;
	Images[i].Align = Align;
	j = Lines.Length-1;
	z = Lines[j].ImgList.Length;
	Lines[j].ImgList.Length = z+1;
	Lines[j].ImgList[z] = i;
}
final function SetContents( string Input )
{
	local string LeftText,HTML,RightText,Output,Temp,Link;
	local int Index;
	local color TextColor,LinkColor,ALinkColor,OrgTextColor;
	local byte Alignment,FontScaler,NextLineSkips;

	CurTab = 0;
	BGColor.A = 0;
	BgImage.Img = None;
	Lines.Length = 0;
	Images.Length = 0;
	TitleString = "";
	bHasSplitLines = false;
	bNeedsInit = true;
	
	// First remove new liners
	Input = Repl(Input, Chr(13)$Chr(10), "");
	Input = Repl(Input, Chr(13), "");
	Input = Repl(Input, Chr(10), "");
	Input = Repl(Input, Chr(9), "    ");
	Input = Repl(Input, "\\n", "<BR>");
	
	TextColor = Class'HUD'.Default.WhiteColor;
	OrgTextColor = Class'HUD'.Default.WhiteColor;
	LinkColor = Class'HUD'.Default.BlueColor;
	ALinkColor = Class'HUD'.Default.RedColor;
	FontScaler = 3;
	DefaultFontSize = 3;
	Index = -1;

	while (Input != "")
	{
		ParseHTML(Input, LeftText, HTML, RightText);

		switch (GetTag(HTML))
		{
			// multiline HTML tags
		case "P":
			Output $= LeftText;
			if( Output!="" )
			{
				Index = AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
				NextLineSkips = 2;
				Output = "";
			}
			else ++NextLineSkips;
			break;
		case "BR":
			Output $= LeftText;
			if( Output!="" )
			{
				Index = AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
				NextLineSkips = 1;
				Output = "";
			}
			else ++NextLineSkips;
			break;
		case "BODY":
			Temp = GetOption(HTML, "BGCOLOR=");
			if (Temp != "")
				BGColor = ParseColor(Temp);

			Temp = GetOption(HTML, "LINK=");
			if (Temp != "")
				LinkColor = ParseColor(Temp);

			Temp = GetOption(HTML, "ALINK=");
			if (Temp != "")
				ALinkColor = ParseColor(Temp);

			Temp = GetOption(HTML, "TEXT=");
			if (Temp != "")
			{
				TextColor = ParseColor(Temp);
				OrgTextColor = TextColor;
			}
			
			Temp = GetOption(HTML, "SIZE=");
			if (Temp != "")
			{
				FontScaler = int(Temp);
				DefaultFontSize = FontScaler;
			}
			
			Temp = GetOption(Input, "IMG=");
			if (Temp != "")
			{
				if( BGColor.A==0 )
					BGColor = Class'Hud'.Default.WhiteColor;
				BgImage.Img = Material(DynamicLoadObject(Temp,Class'Material'));
				if( BgImage.Img==None )
					BgImage.Img = Texture'DefaultTexture';
				BgImage.X = BgImage.Img.MaterialUSize();
				BgImage.Y = BgImage.Img.MaterialVSize();
				switch( Caps(GetOption(Input, "IMGSTYLE=")) )
				{
				case "TILED":
					BgImage.XS = BgImage.X;
					BgImage.YS = BgImage.Y;
					BgImage.Style = 1;
					Temp = GetOption(Input, "TILEX=");
					if (Temp != "")
						BgImage.XS = int(Temp);
					Temp = GetOption(Input, "TILEY=");
					if (Temp != "")
						BgImage.YS = int(Temp);
					break;
				case "FITX":
					BgImage.Style = 2;
					break;
				case "FITY":
					BgImage.Style = 3;
					break;
				default: // FIT
					BgImage.Style = 0;
				}
				BgImage.Align = 0;
				if( GetOption(Input, "IMGLOCK=")=="0" )
					BgImage.Align = 1;
			}
			Output $= LeftText;
			break;
		case "CENTER":
			Output $= LeftText;
			if ( Output!="" )
			{
				Index = AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
				Output = "";
			}
			NextLineSkips = Max(NextLineSkips,1);
			Alignment = 1;
			break;
		case "RIGHT":
			Output $= LeftText;
			if ( Output!="" )
			{
				Index = AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
				Output = "";
			}
			NextLineSkips = Max(NextLineSkips,1);
			Alignment = 2;
			break;
		case "/CENTER":
		case "/RIGHT":
			Index = AddText(Output $ LeftText,TextColor,Alignment,FontScaler,NextLineSkips);
			++NextLineSkips;
			Alignment = 0;
			Output = "";
			break;
			// Inline HTML tags
		case "H1":
			Output $= LeftText;
			if ( Output!="" )
			{
				Index = AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
				Output = "";
			}
			NextLineSkips = Max(NextLineSkips,1);
			FontScaler = 5;
			Alignment = 1;
			break;
		case "/H1":
			Index = AddText(Output $ LeftText,TextColor,Alignment,FontScaler,NextLineSkips);
			++NextLineSkips;
			Output = "";
			FontScaler = DefaultFontSize;
			Alignment = 0;
			break;
		case "FONT":
			Output $= LeftText;
			if( Output!="" )
			{
				Index = AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
				Output = "";
			}
			Temp = GetOption(HTML, "COLOR=");
			if (Temp != "")
				TextColor = ParseColor(Temp);
			Temp = GetOption(HTML, "SIZE=");
			if (Temp != "")
				FontScaler = int(Temp);
			break;
		case "/FONT":
			Output $= LeftText;
			if( Output!="" )
			{
				Index = AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
				Output = "";
			}
			TextColor = OrgTextColor;
			FontScaler = DefaultFontSize;
			break;
		case "TAB":
			Output $= LeftText;
			if( Output!="" )
			{
				Index = AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
				Output = "";
			}
			CurTab = int(GetOption(HTML, "X="));
			break;
		case "/TAB":
			Output $= LeftText;
			if( Output!="" )
			{
				Index = AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
				Output = "";
			}
			CurTab = 0;
			break;
		case "TITLE":
			Output $= LeftText;
			break;
		case "/TITLE":
			TitleString = LeftText;
			break;
		case "A":
			Output $= LeftText;
			if( Output!="" )
			{
				Index = AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
				Output = "";
			}
			Link = GetOption(HTML, "HREF=");
			break;
		case "/A":
			Output $= LeftText;
			Index = AddText(Output,LinkColor,Alignment,FontScaler,NextLineSkips);
			Lines[Index].ALColor = ALinkColor;
			Lines[Index].bHasURL = true;
			if( Link=="" )
				Lines[Index].URL = ParseLinkType(Output);
			else Lines[Index].URL = ParseLinkType(Link);
			Output = "";
			FontScaler = DefaultFontSize;
			Alignment = 0;
			break;
		case "IMG":
			Output $= LeftText;
			if( Output!="" || NextLineSkips>0 )
				AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
			Output = "";
			AddImage(HTML);
			break;
		default:
			Output = Output $ LeftText;
			break;
		}
		Input = RightText;
	}
	AddText(Output,TextColor,Alignment,FontScaler,NextLineSkips);
}

// Get the next HTML tag, the text before it and everthing after it.
final function ParseHTML(string Input, out string LeftText, out string HTML, out string RightText)
{
	local int i;

	i = InStr(Input, "<");
	if (i == -1)
	{
		LeftText = Input;
		HTML = "";
		RightText = "";
		return;
	}

	LeftText = Left(Input, i);
	HTML = Mid(Input, i);

	i = InStr(HTML, ">");
	if (i == -1)
	{
		RightText = "";
		return;
	}

	RightText = Mid(HTML, i+1);
	HTML = Left(HTML, i+1);
}
final function string GetTag(string HTML)
{
	local int i;

	if (HTML == "")
		return "";

	HTML = Mid(HTML, 1); // lose <

	i = FirstMatching(InStr(HTML, ">"), InStr(HTML, " "));
	if (i == -1)
		return Caps(HTML);
	else
		return Caps(Left(HTML, i));
}
final function string GetOption(string HTML, string Option)
{
	local int i, j;
	local string s;

	i = InStr(Caps(HTML), Caps(Option));

	if (i == 1 || Mid(HTML, i-1, 1) == " ")
	{
		s = Mid(HTML, i+Len(Option));
		j = FirstMatching(InStr(s, ">"), InStr(s, " "));
		s = Left(s, j);

		if (Left(s, 1) == "\"")
			s = Mid(s, 1);

		if (Right(s, 1) == "\"")
			s = Left(s, Len(s) - 1);

		return s;
	}
	return "";
}
final function int FirstMatching(int i, int j)
{
	if (i == -1)
		return j;
	if (j == -1)
		return i;
	return Min(i, j);
}
final function Color ParseColor(string S)
{
	local Color C;
	local int i;

	S = Caps(S);
	if (Left(S, 1) == "#")
	{
		C.R = (GetHexDigit(Mid(S, 1, 1)) << 4) + GetHexDigit(Mid(S, 2, 1));
		C.G = (GetHexDigit(Mid(S, 3, 1)) << 4) + GetHexDigit(Mid(S, 4, 1));
		C.B = (GetHexDigit(Mid(S, 5, 1)) << 4) + GetHexDigit(Mid(S, 6, 1));
	}
	else if (Left(S, 4) == "RGB(")
	{
		S = Mid(S, 4);
		i = InStr(S,",");
		C.R = int(Left(S,i));
		S = Mid(S,i+1);
		i = InStr(S,",");
		C.G = int(Left(S,i));
		C.B = int(Mid(S,i+1));
	}
	else
	{
		switch( S )
		{
		case "RED":
			C.R = 255;
			C.G = 0;
			C.B = 0;
			break;
		case "BLUE":
			C.R = 0;
			C.G = 0;
			C.B = 255;
			break;
		case "GREEN":
			C.R = 0;
			C.G = 255;
			C.B = 0;
			break;
		case "YELLOW":
			C.R = 255;
			C.G = 255;
			C.B = 0;
			break;
		case "BLACK":
			C.R = 0;
			C.G = 0;
			C.B = 0;
			break;
		default: // WHITE
			C.R = 255;
			C.G = 255;
			C.B = 255;
		}
	}
	C.A = 255;

	return C;
}
final function byte GetHexDigit(string D)
{
	local byte i;
	
	i = Asc(D);
	if( i>=48 && i<=57 ) // i>='0' && i<='9'
		return (i-48); // i-'0'
	return Min(i-55,15); // i-('A'-10)
}

function ResolutionChanged( int ResX, int ResY )
{
	bNeedsInit = true;
}

final function SplitLine( int iLine, int iOffset )
{
	local int i;
	local string S;

	++iLine;
	Lines.Insert(iLine,1);
	S = Lines[iLine-1].Text;
	for( i=iOffset; i<Len(S); ++i )
		if( Mid(S,i,1)!=" " )
			break;
	Lines[iLine].Text = Mid(S,i);
	Lines[iLine-1].Text = Left(S,iOffset);
	Lines[iLine].URL = Lines[iLine-1].URL;
	Lines[iLine].Color = Lines[iLine-1].Color;
	Lines[iLine].ALColor = Lines[iLine-1].ALColor;
	Lines[iLine].Align = Lines[iLine-1].Align;
	Lines[iLine].FontSize = Lines[iLine-1].FontSize;
	Lines[iLine].Tab = Lines[iLine-1].Tab;
	Lines[iLine].LineSkips = 1;
	Lines[iLine].bHasURL = Lines[iLine-1].bHasURL;
	Lines[iLine].bSplit = true;
	bHasSplitLines = true;
}
final protected function InitHTMLArea( Canvas C )
{
	local float XS,YS;
	local int i,j,X,Y,iStart,BestHeight,FontSize,PrevY,Remain,iLastWord,iLen,z,ImgHeight;

	// Used to detect resolution changes when text needs realignment.
	OldXSize = ActualWidth(WinWidth);
	OldYSize = ActualHeight(WinHeight);

	// Merge splitted lines again
	if( bHasSplitLines )
	{
		bHasSplitLines = false;
		for( i=1; i<Lines.Length; ++i )
		{
			if( Lines[i].bSplit )
			{
				Lines[i-1].Text @= Lines[i].Text;
				Lines.Remove(i--,1);
			}
		}
	}
	
	// Setup background image scaling
	if( BgImage.Img!=None )
	{
		switch( BgImage.Style )
		{
		case 1: // Tiled
			if( BgImage.X==BgImage.XS )
				BgImage.XOffset = C.ClipX;
			else
			{
				XS = C.ClipX / float(BgImage.XS) * float(BgImage.X);
				BgImage.XOffset = XS;
			}
			if( BgImage.Y==BgImage.YS )
				BgImage.YOffset = C.ClipY;
			else
			{
				XS = C.ClipY / float(BgImage.YS) * float(BgImage.Y);
				BgImage.YOffset = XS;
			}
			break;
		case 2: // Fit X
			XS = C.ClipY * (C.ClipX / float(BgImage.X));
			Log(XS);
			BgImage.YS = XS;
			break;
		case 3: // Fit Y
			XS = C.ClipX * (C.ClipY / float(BgImage.Y));
			Log(XS);
			BgImage.XS = XS;
			break;
		}
	}
	
	FontSize = -2;
	if ( C.SizeY < 480 )
		FontSize++;
	if ( C.SizeY < 600 )
		FontSize++;
	if ( C.SizeY < 800 )
		FontSize++;
	if ( C.SizeY < 1024 )
		FontSize++;
	if ( C.SizeY < 1250 )
		FontSize++;

	C.SetPos(0,0);
	if( Lines.Length>0 )
	{
		while( true )
		{
			if( i>=Lines.Length || (i>0 && Lines[i].LineSkips>0) )
			{
				for( j=iStart; j<i; ++j )
				{
					switch( Lines[j].Align )
					{
					case 0: // Left
						Lines[j].X = Lines[j].TOffset;
						break;
					case 1: // Center
						Lines[j].X = (C.ClipX-X+Lines[j].TOffset)/2;
						break;
					case 2: // Right
						Lines[j].X = C.ClipX-X+Lines[j].TOffset;
						break;
					}
				}
				if( i>=Lines.Length )
					break;
				X = 0;
				iStart = i;
				PrevY = BestHeight;
				BestHeight = 0;
			}
			if( Lines[i].FontSize>=247 )
				Lines[i].Font = Class'HUDKillingFloor'.Static.LoadFontStatic(Lines[i].FontSize-247);
			else Lines[i].Font = Class'HUDKillingFloor'.Static.LoadFontStatic(Clamp(8-(FontSize+Lines[i].FontSize),0,8));
			C.Font = Lines[i].Font;
			if( Lines[i].Text=="" )
			{
				C.TextSize("ABC",XS,YS);
				XS = 0;
			}
			else C.TextSize(Lines[i].Text,XS,YS);
			if( Lines[i].LineSkips>0 )
			{
				if( PrevY==0 )
					PrevY = YS;
				Y+=(PrevY*Lines[i].LineSkips);
			}
			X = Max(X,Lines[i].Tab);
			Lines[i].TOffset = X;
			Lines[i].Y = Y;
			Lines[i].YS = YS;
			BestHeight = Max(BestHeight,YS);
			if( (X+XS)>C.ClipX )
			{
				// Split to next row.
				Remain = C.ClipX-X;
				iLastWord = 0;
				iLen = Len(Lines[i].Text);
				for( j=1; j<iLen; ++j )
				{
					C.TextSize(Left(Lines[i].Text,j),XS,YS);
					if( Remain<XS )
					{
						if( iLastWord==0 ) // Must cut off a word now.
							SplitLine(i,Max(j-1,0));
						else SplitLine(i,iLastWord);
						break;
					}
					if( Mid(Lines[i].Text,j,1)==" " )
						iLastWord = j+1;
				}
				C.TextSize(Lines[i].Text,XS,YS);
			}
			Lines[i].XS = XS;
			X+=XS;
			
			for( j=0; j<Lines[i].ImgList.Length; ++j )
			{
				z = Lines[i].ImgList[j];
				if( Images[z].Align==3 )
					Images[z].X = X+Images[z].XOffset;
				else Images[z].X = Images[z].XOffset;
				Images[z].Y = Y+Images[z].YOffset;
				ImgHeight = Max(ImgHeight,Images[z].Y+Images[z].YS);
			}
			++i;
		}
		YSize = Max(Y+BestHeight,ImgHeight);
	}
	else YSize = 0;

	bNeedScrollbar = (YSize>C.ClipY);
	if( bNeedScrollbar )
	{
		MyScrollBar.EnableMe();
		MyScrollBar.Step = 16;
		MyScrollBar.BigStep = 512;
		MyScrollBar.ItemCount = YSize;
		MyScrollBar.ItemsPerPage = C.ClipY;
		MyScrollBar.UpdateGripPosition(0);
	}
	else MyScrollBar.DisableMe();
}
simulated final function DrawTileStretchedClipped( Canvas C, Material M, float XS, float YS )
{
	C.CurX += C.OrgX;
	C.CurY += C.OrgY;
	if( C.CurX<C.OrgX )
	{
		XS-=(C.OrgX-C.CurX);
		C.CurX = C.OrgX;
	}
	if( C.CurY<C.OrgY )
	{
		YS-=(C.OrgY-C.CurY);
		C.CurY = C.OrgY;
	}
	if( (C.CurX+XS)>C.ClipX )
		XS = (C.ClipX-C.CurX);
	if( (C.CurY+YS)>C.ClipY )
		YS = (C.ClipY-C.CurY);
	C.DrawTileStretched(M,XS,YS);
}
function bool RenderHTMLText( canvas C )
{
	local float CX,CY,YS;
	local int i,YOffset,MX,MY;
	local bool bMouseOnClient;

	CX = C.ClipX;
	CY = C.ClipY;
	C.OrgX = ActualLeft(WinLeft);
	C.OrgY = ActualTop(WinTop);
	C.ClipX = ActualWidth(WinWidth)-MyScrollBar.ActualWidth(MyScrollBar.WinWidth);
	C.ClipY = ActualHeight(WinHeight);

	if( bNeedsInit || OldXSize!=ActualWidth(WinWidth) || OldYSize!=ActualHeight(WinHeight) )
	{
		bNeedsInit = false;
		InitHTMLArea(C);
	}
	if( bNeedScrollbar )
		YOffset = MyScrollBar.CurPos;

	C.Style = 5; // STY_Alpha

	if( BGColor.A>0 )
	{
		C.SetPos(0,0);
		C.DrawColor = BGColor;
		
		if( BgImage.Img!=None )
		{
			if( BgImage.Align==1 ) // not locked on screen.
				MX = YOffset;
			switch( BgImage.Style )
			{
			case 0: // Stretched to fit
				C.DrawTileClipped(BgImage.Img,C.ClipX,C.ClipY,0,MX,BgImage.X,BgImage.Y);
				break;
			case 1: // Tiled
				C.DrawTileClipped(BgImage.Img,C.ClipX,C.ClipY,0,MX,BgImage.XOffset,BgImage.YOffset);
				break;
			case 2: // Fit X
				C.DrawTileClipped(BgImage.Img,C.ClipX,C.ClipY,0,MX,BgImage.X,BgImage.YS);
				break;
			case 3: // Fit Y
				C.DrawTileClipped(BgImage.Img,C.ClipX,C.ClipY,0,MX,BgImage.XS,BgImage.Y);
				break;
			}
		}
		else C.DrawTile(Texture'WhiteTexture',C.ClipX,C.ClipY,0,0,1,1);
	}
	MX = Controller.MouseX-C.OrgX;
	MY = Controller.MouseY-C.OrgY;
	bMouseOnClient = (MX>=0 && MX<=C.ClipX && MY>=0 && MY<=C.ClipY);
	HoverOverLinkLine = -1;
	MY+=YOffset;

	C.DrawColor = Class'HUD'.Default.WhiteColor;
	for( i=0; i<Images.Length; ++i )
	{
		C.CurY = Images[i].Y-YOffset;
		if( (C.CurY+Images[i].YS)<0 || C.CurY>C.ClipY )
			continue;
		switch( Images[i].Align )
		{
		case 0: // Left
		case 3: // Unaligned, postition after text.
			C.CurX = 0;
			break;
		case 1: // Center
			C.CurX = (C.ClipX-Images[i].XS)/2;
			break;
		case 1: // Right
			C.CurX = C.ClipX-Images[i].XS;
			break;
		}
		C.CurX += Images[i].X;
		switch( Images[i].Style )
		{
		case 1: // Stretched
			DrawTileStretchedClipped(C,Images[i].Img,Images[i].XS,Images[i].YS);
			break;
		case 2: // Tiled on X axis
			C.DrawTileClipped(Images[i].Img,Images[i].XS,Images[i].YS,0,0,Images[i].XS,Images[i].Img.MaterialVSize());
			break;
		case 3: // Tiled on Y axis
			C.DrawTileClipped(Images[i].Img,Images[i].XS,Images[i].YS,0,0,Images[i].Img.MaterialUSize(),Images[i].YS);
			break;
		case 4: // Fully tiled
			C.DrawTileClipped(Images[i].Img,Images[i].XS,Images[i].YS,0,0,Images[i].XS,Images[i].YS);
			break;
		default: // Normal
			C.DrawTileClipped(Images[i].Img,Images[i].XS,Images[i].YS,0,0,Images[i].Img.MaterialUSize(),Images[i].Img.MaterialVSize());
		}
	}

	for( i=0; i<Lines.Length; ++i )
	{
		C.SetPos(Lines[i].X,Lines[i].Y-YOffset);
		if( (C.CurY+Lines[i].YS)<0 || Lines[i].Text=="" )
			continue;
		if( C.CurY>C.ClipY )
			break;
		
		// Check if mouse hovers over URL
		if( bMouseOnClient && Lines[i].bHasURL && MX>=Lines[i].X && MX<=(Lines[i].X+Lines[i].XS)
												&& MY>=Lines[i].Y && MY<=(Lines[i].Y+Lines[i].YS) )
		{
			HoverOverLinkLine = i;
			bMouseOnClient = false; // No need to check on rest anymore.
			C.DrawColor = Lines[i].ALColor;
		}
		else C.DrawColor = Lines[i].Color;

		C.Font = Lines[i].Font;
		C.DrawTextClipped(Lines[i].Text);
		if( Lines[i].bHasURL )
		{
			YS = Max(Lines[i].YS/15,1);
			C.SetPos(Lines[i].X,Lines[i].Y+Lines[i].YS-(YS*2)-YOffset);
			if( C.CurY<C.ClipY )
				C.DrawTileClipped(Texture'WhiteTexture',Lines[i].XS,YS,0,0,1,1);
		}
	}

	if( OldHoverLine!=HoverOverLinkLine )
	{
		OldHoverLine = HoverOverLinkLine;
		if( HoverOverLinkLine>=0 )
		{
			Controller.PlayInterfaceSound(CS_Hover);
			SetToolTipText(Lines[HoverOverLinkLine].URL);
		}
		else SetToolTipText("");
	}

	C.OrgX = 0;
	C.OrgY = 0;
	C.ClipX = CX;
	C.ClipY = CY;
	
	return false;
}

function bool LaunchURL(GUIComponent Sender)
{
	if( HoverOverLinkLine>=0 )
	{
		if( Left(Lines[HoverOverLinkLine].URL,8)~="kfurl://" )
			LaunchKFURL(Mid(Lines[HoverOverLinkLine].URL,8));
		else if( Left(Lines[HoverOverLinkLine].URL,5)~="kf://" )
			ChangeGameURL(Mid(Lines[HoverOverLinkLine].URL,5));
		else LaunchURLPage(Lines[HoverOverLinkLine].URL);
	}
    return true;
}

delegate LaunchKFURL( string URL );
delegate ChangeGameURL( string URL )
{
	Class'MutSR_SRLevelCleanup'.Static.AddSafeCleanup(PlayerOwner(),URL);
}
delegate LaunchURLPage( string URL )
{
	PlayerOwner().Player.Console.DelayedConsoleCommand("START "$URL);
}

defaultproperties
{
	bNeedsInit=true

	PropagateVisibility=true
	OnDraw=RenderHTMLText
	OnClick=LaunchURL
	Begin Object Class=GUIVertScrollBar Name=TheScrollbar
		bBoundToParent=true
		bScaleToParent=true
		WinWidth=0.03
		WinLeft=0.97
		WinTop=0.0
		WinHeight=1.0
		bVisible=true
		PropagateVisibility=true
		OnPreDraw=TheScrollbar.GripPreDraw
	End Object
	MyScrollBar=TheScrollbar
	StyleName="NoBackground"
	bAcceptsInput=True
	Begin Object Class=GUIToolTip Name=GUIListBoxBaseToolTip
		ExpirationSeconds=0
	End Object
	ToolTip=GUIListBoxBaseToolTip
}