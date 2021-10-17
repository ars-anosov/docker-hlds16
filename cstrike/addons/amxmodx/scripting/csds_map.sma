/*
*	Скачано с GM-Serv.Ru
*	Готовые сервера, плагины, моды, модули, карты, патчи...
*	Также: форум, мониторинг, топ сайтов
*/

#include <amxmodx>
#include <amxmisc>

#pragma semicolon 1

stock __dhud_color;
stock __dhud_x;
stock __dhud_y;
stock __dhud_effect;
stock __dhud_fxtime;
stock __dhud_holdtime;
stock __dhud_fadeintime;
stock __dhud_fadeouttime;
stock __dhud_reliable;


new const PLUGIN[]  = "Csds Map";
new const VERSION[] = "3.24";
new const AUTHOR[]  = "Deags/AMXX Community/rmx 9 rpamm!?/rmx 2 TalRasha";

#define DEDICATED_LOG_ENABLED

#define MAX_MAPS_AMOUNT 600
#define ADMIN_DMAP ADMIN_LEVEL_A
#define ADMIN_SUPER_DMAP ADMIN_LEVEL_F

new const DMAP_MENU_TITLE[] = "DMAP_MENU_TITLE";

#define DMAP_VOTE_TIME 20
#define DMAP_TASKID_VTR 10000

new maps_to_select, isbuytime = 0, isbetween = 0;
new ban_last_maps = 0, quiet = 0;	//quiet=0 (words and sounds) quiet=1 (words only, no sound) quiet=2 (no sound, no words)
new Float:rtvpercent, Float:thespeed, Float:oldtimelimit;
new minimum = 1, minimumwait = 18, enabled = 1, cycle = 0, dofreeze = 1, maxnom = 3, maxcustnom = 18, frequency = 3, oldwinlimit = 0, addthiswait = 0;
new mapsurl[64], amt_custom = 0;
new isend = 0, isspeedset = 0, istimeset = 0, iswinlimitset = 0, istimeset2 = 0, mapssave = 0, atstart;
new usestandard = 1, currentplayers = 0, activeplayers = 0, counttovote = 0, countnum = 0;
new inprogress = 0, rocks = 0, rocked[33], hasbeenrocked = 0, waited = 0;
new pathtomaps[64];
new custompath[50];
new nmaps[MAX_MAPS_AMOUNT][32];
new listofmaps[MAX_MAPS_AMOUNT][32];
new totalbanned = 0;
new banthesemaps[MAX_MAPS_AMOUNT][32];
new totalmaps = 0;
new lastmaps[100 + 1][32];
new bannedsofar = 0;
new standard[50][32];
new standardtotal = 0;
new nmaps_num = 0;	//this is number of nominated maps
new nbeforefill;
new nmapsfill[MAX_MAPS_AMOUNT][32];
new num_nmapsfill;	//this is number of maps in users admin.cfg file that are valid
new bool:bIsCstrike;
new nnextmaps[10];
new nvotes[12];		// Holds the number of votes for each map
new nmapstoch, before_num_nmapsfill = 0, bool:mselected = false;
#if defined DEDICATED_LOG_ENABLED
new logfilename[256];
#endif
new teamscore[2], last_map[32];
new Nominated[MAX_MAPS_AMOUNT];		//?
new whonmaps_num[MAX_MAPS_AMOUNT];
new curtime = 0, staytime = 0, curplayers = 0, currounds = 0;

new pDmapStrict;		// Pointer to dmap_strict
new pEmptyMap;			// Pointer to amx_emptymap
new pEmptymapAllowed;		// Pointer to emptymap_allowed
new pEnforceTimelimit;		// Pointer to enforce_timelimit
new pExtendmapMax;		// Pointer to amx_extendmap_max
new pExtendmapStep;		// Pointer to amx_extendmap_step
new pIdleTime;			// Pointer to amx_idletime"
new pNominationsAllowed;	// Pointer to nominations_allowed
new pShowActivity;		// Pointer to amx_show_activity
new pWeaponDelay;		// Pointer to weapon_delay

new g_TotalVotes;		// Running total used to calculate percentages
new bool:g_AlreadyVoted[33];	// Keep track of who voted in current round
new g_VoteTimeRemaining;	// Used to set duration of display of vote menu

forward public hudtext16(textblock[], colr, colg, colb, posx, posy, screen, time, id);
forward bool:isbanned(map[]);
forward bool:iscustommap(map[]);
forward bool:islastmaps(map[]);
forward bool:isnominated(map[]);
forward public handle_nominate(id, map[], bool:bForce);
forward available_maps();
forward public getready();
forward public timetovote();
forward public messagefifteen();
forward public messagenominated();
forward public messagemaps();
forward public stopperson();
forward public countdown();
forward public rock_it_now();
forward public timedisplay();
forward public messagethree();

public client_connect(id) {
	if (!is_user_bot(id)) {
		currentplayers++;
	}
	return PLUGIN_CONTINUE;
}

public loopmessages() {
	if (quiet == 2) {	//quiet=0 (words and sounds) quiet=1 (words only, no sound) quiet=2 (no sound, no words)
		return PLUGIN_HANDLED;
	}
	new timeleft = get_timeleft();
	new partialtime = timeleft % 370;
	new maintime = timeleft % 600;
	if ((maintime > 122 && maintime < 128) && timeleft > 114) {
		set_task(1.0, "timedisplay", 454510, "", 0, "a", 14);
	}
	if ((partialtime > 320 && partialtime < 326) && !cycle) {
		set_task(3.0, "messagethree", 987300);	//, "", 0, "a", 10)
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public timedisplay() {
	new timeleft = get_timeleft();
	new seconds = timeleft % 60;
	new minutes = floatround((timeleft - seconds) / 60.0);
	if (timeleft < 1) {
		remove_task(454510);
		remove_task(454500);
		remove_task(123452);
		remove_task(123499);
		return PLUGIN_HANDLED;
	}
	if (timeleft > 140) {
		remove_task(454500);
	}
	if (timeleft > 30) {
		set_hudmessage(255, 255, 220, 0.02, 0.2, 0, 1.0, 1.04, 0.0, 0.05, 3);
	} else {
		set_hudmessage(210, 0 ,0, 0.02, 0.15, 0, 1.0, 1.04, 0.0, 0.05, 3);
		//Flashing red:set_hudmessage(210, 0, 0, 0.02, 0.2, 1, 1.0, 1.04, 0.0, 0.05, 3);
	}
	show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_TIME_LEFT", minutes, seconds);
	if (timeleft < 70 && (timeleft % 5) == 1) {
		new smap[32];
		get_cvar_string("amx_nextmap", smap, 31);
		set_hudmessage(0, 132, 255, 0.02, 0.27, 0, 5.0, 5.04, 0.0, 0.5, 4);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_NEXTMAP", smap);
	}
	return PLUGIN_HANDLED;
	
}

public messagethree() {
	new timeleft = get_timeleft();
	new time2 = timeleft - timeleft % 60;
	new minutesleft = floatround(float(time2) / 60.0);
	new mapname[32];
	get_mapname(mapname, 31);
	new smap[32];
	get_cvar_string("amx_nextmap", smap, 31);
	if (minutesleft >= 2 && !mselected) {
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_NEXTMAP_VOTE_REMAINING", 
		  (minutesleft == 3 || minutesleft == 2) ? timeleft -100 : minutesleft - 2, (minutesleft == 3 || minutesleft == 2) ? "seconds" : "minutes");
	} else {
		if (mselected) {
			client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_NEXTMAP_VOTED", smap, timeleft);
		} else {
			if (minutesleft <= 2 && timeleft) {
				client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_CURRENT_MAP", mapname);
			}
		}
	}
}

public client_putinserver(id) {
	if (!is_user_bot(id)) {
		activeplayers++;
	}
	return PLUGIN_CONTINUE;
}

public client_disconnect(id) {
	remove_task(987600 + id);
	remove_task(127600 + id);
	if (is_user_bot(id)) {
		return PLUGIN_CONTINUE;
	}
	currentplayers--;
	activeplayers--;
	g_AlreadyVoted[id] = false;
	if (rocked[id]) {
		rocked[id] = 0;
		rocks--;
	}
	if (get_timeleft() > 160) {
		if (!mselected && !hasbeenrocked && !inprogress) {
			check_if_need();
		}
	}
	new kName[32];
	get_user_name(id, kName, 31);

	new n = 0;
	while (Nominated[id] > 0 && n < nmaps_num) {
		if (whonmaps_num[n] == id) {
			if (get_timeleft() > 50 && quiet != 2) {	//quiet=0 (words and sounds) quiet=1 (words only, no sound) quiet=2 (no sound, no words)
				client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_PLAYER_LEFT", kName, nmaps[n]);
#if defined DEDICATED_LOG_ENABLED
				log_to_file(logfilename, "%s has left; %s is no longer nominated", kName, nmaps[n]);
#endif
			}

			new j = n;
			while (j < nmaps_num - 1) {
				whonmaps_num[j] = whonmaps_num[j + 1];
				nmaps[j] = nmaps[j + 1];
				j++;
			}
			nmaps_num--;
			Nominated[id] = Nominated[id] - 1;
		} else {
			n++;
		}
	}
	return PLUGIN_CONTINUE;
}

public timer(id) {
	if (get_playersnum() == 0) {
		curtime++;
		if (curtime >= staytime) {
			change_maps();
		}
	} else {
		new i, noncounted, players = get_playersnum();
		for (i = 1; i <= get_maxplayers(); i++) {
			if ((get_user_time(i, 1) >= (get_pcvar_num(pIdleTime) * 216000)) || is_user_bot(i) || is_user_hltv(i)) {
				noncounted++;
			}
		}
		if (players == noncounted) {
			curtime++;
			if (curtime >= staytime) {
				change_maps();
			}
		} else {
			curtime = 0;
		}
	}
	return curtime;
}

public change_maps() {

	new map[51], curmap[51];
	get_mapname(curmap,50);
	get_pcvar_string(pEmptyMap, map, 31);

	if (get_pcvar_num(pEmptymapAllowed) == 1 && strlen(map) > 0) {
		server_cmd("changelevel %s", map);
	}
}

public list_maps(id) {
	new m, iteration = 0;
	client_print(id, print_chat, "%L", id, "DMAP_LISTMAPS", totalmaps);
	if (totalmaps - (50 * iteration) >= 50) {
		console_print(id, "%L", id, "DMAP_LISTMAPS_MAPS", iteration * 50 + 1, iteration * 50 + 50);
	} else {
		console_print(id, "%L", id, "DMAP_LISTMAPS_MAPS", iteration * 50 + 1, iteration * 50 + (totalmaps - iteration * 50));
	}
	
	for (m = 50 * iteration; (m < totalmaps && m < 50 * (iteration + 1)); m += 3)
		if (m + 1 < totalmaps) {
			if (m + 2 < totalmaps) {
				console_print(id, "   %s   %s   %s", listofmaps[m], listofmaps[m + 1], listofmaps[m + 2]);
			} else {
				console_print(id, "   %s   %s", listofmaps[m], listofmaps[m + 1]);
			}
		} else {
			console_print(id, "   %s", listofmaps[m]);
		}
	if (50 * (iteration + 1) < totalmaps) {
		new kIdfake[32];
		num_to_str((id + 50 * (iteration + 1)), kIdfake, 31);
		client_print(id, print_console, "%L", id, "DMAP_LISTMAPS_MORE");
		set_task(4.0, "more_list_maps", 127600 + id, kIdfake, 6);
	}
	return PLUGIN_CONTINUE;
}

public more_list_maps(idfakestr[]) {
	new idreal = str_to_num(idfakestr);
	new m, iteration = 0;
	while (idreal >= 50) {
		idreal -= 50;
		iteration++;
	}	//Now idreal is the real id of client

	if (totalmaps - (50 * iteration) >= 50) {
		console_print(idreal, "%L", idreal, "DMAP_LISTMAPS_MAPS", iteration * 50 + 1, iteration * 50 + 50);
	} else {
		console_print(idreal, "%L", idreal, "DMAP_LISTMAPS_MAPS", iteration * 50 + 1, iteration * 50 + (totalmaps - iteration * 50));
	}

	for (m = 50 * iteration; (m < totalmaps && m < 50 * (iteration + 1)); m += 3) {
		if (m + 1 < totalmaps) {
			if (m + 2 < totalmaps) {
				console_print(idreal, "   %s   %s   %s", listofmaps[m], listofmaps[m + 1], listofmaps[m + 2]);
			} else {
				console_print(idreal, "   %s   %s", listofmaps[m], listofmaps[m + 1]);
			}
		} else {
			console_print(idreal, "   %s", listofmaps[m]);
		}
	}
		
	if (50 * (iteration + 1) < totalmaps) {
		new kIdfake[32];
		num_to_str((idreal + 50 * (iteration + 1)), kIdfake, 31);
		client_print(idreal, print_console, "%L", idreal, "DMAP_LISTMAPS_MORE");
		set_task(2.0, "more_list_maps", 127600 + idreal, kIdfake, 6);
	} else {	//Base case has been reached
		client_print(idreal, print_console, "%L", idreal, "DMAP_LISTMAPS_FINISHED", totalmaps);
	}
}

public say_nextmap(id) {
	new timeleft = get_timeleft();
	new time2 = timeleft - timeleft % 60;
	new minutesleft = floatround(float(time2) / 60.0);
	new mapname[32];
	get_mapname(mapname,31);
	new smap[32];
	get_cvar_string("amx_nextmap", smap, 31);
	if (minutesleft >= 2 && !mselected)
	if (get_pcvar_num(pNominationsAllowed) == 1) {
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_SAY_NOMINATIONS", 
		  (minutesleft == 3 || minutesleft == 2) ? timeleft - 100 : minutesleft - 2, (minutesleft == 3 || minutesleft == 2) ? "sec." : "min.");
	} else {
		if (mselected) {
			client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_NEXTMAP_VOTED", smap, timeleft);
		} else {
			if (inprogress) {
				client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_CURRENT_MAP", mapname);
			}
		}
	}
	return PLUGIN_HANDLED;
}

public check_if_need() {
	new Float:ratio = rtvpercent;
	new needed = floatround(float(activeplayers) * ratio + 0.49);
	new timeleft = get_timeleft();
	new Float:minutesleft = float(timeleft) / 60.0;
	new Float:currentlimit = get_cvar_float("mp_timelimit");
	new Float:minutesplayed = currentlimit - minutesleft;
	new wait;
	wait = minimumwait;
	if ((minutesplayed + 0.5) >= (float(wait))) {
		if (rocks >= needed && rocks >= minimum) {
			client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_RTV_STARTING", rocks);
			set_hudmessage(222, 70, 0, -1.0, 0.3, 1, 10.0, 10.0, 2.0, 4.0, 4);
			show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_RTV_START", rocks);
			hasbeenrocked = 1;
			inprogress = 1;
			mselected = false;
			set_task(10.0, "rock_it_now", 765100);
		}
	}
}

