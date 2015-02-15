 #pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>
#include <geoip>

#define PLUGIN_URL "https://github.com/ESK0"
#define FILE_PATH "addons/sourcemod/configs/ServerAdvertisement.cfg"
#define PLUGIN_VERSION "1.1a"
#define PLUGIN_AUTHOR "ESK0"

new g_iEnable;

new String: g_sTag[50];

new Handle: g_hMessages;
new any: g_fMessageDelay;


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
	LoadConfig();
	LoadMessages();
	if(g_iEnable)
	{
		CreateTimer(g_fMessageDelay, PrintAdverToAll, _, TIMER_REPEAT);
	}
	RegAdminCmd("sm_reloadsadvert", Event_ReloadAdvert, ADMFLAG_ROOT);
}
public Action: Event_ReloadAdvert(client, args)
{
	if(g_iEnable)
	{
		if(g_hMessages)
		{
			CloseHandle(g_hMessages);
		}
		LoadMessages();
		PrintToChat(client, "%s Messages are successfully reloaded.", g_sTag);
	}
}

public Action:PrintAdverToAll(Handle: timer)
{
	if(g_iEnable)
	{
		if(!KvGotoNextKey(g_hMessages))
		{
			KvGoBack(g_hMessages);
			KvGotoFirstSubKey(g_hMessages);
		}
		for(new i = 1 ; i < MaxClients; i++)
		{
			if(IsValidPlayer(i))
			{
				new String: sType[12];
				new String: sText[256];
				new String: sBuffer[256];
				new String: sCountryTag[3];
				new String: sIP[26];
				GetClientIP(i, sIP, sizeof(sIP));
				GeoipCode2(sIP, sCountryTag);
				KvGetString(g_hMessages, sCountryTag, sText, sizeof(sText), "LANGMISSING");

				if (StrEqual(sText, "LANGMISSING"))
				{
					KvGetString(g_hMessages, "default", sText, sizeof(sText));
				}
				if(StrContains(sText, "{CURRENTMAP}") != -1)
				{
					GetCurrentMap(sBuffer, sizeof(sBuffer));
					ReplaceString(sText, sizeof(sText), "{CURRENTMAP}", sBuffer);
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
	new Handle: hConfig = CreateKeyValues("ServerAdvertisement");
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
		KvGetString(hConfig, "Tag", g_sTag, sizeof(g_sTag));
	}
	else
	{
		SetFailState("Config for 'Server Advertisement' not found!");
		return;
	}
}
stock bool:IsValidPlayer(client, bool:alive = false){
    if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client))){
        return true;
    }

    return false;
}
