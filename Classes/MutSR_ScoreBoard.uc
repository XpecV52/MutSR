class MutSR_ScoreBoard extends KFScoreBoardNew;

#exec TEXTURE IMPORT COMPRESS NAME="Box" FILE="Textures\Box.dds" FORMAT=DXT5

// #exec OBJ LOAD FILE="Maniac_VetIcon.utx" Package="MutSR"

var localized string NotShownInfo,PlayerCountText,SpectatorCountText,AliveCountText,BotText,PlayerTimeText;
var Color GrayColor;
var Color Blue;
var Color DarkGrayColor;//Ast
var Color YellowColor;//Time
var Color GoldColor;//Dosh
var Color OrangeRedColor;//Title
var Color PurpleColor;//Kill


struct ColorRecord
{
    var string Color;
    var string Tag;
    var string RGB;
};
var config array<ColorRecord> ColorList;
var array<string> colorCodes;
var bool bMadeColorCodes;
var string PN,CurrentDiffString;


function string GetDateString()
{
    local string DateString;

    DateString = "DATE:";
    switch(Level.DayOfWeek)
    {
        case 0:
            DateString @= "SUNDAY";
            break;
        case 1:
            DateString @= "MONDAY";
            break;
        case 2:
            DateString @= "TUESDAY";
            break;
        case 3:
            DateString @= "WEDNESDAY";
            break;
        case 4:
            DateString @= "THURSDAY";
            break;
        case 5:
            DateString @= "FRIDAY";
            break;
        case 6:
            DateString @= "SATUDAY";
            break;
        default:
            break;
    }//sat | 09M-10D-2020Y | 15:
    //Year
    DateString @= ("|" $ string(Level.Year));
    //Mon
    if(Level.Month < 10)
        DateString $= ("/" $ "0" $ string(Level.Month));
    else
        DateString $= ("/" $ string(Level.Month));
        
    //Day
    if(Level.Day < 10)
        DateString $= ("/" $ "0" $ string(Level.Day));
    else
        DateString $= ("/" $ string(Level.Day));
        
    //Time
    if(Level.Hour < 10)
        DateString @= ("|" @ "0" $ string(Level.Hour));
    else
        DateString @= ("|" @ string(Level.Hour));
    if(Level.Minute < 10)
        DateString $= (":" $ "0" $ string(Level.Minute));
    else
        DateString $= (":" $ string(Level.Minute));
    if(Level.Second < 10)
        DateString $= (":" $ "0" $ string(Level.Second));
    else
        DateString $= (":" $ string(Level.Second));
    return DateString;
}

function string GetGameDifficulty()
{   
    switch(KFGameReplicationInfo(Level.GRI).GameDiff)
    {
        case 1:
            return "PATHETIC";
            break;
        case 2:
            return "NORMAL";
            break;
        case 4:
            return "HARD";
            break;
        case 5:
            return "SUICIDAL";
            break;
        case 7:
            return "INFERNAL";
            break;
        default:
            return "NULL";
            break;
    }
}


/* function string GetGameAcronym()
{
	if(GRI != none && ManiacScoreBoardGameReplicationInfo(GRI).ReplicatedGameConfigAcronym != "")
    {
		return ManiacScoreBoardGameReplicationInfo(GRI).ReplicatedGameConfigAcronym;
    }
    else if(GRI != none)
	{
		return "DEFAULT";
	}
} */