public rock_the_vote(id) {
	new Float:ratio = rtvpercent;
	new needed = floatround(float(activeplayers) * ratio + 0.49);
	new kName[32];
	get_user_name(id, kName, 31);
	new timeleft = get_timeleft();
	new Float:minutesleft = float(timeleft) / 60.0;
	new Float:currentlimit = get_cvar_float("mp_timelimit");
	new Float:minutesplayed = currentlimit - minutesleft;
	new wait;
	wait = minimumwait;
	if (cycle) {
		client_print(id, print_chat, "%L", id, "DMAP_VOTING_DISABLED");
		return PLUGIN_CONTINUE;
	}
	if (!enabled) {
		client_print(id, print_chat, "%L", id, "DMAP_RTV_DISABLED");
		return PLUGIN_CONTINUE;
	}
	if (inprogress) {
		client_print(id, print_chat, "%L", id, "DMAP_VOTE_BEGINNING");
		return PLUGIN_CONTINUE;
	}
	if (mselected) {
		new smap[32];
		get_cvar_string("amx_nextmap", smap, 31);
		client_print(id, print_chat, "%L", id, "DMAP_VOTING_COMPLETED", smap, get_timeleft());
		return PLUGIN_CONTINUE;
	}
	if (hasbeenrocked) {
		client_print(id, print_chat, "%L", id, "DMAP_MAP_ALREADY_ROCKED", kName);
		return PLUGIN_CONTINUE;
	}
	if (timeleft < 120) {
		if (timeleft > 1) {
			client_print(id, print_chat, "%L", id, "DMAP_NOT_ENOUGH_TIME");
		} else {
			client_print(id, print_chat, "%L", id, "DMAP_NO_TIMELIMIT");
		}
		return PLUGIN_CONTINUE;
	}
	if ((minutesplayed + 0.5) < (float(wait))) {
		if (float(wait) - 0.5 - minutesplayed > 0.0) {
			client_print(id, print_chat, "%L", id, "DMAP_RTV_WAIT",
			  kName, (floatround(float(wait) + 0.5-minutesplayed) > 0) ? (floatround(float(wait) + 0.5 - minutesplayed)) : (1));
		} else {
			client_print(id, print_chat, "%L", id, "DMAP_RTV_1MIN");
		}
		if ((get_user_flags(id) & ADMIN_MAP)) {
			console_print(id, "%L", id, "DMAP_RTV_ADMIN_FORCE", kName);
		}
		return PLUGIN_CONTINUE;
	}
	if (!rocked[id]) {
		rocked[id] = 1;
		rocks++;
	} else {
		client_print(id, print_chat, "%L", id, "DMAP_ALREADY_ROCKED", kName);
		return PLUGIN_CONTINUE;
	}
	if (rocks >= needed && rocks >= minimum) {
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_RTV_STARTING", rocks);
		set_hudmessage(222, 70,0, -1.0, 0.3, 1, 10.0, 10.0, 2.0, 4.0, 4);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_RTV_START", rocks);
		hasbeenrocked = 1;
		inprogress = 1;
		mselected = false;
		set_task(15.0, "rock_it_now", 765100);
	} else {
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_RTV_NEEDED", ((needed-rocks) > (minimum-needed)) ? (needed-rocks) : (minimum-rocks));
	}
	return PLUGIN_CONTINUE;
}

public rock_it_now() {
	new temprocked = hasbeenrocked;
	hasbeenrocked = 1;
	new timeleft = get_timeleft();
	new Float:minutesleft=float(timeleft) / 60.0;
	new Float:currentlimit = get_cvar_float("mp_timelimit");
	new Float:minutesplayed = currentlimit-minutesleft;
	new Float:timelimit;
	counttovote = 0;
	remove_task(459200);
	remove_task(459100);
	timelimit = float(floatround(minutesplayed + 1.5));
	if (timelimit > 0.4) {
		oldtimelimit = get_cvar_float("mp_timelimit");
		istimeset = 1;
		set_cvar_float("mp_timelimit", timelimit);
		if (quiet != 2) {
			console_print(0, "%L", LANG_PLAYER, "DMAP_TIMELIMIT_CHANGED", floatround(get_cvar_float("mp_timelimit")));
		}
#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "Time limit changed to %d to enable vote to occur now", floatround(get_cvar_float("mp_timelimit")));
#endif
	} else {
		console_print(0, "%L", LANG_PLAYER, "DMAP_TIMELIMIT_NOTCHANGED");
#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "Will not set a timelimit of %d, vote is not rocked, seconds left on map:%d", floatround(timelimit), timeleft);
#endif
		new inum, players[32], i;
		get_players(players, inum, "c");
		for (i = 0; i < inum; ++i) {
			rocked[i] = 0;
		}
		rocks = 0;
		hasbeenrocked = temprocked;
		return PLUGIN_HANDLED;
	}
	timeleft = get_timeleft();
	inprogress = 1;
	mselected = false;
	if (quiet != 2) {
		set_dhudmessage(0, 555, 0, -1.0, 0, 0, 0.0, 1.5);
		show_dhudmessage(0, "%L", LANG_PLAYER, "DMAP_START_MAPVOTE");
	} else {
		//client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_START_MAPVOTE");
	}
	if (quiet == 0) {
		client_cmd(0, "spk ^"get red(e80) ninety(s45) to check(e20) use _comma(e10) bay(s18) mass(e42) cap(s50)^"");
	}
	set_task(3.5, "getready", 459100);
	set_task(10.0, "startthevote");
	remove_task(454500);
	remove_task(123452);
	rocks = 0;
	new inum, players[32], i;
	get_players(players, inum, "c");
	for (i = 0; i < inum; ++i) {
		rocked[i] = 0;
	}
	set_task(2.18, "calculate_custom");
	return PLUGIN_HANDLED;
}

public admin_rockit(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 31);
	new kName[32], timeleft = get_timeleft();
	get_user_name(id, kName, 31);

	if (timeleft < 180.0) {
		console_print(id, "%L", id, "DMAP_NOT_ENOUGH_TIME");
		return PLUGIN_HANDLED;
	}
	if (inprogress || hasbeenrocked || isend) {
		console_print(id, "%L", id, "DMAP_ALREADY_VOTING");
		return PLUGIN_HANDLED;
	}
	if (cycle) {
		console_print(id, "%L", id, "DMAP_ENABLE_VOTEMODE");
		return PLUGIN_HANDLED;
	}
	if (!mselected) {
		switch(get_pcvar_num(pShowActivity)) {
			case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_VOTE_ROCKED_BY_ADMIN", kName);
			case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_RTV_USED_BY_ADMIN");
		}
	} else {
		switch(get_pcvar_num(pShowActivity)) {
			case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_REVOTE_BY_ADMIN", kName);
			case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_REVOTE");
		}
	}
	remove_task(123450);
	remove_task(123400);
	remove_task(123452);
	remove_task(123499);
	counttovote = 0;
	remove_task(459200);
	remove_task(459100);
#if defined DEDICATED_LOG_ENABLED
	log_to_file(logfilename, "Admin: <%s> calls rockthevote with %d seconds left on map", kName, timeleft);
#endif
	inprogress = 1;
	mselected = false;
	set_task(15.0, "rock_it_now", 765100);
	set_task(0.18, "calculate_custom");
	return PLUGIN_HANDLED;
}

public check_votes() {
	
	client_cmd(0, "spk csds/map/g_end");
	
	new timeleft = get_timeleft();
	new b = 0, a;
	for (a = 0; a < nmapstoch; ++a) {
		if (nvotes[b] < nvotes[a]) {
			b = a;
		}
	}
	if (nvotes[maps_to_select] > nvotes[b]) {
		new mapname[32];
		get_mapname(mapname, 31);
		new Float:steptime = get_pcvar_float(pExtendmapStep);
		set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") + steptime);
		//oldtimelimit = get_cvar_float("mp_timelimit");
		istimeset = 1;

		if (quiet != 2) {
			set_dhudmessage(222, 70,0, -1.0, 0.4, 0, 4.0, 10.0, 2.0, 2.0, 4);
			show_dhudmessage(0, "%L", LANG_PLAYER, "DMAP_MAP_EXTENDED", steptime);
			if (quiet != 1) {
				client_cmd(0, "speak ^"barney/waitin^"");
			}
		}
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_MAP_EXTENDED2", steptime);
#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "Vote: Voting for the nextmap finished. Map %s will be extended to next %.0f minutes", mapname, steptime);
#endif
		inprogress = isend = 0;
		nmaps_num = nbeforefill;
		num_nmapsfill = before_num_nmapsfill;
		return PLUGIN_HANDLED;
	}
	if (nvotes[b] && nvotes[maps_to_select+1] <= nvotes[b]) {
		set_cvar_string("amx_nextmap", nmaps[nnextmaps[b]]);
		new smap[32];
		get_cvar_string("amx_nextmap", smap, 31);
		new players[32], inum;
		get_players(players, inum, "c");
		if (quiet != 2) {
			if (timeleft <= 0 || timeleft > 300) {
				set_hudmessage(222, 70,0, -1.0, 0.36, 0, 4.0, 10.0, 2.0, 2.0, 4);
				show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_MAP_WINS", nmaps[nnextmaps[b]], nvotes[b], timeleft);
			} else {
				set_hudmessage(0, 152, 255, -1.0, 0.22, 0, 4.0, 7.0, 2.1, 1.5, 4);
				if (get_pcvar_float(pEnforceTimelimit) == 1.0 && bIsCstrike) {
					show_hudmessage(0, "%L %L", LANG_PLAYER, "DMAP_MAP_WINS2", nmaps[nnextmaps[b]], nvotes[b], LANG_PLAYER, "DMAP_IN_SECONDS", timeleft);
				} else {
					show_hudmessage(0, "%L %L", LANG_PLAYER, "DMAP_MAP_WINS2", nmaps[nnextmaps[b]], nvotes[b], LANG_PLAYER, "DMAP_SHORTLY");
				}
				if (iscustommap(nmaps[nnextmaps[b]]) && usestandard) {
					client_print(0, print_notify, "%L", LANG_PLAYER, "DMAP_DOWNLOAD_CUSTOM_MAP");
				}
			}
			if ((containi(mapsurl, "www") != -1 || containi(mapsurl, "http") != -1) && iscustommap(nmaps[nnextmaps[b]])) {
				//set_hudmessage(0, 152, 255, -1.0, 0.70, 1, 4.0, 12.0, 2.1, 1.5, 7);
				client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_DOWNLOAD_MAPS_URL", mapsurl);
			}
			if (quiet != 1) {
				client_cmd(0, "speak ^"barney/letsgo^"");	//quiet=0 (words and sounds) quiet=1 (words only, no sound) quiet=2 (no sound, no words)
			}
		}
	}

	new smap[32];
	get_cvar_string("amx_nextmap", smap, 31);
	client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_CHOOSING_FINISHED", smap);
#if defined DEDICATED_LOG_ENABLED
	log_to_file(logfilename, "Vote: Voting for the nextmap finished. The nextmap will be %s", smap);
#endif
	inprogress = waited = 0;
	isend = 1;
	//WE ARE near END OF MAP; time to invoke Round mode ALgorithm
	//set_task(2.0, "endofround", 123452, "", 0, "b");
	new waituntilready = timeleft - 60;
	if (waituntilready > 30) {
		waituntilready = 30;
	}
	if (waituntilready <= 0 || get_cvar_num("mp_winlimit")) {
		addthiswait = 4;
		set_task(4.0, "RoundMode", 333333);
	} else {
		set_task(float(waituntilready), "RoundMode", 333333);
		addthiswait = waituntilready;
	}
	nmaps_num = nbeforefill;
	num_nmapsfill = before_num_nmapsfill;
	set_task(2.18, "calculate_custom");
	return PLUGIN_HANDLED;
}

public show_timer() {
	set_task(1.0, "timedis2", 454500, "", 0, "b");
}

public timedis2() {
	new timeleft = get_timeleft();
	if ((timeleft % 5) == 1) {
		new smap[32];
		get_cvar_string("amx_nextmap", smap, 31);
		set_hudmessage(0, 132, 255, 0.02, 0.27, 0, 5.0, 5.04, 0.0, 0.5, 4);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_NEXTMAP", smap);
		if (waited < 90) {
			set_hudmessage(255, 215, 190, 0.02, 0.2, 0, 5.0, 5.04, 0.0, 0.5, 3);
		} else {
			set_hudmessage(210, 0 ,0, 0.02, 0.15, 0, 5.0, 5.04, 0.0, 0.5, 3);
			//Flashing red:set_hudmessage(210, 0 ,0, 0.02, 0.2, 1, 1.0, 1.04, 0.0, 0.05, 3);
		}
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_LAST_ROUND");
	}
	return PLUGIN_HANDLED;
}

public timedis3() {
	new timeleft = get_timeleft();
	if ((timeleft % 5) == 1) {
		new smap[32];
		get_cvar_string("amx_nextmap", smap, 31);
		set_hudmessage(0, 132, 255, 0.02, 0.27, 0, 5.0, 5.04, 0.0, 0.5, 4);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_NEXTMAP", smap);
		if (timeleft > 30) {
			set_hudmessage(255, 215, 190, 0.02, 0.2, 0, 5.0, 5.04, 0.0, 0.5, 3);
		} else {
			set_hudmessage(210, 0 ,0, 0.02, 0.15, 0, 5.0, 5.04, 0.0, 0.5, 3);
			//Flashing red:set_hudmessage(210, 0, 0, 0.02, 0.2, 1, 5.0, 5.04, 0.0, 0.5, 3);
		}
		//countdown when "Enforcing timelimit"
		new seconds = timeleft % 60;
		new minutes = floatround((timeleft - seconds) / 60.0);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_TIME_LEFT", minutes, seconds);
	}
	return PLUGIN_HANDLED;
}

public RoundMode() {
	if (get_cvar_float("mp_timelimit") > 0.1 && get_pcvar_num(pEnforceTimelimit)) {
		remove_task(333333);
		remove_task(454500);
		new timeleft = get_timeleft();
		if (timeleft < 200) {
			set_task(float(timeleft) - 5.8, "endofround");
			set_task(1.0, "timedis3", 454500, "", 0, "b");
		}
		return PLUGIN_HANDLED;
	} else {
		if (waited == 0) {
			set_task(1.0, "show_timer");
		}
		if (isbetween || isbuytime || (waited + addthiswait) > 190 || (!bIsCstrike && (waited + addthiswait) >= 30) || activeplayers < 2) {	//Time to switch maps!!!!!!!!
			remove_task(333333);
			remove_task(454500);
			if (isbetween) {
				set_task(3.9, "endofround");
			} else {
				endofround();	//switching very soon!
			}
		} else {
			waited += 5;
			//if (waited >= 15 && waited <= 150 && get_timeleft() < 7) {
			if ((waited + addthiswait) <= 190 && get_timeleft() >= 0 && get_timeleft() <= 15) {
				istimeset2 = 1;
				set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") + 2.0);
				if (bIsCstrike) {
					client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_FINISHING_CUR_ROUND");
				}
			}
			set_task(5.0, "RoundMode", 333333);
		}
	}
	return PLUGIN_HANDLED;
}

