#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <async>
#include <clientprefs>

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_WITCH 7
#define ZOMBIECLASS_TANK 8

Handle g_BuzzID;

ConVar g_cvAPIToken;

int i_BuzzID[MAXPLAYERS];

char api_token[128];

public Plugin myinfo = 
{
    name = "Lovense4Dead",
    author = "Rowedahelicon",
    description = "Don't ask.",
    version = "1.0",
    url = "https://cruxes.space/stuff/lovense4dead/"
}

public void OnPluginStart()
{    
    g_BuzzID = RegClientCookie("buzz_enaable", "Buzzy Enable", CookieAccess_Protected);
    g_cvAPIToken = CreateConVar("buzzy_api_key", "", "Sets the API token for Loveense");

    RegConsoleCmd("togglebuzz", toggleBuzz);

    //Minor
    HookEvent("charger_impact", Event_Impact);
    HookEvent("defibrillator_used", Event_Defib);
    HookEvent("player_falldamage", Event_FallDamage);
    HookEvent("friendly_fire", Event_Impact); //Uses victim w/ no damage
    HookEvent("player_hurt", Event_PlayerHurt); //Uses victim w/ no damage
    
    //Start scenarios
    HookEvent("charger_carry_start", Event_Carry);
    HookEvent("jockey_ride", Event_Drag); //Jockey Rides
    HookEvent("player_incapacitated", Event_Incap);
    HookEvent("player_ledge_grab", Event_Incap);

    //End scenarios, kill connection
    HookEvent("charger_carry_end", Event_Stop);
    HookEvent("choke_end", Event_Stop); //Smoker choking
    HookEvent("jockey_ride_end", Event_Stop); //Jockey rides
    HookEvent("revive_success", Event_Stop); //Player picked up
    HookEvent("player_death", Event_Stop); //Player died
    HookEvent("mission_lost", Event_MissionLost); //Mission failed
    HookEvent("round_freeze_end", Event_MissionLost); //Unknown
    HookEvent("round_end", Event_MissionLost); //Unknown
    HookEvent("round_end_message", Event_MissionLost); //Unknown
    HookEvent("map_transition", Event_MissionLost); //End of map

    OnMapStart();
}

public void OnMapStart()
{ 
    g_cvAPIToken.GetString(api_token, sizeof(api_token));

    for(int i = 1; i < MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            loadCookieValue(i);
        }
    }

}

public void OnClientConnected(int client)
{
    loadCookieValue(client);
}

public Action toggleBuzz(int client, int args)
{
    if (IsValidSurvivor(client) && AreClientCookiesCached(client))
	{
        loadCookieValue(client);
            
        if (i_BuzzID[client] == 1 )
        {
            SetClientCookie(client, g_BuzzID, "0");
            i_BuzzID[client] = 0;
            ReplyToCommand(client, "Your buzzing has been disabled!");
        }
        else
        {
            SetClientCookie(client, g_BuzzID, "1");
            i_BuzzID[client] = 1;
            ReplyToCommand(client, "Your buzzing has been enabled!");
        }
    }

    return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int type = event.GetInt("type");

    if(IsHanging(client)) return Plugin_Continue; //Don't cancel our hanging buzz
    if(IsIncapped(client)) return Plugin_Continue; //Don't cancel our incap buzz

    if(IsValidZombie(attacker))
    {
        int class = GetZombieType(attacker);

        if( class == ZOMBIECLASS_CHARGER && IsAttacked(client))
        {
            sendCommand(client, "Function", "&action=Vibrate:85&timeSec=1");
        }

        if( class == ZOMBIECLASS_SMOKER && IsAttacked(client))
        {
            sendCommand(client, "Function", "&action=Vibrate:70&timeSec=1");
        }    
        
        if( class == ZOMBIECLASS_SPITTER)
        {
            sendCommand(client, "Function", "&action=Vibrate:20&timeSec=1");
        }

        if( class == ZOMBIECLASS_JOCKEY && !IsAttacked(client))
        {
            sendCommand(client, "Function", "&action=Vibrate:10&timeSec=1");
        }

        if( class == ZOMBIECLASS_HUNTER && IsAttacked(client))
        {
            sendCommand(client, "Function", "&action=Vibrate:80&timeSec=1");
        }

        if( class == ZOMBIECLASS_TANK)
        {
            sendCommand(client, "Function", "&action=Vibrate:100&timeSec=3");
        }
    }
    else
    {
        switch(type)
        {
            case 8: //Fire
            {
                sendCommand(client, "Function", "&action=Vibrate:1&timeSec=1");
            }
            case 128: //Zombies
            {
                sendCommand(client, "Function", "&action=Vibrate:2&timeSec=1");
            }
            case 134217792:
            {
                sendCommand(client, "Function", "&action=Vibrate:16&timeSec=1");
            }
        }
    }

    return Plugin_Continue;
}

public Action Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        sendCommand(i, "Function", "&action=Stop&timeSec=1");
    }
    
    return Plugin_Continue;
}

public Action Event_Impact(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));

    if(IsIncapped(client)) return Plugin_Continue;

    sendCommand(client, "Function", "&action=Vibrate:75&timeSec=1");
    return Plugin_Continue;
}

public Action Event_Defib(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("subject"));
    sendCommand(client, "Function", "&action=Vibrate:75&timeSec=1");
    return Plugin_Continue;
}

