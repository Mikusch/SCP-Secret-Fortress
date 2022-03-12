public bool SCP035_Create(int client)
{
	Classes_VipSpawn(client);

	Client[client].Extra2 = 0;

	return false;
}

public void SCP035_OnDeath(int client, Event event)
{
	Classes_DeathScp(client, event);
	CreateTimer(5.0, Timer_DissolveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action SCP035_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		float engineTime = GetGameTime();
		static float delay[MAXTF2PLAYERS];
		if(delay[client] > engineTime)
			return Plugin_Handled;

		if(StrContains(sample, "autodejectedtie", false) != -1)
		{
			delay[client] = engineTime+19.0;
			strcopy(sample, PLATFORM_MAX_PATH, "scp_sf/035/035closet3.mp3");
		}
		else if(StrContains(sample, "battlecry", false) != -1)
		{
			int value = GetRandomInt(1, 2);
			delay[client] = engineTime+2.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle4.mp3", value);
		}
		else if(StrContains(sample, "cheers", false) != -1)
		{
			delay[client] = engineTime+2.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle1.mp3", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "cloakedspy", false) != -1)
		{
			delay[client] = engineTime+4.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle2.mp3", GetRandomInt(1, 2));
		}
		else if(StrContains(sample, "goodjob", false)!=-1 || StrContains(sample, "incoming", false)!=-1 || StrContains(sample, "need", false)!=-1 || StrContains(sample, "niceshot", false)!=-1 || StrContains(sample, "sentry", false)!=-1)
		{
			delay[client] = engineTime+5.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle6.mp3", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "helpme", false) != -1)
		{
			delay[client] = engineTime+6.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/035/035closet2.mp3", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "jeers", false) != -1)
		{
			delay[client] = engineTime+2.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle7.mp3", GetRandomInt(1, 2));
		}
		else if(StrContains(sample, "negative", false) != -1)
		{
			delay[client] = engineTime+5.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle3.mp3", GetRandomInt(1, 2));
		}
		else if(StrContains(sample, "positive", false) != -1)
		{
			delay[client] = engineTime+8.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle5.mp3", GetRandomInt(1, 3));
		}
		else
		{
			return Plugin_Handled;
		}

		for(int i; i<3; i++)
		{
			EmitSoundToAll2(sample, client, _, level, flags, _, pitch);
		}
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}