function DrawTitle(Canvas Canvas, float HeaderOffsetY, float PlayerAreaY, float PlayerBoxSizeY)
{
    local string CurrentGameString, CurrentDateString, scoreinfostring, RestartString;
    local float CurrentGameXL, CurrentGameYL, CurrentDateXL, CurrentDateYL, ScoreInfoXL, ScoreInfoYL,
	    TitleYPos, DrawYPos;

	// CurrentVoteString = GetGameAcronym();
	CurrentDiffString = GetGameDifficulty();
    CurrentDateString = GetDateString();
    CurrentGameString = "GAME:" @ /* CurrentVoteString$"-"$ */CurrentDiffString @ "|" @ "WAVE" @ string(InvasionGameReplicationInfo(GRI).WaveNumber + 1)$"/"$string(InvasionGameReplicationInfo(GRI).FinalWave) @ "|" @ Level.Title;
    Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);
    if(GRI.TimeLimit != 0)
    {
        scoreinfostring = TimeLimit $ (FormatTime(GRI.RemainingTime));
    }
    else
    {
        scoreinfostring = FooterText @ (FormatTime(GRI.ElapsedTime));
    }
    if(UnrealPlayer(Owner).bDisplayLoser)
    {
        scoreinfostring = class'HudBase'.default.YouveLostTheMatch;
    }
    else
    {
        if(UnrealPlayer(Owner).bDisplayWinner)
        {
            scoreinfostring = class'HudBase'.default.YouveWonTheMatch;
        }
        else
        {
            if(PlayerController(Owner).IsDead())
            {
                RestartString = Restart;
                if(PlayerController(Owner).PlayerReplicationInfo.bOutOfLives)
                {
                    RestartString = OutFireText;
                }
                scoreinfostring = RestartString;
            }
        }
    }
    TitleYPos = Canvas.ClipY * 0.130;
    DrawYPos = TitleYPos;
    Canvas.DrawColor = HudClass.default.WhiteColor;
    // Canvas.DrawColor = default.Blue;
    Canvas.StrLen(CurrentGameString, CurrentGameXL, CurrentGameYL);
    Canvas.SetPos(0.50 * (Canvas.ClipX - CurrentGameXL), DrawYPos);
    Canvas.DrawText(CurrentGameString);
    DrawYPos += CurrentGameYL;
    Canvas.StrLen(CurrentDateString, CurrentDateXL, CurrentDateYL);
    Canvas.SetPos(0.50 * (Canvas.ClipX - CurrentDateXL), DrawYPos);
    Canvas.DrawText(CurrentDateString);
    DrawYPos += CurrentDateYL;
    Canvas.StrLen(scoreinfostring, ScoreInfoXL, ScoreInfoYL);
    Canvas.SetPos(0.50 * (Canvas.ClipX - ScoreInfoXL), DrawYPos);
    Canvas.DrawText(scoreinfostring);
}

