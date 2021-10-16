/*******************************************************************************

  Parachute

  Version: 1.3
  Author: KRoTaL/JTP10181

  0.1    Release
  0.1.1  Players can't buy a parachute if they already own one
  0.1.2  Release for AMX MOD X
  0.1.3  Minor changes
  0.1.4  Players lose their parachute if they die
  0.1.5  Added amx_parachute cvar
  0.1.6  Changed set_origin to movetype_follow (you won't see your own parachute)
  0.1.7  Added amx_parachute <name> | admins with admin level a get a free parachute
  0.1.8  JTP - Cleaned up code, fixed runtime error
  1.0    JTP - Should be final version, made it work on basically any mod
  1.1    JTP - Added Changes from AMX Version 0.1.8
		     Added say give_parachute and parachute_fallspeed cvar
               Plays the release animation when you touch the ground
               Added chat responder for automatic help
  1.2    JTP - Added cvar to disable the detach animation
  			Redid animation code to improve organization
  			Force "walk" animation on players when falling
  			Change users gravity when falling to avoid choppiness
  1.3    JTP - Upgraded to pCVARs

  Commands:

	say buy_parachute   -   buys a parachute (CStrike ONLY)
	saw sell_parachute  -   sells your parachute (75% of the purchase price)
	say give_parachute <nick, #userid or @team>  -  gives your parachute to the player

	amx_parachute <nick, #userid or @team>  -  gives a player a free parachute (CStrike ONLY)
	amx_parachute @all  -  gives everyone a free parachute (CStrike ONLY)

	Press +use to slow down your fall.

  Cvars:

	sv_parachute "1"			- 0: disables the plugin - 1: enables the plugin

	parachute_cost "1000"		- cost of the parachute (CStrike ONLY)

	parachute_payback "75"		- how many percent of the parachute cost you get when you sell your parachute
								(ie. (75/100) * 1000 = 750$)

	parachute_fallspeed "100"	- speed of the fall when you use the parachute


  Setup (AMXX 1.x):

	Install the amxx file.
	Enable engine and cstrike (for cs only) in the amxx modules.ini
	Put the parachute.mdl file in the modname/models/ folder

*******************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <fun>

new bool:has_parachute[33]
new para_ent[33]
new gCStrike = 0
new pDetach, pFallSpeed, pEnabled, pCost, pPayback

#define PARACHUTE_LEVEL ADMIN_LEVEL_A

public plugin_init()
{
	register_plugin("Parachute", "1.3", "KRoT@L/JTP10181")
	pEnabled = register_cvar("sv_parachute", "1" )
	pFallSpeed = register_cvar("parachute_fallspeed", "100")
	pDetach = register_cvar("parachute_detach", "1")

	if (cstrike_running()) gCStrike = true

	if (gCStrike) {

		pCost = register_cvar("parachute_cost", "1000")
		pPayback = register_cvar("parachute_payback", "75")

		register_concmd("amx_parachute", "admin_give_parachute", PARACHUTE_LEVEL, "<nick, #userid or @team>" )
	}

	register_clcmd("say", "HandleSay")
	register_clcmd("say_team", "HandleSay")

	register_event("ResetHUD", "newSpawn", "be")
	register_event("DeathMsg", "death_event", "a")

	//Setup jtp10181 CVAR
	new cvarString[256], shortName[16]
	copy(shortName,15,"chute")

	register_cvar("jtp10181","",FCVAR_SERVER|FCVAR_SPONLY)
	get_cvar_string("jtp10181",cvarString,255)

	if (strlen(cvarString) == 0) {
		formatex(cvarString,255,shortName)
		set_cvar_string("jtp10181",cvarString)
	}
	else if (contain(cvarString,shortName) == -1) {
		format(cvarString,255,"%s,%s",cvarString, shortName)
		set_cvar_string("jtp10181",cvarString)
	}
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[])
{
	if (!cstrike_running() && equali(module, "cstrike")) {
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap) return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public client_connect(id)
{
	parachute_reset(id)
}

public client_disconnect(id)
{
	parachute_reset(id)
}

public death_event()
{
	new id = read_data(2)
	parachute_reset(id)
}

parachute_reset(id)
{
	if(para_ent[id] > 0) {
		if (is_valid_ent(para_ent[id])) {
			remove_entity(para_ent[id])
		}
	}

	if (is_user_alive(id)) set_user_gravity(id, 1.0)

	has_parachute[id] = false
	para_ent[id] = 0
}

public newSpawn(id)
{
	if(para_ent[id] > 0) {
		remove_entity(para_ent[id])
		set_user_gravity(id, 1.0)
		para_ent[id] = 0
	}

	if (!gCStrike || access(id,PARACHUTE_LEVEL) || get_pcvar_num(pCost) <= 0) {
		has_parachute[id] = true
		//set_view(id, CAMERA_3RDPERSON)
	}
}

public HandleSay(id)
{
	if(!is_user_connected(id)) return PLUGIN_CONTINUE

	new args[128]
	read_args(args, 127)
	remove_quotes(args)

	if (gCStrike) {
		if (equali(args, "buy_parachute")) {
			buy_parachute(id)
			return PLUGIN_HANDLED
		}
		else if (equali(args, "sell_parachute")) {
			sell_parachute(id)
			return PLUGIN_HANDLED
		}
		else if (containi(args, "give_parachute") == 0) {
			give_parachute(id,args[15])
			return PLUGIN_HANDLED
		}
	}

	if (containi(args, "parachute") != -1) {
		if (gCStrike) client_print(id, print_chat, "[AMXX] команды Парашюта: buy_parachute, sell_parachute, give_parachute")
		client_print(id, print_chat, "[AMXX], Чтобы использовать твой парашют нажимают и держат твою +use кнопку, падая")
	}

	return PLUGIN_CONTINUE
}

public buy_parachute(id)
{
	if (!gCStrike) return PLUGIN_CONTINUE
	if (!is_user_connected(id)) return PLUGIN_CONTINUE

	if (!get_pcvar_num(pEnabled)) {
		client_print(id, print_chat, "[AMXX] Плагин парашута отключен ")
		return PLUGIN_HANDLED
	}

	if (has_parachute[id]) {
		client_print(id, print_chat, "[AMXX] У тебя уже есть парашют")
		return PLUGIN_HANDLED
	}

	new money = cs_get_user_money(id)
	new cost = get_pcvar_num(pCost)

	if (money < cost) {
		client_print(id, print_chat, "[AMXX] У тебя нет денег для парашюта - $ Затрат %i", cost)
		return PLUGIN_HANDLED
	}

	cs_set_user_money(id, money - cost)
	client_print(id, print_chat, "[AMXX] Ты купил парашют. Чтобы использовать это, нажми +use.")
	has_parachute[id] = true

	return PLUGIN_HANDLED
}

public sell_parachute(id)
{
	if (!gCStrike) return PLUGIN_CONTINUE
	if (!is_user_connected(id)) return PLUGIN_CONTINUE

	if (!get_pcvar_num(pEnabled)) {
		client_print(id, print_chat, "[AMXX] Парашут выключен")
		return PLUGIN_HANDLED
	}

	if (!has_parachute[id]) {
		client_print(id, print_chat, "[AMXX] У тебя нет парашюта, чтобы продать")
		return PLUGIN_HANDLED
	}

	if (access(id,PARACHUTE_LEVEL)) {
		client_print(id, print_chat, "[AMXX] Ты не можешь продать свой свободный парашют admin")
		return PLUGIN_HANDLED
	}

	parachute_reset(id)

	new money = cs_get_user_money(id)
	new cost = get_pcvar_num(pCost)

	new sellamt = floatround(cost * (get_pcvar_num(pPayback) / 100.0))
	cs_set_user_money(id, money + sellamt)

	client_print(id, print_chat, "[AMX] Ты продал свой используемый парашют за $ %d", sellamt)

	return PLUGIN_CONTINUE
}

public give_parachute(id,args[])
{
	if (!gCStrike) return PLUGIN_CONTINUE
	if (!is_user_connected(id)) return PLUGIN_CONTINUE

	if (!get_pcvar_num(pEnabled)) {
		client_print(id, print_chat, "[AMXX] Плагин парошют выключен")
		return PLUGIN_HANDLED
	}

	if (!has_parachute[id]) {
		client_print(id, print_chat, "[AMXX] У тебя нет парашюта, чтобы дать")
		return PLUGIN_HANDLED
	}

	new player = cmd_target(id, args, 4)
	if (!player) return PLUGIN_HANDLED

	new id_name[32], pl_name[32]
	get_user_name(id, id_name, 31)
	get_user_name(player, pl_name, 31)

	if(has_parachute[player]) {
		client_print(id, print_chat, "[AMXX] У %s уже есть парашют.", pl_name)
		return PLUGIN_HANDLED
	}

	parachute_reset(id)
	has_parachute[player] = true

	client_print(id, print_chat, "[AMXX] Ты дал свой парашют %s.", pl_name)
	client_print(player, print_chat, "[AMXX] %s дал парашют тебе.", id_name)

	return PLUGIN_HANDLED
}

public admin_give_parachute(id, level, cid) {

	if (!gCStrike) return PLUGIN_CONTINUE

	if(!cmd_access(id,level,cid,2)) return PLUGIN_HANDLED

	if (!get_pcvar_num(pEnabled)) {
		client_print(id, print_chat, "[AMXX] Плагин выключен")
		return PLUGIN_HANDLED
	}

	new arg[32], name[32], name2[32], authid[35], authid2[35]
	read_argv(1,arg,31)
	get_user_name(id,name,31)
	get_user_authid(id,authid,34)

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum)
		else						get_players(players,inum,"e",arg[1])

		if (inum == 0) {
			console_print(id,"No clients in such team")
			return PLUGIN_HANDLED
		}

		for(new a = 0; a < inum; a++) {
			has_parachute[players[a]] = true
		}

		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: Дал парашют ^"%s^" players",name,arg[1])
			case 1:	client_print(0,print_chat,"ADMIN: Дал парашют ^"%s^" players",arg[1])
		}

		console_print(id,"[AMXX] You gave a parachute to ^"%s^" players",arg[1])
		log_amx("^"%s<%d><%s><>^" gave a parachute to ^"%s^"", name,get_user_userid(id),authid,arg[1])
	}
	else {

		new player = cmd_target(id,arg,6)
		if (!player) return PLUGIN_HANDLED

		has_parachute[player] = true

		get_user_name(player,name2,31)
		get_user_authid(player,authid2,34)

		switch(get_cvar_num("amx_show_activity")) {
			case 2:	client_print(0,print_chat,"ADMIN %s: Дал парашют ^"%s^"",name,name2)
			case 1:	client_print(0,print_chat,"ADMIN: Дал парашют ^"%s^"",name2)
		}

		console_print(id,"[AMXX] You gave a parachute to ^"%s^"", name2)
		log_amx("^"%s<%d><%s><>^" gave a parachute to ^"%s<%d><%s><>^"", name,get_user_userid(id),authid,name2,get_user_userid(player),authid2)
	}
	return PLUGIN_HANDLED
}

public client_PreThink(id)
{
	//parachute.mdl animation information
	//0 - deploy - 84 frames
	//1 - idle - 39 frames
	//2 - detach - 29 frames

	if (!get_pcvar_num(pEnabled)) return
	if (!is_user_alive(id) || !has_parachute[id]) return

	new Float:fallspeed = get_pcvar_float(pFallSpeed) * -1.0
	new Float:frame

	new button = get_user_button(id)
	new oldbutton = get_user_oldbutton(id)
	new flags = get_entity_flags(id)

	if (para_ent[id] > 0 && (flags & FL_ONGROUND)) {

		if (get_pcvar_num(pDetach)) {

			if (get_user_gravity(id) == 0.1) set_user_gravity(id, 1.0)

			if (entity_get_int(para_ent[id],EV_INT_sequence) != 2) {
				entity_set_int(para_ent[id], EV_INT_sequence, 2)
				entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
				entity_set_float(para_ent[id], EV_FL_frame, 0.0)
				entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
				entity_set_float(para_ent[id], EV_FL_framerate, 0.0)
				return
			}

			frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 2.0
			entity_set_float(para_ent[id],EV_FL_fuser1,frame)
			entity_set_float(para_ent[id],EV_FL_frame,frame)

			if (frame > 254.0) {
				remove_entity(para_ent[id])
				para_ent[id] = 0
			}
		}
		else {
			remove_entity(para_ent[id])
			set_user_gravity(id, 1.0)
			para_ent[id] = 0
		}

		return
	}

	if (button & IN_USE) {

		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)

		if (velocity[2] < 0.0) {

			if(para_ent[id] <= 0) {
				para_ent[id] = create_entity("info_target")
				if(para_ent[id] > 0) {
					entity_set_string(para_ent[id],EV_SZ_classname,"parachute")
					entity_set_edict(para_ent[id], EV_ENT_aiment, id)
					entity_set_edict(para_ent[id], EV_ENT_owner, id)
					entity_set_int(para_ent[id], EV_INT_movetype, MOVETYPE_FOLLOW)
					entity_set_int(para_ent[id], EV_INT_sequence, 0)
					entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
					entity_set_float(para_ent[id], EV_FL_frame, 0.0)
					entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				}
			}

			if (para_ent[id] > 0) {

				entity_set_int(id, EV_INT_sequence, 3)
				entity_set_int(id, EV_INT_gaitsequence, 1)
				entity_set_float(id, EV_FL_frame, 1.0)
				entity_set_float(id, EV_FL_framerate, 1.0)
				set_user_gravity(id, 0.1)

				velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
				entity_set_vector(id, EV_VEC_velocity, velocity)

				if (entity_get_int(para_ent[id],EV_INT_sequence) == 0) {

					frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 1.0
					entity_set_float(para_ent[id],EV_FL_fuser1,frame)
					entity_set_float(para_ent[id],EV_FL_frame,frame)

					if (frame > 100.0) {
						entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
						entity_set_float(para_ent[id], EV_FL_framerate, 0.4)
						entity_set_int(para_ent[id], EV_INT_sequence, 1)
						entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
						entity_set_float(para_ent[id], EV_FL_frame, 0.0)
						entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
					}
				}
			}
		}
		else if (para_ent[id] > 0) {
			remove_entity(para_ent[id])
			set_user_gravity(id, 1.0)
			para_ent[id] = 0
		}
	}
	else if ((oldbutton & IN_USE) && para_ent[id] > 0 ) {
		remove_entity(para_ent[id])
		set_user_gravity(id, 1.0)
		para_ent[id] = 0
	}
}