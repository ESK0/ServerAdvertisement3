#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <geoip>
#include <multicolors>
#include "files/globals.sp"
#include "files/client.sp"

#pragma newdecls required
#pragma semicolon 1

#define LoopClients(%1) for(int %1 = 1;%1 <= MaxClients;%1++) if(IsValidClient(%1))


#include "files/misc.sp"


public Plugin myinfo =
{
  name = "ServerAdvertisements3",
  version = "3.0",
  author = "ESK0 ",
  description = "Server Advertisement",
  url = "https://forums.alliedmods.net/showthread.php?t=248314"
};

public void OnPluginStart()
{
  RegAdminCmd("sm_sa3debug", Command_sa3, ADMFLAG_ROOT, "Message debug");
  RegAdminCmd("sm_sa3r", Command_sa3r, ADMFLAG_ROOT, "Message reload");

  BuildPath(Path_SM, sConfigPath, sizeof(sConfigPath), "configs/ServerAdvertisements3.cfg");

  aMessagesList = new ArrayList(512);
  aLanguages = new ArrayList(12);

  g_cV_Enabled = CreateConVar("sm_sa3_enable", "1", "Enable/Disable ServerAdvertisements3");
  g_b_Enabled = g_cV_Enabled.BoolValue;
  g_cV_Enabled.AddChangeHook(OnConVarChanged);
  AutoExecConfig(true, "ServerAdvertisements3");
}
public void OnMapStart()
{
  GetCurrentMap(sMapName, sizeof(sMapName));
  LoadConfig();
  g_iCurrentMessage = 0;
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
        char sLangName[32];
        char sLangText[512];
        aRtemp.GetString(0, sType, sizeof(sType));
        aRtemp.GetString(1, sTag, sizeof(sTag));
        aRtemp.GetString(2, sFlags, sizeof(sFlags));
        ArrayList aRtempText = aRtemp.Get(3);
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
          char sMessagePosX[16];
          char sMessagePosY[16];
          char sMessageFadeIn[32];
          char sMessageFadeOut[16];
          char sMessageHoldTime[16];
          aRtemp.GetString(4, sMessageColor, sizeof(sMessageColor));
          aRtemp.GetString(5, sMessagePosX, sizeof(sMessagePosX));
          aRtemp.GetString(6, sMessagePosY, sizeof(sMessagePosY));
          aRtemp.GetString(7, sMessageFadeIn, sizeof(sMessageFadeIn));
          aRtemp.GetString(8, sMessageFadeOut, sizeof(sMessageFadeOut));
          aRtemp.GetString(9, sMessageHoldTime, sizeof(sMessageHoldTime));
          PrintToConsole(client, "   \"Color\" \"%s\"", sMessageColor);
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
    kvConfig.GetString("Languages", sLanguages, sizeof(sLanguages));
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
  }
  else
  {
    SetFailState("%s Unable to find Settings in %s",SA3, sConfigPath);
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
    char sTag[32];
    char sFlags[16];
    char sLangText[512];
    int iFlagBit = -1;
    aRtemp.GetString(0, sType, sizeof(sType));
    aRtemp.GetString(1, sTag, sizeof(sTag));
    aRtemp.GetString(2, sFlags, sizeof(sFlags));
    if(StrEqual(sFlags, "all", false) != true)
    {
      iFlagBit = ReadFlagString(sFlags);
    }
    ArrayList aRtempText = aRtemp.Get(3);
    LoopClients(i)
    {
      if(CheckCommandAccess(i, "", iFlagBit) || StrEqual(sFlags, "all", false) == true)
      {
        char sCountryTag[3];
        char sIP[26];
        GetClientIP(i, sIP, sizeof(sIP));
        GeoipCode2(sIP, sCountryTag);
        int sIndex = aLanguages.FindString(sCountryTag);
        if(sIndex == -1)
        {
          sIndex = 0;
        }
        aRtempText.GetString(sIndex, sLangText, sizeof(sLangText));
        CheckMessageVariables(sLangText, sizeof(sLangText));
        CheckMessageClientVariables(i, sLangText, sizeof(sLangText));
        char sMultipleLines[5][512];
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
          char sMessageColor[32];
          char sMessagePosX[16];
          char sMessagePosY[16];
          char sMessageFadeIn[32];
          char sMessageFadeOut[16];
          char sMessageHoldTime[16];
          aRtemp.GetString(4, sMessageColor, sizeof(sMessageColor));
          aRtemp.GetString(5, sMessagePosX, sizeof(sMessagePosX));
          aRtemp.GetString(6, sMessagePosY, sizeof(sMessagePosY));
          aRtemp.GetString(7, sMessageFadeIn, sizeof(sMessageFadeIn));
          aRtemp.GetString(8, sMessageFadeOut, sizeof(sMessageFadeOut));
          aRtemp.GetString(9, sMessageHoldTime, sizeof(sMessageHoldTime));
          HudMessage(i, sMessageColor, sLangText, sMessagePosX, sMessagePosY, sMessageFadeIn, sMessageFadeOut, sMessageHoldTime);
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