simulated event UpdateScoreBoard(Canvas Canvas)
{
    local PlayerReplicationInfo PRI, OwnerPRI;
    local int i, /* j, */  FontReduction, NetXPos,PlayerCount, HeaderOffsetY, HeadFoot, MessageFoot, PlayerBoxSizeY,BoxSpaceY, NameXPos, BoxTextOffsetY, BoxXPos, KillsXPos,	TitleYPos, BoxWidth, VetXPos, TempVetXPos, VetYPos;

    local float XL, YL, MaxScaling,AssistsXL, KillsXL, netXL, KillWidthX, ScoreXPos, scoreXL,PlayerXL;
	local float AssistsXPos,AssistsWidthX;
    local bool bNameFontReduction;
    local Material VeterancyBox, StarMaterial;
    local int TempLevel;
    local KFPlayerReplicationInfo KFPRI;
    local float PlayerTimeXPos, PlayerTimeXL, PlayerTimeWidthX, CashX;

    local string CashString, PlayerTime;
    local array<PlayerReplicationInfo> TeamPRIArray;
    local int OwnerOffset;

    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
    OwnerOffset = -1;
    
    for(i=0;i < GRI.PRIArray.Length;i++)
    {
        PRI = GRI.PRIArray[i];
        if(!PRI.bOnlySpectator)
        {
            if(PRI == OwnerPRI)
            {
                OwnerOffset = i;
            }
            PlayerCount++;
            TeamPRIArray[TeamPRIArray.Length] = PRI;
        }
        
    }
    PlayerCount = Min(PlayerCount, MAXPLAYERS);//32
    Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);
    Canvas.StrLen("Test", XL, YL);
    BoxSpaceY = int(0.250 * YL);
    PlayerBoxSizeY = int(1.20 * YL);
    HeadFoot = int(float(7) * YL);
    MessageFoot = int(1.50 * float(HeadFoot));
    if(float(PlayerCount) > ((Canvas.ClipY - (1.50 * float(HeadFoot))) / float(PlayerBoxSizeY + BoxSpaceY)))
    {
        BoxSpaceY = int(0.1250 * YL);
        PlayerBoxSizeY = int(1.250 * YL);
        if(float(PlayerCount) > ((Canvas.ClipY - (1.50 * float(HeadFoot))) / float(PlayerBoxSizeY + BoxSpaceY)))
        {
            if(float(PlayerCount) > ((Canvas.ClipY - (1.50 * float(HeadFoot))) / float(PlayerBoxSizeY + BoxSpaceY)))
            {
                PlayerBoxSizeY = int(1.1250 * YL);
            }
        }
    }
    if(Canvas.ClipX < float(512))
    {
        PlayerCount = Min(PlayerCount, int(float(1) + ((Canvas.ClipY - float(HeadFoot)) / float(PlayerBoxSizeY + BoxSpaceY))));
    }
    else
    {
        PlayerCount = Min(PlayerCount, int(Canvas.ClipY - float(HeadFoot)) / (PlayerBoxSizeY + BoxSpaceY));
    }
    if(FontReduction > 1)//2
    {
        MaxScaling = 1.75;//3.0
    }
    else
    {
        MaxScaling = 1.75;//2.1250
    }
    PlayerBoxSizeY = int(FClamp(((1.250 + (Canvas.ClipY - (0.670 * float(MessageFoot)))) / float(PlayerCount)) - float(BoxSpaceY), float(PlayerBoxSizeY), MaxScaling * YL));
    bDisplayMessages = float(PlayerCount) <= ((Canvas.ClipY - float(MessageFoot)) / float(PlayerBoxSizeY + BoxSpaceY));
    
    HeaderOffsetY = int(float(9) * YL);//10
    BoxWidth = int(0.70 * Canvas.ClipX);//???????????
    BoxXPos = int(0.40 * (Canvas.ClipX - float(BoxWidth)));//0.2  ??????
    BoxWidth = int(Canvas.ClipX - float(2 * BoxXPos));
    // ???????????
    VetXPos = int(float(BoxXPos) + (0.00007 * float(BoxWidth)));
    NameXPos = int(float(BoxXPos) + (0.065 * float(BoxWidth)));//0.665
    KillsXPos = int(float(BoxXPos) + (0.43 * float(BoxWidth)));//0.45
	AssistsXPos = BoxXPos + 0.56 * BoxWidth; //0.525
    // HuskXPos = float(BoxXPos) + (0.51 * float(BoxWidth));//0.60
    // SCXPos = float(BoxXPos) + (0.60 * float(BoxWidth));//0.675
    // FPXPos = float(BoxXPos) + (0.69 * float(BoxWidth));//0.75
    PlayerTimeXPos = float(BoxXPos) + (0.69 * float(BoxWidth));//0.825
    ScoreXPos = float(BoxXPos) + (0.82 * float(BoxWidth));//0.90
    NetXPos = int(float(BoxXPos) + (0.95 * float(BoxWidth)));//0.975
    Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.DrawColor = HudClass.default.WhiteColor;
    
    for(i=0;i < PlayerCount;i++)
    {
        if(i == OwnerOffset)
        {
            Canvas.DrawColor.A = 64;
        }
        else
        {
            Canvas.DrawColor.A = 32;
        }
        Canvas.SetPos(float(BoxXPos), float(HeaderOffsetY + ((PlayerBoxSizeY + BoxSpaceY) * i)));
        Canvas.DrawTileStretched(BoxMaterial, float(BoxWidth), float(PlayerBoxSizeY));
        
    }

    Canvas.Style = ERenderStyle.STY_Normal;
    DrawTitle(Canvas, float(HeaderOffsetY), float(PlayerCount + 1) * float(PlayerBoxSizeY + BoxSpaceY), float(PlayerBoxSizeY));
    TitleYPos = int(float(HeaderOffsetY) - (1.10 * YL));
    Canvas.StrLen(PlayerText, PlayerXL, YL);
    Canvas.StrLen(KillsText, KillsXL, YL);
	Canvas.StrLen(AssistsHeaderText, AssistsXL, YL);
    Canvas.StrLen(PointsText, scoreXL, YL);
    // Canvas.StrLen(HuskText,HuskXL,YL);
	// Canvas.StrLen(SCText, SCXL, YL);
	// Canvas.StrLen(FPText, FPXL, YL);
    Canvas.StrLen(PlayerTimeText, PlayerTimeXL, YL);
    // Canvas.DrawColor = HudClass.default.GreenColor;
    Canvas.DrawColor = HudClass.default.WhiteColor;
    Canvas.SetPos(float(NameXPos ), float(TitleYPos));
    Canvas.DrawText(PlayerText, true);
    // Canvas.DrawColor = default.PurpleColor;
    Canvas.DrawColor = HudClass.default.WhiteColor;
    Canvas.SetPos(float(KillsXPos) - (0.50 * KillsXL), float(TitleYPos));
    Canvas.DrawText(KillsText, true);
    //Ast
	Canvas.DrawColor = HudClass.default.WhiteColor;
	Canvas.SetPos(AssistsXPos - 0.5 * AssistsXL, TitleYPos);
    Canvas.DrawText(AssistsHeaderText, true);
	// Canvas.DrawText(KillAssistsSeparator $ AssistsHeaderText,true);
    //
    Canvas.DrawColor = HudClass.default.WhiteColor;
    Canvas.SetPos(PlayerTimeXPos - (0.50 * PlayerTimeXL), float(TitleYPos));
    Canvas.DrawText(PlayerTimeText, true);
    // Canvas.DrawColor = default.GoldColor;
    Canvas.DrawColor = HudClass.default.WhiteColor;
    Canvas.SetPos(ScoreXPos - (0.50 * scoreXL), float(TitleYPos));
    Canvas.DrawText(PointsText, true);
    // MaxNamePos = 0.90 * float(KillsXPos - NameXPos);
    
    for(i=0;i < PlayerCount;i++)
    {
        PN = ParseTags(TeamPRIArray[i].PlayerName);
		Canvas.StrLen(PN, XL, YL);
    }
    if(bNameFontReduction)
    {
        Canvas.Font = GetSmallerFontFor(Canvas, FontReduction - 1);
    }
    Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.SetPos(0.50 * Canvas.ClipX, float(HeaderOffsetY + 4));
    BoxTextOffsetY = int(float(HeaderOffsetY) + (0.50 * (float(PlayerBoxSizeY) - YL)));
    
    for(i=0;i < PlayerCount;i++)
    {
        Canvas.DrawColor = HudClass.default.WhiteColor;
        KFPRI = KFPlayerReplicationInfo(TeamPRIArray[i]);
        Canvas.DrawColor.B = 0;
        if(i == OwnerOffset)
        {
            Canvas.DrawColor.A = 140;
        }
        else
        {
            Canvas.DrawColor.A = 70;//64
        }
        if(KFPRI.PlayerHealth >100)
        {
            // Canvas.DrawColor.R = 32;//0
            // Canvas.DrawColor.G = byte(128);//255
            // Canvas.DrawColor.B = byte((0.63750 * float(KFPRI.PlayerHealth)) - 63.750);
            
            Canvas.DrawColor.R = 0;//0
            Canvas.DrawColor.G = byte(255);//255
            Canvas.DrawColor.B = 127;
            // Canvas.DrawColor.A = 140;
        }
        else
        {
            if(KFPRI.PlayerHealth >= 65)
            {
                // Canvas.DrawColor.R = byte(float(510) - (5.10 * float(KFPRI.PlayerHealth)));
                // Canvas.DrawColor.G = byte(255);
                
            Canvas.DrawColor.R = 0;//11;//12;//byte(float(510) - (5.10 * float(KFPRI.PlayerHealth)))
            Canvas.DrawColor.G = 134;//86;////29;//byte(103);//128
            Canvas.DrawColor.B = 139;//193;////127;//136;//128
            // Canvas.DrawColor.A = 140;
            }
            else
            {
                if(KFPRI.PlayerHealth >= 25)
                {
                    Canvas.DrawColor.R = byte(255);
                    Canvas.DrawColor.G = byte((10.20 * float(KFPRI.PlayerHealth)) - float(255));
                    // Canvas.DrawColor.A = 140;
                }
                else
                {
                    Canvas.DrawColor.R = byte(255);
                    Canvas.DrawColor.G = 0;
                    // Canvas.DrawColor.A = 140;
                }
            }
        }
        Canvas.SetPos(float(BoxXPos), float(HeaderOffsetY + ((PlayerBoxSizeY + BoxSpaceY) * i)));
        Canvas.DrawTileStretched(BoxMaterial, float((BoxWidth * Clamp(KFPRI.PlayerHealth, 0, 100)) / 100), float(PlayerBoxSizeY));
        
    }

    if(bNameFontReduction)
    {
        Canvas.Font = GetSmallerFontFor(Canvas, FontReduction);
    }
    Canvas.Style = ERenderStyle.STY_Alpha;
    MaxScaling = FMax(float(PlayerBoxSizeY), 30.0);
    
    for(i=0;i < PlayerCount;i++)
    {
        KFPRI = KFPlayerReplicationInfo(TeamPRIArray[i]);
        Canvas.DrawColor = HudClass.default.WhiteColor;
        if(i == OwnerOffset)
        {
            Canvas.DrawColor.A = byte(255);
        }
        else
        {
            Canvas.DrawColor.A = 192;
        }
        if((KFPRI != none) && KFPRI.ClientVeteranSkill != none)
        {
            if(KFPRI.ClientVeteranSkillLevel == 6)
            {
                VeterancyBox = KFPRI.ClientVeteranSkill.default.OnHUDGoldIcon;
                // StarMaterial = class'HUDKillingFloor'.default.VetStarGoldMaterial;
                StarMaterial = None;
                TempLevel = KFPRI.ClientVeteranSkillLevel;
            }
            else
            {
                VeterancyBox = KFPRI.ClientVeteranSkill.default.OnHUDIcon;
                // StarMaterial = class'HUDKillingFloor'.default.VetStarMaterial;
                StarMaterial = None;
                TempLevel = KFPRI.ClientVeteranSkillLevel;
            }
            if(VeterancyBox != none)
            {
                TempVetXPos = VetXPos;
                VetYPos = int(float(((PlayerBoxSizeY + BoxSpaceY) * i) + BoxTextOffsetY) - (float(PlayerBoxSizeY) * 0.195));//0.22
                Canvas.SetPos(float(TempVetXPos), float(VetYPos));
                Canvas.DrawTile(VeterancyBox, float(PlayerBoxSizeY), float(PlayerBoxSizeY), 0.0, 0.0, float(VeterancyBox.MaterialUSize()), float(VeterancyBox.MaterialVSize()));
               
                TempVetXPos += int(float(PlayerBoxSizeY) - (float(PlayerBoxSizeY / 5) * 0.750));
                VetYPos += int(float(PlayerBoxSizeY) - (float(PlayerBoxSizeY / 5) * 1.50));
                
                Canvas.SetPos(float(TempVetXPos), VetYPos-(PlayerBoxSizeY/5) * 0.7);
                Canvas.DrawText(TempLevel);
                VetYPos -= int(float(PlayerBoxSizeY / 5) * 0.70);
                  
            }
        }
        Canvas.SetPos(float(NameXPos), (float(PlayerBoxSizeY + BoxSpaceY) * float(i)) + float(BoxTextOffsetY));
		PN = ParseTags(KFPRI.PlayerName);
		Canvas.DrawTextClipped(PN);
        // Canvas.DrawTextClipped(KFPRI.PlayerName);

        if(bDisplayWithKills)
        {
            // Canvas.DrawColor = default.PurpleColor;
            Canvas.DrawColor = HudClass.default.WhiteColor;
            Canvas.StrLen(string(KFPRI.Kills), KillWidthX, YL);
            Canvas.SetPos(float(KillsXPos) - (0.50 * KillWidthX), (float(PlayerBoxSizeY + BoxSpaceY) * float(i)) + float(BoxTextOffsetY));
            Canvas.DrawText(string(KFPRI.Kills), true);
            // Draw Kill Assists
			Canvas.DrawColor = HudClass.default.WhiteColor;
			Canvas.StrLen(KFPRI.KillAssists, AssistsWidthX, YL);
			Canvas.SetPos(AssistsXPos - 0.5 * AssistsWidthX, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
			Canvas.DrawText(KFPRI.KillAssists, true);            
			// Canvas.DrawText(KillAssistsSeparator $ KFPRI.KillAssists, true);            
        }
        PlayerTime = FormatTime(GRI.ElapsedTime - KFPRI.StartTime);
        // Canvas.DrawColor = default.YellowColor;
        Canvas.DrawColor = HudClass.default.WhiteColor;
        Canvas.StrLen(PlayerTime, PlayerTimeWidthX, YL);
        Canvas.SetPos(PlayerTimeXPos - (0.50 * PlayerTimeWidthX), (float(PlayerBoxSizeY + BoxSpaceY) * float(i)) + float(BoxTextOffsetY));
        Canvas.DrawText(PlayerTime, true);
        CashString = "£" $ string(int(TeamPRIArray[i].Score));
        if(TeamPRIArray[i].Score >= float(1000))
        {
            CashString = ( "£" $ string(TeamPRIArray[i].Score / 1000.0)) $ "K";
        }
        // Canvas.DrawColor = default.GoldColor;
        Canvas.DrawColor = HudClass.default.WhiteColor;
        Canvas.StrLen(CashString, CashX, YL);
        Canvas.SetPos(ScoreXPos - (CashX / float(2)), (float(PlayerBoxSizeY + BoxSpaceY) * float(i)) + float(BoxTextOffsetY));
        Canvas.DrawText(CashString);
        
    }
    if(Level.NetMode == NM_Standalone)
    {
        return;
    }
    Canvas.DrawColor = HudClass.default.WhiteColor;
    Canvas.StrLen(NetText, netXL, YL);
    Canvas.SetPos(float(NetXPos) - (0.50 * netXL), float(TitleYPos));
    Canvas.DrawText(NetText, true);

    for(i=0;i < GRI.PRIArray.Length;i++)
    {
        PRIArray[i] = GRI.PRIArray[i];
    }
    DrawNetInfo(Canvas, FontReduction, HeaderOffsetY, PlayerBoxSizeY, BoxSpaceY, BoxTextOffsetY, OwnerOffset, PlayerCount, NetXPos);
    DrawMatchID(Canvas, FontReduction);
}

