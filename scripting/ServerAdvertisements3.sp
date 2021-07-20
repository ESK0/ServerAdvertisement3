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


#include "files/misc.sp"


public Plugin myinfo =
{
  name = PLUGIN_NAME,
  version = PLUGIN_VERSION,
  author = PLUGIN_AUTHOR,
  description = "Server Advertisement",
  url = "https://forums.alliedmods.net/showthread.php?t=248314"
};

public void OnPluginStart()
{
  CreateConVar("SA3_version", PLUGIN_VERSION, "ServerAdvertisement3", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  AutoExecConfig(true, "ServerAdvertisements3");

  RegAdminCmd("sm_sa3r", Command_sa3r, ADMFLAG_ROOT, "Message reload");

  RegConsoleCmd("sm_sa3lang", Command_ChangeLanguage);

  BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), "configs/ServerAdvertisements3.cfg");

  g_cV_Enabled = CreateConVar("sm_sa3_enable", "1", "Enable/Disable ServerAdvertisements3");
  g_b_Enabled = g_cV_Enabled.BoolValue;
  g_cV_Enabled.AddChangeHook(OnConVarChanged);

  g_hSA3CustomLanguage = RegClientCookie("sa3_customlanguage", "Custom langauge for SA3", CookieAccess_Private);

  aMessagesList = new ArrayList(512);
  aLanguages = new ArrayList(12);
  aWelcomeMessage = new ArrayList(128);
}
public void OnMapStart()
{
  char sTempMap[PLATFORM_MAX_PATH];
  GetCurrentMap(sTempMap, sizeof(sTempMap));
  GetMapDisplayName(sTempMap, sMapName,sizeof(sMapName));
  LoadConfig();
  g_iCurrentMessage = 0;
}