public vote_count(id, key) {
	if (get_cvar_float("amx_vote_answers")) {
		new name[32];
		get_user_name(id, name, 31);
		if (key == maps_to_select) {
			client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_CHOSE_MAPEXTENDING", name);
		} else if (key < maps_to_select) {
			client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_CHOSE_MAP", name, nmaps[nnextmaps[key]]);
		}
	}
	nvotes[key] += 1;
	g_TotalVotes += 1;
	g_AlreadyVoted[id] = true;
	show_vote_menu(false);

	return PLUGIN_HANDLED;
}

bool:isinmenu(id) {
	new a;
	for (a = 0; a < nmapstoch; ++a) {
		if (id == nnextmaps[a]) {
			return true;
		}
	}
	return false;
}

public dmapcancelvote(id, level, cid) {
	if (!cmd_access(id, level, cid, 0)) {
		return PLUGIN_HANDLED ;
	}
	if (task_exists(765100, 1)) { 
		new authid[32], name[32];

		get_user_authid(id, authid, 31) ;
		get_user_name(id, name, 31);
#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "ADMIN <%s> cancelled the map vote.", name);
#endif
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_ADMIN_CANCELLED", name);
		remove_task(765100, 1);
		set_hudmessage(222, 70,0, -1.0, 0.3, 1, 10.0, 10.0, 2.0, 4.0, 8);
		show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_ADMIN_CANCELLED", name);
		hasbeenrocked = 0;
		inprogress = 0;
		mselected = true;

		return PLUGIN_CONTINUE;
	} else {
		client_print(id, print_chat, "%L", id, "DMAP_NO_CURRENT_VOTE");
	}
	return PLUGIN_HANDLED;
}

public dmapnominate(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new sArg1[32];
	read_argv(1, sArg1, 31);

	handle_andchange(id, sArg1, true);	// Force nomination

	return PLUGIN_HANDLED;
}

public levelchange() {
	if (istimeset2 == 1) {	//Allow automatic map change to take place.
		set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") - 2.0);
		istimeset2 = 0;
	} else {
		if (get_cvar_float("mp_timelimit") >= 4.0) {	//Allow automatic map change to take place.
			if (!istimeset) {
				oldtimelimit = get_cvar_float("mp_timelimit");
			}
			set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") - 3);
			istimeset = 1;
		} else {
			if (get_cvar_num("mp_winlimit")) {	//Allow automatic map change based on teamscores
				new largerscore;
				largerscore = (teamscore[0] > teamscore[1]) ? teamscore[0] : teamscore[1];
				iswinlimitset = 1;
				oldwinlimit = get_cvar_num("mp_winlimit");
				set_cvar_num("mp_winlimit", largerscore);
			}
		}
	}
	//If we are unable to achieve automatic level change, FORCE it.
	set_task(2.1, "DelayedChange", 444444);
}

public changeMap() {	//Default event copied from nextmap.amx, and changed around.
	set_cvar_float("mp_chattime", 3.0);	// make sure mp_chattime is long
	remove_task(444444);
	set_task(1.85, "DelayedChange");
}

public DelayedChange() {
	new smap[32];
	get_cvar_string("amx_nextmap", smap, 31);
	server_cmd("changelevel %s", smap);
}

public endofround() {	//Call when ready to switch maps in (?) seconds
	remove_task(123452);
	remove_task(987111);
	remove_task(333333);
	remove_task(454510);
	remove_task(454500);
	remove_task(123499);
	new smap[32];
	get_cvar_string("amx_nextmap", smap, 31);
	set_task(6.0, "levelchange");	//used to be 9.0
	if (quiet != 2) {
		countnum = 0;
		set_task(1.0, "countdown", 123400, "", 0, "a", 10);
		if (quiet != 1) {
			client_cmd(0, "spk csds/map/g_sps");
		}
	} else {
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_MAP_ABOUT_CHANGE");
	}
	///////////////////////////////////////////////
	client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_NEXTMAP2", smap);
	if ((containi(mapsurl, "www") != -1 || containi(mapsurl, "http") != -1) && iscustommap(smap)) {
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_DOWNLOAD_MAPS_URL2", smap, mapsurl);
	}
	///////////////////////////////////////////////
	if (dofreeze) {
		isspeedset = 1;
		thespeed = get_cvar_float("sv_maxspeed");
		set_cvar_float("sv_maxspeed", 0.0);
		new players[32], inum, i;
		get_players(players, inum, "c");
		for (i = 0; i < inum; ++i) {
			client_cmd(players[i], "drop");
			client_cmd(players[i], "+showscores");
		}
	}
	if (dofreeze) {
		set_task(1.1, "stopperson", 123450, "", 0, "a", 2);
	}
	return PLUGIN_HANDLED;
}

public countdown() {
	new smap[32];
	get_cvar_string("amx_nextmap", smap, 31);
	countnum++;
	set_hudmessage(150, 120, 0, -1.0, 0.3, 0, 0.5, 1.1, 0.1, 0.1, 4);
	show_hudmessage(0, "%L", LANG_PLAYER, "DMAP_MAP_CHANGING_IN", smap, 7 - countnum);
	return PLUGIN_HANDLED;
}

public stopperson() {
	new players[32], inum, i;
	get_players(players, inum, "c");
	if (isspeedset >= 0 && isspeedset < 2) {
		thespeed = get_cvar_float("sv_maxspeed");
		isspeedset++;
		set_cvar_float("sv_maxspeed", 0.0);
	}
	for (i = 0; i < inum; ++i) {
		client_cmd(players[i], "drop");
	}
	return PLUGIN_HANDLED;
}

public display_message() {
	new timeleft = get_timeleft();
	new parttime = timeleft % (frequency * 60 * 2);	//460//period(minutes/cycle) * 60 seconds/minute = period in seconds
	//if frequency = 2 (every 2 minutes one message will appear) THIS FUNCTION COVERS 2 MESSAGES WHICH MAKES ONE CYCLE
	//parttime=timeleft%240;
	new addition = frequency * 60;
	if (mselected || inprogress || cycle) {
		return PLUGIN_CONTINUE;
	}
	//if (parttime > 310 && parttime < 326 && timeleft > 132)
	if (parttime > (40 + addition) && parttime < (56 + addition) && timeleft > 132) {
		set_task(3.0, "messagenominated", 986100);	//, "", 0, "a", 4)
	} else {
		//if (parttime > 155 && parttime < 171 && timeleft > 132)
		if (parttime > 30 && parttime < 46 && timeleft > 132) {
			set_task(10.0, "messagemaps", 986200, "", 0, "a", 1);
		} else if (timeleft >= 117 && timeleft < 132) {
			messagefifteen();
		}
	}
	return PLUGIN_CONTINUE;
}

// THIS IS UNTESTED, BUT SHOULD WORK
/* 1.6 hudtext function
Arguments:
textblock: a string containing the text to print, not more than 512 chars (a small calc shows that the max number of letters to be displayed is around 270 btw)
colr, colg, colb: color to print text in (RGB format)
posx, posy: position on screen * 1000 (if you want text to be displayed centered, enter -1000 for both, text on top will be posx=-1000 & posy=20
screen: the screen to write to, hl supports max 4 screens at a time, do not use screen+0 to screen+3 for other hudstrings while displaying this one
time: how long the text shoud be displayed (in seconds)
*/

public hudtext16(textblock[] ,colr, colg, colb, posx, posy, screen, time, id) {
	new y;
	if (contain(textblock, "^n") == -1) {	// if there is no linebreak in the text, we can just show it as it is
		set_hudmessage(colr, colg, colb, float(posx) / 1000.0, float(posy) / 1000.0, 0, 6.0, float(time), 0.2, 0.2, screen);
		show_hudmessage(id, textblock);
	} else {	// more than one line
		new out[128], rowcounter = 0, tmp[512], textremain = true;
		y = screen;
		new i = contain(textblock, "^n");
		copy(out, i, textblock);	// we need to get the first line of text before the loop
		do {	// this is the main print loop
			setc(tmp, 511, 0);	// reset string
			copy(tmp, 511, textblock[i + 1]);	// copy everything AFTER the first linebreak (hence the +1, we don't want the linebreak in our new string)
			setc(textblock, 511, 0);	// reset string
			copy(textblock, 511, tmp);	// copy back remaining text
			i = contain(textblock, "^n");	// get next linebreak position
			if ((strlen(out) + i < 64) && (i != -1)) {	// we can add more lines to the outstring if total letter count don't exceed 64 chars (decrease if you have a lot of short lines since the leading linbreaks for following lines also take up one char in the string)
				add(out, 127, "^n");	// add a linebreak before next row
				add(out, strlen(out) + i, textblock);
				rowcounter++;	// we now have one more row in the outstring
			} else {	// no more lines can be added
				set_hudmessage(colr, colg, colb, float(posx) / 1000.0, float(posy) / 1000.0, 0, 6.0, float(time), 0.2, 0.2, screen);	// format our hudmsg
				if ((i == -1) && (strlen(out) + strlen(textblock) < 64)) {
					add(out, 127, "^n");	// if i == -1 we are on the last line, this line is executed if the last line can be added to the current string (total chars < 64)
				} else {	// not the last line or last line must have it's own screen
					if (screen-y < 4) {
						show_hudmessage(id, out);	// we will only print the hudstring if we are under the 4 screen limit
					}
					screen++;	// go to next screen after printing this one
					rowcounter++;	// one more row
					setc(out, 127, 0);	// reset string
					for (new j = 0; j < rowcounter; j++) {
						add(out, 127, "^n");	// add leading linebreaks equal to the number of rows we already printed
					}
					if (i == -1) {
						set_hudmessage(colr, colg, colb, float(posx) / 1000.0, float(posy) / 1000.0, 0, 6.0, float(time), 0.2, 0.2, screen);	// format our hudmsg if we are on the last line
					} else {
						add(out, strlen(out) + i, textblock);	// else add the next line to the outstring, before this, out is empty (or have some leading linebreaks)
					}
				}
				if (i == -1) {	// apparently we are on the last line here
					add(out, strlen(out) + strlen(textblock), textblock);	// add the last line to out
					if (screen - y < 4) show_hudmessage(id, out);	// we will only print the hudstring if we are under the 4 screen limit
					textremain = false;	// we have no more text to print
				}
			}
		} while (textremain);
	}
	return screen - y;	// we will return how many screens of text we printed
}

public messagenominated() {
	if (quiet == 2) {
		return PLUGIN_CONTINUE;
	}

	new string[256], string2[256], string3[512];
	if (nmaps_num < 1) {
		formatex(string3, 511, "%L", LANG_SERVER, "DMAP_NO_MAPS_NOMINATED");
	} else {
		new n = 0, foundone = 0;
		formatex(string, 255, "%L", LANG_SERVER, "DMAP_NOMINATIONS");
		while (n < 3 && n < nmaps_num) {
			formatex(string, 255, "%s   %s", string, nmaps[n++]);
		}
		while (n < 6 && n < nmaps_num) {
			foundone = 1;
			format(string2, 255, "%s   %s", string2, nmaps[n++]);
		}
		if (foundone) {
			formatex(string3, 511, "%s^n%s", string, string2);
		} else {
			formatex(string3, 511, "%s", string);
		}
	}
	hudtext16(string3, random_num(0, 222), random_num(0, 111), random_num(111, 222), -1000, 50, random_num(1, 4), 10, 0);
	return PLUGIN_CONTINUE;
}

public listnominations(id) {
	if (get_pcvar_num(pNominationsAllowed) == 1) {
		new a = 0, string3[512], string1[96], name1[33];
		if (a < nmaps_num) {
			//show_hudmessage(id, "The following maps have been nominated for the next map vote:");
			formatex(string3, 255, "%L", id, "DMAP_NOMINATED_MAPS");
		}
		while (a < nmaps_num) {
			get_user_name(whonmaps_num[a], name1, 32);
			//set_hudmessage(255, 0, 0, 0.12, 0.3 + 0.08 * float(a), 0, 15.0, 15.04, 1.5, 3.75, 2 + a);
			//show_hudmessage(id, "%s by: %s", nmaps[a], name1);
			formatex(string1, 95, "%L", id, "DMAP_MAP_BY", nmaps[a], name1);
			add(string3, 511, string1, 95);
			a++;
		}
		hudtext16(string3, random_num(0, 222), random_num(0, 111), random_num(111, 222), 300, 10, random_num(1, 4), 15, id);
	}
}

public messagemaps() {
	if (quiet == 2) {
		return PLUGIN_CONTINUE;
	}

	new string[256], string2[256], string3[512];
	new n = 0;
	new total = 0;

	if ((totalmaps - 6) > 0) {
		n = random_num(0, totalmaps - 6);
	}
	while (total < 3 && total < totalmaps && is_map_valid(listofmaps[n]) && n < totalmaps) {
		if (!islastmaps(listofmaps[n]) && !isbanned(listofmaps[n]) && !isnominated(listofmaps[n])) {
			format(string, 255, "%s   %s", string, listofmaps[n]);
			total++;
		}
		n++;
	}
	while (total < 6 && n < totalmaps && is_map_valid(listofmaps[n]) && !isnominated(listofmaps[n])) {
		if (!islastmaps(listofmaps[n]) && !isbanned(listofmaps[n])) {
			format(string2, 255, "%s     %s", string2, listofmaps[n]);
			total++;
		}
		n++;
	}
	if (total > 0) {
		//show_hudmessage(0, "The following maps are available to nominate:^n%s", string);
		new temp[256];
		formatex(temp, 255, "%L", LANG_SERVER, "DMAP_AVAILABLE_MAPS");
		add(string3, 511, temp, 100);
		add(string3, 511, string, 100);
		add(string3, 511, "^n");
	}
	if (total > 3) {
		add(string3, 511, string2, 100);
	}

	hudtext16(string3, random_num(0, 222), random_num(0, 111), random_num(111, 222), -1000, 50, random_num(1, 4), 10, 0);
	return PLUGIN_CONTINUE;
}

public messagefifteen() {
	if (quiet == 2) {
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_VOTING_IN_15SEC");
		return PLUGIN_HANDLED;
	}
	set_dhudmessage(0, 555, 0, -1.0, 0, 0, 0.0, 0.01);
	show_dhudmessage(0, "%L", LANG_PLAYER, "DMAP_VOTING_IN_15SEC");
	if (quiet == 0) {
		client_cmd(0, "spk ^"get red(e80) ninety(s45) to check(e20) use bay(s18) mass(e42) cap(s50)^"");
	}
	set_task(8.7, "getready", 459100);
	return PLUGIN_HANDLED;
}

