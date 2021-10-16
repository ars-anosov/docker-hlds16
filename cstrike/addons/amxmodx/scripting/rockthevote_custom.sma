/*
*			Made by DA
* 
* 			Description:
* 							This plugin allows the players on your server to vote for a mapvoting.
* 							The players can say in the chat "/rockthevote", "rockthevote" or "rtv" to vote for the vote.
* 							The maps will be automaticle loaded from the maps.ini (if it exists) or from the mapcycle.txt.
* 
* 			
* 			Installation:
* 							1. Download the rockthevote_custom.sma and compile it on your local machine.
* 							2. Put the rockthevote_custom.amxx in your plugins folder.
* 							3. Add at the end from the plugins.ini this line: rockthevote_custom.amxx
* 							4. Open your amxx.cfg (mod/addons/amxmodx/configs/) and add the cvar's.
* 							5. Restart or change the map from your server.
* 
* 							
* 			CVAR's:
* 							amx_timevote number             - Default 5      - After 5 MINUTES (Default) is rockthevote allowed.
* 							amx_howmanypercentage float     - Default 0.30   - When 30% (Default) of the players said rockthevote then comes the mapvote.
* 							amx_howmanyvotes number			- Default 8      - When 8 (default) players said rockthevote then comes the mapvote.
* 							amx_rocktime time	 			- Default 10     - After 10 (default) seconds the voting is over and the server change the map.  
* 
* 
* 			Credits:
* 							Deagles - The main idea
* 							arkshine - Some code
* 							X-olent - Percentage idea
* 
*/

#include <amxmodx>
#include <amxmisc>

#define PLUGIN	"RockTheVote"
#define AUTHOR	"DA"
#define VERSION	"1.8"

#define MAX_MAPS 5
#define MAX_MAP_LENGTH 64
#define MAPSINI "maps.ini"

new rtv[33], howmanyvotes, task_time, keycount[MAX_MAPS], s_Maps[MAX_MAPS][MAX_MAP_LENGTH], count;
new presskeys, howmanyvotesperc, timevote, directmapchange, bool:NextRoundChangeMap = false, nextmap[MAX_MAP_LENGTH];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_dictionary("mapchooser.txt");
	register_dictionary("common.txt");
	register_clcmd("say", "rockthevote");
	register_menu("Chose your Map", 1023, "gonna_chose");
	howmanyvotes = register_cvar("amx_howmanyvotes", "8");
	howmanyvotesperc = register_cvar("amx_howmanypercentage", "0.30");
	task_time = register_cvar("amx_rocktime", "10.0");
	timevote = register_cvar("amx_timevote", "5");
	directmapchange = register_cvar( "amx_directmapchange", "0" );
	
	register_logevent ( "RoundStart", 2, "1=Round_Start" );
	
	for (new i=0; i < MAX_MAPS+2; i++)
		presskeys = presskeys | (1<<i)
}

public  client_disconnect(id)
{
	if (rtv[id-1] == id)
	{
		rtv[id-1] = 0;
		count--;
	}
}

public RoundStart()
{
	if ( !get_pcvar_num( directmapchange ) && NextRoundChangeMap )
	{
		server_cmd( "amx_map %s", nextmap );
	}
}

