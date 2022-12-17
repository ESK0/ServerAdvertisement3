#define SA "[SA]"
#define PLUGIN_NAME "ServerAdvertisements"
#define PLUGIN_AUTHOR "ESK0"
#define PLUGIN_VERSION "3.3.0"

#define TAG_SIZE 64

enum struct SMessageGroup
{
	ArrayList mMessages;
	int mNextMsgIndex;
	Handle mhTimer;
}

enum struct SMessageEntry
{
	int mFlags;
	int mIgnoreFlags;
	int mColor[4];
	char mType[2];
	char mTag[TAG_SIZE];
	StringMap mTextByLanguage;
	ArrayList mHUDParams;

	bool HasAccess(int client)
	{
		return (CheckCommandAccess(client, "", this.mFlags, true)
			&& (this.mIgnoreFlags < 1 || !CheckCommandAccess(client, "", this.mIgnoreFlags, true)));
	}
}

enum struct SHUDParams
{
	int mChannel;
	int mEndColor[4];
	int mEffect;
	float mXPos;
	float mYPos;
	float mHoldTime;
	float mFadeIn;
	float mFadeOut;
}

char sConfigPath[PLATFORM_MAX_PATH];
char sServerName[TAG_SIZE];
char sMapName[128];
float fTime;
bool gRandomize;

StringMap gLanguages, gMessageGroups;

ConVar g_cV_Enabled;
bool g_b_Enabled;

bool bExpiredMessagesDebug;
char sDefaultLanguage[12];

float g_fWM_Delay;
SMessageEntry gWelcomeMessage;

Handle g_hSACustomLanguage;