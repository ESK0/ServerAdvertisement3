stock void AddMessagesToArray(KeyValues kv)
{
  bool bEnabled;
  bEnabled = view_as<bool>(kv.GetNum("enabled", 1));
  if(bEnabled)
  {
    if(SA_CheckDate(kv))
    {
      char sTempMap[256];
      char sBannedMap[512];
      kv.GetString("maps", sTempMap, sizeof(sTempMap), "all");
      kv.GetString("ignore_maps", sBannedMap, sizeof(sBannedMap), "none");
      if(SA_CheckIfMapIsBanned(sMapName, sBannedMap))
      {
        return;
      }
      if(StrEqual(sTempMap, "all") || SA_ContainsMap(sMapName, sTempMap) || SA_ContainsMapPreFix(sMapName, sTempMap))
      {
        ArrayList aMessages = new ArrayList(512);
        ArrayList aMessages_Text = new ArrayList(512);

        char sMessageType[3];
        char sMessageTag[64];
        char sMessageFlags[16];
        char sMessageFlagsIgnore[16];
        char sTempLanguageName[12];
        char sTempLanguageMessage[512];
        kv.GetString("type", sMessageType, sizeof(sMessageType), "T");
        kv.GetString("tag", sMessageTag, sizeof(sMessageTag), sServerName);
        kv.GetString("flags", sMessageFlags, sizeof(sMessageFlags), "all");
        kv.GetString("ignore", sMessageFlagsIgnore, sizeof(sMessageFlagsIgnore), "none");
        if(strlen(sMessageFlags) == 0)
        {
          Format(sMessageFlags, sizeof(sMessageFlags), "all");
        }
        if(strlen(sMessageFlagsIgnore) == 0)
        {
          Format(sMessageFlagsIgnore, sizeof(sMessageFlagsIgnore), "none");
        }
        for(int i = 0; i < aLanguages.Length; i++)
        {
          aLanguages.GetString(i, sTempLanguageName, sizeof(sTempLanguageName));
          kv.GetString(sTempLanguageName, sTempLanguageMessage, sizeof(sTempLanguageMessage), "NOLANG");
          if(StrEqual(sTempLanguageMessage, "NOLANG"))
          {
            SetFailState("%s '%s' translation missing in message \"%i\"", SA3, sTempLanguageName, aMessagesList.Length+1);
            return;
          }
          aMessages_Text.PushString(sTempLanguageMessage);
        }
        aMessages.PushString(sMessageType);
        aMessages.PushString(sMessageTag);
        aMessages.PushString(sMessageFlags);
        aMessages.PushString(sMessageFlagsIgnore);
        aMessages.Push(aMessages_Text);
        bool isHUD = StrEqual(sMessageType, "H", false);

        if (isHUD || StrEqual(sMessageType, "M", false)) // HUD or top menu message?
        {
          CopyKeyValuesColor(kv, "color", _, aMessages);
        }

        if (isHUD)
        {
          CopyKeyValuesColor(kv, "color2", {255, 255, 51, 255}, aMessages);
          aMessages.Push(kv.GetNum("effect", 0));
          aMessages.Push(kv.GetNum("channel", 1));
          aMessages.Push(kv.GetFloat("posx", -1.0));
          aMessages.Push(kv.GetFloat("posy", 0.05));
          aMessages.Push(kv.GetFloat("fadein", 0.2));
          aMessages.Push(kv.GetFloat("fadeout", 0.2));
          aMessages.Push(kv.GetFloat("holdtime", 5.0));
        }
        aMessagesList.Push(aMessages);
      }
    }
  }
}
stock void CheckMessageVariables(char[] message, int len)
{
  char sBuffer[256];
  ConVar hConVar;
  char sConVar[64];
  char sSearch[64];
  char sReplace[64];
  int iCustomCvarEnd = -1;
  int iCustomCvarStart = StrContains(message, "{");
  int iCustomCvarNextStart;
  if(iCustomCvarStart != -1)
  {
    while(iCustomCvarStart != -1)
    {
        iCustomCvarEnd = StrContains(message[iCustomCvarStart+1], "}");
        if(iCustomCvarEnd != -1)
        {
          strcopy(sConVar, iCustomCvarEnd+1, message[iCustomCvarStart+1]);
          Format(sSearch, sizeof(sSearch), "{%s}", sConVar);
          hConVar = FindConVar(sConVar);
          if(hConVar)
          {
              hConVar.GetString(sReplace, sizeof(sReplace));
              ReplaceString(message, len, sSearch, sReplace, false);
          }
          iCustomCvarNextStart = StrContains(message[iCustomCvarStart+1], "{");
          if(iCustomCvarNextStart != -1)
          {
            iCustomCvarStart += iCustomCvarNextStart+1;
          }
          else break;
        }
        else break;
    }
  }

  if(StrContains(message , "{CURRENTDATE}") != -1)
  {
    FormatTime(sBuffer, sizeof(sBuffer), "%d-%m-%Y");
    ReplaceString(message, len, "{CURRENTDATE}", sBuffer);
  }

  if(StrContains(message , "{CURRENTDATE_US}") != -1)
  {
    FormatTime(sBuffer, sizeof(sBuffer), "%m-%d-%Y");
    ReplaceString(message, len, "{CURRENTDATE_US}", sBuffer);
  }

  if(StrContains(message , "{NEXTMAP}") != -1)
  {
    GetNextMap(sBuffer, sizeof(sBuffer));
    ReplaceString(message, len, "{NEXTMAP}", sBuffer);
  }

  if(StrContains(message, "{CURRENTMAP}") != -1)
  {
    char sTempMap[256];
    GetCurrentMap(sTempMap, sizeof(sTempMap));
    GetMapDisplayName(sTempMap, sBuffer, sizeof(sBuffer));
    ReplaceString(message, len, "{CURRENTMAP}", sBuffer);
  }

  if(StrContains(message, "{PLAYERCOUNT}") != -1)
  {
    Format(sBuffer, sizeof(sBuffer), "%i", CountPlayers());
    ReplaceString(message, len, "{PLAYERCOUNT}", sBuffer);
  }

  if(StrContains(message, "{CURRENTTIME}") != -1)
  {
    FormatTime(sBuffer, sizeof(sBuffer), "%H:%M:%S");
    ReplaceString(message, len, "{CURRENTTIME}", sBuffer);
  }

  if(StrContains(message, "{SERVERIP}") != -1)
  {
    GetServerIP(sBuffer, sizeof(sBuffer));
    ReplaceString(message, len, "{SERVERIP}", sBuffer);
  }

  if(StrContains(message, "{SERVERNAME}") != -1)
  {
    GetConVarString(FindConVar("hostname"), sBuffer,sizeof(sBuffer));
    ReplaceString(message, len, "{SERVERNAME}", sBuffer);
  }

  if(StrContains(message , "{TIMELEFT}") != -1)
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
    ReplaceString(message, len, "{TIMELEFT}", sBuffer);
  }
  if(StrContains(message, "{ADMINSONLINE}") != -1)
  {
    char sAdminList[128];
    LoopClients(x)
    {
      if(IsValidClient(x) && IsPlayerAdmin(x))
      {
       if(sAdminList[0] == 0) Format(sAdminList,sizeof(sAdminList),"'%N'", x);
       else Format(sAdminList,sizeof(sAdminList),"%s,'%N'",sAdminList, x);
      }
    }
    ReplaceString(message, len, "{ADMINSONLINE}", sAdminList);
  }
  if(StrContains(message, "{VIPONLINE}") != -1)
  {
    char sAdminList[128];
    LoopClients(x)
    {
      if(IsValidClient(x) && IsPlayerVIP(x))
      {
       if(sAdminList[0] == 0) Format(sAdminList,sizeof(sAdminList),"'%N'", x);
       else Format(sAdminList,sizeof(sAdminList),"%s,'%N'",sAdminList, x);
      }
    }
    ReplaceString(message, len, "{VIPONLINE}", sAdminList);
  }
}
stock void SA_GetClientLanguage(int client, char buffer[3])
{
  char sBuffer[12], sIP[26];
  GetClientCookie(client, g_hSA3CustomLanguage, sBuffer, sizeof(sBuffer));

  if (!StrEqual(sBuffer, "geoip", false))
  {
    int index = -1;

    if (StrEqual(sBuffer, "ingame", false) || StrEqual(sDefaultLanguage, "ingame", false)
      && (index = aLanguages.FindString(sBuffer)) < 0)
    {
      SA_GetInGameLanguage(client, sBuffer, sizeof(sBuffer));
      index = aLanguages.FindString(sBuffer);
    }

    if (index > -1)
    {
      FormatEx(buffer, sizeof(buffer), sBuffer);
      return;
    }
  }

  GetClientIP(client, sIP, sizeof(sIP));
  GeoipCode2(sIP, buffer);
  String_ToLower(buffer, buffer, sizeof(buffer));
}
stock void CheckMessageClientVariables(int client, char[] message, int len)
{
  char sBuffer[256];
  if(StrContains(message, "{STEAMID}") != -1)
  {
    GetClientAuthId(client, AuthId_Engine, sBuffer, sizeof(sBuffer));
    ReplaceString(message, len, "{STEAMID}", sBuffer);
  }

  if(StrContains(message , "{PLAYERNAME}") != -1)
  {
    Format(sBuffer, sizeof(sBuffer), "%N", client);
    ReplaceString(message, len, "{PLAYERNAME}", sBuffer);
  }
}
stock int CountPlayers()
{
  int count = 0;
  LoopClients(i)
  {
    count++;
  }
  return count;
}
stock void GetServerIP(char[] buffer, int len)
{
  int ips[4];
  int ip = GetConVarInt(FindConVar("hostip"));
  int port = GetConVarInt(FindConVar("hostport"));
  ips[0] = (ip >> 24) & 0x000000FF;
  ips[1] = (ip >> 16) & 0x000000FF;
  ips[2] = (ip >> 8) & 0x000000FF;
  ips[3] = ip & 0x000000FF;
  Format(buffer, len, "%d.%d.%d.%d:%d", ips[0], ips[1], ips[2], ips[3], port);
}

