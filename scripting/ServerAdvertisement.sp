 #pragma semicolon 1

#include <sourcemod>
#include <multicolors>
#include <cstrike>
#include <geoip>

#define PLUGIN_URL "https://github.com/ESK0"
#define FILE_PATH "addons/sourcemod/configs/ServerAdvertisement.cfg"
#define PLUGIN_VERSION "2.2"
#define PLUGIN_AUTHOR "ESK0"

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)

int g_iEnable;

char g_sTag[50];
char g_sTime[32];

Handle g_hMessages;
float g_fMessageDelay;


public Plugin myinfo =
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
  RegAdminCmd("sm_reloadsadvert", Event_ReloadAdvert, ADMFLAG_ROOT);
}
public OnMapStart()
{
  CreateTimer(g_fMessageDelay, Event_PrintAdvert, _,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public Action Event_PrintAdvert(Handle timer)
{
  PrintAdverToAll();
}
public Action Event_ReloadAdvert(int client, args)
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

public Action PrintAdverToAll()
{
	if(g_iEnable)
	{
		if(!KvGotoNextKey(g_hMessages))
		{
			KvGoBack(g_hMessages);
			KvGotoFirstSubKey(g_hMessages);
		}
		LoopClients(i)
		{
      if(IsValidPlayer(i))
      {
        char sType[12];
        char sText[256];
        char sBuffer[256];
        char sCountryTag[3];
        char sAdminList[128];
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
        if(StrContains(sText, "{SERVERIP}") != -1)
        {
          int ips[4];
          int ip = GetConVarInt(FindConVar("hostip"));
          int port = GetConVarInt(FindConVar("hostport"));
          ips[0] = (ip >> 24) & 0x000000FF;
          ips[1] = (ip >> 16) & 0x000000FF;
          ips[2] = (ip >> 8) & 0x000000FF;
          ips[3] = ip & 0x000000FF;
          Format(sBuffer, sizeof(sBuffer), "%d.%d.%d.%d:%d", ips[0], ips[1], ips[2], ips[3],port);
          ReplaceString(sText, sizeof(sText), "{SERVERIP}", sBuffer);
        }
        if(StrContains(sText, "{SERVERNAME}") != -1)
        {
          GetConVarString(FindConVar("hostname"), sBuffer,sizeof(sBuffer));
          ReplaceString(sText, sizeof(sText), "{SERVERNAME}", sBuffer);
        }
        if(StrContains(sText, "{ADMINSONLINE}") != -1)
        {
          LoopClients(x)
          {
            if(IsValidPlayer(x) && IsPlayerAdmin(x))
            {
              if(sAdminList[0] == 0) Format(sAdminList,sizeof(sAdminList),"%N", x);
              else Format(sAdminList,sizeof(sAdminList),",%N", x);
            }
          }
          ReplaceString(sText, sizeof(sText), "{ADMINSONLINE}", sAdminList);
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

        KvGetString(g_hMessages, "type", sType, sizeof(sType), "T");
        if(StrEqual(sType, "T", false))
        {
        	CPrintToChat(i,"%s %s",g_sTag, sText);
        }

        if(StrEqual(sType, "C", false))
        {
        	PrintHintText(i,"%s %s",g_sTag, sText);
        }
      }
		}
	}
}

public LoadMessages()
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
public LoadConfig()
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
    g_fMessageDelay = KvGetFloat(hConfig, "Delay_between_messages", 30.0);
    KvGetString(hConfig, "Time_Format", g_sTime, sizeof(g_sTime));
    KvGetString(hConfig, "Advertisement_tag", g_sTag, sizeof(g_sTag), "[Server]");
  }
  else
  {
    SetFailState("Config for 'Server Advertisement' not found!");
    return;
  }
  CloseHandle(hConfig);
}
stock bool IsValidPlayer(int client, bool alive = false)
{
    if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client))){
        return true;
    }
    return false;
}
stock bool IsPlayerAdmin(client)
{
	if (GetAdminFlag(GetUserAdmin(client), Admin_Generic))
    {
		return true;
	}
	return false;
}