public void OnMapEnd()
{
    for(int i = 0; i < aMessagesList.Length; i++)
    {
        ArrayList aRtemp = aMessagesList.Get(i);
        if (aRtemp != null)
        {
            ArrayList aRtempText = aRtemp.Get(4);
            delete aRtempText;
        }
        delete aRtemp;
    }
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
    else if(action == MenuAction_End)
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
    else if(StrEqual(g_sWM_Type, "C", false))
    {
      char sBuffer[1024];
      int iExplode = ExplodeString(sWelcomeMessage, "\\n", sWelcomeMessageEx, sizeof(sWelcomeMessageEx), sizeof(sWelcomeMessageEx[]));
      for(int i = 0; i < iExplode; i++)
      {
        TrimString(sWelcomeMessageEx[i]);
        CheckMessageVariables(sWelcomeMessageEx[i], sizeof(sWelcomeMessageEx[]));
        CheckMessageClientVariables(client, sWelcomeMessageEx[i], sizeof(sWelcomeMessageEx[]));
        if(strlen(sBuffer) == 0)
        {
          Format(sBuffer, sizeof(sBuffer), "%s\n", sWelcomeMessageEx[i]);
        }
        else
        {
          Format(sBuffer, sizeof(sBuffer), "%s\n%s", sBuffer, sWelcomeMessageEx[i]);
        }
      }
      PrintCenterText(client, sBuffer);
    }
    else if(StrEqual(g_sWM_Type, "H", false))
    {
      char sMessageExplode[32][255];
      char sMessage[1024];
      int count = ExplodeString(sWelcomeMessage, "\\n", sMessageExplode, sizeof(sMessageExplode), sizeof(sMessageExplode[]));
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

      int color1[4], color2[4];
      aWelcomeMessage.GetArray(aLanguages.Length, color1, sizeof(color1));
      aWelcomeMessage.GetArray(aLanguages.Length + 1, color2, sizeof(color2));
      HudMessage(client, color1, color2, aWelcomeMessage.Get(aLanguages.Length + 2),
        aWelcomeMessage.Get(aLanguages.Length + 3), sMessage, aWelcomeMessage.Get(aLanguages.Length + 4),
        aWelcomeMessage.Get(aLanguages.Length + 5), aWelcomeMessage.Get(aLanguages.Length + 6),
        aWelcomeMessage.Get(aLanguages.Length + 7), aWelcomeMessage.Get(aLanguages.Length + 8));
    }
    else if (StrEqual(g_sWM_Type, "M", false)) // Top menu?
    {
      int color[4];
      aWelcomeMessage.GetArray(aLanguages.Length, color, sizeof(color));
      DisplayTopMenuMessage(client, sWelcomeMessage, color);
    }
  }
  return Plugin_Stop;
}
public void OnConVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
  if(cvar == g_cV_Enabled)
  {
    int iNewVal = StringToInt(newValue);
    g_b_Enabled = view_as<bool>(iNewVal);
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
    gRandomize = view_as<bool>(kvConfig.GetNum("Random"));
    char sLanguages[64];
    char sLanguageList[64][12];
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
    LoadMessages();
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

    bool isHUD = StrEqual(g_sWM_Type, "H", false);

    if (isHUD || StrEqual(g_sWM_Type, "M", false)) // HUD or top menu message?
    {
      CopyKeyValuesColor(kvConfig, "color", _, aWelcomeMessage);
    }

    if (isHUD)
    {
      CopyKeyValuesColor(kvConfig, "color2", {255, 255, 51, 255}, aWelcomeMessage);
      aWelcomeMessage.Push(kvConfig.GetNum("effect", 0));
      aWelcomeMessage.Push(kvConfig.GetNum("channel", 1));
      aWelcomeMessage.Push(kvConfig.GetFloat("posx", -1.0));
      aWelcomeMessage.Push(kvConfig.GetFloat("posy", 0.05));
      aWelcomeMessage.Push(kvConfig.GetFloat("fadein", 0.2));
      aWelcomeMessage.Push(kvConfig.GetFloat("fadeout", 0.2));
      aWelcomeMessage.Push(kvConfig.GetFloat("holdtime", 5.0));
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
    if(aMessagesList.Length > 0)
    {
      g_h_Timer = CreateTimer(fTime, Timer_PrintMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
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
  int next = gRandomize ? GetURandomInt() : g_iCurrentMessage;
  next %= aMessagesList.Length;
  ArrayList aRtemp = aMessagesList.Get(next);

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

          if (StrEqual(sType, "T", false))
          {
              char sMultipleLines[9][512];
              int iMessagesCount = ExplodeString(sLangText, "\\n", sMultipleLines, sizeof(sMultipleLines), sizeof(sMultipleLines[]));
              for(int y = 0; y < iMessagesCount; y++)
              {
                TrimString(sMultipleLines[y]);
                char sBuffer[512];
                Format(sBuffer, sizeof(sBuffer), "%s %s",sTag, sMultipleLines[y]);
                TrimString(sBuffer);
                CPrintToChat(i,sBuffer);
              }
          }
          else if (StrEqual(sType, "C", false))
          {
            PrintCenterText(i, sLangText);
          }
          else if (StrEqual(sType, "H", false))
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

            int color1[4], color2[4];
            aRtemp.GetArray(5, color1, sizeof(color1));
            aRtemp.GetArray(6, color2, sizeof(color2));
            HudMessage(i, color1, color2, aRtemp.Get(7), aRtemp.Get(8), sMessage, aRtemp.Get(9),
              aRtemp.Get(10), aRtemp.Get(11), aRtemp.Get(12), aRtemp.Get(13));
          }
          else if (StrEqual(sType, "M", false)) // Top menu?
          {
            int color[4];
            aRtemp.GetArray(5, color, sizeof(color));
            DisplayTopMenuMessage(i, sLangText, color);
          }
        }
      }
    }
  }
  g_iCurrentMessage = next + 1;
  return Plugin_Continue;
}