public getready() {
	if (!cycle) {
		set_task(0.93, "timetovote", 459200, "", 0, "a", 11);
	}
}

public timetovote()
{
	counttovote++;

	if (get_timeleft() > 132 || counttovote > 11 || cycle || isbuytime)
	{
		counttovote = 0;
		remove_task(459200);
		remove_task(459100);
		return PLUGIN_HANDLED;
	} else {

        set_dhudmessage(0, 555, 0, -1.0, 0, 0, 0.0, 0.01);
        show_dhudmessage(0, "%L", LANG_PLAYER, "DMAP_VOTING_IN_XSEC", 6 - counttovote);
		
		switch(counttovote)
		{
                        case 1: client_cmd(0,"spk csds/map/g_5");
			case 2: client_cmd(0,"spk csds/map/g_4");
			case 3: client_cmd(0,"spk csds/map/g_3");
			case 4: client_cmd(0,"spk csds/map/g_2");
			case 5: client_cmd(0,"spk csds/map/g_1");
		}
	}
	return PLUGIN_HANDLED;
}

available_maps() {	//return number of maps that havent that have been added yet
	new num = 0, isinlist;
	new current_map[32], a, i;
	get_mapname(current_map, 31);
	for (a = 0; a < num_nmapsfill; a++) {
		if (is_map_valid(nmapsfill[a])) {
			isinlist = 0;
			for (i = 0; i < nmaps_num; i++) {
				if (equali(nmapsfill[a], nmaps[i])) {
					isinlist = 1;
				}
			}
			if (!isinlist) {
				num++;
			}
		}
	}
	return num;
}

public askfornextmap() {
	display_message();
	new timeleft = get_timeleft();

	if (isspeedset && timeleft > 30) {
		isspeedset = 0;
		set_cvar_float("sv_maxspeed", thespeed);
	}
	if (waited > 0) {
		return PLUGIN_HANDLED;
	}
	if (timeleft > 300) {
		isend = 0;
		remove_task(123452);
	}
	new mp_winlimit = get_cvar_num("mp_winlimit");
	if (mp_winlimit) {
		new s = mp_winlimit - 2;
		if ((s > teamscore[0] && s > teamscore[1]) && (timeleft > 114 || timeleft < 1)) {
			remove_task(454500);
			mselected = false;
			return PLUGIN_HANDLED;
		}
	} else {
		if (timeleft > 114 || timeleft < 1) {
			if (timeleft > 135) {
				remove_task(454510);
				remove_task(454500);
				remove_task(123499);
			} else {
				remove_task(454500);
			}
			mselected = false;
			return PLUGIN_HANDLED;
		}
	}
	if (inprogress || mselected || cycle) {
		return PLUGIN_HANDLED;
	}
	mselected = false;
	inprogress = 1;
	if (mp_winlimit && !(timeleft >= 115 && timeleft < 134)) {
		if (quiet != 2) {
			set_dhudmessage(0, 555, 0, -1.0, 0, 0, 0.0, 1.5);
			show_dhudmessage(0, "%L", LANG_PLAYER, "DMAP_START_MAPVOTE");
			if (quiet != 1) {
				client_cmd(0, "spk ^"get red(e80) ninety(s45) to check(e20) use bay(s18) mass(e42) cap(s50)^"");
			}
			set_task(8.2, "getready", 459100);
			set_task(10.0, "startthevote");
		} else {
			set_task(1.0, "startthevote");
		}
	} else {
		set_task(0.9, "startthevote");
	}
	return PLUGIN_HANDLED;
}

public startthevote() {
	
	client_cmd(0, "spk csds/map/g_start");

	new j;
	if (cycle) {
		inprogress = 0;
		mselected = false;
		remove_task(459200);
		remove_task(459100);
		new smap[32];
		get_cvar_string("amx_nextmap", smap, 31);
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_NEXTMAP2", smap);
		return PLUGIN_HANDLED;
	}
	for (j = 0; j < maps_to_select + 2; j++) {
		nvotes[j] = 0;
	}
	mselected = true;
	inprogress = 1;
	counttovote = 0;
	if ((isbuytime || isbetween) && get_timeleft() && get_timeleft() > 54 && get_pcvar_num(pWeaponDelay)) {
		set_dhudmessage(255, 127, 0, -1.0, 0.74, 0, 0.0, 1.5);
		show_dhudmessage(0, "Р“РѕР»РѕСЃРѕРІР°РЅРёРµ Р·Р° СЃР»РµРґ. РєР°СЂС‚Сѓ РѕС‚Р»РѕР¶РµРЅРѕ, РґР»СЏ РІРѕР·РјРѕР¶РЅРѕСЃС‚Рё Р·Р°РєСѓРїРєРё РѕСЂСѓР¶РёСЏ.");
		if (isbetween) {
			set_task(15.0, "getready", 459100);
			set_task(21.0, "startthevote");
		} else {
			set_task(8.0, "getready", 459100);
			set_task(14.0, "startthevote");
		}
		return PLUGIN_HANDLED;
	}

	remove_task(459200);
	remove_task(459100);

	if (quiet != 2) {
		if (bIsCstrike) {
			client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_POSSIBLE_NOMINATIONS", nmaps_num, maps_to_select);
		}
	}

#if defined DEDICATED_LOG_ENABLED
	log_to_file(logfilename, "Nominations for the map vote: %d out of %d possible nominations", nmaps_num, maps_to_select);
#endif

	before_num_nmapsfill = num_nmapsfill;
	new available = available_maps();

	if ((nmaps_num + available) < (maps_to_select + 1)) {	//Loads maps from mapcycle.txt/allmaps.txt if not enough are in in mapchoice.ini

		new current_map[32];
		get_mapname(current_map,31);
		new overflowprotect = 0;
		new used[MAX_MAPS_AMOUNT];
		new k = num_nmapsfill;
		new totalfilled = 0;
		new alreadyused;
		new tryfill, custfill = 0;
		new q;
		new listpossible = totalmaps;
		while (((available_maps() + nmaps_num - custfill) < (maps_to_select + 7)) && listpossible > 0) {
			alreadyused = 0;
			q = 0;
			tryfill = random_num(0, totalmaps - 1);
			overflowprotect = 0;
			while (used[tryfill] && overflowprotect++ <= totalmaps * 15) {
				tryfill = random_num(0, totalmaps - 1);
			}
			if (overflowprotect >= totalmaps * 15) {
				alreadyused = 1;
#if defined DEDICATED_LOG_ENABLED
				log_to_file(logfilename, "Overflow detected in Map Nominate plugin, there might not be enough maps in the current vote");
#endif
				listpossible -= 1;
			} else {
				while (q < num_nmapsfill && !alreadyused) {
					if (equali(listofmaps[tryfill], nmapsfill[q])) {
						alreadyused = used[tryfill] = 1;
						listpossible--;
					}
					q++;
				}
				q = 0;
				while (q < nmaps_num && !alreadyused) {
					if (equali(listofmaps[tryfill], nmaps[q])) {
						alreadyused = used[tryfill] = 1;
						listpossible--;
					}
					q++;
				}
			}

			if (!alreadyused) {
				if (equali(listofmaps[tryfill], current_map) || equali(listofmaps[tryfill], last_map)||
				  islastmaps(listofmaps[tryfill]) || isbanned(listofmaps[tryfill])) {
					listpossible--;
					used[tryfill] = 1;
				} else {
					if (iscustommap(listofmaps[tryfill])) {
						custfill++;
					}
					nmapsfill[k] = listofmaps[tryfill];
					num_nmapsfill++;
					listpossible--;
					used[tryfill] = 1;
					k++;
					totalfilled++;
				}
			}
		}
#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "Filled %d slots in the fill maps array with maps from mapcycle.txt, %d are custom", totalfilled, custfill);
#endif
	}

	nbeforefill = nmaps_num;	//extra maps do not act as "nominations" they are additions

	if (nmaps_num < maps_to_select) {

		new need = maps_to_select - nmaps_num;
		console_print(0, "%L", LANG_PLAYER, "DMAP_RANDOM_MAPSELECTION", need);
#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "Randomly Filling slots for the vote with %d out of %d", need, num_nmapsfill);
#endif
		new fillpossible = num_nmapsfill;
		new k = nmaps_num;
		new overflowprotect = 0;
		new used[MAX_MAPS_AMOUNT];
		new totalfilled = 0, custchoice = 0, full = ((amt_custom + custchoice) >= maxcustnom);
		new alreadyused;
		new tryfill;
		if (num_nmapsfill < 1) {
			if (quiet != 2) {
				client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_NOMORE_RANDOM_DEFINED");
			}
#if defined DEDICATED_LOG_ENABLED
			log_to_file(logfilename, "ERROR: Unable to fill any more voting slots with random maps, none defined in mapchoice.ini/allmaps.txt/mapcycle.txt");
#endif
		} else {
			while (fillpossible > 0 && k < maps_to_select) {
				alreadyused = 0;
				new q = 0;
				tryfill = random_num(0, num_nmapsfill - 1);
				overflowprotect = 0;
				while (used[tryfill] && overflowprotect++ <= num_nmapsfill * 10) {
					tryfill = random_num(0, num_nmapsfill - 1);
				}
				if (overflowprotect >= num_nmapsfill * 15) {
					alreadyused = 1;
#if defined DEDICATED_LOG_ENABLED
					log_to_file(logfilename, "Overflow detected in Map Nominate plugin, there might not be enough maps in the current vote");
#endif
					fillpossible -= 2;
				} else {
					while (q < nmaps_num && !alreadyused) {
						if (equali(nmapsfill[tryfill], nmaps[q])) {
							alreadyused = used[tryfill] = 1;
							fillpossible--;
						}
						q++;
					}
					if (!alreadyused) {
						if (iscustommap(nmapsfill[tryfill]) && full) {
							alreadyused = used[tryfill] = 1;
							fillpossible--;
						}
					}
				}

				if (!alreadyused) {
					if (iscustommap(nmapsfill[tryfill])) {
						custchoice++;
						full = ((amt_custom + custchoice) >= maxcustnom);
					}
					nmaps[k] = nmapsfill[tryfill];
					nmaps_num++;
					fillpossible--;
					used[tryfill] = 1;
					k++;
					totalfilled++;
				}
			}

			if (totalfilled == 0) {
				console_print(0, "%L", LANG_PLAYER, "DMAP_NO_DEFAULTMAPS_FOUND");
			} else {
				if (quiet != 2) {
					console_print(0, "%L", LANG_PLAYER, "DMAP_FILLED_RANDOM_MAPS", totalfilled);
				}
			}
#if defined DEDICATED_LOG_ENABLED
			log_to_file(logfilename, "Filled %d vote slots with random maps, %d are custom", totalfilled, custchoice);
#endif
		}
	}

	show_vote_menu(true);
	return PLUGIN_HANDLED;
}

show_vote_menu(bool:bFirstTime) {

	new menu[512], a, mkeys = (1 << maps_to_select + 1);
	new Float:steptime = get_pcvar_float(pExtendmapStep);
	new extendint = floatround(steptime);

	new pos;

	new mp_winlimit = get_cvar_num("mp_winlimit");
	if (bFirstTime == true) {
		g_TotalVotes = 0;
		for (a = 0; a <= 32; a++) {
			g_AlreadyVoted[a] = false;
		}
	}

	if (bIsCstrike) {
		pos = formatex(menu, 511, "%L", LANG_SERVER, "DMAP_CS_MENU_TITLE");
	} else {
		pos = formatex(menu, 511, "%L", LANG_SERVER, "DMAP_MENU_TITLE");
	}

	new dmax = (nmaps_num > maps_to_select) ? maps_to_select : nmaps_num;

	new tagpath[64], sMenuOption[64];	// If size of sMenuOption is changed, change maxlength in append_vote_percent as well
	formatex(tagpath, 63, "%s/dmaptags.ini", custompath);

	for (nmapstoch = 0; nmapstoch < dmax; ++nmapstoch) {
		if (bFirstTime == true) {
			a = random_num(0, nmaps_num - 1);	// Randomize order of maps in vote
			while (isinmenu(a)) {
				if (++a >= nmaps_num) {
					a = 0;
				}
			}
			nnextmaps[nmapstoch] = a;
			nvotes[nmapstoch] = 0;			// Reset votes for each map
		}

		if (iscustommap(nmaps[nnextmaps[nmapstoch]]) && usestandard) {
			if (bIsCstrike) {
				formatex(sMenuOption, 63, "%L", LANG_SERVER, "DMAP_CS_MENU_CUSTOM", nmapstoch + 1, nmaps[nnextmaps[nmapstoch]]);
			} else {
				formatex(sMenuOption, 63, "%L", LANG_SERVER, "DMAP_MENU_CUSTOM", nmapstoch + 1, nmaps[nnextmaps[nmapstoch]]);
			}
		} else {	// Don't show (Custom)
			formatex(sMenuOption, 63, "%d. %s", nmapstoch + 1, nmaps[nnextmaps[nmapstoch]]);
		}

		if (file_exists(tagpath)) {	// If the tag file is there, check for the extra tag
			new iLine, sFullLine[64], sTagMap[32], sTagText[32], txtLen;
		
			while (read_file(tagpath, iLine, sFullLine, 63, txtLen)) {
				if (sFullLine[0] == ';') {
					iLine++;
					continue;	// Ignore comments
				}

				strbreak(sFullLine, sTagMap, 31, sTagText, 31);	// Split the map name and tag apart

				if (equali(nmaps[nnextmaps[nmapstoch]], sTagMap)) {
					format(sMenuOption, 63, "%s [%s]", sMenuOption, sTagText);
					break;	// Quit reading the file
				}
				iLine++;
			}
		}

		append_vote_percent(sMenuOption, nmapstoch, true);
		pos += formatex(menu[pos], 511, sMenuOption);

		mkeys |= (1 << nmapstoch);
	}

	menu[pos++] = '^n';
	if (bFirstTime == true) {
		nvotes[maps_to_select] = 0;
		nvotes[maps_to_select + 1] = 0;
	}
	new mapname[32];
	get_mapname(mapname, 31);
	if (!mp_winlimit && get_cvar_float("mp_timelimit") < get_pcvar_float(pExtendmapMax)) {
		formatex(sMenuOption, 63, "%L", LANG_SERVER, "DMAP_MENU_EXTEND", maps_to_select + 1, mapname, extendint);
		append_vote_percent(sMenuOption, maps_to_select, true);
		pos += formatex(menu[pos], 511, sMenuOption);

		mkeys |= (1 << maps_to_select);
	}

	formatex(sMenuOption, 63, "%L", LANG_SERVER, "DMAP_MENU_NONE", maps_to_select + 2);
	append_vote_percent(sMenuOption, maps_to_select + 1);
	formatex(menu[pos], 511, sMenuOption);

	if (bFirstTime == true) {
		g_VoteTimeRemaining = DMAP_VOTE_TIME;
		set_task(float(g_VoteTimeRemaining), "check_votes");
		show_menu(0, mkeys, menu, --g_VoteTimeRemaining, DMAP_MENU_TITLE);
		set_task(1.0, "update_vote_time_remaining", DMAP_TASKID_VTR, "", 0, "a", g_VoteTimeRemaining);
		if (bIsCstrike) {
			client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_TIME_TO_CHOOSE");
		}

#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "Vote: Voting for the nextmap started");
#endif
	} else {
		new players[32], iNum, id;
		get_players(players, iNum, "ch");
		for (new iPlayer = 0; iPlayer < iNum; iPlayer++) {
			id = players[iPlayer];
			if (g_AlreadyVoted[id] == false) {
				show_menu(players[iPlayer], mkeys, menu, g_VoteTimeRemaining, DMAP_MENU_TITLE);
			}
		}

	}
	return PLUGIN_HANDLED;
}

