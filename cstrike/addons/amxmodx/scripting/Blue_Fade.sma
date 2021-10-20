#include <amxmodx>
#include <hamsandwich>

#define PLUGIN    "Blue Fade"
#define VERSION   "0.1"
#define AUTHOR    "Stimul"

public plugin_init()
{
        register_plugin(PLUGIN, VERSION, AUTHOR);
       
        RegisterHam(Ham_Killed, "player", "fwdKilledPost");
}

public fwdKilledPost(victim, attacker, corpse)
{
        if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker)
                return HAM_IGNORED;
               
        message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, attacker)
        write_short(1<<10)
        write_short(1<<10)
        write_short(0x0000)
        write_byte(0)
        write_byte(0)
        write_byte(200)
        write_byte(75)
        message_end()
        return HAM_IGNORED;
}