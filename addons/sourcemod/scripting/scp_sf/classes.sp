enum struct ClassEnum
{
	char Name[16];
	char Display[22];

	TFClassType Class;
	char Model[PLATFORM_MAX_PATH];
	int ModelIndex;
	int ModelAlt;
	bool Human;
	bool Vip;

	float Speak;
	float Hear;
	float SpeakTeam;
	float HearTeam;

	int Health;
	float Speed;
	bool Regen;

	int Group;
	TFTeam Team;

	int Floor;
	char Spawn[32];
	char Color[16];
	int Color4[4];

	int Ammo[Ammo_MAX];
	int MaxAmmo[Ammo_MAX];
	int Items[ITEMS_MAX+1];

	Function OnAnimation;	// Action(int client, PlayerAnimEvent_t &anim, int &data)
	Function OnButton;	// void(int client, int button)
	Function OnCondAdded;	// void(int client, TFCond cond)
	Function OnCondRemoved;	// void(int client, TFCond cond)
	Function OnDealDamage;	// Action(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	Function OnDeath;		// void(int client, int attacker)
	Function OnGlowPlayer;	// bool(int client, int victim)
	Function OnKeycard;	// int(int client, AccessEnum access)
	Function OnKill;		// void(int client, int victim)
	Function OnMaxHealth;	// void(int client, int &health)
	Function OnPickup;	// bool(int client, int entity)
	Function OnSeePlayer;	// bool(int client, int victim)
	Function OnSound;		// Action(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	Function OnSpawn;		// void(int client)
	Function OnSpeed;		// void(int client, float &speed)
	Function OnTakeDamage;	// Action(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	Function OnTheme;		// void(int client, char path[PLATFORM_MAX_PATH])
	Function OnWeaponSwitch;	// void(int client, int entity)

	void SetDefaults()
	{
		this.OnAnimation = INVALID_FUNCTION;
		this.OnButton = INVALID_FUNCTION;
		this.OnCondAdded = INVALID_FUNCTION;
		this.OnCondRemoved = INVALID_FUNCTION;
		this.OnDealDamage = INVALID_FUNCTION;
		this.OnDeath = INVALID_FUNCTION;
		this.OnGlowPlayer = INVALID_FUNCTION;
		this.OnKeycard = INVALID_FUNCTION;
		this.OnKill = INVALID_FUNCTION;
		this.OnMaxHealth = INVALID_FUNCTION;
		this.OnPickup = INVALID_FUNCTION;
		this.OnSeePlayer = INVALID_FUNCTION;
		this.OnSound = INVALID_FUNCTION;
		this.OnSpawn = INVALID_FUNCTION;
		this.OnSpeed = INVALID_FUNCTION;
		this.OnTakeDamage = INVALID_FUNCTION;
		this.OnTheme = INVALID_FUNCTION;
		this.OnWeaponSwitch = INVALID_FUNCTION;
	}
}

static ArrayList Classes;

void Classes_Setup(KeyValues main, KeyValues map, ArrayList whitelist)
{
	if(Classes != INVALID_HANDLE)
		delete Classes;

	Classes = new ArrayList(sizeof(ClassEnum));

	KeyValues kv = main;
	if(map)
	{
		map.Rewind();
		if(map.JumpToKey("Classes"))
			kv = map;
	}

	ClassEnum defaul;
	defaul.SetDefaults();
	if(kv.JumpToKey("default"))
	{
		GrabKvValues(kv, defaul, defaul, -1);
		kv.GoBack();
	}

	ClassEnum class;
	if(kv.GotoFirstSubKey())
	{
		int count;
		do
		{
			if(!kv.GetSectionName(class.Name, sizeof(class.Name)) || StrEqual(class.Name, "default"))
				continue;

			if(whitelist && whitelist.FindString(class.Name)==-1)
				continue;

			GrabKvValues(kv, class, defaul, count++);
			Format(class.Display, sizeof(class.Display), "class_%s", class.Name);
			if(!TranslationPhraseExists(class.Display))
				strcopy(class.Display, sizeof(class.Display), "class_0");

			Classes.PushArray(class);
		} while(kv.GotoNextKey());
	}
}