stock percent(iIs, iOf) {
	return (iOf != 0) ? floatround(floatmul(float(iIs) / float(iOf), 100.0)) : 0;
}

append_vote_percent(sMenuOption[], iChoice, bool:bNewLine = false) {

	new iPercent = percent(nvotes[iChoice], g_TotalVotes);
	new sPercent[16];
	if (iPercent > 0) {	// Don't show 0%
		if (bIsCstrike) {
			formatex(sPercent, 15, " \d(%d%s)\w", iPercent, "%%");
		} else {
			formatex(sPercent, 15, " (%d%s)", iPercent, "%%");
		}
		strcat(sMenuOption, sPercent, 63);
	}

	if (bNewLine == true) {		// Do this even if vote is 0%
		strcat(sMenuOption, "^n", 63);
	}

	return PLUGIN_HANDLED;
}

public update_vote_time_remaining() {
	if (--g_VoteTimeRemaining <= 0) {
		remove_task(DMAP_TASKID_VTR);
	}
	return PLUGIN_HANDLED;
}

handle_andchange(id, map2[], bool:bForce = false) {
	new tester[32];
	if (is_map_valid(map2) == 1) {
		handle_nominate(id, map2, bForce);
	} else {
		formatex(tester, 31, "cs_%s", map2);
		if (is_map_valid(tester) == 1) {
			handle_nominate(id, tester, bForce);
		} else {
			formatex(tester, 31, "de_%s", map2);
			if (is_map_valid(tester) == 1) {
				handle_nominate(id, tester, bForce);
			} else {
				formatex(tester, 31, "as_%s", map2);
				if (is_map_valid(tester) == 1) {
					handle_nominate(id, tester, bForce);
				} else {
					formatex(tester, 31, "dod_%s", map2);
					if (is_map_valid(tester) == 1) {
						handle_nominate(id, tester, bForce);
					} else {
						formatex(tester, 31, "fy_%s", map2);
						if (is_map_valid(tester) == 1) {
							handle_nominate(id, tester, bForce);
						} else {				// Send invalid map. handle_nominate() handles the error.
							handle_nominate(id, map2, bForce);
						}
					}
				}
			}
		}
	}
}

