# ServerAdvertisement3
Very useful plugin for your server with which you can print messages to players. Messages are stored in file.

## Features
- Message Types:
	- Chat messages ***(Type T)*** - Color Support;
	- HUD messages ***(Type H)*** - R G B Color;
	- Center Text messages ***(Type C)*** - Support Only HTML **`hex`** colors;
	- Top Menu messages ***(Type M)*** - Which just permits to adjust the **`color`** setting in the CFG, [example](https://user-images.githubusercontent.com/15228896/164123861-13dcb895-d5ae-4a77-b022-bf41b12f485c.jpg);
- Multi-language support; ***(Use [Alpha-2 Codes](https://en.wikipedia.org/wiki/ISO_3166-1))***
- Support for breaking lines; **(`Use \n` to break lines)**
- Custom Tag for message; ***(Keep tag text empty to have message without tag)***
- Messages for specific maps; ***(all, de_dust2, de_inferno, de_, zm_, etc)*** - **(`"maps" "surf_;am_;awp_"`)**
- Message can be banned for certain maps if you use all, de_, ar_, etc; **(`"ignore_maps" "ar_;de_;etc"`)**
- Messages for specific flags; ***(a,b,c,d,z, etc)*** - **(`"flags" "a"`)**
- Message can be disabled for specific flags; ***(a,b,c,d,z, etc)*** - **(`"ignore" "d"`)**
- Enable/Disabled option per message; ***(Message can be temporarily disabled - By default its enabled)***
- Message can be enabled till any date; ***(Messages for some events or so)***
	- **Added Log Expired Messages** option in **Settings** part for debugging expired messages.
- Welcome Message;
- Client can change its language to any available language; ***(Language is stored in a cache)***

**AlliedModders:** https://forums.alliedmods.net/showthread.php?t=248314

## Admin Commands
- **`!sa3r`** - Messages reload;

## Client Commands
- **`!sa3lang`** - Client can change his language to any available language;

## Installation
- Move **ServerAdvertisements3.cfg** to your folder **`addons/sourcemod/configs`**;
- Move **ServerAdvertisements3.smx** to folder **`addons/sourcemod/plugins`**;
- Restart server;

## Config Editing
- Be careful with editing and be sure you did not forget any **{ } " " and/or any other symbol**;
- I recommend **[Notepad++](https://notepad-plus-plus.org/downloads/)** for editing config;
- Save config in **UTF-8 without BOM**;
- Keep language code in Settings part upper-case; ***(EN;PT;CZ;SK;FR)***

## Text variables
```
{NEXTMAP}
{CURRENTMAP}
{PLAYERCOUNT}
{CURRENTTIME}
{SERVERIP}
{SERVERNAME}
{PLAYERNAME}
{ADMINSONLINE}
{TIMELEFT}
{STEAMID}
{CONVAR} -> {mp_friendlyfire}, {sv_cheats}, or convar from any pluigin
{CURRENTDATE}
{CURRENTDATE_US}
{VIPONLINE} - Flag A
{TAG}
```

## Supported Colors (Maybe some will not work or be different)

#### CS:GO Only
```
Default
Darkred
Green
Lightgreen
Red
Blue
Olive
Lime
Lightred
Purple
Grey
Orange
Yellow
Bluegrey
Lightblue
Darkblue
Grey2
Orchid
```

#### Other Games
```
aliceblue
allies
ancient
antiquewhite
aqua
aquamarine
arcana
axis
azure
beige
bisque
black
blanchedalmond
blue
blueviolet
brown
burlywood
cadetblue
chartreuse
chocolate
collectors
common
community
coral
cornflowerblue
cornsilk
corrupted
crimson
cyan
darkblue
darkcyan
darkgoldenrod
darkgray
darkgrey
darkgreen
darkkhaki
darkmagenta
darkolivegreen
darkorange
darkorchid
darkred
darksalmon
darkseagreen
darkslateblue
darkslategray
darkslategrey
darkturquoise
darkviolet
deeppink
deepskyblue
dimgray
dimgrey
dodgerblue
exalted
firebrick
floralwhite
forestgreen
frozen
fuchsia
fullblue
fullred
gainsboro
genuine
ghostwhite
gold
goldenrod
gray
grey
green
greenyellow
haunted
honeydew
hotpink
immortal
indianred
indigo
ivory
khaki
lavender
lavenderblush
lawngreen
legendary
lemonchiffon
lightblue
lightcoral
lightcyan
lightgoldenrodyellow
lightgray
lightgrey
lightgreen
lightpink
lightsalmon
lightseagreen
lightskyblue
lightslategray
lightslategrey
lightsteelblue
lightyellow
lime
limegreen
linen
magenta
maroon
mediumaquamarine
mediumblue
mediumorchid
mediumpurple
mediumseagreen
mediumslateblue
mediumspringgreen
mediumturquoise
mediumvioletred
midnightblue
mintcream
mistyrose
moccasin
mythical
navajowhite
navy
normal
oldlace
olive
olivedrab
orange
orangered
orchid
palegoldenrod
palegreen
paleturquoise
palevioletred
papayawhip
peachpuff
peru
pink
plum
powderblue
purple
rare
red
rosybrown
royalblue
saddlebrown
salmon
sandybrown
seagreen
seashell
selfmade
sienna
silver
skyblue
slateblue
slategray
slategrey
snow
springgreen
steelblue
strange
tan
teal
thistle
tomato
turquoise
uncommon
unique
unusual
valve
vintage
violet
wheat
white
whitesmoke
yellow
yellowgreen
```
