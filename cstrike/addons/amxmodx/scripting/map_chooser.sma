#include <amxmodx>

/* Настройки */
#define BLOCK_MAPS 	10	// Количество последних сыгранных карт
#define VOTE_TIME	10	// Время голосования
#define MAP_ON_VOTE	5	// Карт в меню голосования

#define ROCK_THE_VOTE		// Функция rtv 
#define RTV_DELAY	180	// Задержка о начала карты для использования rtv функции (в секундах)
#define RTV_PERCENTS	60	// Процент голосов

// #define NOMINATE		// Функция номинаций
#define NOM_MAX		3	// Максимум карт для номинации
#define NOM_PLAYER	1	// Максимум карт для номинации одним игроком
#define SAY_MAPS		// Команда /maps
#define NOM_WITH_PREFIXES	// Номинация карты без префиксов(de_dust2 можно номинировать как dust2)

#define MAX_EXTENDS	3	// Количество продлений
#define EXTEND_TIME	15	// Время одного продления

#define SHOW_TIMELEFT		// Показывать в чате в начале раунда, сколько осталось до конца карты

#define ADMIN_ROCK_THE_VOTE	// Досрочное голосование у админов
#define ADMIN_RTV_TIME	5	
	// Сколько времени нужно играть на карте, чтобы можно было вызвать досрочное для админов
	// Команда в консоль сервера и админы с флагом ADMIN_RCON("l") имеют иммунитет к данной настройке
	// Закомментируйте, чтобы было доступно всегда

#define SHOW_MENU_WITH_PERCENTS // Показывать результаты с процентами голосов после выбора карты при голосовании

//#define ADMIN_DUAL_VOTE (ADMIN_MAP|ADMIN_LEVEL_H)
	// Голос админа(ADMIN_MAP) и VIP(ADMIN_LEVEL_H) имеют вес двух голосов 
//#define ONLY_GAME_PLAYERS
	// Считать только реальных игроков. Спектров не учитывать.
//#define BLOCK_CHATS
	// Блокировать VOICE и TEXT чаты на время голосования

#define VSEM_SPS_SOUND 	 "misc/neugomon/vsem_sps.wav" 
	// Звук в 3 сек перед сменой карты. 
	// Закомментируйте или удалите строку, если не требуется

//#define NO_ROUND_SUPPORT	// Режим работы в realtime. Для серверов CSDM

//#define NIGHTMODE
	// Ночной список карт. НЕ работает блокировка карт, сортировка по онлайну и номинации
	// Map List addons/amxmodx/configs/nmaps.ini | Просто список карт и все | ФАЙЛ НУЖНО СОЗДАТЬ САМОМУ!!!
#define BLOCK_CMDS		// Блокировать команды
#define NIGHT_START	1	// Начало ночного режима
#define NIGHT_END	10	// Окончание ночного режима

// ˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅ PLEASE, NOT EDIT IT'S CODE ˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅ 
// ˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅˅
#if !defined NIGHTMODE && defined BLOCK_CMDS
	#undef BLOCK_CMDS
#endif
#if !defined NOMINATE && defined NOM_WITH_PREFIXES
	#undef NOM_WITH_PREFIXES
#endif
// ˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄
// ˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄ PLEASE, NOT EDIT IT'S CODE ˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄˄

#if defined BLOCK_CMDS
	new g_szBlockCMDs[][] = { "amx_map", "amx_votemap", "amx_votemapmenu" };
		// Команды для блокировки во время ночного режима
		// Чтобы работала блокировка команд, нужно прописывать mapchooser  в plugins.ini выше плагина который выполняет эту команду!
#endif
#if defined NOM_WITH_PREFIXES
	new const g_szMapPrefixes[][] = { "de_", "cs_", "as_" };
		// Префиксы карт, используемые для быстрой номинации
#endif
new g_iColors[3] = { 50, 255, 50 };  // R G B цвет для HUD отсчета
new Float:g_fPos[2] = { -1.0, 0.6 }; // X и Y координаты в HUD отсчета

/* Словарь плагина */
#define MSG_NOMINATE_BLOCKED 		"^1[^4MM^1] ^4Данная карта была недавно сыграна!"
#define MSG_NOMINATE_DISABLE 		"^1[^4MM^1] ^4Номинация недоступна!"
#define MSG_NOMINATE_MAX_MAP_PL 	"^1[^4MM^1] ^4Вы уже номинировали максимум карт ^3[%d]^4!"
#define MSG_NOMINATE_MAX_MAP_ALL 	"^1[^4MM^1] ^4Уже номинировано максимум карт ^3[%d]^4!"
#define MSG_NOMINATE_MAP_NOMINATED	"^1[^4MM^1] ^4Данная карта уже номинирована!"
#define MSG_NOMINATE_PL_NOMINATEMAP	"^1[^4MM^1] ^3%s ^4номинировал карту ^3%s"

#define MSG_RTV_BLOCKED0		"^1[^4MM^1] ^4Досрочная смена карты будет доступна менее, чем через ^3минуту^4!"
#define MSG_RTV_BLOCKED			"^1[^4MM^1] ^4Досрочная смена карты будет доступна через ^3%d ^4мин!"
#define MSG_RTV_PL_VOTED		"^1[^4MM^1] ^4Вы уже голосовали! Осталось ^3%d ^4голосов"
#define MSG_RTV_PL_VOTE			"^1[^4MM^1] ^3%s ^4проголосовал за смену карты. Осталось ^3%d ^4голосов"
#define MSG_RTV_VOTE_START		"^1[^4MM^1] ^4Все голоса за досрочную смену карты набраны. ^3Последний ^4раунд"
#define MSG_ADMIN_RTV			"^1[^4MM^1] ^4Администратор ^3%s ^4запустил досрочную смену карты. ^3Последний ^4раунд"

