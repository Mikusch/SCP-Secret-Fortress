enum Achievements
{
	Achievement_MTFSpawn = 0,
	Achievement_ChaosSpawn,
	Achievement_DeathTesla,
	Achievement_DeathEarly,
	Achievement_Death173,
	Achievement_Death106,
	Achievement_DeathFall,
	Achievement_DeathGrenade,
	Achievement_DeathEnrage,
	Achievement_DeathMicro,
	Achievement_Kill106,
	Achievement_KillSCPMirco,
	Achievement_KillSCPSci,
	Achievement_KillMirco,
	Achievement_KillSci,
	Achievement_KillDClass,
	Achievement_KillSpree,	//TODO
	Achievement_FindGun,
	Achievement_FindO5,
	Achievement_FindSCP,	// TODO
	Achievement_EscapeDClass,
	Achievement_EscapeSci,
	Achievement_EscapeSpeed,	// TODO
	Achievement_Escape207,	// TODO
	Achievement_SurvivePocket,
	Achievement_SurviveWarhead,
	Achievement_Survive500,
	Achievement_SurviveAdren,	// TODO
	Achievement_SurviveCancel,	// TODO
	Achievement_Intercom,
	Achievement_Upgrade,
	Achievement_Revive,
	Achievement_DisarmMTF
}

bool NoAchieve;

void GiveAchievement(Achievements achievement, int client)
{
	if(NoAchieve)
		return;

	switch(achievement)
	{
		case Achievement_KillDClass:
		{
			if(!AreClientCookiesCached(client))
				return;

			static char buffer[16];
			CookieDClass.Get(client, buffer, sizeof(buffer));
			int amount = StringToInt(buffer)+1;
			IntToString(amount, buffer, sizeof(buffer));
			CookieDClass.Set(client, buffer);
			if(amount < 50)
				return;
		}
		case Achievement_SurviveWarhead:
		{
			for(int i=1; i<=MaxClients; i++)
			{
				if(IsValidClient(i) && !IsSpec(i))
					Forward_OnAchievement(i, achievement);
			}
			return;
		}
	}

	Forward_OnAchievement(client, achievement);
}