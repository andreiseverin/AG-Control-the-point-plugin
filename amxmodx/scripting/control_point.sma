/*
*	PLUGIN NAME 	: Control Point
*	VERSION		: v1.0
*	AUTHOR		: teylo
*
*
*  	Copyright (C) 2023, teylo 
*	
*
*/
#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>

#define PLUGIN	"Control Point"
#define VERSION	"1.0"
#define AUTHOR	"teylo"

// Radius to find platform
#define BLOCK_RADIUS 150.0 

// Hud mesage
new gHudLoc
new g_msg[512]

new g_red_wins = 0, g_blue_wins = 0;

new bool:win;

public plugin_init()
{
	register_plugin( 
		PLUGIN,		//: Control Point
		VERSION,	//: 1.0
		AUTHOR		//: teylo
	);

	new ag_gamemode[32];
	get_cvar_string("sv_ag_gamemode", ag_gamemode, charsmax(ag_gamemode));
	if (ag_gamemode[0] && !(equali(ag_gamemode, "control") ))
	{
		server_print("[Control Point] The %s plugin can only be run in the ^"control^" gamemode on Adrenaline Gamer 6.6 or its Mini version for HL.", PLUGIN);
		pause("ad");
		return;
	}

	// create hud objetc
	gHudLoc = CreateHudSyncObj();

	// catch msg events
	register_message(23, "fwWinSwitch") //23 is the msg id for our game_text messages

	// loop hud for tracking score
	check_alive_hud()

	// AG Messages - 
	register_message(get_user_msgid("Countdown"), "FwMsgCountdown");

}

public show_score()
{
	if (g_red_wins > g_blue_wins)
	{
		client_print(0, print_chat, "^^8[Control Point] ^^1 Red^^8: ^^2%d ^^8| ^^4Blue^^8: ^^2%d ^^8 - ^^1RED WINS!",g_red_wins,g_blue_wins)
	} else if (g_red_wins < g_blue_wins)
	{
		client_print(0, print_chat, "^^8[Control Point] ^^1 Red^^8: ^^2%d ^^8| ^^4Blue^^8: ^^2%d ^^8 - ^^4BLUE WINS!",g_red_wins,g_blue_wins)
	} else {
		client_print(0, print_chat, "^^8[Control Point] ^^1 Red^^8: ^^2%d ^^8| ^^4Blue^^8: ^^2%d ^^8 - TIE!",g_red_wins,g_blue_wins)
	}
}


//   msg_id           - Message id
//   msg_dest        - Destination type (see MSG_* constants in messages_const.inc)
//   msg_entity      - Entity receiving the message
public fwWinSwitch(MsgId, MsgDest, MsgEntity)
{
	static str[256]
	new argcount
	argcount = get_msg_args()

	if (argcount == 17)
	{
		get_msg_arg_string(17, str, 255) // 17 is the argument where we have our info
		replace_all(str, 254, "^t", "^^t")
		replace_all(str, 254, "^n", "^^n")
		replace_all(str, 254, "%", "%%")

		// Determine the destination of the message

		if ((equal(str, "RED WINS! Resetting game...")))
		{	
			fwRedWin()
		}
		if ((equal(str, "BLUE WINS! Resetting game...")))
		{	
			fwBlueWin()
		} 
		if ((equal(str, "Capturing: 8"))) // 8 to avoid double msg when both teams are on the cp
		{	
			fwCapturing(MsgEntity)
		}
	}
}

public fwCapturing(id)
{

	// 
	static origin [3], classname [32],ent,target[32],point[32]
	// get player origin
	pev (id, pev_origin, origin) 


	ent = -1 
	while ((ent = engfunc(EngFunc_FindEntityInSphere, ent, origin, BLOCK_RADIUS))!= 0) 
	{ 
		if (pev_valid (ent)) 
		{ 
			pev (ent, pev_classname, classname, charsmax (classname)) 
			pev (ent, pev_target, target, charsmax (target)) 
			if(equali(classname,"trigger_relay") && equali(target,"redbutton1"))
			{
				format(point, 32, "POINT 1")
			}
			if(equali(classname,"trigger_relay") && equali(target,"redbutton2"))
			{
				format(point, 32, "POINT 2")
			}
			if(equali(classname,"trigger_relay") && equali(target,"redbutton3"))
			{
				format(point, 32, "POINT 3")
			}
			if(equali(classname,"trigger_relay") && equali(target,"redbutton4"))
			{
				format(point, 32, "POINT 4")
			}
		}
  	} 

	// sort alive players by model and count them
	static sz_playerModel[32]
	get_user_info(id,"model",sz_playerModel,sizeof(sz_playerModel))
	if (equali(sz_playerModel, "red"))
	{
		client_print(0, print_chat, "^^8[Control Point] ^^1 RED TEAM ^^8 is capturing - ^^2%s",point)
	} else {
		client_print(0, print_chat, "^^8[Control Point] ^^4 BLUE TEAM ^^8 is capturing - ^^2%s",point)
	}
	
}

// Called every second during the agstart countdown
public FwMsgCountdown(id, dest, ent) 
{
	static count, sound;
	count = get_msg_arg_int(1);
	sound = get_msg_arg_int(2);

	// A match is started (Countdown end)

	if (count != -1 || sound != 0)
		return;

	// reset scoreboard 
	g_red_wins = 0;
	g_blue_wins = 0;

	// Show score in chat at the end of the map
	set_task(get_cvar_float("mp_timelimit")*60-1.0,"show_score");

}

public fwBlueWin()
{
	if (!win)
	{
		// add 1 to win counter
		g_blue_wins+=1;
		// set win to true to avoid looping for each id
		win = true;
		set_task(5.0,"ResetWin")
	}
}

public fwRedWin()
{
	if (!win)
	{
		// add 1 to win counter
		g_red_wins+=1;
		// set win to true to avoid looping for each id
		win = true;
		// reset win boolean after the mesage disapear (3 sec)
		set_task(5.0,"ResetWin")
	}
}

public ResetWin()
{
	win = false;
}

public check_alive_hud()
{

	static pos
	pos = 0
	pos += formatex(g_msg[pos], 511-pos, "^^8teylo's Control Point Plugin^n Score stats: [^^8RED: ^^1%d ^^8| ^^8BLUE: ^^4%d^^8]", g_red_wins,g_blue_wins)
	print_hud()

	set_task(1.0,"check_alive_hud")

	return PLUGIN_CONTINUE;

}

public print_hud()
{
	new players[32],inum,player
	get_players(players, inum)
	
	for(new i; i < inum; i++) 
	{
		player = players[i]
		set_hudmessage(255, 255, 255, -1.0, 0.0, 0, 1.0, 3.0, 0.1, 0.1)
		ShowSyncHudMsg(player, gHudLoc, "%s", g_msg)

	}
	return PLUGIN_HANDLED;	
}