stock void CopyKeyValuesColor(KeyValues keyValues, const char[] name,
  int color[4] = {255, 255, 255, 255}, ArrayList list)
{
  if (keyValues.JumpToKey(name))
  {
    keyValues.GetColor4(NULL_STRING, color);
    keyValues.GoBack();
  }

  list.PushArray(color, sizeof(color));
}

stock void HudMessage(int client, int color1[4], int color2[4], int effect, int channel, const char[] message,
  float posx, float posy, float fadein, float fadeout, float holdtime)
{
  SetHudTextParamsEx(posx, posy, holdtime, color1, color2, effect, 0.25, fadein, fadeout);
  ShowHudText(client, channel, message);
}

stock void DisplayTopMenuMessage(int client, const char[] message, int color[4])
{
  KeyValues keyValues = new KeyValues("menu", "title", message);
  keyValues.SetNum("level", 1);
  keyValues.SetColor4("color", color);
  CreateDialog(client, keyValues, DialogType_Msg);
  delete keyValues;
}

stock bool SA_DateCompare(int currentdate[3], int availabletill[3])
{
  if(availabletill[0] > currentdate[0])
  {
    return true;
  }
  else if(availabletill[0] == currentdate[0])
  {
    if(availabletill[1] > currentdate[1])
    {
      return true;
    }
    else if(availabletill[1] == currentdate[1])
    {
      if(availabletill[2] >= currentdate[2])
      {
        return true;
      }
    }
  }
  return false;
}
stock bool SA_CheckIfMapIsBanned(const char[] currentmap, const char[] bannedmap)
{
  char sBannedMapExploded[64][256];
  int count = ExplodeString(bannedmap, ";", sBannedMapExploded, sizeof(sBannedMapExploded), sizeof(sBannedMapExploded[]));
  for(int i = 0; i < count; i++)
  {
    if(StrEqual(sBannedMapExploded[i], currentmap) || StrContains(currentmap, sBannedMapExploded[i]) != -1)
    {
      return true;
    }
  }
  return false;
}
stock bool SA_ContainsMapPreFix(const char[] mapname, const char[] prefix)
{
  char sPreFixExploded[32][12];
  int count = ExplodeString(prefix, ";", sPreFixExploded, sizeof(sPreFixExploded), sizeof(sPreFixExploded[]));
  for(int i = 0; i < count; i++)
  {
    if(StrContains(mapname, sPreFixExploded[i]) != -1)
    {
      return true;
    }
  }
  return false;
}
stock bool SA_ContainsMap(const char[] currentmap, const char[] mapname)
{
  char sMapExploded[32][12];
  int count = ExplodeString(mapname, ";", sMapExploded, sizeof(sMapExploded), sizeof(sMapExploded[]));
  for(int i = 0; i < count; i++)
  {
    if(StrEqual(sMapExploded[i], currentmap))
    {
      return true;
    }
  }
  return false;
}
stock void SA_GetInGameLanguage(int client, char[] sLanguage, int len)
{
  char sFullName[3];
  int iLangId = GetClientLanguage(client);
  GetLanguageInfo(iLangId, sLanguage, len, sFullName, sizeof(sFullName));
}
stock bool SA_CheckDate(KeyValues kv)
{
  char sEnabledTill[32];
  char sEnabledTillEx[3][12];
  kv.GetString("enabledtill", sEnabledTill, sizeof(sEnabledTill), "");
  if(strlen(sEnabledTill) > 0)
  {
    int iEnabledTill = ExplodeString(sEnabledTill, ".", sEnabledTillEx, sizeof(sEnabledTillEx), sizeof(sEnabledTillEx[]));
    if(iEnabledTill != 3)
    {
      SetFailState("%s (1) Wrong date format in message %i. Use: DD.MM.YYYY",SA3, aMessagesList.Length+1);
    }
  }
  else
  {
    return true;
  }
  int iExpDate[3];
  int iCurrentDate[3];
  char sCurrentYear[12];
  char sCurrentYearEx[3][12];
  FormatTime(sCurrentYear, sizeof(sCurrentYear), "%Y.%m.%d");
  ExplodeString(sCurrentYear, ".", sCurrentYearEx, sizeof(sCurrentYearEx), sizeof(sCurrentYearEx[]));

  iCurrentDate[0] = StringToInt(sCurrentYearEx[0]);
  iCurrentDate[1] = StringToInt(sCurrentYearEx[1]);
  iCurrentDate[2] = StringToInt(sCurrentYearEx[2]);

  iExpDate[0] = StringToInt(sEnabledTillEx[2]);
  iExpDate[1] = StringToInt(sEnabledTillEx[1]);
  iExpDate[2] = StringToInt(sEnabledTillEx[0]);

  if(((strlen(sEnabledTillEx[0]) != 2) || (strlen(sEnabledTillEx[1]) != 2) || (strlen(sEnabledTillEx[2]) != 4) || iExpDate[2] > 31 || iExpDate[1] > 12))
  {
    SetFailState("%s (2) Wrong date format in message %i. Use: DD.MM.YYYY",SA3, aMessagesList.Length+1);
  }
  else
  {
    if(SA_DateCompare(iCurrentDate, iExpDate))
    {
      return true;
    }
    else
    {
      if(bExpiredMessagesDebug == true)
      {
        LogError("%s Message #%i is not available anymore. The message expired on %s",SA3, aMessagesList.Length+1, sEnabledTill);
      }
    }
  }
  return false;
}