static void GrabKvValues(KeyValues kv, ClassEnum class, ClassEnum defaul, int index)
{
	class.Class = KvGetClass(kv, "class", defaul.Class);

	class.Speed = kv.GetFloat("speed", defaul.Speed);
	class.Speak = kv.GetFloat("speak", defaul.Speak);
	class.Hear = kv.GetFloat("hear", defaul.Hear);
	class.SpeakTeam = kv.GetFloat("speakteam", defaul.SpeakTeam);
	class.HearTeam = kv.GetFloat("hearteam", defaul.HearTeam);

	class.Health = kv.GetNum("health", defaul.Health);
	class.Group = kv.GetNum("group", defaul.Group);
	class.Floor = kv.GetNum("floor", defaul.Floor);
	class.Team = view_as<TFTeam>(kv.GetNum("team", view_as<int>(defaul.Team)));
	class.Regen = view_as<bool>(kv.GetNum("regen", defaul.Regen ? 1 : 0));
	class.Human = view_as<bool>(kv.GetNum("human", defaul.Human ? 1 : 0));
	class.Vip = view_as<bool>(kv.GetNum("vip", defaul.Vip ? 1 : 0));

	class.Color4 = defaul.Color4;
	kv.GetColor4("color4", class.Color4);

	class.OnAnimation = KvGetFunction(kv, "func_precache");
	if(class.OnAnimation != INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnAnimation);
		Call_PushCell(index);
		Call_Finish();
	}

	class.OnAnimation = KvGetFunction(kv, "func_animation", defaul.OnAnimation);
	class.OnButton = KvGetFunction(kv, "func_button", defaul.OnButton);
	class.OnCondAdded = KvGetFunction(kv, "func_condadded", defaul.OnCondAdded);
	class.OnCondRemoved = KvGetFunction(kv, "func_condremove", defaul.OnCondRemoved);
	class.OnDealDamage = KvGetFunction(kv, "func_dealdamage", defaul.OnDealDamage);
	class.OnDeath = KvGetFunction(kv, "func_death", defaul.OnDeath);
	class.OnGlowPlayer = KvGetFunction(kv, "func_glow", defaul.OnGlowPlayer);
	class.OnKeycard = KvGetFunction(kv, "func_keycard", defaul.OnKeycard);
	class.OnKill = KvGetFunction(kv, "func_kill", defaul.OnKill);
	class.OnMaxHealth = KvGetFunction(kv, "func_maxhealth", defaul.OnMaxHealth);
	class.OnPickup = KvGetFunction(kv, "func_pickup", defaul.OnPickup);
	class.OnSeePlayer = KvGetFunction(kv, "func_transmit", defaul.OnSeePlayer);
	class.OnSound = KvGetFunction(kv, "func_sound", defaul.OnSound);
	class.OnSpawn = KvGetFunction(kv, "func_spawn", defaul.OnSpawn);
	class.OnSpeed = KvGetFunction(kv, "func_speed", defaul.OnSpeed);
	class.OnTakeDamage = KvGetFunction(kv, "func_takedamage", defaul.OnTakeDamage);
	class.OnTheme = KvGetFunction(kv, "func_theme", defaul.OnTheme);
	class.OnWeaponSwitch = KvGetFunction(kv, "func_switch", defaul.OnWeaponSwitch);

	kv.GetString("spawn", class.Spawn, sizeof(class.Spawn), defaul.Spawn);
	kv.GetString("color", class.Color, sizeof(class.Color), defaul.Color);

	char num[6];
	if(kv.JumpToKey("ammo"))
	{
		for(int i; i<sizeof(class.Ammo); i++)
		{
			IntToString(i, num, sizeof(num));
			class.Ammo[i] = kv.GetNum(num, defaul.Ammo[i]);
		}
		kv.GoBack();
	}
	else
	{
		class.Ammo = defaul.Ammo;
	}

	if(kv.JumpToKey("maxammo"))
	{
		for(int i; i<sizeof(class.MaxAmmo); i++)
		{
			IntToString(i, num, sizeof(num));
			class.MaxAmmo[i] = kv.GetNum(num, defaul.MaxAmmo[i]);
		}
		kv.GoBack();
	}
	else
	{
		class.MaxAmmo = defaul.MaxAmmo;
	}

	if(kv.JumpToKey("items"))
	{
		for(int i; i<sizeof(class.Items); i++)
		{
			IntToString(i+1, num, sizeof(num));
			class.Items[i] = kv.GetNum(num, defaul.Items[i]);
		}
		kv.GoBack();
	}
	else
	{
		class.Items = defaul.Items;
	}

	if(kv.JumpToKey("precache"))
	{
		for(int i=1; ; i++)
		{
			IntToString(i, num, sizeof(num));
			kv.GetString(num, class.Model, sizeof(class.Model));
			if(!class.Model[0])
				break;

			if(!FileExists(class.Model, true))
			{
				LogError("[Config] '%s' has missing file '%s' in 'precache'", class.Name, class.Model);
				continue;
			}

			PrecacheModel(class.Model, true);
		}
		kv.GoBack();
	}

	if(kv.JumpToKey("precache_sound"))
	{
		for(int i=1; ; i++)
		{
			IntToString(i, num, sizeof(num));
			kv.GetString(num, class.Model, sizeof(class.Model));
			if(!class.Model[0])
				break;

			PrecacheSound(class.Model, true);
		}
		kv.GoBack();
	}

	if(kv.JumpToKey("downloads"))
	{
		int table = FindStringTable("downloadables");
		bool save = LockStringTables(false);
		for(int i=1; ; i++)
		{
			IntToString(i, num, sizeof(num));
			kv.GetString(num, class.Model, sizeof(class.Model));
			if(!class.Model[0])
				break;

			if(!FileExists(class.Model, true))
			{
				LogError("[Config] '%s' has missing file '%s' in 'downloads'", class.Name, class.Model);
				continue;
			}

			AddToStringTable(table, class.Model);
		}
		LockStringTables(save);
		kv.GoBack();
	}

	kv.GetString("modelalt", class.Model, sizeof(class.Model));
	class.ModelAlt = class.Model[0] ? PrecacheModel(class.Model, true) : defaul.ModelAlt;

	kv.GetString("model", class.Model, sizeof(class.Model), defaul.Model);
	class.ModelIndex = class.Model[0] ? PrecacheModel(class.Model, true) : defaul.ModelIndex;
}

