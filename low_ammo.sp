/*  SM Advert in low ammo
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Handle:trie_armas;
bool csgo;
float percentage;
Handle cvar_p;

public Plugin:myinfo =
{
	name = "SM Advert in low ammo",
	author = "Franc1sco franug",
	description = "",
	version = "1.2",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)csgo = false;
	else csgo = true;
	
	cvar_p = CreateConVar("sm_advertlowammo_percentage", "0.30", "Percentage the ammo spend needed for show the advert");
	CreateConVar("sm_advertlowammo_version", "1.2", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	percentage = GetConVarFloat(cvar_p);
	HookConVarChange(cvar_p, OnSettingsChange);
	
	trie_armas = CreateTrie();
	
	HookEvent("weapon_fire", ClientWeaponFire);
	
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	percentage = StringToFloat(newvalue);
}

public OnMapStart()
{
	if(csgo) PrecacheSound("ui/beep22.wav");	
}

public ClientWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,  "userid"));
    Darm(client);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, EventItemPickup2);
}

Darm(client)
{
	if(IsPlayerAlive(client))
	{
		new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if(weapon > 0 && (weapon == GetPlayerWeaponSlot(client, 0) || weapon == GetPlayerWeaponSlot(client, 1)))
		{
			new warray;
			decl String:classname[64];
			//GetEdictClassname(weapon, classname, sizeof(classname));
			if(csgo)Format(classname, 4, "%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
			else GetEdictClassname(weapon, classname, sizeof(classname));
			
			if(GetTrieValue(trie_armas, classname, warray))
			{
				int ammo = GetReserveAmmo(weapon)-1;
				if (ammo < 0)ammo = 0;
				//PrintToChat(client, "municion fijado a %i",warray[1]);
				float porc = (warray * percentage);
				if(ammo <= RoundToCeil(porc))
				{
					if(csgo)
					{
						PrintCenterText(client, "<font size='30' color='#F7FE2E'>Low AMMO</font><font size='30' color='#DF0101'> %i/%i</font>",ammo, warray);
						EmitSoundToClient(client, "ui/beep22.wav");
					}
					else
					{
						PrintCenterText(client, "Low AMMO %i/%i",ammo, warray);
					}
				}
			}
		}
	}
}

stock GetReserveAmmo(weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_iClip1");
}

public Action:EventItemPickup2(client, weapon)
{
	if(weapon == GetPlayerWeaponSlot(client, 0) || weapon == GetPlayerWeaponSlot(client, 1))
	{
		new warray;
		decl String:classname[64];
		//GetEdictClassname(weapon, classname, sizeof(classname));
		if(csgo) Format(classname, 4, "%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		else GetEdictClassname(weapon, classname, sizeof(classname));
		
		
		if(!GetTrieValue(trie_armas, classname, warray))
		{
			warray = GetEntProp(weapon, Prop_Send, "m_iClip1");
		
			SetTrieValue(trie_armas, classname, warray);
		}
	}
}