#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <clientprefs>
#include <multicolors>
#include "files/globals.sp"
#include "files/client.sp"

#pragma newdecls required
#pragma semicolon 1

#define LoopClients(%1) for(int %1 = 1;%1 <= MaxClients;%1++) if(IsValidClient(%1))

#define PLUGIN_VERSION "3.1.2"


#include "files/misc.sp"
#include "files/mysql.sp"


public Plugin myinfo =
{
  name = "ServerAdvertisements3",
  version = PLUGIN_VERSION,
  author = "ESK0 ",
  description = "Server Advertisement",
  url = "https://forums.alliedmods.net/showthread.php?t=248314"
};

public void OnPluginStart()
{
  CreateConVar("SA3_version", PLUGIN_VERSION, "ServerAdvertisement3", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  AutoExecConfig(true, "ServerAdvertisements3");

  RegAdminCmd("sm_sa3debug", Command_sa3, ADMFLAG_ROOT, "Message debug");
  RegAdminCmd("sm_sa3r", Command_sa3r, ADMFLAG_ROOT, "Message reload");

  RegConsoleCmd("sm_sa3lang", Command_ChangeLanguage);

  BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), "configs/ServerAdvertisements3.cfg");

  aMessagesList = new ArrayList(512);
  aLanguages = new ArrayList(12);
  aWelcomeMessage = new ArrayList(128);

  g_cV_Enabled = CreateConVar("sm_sa3_enable", "1", "Enable/Disable ServerAdvertisements3");
  g_b_Enabled = g_cV_Enabled.BoolValue;
  g_cV_Enabled.AddChangeHook(OnConVarChanged);

  g_hSA3CustomLanguage = RegClientCookie("sa3_customlanguage", "Custom langauge for SA3", CookieAccess_Private);
}
public void OnMapStart()
{
  char sTempMap[256];
  GetCurrentMap(sTempMap, sizeof(sTempMap));
  GetMapDisplayName(sTempMap, sMapName,sizeof(sMapName));
  LoadConfig();
  g_iCurrentMessage = 0;
}
public void OnClientPostAdminCheck(int client)
{
  if(IsValidClient(client))
  {
    if(g_iWM_Enabled == 1)
    {
      if(CheckCommandAccess(client, "", g_iWM_FlagsBit, true) || strlen(g_sWM_Flags) == 0)
      {
        CreateTimer(g_fWM_Delay, Timer_WelcomeMessage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
      }
    }
    char sBuffer[12];
    GetClientCookie(client, g_hSA3CustomLanguage, sBuffer, sizeof(sBuffer));
    if(StrEqual(sBuffer, "", false))
    {
      SetClientCookie(client, g_hSA3CustomLanguage, sDefaultLanguage);
    }
  }
}
public Action Command_ChangeLanguage(int client, int args)
{
  if(IsValidClient(client))
  {
    char sTempLang[12];
    char sTempLangSelected[12];
    char sBuffer[64];
    char sLangName[3];
    SA_GetInGameLanguage(client, sLangName, sizeof(sLangName));
    GetClientCookie(client, g_hSA3CustomLanguage, sTempLangSelected, sizeof(sTempLangSelected));
    Menu mSA3LangMenu = CreateMenu(hSA3LangMenu);
    mSA3LangMenu.SetTitle("%s Choose your language", SA3);
    Format(sBuffer, sizeof(sBuffer), "Get my language by ip %s", StrEqual(sTempLangSelected, "geoip", false) ? "[SELECTED]" : "");
    mSA3LangMenu.AddItem("geoip", sBuffer, StrEqual(sTempLangSelected, "geoip", false) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    Format(sBuffer, sizeof(sBuffer), "Get my language by game (%s) %s", sLangName, StrEqual(sTempLangSelected, "ingame", false) ? "[SELECTED]" : "");
    mSA3LangMenu.AddItem("ingame", sBuffer, StrEqual(sTempLangSelected, "ingame", false) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    for(int i = 0; i < aLanguages.Length; i++)
    {
      aLanguages.GetString(i, sTempLang, sizeof(sTempLang));
      Format(sBuffer, sizeof(sBuffer), "%s %s",sTempLang, StrEqual(sTempLangSelected, sTempLang, false) ? "[SELECTED]" : "");
      mSA3LangMenu.AddItem(sTempLang, sBuffer, StrEqual(sTempLangSelected, sTempLang, false) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    }
    mSA3LangMenu.ExitButton = true;
    mSA3LangMenu.Display(client, MENU_TIME_FOREVER);
  }
  return Plugin_Handled;
}
public int hSA3LangMenu(Menu menu, MenuAction action, int client, int Position)
{
  if(IsValidClient(client))
  {
    if(action == MenuAction_Select)
    {
      char Item[10];
      menu.GetItem(Position, Item, sizeof(Item));
      SetClientCookie(client, g_hSA3CustomLanguage, Item);
    }
    else if (action == MenuAction_End)
    {
      delete menu;
    }
  }
}
public Action Timer_WelcomeMessage(Handle timer, int userid)
{
  int client = GetClientOfUserId(userid);
  if(IsValidClient(client))
  {
    char sCountryTag[3];
    char sWelcomeMessage[1024];
    char sWelcomeMessageEx[9][1024];
    SA_GetClientLanguage(client, sCountryTag);
    int sIndex = aLanguages.FindString(sCountryTag);
    if(sIndex == -1)
    {
      sIndex = 0;
    }
    aWelcomeMessage.GetString(sIndex, sWelcomeMessage, sizeof(sWelcomeMessage));
    if(StrEqual(g_sWM_Type, "T", false))
    {
      int iExplode = ExplodeString(sWelcomeMessage, "\\n", sWelcomeMessageEx, sizeof(sWelcomeMessageEx), sizeof(sWelcomeMessageEx[]));
      for(int i = 0; i < iExplode; i++)
      {
        TrimString(sWelcomeMessageEx[i]);
        CheckMessageVariables(sWelcomeMessageEx[i], sizeof(sWelcomeMessageEx[]));
        CheckMessageClientVariables(client, sWelcomeMessageEx[i], sizeof(sWelcomeMessageEx[]));
        CPrintToChat(client, "%s", sWelcomeMessageEx[i]);
      }
    }
  }
}
public void OnConVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
  if(cvar == g_cV_Enabled)
  {
    g_b_Enabled = g_cV_Enabled.BoolValue;
    if(g_b_Enabled == true)
    {
      LoadMessages();
    }
    else
    {
      delete g_h_Timer;
    }
  }
}
public Action Command_sa3(int client, int args)
{
  if(IsValidClient(client))
  {
    for(int i = 0; i < aMessagesList.Length; i++)
    {
      ArrayList aRtemp = aMessagesList.Get(i);
      if(aRtemp)
      {
        char sType[32];
        char sTag[32];
        char sFlags[16];
        char sFlagsIgnore[16];
        char sLangName[32];
        char sLangText[512];
        aRtemp.GetString(0, sType, sizeof(sType));
        aRtemp.GetString(1, sTag, sizeof(sTag));
        aRtemp.GetString(2, sFlags, sizeof(sFlags));
        aRtemp.GetString(3, sFlagsIgnore, sizeof(sFlagsIgnore));
        ArrayList aRtempText = aRtemp.Get(4);
        PrintToConsole(client, "\"%i\"", i+1);
        PrintToConsole(client, "{");
        for(int x = 0; x < aRtempText.Length; x++)
        {
          aLanguages.GetString(x, sLangName, sizeof(sLangName));
          aRtempText.GetString(x, sLangText, sizeof(sLangText));
          char sMultipleLines[5][512];
          int iMessagesCount = ExplodeString(sLangText, "\\n", sMultipleLines, sizeof(sMultipleLines), sizeof(sMultipleLines[]));
          for(int y = 0; y < iMessagesCount; y++)
          {
            TrimString(sMultipleLines[y]);
            PrintToConsole(client, "   \"%s\"  \"%s\"", sLangName, sMultipleLines[y]);
          }
        }
        PrintToConsole(client, "   \"Type\" \"%s\"", sType);
        PrintToConsole(client, "   \"Tag\"  \"%s\"", sTag);
        PrintToConsole(client, "   \"Flags\"  \"%s\"", sFlags);
        if(StrEqual(sType, "h", false))
        {
          char sMessageColor[32];
          char sMessageColor2[32];
          char sMessageEffect[3];
          char sMessageChannel[32];
          char sMessagePosX[16];
          char sMessagePosY[16];
          char sMessageFadeIn[32];
          char sMessageFadeOut[16];
          char sMessageHoldTime[16];
          aRtemp.GetString(5, sMessageColor, sizeof(sMessageColor));
          aRtemp.GetString(6, sMessageColor2, sizeof(sMessageColor2));
          aRtemp.GetString(7, sMessageEffect, sizeof(sMessageEffect));
          aRtemp.GetString(8, sMessageChannel, sizeof(sMessageChannel));
          aRtemp.GetString(9, sMessagePosX, sizeof(sMessagePosX));
          aRtemp.GetString(10, sMessagePosY, sizeof(sMessagePosY));
          aRtemp.GetString(11, sMessageFadeIn, sizeof(sMessageFadeIn));
          aRtemp.GetString(12, sMessageFadeOut, sizeof(sMessageFadeOut));
          aRtemp.GetString(13, sMessageHoldTime, sizeof(sMessageHoldTime));
          PrintToConsole(client, "   \"Color\" \"%s\"", sMessageColor);
          PrintToConsole(client, "   \"Color2\" \"%s\"", sMessageColor2);
          PrintToConsole(client, "   \"Effect\" \"%s\"", sMessageEffect);
          PrintToConsole(client, "   \"Channel\" \"%s\"", sMessageChannel);
          PrintToConsole(client, "   \"PosX\"  \"%s\"", sMessagePosX);
          PrintToConsole(client, "   \"PosY\"  \"%s\"", sMessagePosY);
          PrintToConsole(client, "   \"FadeIn\" \"%s\"", sMessageFadeIn);
          PrintToConsole(client, "   \"FadeOut\"  \"%s\"", sMessageFadeOut);
          PrintToConsole(client, "   \"HoldTime\"  \"%s\"", sMessageHoldTime);
        }
        PrintToConsole(client, "}");
      }
    }
  }
  return Plugin_Handled;
}
public Action Command_sa3r(int client, int args)
{
  if(IsValidClient(client))
  {
    delete g_h_Timer;
    LoadMessages();
  }
  return Plugin_Handled;
}
public void LoadConfig()
{
  aLanguages.Clear();
  aWelcomeMessage.Clear();
  KeyValues kvConfig = new KeyValues("ServerAdvertisements3");
  if(FileExists(sConfigPath) == false)
  {
    SetFailState("%s Unable to find ServerAdvertisements3.cfg in %s",SA3, sConfigPath);
    return;
  }
  kvConfig.ImportFromFile(sConfigPath);
  if(kvConfig.JumpToKey("Settings"))
  {
    kvConfig.GetString("ServerName", sServerName, sizeof(sServerName), "[ServerAdvertisements3]");
    fTime = kvConfig.GetFloat("Time", 30.0);
    char sLanguages[64];
    char sLanguageList[64][12];
    iMySql = kvConfig.GetNum("MySQL", 0);
    kvConfig.GetString("ServerType", sServerType, sizeof(sServerType), "default");
    kvConfig.GetString("Languages", sLanguages, sizeof(sLanguages));
    kvConfig.GetString("Default language", sDefaultLanguage, sizeof(sDefaultLanguage), "geoip");

    bExpiredMessagesDebug = view_as<bool>(kvConfig.GetNum("Log expired messages", 0));
    if(strlen(sLanguages) < 1)
    {
      SetFailState("%s No language found! Please set langauges in 'Settings' part in .cfg", SA3);
      return;
    }
    int iLangCountTemp = ExplodeString(sLanguages, ";", sLanguageList, sizeof(sLanguageList), sizeof(sLanguageList[]));
    for(int i = 0; i < iLangCountTemp; i++)
    {
      aLanguages.PushString(sLanguageList[i]);
    }
    if(iMySql == 0)
    {
      LoadMessages();
    }
    else
    {
      bool bSuccess = SA_MySQLConnect();
      if(bSuccess)
      {
        if(SA_MySQLCheckTables())
        {
          //SA_MySQLLoadMessages();
        }
      }
    }
    kvConfig.GoBack();
  }
  else
  {
    SetFailState("%s Unable to find Settings in %s",SA3, sConfigPath);
    return;
  }
  if(kvConfig.JumpToKey("Welcome Message"))
  {
    char sTempWelcomeMessage[1024];
    char sTempLanguageName[12];
    g_iWM_Enabled = kvConfig.GetNum("Enabled", 1);
    kvConfig.GetString("Type", g_sWM_Type, sizeof(g_sWM_Type), "T");
    g_fWM_Delay = kvConfig.GetFloat("Delay", 5.0);
    kvConfig.GetString("flags", g_sWM_Flags, sizeof(g_sWM_Flags), "");
    if(strlen(g_sWM_Flags) > 0)
    {
      g_iWM_FlagsBit = ReadFlagString(g_sWM_Flags);
    }
    for(int i = 0; i < aLanguages.Length; i++)
    {
      aLanguages.GetString(i, sTempLanguageName, sizeof(sTempLanguageName));
      kvConfig.GetString(sTempLanguageName, sTempWelcomeMessage, sizeof(sTempWelcomeMessage), "NOLANG");
      if(StrEqual(sTempWelcomeMessage, "NOLANG"))
      {
        SetFailState("%s '%s' translation missing in welcome message", SA3, sTempLanguageName);
        return;
      }
      aWelcomeMessage.PushString(sTempWelcomeMessage);
    }
  }
  else
  {
    SetFailState("%s Unable to find Welcome Message part in %s",SA3, sConfigPath);
    return;
  }
  delete kvConfig;
}
public void LoadMessages()
{
  aMessagesList.Clear();
  KeyValues kvMessages = new KeyValues("ServerAdvertisements3");
  if(FileExists(sConfigPath) == false)
  {
    SetFailState("%s Unable to find ServerAdvertisements3.cfg in %s",SA3, sConfigPath);
    return;
  }
  kvMessages.ImportFromFile(sConfigPath);
  if(kvMessages.JumpToKey("Messages"))
  {
    kvMessages.GotoFirstSubKey();
    AddMessagesToArray(kvMessages);
    while(kvMessages.GotoNextKey())
    {
      AddMessagesToArray(kvMessages);
    }
    g_h_Timer = CreateTimer(fTime, Timer_PrintMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
  }
  else
  {
    SetFailState("%s Unable to find Messages in %s",SA3, sConfigPath);
    return;
  }
  delete kvMessages;
}
public Action Timer_PrintMessage(Handle timer)
{
  ArrayList aRtemp = aMessagesList.Get(g_iCurrentMessage);
  if(aRtemp)
  {
    char sType[32];
    char sTag[64];
    char sFlags[16];
    char sFlagsIgnore[16];
    char sLangText[512];
    int iFlagBit = -1;
    int iFlagBitIgnore = -1;
    aRtemp.GetString(0, sType, sizeof(sType));
    aRtemp.GetString(1, sTag, sizeof(sTag));
    aRtemp.GetString(2, sFlags, sizeof(sFlags));
    aRtemp.GetString(3, sFlagsIgnore, sizeof(sFlagsIgnore));
    if(StrEqual(sFlagsIgnore, "none", false) != true)
    {
      iFlagBitIgnore = ReadFlagString(sFlagsIgnore);
    }
    if(StrEqual(sFlags, "all", false) != true)
    {
      iFlagBit = ReadFlagString(sFlags);
    }
    ArrayList aRtempText = aRtemp.Get(4);
    LoopClients(i)
    {
      if(CheckCommandAccess(i, "", iFlagBitIgnore, true) != true || StrEqual(sFlagsIgnore, "none", false) == true)
      {
        if(CheckCommandAccess(i, "", iFlagBit, true) || StrEqual(sFlags, "all", false) == true)
        {
          char sCountryTag[3];
          SA_GetClientLanguage(i, sCountryTag);
          int sIndex = aLanguages.FindString(sCountryTag);
          if(sIndex == -1)
          {
            sIndex = 0;
          }
          aRtempText.GetString(sIndex, sLangText, sizeof(sLangText));
          CheckMessageVariables(sLangText, sizeof(sLangText));
          CheckMessageClientVariables(i, sLangText, sizeof(sLangText));
          char sMultipleLines[9][512];
          int iMessagesCount = ExplodeString(sLangText, "\\n", sMultipleLines, sizeof(sMultipleLines), sizeof(sMultipleLines[]));
          for(int y = 0; y < iMessagesCount; y++)
          {
            TrimString(sMultipleLines[y]);
            if(StrEqual(sType, "T", false))
            {
              char sBuffer[512];
              Format(sBuffer, sizeof(sBuffer), "%s %s",sTag, sMultipleLines[y]);
              TrimString(sBuffer);
              CPrintToChat(i,sBuffer);
            }
          }
          if(StrEqual(sType, "C", false))
          {
            PrintHintText(i, sLangText);
          }
          if(StrEqual(sType, "H", false))
          {
            char sMessageExplode[32][255];
            char sMessage[1024];
            int count = ExplodeString(sLangText, "\\n", sMessageExplode, sizeof(sMessageExplode), sizeof(sMessageExplode[]));
            for(int x = 0; x < count; x++)
            {
              if(strlen(sMessage) == 0)
              {
                Format(sMessage, sizeof(sMessage), sMessageExplode[x]);
              }
              else
              {
                Format(sMessage, sizeof(sMessage), "%s\n%s", sMessage, sMessageExplode[x]);
              }
            }
            char sMessageColor[32];
            char sMessageColor2[32];
            char sMessageEffect[3];
            char sMessageChannel[32];
            char sMessagePosX[16];
            char sMessagePosY[16];
            char sMessageFadeIn[32];
            char sMessageFadeOut[16];
            char sMessageHoldTime[16];
            aRtemp.GetString(5, sMessageColor, sizeof(sMessageColor));
            aRtemp.GetString(6, sMessageColor2, sizeof(sMessageColor2));
            aRtemp.GetString(7, sMessageEffect, sizeof(sMessageEffect));
            aRtemp.GetString(8, sMessageChannel, sizeof(sMessageChannel));
            aRtemp.GetString(9, sMessagePosX, sizeof(sMessagePosX));
            aRtemp.GetString(10, sMessagePosY, sizeof(sMessagePosY));
            aRtemp.GetString(11, sMessageFadeIn, sizeof(sMessageFadeIn));
            aRtemp.GetString(12, sMessageFadeOut, sizeof(sMessageFadeOut));
            aRtemp.GetString(13, sMessageHoldTime, sizeof(sMessageHoldTime));
            HudMessage(i, sMessageColor, sMessageColor2, sMessageEffect, sMessageChannel, sMessage, sMessagePosX, sMessagePosY, sMessageFadeIn, sMessageFadeOut, sMessageHoldTime);
          }
        }
      }
    }
  }
  g_iCurrentMessage++;
  if(g_iCurrentMessage == aMessagesList.Length)
  {
    g_iCurrentMessage = 0;
  }
  return Plugin_Continue;
}