#define MSG_CMD_FFIRE			"^1[^4MM^1] ^4На сервере огонь по своим  ^3%s"
#define MSG_CMD_THETIME			"^1[^4MM^1] ^4Текущее время ^3%s"
#define MSG_CMD_NEXTMAP			"^1[^4MM^1] ^4Следующая карта еще ^3не определена ^1:("
#define MSG_CMD_TIMELEFT0		"^1[^4MM^1] ^4Карта ^3не ограничена ^4по времени"
#define MSG_CMD_TIMELEFT		"^1[^4MM^1] ^4До конца карты осталось ^3%d ^4мин ^3%02d ^4сек"
#define MSG_CMD_TIMELEFT_LAST_RND	"^1[^4MM^1] ^4Карта окончена. ^3Последний ^4раунд!"

#define MSG_TIMELEFT_ON_ROUNDSTART	"^1[^4MM^1] ^4До конца карты осталось ^3%d ^4мин ^3%02d ^4сек%s"
#define MSG_NOTIMELIMIT_ON_ROUNDSTART	"^1[^4MM^1] ^4Карта ^3не ограничена ^4по времени"
#define MSG_TIMELEFT_ADD_LASTRND	". ^3Последний ^4раунд!"

#define MSG_TIME_TO_VOTE		"До голосования осталось %d сек!"

#define MSG_VOTEMAP_PL_EXT		"^1[^4MM^1] ^4Игрок ^3%s ^4выбрал ^3продление карты"
#define MSG_VOTEMAP_PL_MAP		"^1[^4MM^1] ^4Игрок ^3%s ^4выбрал карту ^3%s"

#define MSG_VOTE_END_NOVOTES		"^1[^4MM^1] ^4Никто ^3не проголосовал! ^4Cлучайная карта ^3%s"
#define MSG_VOTE_END_EXTENDED		"^1[^4MM^1] ^4Голосование ^3завершено! ^4Карта продлена на ^3%d ^4минут"
#define MSG_VOTE_END_NEXTMAP		"^1[^4MM^1] ^4Голосование ^3завершено! ^4Cледующая карта ^3%s"

#define MSG_NIGHT_BLOCK_CMD		"^1[^4MM^1] ^4Данная команда ^3заблокирована ^4в ^1ночном ^4режиме!"

/* Размерности массивов */
#define MAP_LENGTH  32
#define NAME_LENGTH 32
#if !defined MAX_PLAYERS
	const MAX_PLAYERS = 32;
#endif

enum _:aMAPS
{
	map[MAP_LENGTH],
	minpl,
	maxpl
}

new Trie:g_tBlockMaps;
#if defined NOMINATE
	new Trie:g_tAllowMaps;
	#if defined SAY_MAPS
		new g_iMapsMenu;
	#endif
#else
	#if defined SAY_MAPS
		#undef SAY_MAPS
	#endif	
#endif
new Array:g_arrAllMaps, 
	Array:g_arrNightMaps;

new g_szArrayData[aMAPS];
new g_szCurrentMap[MAP_LENGTH];

new g_iMapSortedByOnline = -1;
new g_iNumAllMaps,
	g_iNumNightMaps;

new g_iVoteItems;
new g_iMenuItemId[MAP_ON_VOTE+1];
new g_iSelectedItem[MAP_ON_VOTE+2];
new g_szMenuMapName[MAP_ON_VOTE+2][MAP_LENGTH];
#if defined ROCK_THE_VOTE || (defined ADMIN_ROCK_THE_VOTE && defined ADMIN_RTV_TIME)
	new g_iStartMap;
#endif
#if defined ROCK_THE_VOTE
	new g_iRtvVotes;
#endif
#if defined NOMINATE
	new g_iNominated[NOM_MAX+1];
	new g_iNominateNum;
	new g_iNominate[MAX_PLAYERS];
#endif
#if defined SHOW_MENU_WITH_PERCENTS
	new g_iVotes;
	new g_iTimeOst;
	new bool:g_bIsVoted[MAX_PLAYERS];
	new g_szPercentMenu[512];
#endif
#if defined BLOCK_CHATS
	new g_FM_SetClientListening;
#endif
/* cVar pointer's */
new g_pFreezeTime, g_pRoundTime, g_pTimeLimit, g_pC4timer, g_pChatTime;

/* cVar's data */
new g_iOldFreezeTime;
new Float:g_fOldTimeLimit, g_iTempTimelimit, g_iMapLimit;

/* Bit's */
enum _:st 
{ 
	preVote = 1,
	beInVote,
	voteStarted,
	nMode,
	blockExt
}
enum _:DATA 
{
#if defined ROCK_THE_VOTE
	status,
	rtVoted
#else
	status	
#endif
}
new g_bitData[DATA];
#define	GetBit(%1,%2)	(%1 & (1 << (%2 & 31)))
#define	SetBit(%1,%2)	%1 |= (1 << (%2 & 31))
#define	ResetBit(%1,%2)	%1 &= ~(1 << (%2 & 31))
#define is_map_valid_by_online(%0,%1,%2) (g_iMapSortedByOnline != 1 || g_szArrayData[%1] <= %0 <= g_szArrayData[%2])