public HandleSay(id) {

	new chat[256];
	read_args(chat, 255);
	new saymap[256];
	saymap = chat;
	remove_quotes(saymap);
	new saymap2[29];
	read_args(saymap2, 28);
	remove_quotes(saymap2);
	new chat2[32];

	if (containi(chat, "<") != -1 || containi(chat, "?") != -1 || containi(chat, ">") != -1 || containi(chat, "*") != -1 || containi(chat, "&") != -1 || containi(chat, ".") != -1) {
		return PLUGIN_CONTINUE;
	}
	if (containi(chat, "nominations") != -1) {
		if (get_pcvar_num(pNominationsAllowed) == 0) {
			client_print(id, print_chat, "%L", id, "DMAP_NOMINATIONS_DISABLED");
			return PLUGIN_HANDLED;
		}
		if (mselected) {
			client_print(id, print_chat, "%L", id, "DMAP_VOTE_IN_PROGRESS");
		} else {
			if (nmaps_num == 0) {
				client_print(id, print_chat, "%L", id, "DMAP_NO_NOMINATIONS");
			} else {
				listnominations(id);
			}
		}
	} else {
		if (containi(chat, "nominate ") == 1) {
			new mycommand[41];
			read_args(mycommand, 40);
			remove_quotes(mycommand);
			handle_andchange(id, mycommand[9]);
		} else {
			if (containi(chat, "vote ") == 1) {
				new mycommand[37];
				read_args(mycommand, 36);
				remove_quotes(mycommand);
				handle_andchange(id, mycommand[5]);
			} else {
				if (is_map_valid(saymap) == 1) {
					handle_nominate(id, saymap, false);
				} else {
					formatex(chat2, 31, "cs_%s", saymap2);
					if (is_map_valid(chat2) == 1) {
						handle_nominate(id, chat2, false);
					} else {
						formatex(chat2, 31, "de_%s", saymap2);
						if (is_map_valid(chat2) == 1) {
							handle_nominate(id, chat2, false);
						} else {
							formatex(chat2, 31, "as_%s", saymap2);
							if (is_map_valid(chat2) == 1) {
								handle_nominate(id, chat2, false);
							} else {
								formatex(chat2, 31, "dod_%s", saymap2);
								if (is_map_valid(chat2) == 1) {
									handle_nominate(id, chat2, false);
								} else {
									formatex(chat2, 31, "fy_%s", saymap2);
									if (is_map_valid(chat2) == 1) {
										handle_nominate(id, chat2, false);
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public calculate_custom() {
	//New optional protection against "too many" custom maps being nominated.
	amt_custom = 0;
	new i;
	for (i = 0; i < nmaps_num; i++) {
		if (iscustommap(nmaps[i])) {
			amt_custom++;
		}
	}
}

public handle_nominate(id, map[], bool:bForce) {
	if ((get_pcvar_num(pNominationsAllowed) == 0) && (bForce == false)) {
		client_print(id, print_chat, "%L", id, "DMAP_NOMINATIONS_DISABLED");
		return PLUGIN_HANDLED;
	}
	strtolower(map);
	new current_map[32], iscust = 0, iscust_t = 0, full;
	full = (amt_custom >= maxcustnom);
	new n = 0, i, done = 0, isreplacement = 0;	//0: (not a replacement), 1: (replacing his own), 2: (replacing others)
	new tempnmaps = nmaps_num;
	get_mapname(current_map, 31);
	if (maxnom == 0) {
		client_print(id, print_chat, "%L", id, "DMAP_NOMINATIONS_DISABLED");
		return PLUGIN_HANDLED;
	}
	if (inprogress && mselected) {
		client_print(id, print_chat, "%L", id, "DMAP_VOTING_IN_PROGRESS");
		return PLUGIN_HANDLED;
	}
	if (mselected) {
		new smap[32];
		get_cvar_string("amx_nextmap", smap, 31);
		client_print(id, print_chat, "%L", id, "DMAP_VOTING_OVER", smap);
		return PLUGIN_HANDLED;
	}
	if (!is_map_valid(map) || is_map_valid(map[1])) {
		client_print(id, print_chat, "%L", id, "DMAP_MAP_NOTFOUND", map);
		return PLUGIN_HANDLED;
	}
	if (isbanned(map) && (bForce == false)) {
		client_print(id, print_chat, "%L", id, "DMAP_MAPVOTE_NOT_AVAILABLE");
		return PLUGIN_HANDLED;
	}
	if (islastmaps(map) && !equali(map, current_map) && (bForce == false)) {
		client_print(id, print_chat, "%L", id, "DMAP_CANT_NOMINATE_LASTMAP", ban_last_maps);
		return PLUGIN_HANDLED;
	}
	if (equali(map, current_map)) {
		client_print(id, print_chat, "%L", id, "DMAP_EXTEND_MAP", map);
		return PLUGIN_HANDLED;
	}
	//Insert Strict Style code here, for pcvar dmap_strict 1
	if (get_pcvar_num(pDmapStrict) && (bForce == false)) {
		new isinthelist = 0;
		for (new a = 0; a < totalmaps; a++) {
			if (equali(map, listofmaps[a]))
				isinthelist = 1;
		}
		if (!isinthelist) {
			client_print(id, print_chat, "%L", id, "DMAP_ALLOWED_MAPS");
			return PLUGIN_HANDLED;
		}
	}
	iscust = iscustommap(map);
	if (nmaps_num >= maps_to_select || Nominated[id] >= maxnom) {	//3 (1,2,3)
		if (Nominated[id] > maxnom) {	//3
			client_print(id, print_chat, "%L", id, "DMAP_MAX_MAPS_REACHED");	//Possible to reach here!
			//only if the command dmap_nominations is used to lower amount of maps that can be nominated
			return PLUGIN_HANDLED;
		}

		for (i = 0; i < nmaps_num; i++) {
			if (equali(map, nmaps[i])) {

				new name[32];
				get_user_name(whonmaps_num[i], name, 31);
				if (quiet == 2) {
					client_print(id, print_chat, "%L", id, "DMAP_ALREADY_NOMINATED", map, name);
				} else {
					client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_ALREADY_NOMINATED", map, name);
				}
				return PLUGIN_HANDLED;
			}
		}

		while (n < nmaps_num && !done && Nominated[id] > 1) {	//If the person has nominated 2 or 3 maps, he can replace his own
			if (whonmaps_num[n] == id) {	//If a map is found that he has nominated, replace his own nomination.
				iscust_t = iscustommap(nmaps[n]);
				if (!(full && iscust && !iscust_t)) {
					Nominated[id] = Nominated[id] - 1;
					nmaps_num = n;
					done = 1;
					isreplacement = 1;
				}
			}
			n++;
		}

		if (!done) {
			n = 0;
			while (n < nmaps_num && !done && Nominated[id] < 2) {	//If the person has nom only 1 or no maps, he can replace ppl who nominated 3
				if (Nominated[whonmaps_num[n]] > 2) {	//Replace the "greedy person's" nomination
					iscust_t = iscustommap(nmaps[n]);
					if (!(full && iscust && !iscust_t)) {
						done = 1;
						Nominated[whonmaps_num[n]] = Nominated[whonmaps_num[n]] - 1;
						nmaps_num = n;
						isreplacement = 2;
					}
				}
				n++;
			}
		}
		if (!done) {
			n = 0;

			while (n < nmaps_num && !done && Nominated[id] < 1) {	//If the person has not nom any maps, he can replace those with more than one
				//he cannot replace those with only one nomination, that would NOT be fair

				if (Nominated[whonmaps_num[n]] > 1) {	//Replace the "greedy person's" nomination
					iscust_t = iscustommap(nmaps[n]);
					if (!(full && iscust && !iscust_t)) {
						done = 1;
						Nominated[whonmaps_num[n]] = Nominated[whonmaps_num[n]] - 1;
						nmaps_num = n;
						isreplacement = 2;
					}
				}
				n++;
			}
		}

		if (!done) {
			n = 0;

			while (n < nmaps_num && !done && Nominated[id] > 0) {	//If the person has nominated a map, he can replace his own
				if (whonmaps_num[n] == id) {	//If a map is found that he has nominated, replace his own nomination.
					iscust_t = iscustommap(nmaps[n]);
					if (!(full && iscust && !iscust_t)) {	//Check to see if too many custom maps are nominated
						Nominated[id] = Nominated[id] - 1;
						nmaps_num = n;
						done = 1;
						isreplacement = 1;
					}
				}
				n++;
			}
		}
		if (!done) {
			client_print(id, print_chat, "%L", id, "DMAP_MAX_NOMINATIONS_REACHED", nmaps_num);
			return PLUGIN_HANDLED;
		}
	}

	for (i = 0; i < nmaps_num; i++) {
		if (equali(map, nmaps[i])) {
			new name[32];
			get_user_name(whonmaps_num[i], name, 31);

			client_print(id, print_chat, "%L", id, "DMAP_ALREADY_NOMINATED", map, name);

			nmaps_num = tempnmaps;

			return PLUGIN_HANDLED;
		}
	}

	if (!isreplacement && iscust && full) {
		client_print(id, print_chat, "%L", id, "DMAP_MAX_CUSTOMMAPS_REACHED", maxcustnom);
		return PLUGIN_HANDLED;
	}

	new name[32];
	get_user_name(id, name, 31);
	if (isreplacement == 1) {	//They are replacing their old map
		if (quiet == 2) {
			client_print(id, print_chat, "%L", id, "DMAP_REPLACE_PREVIOUS_NOMINATION", nmaps[nmaps_num]);
		} else {
			client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_PLAYER_REPLACED_NOMINATION", name, nmaps[nmaps_num]);
		}
	} else {
		if (isreplacement == 2) {
			if (quiet == 2) {
				client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_NOMINATION_REPLACED", nmaps[nmaps_num]);
			} else {		
				new name21[32];
				get_user_name(whonmaps_num[nmaps_num], name21, 31);
				client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_NOMINATION_REPLACED2", name21, nmaps[nmaps_num]);
			}
		}
	}

	Nominated[id]++;

	console_print(id, "%L", id, "DMAP_ADD_NOMINATION", map, nmaps_num + 1);

	set_task(0.18, "calculate_custom");
	copy(nmaps[nmaps_num], 31, map);
	whonmaps_num[nmaps_num] = id;

	if (isreplacement) {
		nmaps_num = tempnmaps;
	} else {
		nmaps_num = tempnmaps + 1;
	}
	if ((bForce == true) && (get_pcvar_num(pShowActivity) > 0)) {
		switch(get_pcvar_num(pShowActivity)) {
			case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_ADMIN_NOMINATED_MAP1", map);
			case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_ADMIN_NOMINATED_MAP2", name, map);
		}
	} else {
		client_print(0, print_chat, "%L", LANG_PLAYER, "DMAP_NOMINATED_MAP", name, map);
	}

	return PLUGIN_HANDLED;
}

public team_score() {

	new team[2];
	read_data(1, team, 1);
	teamscore[(team[0] == 'C') ? 0 : 1] = read_data(2);

	return PLUGIN_CONTINUE;
}

public plugin_end() {
	new current_map[32];
	get_mapname(current_map, 31);
	set_localinfo("amx_lastmap", current_map);

	if (istimeset) {
		set_cvar_float("mp_timelimit", oldtimelimit);
	} else {
		if (istimeset2) {
			set_cvar_float("mp_timelimit", get_cvar_float("mp_timelimit") - 2.0);
		}
	}
	if (isspeedset) {
		set_cvar_float("sv_maxspeed", thespeed);
	}
	if (iswinlimitset) {
		set_cvar_num("mp_winlimit", oldwinlimit);
	}
	return PLUGIN_CONTINUE;
}

public get_listing() {
	new i = 0, iavailable = 0;
	new line = 0, p;
	new stextsize = 0, isinthislist = 0, found_a_match = 0, done = 0;
	new linestr[256];
	new maptext[32];
	new current_map[32];
	get_mapname(current_map, 31);
	//pathtomaps = "mapcycle.txt";
	get_cvar_string("mapcyclefile", pathtomaps, 63);
	new smap[32];
	get_cvar_string("amx_nextmap", smap, 31);
	if (file_exists(pathtomaps)) {
		while (read_file(pathtomaps, line, linestr, 255, stextsize) && !done) {
			formatex(maptext, 31, "%s", linestr);
			if (is_map_valid(maptext) && !is_map_valid(maptext[1]) && equali(maptext, current_map)) {
				done = found_a_match = 1;
				line++;
				if (read_file(pathtomaps, line, linestr, 255, stextsize)) {
					formatex(maptext, 31, "%s", linestr);
					if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
						//////////////////////////////////////////
						if (equali(smap, "")) {
							register_cvar("amx_nextmap", "", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY);
						}
						set_cvar_string("amx_nextmap", maptext);
					} else {
						found_a_match = 0;
					}
				} else {
					found_a_match = 0;
				}
			} else {
				line++;
			}
		}
		/*
		if (!found_a_match) {
			line = 0;
			while (read_file(pathtomaps, line, linestr, 255, stextsize) && !found_a_match && line < 1024) {
				formatex(maptext, 31, "%s", linestr);
				if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
					if (equali(smap, "")) {
						register_cvar("amx_nextmap", "", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY);
					}
					set_cvar_string("amx_nextmap", maptext);
					found_a_match = 1;
				} else {
					line++;
				}
			}
		}
		*/
		/* CODE TO RANDOMIZE NEXTMAP VARIABLE!*/
		if (!found_a_match) {
			line = random_num(0, 50);
			new tries = 0;

			while ((read_file(pathtomaps, line, linestr, 255, stextsize) || !found_a_match) && (tries < 1024 && !found_a_match)) {
				formatex(maptext, 31, "%s", linestr);
				if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
					if (equali(smap, "")) {
						register_cvar("amx_nextmap", "", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY);
					}
					set_cvar_string("amx_nextmap", maptext);
					found_a_match = 1;
				} else {
					line = random_num(0, 50);
					tries++;
				}
			}
		}
	}

	line = 0;
	formatex(pathtomaps, 63, "%s/allmaps.txt", custompath);
	if (!file_exists(pathtomaps)) {
		new mapsadded = 0;
		while ((line = read_dir("maps", line, linestr, 255, stextsize)) != 0) {
			stextsize -= 4;

			if (stextsize > 0) {
				if (!equali(linestr[stextsize], ".bsp")) {
					continue;	// skip non map files
				}
				linestr[stextsize] = 0;	// remove .bsp
			}

			if (is_map_valid(linestr)) {
				write_file(pathtomaps, linestr);
				mapsadded++;
			}
		}
#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "Found %d maps in your <mod>/MAPS folder, and added these to the addons/amxmodx/allmaps.txt file", mapsadded);
#endif
		line = 0;
	}

	if (get_pcvar_float(pDmapStrict) == 1.0) {
		get_cvar_string("mapcyclefile", pathtomaps, 63);
		//pathtomaps = "mapcycle.txt";
	}

	if (file_exists(pathtomaps)) {
		while (read_file(pathtomaps, line, linestr, 255, stextsize) && i < MAX_MAPS_AMOUNT) {
			formatex(maptext, 31, "%s", linestr);
			if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
				isinthislist = 0;
				for (p = 0; p < i; p++) {
					if (equali(maptext, listofmaps[p])) {
						isinthislist = 1;
					}
				}
				if (!isinthislist) {
					listofmaps[i++] = maptext;
				}
			}
			line++;
		}
	}

	line = 0;
	for (p = 0; p < i; p++) {
		if (!isbanned(listofmaps[p]) && !islastmaps(listofmaps[p])) {
			iavailable++;
		}
	}
	new dummy_str[64];
	get_cvar_string("mapcyclefile", dummy_str, 63);
	//if (iavailable < maps_to_select && !equali(pathtomaps, "mapcycle.txt"))
	if (iavailable < maps_to_select && !equali(pathtomaps, dummy_str)) {
		//pathtomaps = "mapcycle.txt";
		get_cvar_string("mapcyclefile", pathtomaps, 63);
		if (file_exists(pathtomaps)) {
			while (read_file(pathtomaps, line, linestr, 255, stextsize) && i < MAX_MAPS_AMOUNT) {
				formatex(maptext, 31, "%s", linestr);
				if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
					isinthislist = 0;
					for (p = 0; p < i; p++)
						if (equali(maptext, listofmaps[p])) {
							isinthislist = 1;
						}
					if (!isinthislist) {
						listofmaps[i++] = maptext;
					}
				}
				line++;
			}
		}
	}
	totalmaps = i;
	iavailable = 0;
	for (p = 0; p < i; p++) {
		if (!isbanned(listofmaps[p]) && !islastmaps(listofmaps[p])) {
			iavailable++;
		}
	}
#if defined DEDICATED_LOG_ENABLED
	log_to_file(logfilename, "Found %d Maps in your mapcycle.txt/allmaps.txt file, %d are available for filling slots", i, iavailable);
#endif
}

public ban_some_maps() {
	//BAN MAPS FROM CONFIG FILE
	new banpath[64];
	formatex(banpath, 63, "%s/mapstoban.ini", custompath);
	new i = 0;
	new line = 0;
	new stextsize = 0;
	new linestr[256];
	new maptext[32];

	if (file_exists(banpath)) {
		while (read_file(banpath, line, linestr, 255, stextsize) && i < MAX_MAPS_AMOUNT) {
			formatex(maptext, 31, "%s", linestr);
			if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
				banthesemaps[i++] = maptext;
			}
			line++;
		}
	}
	totalbanned = i;
#if defined DEDICATED_LOG_ENABLED
	if (totalbanned > 0) {
		log_to_file(logfilename, "Banned %d Maps in your mapstoban.ini file", totalbanned);
	} else {
		log_to_file(logfilename, "Did not ban any maps from mapstoban.ini file");
	}
#endif
	//BAN RECENT MAPS PLAYED
	new lastmapspath[64];
	formatex(lastmapspath, 63, "%s/lastmapsplayed.txt", custompath);
	//new linestring[32];
	line = stextsize = 0;
	new current_map[32];
	get_mapname(current_map, 31);
	lastmaps[0] = current_map;
	bannedsofar++;
	currentplayers = activeplayers = rocks = 0;
	if (file_exists(lastmapspath)) {
		while(read_file(lastmapspath, line, linestr, 255, stextsize) && bannedsofar <= ban_last_maps) {
			if ((strlen(linestr) > 0) && (is_map_valid(linestr))) {
				formatex(lastmaps[bannedsofar++], 31, "%s", linestr);
			}
			line++;
		}
	}
	write_lastmaps();	//deletes and writes to lastmapsplayed.txt
}

public write_lastmaps() {
	new lastmapspath[64];
	formatex(lastmapspath, 63, "%s/lastmapsplayed.txt", custompath);
	if (file_exists(lastmapspath)) {
		delete_file(lastmapspath);
	}
	new text[256], p;
	for (p = 0; p < bannedsofar; p++) {
		formatex(text, 255, "%s", lastmaps[p]);
		write_file(lastmapspath, text);
	}
	write_file(lastmapspath, "Generated by map_nominate plugin,");
	write_file(lastmapspath, "these are most recent maps played");

	load_maps();
}

public load_maps() {
	new choicepath[64];
	formatex(choicepath, 63, "%s/mapchoice.ini", custompath);
	new line = 0;
	new stextsize = 0, isinlist, unable = 0, i;
	new linestr[256];
	new maptext[32];
	new current_map[32];
	get_mapname(current_map, 31);
	if (file_exists(choicepath)) {
		while (read_file(choicepath, line, linestr, 255, stextsize) && (num_nmapsfill < MAX_MAPS_AMOUNT)) {
			formatex(maptext, 31, "%s", linestr);
			if (is_map_valid(maptext) && !is_map_valid(maptext[1])) {
				isinlist = 0;
				if (isbanned(maptext) || islastmaps(maptext)) {
					isinlist = 1;
				} else {
					if (equali(maptext, current_map) || equali(maptext, last_map)) {
						isinlist = 1;
					} else {
						for (i = 0; i < num_nmapsfill; i++) {
							if (equali(maptext, nmapsfill[i])) {
#if defined DEDICATED_LOG_ENABLED
								log_to_file(logfilename, "Map ^"%s^" is already in list! It is defined it twice", maptext);
#endif
								isinlist = 1;
							}
						}
					}
				}
				if (!isinlist) {
					copy(nmapsfill[num_nmapsfill++], 31, maptext);
				} else {
					unable++;
				}
			}
			line++;
		}
#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "Loaded %d Maps into the maps that will be picked for the vote", num_nmapsfill);
		log_to_file(logfilename, "%d Maps were not loaded because they were the last maps played, or defined twice, or banned", unable);
	} else {
		log_to_file(logfilename, "Unable to open file %s, In order to get maps: your mapcycle.txt file will be searched", choicepath);
#endif
	}
	get_listing();
}

public load_defaultmaps() {
	new standardpath[64];
	formatex(standardpath, 63, "%s/standardmaps.ini", custompath);
	new i = 0;
	new line = 0;
	new stextsize = 0;
	new linestr[256];
	new maptext[32];
	usestandard = 1;
	if (!file_exists(standardpath)) {
		usestandard = standardtotal = 0;
	} else {
		while(read_file(standardpath, line, linestr, 255, stextsize) && i < 40) {
			formatex(maptext, 31, "%s", linestr);
			if (is_map_valid(maptext)) {
				standard[i++] = maptext;
			}
			line++;
		}
		standardtotal = i;
	}
	if (standardtotal < 5) {
		usestandard = 0;
#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "Attention, %d Maps were found in the standardmaps.ini file. This is no problem, but the words Custom will not be used", standardtotal);
#endif
	}
}

bool:iscustommap(map[]) {
	new a;
	for (a = 0; a < standardtotal; a++) {
		if (equali(map, standard[a])) {
			return false;
		}
	}
	if (usestandard) {
		return true;
	}
	return false;
}

bool:islastmaps(map[]) {
	new a;
	for (a = 0; a < bannedsofar; a++) {
		if (equali(map, lastmaps[a])) {
			return true;
		}
	}
	return false;
}

bool:isnominated(map[]) {
	new a;
	for (a = 0; a < nmaps_num; a++) {
		if (equali(map, nmaps[a])) {
			return true;
		}
	}
	return false;
}

bool:isbanned(map[]) {
	new a;
	for (a = 0; a < totalbanned; a++) {
		if (equali(map, banthesemaps[a])) {
			return true;
		}
	}
	return false;
}

loadsettings(filename[]) {
	if (!file_exists(filename)) {
		return 0;
	}

	new text[256], percent[5], strban[4], strplay[3], strwait[3], strwait2[3], strurl[64], strnum[3], strnum2[3];
	new len, pos = 0;
	new Float:numpercent;
	new banamount, nplayers, waittime, mapsnum;
	while (read_file(filename, pos++, text, 255, len)) {
		if (text[0] == ';') {
			continue;
		}
		switch(text[0]) {
			case 'r': {
				formatex(percent, 4, "%s", text[2]);
				numpercent = float(str_to_num(percent)) / 100.0;
				if (numpercent >= 0.03 && numpercent <= 1.0) {
					rtvpercent = numpercent;
				}
			}
			case 'q': {
				if (text[1] == '2') {
					quiet = 2;
				} else {
					quiet = 1;
				}
			}
			case 'c': {
				cycle = 1;
			}
			case 'd': {
				enabled = 0;
			}
			case 'f': {
				if (text[1] == 'r') {
					formatex(strwait2, 2, "%s", text[2]);
					waittime = str_to_num(strwait2);
					if (waittime >= 2 && waittime <= 20) {
						frequency = waittime;
					}
				} else {
					dofreeze = 0;
				}
			}
			case 'b': {
				formatex(strban, 3, "%s", text[2]);
				banamount = str_to_num(strban);
				if (banamount >= 0 && banamount <= 100) {
					if ((banamount == 0 && text[2] == '0') || banamount > 0) {
						ban_last_maps = banamount;
					}
				}
			}
			case 'm': {
				if (atstart) {
					formatex(strnum, 2, "%s", text[2]);
					mapsnum = str_to_num(strnum);
					if (mapsnum >= 2 && mapsnum <= 8) {
						maps_to_select = mapssave = mapsnum;
					}
				}
			}
			case 'p': {
				formatex(strplay, 2, "%s", text[2]);
				nplayers = str_to_num(strplay);
				if (nplayers > 0 && nplayers <= 32) {
					minimum = nplayers;
				}
			}
			case 'u': {
				formatex(strurl, 63, "%s", text[2]);
				if ((containi(strurl, "www") != -1 || containi(strurl, "http") != -1) && !equali(strurl, "http")) {
					mapsurl = strurl;
				}
			}
			case 'w': {
				formatex(strwait, 2, "%s", text[2]);
				waittime = str_to_num(strwait);
				if (waittime >= 5 && waittime <= 30) {
					minimumwait = waittime;
				}
			}
			case 'x': {
				formatex(strnum2, 2, "%s", text[2]);
				mapsnum = str_to_num(strnum2);
				if (mapsnum >= 1 && mapsnum <= 3) {
					maxnom = mapsnum;
				}
			}
			case 'y': {
				formatex(strnum2, 2, "%s", text[2]);
				mapsnum = str_to_num(strnum2);
				if (mapsnum >= 0 && mapsnum <= mapssave) {
					maxcustnom = mapsnum;
				}
			}
		}
	}
	return 1;
}

set_defaults(myid) {

	rtvpercent = 0.6;
	ban_last_maps = 4;
	maxnom = frequency = 3;
	quiet = cycle = 0;
	minimum = enabled = 1;
	minimumwait = 10;
	mapssave = maxcustnom = 5;
	mapsurl = "";
	dofreeze = bIsCstrike;

	if (myid < 0) {
		savesettings(-1);
	} else {
		savesettings(myid);
		showsettings(myid);
		console_print(myid, "==================   DEFAULTS SET   =========================");
	}
}

public dmaprtvpercent(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 3);
	new Float:percentage = float(str_to_num(arg)) / 100.0;
	if (percentage >= 0.03 && percentage <= 1.0) {
		rtvpercent = percentage;
		savesettings(id);
		showsettings(id);
	} else {
		console_print(id, "You must specify a value between 3 and 100 for dmap_rtvpercent");
		console_print(id, "This sets minimum percent of players that must say rockthevote to rockit");
	}
	return PLUGIN_HANDLED;
}

public dmaprtvplayers(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 3);
	new players = str_to_num(arg);
	if (players >= 1 && players <= 32) {
		minimum = players;
		savesettings(id);
		showsettings(id);
	} else {
		console_print(id, "You must specify a value between 1 and 32 for dmap_rtvplayers");
		console_print(id, "This sets minimum num of players that must say rockthevote to rockit");
	}
	return PLUGIN_HANDLED;
}

public dmaprtvwait(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 3);
	new wait = str_to_num(arg);
	if (wait >= 5 && wait <= 30) {
		minimumwait = wait;
		savesettings(id);
		showsettings(id);
	} else {
		console_print(id, "You must specify a value between 5 and 30 for dmap_rtvwait");
		console_print(id, "This sets how long must pass from the start of map before players may rockthevote");
	}
	return PLUGIN_HANDLED;
}

public dmapmessages(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 3);
	new wait = str_to_num(arg);
	if (wait >= 2 && wait <= 20) {
		frequency = wait;
		savesettings(id);
		showsettings(id);
	} else {
		console_print(id, "You must specify a value between 2 and 20 minutes for dmap_messages");
		console_print(id, "This sets how many minutes will pass between messages for nominations for available maps");
	}
	return PLUGIN_HANDLED;
}

public dmapmapsnum(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 3);
	new maps = str_to_num(arg);
	if (maps >= 2 && maps <= 8) {
		mapssave = maps;
		savesettings(id);
		showsettings(id);
		console_print(id, "*****  Settings for dmap_mapsnum do NOT take effect until the next map!!! ******");
	} else {
		console_print(id, "You must specify a value between 2 and 8 for dmap_mapsnum");
		console_print(id, "This sets the # of maps in the vote, changing this doesn't take effect until the next map");
	}
	return PLUGIN_HANDLED;
}

