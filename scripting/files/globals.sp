#define SA3 "[SA3]"

char sConfigPath[PLATFORM_MAX_PATH];
char sServerName[64];
char sMapName[128];
float fTime;

int iMySql;


Handle g_h_Timer;
ArrayList aMessagesList;
ArrayList aLanguages;

ConVar g_cV_Enabled;
bool g_b_Enabled;


int g_iCurrentMessage;
bool bExpiredMessagesDebug;
char sServerType[32];
char sDefaultLanguage[12];

Database hDB = null;
char sDBerror[512];
//char sDBquery[512];

int g_iWM_Enabled;
char g_sWM_Type[2];
float g_fWM_Delay;
char g_sWM_Flags[32];
int g_iWM_FlagsBit;
ArrayList aWelcomeMessage;

Handle g_hSA3CustomLanguage;

int iGameText = -1;