function DrawNetInfo(Canvas Canvas, int FontReduction, int HeaderOffsetY, int PlayerBoxSizeY, int BoxSpaceY, int BoxTextOffsetY, int OwnerOffset, int PlayerCount, int NetXPos)
{
    local int i, PlayerPing;
    local float AdminXL, AdminYL, ReadyXL, ReadyYL, NotReadyXL, NotReadyYL,
	    PlayerPingXL, PlayerPingYL;

    if(Canvas.ClipX < float(512))
    {
        PingText = "";
    }
    else
    {
        PingText = default.PingText;
    }
    if(GRI.bMatchHasBegun)
    {
        Canvas.DrawColor = HudClass.default.WhiteColor;
        
        for(i=0;i < PlayerCount;i++)
        {
            if(i == OwnerOffset)
            {
                Canvas.DrawColor.A = byte(255);
            }
            else
            {
                Canvas.DrawColor.A = 192;
            }
            if(PRIArray[i].bAdmin)
            {
                Canvas.StrLen(AdminText, AdminXL, AdminYL);
                Canvas.SetPos(float(NetXPos) - (0.50 * AdminXL), (float(PlayerBoxSizeY + BoxSpaceY) * float(i)) + float(BoxTextOffsetY));
                Canvas.DrawText(AdminText);
            }

        }
    }
    else
    {
        
        for(i=0;i < PlayerCount;i++)
        {
            Canvas.DrawColor = HudClass.default.WhiteColor;
            PlayerPing = Min(999, 4 * PRIArray[i].Ping);
            if(i == OwnerOffset)
            {
                Canvas.DrawColor.A = byte(255);
            }
            else
            {
                Canvas.DrawColor.A = 192;
            }
            if(PRIArray[i].bReadyToPlay)
            {
                Canvas.StrLen(ReadyText, ReadyXL, ReadyYL);
                Canvas.SetPos(float(NetXPos) - (0.50 * ReadyXL), (float(PlayerBoxSizeY + BoxSpaceY) * float(i)) + float(BoxTextOffsetY));
                Canvas.DrawText(ReadyText, true);
                
            }
            Canvas.StrLen(NotReadyText, NotReadyXL, NotReadyYL);
            Canvas.SetPos(float(NetXPos) - (0.50 * NotReadyXL), (float(PlayerBoxSizeY + BoxSpaceY) * float(i)) + float(BoxTextOffsetY));
            Canvas.DrawText(NotReadyText, true);
            
        }
        return;
    }
    if(Canvas.ClipX < float(512))
    {
        PingText = "";
    }
    else
    {
        PingText = default.PingText;
    }
    
    for(i=0;i < PlayerCount;i++)
    {
        Canvas.DrawColor = HudClass.default.WhiteColor;
        if(i == OwnerOffset)
        {
            Canvas.DrawColor.A = byte(255);
        }
        else
        {
            Canvas.DrawColor.A = 192;
        }
        if(!PRIArray[i].bAdmin && !PRIArray[i].bOutOfLives)
        {
            PlayerPing = Min(999, 4 * PRIArray[i].Ping);
            Canvas.StrLen(string(PlayerPing), PlayerPingXL, PlayerPingYL);
            Canvas.SetPos(float(NetXPos) - (0.50 * PlayerPingXL), (float(PlayerBoxSizeY + BoxSpaceY) * float(i)) + float(BoxTextOffsetY));
            Canvas.DrawText(string(PlayerPing), true);
        }
        
    }
}