public dmapmaxnominations(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 3);
	new thisnumber = str_to_num(arg);
	if (thisnumber >= 0 && thisnumber <= 3) {
		maxnom = thisnumber;
		savesettings(id);
		showsettings(id);
		console_print(id, "*****  Settings for dmap_nominations do NOT take effect until the next map!!! ******");
	} else {
		console_print(id, "You must specify a value between 0 and 3 for dmap_nominations");
		console_print(id, "This sets the maximum number of maps a person can nominate");
	}
	return PLUGIN_HANDLED;
}

public dmapmaxcustom(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 3);
	new thisnumber = str_to_num(arg);
	if (thisnumber >= 0 && thisnumber <= mapssave) {
		maxcustnom = thisnumber;
		savesettings(id);
		showsettings(id);
	} else {
		console_print(id, "You must specify a value between {0} and maximum maps in the vote, which is {%d}, for dmap_maxcustom", mapssave);
		console_print(id, "This sets the maximum number of custom maps that may be nominated by the players");
	}
	return PLUGIN_HANDLED;
}

public dmapquiet(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 31);
	if (containi(arg, "off") != -1) {
		console_print(id, "======Quiet mode is now OFF, messages pertaining to maps will be shown=====");
		quiet = 0;
	} else if (containi(arg, "silent") != -1) {
		console_print(id, "======Quiet mode is now set to SILENT, A minimal amount of messages will be shown!=====");
		quiet = 2;
	} else if (containi(arg, "nosound") != -1) {
		console_print(id, "======Quiet mode is now set to NOSOUND, messages pertaining to maps will be shown, with no sound=====");
		quiet = 1;
	} else {
		console_print(id, "USAGE: dmap_quietmode <OFF|NOSOUND|SILENT>");
		return PLUGIN_HANDLED;
	}
	savesettings(id);
	showsettings(id);
	return PLUGIN_HANDLED;
}

public dmaprtvtoggle(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	if (enabled == 0) {
		console_print(id, "=========Rockthevote is now enabled==============");
	} else {
		console_print(id, "=========Rockthevote is not disabled=================");
	}
	enabled = !enabled;
	savesettings(id);
	showsettings(id);
	return PLUGIN_HANDLED;
}

public changefreeze(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	if (!bIsCstrike) {
		console_print(id, "Freeze is always off on non-Counter Strike Servers");
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 31);
	if (containi(arg, "off") != -1) {
		console_print(id, "=========FREEZE/Weapon Drop at end of round is now disabled==============");
		dofreeze = 0;
	} else {
		if (containi(arg, "on") != -1) {
			console_print(id, "=========FREEZE/Weapon Drop at end of round is now enabled==============");
			dofreeze = 1;
		} else {
			console_print(id, "========= USAGE of dmap_freeze: dmap_freeze on|off (this will turn freeze/weapons drop at end of round on/off");
			return PLUGIN_HANDLED;
		}
	}
	savesettings(id);
	showsettings(id);
	return PLUGIN_HANDLED;
}

public dmapcyclemode(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	if (!cycle) {
		console_print(id, "=========     Cylce mode is now ON, NO VOTE will take place!   =========");
	} else {
		console_print(id, "=========     Cycle Mode is already on, no change is made   =========");
		console_print(id, "=========     If you are trying to enable voting, use command dmap_votemode");
		return PLUGIN_HANDLED;
	}
	cycle = 1;
	savesettings(id);
	showsettings(id);
	if (inprogress) {
		console_print(id, "=========     The Vote In Progress cannot be terminated, unless it hasn't started!   =========");
	}
	return PLUGIN_HANDLED;
}

public dmapvotemode(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	if (cycle) {
		console_print(id, "=========     Voting mode is now ON, Votes WILL take place   =========");
	} else {
		console_print(id, "=========     Voting mode is already ON, no change is made   =========");
		console_print(id, "=========     If you are trying to disable voting, use command dmap_cyclemode");
		return PLUGIN_HANDLED;
	}
	cycle = 0;
	savesettings(id);
	showsettings(id);
	return PLUGIN_HANDLED;
}

public dmapbanlastmaps(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, 4);
	new banamount;
	banamount = str_to_num(arg);
	if (banamount >= 0 && banamount <= 99) {
		if (banamount > ban_last_maps) {
			console_print(id, "You have choosen to increase the number of banned maps");
			console_print(id, "Changes will not take affect until the nextmap; maps played more than %d maps ago will not be included in the ban", ban_last_maps);
		} else {
			if (banamount < ban_last_maps) {
				console_print(id, "You have choosen to decrease the number of banned maps");
			}
		}
		ban_last_maps = banamount;
		savesettings(id);
		showsettings(id);
	} else {
		console_print(id, "You must specify a value between 0 and 99 for dmap_banlastmaps");
		console_print(id, "dmap_banlastmaps <n> will ban the last <n> maps from being voted/nominated");
	}
	return PLUGIN_HANDLED;
}

public dmaphelp(id) {
	if (!(get_user_flags(id) & ADMIN_MAP)) {
		new myversion[32];
		get_cvar_string("Deags_Map_Manage", myversion, 31);
		console_print(id, "*****This server uses the plugin Deagles NextMap Management %s *****", myversion);
		console_print(id, "");
		if (cycle) {
			console_print(id, "===================  The plugin is set to cycle mode.  No vote will take place   =================");
			return PLUGIN_HANDLED;
		}
		console_print(id, "Say ^"vote mapname^" ^"nominate mapname^" or just simply ^"mapname^" to nominate a map");
		console_print(id, "");
		console_print(id, "Say ^"nominations^" to see a list of maps already nominated.");
		console_print(id, "Say ^"listmaps^" for a list of maps you can nominate");
		console_print(id, "Number of maps for the vote at the end of this map will be: %d", maps_to_select);
		console_print(id, "Players may nominate up to %d maps for the vote (dmap_nominations)", maxnom);
		console_print(id, "Players may nominate up to %d **Custom** maps for the vote (dmap_maxcustom)", maxcustnom);
		if (enabled) {
			console_print(id, "Say ^"rockthevote^" to rockthevote");
			console_print(id, "In order to rockthevote the following 3 conditions need to be true:");
			console_print(id, "%d percent of players must rockthevote, and at least %d players must rockthevote", floatround(rtvpercent * 100.0), minimum);
			console_print(id, "Vote may not be rocked before %d minutes have elapsed on the map", minimumwait);
		}
		if (containi(mapsurl, "www") != -1 || containi(mapsurl, "http") != -1) {
			console_print(id, "You can download Custom maps at %s (dmap_mapsurl)", mapsurl);
		}
		return PLUGIN_HANDLED;
	}
	//For CS 1.6, the following MOTD will display nicely, for 1.5, It will show html tags.
	client_print(id, print_chat, "%L", id, "DMAP_MOTD_LOADING");
	showmotdhelp(id);

	return PLUGIN_HANDLED;
}

public gen_maphelphtml() {
	new path[64], text[128];
	formatex(path, 63, "%s/map_manage_help.htm", custompath);
	if (file_exists(path)) {
		delete_file(path);
	}
	formatex(text, 127, "%L", LANG_SERVER, "DMAP_HELP");
	write_file(path, text);
	formatex(text, 127, "%L", LANG_SERVER, "DMAP_HELP2");
	write_file(path, text);
	formatex(text, 127, "%L", LANG_SERVER, "DMAP_HELP3");
	write_file(path, text);
	formatex(text, 127, "%L", LANG_SERVER, "DMAP_HELP4");
	write_file(path, text);
	formatex(text, 127, "%L", LANG_SERVER, "DMAP_HELP5");
	write_file(path, text);
	formatex(text, 127, "%L", LANG_SERVER, "DMAP_HELP6");
	write_file(path, text);
	formatex(text, 127, "%L", LANG_SERVER, "DMAP_HELP7");
	write_file(path, text);
	formatex(text, 127, "%L", LANG_SERVER, "DMAP_HELP8");
	write_file(path, text);
}

public showmotdhelp(id) {
	new header[80];
	new myversion[32];
	new helpfile[64];
	formatex(helpfile, 63, "%s/map_manage_help.htm", custompath);
	get_cvar_string("Deags_Map_Manage", myversion, 31);
	formatex(header, 79, "%L", id, "DMAP_HELP9", myversion);
	if (!file_exists(helpfile)) {
		gen_maphelphtml();
	}
	show_motd(id, helpfile, header);
}

public dmapstatus(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	showsettings(id);
	return PLUGIN_CONTINUE;
}

showsettings(id) {

	console_print(id, "-----------------------------------------------------------------------------------------------");
	console_print(id, "                 Status of Deagles Map Management Version %s", VERSION);

	if (cycle) {
		console_print(id, "===================  Mode is Cycle Mode NO vote will take place   =================");
		console_print(id, "===================  To enable voting use command dmap_votemode   ===================");
	} else {
		console_print(id, "=======================  Current Mode is Voting Mode   ===============================");
		if (quiet == 2) {
			console_print(id, "Quiet Mode is set to SILENT.  Minimal text messages will be shown, no sound will be played  (dmap_quietmode)");
		} else {
			if (quiet == 1) {
				console_print(id, "Quiet Mode is set to NOSOUND.  Text messages will be shown, with no sound.  (dmap_quietmode)");
			} else {
				console_print(id, "Quiet Mode is OFF, messages will be shown with sound (dmap_quietmode)");
			}
			console_print(id, "The time between messages about maps is %d minutes (dmap_messages)", frequency);
		}

		console_print(id, "The last %d Maps played will not be in the vote (changing this will not start until the Next Map)", ban_last_maps);

		if (maps_to_select != mapssave) {
			console_print(id, "Number of maps for the vote on this map is: %d (Next Map it will be: %d)", maps_to_select, mapssave);
		} else {
			console_print(id, "Number of maps for the vote at the end of this map will be: %d (dmap_mapsnum)", maps_to_select);
		}

		console_print(id, "Players may nominate up to %d maps each for the vote (dmap_nominations)", maxnom);

		console_print(id, "Players may nominate up to %d **Custom** maps each for the vote (dmap_maxcustom)", maxcustnom);

		if (get_pcvar_num(pEnforceTimelimit)) {
			console_print(id, "^"Timeleft^" will be followed to change the maps, not allowing players to finish the round");
			console_print(id, "To change this, ask your server admin to set the cvar ^"enforce_timelimit^" to 0");
		}

		if (enabled == 0) {
			if (!get_cvar_num("mp_timelimit")) {
				console_print(id, "rockthevote is disabled since mp_timelimit is set to 0");
			} else {
				console_print(id, "rockthevote is disabled; (dmap_rtvtoggle)");
			}
		}
		console_print(id, "In order to rockthevote the following 3 conditions need to be met:");
		console_print(id, "%d percent of players must rockthevote, and at least %d players must rockthevote", floatround(rtvpercent * 100.0), minimum);
		console_print(id, "Vote may not be rocked before %d minutes have elapsed on the map (10 is recommended)", minimumwait);
	}

	console_print(id, "The Freeze/Weapons Drop at the end of the round is %s (dmap_freeze)", dofreeze ? "ENABLED" : "DISABLED");

	if (!usestandard) {
		console_print(id, "Custom will not be shown by any maps, since file standardmaps.ini is not on the server");
	} else {
		console_print(id, "The words custom will be shown by Custom maps");
	}
	if (containi(mapsurl, "www") != -1 || containi(mapsurl, "http") != -1) {
		console_print(id, "URL to download Custom maps is %s (dmap_mapsurl)", mapsurl);
	} else {
		console_print(id, "URL to download maps from will not be shown (dmap_mapsurl)");
	}
	console_print(id, "------------------------------------------------------------------------------------------------");
	console_print(id, "Commands: dmap_status; dmap_cyclemode; dmap_votemode; dmap_quietmode <OFF|NOSOUND|SILENT>;");
	console_print(id, "Commands: dmap_banlastmaps <n>; dmap_default ; dmap_mapsurl <url>; dmap_mapsnum <n>; dmap_maxcustom <n>;");
	console_print(id, "Commands: dmap_rtvtoggle; dmap_rtvpercent <n>; dmap_rtvplayers <n>; dmap_rtvwait <n>;");
	console_print(id, "Commands: dmap_rockthevote; dmap_freeze; dmap_nominations <n>; dmap_messages <n(minutes)>;");
	console_print(id, "Cvars:    amx_emptymap <map>; amx_idletime <n>; amx_staytime <n>; dmap_strict <0|1>;");
	console_print(id, "Cvars:    emptymap_allowed <0|1>; enforce_timelimit <0|1>; amx_extendmap_max <n>; amx_extendmap_step <n>;");
	console_print(id, "Cvars:    nominations_allowed <0|1>; weapon_delay <0|1>");
	console_print(id, "-------------------------   use command dmap_help for more information   -----------------------");
}

change_custom_path() {
	new temp[64];
	formatex(temp, 63, "%s/dmap", custompath);
	if (dir_exists(temp)) {
		copy(custompath, 48, temp);
	}
}