bool Classes_GetByIndex(int index, ClassEnum class)
{
	if(index<0 || index>=Classes.Length)
		return false;

	Classes.GetArray(index, class);
	return true;
}

int Classes_GetByName(const char[] name, ClassEnum class=0)
{
	int length = Classes.Length;
	for(int i; i<length; i++)
	{
		Classes.GetArray(i, class);
		if(StrEqual(name, class.Name, false))
			return i;
	}
	return -1;
}

void Classes_PlayerSpawn(int client)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class))
	{
		Client[client].Colors = class.Color4;
		for(int i; i<3; i++)
		{
			if(Client[client].ColorBlind[i] >= 0)
				Client[client].Colors[i] = Client[client].ColorBlind[i];
		}

		bool result;
		if(class.OnSpawn != INVALID_FUNCTION)
		{
			Call_StartFunction(null, class.OnSpawn);
			Call_PushCell(client);
			Call_Finish(result);
		}

		if(!result)
		{
			// Teleport to spawn point
			ChangeClientTeamEx(client, class.Team);
			Classes_SpawnPoint(client, Client[client].Class);

			// Show class info
			Client[client].HudIn = GetEngineTime()+9.9;
			CreateTimer(2.0, ShowClassInfoTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

			// Model stuff
			SetVariantString(class.Model);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", class.ModelIndex, _, 0);
			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", class.ModelAlt, _, 3);
			TF2_CreateGlow(client, class.Model);

			// Reset health
			SetEntityHealth(client, class.Health);

			// Weapon stuff
			for(int i; i<sizeof(class.Items); i++)
			{
				if(!class.Items[i])
					break;

				Items_CreateWeapon(client, class.Items[i], !i, true);
			}

			// Ammo stuff
			for(int i; i<Ammo_MAX; i++)
			{
				SetEntProp(client, Prop_Data, "m_iAmmo", class.Ammo[i], _, i);
			}

			// Other stuff
			TF2_AddCondition(client, TFCond_NoHealingDamageBuff, 1.0);
			TF2Attrib_SetByDefIndex(client, 49, 1.0);
		}
	}
}