function Color GetPingNewColor( int Ping)
{
    if(Ping >= 200)
    {
        //return 	HUDClass.default.RedColor;
		return default.DarkGrayColor;
    }
    else if( Ping >= 100)
    {
        //return HUDClass.default.GoldColor;
		return default.GrayColor;
    }
    else if( Ping < 100)
    {
        //return HUDClass.default.GreenColor;
		return HudClass.default.WhiteColor;
    }
}


static final function string ParseTags(string S)
{
    local int i;
    local string NewTag, newCode;

    CheckColorCodes();
    
    for(i=0;i < default.ColorList.Length;i++)
    {
        NewTag = default.ColorList[i].Tag;
        newCode = default.colorCodes[i];
        ReplaceText(S, NewTag, newCode);
    }
    return S;
}


static final function CheckColorCodes()
{
    if(!default.bMadeColorCodes)
    {
        MakeColorCodes();
    }
}


static final function MakeColorCodes()
{
    local int i;

    for(i=0;i < default.ColorList.Length;i++)
    {
        default.colorCodes[default.colorCodes.Length] = GetColorCode(default.ColorList[i].RGB);
    }
    default.bMadeColorCodes = true;
}


static final function string GetColorCode(string rgbString)
{
    local Color NewColor;
    local array<string> RGB;

    Split(rgbString, ",", RGB);
    NewColor.R = byte(Clamp(int(RGB[0]), 1, 255));
    NewColor.G = byte(Clamp(int(RGB[1]), 1, 255));
    NewColor.B = byte(Clamp(int(RGB[2]), 1, 255));
    return ((Chr(27) $ Chr(NewColor.R)) $ Chr(NewColor.G)) $ Chr(NewColor.B);
}


