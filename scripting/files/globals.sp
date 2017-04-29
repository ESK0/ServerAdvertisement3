#define SA3 "[SA3]"

char sConfigPath[PLATFORM_MAX_PATH];
char sServerName[32];
char sMapName[64];
float fTime;


Handle g_h_Timer;
ArrayList aMessagesList;
ArrayList aLanguages;

ConVar g_cV_Enabled;
bool g_b_Enabled;

int g_iCurrentMessage;