void Classes_SpawnPoint(int client, int index)
{
	ClassEnum class;
	if(Classes_GetByIndex(index, class))
	{
		ArrayList list = new ArrayList();
		int entity = -1;
		static char name[32];
		while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(!StrContains(name, class.Spawn, false))
				list.Push(entity);
		}

		int length = list.Length;
		if(!length && !class.Human)	// Temp backwards compability
		{
			entity = -1;
			while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
			{
				GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
				if(StrEqual(name, "scp_spawn_p", false))
					list.Push(entity);
			}

			length = list.Length;
			if(!length)
			{
				Client[client].InvisFor = GetEngineTime()+30.0;

				DataPack pack;
				CreateDataTimer(1.0, Timer_Stun, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(GetClientUserId(client));
				pack.WriteFloat(29.0);
				pack.WriteFloat(1.0);
				pack.WriteCell(TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT);
				delete list;
				return;
			}
		}

		if(!class.Human)	// Remove this soonTM
		{
			Client[client].InvisFor = GetEngineTime()+15.0;

			DataPack pack;
			CreateDataTimer(1.0, Timer_Stun, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(client));
			pack.WriteFloat(14.0);
			pack.WriteFloat(1.0);
			pack.WriteCell(TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT);
		}

		if(length)
		{
			static float pos[3];
			GetEntPropVector(list.Get(GetRandomInt(0, length-1)), Prop_Send, "m_vecOrigin", pos);
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
		}

		delete list;
	}
}

int Classes_GetMaxAmmo(int client, int type)
{
	if(type>=0 && type<Ammo_MAX)
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class))
		{
			int ammo = class.MaxAmmo[type];
			if(ammo > 0)
				return ammo;
		}
	}
	return 0;
}

int Classes_GetMaxHealth(int client)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class))
		return 125;

	int health = class.Health;
	if(class.OnMaxHealth != INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnMaxHealth);
		Call_PushCell(client);
		Call_PushCellRef(health);
		Call_Finish();
	}
	return health;
}

stock bool IsSCP(int client)
{
	ClassEnum class;
	Classes_GetByIndex(Client[client].Class, class);
	return !class.Human;
}

Action Classes_OnAnimation(int client, PlayerAnimEvent_t &anim, int &data)
{
	Action result = Plugin_Continue;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnAnimation!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnAnimation);
		Call_PushCell(client);
		Call_PushCellRef(anim);
		Call_PushCellRef(data);
		Call_Finish(result);
	}
	return result;
}

void Classes_OnButton(int client, int button)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnButton==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnButton);
	Call_PushCell(client);
	Call_PushCell(button);
	Call_Finish();
}

void Classes_OnCondAdded(int client, TFCond cond)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnCondAdded==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnCondAdded);
	Call_PushCell(client);
	Call_PushCell(cond);
	Call_Finish();
}