public Action Event_Carry(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));
    sendCommand(client, "Pattern", "&rule=V:1;F:v;S:1000#&strength=50&timeSec=0");
    return Plugin_Continue;
}

public Action Event_Drag(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));
    sendCommand(client, "Pattern", "&rule=V:1;F:v;S:1000#&strength=40;5&timeSec=0");
    return Plugin_Continue;
}

// public Action Event_Pounce(Event event, const char[] name, bool dontBroadcast)
// {
//     int client = GetClientOfUserId(event.GetInt("victim"));
//     sendCommand(client, "Pattern", "&rule=V:1;F:v;S:400#&strength=50;5&timeSec=0");
//     return Plugin_Continue;
// }

public Action Event_Incap(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    //if(IsAttacked(client)) return Plugin_Continue; //Let us be attacked first
    
    sendCommand(client, "Function", "&action=Vibrate:90&timeSec=500");
    return Plugin_Continue;
}

// public Action Event_Pummel(Event event, const char[] name, bool dontBroadcast)
// {
//     int client = GetClientOfUserId(event.GetInt("victim"));
//     //sendCommand(client, "Pattern", "&action=Stop&timeSec=0&loopRunningSec=5&loopPauseSec=4");
//     return Plugin_Continue;
// }


public Action Event_FallDamage(Event event, const char[] name, bool dontBroadcast)
{
    char command[128];
    int client = GetClientOfUserId(event.GetInt("userid"));
    int damage = event.GetInt("damage");
    if(damage > 100)
    {
        damage = 100; //Cap this
    }

    if(damage > 0)
    {
        Format(command, sizeof(command), "&action=Vibrate:%i&timeSec=1", damage);
        sendCommand(client, "Function", command);
    }

    return Plugin_Continue;
}

public Action Event_Stop(Event event, const char[] name, bool dontBroadcast)
{
    int client = -1;
        
    if(StrEqual(name, "charger_carry_end") || StrEqual(name, "jockey_ride_end") || StrEqual(name, "charger_pummel_end") || StrEqual(name, "choke_end") || StrEqual(name, "pounce_end"))
    {
        client = GetClientOfUserId(event.GetInt("victim"));
    }
    
    if(StrEqual(name, "drag_end") || StrEqual(name, "revive_success"))
    {
        client = GetClientOfUserId(event.GetInt("subject"));
    }

    if(StrEqual(name, "player_death"))
    {
        client = GetClientOfUserId(event.GetInt("userid"));
        if( IsValidSurvivor(client))
        {
            sendCommand(client, "Function", "&action=Stop&timeSec=1");
            return Plugin_Continue;
        }

    }

    if(!IsValidSurvivor(client)) return Plugin_Continue;

    if(IsIncapped(client))
    {
        //If something happened to end, but we're incapped, just do a light buzz
        sendCommand(client, "Function", "&action=Vibrate:4&timeSec=0");
    }
    else
    {
        //Stop all buzzing
        sendCommand(client, "Function", "&action=Stop&timeSec=1");
    }

    return Plugin_Continue;
}

stock void sendCommand(int client, char[] command, char[] fullCommand)
{
    if(!IsValidSurvivor(client)) return;
    if(IsDrugged(client)) return;
    if (i_BuzzID[client] == 1)
    {
        char m_szAuthID[64];
        GetClientAuthId(client, AuthId_SteamID64, m_szAuthID, sizeof(m_szAuthID));

        char m_szMessage[2048];
        Format(m_szMessage, sizeof(m_szMessage), "token=%s&uid=%s&command=%s%s&apiVer=1", api_token, m_szAuthID, command, fullCommand); 

        if (StrEqual(m_szAuthID, "STEAM_ID_STOP_IGNORING_RETVALS")) return;

        CurlHandle h = Async_CurlNew(123);
        Async_CurlPost(h, "https://api.lovense.com/api/lan/v2/command", m_szMessage, OnRequestDone);
    }
    else
    {
        return;
    }
}

public void OnRequestDone(CurlHandle request, int curlcode, int httpcode, int size, any userdata)
{
    Async_Close(request);
}

stock bool IsIncapped(int client)
{
    if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1) return true;
    return false;
}

stock bool IsHanging(int client)
{
    if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1) return true;
    return false;
}

stock bool IsDrugged(int client)
{
    if (GetEntProp(client, Prop_Send, "m_bAdrenalineActive") == 1) return true;
    return false;
}

stock bool IsAttacked(int client)
{
    int attacker;

    /* Charger */
    attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
    if (attacker > 0)
    {
        return true;
    }

    attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
    if (attacker > 0)
    {
        return true;
    }

    /* Hunter */
    attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
    if (attacker > 0)
    {
        return true;
    }

    /* Smoker */
    attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
    if (attacker > 0)
    {
        return true;
    }

    /* Jockey */
    attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
    if (attacker > 0)
    {
        return true;
    }

    return false;
}

stock bool IsValidSurvivor(int client)
{
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2) return true;
    return false;
}

stock bool IsValidZombie(int client)
{
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 3) return true;
    return false;
}

stock int GetZombieType(int client)
{
    return GetEntProp(client, Prop_Send, "m_zombieClass");
}

stock void loadCookieValue(int client)
{
    if(IsValidSurvivor(client) && AreClientCookiesCached(client))
	{
        char sCookieValue[10];
        GetClientCookie(client, g_BuzzID, sCookieValue, sizeof(sCookieValue));
        i_BuzzID[client] = StringToInt(sCookieValue);
    }
}