savesettings(myid) {

	new settings[64];
	formatex(settings, 63, "%s/mapvault.dat", custompath);

	if (file_exists(settings)) {
		delete_file(settings);
	}
	new text[32], text2[128], percent, success = 1, usedany = 0;
	formatex(text2, 127, ";To use comments simply use ;");
	if (!write_file(settings,text2)) {
		success = 0;
	}
	formatex(text2, 127, ";Do not modify this variables, this is used by the Nomination_style_voting plugin to save settings");

	if (!write_file(settings, text2)) {
		success = 0;
	}
	formatex(text2, 127, ";If you delete this file, defaults will be restored.");
	if (!write_file(settings, text2)) {
		success = 0;
	}
	formatex(text2, 127, ";If you make an invalid setting, that specific setting will restore to the default");
	if (!write_file(settings, text2)) {
		success = 0;
	}
	if (!enabled) {
		formatex(text, 31, "d");	//d for disabled
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (quiet != 0) {
		if (quiet == 1) {
			formatex(text, 31, "q1");	//d for disabled
		} else {
			formatex(text, 31, "q2");	//d for disabled
		}
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (!dofreeze || !bIsCstrike) {
		formatex(text, 31, "f");
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (cycle) {
		formatex(text, 31, "c");	//c for Cycle mode=on
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	percent = floatround(rtvpercent * 100.0);
	if (percent >= 3 && percent <= 100) {
		formatex(text, 31, "r %d", percent);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (ban_last_maps >= 0 && ban_last_maps <= 100) {
		formatex(text, 31, "b %d", ban_last_maps);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (mapssave >= 2 && mapssave <= 8) {
		formatex(text, 31, "m %d", mapssave);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (maxnom >= 0 && maxnom <= 3) {
		formatex(text, 31, "x %d", maxnom);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (maxcustnom >= 0 && maxcustnom <= mapssave) {
		formatex(text, 31, "y %d", maxcustnom);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (minimum > 0 && minimum <= 32) {
		formatex(text, 31, "p %d", minimum);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (minimumwait >= 10 && minimumwait <= 30) {
		formatex(text, 31, "w %d", minimumwait);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (frequency >= 2 && frequency <= 20) {
		formatex(text, 31, "fr %d", frequency);
		usedany = 1;
		if (!write_file(settings, text)) {
			success = 0;
		}
	}
	if (containi(mapsurl, "www") != -1 || containi(mapsurl, "http") != -1) {
		formatex(text2, 75, "u %s", mapsurl);
		usedany = 1;
		if (!write_file(settings, text2)) {
			success = 0;
		}
	}
	if (usedany) {
		if (myid >= 0) {
			if (success) {
				console_print(myid, "*********   Settings saved successfully    *********");
			} else {
				console_print(myid, "Unable to write to file %s", settings);
			}
		}
		if (!success) {
#if defined DEDICATED_LOG_ENABLED
			log_to_file(logfilename, "Unable to write to file %s", settings);
#endif
			return 0;
		}
	} else {
		if (myid >= 0) {
			console_print(myid, "Variables not valid, not saving to %s", settings);
		}
#if defined DEDICATED_LOG_ENABLED
		log_to_file(logfilename, "Warning: Variables not valid, not saving to %s", settings);
#endif
		return 0;
	}
	return 1;
}

public dmapmapsurl(id, level, cid) {
	if (!cmd_access(id, level, cid, 2)) {
		return PLUGIN_HANDLED;
	}

	new arg[64];
	read_argv(1, arg, 63);
	if (equali(arg, "http")) {
		console_print(id, "You must specify a url that contains www or http (do not use any colons)(use ^"none^" to disable)");
		return PLUGIN_HANDLED;
	}
	if (containi(arg, "www") != -1 || containi(arg, "http") != -1) {
		console_print(id, "You have changed the mapsurl to %s", arg);
		mapsurl = arg;
		savesettings(id);
		showsettings(id);
	} else {
		if (containi(arg, "none") != -1) {
			console_print(id, "You have choosen to disable your mapsurl, none will be used");
			mapsurl = "";
			savesettings(id);
			showsettings(id);
		} else {
			console_print(id, "You must specify a url that contains www or http (do not use any colons)(use ^"none^" to disable)");
		}
	}
	return PLUGIN_HANDLED;
}

public dmapdefaults(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	set_defaults(id);
	return PLUGIN_HANDLED;	
}

public event_RoundStart() {
	isbetween = 0;
	isbuytime = 1;
	set_task(10.0, "now_safe_to_vote");

	currounds++;
	new players[32], playernum;
	get_players(players, playernum, "c");
	curplayers += playernum;
}

public event_RoundEnd() {
	isbetween = 1;
}

public now_safe_to_vote() {
	//client_print(0, print_chat, "Now it is safe to vote");
	isbuytime = 0;
}

public list_maps2() {
	messagemaps();
}

public list_maps3() {
	messagenominated();
}

public plugin_init() {

	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_dictionary("common.txt");
	register_dictionary("csds_map.txt");

	get_configsdir(custompath, 49);
	change_custom_path();

	register_clcmd("say", "HandleSay", 0, "Say: vote mapname, nominate mapname, or just mapname to nominate a map, say: nominations");
	register_clcmd("say rockthevote", "rock_the_vote", 0, "Rocks the Vote");
	register_clcmd("say rtv", "rock_the_vote", 0, "Rocks the Vote");
	register_clcmd("say listmaps", "list_maps", 0, "Lists all maps in a window and in console");
	register_clcmd("say nextmap", "say_nextmap", 0, "Shows nextmap information to players");
	register_concmd("dmap_help", "dmaphelp", 0, "Shows on-screen help information about Map Plugin");
	register_concmd("dmap_status", "dmapstatus", ADMIN_DMAP, "Shows settings/status/help of the map management variables");
	register_concmd("dmap_votemode", "dmapvotemode", ADMIN_SUPER_DMAP, "Enables Voting (This is default mode)");
	register_concmd("dmap_cyclemode", "dmapcyclemode", ADMIN_SUPER_DMAP, "Disables Voting (To restore voting use dmap_votemode)");
	register_concmd("dmap_banlastmaps", "dmapbanlastmaps", ADMIN_SUPER_DMAP, "Bans the last <n> maps played from being voted (0-99)");
	register_concmd("dmap_quietmode", "dmapquiet", ADMIN_SUPER_DMAP, "Usage: <OFF|NOSOUND|SILENT>");
	register_concmd("dmap_freeze", "changefreeze", ADMIN_SUPER_DMAP, "Toggles Freeze/Drop at end of round ON|off");
	register_concmd("dmap_messages", "dmapmessages", ADMIN_SUPER_DMAP, "Sets the time interval in minutes between messages");
	register_concmd("dmap_rtvtoggle", "dmaprtvtoggle", ADMIN_SUPER_DMAP, "Toggles on|off Ability of players to use rockthevote");
	register_concmd("dmap_rockthevote", "admin_rockit", ADMIN_DMAP, "(option: now) Allows admins to force a vote");
	register_concmd("amx_rockthevote", "admin_rockit", ADMIN_DMAP, "(option: now) Allows admins to force a vote");
	register_concmd("amx_rtv", "admin_rockit", ADMIN_DMAP, "(option: now) Allows admins to force a vote");
	register_concmd("dmap_rtvpercent", "dmaprtvpercent", ADMIN_SUPER_DMAP, "Set the percent (3-100) of players for a rtv");
	register_concmd("dmap_rtvplayers", "dmaprtvplayers", ADMIN_SUPER_DMAP, "Sets the minimum number of players needed to rockthevote");
	register_concmd("dmap_rtvwait", "dmaprtvwait", ADMIN_SUPER_DMAP, "Sets the minimum time before rockthevote can occur (5-30)");
	register_concmd("dmap_default", "dmapdefaults", ADMIN_SUPER_DMAP, "Will restore settings to default");
	register_concmd("dmap_mapsurl", "dmapmapsurl", ADMIN_SUPER_DMAP, "Specify what website to get custom maps from");
	register_concmd("dmap_mapsnum", "dmapmapsnum", ADMIN_SUPER_DMAP, "Set number of maps in vote (will not take effect until next map");
	register_concmd("dmap_nominations", "dmapmaxnominations", ADMIN_SUPER_DMAP, "Set maximum number of nominations for each person");
	register_concmd("dmap_maxcustom", "dmapmaxcustom", ADMIN_SUPER_DMAP, "Set maximum number of custom nominations that may be made");
	register_concmd("dmap_cancelvote", "dmapcancelvote", ADMIN_DMAP, "Cancels the rocked vote");
	register_concmd("dmap_nominate", "dmapnominate", ADMIN_DMAP, "<mapname> - Force nomination of a map by an admin");

	register_logevent("event_RoundStart", 2, "0=World triggered", "1=Round_Start");
	register_logevent("event_RoundEnd", 2, "0=World triggered", "1=Round_End");

	register_event("30", "changeMap", "a");
#if defined DEDICATED_LOG_ENABLED
	get_time("dmaplog%m%d.log", logfilename, 255);
#endif

	pDmapStrict = register_cvar("dmap_strict", "0");
	pEmptyMap = register_cvar("amx_emptymap", "de_dust2");
	pEmptymapAllowed = register_cvar("emptymap_allowed", "0");
	pEnforceTimelimit = register_cvar("enforce_timelimit", "0");
	pExtendmapMax = register_cvar("amx_extendmap_max", "90");
	pExtendmapStep = register_cvar("amx_extendmap_step", "15");
	pIdleTime = register_cvar("amx_idletime", "10");
	pNominationsAllowed = register_cvar("nominations_allowed", "1");
	pShowActivity = register_cvar("amx_show_activity", "1");
	register_cvar("amx_staytime", "300");			// No pointer; only used once
	pWeaponDelay = register_cvar("weapon_delay", "0");

	staytime = get_cvar_num("amx_staytime");

	bIsCstrike = (cstrike_running() == 1);
	nmaps_num = num_nmapsfill = 0;

	if (bIsCstrike) {
		register_cvar("Deags_Map_Manage", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY);
		register_event("TeamScore", "team_score", "a");
	} else {
		dofreeze = 0;
		register_cvar("Deags_Map_Manage", VERSION);
	}
	rtvpercent = 0.6;
	ban_last_maps = 4;
	minimumwait = 10;
	atstart = enabled = minimum = 1;
	quiet = cycle = isend = 0;
	mapsurl = "";
	set_task(3.0, "ban_some_maps");	//reads from lastmapsplayed.txt and stores into global array
	set_task(2.0, "get_listing");	//loads mapcycle / allmaps.txt
	set_task(14.0, "load_defaultmaps");	//loads standardmaps.ini
	set_task(15.0, "askfornextmap", 987456, "", 0, "b");
	set_task(5.0, "loopmessages", 987111, "", 0, "b");
	set_task(34.0, "gen_maphelphtml");	//Writes to help file, which is read every time that dmap_help is called by ANY player
	oldtimelimit = get_cvar_float("mp_timelimit");
	get_localinfo("amx_lastmap", last_map, 31);
	set_localinfo("amx_lastmap", "");
	set_task(1.0, "timer", 0, "curtime", 0, "b", 1);
	maps_to_select = mapssave = 10;
	new temparray[64];
	formatex(temparray, 63, "%s/mapvault.dat", custompath);
	if (!loadsettings(temparray)) {
		set_defaults(-1);
	}
	atstart = 0;
	register_menucmd(register_menuid(DMAP_MENU_TITLE), (-1 ^ (-1 << (maps_to_select + 2))), "vote_count");
}

public plugin_precache()
{
	precache_sound("csds/map/g_sps.wav");
	precache_sound("csds/map/g_start.wav");
	precache_sound("csds/map/g_end.wav");
	precache_sound("csds/map/g_1.wav");
	precache_sound("csds/map/g_2.wav");
	precache_sound("csds/map/g_3.wav");
	precache_sound("csds/map/g_4.wav");
	precache_sound("csds/map/g_5.wav");
}

stock set_dhudmessage( red = 0, green = 160, blue = 0, Float:x = -1.0, Float:y = 0.65, effects = 2, Float:fxtime = 0.6, Float:holdtime = 0.6, Float:fadeintime = 0.6, Float:fadeouttime = 0.6, bool:reliable = false )
{
    #define clamp_byte(%1)       ( clamp( %1, 0, 255 ) )
    #define pack_color(%1,%2,%3) ( %3 + ( %2 << 8 ) + ( %1 << 16 ) )

    __dhud_color       = pack_color( clamp_byte( red ), clamp_byte( green ), clamp_byte( blue ) );
    __dhud_x           = _:x;
    __dhud_y           = _:y;
    __dhud_effect      = effects;
    __dhud_fxtime      = _:fxtime;
    __dhud_holdtime    = _:holdtime;
    __dhud_fadeintime  = _:fadeintime;
    __dhud_fadeouttime = _:fadeouttime;
    __dhud_reliable    = _:reliable;

    return 1;
}

stock show_dhudmessage( index, const message[], any:... )
{
    new buffer[ 128 ];
    new numArguments = numargs();

    if( numArguments == 2 )
    {
        send_dhudMessage( index, message );
    }
    else if( index || numArguments == 3 )
    {
        vformat( buffer, charsmax( buffer ), message, 3 );
        send_dhudMessage( index, buffer );
    }
    else
    {
        new playersList[ 32 ], numPlayers;
        get_players( playersList, numPlayers, "ch" );

        if( !numPlayers )
        {
            return 0;
        }

        new Array:handleArrayML = ArrayCreate();

        for( new i = 2, j; i < numArguments; i++ )
        {
            if( getarg( i ) == LANG_PLAYER )
            {
                while( ( buffer[ j ] = getarg( i + 1, j++ ) ) ) {}
                j = 0;

                if( GetLangTransKey( buffer ) != TransKey_Bad )
                {
                    ArrayPushCell( handleArrayML, i++ );
                }
            }
        }

        new size = ArraySize( handleArrayML );

        if( !size )
        {
            vformat( buffer, charsmax( buffer ), message, 3 );
            send_dhudMessage( index, buffer );
        }
        else
        {
            for( new i = 0, j; i < numPlayers; i++ )
            {
                index = playersList[ i ];

                for( j = 0; j < size; j++ )
                {
                    setarg( ArrayGetCell( handleArrayML, j ), 0, index );
                }

                vformat( buffer, charsmax( buffer ), message, 3 );
                send_dhudMessage( index, buffer );
            }
        }

        ArrayDestroy( handleArrayML );
    }

    return 1;
}

stock send_dhudMessage( const index, const message[] )
{
    message_begin( __dhud_reliable ? ( index ? MSG_ONE : MSG_ALL ) : ( index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST ), SVC_DIRECTOR, _, index );
    {
        write_byte( strlen( message ) + 31 );
        write_byte( DRC_CMD_MESSAGE );
        write_byte( __dhud_effect );
        write_long( __dhud_color );
        write_long( __dhud_x );
        write_long( __dhud_y );
        write_long( __dhud_fadeintime );
        write_long( __dhud_fadeouttime );
        write_long( __dhud_holdtime );
        write_long( __dhud_fxtime );
        write_string( message );
    }
    message_end();
}