public rockthevote(id)
{
	new said[192];
	read_args(said, 192);
	if	((contain(said, "/rockthevote") != -1) || (contain(said, "rockthevote") != -1) || (contain(said, "rtv") != -1))
	{
		if (get_gametime() < (get_pcvar_float(timevote) * 60.0))
			client_print(id, print_chat, "Голосование сейчас не доступно. Подождите %d минуты.", (floatround(((get_pcvar_float(timevote) * 60.0) - get_gametime()) / 60.0)));
		else
		{
			if	(rtv[id-1] == id)
				client_print(id, print_chat, "Ты уже голосовал!");
			else
			{
				rtv[id-1] = id;
				count++;
							
				static num;
				num = get_playersnum();
				num = floatround((get_pcvar_float(howmanyvotesperc) * num));
				if ((num == count) || (count >= get_pcvar_num(howmanyvotes)))
				{
					// AMXX Nextmap Chooser by cheap_suit
					if(find_plugin_byfile("mapchooser.amxx") != INVALID_PLUGIN_ID)
					{
						new oldWinLimit = get_cvar_num("mp_winlimit"), oldMaxRounds = get_cvar_num("mp_maxrounds");
						set_cvar_num("mp_winlimit",0); 
						set_cvar_num("mp_maxrounds",-1); 
  
						if(callfunc_begin("voteNextmap","mapchooser.amxx") == 1)
							callfunc_end();
  
						set_cvar_num("mp_winlimit",oldWinLimit);
						set_cvar_num("mp_maxrounds",oldMaxRounds);
						set_task(get_pcvar_float(task_time), "change_map", true);
						return PLUGIN_CONTINUE;
					}
				
					StartTheVote();
					return PLUGIN_CONTINUE;
				}
				static name[32];
				get_user_name( id, name, charsmax( name ) );
				
				client_print ( 0, print_chat, "%s голос добавлен. Осталось %d или %d^%^%  чтобы начать голосование!", name, (get_pcvar_num(howmanyvotes)-count), (floatround(get_pcvar_float(howmanyvotesperc) * 100.00)))
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public gonna_chose(id, key)
{
	if (key < MAX_MAPS)
	{
		keycount[key]++;
		static name[32]
		get_user_name(id, name, charsmax(name));
		client_print(0, print_chat, "%L", LANG_PLAYER, "X_CHOSE_X", name, s_Maps[key]);
	}
}

StartTheVote()
{
	if (!RetrieveMaps(s_Maps))
		return PLUGIN_CONTINUE;
	
	static i, chosetext[256];
	count=0;
	
	formatex(chosetext, charsmax(chosetext), "\y%L:\w^n^n", LANG_SERVER, "CHOOSE_NEXTM");
	for (i=0; i < MAX_MAPS; i++)
		formatex(chosetext, charsmax(chosetext), "%s%d. %s^n", chosetext, i+1, s_Maps[i]);
	
	
	formatex(chosetext, charsmax(chosetext), "%s^n%d. %L", chosetext, MAX_MAPS+2, LANG_SERVER, "NONE");
	client_cmd(0, "spk Gman/Gman_Choose2");
	client_print(0, print_chat, "%L", LANG_SERVER, "TIME_CHOOSE");
	show_menu(0, presskeys, chosetext, 15, "Chose your Map");
	set_task(get_pcvar_float(task_time), "change_map", false);
	return PLUGIN_CONTINUE;
}

	
bool:RetrieveMaps(s_MapsFound[][])
{
	new s_File[256], s_ConfigsDir[256];
	get_configsdir(s_ConfigsDir, 255);
	formatex(s_File, 255, "%s/%s", s_ConfigsDir, MAPSINI);
	
	if (!file_exists(s_File))
		get_cvar_string("mapcyclefile", s_File, charsmax(s_File)); 
		
	new s_CurrentMap[MAX_MAP_LENGTH];
	get_mapname(s_CurrentMap, charsmax(s_CurrentMap));

	new p_File = fopen(s_File, "rt");
	new Array:a_Maps;
	new i_MapsCount = SaveAllMaps(p_File, a_Maps);

	new bool:b_Error = true, i;   
	switch (i_MapsCount)
    {
        case 0             : log_amx("There are no maps in the %s.", s_File);
        case 1 .. MAX_MAPS : log_amx("Not enough maps found. (requires at least %d maps)", MAX_MAPS + 1 );
        default            :  b_Error = false;
    }
	if (b_Error)
    {
        fclose(p_File); 
        ArrayDestroy(a_Maps);
        return false;
    }
	fclose(p_File);

	new i_Rand, i_Cnt;
	while (i_Cnt != MAX_MAPS)
    {
        i_Rand = random_num(0, ArraySize(a_Maps) - 1);
        ArrayGetString(a_Maps, i_Rand, s_MapsFound[i_Cnt], MAX_MAP_LENGTH - 1);

        if (equal(s_MapsFound[i_Cnt], s_CurrentMap))
        {
            continue;
        }

        for (i = 0; i < i_Cnt; i++)
        {
            if (equal(s_MapsFound[i], s_MapsFound[i_Cnt]))
            {
                break;
            }
        }

        if (i == i_Cnt)
        {
            ArrayDeleteItem(a_Maps, i_Rand);
            i_Cnt++;
        }
    }
	ArrayDestroy(a_Maps);
	return true;
}

SaveAllMaps(p_File, &Array:a_Maps)
{
	a_Maps = ArrayCreate(MAX_MAP_LENGTH);
	new s_Buffer[MAX_MAP_LENGTH]
	
	while (!feof(p_File))
	{
		fgets(p_File, s_Buffer, charsmax(s_Buffer));
		trim(s_Buffer);
		if (!s_Buffer[0] || s_Buffer[0] == ';' || (s_Buffer[0] == '/' && s_Buffer[1] == '/'))
		{
			continue;
		}
		if (is_map_valid(s_Buffer))
		{
			ArrayPushString(a_Maps, s_Buffer);
		}
	}
	return ArraySize(a_Maps);
}

public change_map(bool:chooserornot)
{
	if (!chooserornot)
	{
		static keypuffer=0, i=0;
		for (i=0; i < MAX_MAPS; i++)
			if (keycount[i] > keycount[keypuffer])
				keypuffer = i;
			
		copy(nextmap, charsmax(nextmap), s_Maps[keypuffer]);
	}
	else
		get_cvar_string("amx_nextmap", nextmap, charsmax(nextmap));
		
	log_amx("Map will be changed to %s.", nextmap)
	if (chooserornot)
		client_print(0, print_chat, "%L", LANG_PLAYER, "CHO_FIN_NEXT", nextmap);
		
	if ( !get_pcvar_num( directmapchange ) )
	{
		set_hudmessage(210, 0, 0, 0.05, 0.45, 1, 20.0, 10.0, 0.5, 0.15, 4);
		show_hudmessage(0, "Это последний раунд");
		
		NextRoundChangeMap = true;
	}
	
	else
	{
		server_cmd("amx_map %s", nextmap);
	}
}