new g_szSounds[][] =
{
	"",
	"fvox/one",
	"fvox/two",
	"fvox/three"
};
#if defined NO_ROUND_SUPPORT
	#tryinclude <reapi>
	#if !defined _reapi_included
		#include <hamsandwich>
		
		#define RG_CBasePlayer_Spawn Ham_Spawn
		#define HookChain HamHook
		#define EnableHookChain EnableHamForward
		#define DisableHookChain DisableHamForward
		#define RegisterHookChain(%0,%1,%2) RegisterHam(%0, "player", %1, %2)
		
		#define set_entvar set_pev
		#define get_entvar pev
		#define var_flags pev_flags
	#endif
	new HookChain:g_HookChainPlayerSpawn;
#endif
#if defined NO_ROUND_SUPPORT || defined BLOCK_CHATS
	#include <fakemeta>
#endif
#if AMXX_VERSION_NUM < 183
	#include <colorchat>
	#define client_disconnected client_disconnect
#endif	
#if defined VSEM_SPS_SOUND
public plugin_precache()
	precache_sound(VSEM_SPS_SOUND);
#endif
public plugin_init()
{
	register_plugin("Advanced MapChooser", "1.1.1", "neygomon");
#if defined NOMINATE || defined BLOCK_CHATS
	register_clcmd("say", 		"ClcmdHookSay");
	register_clcmd("say_team", 	"ClcmdHookSay");
#endif
#if defined SAY_MAPS
	register_clcmd("say /maps", 	"ClcmdSayMaps");
	register_clcmd("say_team /maps","ClcmdSayMaps");
#endif
#if defined BLOCK_CMDS
	for(new i; i < sizeof g_szBlockCMDs; ++i)
		register_clcmd(g_szBlockCMDs[i], "ClcmdBlock");
#endif
#if defined ROCK_THE_VOTE	
	register_clcmd("say /rtv", 	"ClcmdRockTheVote");
	register_clcmd("say rtv",  	"ClcmdRockTheVote");
#endif
#if defined ADMIN_ROCK_THE_VOTE
	register_concmd("amx_rtv",	"ConCmdAdminRockTheVote", ADMIN_MAP);
#endif
	register_clcmd("say ff", 	"ClcmdFF");
	register_clcmd("say nextmap", 	"ClcmdNextMap");
	register_clcmd("say timeleft", 	"ClcmdTimeLeft");
	register_clcmd("say thetime", 	"ClcmdTheTime");
	register_clcmd("votemap", 	"ClcmdVotemap");
#if !defined NO_ROUND_SUPPORT	
	register_event("HLTV", "eventHLTV", "a", "1=0", "2=0");
#else
	#if defined SHOW_TIMELEFT
		#undef SHOW_TIMELEFT
	#endif
	set_task(60.0, "eventHLTV", .flags="b");
#endif	
	g_pFreezeTime= get_cvar_pointer("mp_freezetime");
	g_pRoundTime = get_cvar_pointer("mp_roundtime");
	g_pTimeLimit = get_cvar_pointer("mp_timelimit");
	g_pC4timer   = get_cvar_pointer("mp_c4timer");
	g_pChatTime  = get_cvar_pointer("mp_chattime");

	register_menucmd(register_menuid("Map Chooser"), (-1^(-1<<(MAP_ON_VOTE+2))), "mapchooser_handler");
#if defined ROCK_THE_VOTE	
	g_iStartMap = get_systime();
#endif	
}

public plugin_cfg()
{
	g_tBlockMaps = TrieCreate();
#if defined NOMINATE	
	g_tAllowMaps = TrieCreate();
#endif	
	g_arrAllMaps = ArrayCreate(aMAPS);
#if defined NIGHTMODE
	g_arrNightMaps = ArrayCreate(aMAPS);
#endif
	get_mapname(g_szCurrentMap, charsmax(g_szCurrentMap));

	LoadBlockMaps();
	LoadAllowMaps();
}

public plugin_end()
{
	if(g_iOldFreezeTime)
		set_pcvar_num(g_pFreezeTime, g_iOldFreezeTime);
	if(g_fOldTimeLimit > 0.0)
		set_pcvar_float(g_pTimeLimit, g_fOldTimeLimit);
	
	TrieDestroy(g_tBlockMaps);
#if defined NOMINATE	
	TrieDestroy(g_tAllowMaps);
#endif	
	ArrayDestroy(g_arrAllMaps);
#if defined NIGHTMODE
	ArrayDestroy(g_arrNightMaps);
#endif	
}

