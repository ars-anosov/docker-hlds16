#include <amxmodx>

new g_MsgSync
new g_MsgSync2

new isConnected[33 char]

public plugin_init()
{
	register_plugin("Damager", "1.0", "Prayer")
	
	register_event("Damage", "EVENT_Damage", "b", "2!0", "3=0", "4!0")
	
	g_MsgSync = CreateHudSyncObj()
	g_MsgSync2 = CreateHudSyncObj()
}

public client_putinserver(id)
{
	isConnected{id} = true
}

public client_disconnect(id)
{
	isConnected{id} = false
}

public EVENT_Damage(id)
{ 
	if(isConnected{id})
	{
		static damage, pid
		damage = read_data(2)
		
		set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(id, g_MsgSync2, "%d", damage)
	
		pid = get_user_attacker(id)
		
		if((pid > 0) && (pid < 33) && isConnected{pid})
		{
			set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
			ShowSyncHudMsg(pid, g_MsgSync, "%d", damage)
		}
	}
}