void Classes_OnCondRemoved(int client, TFCond cond)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnCondRemoved==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnCondRemoved);
	Call_PushCell(client);
	Call_PushCell(cond);
	Call_Finish();
}

Action Classes_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result = Plugin_Continue;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnDealDamage!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnDealDamage);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_PushCellRef(inflictor);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_PushCellRef(weapon);
		Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
		Call_PushCell(damagecustom);
		Call_Finish(result);
	}
	return result;
}

bool Classes_OnDeath(int client, Event event)
{
	bool result;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnDeath!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnDeath);
		Call_PushCell(client);
		Call_PushCell(event);
		Call_Finish(result);
	}
	return result;
}

bool Classes_OnGlowPlayer(int client, int victim)
{
	bool result;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnGlowPlayer!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnGlowPlayer);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_Finish(result);
	}
	return result;
}

bool Classes_OnKeycard(int client, any access, int &value)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnKeycard==INVALID_FUNCTION)
		return false;

	Call_StartFunction(null, class.OnKeycard);
	Call_PushCell(client);
	Call_PushCell(access);
	Call_Finish(value);
	return true;
}

void Classes_OnKill(int client, int victim)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnKill==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnKill);
	Call_PushCell(client);
	Call_PushCell(victim);
	Call_Finish();
}

bool Classes_OnPickup(int client, int entity)
{
	bool result;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnPickup!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnPickup);
		Call_PushCell(client);
		Call_PushCell(entity);
		Call_Finish(result);
	}
	return result;
}

bool Classes_OnSeePlayer(int client, int victim)
{
	bool result = true;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnSeePlayer!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnSeePlayer);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_Finish(result);
	}
	return result;
}

bool Classes_OnSound(Action &result, int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnSound==INVALID_FUNCTION)
		return false;

	Call_StartFunction(null, class.OnSound);
	Call_PushCell(client);
	Call_PushStringEx(sample, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCellRef(channel);
	Call_PushFloatRef(volume);
	Call_PushCellRef(level);
	Call_PushCellRef(pitch);
	Call_PushCellRef(flags);
	Call_PushStringEx(soundEntry, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCellRef(seed);
	Call_Finish(result);
	return true;
}

void Classes_OnSpeed(int client, float &speed)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnSpeed==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnSpeed);
	Call_PushCell(client);
	Call_PushFloatRef(speed);
	Call_Finish();
}

Action Classes_OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result = Plugin_Continue;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnTakeDamage!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnTakeDamage);
		Call_PushCell(client);
		Call_PushCellRef(attacker);
		Call_PushCellRef(inflictor);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_PushCellRef(weapon);
		Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
		Call_PushCell(damagecustom);
		Call_Finish(result);
		PrintToChat(client, "%d", result);
	}
	return result;
}

float Classes_OnTheme(int client, char path[PLATFORM_MAX_PATH])
{
	float result;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnTheme!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnTheme);
		Call_PushCell(client);
		Call_PushStringEx(path, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_Finish(result);
	}
	return result;
}

void Classes_OnWeaponSwitch(int client, int entity)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnWeaponSwitch==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnWeaponSwitch);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_Finish();
}

public bool Classes_GhostSpawn(int client)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class))
		return false;

	TF2_AddCondition(client, TFCond_HalloweenGhostMode);

	SetVariantString(class.Model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);

	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", (Client[client].IsVip ? class.ModelAlt : class.ModelIndex), _, 0);
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", (Client[client].IsVip ? class.ModelAlt : class.ModelIndex), _, 3);

	if(IsFakeClient(client))
		TeleportEntity(client, TRIPLE_D, NULL_VECTOR, NULL_VECTOR);

	return true;
}

public bool Classes_VipSpawn(int client)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class))
	{
		switch(class.Group)
		{
			case 0:
				Gamemode_AddValue("ptotal");

			case 2:
				Gamemode_AddValue("dtotal");

			default:
				Gamemode_AddValue("stotal");
		}
	}
	return false;
}