public client_disconnected(id)
{
#if defined ROCK_THE_VOTE	
	if(GetBit(g_bitData[rtVoted], id))
	{
		g_iRtvVotes--;
		ResetBit(g_bitData[rtVoted], id);
	}
#endif	
#if defined NOMINATE	
	g_iNominate[id] = 0;
#endif	
}
#if defined BLOCK_CHATS
public FM_SetClientListening_Pre(iRecv, iSender, listen)
{
	if(iRecv == iSender)
		return FMRES_IGNORED;
	
	engfunc(EngFunc_SetClientListening, iRecv, iSender, false);
	forward_return(FMV_CELL, false);
	return FMRES_SUPERCEDE;
}
#endif
#if defined NOMINATE || defined BLOCK_CHATS
public ClcmdHookSay(id)
{
#if defined BLOCK_CHATS
	if(GetBit(g_bitData[status], preVote) || GetBit(g_bitData[status], beInVote))
		return PLUGIN_HANDLED;
#endif		
#if defined NOMINATE
	if(GetBit(g_bitData[status], nMode))
		return PLUGIN_CONTINUE;

	static szMessage[MAP_LENGTH+5];
	read_args(szMessage, charsmax(szMessage));
	remove_quotes(szMessage);
	#if defined NOM_WITH_PREFIXES
	if(!fnNominateMap(id, szMessage))
	{
		for(new i, szMapName[32]; i < sizeof g_szMapPrefixes; ++i)
		{
			formatex(szMapName, charsmax(szMapName), "%s%s", g_szMapPrefixes[i], szMessage);
			if(fnNominateMap(id, szMapName))
				return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
	#else
	return fnNominateMap(id, szMessage);
	#endif
#else
	return PLUGIN_CONTINUE;	
#endif
}
#endif
#if defined SAY_MAPS
public ClcmdSayMaps(id)
{
	if(GetBit(g_bitData[status], nMode))
		return PLUGIN_HANDLED;

	menu_display(id, g_iMapsMenu, 0);
	return PLUGIN_HANDLED;
}		

public mapsnominate_handler(id, menu, item)
{
	if(item != MENU_EXIT)
	{
		new _access, callback, mapp[32];
		menu_item_getinfo(menu, item, _access, mapp, charsmax(mapp), .callback = callback);
		fnNominateMap(id, mapp);
	}
	return PLUGIN_HANDLED;
}

public mapsnominate_callback(id, menu, item)
{
	new _access, callback, mapp[32];
	menu_item_getinfo(menu, item, _access, mapp, charsmax(mapp), .callback = callback);
	new aPos; TrieGetCell(g_tAllowMaps, mapp, aPos);
	return nominated_map(aPos) ? ITEM_DISABLED : ITEM_ENABLED;
}
#endif
#if defined NOMINATE
fnNominateMap(id, mapp[])
{
	static aPos;
	if(TrieKeyExists(g_tBlockMaps, mapp))
		return client_print_color(id, print_team_default, MSG_NOMINATE_BLOCKED);
	else if(!TrieGetCell(g_tAllowMaps, mapp, aPos))
		return PLUGIN_CONTINUE;
	else if(GetBit(g_bitData[status], voteStarted) || GetBit(g_bitData[status], beInVote))
		return client_print_color(id, print_team_default, MSG_NOMINATE_DISABLE);
	else if(g_iNominate[id] == NOM_PLAYER)
		return client_print_color(id, print_team_default, MSG_NOMINATE_MAX_MAP_PL, NOM_PLAYER);
	else if(g_iNominateNum == NOM_MAX)
		return client_print_color(id, print_team_default, MSG_NOMINATE_MAX_MAP_ALL, NOM_MAX); 
	else if(nominated_map(aPos))
		return client_print_color(id, print_team_default, MSG_NOMINATE_MAP_NOMINATED);
	
	g_iNominated[g_iNominateNum] = aPos;
	g_iNominate[id]++;
	g_iNominateNum++;

	new szName[NAME_LENGTH]; get_user_name(id, szName, charsmax(szName));
	return client_print_color(0, print_team_default, MSG_NOMINATE_PL_NOMINATEMAP, szName, mapp);
}
#endif
#if defined BLOCK_CMDS
public ClcmdBlock(id)
	return GetBit(g_bitData[status], nMode) ? client_print_color(0, print_team_default, MSG_NIGHT_BLOCK_CMD) : PLUGIN_CONTINUE;
#endif
#if defined ROCK_THE_VOTE
public ClcmdRockTheVote(id)
{
	if(GetBit(g_bitData[status], voteStarted) || GetBit(g_bitData[status], beInVote) || !valid_rtv(id))
		return PLUGIN_HANDLED;

	if(GetBit(g_bitData[rtVoted], id))
		client_print_color(id, print_team_default, MSG_RTV_PL_VOTED, floatround(get_playersnum() * RTV_PERCENTS / 100.0) - g_iRtvVotes);
	else
	{
		SetBit(g_bitData[rtVoted], id);
		g_iRtvVotes++;
		new vote = floatround(get_playersnum() * RTV_PERCENTS / 100.0) - g_iRtvVotes;
		
		if(vote > 0)
		{
			static szName[NAME_LENGTH]; get_user_name(id, szName, charsmax(szName));
			client_print_color(0, print_team_default, MSG_RTV_PL_VOTE, szName, vote);
			log_amx("%s проголосовал за смену карты. Осталось %d голосов", szName, vote);
		}
		else
		{
			SetBit(g_bitData[status], voteStarted);
			SetBit(g_bitData[status], blockExt);
	
			client_print_color(0, print_team_default, MSG_RTV_VOTE_START);
			log_amx("Досрочное голосование запущено");
		}
	}	
	return PLUGIN_HANDLED;
}
#endif
#if defined ADMIN_ROCK_THE_VOTE
public ConCmdAdminRockTheVote(id, bitAccess)
{
	if(GetBit(g_bitData[status], voteStarted) || GetBit(g_bitData[status], preVote) || GetBit(g_bitData[status], beInVote))
		return PLUGIN_HANDLED;
#if defined ADMIN_RTV_TIME
	if(id)
	{
		new flags = get_user_flags(id);
		if(~flags & ADMIN_RCON)
		{
			if(~flags & bitAccess)
				return PLUGIN_HANDLED;

			new time = (get_systime() - g_iStartMap) / 60;
			if(ADMIN_RTV_TIME > time)
			{
				client_print_color(id, print_team_default, "^1[^4MM^1] ^3Досрочное голосование ^4будет доступно через ^3%d ^4мин", ADMIN_RTV_TIME - time);
				return PLUGIN_HANDLED;
			}
		}
	}
#endif	
	SetBit(g_bitData[status], voteStarted);
	SetBit(g_bitData[status], blockExt);

	new szName[32]; get_user_name(id, szName, charsmax(szName));
	client_print_color(0, print_team_default, MSG_ADMIN_RTV, szName);
	log_amx("Администратор %s запустил досрочную смену карты", szName);
	return PLUGIN_HANDLED;
}				
#endif
public ClcmdFF(id)
	return client_print_color(id, print_team_default, MSG_CMD_FFIRE, get_cvar_num("mp_friendlyfire") ? "разрешен" : "запрещен");

public ClcmdTheTime(id)
{
	new time[64]; get_time ("%d.%m.%Y # %H:%M:%S", time, charsmax(time));
	return client_print_color(id, print_team_default, MSG_CMD_THETIME, time);
}

public ClcmdNextMap(id)
	return client_print_color(id, print_team_default, MSG_CMD_NEXTMAP);

public ClcmdTimeLeft(id)
{
	if(GetBit(g_bitData[status], voteStarted))
	{
		return client_print_color(id, print_team_default, MSG_CMD_TIMELEFT_LAST_RND);
	}

	new a = get_timeleft();
	if(a > 0) return client_print_color(id, print_team_default, MSG_CMD_TIMELEFT, (a / 60), (a % 60));
	return client_print_color(id, print_team_default, MSG_CMD_TIMELEFT0);
}

public ClcmdVotemap()
	return PLUGIN_HANDLED;

public eventHLTV()
{
	if(GetBit(g_bitData[status], voteStarted))
	{
		ResetBit(g_bitData[status], voteStarted);
		StartVote();
		return;
	}	
#if defined NIGHTMODE	
	if(g_iNumNightMaps)
	{
		new iHour; time(iHour);
		if(NIGHT_START > NIGHT_END && (iHour >= NIGHT_START || iHour < NIGHT_END)) // thx radius_r16
			SetBit(g_bitData[status], nMode);
		else if(NIGHT_START <= iHour < NIGHT_END)
			SetBit(g_bitData[status], nMode);
		else	ResetBit(g_bitData[status], nMode);
	}
#endif
	new Float:fTimeLimit = get_pcvar_float(g_pTimeLimit);
	new Float:fRoundTime = get_pcvar_float(g_pRoundTime);

	new a = get_timeleft();
	if((fRoundTime * 60 + VOTE_TIME * 2) > float(a) && fTimeLimit)
	{
		g_iTempTimelimit = floatround(fTimeLimit);
		if(g_fOldTimeLimit == 0.0)
		{
			g_fOldTimeLimit = fTimeLimit;
			g_iMapLimit = g_iTempTimelimit + MAX_EXTENDS * EXTEND_TIME;
		}
		if(g_iTempTimelimit >= g_iMapLimit)
		{
			if(!GetBit(g_bitData[status], blockExt))
				SetBit(g_bitData[status], blockExt);
		}
		
		SetBit(g_bitData[status], voteStarted);

		new Float:fAddTime = (fRoundTime * 60 + get_pcvar_float(g_pC4timer) + get_pcvar_float(g_pChatTime) + VOTE_TIME + 60) / 60;
		set_pcvar_float(g_pTimeLimit, fTimeLimit + fAddTime);
	}
#if defined SHOW_TIMELEFT
	if(a > 0)
	{
		client_print_color(0, print_team_default, MSG_TIMELEFT_ON_ROUNDSTART, 
			(a / 60), (a % 60), GetBit(g_bitData[status], voteStarted) ? MSG_TIMELEFT_ADD_LASTRND : "");
	}		
	else	client_print_color(0, print_team_default, MSG_NOTIMELIMIT_ON_ROUNDSTART);
#endif	
}
#if defined NO_ROUND_SUPPORT
public CBasePlayer_Spawn_Post(const id)
{
	if(is_user_alive(id))
		set_entvar(id, var_flags, get_entvar(id, var_flags) | FL_FROZEN);
}
#endif
public StartVote()
{
	if(!g_iOldFreezeTime) 
		g_iOldFreezeTime = get_pcvar_num(g_pFreezeTime);

	SetBit(g_bitData[status], preVote);
	ScreenFade(1);
	FrozenUsers(1);
	
	set_task(1.0, "ShowTimer", .flags = "a", .repeat = 4);
}

public ShowTimer()
{
	static timer = 3;
	switch(timer)
	{
		case 0:
		{
			timer = 3;
			ShowVoteMenu();
		}	
		default:
		{
			set_hudmessage(g_iColors[0], g_iColors[1], g_iColors[2], g_fPos[0], g_fPos[1], 0, 0.0, 1.0, 0.0, 0.0, 4);
			show_hudmessage(0, MSG_TIME_TO_VOTE, timer);
			client_cmd(0, "spk %s", g_szSounds[timer--]);
		}
	}
}

public ShowVoteMenu()
{
	g_iVoteItems = 0;
#if defined SHOW_MENU_WITH_PERCENTS	
	g_iVotes = 0;
	arrayset(g_bIsVoted, false, sizeof g_bIsVoted);
#endif	
	ResetBit(g_bitData[status], preVote);
	SetBit(g_bitData[status], beInVote);

	new maxMaps = GetBit(g_bitData[status], nMode) ? g_iNumNightMaps : g_iNumAllMaps;
	new maxVoteMap = (MAP_ON_VOTE > maxMaps) ? maxMaps : MAP_ON_VOTE;
	new szMenu[512], iKeys, iLen;
	new plrsnum;
	
	if(!GetBit(g_bitData[status], nMode))
	{	
	#if defined ONLY_GAME_PLAYERS	
		new pl[32], pnum;
		get_players(pl, pnum, "e", "TERRORIST"); plrsnum = pnum;
		get_players(pl, pnum, "e", "CT"); 	 plrsnum += pnum;
	#else
		plrsnum = get_playersnum();
	#endif
		if(!valid_maps_on_vote(plrsnum))
			g_iMapSortedByOnline = 0;
	}

	iLen = formatex(szMenu, charsmax(szMenu), "\d[\rMap to Choose\d] \yВыберите карту^n^n");
#if defined NOMINATE
	if(!GetBit(g_bitData[status], nMode) && g_iNominateNum)
	{
		for(new i; i < g_iNominateNum; ++i)
		{
			ArrayGetArray(g_arrAllMaps, g_iNominated[i], g_szArrayData);
			if(!is_map_valid_by_online(plrsnum, minpl, maxpl))
				continue;
			
			g_iMenuItemId[g_iVoteItems] = g_iNominated[i];
			copy(g_szMenuMapName[g_iVoteItems], charsmax(g_szMenuMapName[]), g_szArrayData[map]);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s^n", g_iVoteItems+1, g_szMenuMapName[g_iVoteItems]);
			iKeys |= (1 << g_iVoteItems++);
		}
	}
#endif
	new item;
	while(maxVoteMap > g_iVoteItems)
	{
		do item = random(maxMaps);
		while(item_in_menu(item));
		
		g_iMenuItemId[g_iVoteItems] = item;

		if(GetBit(g_bitData[status], nMode))
		{
			ArrayGetArray(g_arrNightMaps, item, g_szArrayData);
			copy(g_szMenuMapName[g_iVoteItems], charsmax(g_szMenuMapName[]), g_szArrayData[map]);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s^n", g_iVoteItems+1, g_szMenuMapName[g_iVoteItems]);
			iKeys |= (1 << g_iVoteItems++);
		}
		else
		{
			ArrayGetArray(g_arrAllMaps, item, g_szArrayData);
			if(!is_map_valid_by_online(plrsnum, minpl, maxpl))
				continue;
			
			copy(g_szMenuMapName[g_iVoteItems], charsmax(g_szMenuMapName[]), g_szArrayData[map]);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s^n", g_iVoteItems+1, g_szMenuMapName[g_iVoteItems]);
			iKeys |= (1 << g_iVoteItems++);
		}
	}
	if(!GetBit(g_bitData[status], blockExt))
	{
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r%d. \w%s \d[\rПродлить\d]", g_iVoteItems+1, g_szCurrentMap);
		iKeys |= (1 << g_iVoteItems);
	}
	
	show_menu(0, iKeys, szMenu, VOTE_TIME, "Map Chooser");
	
	client_cmd(0, "spk Gman/Gman_Choose2");
	log_amx("[Start VoteMap] Голосование началось...");
#if defined SHOW_MENU_WITH_PERCENTS
	g_iTimeOst = VOTE_TIME;
	set_task(1.0, "ShowCacheMenu", 100, .flags = "a", .repeat = VOTE_TIME);
#else
	set_task(float(VOTE_TIME), "GoToCheckVotes");
#endif
}

public mapchooser_handler(id, iKey)
{
	static szName[NAME_LENGTH]; 
	get_user_name(id, szName, charsmax(szName));

	if(iKey == g_iVoteItems)
		client_print_color(0, id, MSG_VOTEMAP_PL_EXT, szName);
	else 	client_print_color(0, id, MSG_VOTEMAP_PL_MAP, szName, g_szMenuMapName[iKey]);
#if defined ADMIN_DUAL_VOTE
	if(get_user_flags(id) & ADMIN_DUAL_VOTE)
	{
		g_iSelectedItem[iKey] += 2;
		#if defined SHOW_MENU_WITH_PERCENTS
		g_iVotes += 2;
		#endif
	}
	else
	{
		g_iSelectedItem[iKey]++;
		#if defined SHOW_MENU_WITH_PERCENTS
		g_iVotes++;
		#endif
	}
#else
	g_iSelectedItem[iKey]++;
#endif
#if defined SHOW_MENU_WITH_PERCENTS
	g_bIsVoted[id] = true;
	#if !defined ADMIN_DUAL_VOTE
	g_iVotes++;
	#endif
	ShowCacheMenu(id);
#endif
	return PLUGIN_HANDLED;
}
#if defined SHOW_MENU_WITH_PERCENTS
public ShowCacheMenu(id)
{
	if(id == 100)
	{
		g_iTimeOst--;
		if(!g_iTimeOst)
		{
			show_menu(0, 0, "^n", 1);
			GoToCheckVotes();
		}
		else
		{
			new len = formatex(
				g_szPercentMenu, charsmax(g_szPercentMenu), 
				"\d[\rMap to Choose\d] \yВы уже проголосовали^n\wДо конца голосования осталось \r%d \wсек!^n^n",
				g_iTimeOst
			);

			for(new i; i < g_iVoteItems; ++i)
			{
				len += formatex(
					g_szPercentMenu[len], charsmax(g_szPercentMenu) - len, 
					"\r%d. \w%s \d[\y%d%%\d]^n", 
						i+1, g_szMenuMapName[i], g_iVotes ? floatround(g_iSelectedItem[i] * 100.0 / g_iVotes) : 0
				);
			}
			
			if(!GetBit(g_bitData[status], blockExt))
			{
				len += formatex(
					g_szPercentMenu[len], charsmax(g_szPercentMenu) - len, 
					"^n\r%d. \w%s \d[\rПродлить\d][\y%d%%\d]", 
						g_iVoteItems+1, g_szCurrentMap, g_iVotes ? floatround(g_iSelectedItem[g_iVoteItems] * 100.0 / g_iVotes) : 0
				);
			}
#define KEY (1 << 10)
		#if AMXX_VERSION_NUM < 183
			static MaxClients; if(!MaxClients) MaxClients = get_maxplayers();
		#endif
			for(new id = 1; id <= MaxClients; id++)
			{
				if(!g_bIsVoted[id])
					continue;
				if(!is_user_connected(id))
				{
					g_bIsVoted[id] = false;
					continue;
				}
				
				show_menu(id, KEY, g_szPercentMenu, -1, "ShowPercentMenu");
			}
		}
	}
	else	show_menu(id, KEY, g_szPercentMenu, -1, "ShowPercentMenu");
}
#endif
public GoToCheckVotes()
{
	new x;
	for(new i; i < MAP_ON_VOTE+1; ++i)
		if(g_iSelectedItem[x] < g_iSelectedItem[i])
			x = i;

	if(!g_iSelectedItem[x])
	{
		new mp = random(g_iVoteItems);
		client_print_color(0, print_team_default, MSG_VOTE_END_NOVOTES, g_szMenuMapName[mp]);
		log_amx("[End VoteMap] Никто не голосовал. Случайная карта %s", g_szMenuMapName[mp]);
		ChangeLevel(g_szMenuMapName[mp]);

	}
	else if(g_iSelectedItem[x] == g_iSelectedItem[g_iVoteItems])
	{
		client_print_color(0, print_team_default, MSG_VOTE_END_EXTENDED, EXTEND_TIME);
		log_amx("[End VoteMap] Голосование завершено. Карта %s была продлена на %d минут", g_szCurrentMap, EXTEND_TIME);
#if defined NOMINATE
		g_iNominateNum = 0;
		arrayset(g_iNominate, 0, sizeof g_iNominate);
		arrayset(g_iNominated, 0, sizeof g_iNominated);
#endif		
		arrayset(g_iSelectedItem, 0, sizeof g_iSelectedItem);
		ResetBit(g_bitData[status], beInVote);
		ResetBit(g_bitData[status], blockExt);
		
		set_pcvar_float(g_pTimeLimit, float(g_iTempTimelimit + EXTEND_TIME));
		ScreenFade(0);
	}
	else
	{
		client_print_color(0, print_team_default, MSG_VOTE_END_NEXTMAP, g_szMenuMapName[x]);
		log_amx("[End VoteMap] Голосование завершено %s", g_szMenuMapName[x]);
		ChangeLevel(g_szMenuMapName[x]);
	}
	FrozenUsers(0);
}

LoadBlockMaps()
{
	new szPath[75];
	get_localinfo("amxx_datadir", szPath, charsmax(szPath));
	add(szPath, charsmax(szPath), "/block_maps.ini");

	new fp = fopen(szPath, "rt");
	new i = 1;
	new szBuffer[BLOCK_MAPS+1][MAP_LENGTH];
	
	TrieSetCell(g_tBlockMaps, g_szCurrentMap, 0);
	if(fp)
	{
		while(!feof(fp) && BLOCK_MAPS > i)
		{
			fgets(fp, szBuffer[i], charsmax(szBuffer[])), trim(szBuffer[i]);
			if(szBuffer[i][0] && szBuffer[i][0] != ';')
				TrieSetCell(g_tBlockMaps, szBuffer[i], i), i++;
		}
		fclose(fp);
		unlink(szPath);
	}
	if(write_file(szPath, "; File generated by Advanced MapChooser!"))
	{
		copy(szBuffer[0], charsmax(szBuffer[]), g_szCurrentMap);
		for(new x; x < i; x++) write_file(szPath, szBuffer[x]);
	}
}

LoadAllowMaps()
{
	new szPath[64], szFile[75];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	formatex(szFile, charsmax(szFile), "%s/maps.ini", szPath);

	new fp = fopen(szFile, "rt");
	if(!fp)
	{
		new fmt[128]; formatex(fmt, charsmax(fmt), "Файл %s не найден, либо невозможно открыть!", szFile);
		set_fail_state(fmt);
	}

	new szBuffer[MAP_LENGTH + 10], szMinpl[3], szMaxpl[3];
	new iNumParams;
#if defined NOMINATE	
	new i;
#endif
#if defined SAY_MAPS
	g_iMapsMenu = menu_create("\d[\rMaps Nominate\d] \wВыберите карту", "mapsnominate_handler");
	new callback = menu_makecallback("mapsnominate_callback");
#endif
	while(!feof(fp))
	{
		fgets(fp, szBuffer, charsmax(szBuffer));
		if(!szBuffer[0] || szBuffer[0] == ';')
			continue;

		iNumParams = parse(
			szBuffer, 
			g_szArrayData[map], charsmax(g_szArrayData[map]), 
			szMinpl, charsmax(szMinpl), 
			szMaxpl, charsmax(szMaxpl)
		);

		if(!iNumParams)
			continue;
		if(!valid_map(g_szArrayData[map]))
			continue;

		switch(iNumParams)
		{
			case 1:
			{

				if(g_iMapSortedByOnline == 1)
					continue;

				ArrayPushArray(g_arrAllMaps, g_szArrayData);
				g_iMapSortedByOnline = 0;
#if defined NOMINATE				
				TrieSetCell(g_tAllowMaps, g_szArrayData[map], i); i++;
#endif	
#if defined SAY_MAPS
				menu_additem(g_iMapsMenu, g_szArrayData[map], g_szArrayData[map], 0, callback);
#endif				
			}
			case 3:
			{
				if(g_iMapSortedByOnline == 0)
					continue;

				g_szArrayData[minpl] = str_to_num(szMinpl);
				g_szArrayData[maxpl] = str_to_num(szMaxpl);
				ArrayPushArray(g_arrAllMaps, g_szArrayData);
				g_iMapSortedByOnline = 1;
#if defined NOMINATE				
				TrieSetCell(g_tAllowMaps, g_szArrayData[map], i); i++;
#endif
#if defined SAY_MAPS
				menu_additem(g_iMapsMenu, g_szArrayData[map], g_szArrayData[map], 0, callback);
#endif	
			}
		}
	}
	fclose(fp);

	g_iNumAllMaps = ArraySize(g_arrAllMaps);
	
	log_amx("Загружено %d карт из %s", g_iNumAllMaps, szFile);
	log_amx("Режим сортировки карт по онлайну %s!", g_iMapSortedByOnline ? "включен" : "выключен");
#if defined NIGHTMODE
	formatex(szFile, charsmax(szFile), "%s/nmaps.ini", szPath);
	fp = fopen(szFile, "rt");
	if(fp)
	{
		while(!feof(fp))
		{
			fgets(fp, szBuffer, charsmax(szBuffer));
			if(!szBuffer[0] || szBuffer[0] == ';')
				continue;
			
			parse(szBuffer, g_szArrayData[map], charsmax(g_szArrayData[map]));
			if(strcmp(g_szCurrentMap, g_szArrayData[map]) != 0)
				ArrayPushArray(g_arrNightMaps, g_szArrayData);
		}
		fclose(fp);

		g_iNumNightMaps = ArraySize(g_arrNightMaps);
		log_amx("Загружено %d карт для NightMode[%d - %d] из %s", g_iNumNightMaps, NIGHT_START, NIGHT_END, szFile);
	}	
#endif
}

public ScreenFade(fade)
{
	new flags;
	new time = (0 <= fade <= 1) ? 4096 : 1;
	new hold = (0 <= fade <= 1) ? 1024 : 1;
	static mScreenFade; if(!mScreenFade) mScreenFade = get_user_msgid("ScreenFade");
	
	switch(fade)
	{
		case 0:
		{
			flags = 2;
			set_msg_block(mScreenFade, BLOCK_NOT);
		}
		case 1:
		{
			flags = 1;
			set_task(1.0, "ScreenFade", 2);
		}
		case 2:
		{
			flags = 4;
			set_msg_block(mScreenFade, BLOCK_SET);
		}
	}
	
	message_begin(MSG_ALL, mScreenFade);
	write_short(time);
	write_short(hold);
	write_short(flags);
	write_byte(0);
	write_byte(0);
	write_byte(0);
	write_byte(255);
	message_end();
}

FrozenUsers(frozen)
{
#if defined NO_ROUND_SUPPORT
	new players[32], pnum;
	get_players(players, pnum);
#endif
	if(frozen)
	{
	#if defined NO_ROUND_SUPPORT
		for(new i; i < pnum; ++i)
			set_entvar(players[i], var_flags, get_entvar(players[i], var_flags) | FL_FROZEN);
		
		if(g_HookChainPlayerSpawn)
			EnableHookChain(g_HookChainPlayerSpawn);
		else	g_HookChainPlayerSpawn = RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Post", true);
	#else
		set_pcvar_num(g_pFreezeTime, VOTE_TIME + 5);
	#endif
	#if defined BLOCK_CHATS
		g_FM_SetClientListening = register_forward(FM_Voice_SetClientListening, "FM_SetClientListening_Pre", false);
	#endif
	}
	else
	{
	#if defined NO_ROUND_SUPPORT
		for(new i; i < pnum; ++i)
			set_entvar(players[i], var_flags, get_entvar(players[i], var_flags) & ~FL_FROZEN);
		
		DisableHookChain(g_HookChainPlayerSpawn);
	#else
		set_pcvar_num(g_pFreezeTime, g_iOldFreezeTime);
	#endif
	#if defined BLOCK_CHATS	
		unregister_forward(FM_Voice_SetClientListening, g_FM_SetClientListening, false);
	#endif
	}
}

ChangeLevel(mp[])
{
#if defined VSEM_SPS_SOUND
	client_cmd(0, "spk %s", VSEM_SPS_SOUND);
#endif
	emessage_begin(MSG_ALL, SVC_INTERMISSION);
	emessage_end();

	set_task(3.0, "SendCmd", .parameter = mp, .len = strlen(mp) + 1);
}

public SendCmd(mp[])
	server_cmd("changelevel %s", mp);
	
stock bool:valid_map(mp[])
{
	if(!is_map_valid(mp))
		return false;
	if(TrieKeyExists(g_tBlockMaps, mp))
		return false;

	return true;
}
stock bool:item_in_menu(mapid)
{
	for(new i; i < g_iVoteItems; ++i)
		if(g_iMenuItemId[i] == mapid)
			return true;
	return false;
}
stock bool:nominated_map(mapid)
{
	for(new i; i < g_iNominateNum; ++i)
		if(g_iNominated[i] == mapid)
			return true;
	return false;		
}
stock bool:valid_rtv(id)
{
	new iEstTime = get_systime() - g_iStartMap;
	if(iEstTime > RTV_DELAY)
		return true;

	new frmt[190]; 
	new temp = (RTV_DELAY - iEstTime) / 60;

	if(temp < 1) 	formatex(frmt, charsmax(frmt), MSG_RTV_BLOCKED0);
	else 		formatex(frmt, charsmax(frmt), MSG_RTV_BLOCKED, temp);

	client_print_color(id, print_team_default, frmt);
	return false;
}
stock bool:valid_maps_on_vote(players)
{
	new count;
	for(new i; i < g_iNumAllMaps; ++i)
	{
		ArrayGetArray(g_arrAllMaps, i, g_szArrayData);
		if(g_szArrayData[minpl] <= players <= g_szArrayData[maxpl])
			count++;
	}
	return (count >= MAP_ON_VOTE);
}