defaultproperties
{
     NotShownInfo="UNSHOWN"
     PlayerCountText="PLAYER:"
     SpectatorCountText="| SPEC:"
     AliveCountText="| ALIVE:"
     BotText="BOT"
     PlayerTimeText="TIME"
     GrayColor=(B=192,G=192,R=192,A=255)
     Blue=(B=170,G=178,R=32,A=255)
     DarkGrayColor=(B=128,G=128,R=128,A=255)
     YellowColor=(B=32,G=165,R=218,A=255)
     GoldColor=(B=60,G=20,R=220,A=255)
     OrangeRedColor=(B=30,G=222,R=235,A=255)
     PurpleColor=(B=128,R=128,A=255)
     KillsText="KILL"
     AssistsHeaderText="ASSIST"
     PlayerText="PLAYER"
     PointsText="DOSH"
     AdminText="|A|"
     NetText="PING"
     ReadyText="READY"
     NotReadyText="PENDING"
     FooterText="ELAPSED TIME:"
     BoxMaterial=Texture'MutSR.Box'
     ColorList(0)=(Color="Red",Tag="%r",RGB="255,1,1")
     ColorList(1)=(Color="Blue",Tag="%b",RGB="0,100,200")
     ColorList(2)=(Color="Cyan",Tag="%c",RGB="0,255,255")
     ColorList(3)=(Color="Green",Tag="%g",RGB="0,255,0")
     ColorList(4)=(Color="Orange",Tag="%o",RGB="200,77,0")
     ColorList(5)=(Color="Purple",Tag="%p",RGB="128,0,128")
     ColorList(6)=(Color="Violet",Tag="%v",RGB="255,0,139")
     ColorList(7)=(Color="White",Tag="%w",RGB="255,255,255")
     ColorList(8)=(Color="Yellow",Tag="%y",RGB="255,255,0")
}