public void Classes_MoveToSpec(int client, Event event)
{
	int index = Classes_GetByName("spec");
	if(index == -1)
		index = 0;

	Client[client].Class = index;
}

public bool Classes_DeathScp(int client, Event event)
{
	ClassEnum clientClass;
	Classes_GetByIndex(Client[client].Class, clientClass);

	Gamemode_AddValue("pkill");

	ClassEnum attackerClass;
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker!=client && IsValidClient(attacker) && Classes_GetByIndex(Client[attacker].Class, attackerClass))
	{
		int weapon = event.GetInt("weaponid");
		if(weapon>MaxClients && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==594)
			GiveAchievement(Achievement_KillSCPMirco, attacker);

		if(StrEqual(attackerClass.Name, "sci"))
			GiveAchievement(Achievement_KillSCPSci, attacker);

		Config_DoReaction(attacker, "killscp");

		ClassEnum assisterClass;
		int assister = GetClientOfUserId(event.GetInt("assister"));
		if(assister!=client && IsValidClient(assister) && Classes_GetByIndex(Client[assister].Class, assisterClass))
		{
			if(StrEqual(assisterClass.Name, "sci"))
				GiveAchievement(Achievement_KillSCPSci, assister);

			Config_DoReaction(assister, "killscp");

			CPrintToChatAll("%s%t", PREFIX, "scp_killed_duo", clientClass.Color, clientClass.Display, attackerClass.Color, attackerClass.Display, assisterClass.Color, assisterClass.Display);
		}
		else
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, attackerClass.Color, attackerClass.Display);
		}
	}
	else
	{
		int damage = event.GetInt("damagebits");
		if(damage & DMG_SHOCK)
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, "gray", "tesla_gate");
		}
		else if(damage & DMG_NERVEGAS)
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, "gray", "femur_breaker");
		}
		else if(damage & DMG_BLAST)
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, "gray", "alpha_warhead");
		}
		else
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, "black", "redacted");
		}
	}

	Classes_MoveToSpec(client, event);
	return true;
}

