 #pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>
#include <geoip>

#define PLUGIN_URL "https://github.com/ESK0"
#define FILE_PATH "addons/sourcemod/configs/ServerAdvertisement.cfg"
#define PLUGIN_VERSION "1.3"
#define PLUGIN_AUTHOR "ESK0"

int g_iEnable;

char g_sTag[50];
char g_sTime[32];

Handle g_hMessages;
float g_fMessageDelay;


public Plugin:myinfo =
{
	name = "Server Advertisement",
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	description = "Server Advertisement",
	url = PLUGIN_URL
};

public OnPluginStart()
{
  CreateConVar("ServerAdvertisement_version", PLUGIN_VERSION, "Server Advertisement plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  LoadConfig();
  LoadMessages();
  if(g_iEnable)
  {
  	CreateTimer(g_fMessageDelay, PrintAdverToAll, _, TIMER_REPEAT);
  }
  RegAdminCmd("sm_reloadsadvert", Event_ReloadAdvert, ADMFLAG_ROOT);
}
public Action: Event_ReloadAdvert(int client, args)
{
	if(g_iEnable)
	{
		if(g_hMessages)
		{
			CloseHandle(g_hMessages);
		}
		LoadMessages();
		CPrintToChat(client, "%s Messages are successfully reloaded.", g_sTag);
	}
}

public Action:PrintAdverToAll(Handle timer)
{
	if(g_iEnable)
	{
		if(!KvGotoNextKey(g_hMessages))
		{
			KvGoBack(g_hMessages);
			KvGotoFirstSubKey(g_hMessages);
		}
		for(int i = 1 ; i < MaxClients; i++)
		{
      if(IsValidPlayer(i))
      {
        char sType[12];
        char sText[256];
        char sBuffer[256];
        char sCountryTag[3];
        char sIP[26];
        GetClientIP(i, sIP, sizeof(sIP));
        GeoipCode2(sIP, sCountryTag);
        KvGetString(g_hMessages, sCountryTag, sText, sizeof(sText), "LANGMISSING");

        if (StrEqual(sText, "LANGMISSING"))
        {
        	KvGetString(g_hMessages, "default", sText, sizeof(sText));
        }
        if(StrContains(sText , "{NEXTMAP}") != -1)
        {
        	GetNextMap(sBuffer, sizeof(sBuffer));
        	ReplaceString(sText, sizeof(sText), "{NEXTMAP}", sBuffer);
        }
        if(StrContains(sText, "{CURRENTMAP}") != -1)
        {
        	GetCurrentMap(sBuffer, sizeof(sBuffer));
        	ReplaceString(sText, sizeof(sText), "{CURRENTMAP}", sBuffer);
        }
        if(StrContains(sText, "{CURRENTTIME}") != -1)
        {
        	FormatTime(sBuffer, sizeof(sBuffer), g_sTime);
        	ReplaceString(sText, sizeof(sText), "{CURRENTTIME}", sBuffer);
        }
        if(StrContains(sText , "{TIMELEFT}") != -1)
        {
          int i_Minutes;
          int i_Seconds;
          int i_Time;
          if(GetMapTimeLeft(i_Time) && i_Time > 0)
          {
            i_Minutes = i_Time / 60;
            i_Seconds = i_Time % 60;
          }
          Format(sBuffer, sizeof(sBuffer), "%d:%02d", i_Minutes, i_Seconds);
          ReplaceString(sText, sizeof(sText), "{TIMELEFT}", sBuffer);
        }

        KvGetString(g_hMessages, "type", sType, sizeof(sType));
        if(StrContains(sType, "T", false) != -1)
        {
        	CPrintToChat(i,"%s %s",g_sTag, sText);
        }

        if(StrContains(sType, "C", false) != -1)
        {
        	PrintCenterText(i,"%s %s",g_sTag, sText);
        }
      }
		}
	}
}

LoadMessages()
{
	g_hMessages = CreateKeyValues("ServerAdvertisement");
	if(!FileExists(FILE_PATH))
	{
		SetFailState("[ServerAdvertisement] 'addons/sourcemod/configs/ServerAdvertisement.cfg' not found!");
		return;
	}
	FileToKeyValues(g_hMessages, FILE_PATH);
	if(KvJumpToKey(g_hMessages, "Messages"))
	{
		KvGotoFirstSubKey(g_hMessages);
	}
}
LoadConfig()
{
	Handle hConfig = CreateKeyValues("ServerAdvertisement");
	if(!FileExists(FILE_PATH))
	{
		SetFailState("[ServerAdvertisement] 'addons/sourcemod/configs/ServerAdvertisement.cfg' not found!");
		return;
	}
	FileToKeyValues(hConfig, FILE_PATH);
	if(KvJumpToKey(hConfig, "Settings"))
	{
    g_iEnable = KvGetNum(hConfig, "Enable", 1);
    g_fMessageDelay = KvGetFloat(hConfig, "Delay", 30.0);
    KvGetString(hConfig, "TimeFormat", g_sTime, sizeof(g_sTime));
    KvGetString(hConfig, "Tag", g_sTag, sizeof(g_sTag));
	}
	else
	{
		SetFailState("Config for 'Server Advertisement' not found!");
		return;
	}
}
stock bool:IsValidPlayer(int client, bool alive = false){
    if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client))){
        return true;
    }

    return false;
}
