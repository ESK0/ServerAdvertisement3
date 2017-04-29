stock void AddMessagesToArray(KeyValues kv)
{
  char sTempMap[64];
  kv.GetString("maps", sTempMap, sizeof(sTempMap), "all");
  if(StrEqual(sTempMap, "all") || StrEqual(sTempMap, sMapName) || StrContains(sMapName, sTempMap) != -1)
  {
    ArrayList aMessages = new ArrayList(512);
    ArrayList aMessages_Text = new ArrayList(512);

    char sMessageType[3];
    char sMessageTag[32];
    char sMessageFlags[16];
    char sTempLanguageName[12];
    char sTempLanguageMessage[512];
    char sMessageColor[32];
    char sMessagePosX[16];
    char sMessagePosY[16];
    char sMessageFadeIn[32];
    char sMessageFadeOut[16];
    char sMessageHoldTime[16];
    kv.GetString("type", sMessageType, sizeof(sMessageType), "T");
    kv.GetString("tag", sMessageTag, sizeof(sMessageTag), sServerName);
    kv.GetString("flags", sMessageFlags, sizeof(sMessageFlags), "all");
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
    aMessages.Push(aMessages_Text);
    if(StrEqual(sMessageType, "H", false))
    {
      kv.GetString("color", sMessageColor, sizeof(sMessageColor), "255 255 255");
      kv.GetString("posx", sMessagePosX, sizeof(sMessagePosX), "-1");
      kv.GetString("posy", sMessagePosY, sizeof(sMessagePosY), "0.05");
      kv.GetString("fadein", sMessageFadeIn, sizeof(sMessageFadeIn), "0.2");
      kv.GetString("fadeout", sMessageFadeOut, sizeof(sMessageFadeOut), "0.2");
      kv.GetString("holdtime", sMessageHoldTime, sizeof(sMessageHoldTime), "5.0");
      aMessages.PushString(sMessageColor);
      aMessages.PushString(sMessagePosX);
      aMessages.PushString(sMessagePosY);
      aMessages.PushString(sMessageFadeIn);
      aMessages.PushString(sMessageFadeOut);
      aMessages.PushString(sMessageHoldTime);
    }
    aMessagesList.Push(aMessages);
  }
}
stock void CheckMessageVariables(char[] message, int len)
{
  char sBuffer[256];
  if(StrContains(message , "{NEXTMAP}") != -1)
  {
    GetNextMap(sBuffer, sizeof(sBuffer));
    ReplaceString(message, len, "{NEXTMAP}", sBuffer);
  }

  if(StrContains(message, "{CURRENTMAP}") != -1)
  {
    GetCurrentMap(sBuffer, sizeof(sBuffer));
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
stock void HudMessage(int client, const char[] color, const char[] message, const char[] posx, const char[] posy, const char[] fadein, const char[] fadeout, const char[] holdtime)
{
  int ent = CreateEntityByName("game_text");
  DispatchKeyValue(ent, "channel", "1");
  DispatchKeyValue(ent, "color", color);
  DispatchKeyValue(ent, "color2", "0 0 0");
  DispatchKeyValue(ent, "effect", "0");
  DispatchKeyValue(ent, "fadein", fadein);
  DispatchKeyValue(ent, "fadeout", fadeout);
  DispatchKeyValue(ent, "fxtime", "0.25");
  DispatchKeyValue(ent, "holdtime", holdtime);
  DispatchKeyValue(ent, "message", message);
  DispatchKeyValue(ent, "spawnflags", "0");
  DispatchKeyValue(ent, "x", posx);
  DispatchKeyValue(ent, "y", posy);
  DispatchSpawn(ent);
  SetVariantString("!activator");
  AcceptEntityInput(ent,"display",client);
}