public void Classes_KillScp(int client, int victim)
{
	int wep = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
	if(wep>MaxClients && GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex")==594)
		GiveAchievement(Achievement_KillMirco, client);
}

public void Classes_KillDBoi(int client, int victim)
{
	if(Classes_GetByName("sci")==Client[victim].Class && Items_OnKeycard(victim, Access_Main))
		GiveAchievement(Achievement_KillSCPSci, client);
}

public void Classes_KillMtf(int client, int victim)
{
	if(Classes_GetByName("dboi") == Client[victim].Class)
		GiveAchievement(Achievement_KillDClass, client);
}

public Action Classes_TakeDamageHuman(int client, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker<1 || attacker>MaxClients)
	{
		if(damagetype & DMG_CRUSH)
		{
			float engineTime = GetEngineTime();
			static float delay[MAXTF2PLAYERS];
			if(delay[client] > engineTime)
				return Plugin_Handled;

			delay[client] = engineTime+0.05;
		}
		else if(damagetype & DMG_FALL)
		{
			damage *= 5.0;
			return Plugin_Changed;
		}
	}
	else if(!CvarFriendlyFire.BoolValue)
	{
		if(Client[client].Disarmer && Client[client].Disarmer!=attacker && IsFriendly(Client[Client[client].Disarmer].Class, Client[attacker].Class))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Classes_TakeDamageScp(int client, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!(damagetype & DMG_FALL))
		return Plugin_Continue;

	damage *= 0.02;
	return Plugin_Changed;
}

public void Classes_CondDBoi(int client, TFCond cond)
{
	if(cond==TFCond_TeleportedGlow && Client[client].IgnoreTeleFor<GetEngineTime())
	{
		int index;
		if(Client[client].Disarmer)
		{
			Gamemode_AddValue("dcapture");
			index = Classes_GetByName("mtf1");
		}
		else
		{
			Gamemode_AddValue("descape");
			GiveAchievement(Achievement_EscapeDClass, client);
			index = Classes_GetByName("chaos");
		}

		if(index == -1)
			index = 0;

		Items_DropAllItems(client);
		Forward_OnEscape(client, Client[client].Disarmer);
		Client[client].Class = index;
		TF2_RespawnPlayer(client);
		Gamemode_CheckRound();
	}
}

public void Classes_CondSci(int client, TFCond cond)
{
	if(cond==TFCond_TeleportedGlow && Client[client].IgnoreTeleFor<GetEngineTime())
	{
		int index;
		if(Client[client].Disarmer)
		{
			Gamemode_AddValue("scapture");
			index = Classes_GetByName("chaos");
		}
		else
		{
			Gamemode_AddValue("sescape");
			GiveAchievement(Achievement_EscapeDClass, client);
			index = Classes_GetByName("mtfs");
		}

		if(index == -1)
			index = 0;

		Items_DropAllItems(client);
		Forward_OnEscape(client, Client[client].Disarmer);
		Client[client].Class = index;
		TF2_RespawnPlayer(client);
		Gamemode_CheckRound();
	}
}

public bool Classes_PickupStandard(int client, int entity)
{
	char buffer[64];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	if(StrEqual(buffer, "func_button"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_trigger", false))
		{
			AcceptEntityInput(entity, "Press", client, client);
			return true;
		}
	}
	else
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class))
		{
			if(StrEqual(buffer, "tf_dropped_weapon"))
			{
				if(class.Human && Items_Pickup(client, GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), entity))
					AcceptEntityInput(entity, "Kill");

				return true;
			}
			else if(!StrContains(buffer, "prop_dynamic"))
			{
				GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
				if(class.Human)
				{
					if(!StrContains(buffer, "scp_keycard_", false))	// Backwards compatibility
					{
						char buffers[3][4];
						ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
						if(Items_Pickup(client, StringToInt(buffers[2])+30000))
							AcceptEntityInput(entity, "KillHierarchy");

						return true;
					}
					else if(!StrContains(buffer, "scp_healthkit", false))	// Backwards compatibility
					{
						char buffers[3][4];
						ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
						int value = StringToInt(buffers[2]);
						if(value > 3)
						{
							value = 30017;
						}
						else
						{
							value += 30012;
						}

						if(Items_Pickup(client, value))
							AcceptEntityInput(entity, "KillHierarchy");

						return true;
					}
					else if(!StrContains(buffer, "scp_weapon", false))	// Backwards compatibility
					{
						char buffers[3][4];
						ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
						int index = StringToInt(buffers[2]);
						if(!index)
							index = 773;

						if(Items_Pickup(client, index))
							AcceptEntityInput(entity, "KillHierarchy");

						return true;
					}
					else if(!StrContains(buffer, "scp_item_", false))
					{
						AcceptEntityInput(entity, "FireUser1", client, client);

						char buffers[3][6];
						ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
						if(Items_Pickup(client, StringToInt(buffers[2])))
							AcceptEntityInput(entity, "KillHierarchy");

						return true;
					}
				}

				if(!StrContains(buffer, "scp_trigger", false))
				{
					switch(class.Group)
					{
						case 0:
							AcceptEntityInput(entity, "FireUser1", client, client);

						case 1:
							AcceptEntityInput(entity, "FireUser2", client, client);

						case 2:
							AcceptEntityInput(entity, "FireUser3", client, client);

						default:
							AcceptEntityInput(entity, "FireUser4", client, client);
					}
					return true;
				}
			}
		}
	}
	return false;
}

public float Classes_GhostTheme(int client, char path[PLATFORM_MAX_PATH])
{
	strcopy(path, PLATFORM_MAX_PATH, "#scp_sf/music/unexplainedbehaviors.mp3");
	return 49.0;
}