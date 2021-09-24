enum struct WeaponEnum
{
	char Display[16];

	// Weapon Stats
	char Classname[36];
	char Attributes[256];
	int Index;
	bool Strip;

	// SCP-914
	char VeryFine[32];
	char Fine[32];
	char OneToOne[32];
	char Coarse[32];
	char Rough[32];

	TFClassType Class;
	int Ammo;
	int Clip;
	int Bullet;
	int Type;
	bool Hide;
	bool Hidden;

	char Model[PLATFORM_MAX_PATH];
	int Viewmodel;
	int Skin;
	int Rarity;

	Function OnAmmo;		// void(int client, int type, int &ammo)
	Function OnButton;	// Action(int client, int weapon, int &buttons, int &holding)
	Function OnCard;		// int(int client, AccessEnum access)
	Function OnCreate;	// void(int client, int weapon)
	Function OnDamage;	// Action(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	Function OnDrop;		// bool(int client, int weapon, bool swap)
	Function OnItem;		// void(int client, int type, int &amount)
	Function OnRadio;		// int(int client, int weapon)
	Function OnSpeed;		// void(int client, float &speed)
	Function OnSprint;	// void(int client, float &drain)
}

static ArrayList Weapons;

void Items_Setup(KeyValues main, KeyValues map)
{
	if(Weapons != INVALID_HANDLE)
		delete Weapons;

	Weapons = new ArrayList(sizeof(WeaponEnum));

	main.Rewind();
	KeyValues kv = main;
	if(map)	// Check if the map has it's own gamemode config
	{
		map.Rewind();
		if(map.JumpToKey("Weapons"))
			kv = map;
	}

	char buffer[16];
	WeaponEnum weapon;
	kv.GotoFirstSubKey();
	do
	{
		kv.GetSectionName(buffer, sizeof(buffer));
		weapon.Index = StringToInt(buffer);

		Format(weapon.Display, sizeof(weapon.Display), "weapon_%d", weapon.Index);
		if(!TranslationPhraseExists(weapon.Display))
			strcopy(weapon.Display, sizeof(weapon.Display), "weapon_0");

		weapon.Ammo = kv.GetNum("ammo", -1);
		weapon.Clip = kv.GetNum("clip", -1);
		weapon.Bullet = kv.GetNum("bullet");
		weapon.Type = kv.GetNum("type");
		weapon.Skin = kv.GetNum("skin", -1);
		weapon.Rarity = kv.GetNum("rarity", -1);

		weapon.Strip = view_as<bool>(kv.GetNum("strip"));
		weapon.Hide = view_as<bool>(kv.GetNum("hide"));
		weapon.Hidden = view_as<bool>(kv.GetNum("hidden"));

		weapon.Class = KvGetClass(kv, "class");

		weapon.OnAmmo = KvGetFunction(kv, "func_ammo");
		weapon.OnButton = KvGetFunction(kv, "func_button");
		weapon.OnCard = KvGetFunction(kv, "func_card");
		weapon.OnCreate = KvGetFunction(kv, "func_create");
		weapon.OnDamage = KvGetFunction(kv, "func_damage");
		weapon.OnDrop = KvGetFunction(kv, "func_drop");
		weapon.OnItem = KvGetFunction(kv, "func_item");
		weapon.OnRadio = KvGetFunction(kv, "func_radio");
		weapon.OnSpeed = KvGetFunction(kv, "func_speed");
		weapon.OnSprint = KvGetFunction(kv, "func_sprint");

		kv.GetString("classname", weapon.Classname, sizeof(weapon.Classname));
		kv.GetString("attributes", weapon.Attributes, sizeof(weapon.Attributes));

		kv.GetString("viewmodel", weapon.Model, sizeof(weapon.Model));
		weapon.Viewmodel = weapon.Model[0] ? PrecacheModel(weapon.Model, true) : 0;

		kv.GetString("model", weapon.Model, sizeof(weapon.Model));
		if(weapon.Model[0])
			PrecacheModel(weapon.Model, true);

		kv.GetString("914++", weapon.VeryFine, sizeof(weapon.VeryFine));
		kv.GetString("914+", weapon.Fine, sizeof(weapon.Fine));
		kv.GetString("914", weapon.OneToOne, sizeof(weapon.OneToOne));
		kv.GetString("914-", weapon.Coarse, sizeof(weapon.Coarse));
		kv.GetString("914--", weapon.Rough, sizeof(weapon.Rough));

		Weapons.PushArray(weapon);
	} while(kv.GotoNextKey());
}

void Items_RoundStart()
{
	int players;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
			players++;
	}

	if(players < 8)
		players = 8;

	char buffer[16];
	int entity = -1;
	while((entity=FindEntityByClassname(entity, "prop_dynamic*")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_rand_", false))
		{
			if(GetRandomInt(1, 32) > players)
				RemoveEntity(entity);
		}
	}
}

bool Items_GetWeaponByIndex(int index, WeaponEnum weapon)
{
	int length = Weapons.Length;
	for(int i; i<length; i++)
	{
		Weapons.GetArray(i, weapon);
		if(weapon.Index == index)
			return true;
	}
	return false;
}

bool Items_GetWeaponByModel(const char[] model, WeaponEnum weapon)
{
	int length = Weapons.Length;
	for(int i; i<length; i++)
	{
		Weapons.GetArray(i, weapon);
		if(StrEqual(model, weapon.Model, false))
			return true;
	}
	return false;
}

bool Items_GetRandomWeapon(int rarity, WeaponEnum weapon)
{
	ArrayList list = new ArrayList();
	int length = Weapons.Length;
	for(int i; i<length; i++)
	{
		Weapons.GetArray(i, weapon);
		if(weapon.Rarity == rarity)
			list.Push(i);
	}

	length = list.Length;
	if(length < 1)
	{
		delete list;
		return false;
	}

	Weapons.GetArray(list.Get(GetRandomInt(0, length-1)), weapon);
	delete list;
	return true;
}

int Items_Iterator(int client, int &index, bool all=false)
{
	int max = GetMaxWeapons(client);
	WeaponEnum weapon;
	for(; index<max; index++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", index);
		if(entity<=MaxClients || !IsValidEntity(entity))
			continue;

		if(!all && (!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.Hidden))
			continue;

		index++;
		return entity;
	}
	return -1;
}

ArrayList Items_ArrayList(int client, int slot=-1, bool all=false)
{
	ArrayList list = new ArrayList();
	int max = GetMaxWeapons(client);
	WeaponEnum weapon;
	for(int i; i<max; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity<=MaxClients || !IsValidEntity(entity))
			continue;

		if(slot != -1)
		{
			static char buffer[36];
			if(!GetEntityClassname(entity, buffer, sizeof(buffer)) || TF2_GetClassnameSlot(buffer)!=slot)
				continue;
		}

		if(!all && (!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.Hidden))
			continue;

		list.Push(entity);
	}

	list.Sort(Sort_Ascending, Sort_Integer);
	return list;
}

int Items_CreateWeapon(int client, int index, bool equip=true, bool clip=false, bool ammo=false, int ground=-1)
{
	int entity = index;
	switch(Forward_OnWeaponPre(client, ground, entity))
	{
		case Plugin_Changed:
		{
			index = entity;
		}
		case Plugin_Handled, Plugin_Stop:
		{
			return -1;
		}
	}

	entity = -1;
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
	{
		static char buffers[40][16];
		int count = ExplodeString(weapon.Attributes, " ; ", buffers, sizeof(buffers), sizeof(buffers));

		if(count % 2)
			count--;

		int i;
		bool wearable = view_as<bool>(StrContains(weapon.Classname, "tf_weap", false));
		if(wearable)
		{
			entity = CreateEntityByName(weapon.Classname);
			if(IsValidEntity(entity))
			{
				SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
				SetEntProp(entity, Prop_Send, "m_bInitialized", true);
				SetEntProp(entity, Prop_Send, "m_iEntityQuality", 6);
				SetEntProp(entity, Prop_Send, "m_iEntityLevel", 101);

				DispatchSpawn(entity);

				SDKCall_EquipWearable(client, entity);
			}
			else
			{
				LogError("[Config] Invalid classname '%s' for index '%d'", weapon.Classname, index);
			}
		}
		else
		{
			Handle item;
			if(weapon.Strip)
			{
				item = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
			}
			else
			{
				item = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
			}

			if(item)
			{
				TFClassType class = weapon.Class;
				if(class == TFClass_Unknown)
					class = Client[client].CurrentClass;

				if(class != TFClass_Unknown)
					TF2_SetPlayerClass(client, class, false, false);

				TF2Items_SetClassname(item, weapon.Classname);

				TF2Items_SetItemIndex(item, weapon.Index);
				TF2Items_SetLevel(item, 101);
				TF2Items_SetQuality(item, 6);

				if(count > 0)
				{
					TF2Items_SetNumAttributes(item, count/2);
					int a;
					for(; i<count && i<32; i+=2)
					{
						int attrib = StringToInt(buffers[i]);
						if(!attrib)
						{
							LogError("[Config] Bad weapon attribute passed for index %d: %s ; %s", index, buffers[i], buffers[i+1]);
							continue;
						}

						TF2Items_SetAttribute(item, a++, attrib, StringToFloat(buffers[i+1]));
					}
				}
				else
				{
					TF2Items_SetNumAttributes(item, 0);
				}

				entity = TF2Items_GiveNamedItem(client, item);
				delete item;
			}
		}

		if(entity > MaxClients)
		{
			if(!wearable)
				EquipPlayerWeapon(client, entity);

			while(i < count)
			{
				int attrib = StringToInt(buffers[i]);
				if(attrib)
				{
					TF2Attrib_SetByDefIndex(entity, attrib, StringToFloat(buffers[i+1]));
				}
				else
				{
					LogError("[Config] Bad weapon attribute passed for index %d: %s ; %s", index, buffers[i], buffers[i+1]);
				}
				i += 2;
			}

			ApplyStrangeRank(entity, GetRandomInt(0, 20));

			if(weapon.Hide)
			{
				SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 0);

				if(!wearable)
				{
					SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
					SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
					SetEntPropFloat(entity, Prop_Send, "m_flNextSecondaryAttack", FAR_FUTURE);
				}
			}
			else
			{
				SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
				if(weapon.Model[0])
				{
					int precache = PrecacheModel(weapon.Model);
					for(i=0; i<4; i++)
					{
						SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", precache, _, i);
					}
				}
			}

			if(!wearable)
			{
				if(ground > MaxClients)
				{
					i = GetEntProp(entity, Prop_Send, "m_iAccountID");
				}
				else
				{
					i = GetSteamAccountID(client, false);
				}
				SetEntProp(entity, Prop_Send, "m_iAccountID", i);

				if(weapon.Bullet>=0 && weapon.Bullet<AMMO_MAX)
				{
					SetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType", weapon.Bullet);
				}
				else
				{
					weapon.Bullet = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
				}

				if(ground > MaxClients)
				{
					// Save our current ammo
					int ammos[AMMO_MAX];
					for(i=1; i<AMMO_MAX; i++)
					{
						ammos[i] = GetAmmo(client, i);
						SetAmmo(client, 0, i);
					}

					// Get the new weapon's ammo
					SDKCall_InitPickup(ground, client, entity);

					// See where the ammo was sent to, add to our current ammo count
					for(i=0; i<AMMO_MAX; i++)
					{
						count = GetEntProp(client, Prop_Data, "m_iAmmo", _, i);
						if(!count)
							continue;

						if(count < 0)	// Guess we give a new set of ammo
							count = weapon.Ammo;

						ammos[weapon.Bullet] += count;

						count = Classes_GetMaxAmmo(client, weapon.Bullet);
						Items_Ammo(client, weapon.Bullet, count);
						if(ammos[weapon.Bullet] > count)
							ammos[weapon.Bullet] = count;

						break;
					}

					// Set our ammo back
					for(i=0; i<AMMO_MAX; i++)
					{
						if(ammos[i])
							SetAmmo(client, ammos[i], i);
					}
				}
				else
				{
					if(clip && weapon.Clip>=0)
						SetEntProp(entity, Prop_Data, "m_iClip1", weapon.Clip);

					if(ammo && weapon.Ammo>0 && weapon.Bullet>0)
					{
						count = weapon.Ammo+GetAmmo(client, weapon.Bullet);

						i = Classes_GetMaxAmmo(client, weapon.Bullet);
						Items_Ammo(client, weapon.Bullet, i);
						if(count > i)
							count = i;

						SetAmmo(client, count, weapon.Bullet);
					}
				}
			}

			if(weapon.OnCreate != INVALID_FUNCTION)
			{
				Call_StartFunction(null, weapon.OnCreate);
				Call_PushCell(client);
				Call_PushCell(entity);
				Call_Finish();
			}

			if(!wearable && equip)
			{
				SetActiveWeapon(client, entity);
				SZF_DropItem(client);
			}

			Items_ShowItemMenu(client);
			Forward_OnWeapon(client, entity);
		}
	}
	return entity;
}

void Items_SwapWeapons(int client, int wep1, int wep2)
{
	int slot1 = -1;
	int slot2 = -1;
	int max = GetMaxWeapons(client);
	for(int i; i<max; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity == wep1)
		{
			slot1 = i;
			if(slot2 == -1)
				continue;
		}
		else if(entity == wep2)
		{
			slot2 = i;
			if(slot1 == -1)
				continue;
		}
		else
		{
			continue;
		}

		SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", wep1, slot2);
		SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", wep2, slot1);
		break;
	}
}

void Items_SwitchItem(int client, int holding)
{
	int slot = 2;
	static char buffer[36];
	if(holding>MaxClients && GetEntityClassname(holding, buffer, sizeof(buffer)))
	{
		slot = TF2_GetClassnameSlot(buffer);
		ArrayList list = Items_ArrayList(client, slot);

		bool found;
		int length = list.Length;
		if(length > 1)
		{
			for(int i; i<length; i++)
			{
				if(list.Get(i) != holding)
					continue;

				for(int a=1; a<length; a++)
				{
					i++;
					if(i >= length)
						i = 0;

					int entity = list.Get(i);
					Items_SwapWeapons(client, entity, holding);
					SetActiveWeapon(client, entity);
					SZF_DropItem(client);
					Items_ShowItemMenu(client);
					found = true;
					break;
				}
				break;
			}
		}
		delete list;

		if(found)
			return;
	}

	FakeClientCommand(client, "use tf_weapon_fists");
	Items_ShowItemMenu(client);
}

bool Items_CanGiveItem(int client, int type, bool &full=false)
{
	int maxall = Classes_GetMaxItems(client, 0);
	int maxtypes = Classes_GetMaxItems(client, type);
	int i, entity, all, types;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i)) != -1)
	{
		all++;
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
			continue;

		if(weapon.OnItem != INVALID_FUNCTION)
		{
			Call_StartFunction(null, weapon.OnItem);
			Call_PushCell(client);
			Call_PushCell(0);
			Call_PushCellRef(maxall);
			Call_Finish();
		}

		if(type<1 || type>=ITEMS_MAX)
			continue;

		if(weapon.OnItem != INVALID_FUNCTION)
		{
			Call_StartFunction(null, weapon.OnItem);
			Call_PushCell(client);
			Call_PushCell(type);
			Call_PushCellRef(maxtypes);
			Call_Finish();
		}

		if(weapon.Type != type)
			continue;

		types++;
	}

	if(all >= maxall)
	{
		full = true;
		return false;
	}

	if(types >= maxtypes)
	{
		full = false;
		return false;
	}
	return true;
}

bool Items_DropItem(int client, int helditem, const float origin[3], const float angles[3], bool swap=true)
{
	static char buffer[PLATFORM_MAX_PATH];
	GetEntityNetClass(helditem, buffer, sizeof(buffer));
	int offset = FindSendPropInfo(buffer, "m_Item");
	if(offset < 0)
	{
		LogError("Failed to find m_Item on: %s", buffer);
		return false;
	}

	WeaponEnum weapon;
	if(!Items_GetWeaponByIndex(GetEntProp(helditem, Prop_Send, "m_iItemDefinitionIndex"), weapon))
		return false;

	if(weapon.OnDrop != INVALID_FUNCTION)
	{
		Call_StartFunction(null, weapon.OnDrop);
		Call_PushCell(client);
		Call_PushCell(helditem);
		Call_PushCellRef(swap);

		bool canDrop;
		Call_Finish(canDrop);
		if(!canDrop)
			return false;
	}

	if(!weapon.Model[0])
	{
		int index = GetEntProp(helditem, Prop_Send, HasEntProp(helditem, Prop_Send, "m_iWorldModelIndex") ? "m_iWorldModelIndex" : "m_nModelIndex");
		if(index < 1)
			return false;

		ModelIndexToString(index, weapon.Model, sizeof(weapon.Model));
	}

	//Dropped weapon doesn't like being spawn high in air, create on ground then teleport back after DispatchSpawn
	TR_TraceRayFilter(origin, view_as<float>({90.0, 0.0, 0.0}), MASK_SOLID, RayType_Infinite, Trace_OnlyHitWorld);
	if(!TR_DidHit())	//Outside of map
		return false;

	static float spawn[3];
	TR_GetEndPosition(spawn);

	// If were swapping, don't drop any ammo with this weapon
	int ammo;
	int type = GetEntProp(helditem, Prop_Send, "m_iPrimaryAmmoType");
	if(swap)
	{
		if(type != -1)
		{
			ammo = GetAmmo(client, type);
			int clip = GetEntProp(helditem, Prop_Data, "m_iClip1");
			int max = Classes_GetMaxAmmo(client, type);
			Items_Ammo(client, type, max);

			if(ammo > max)
			{
				ammo = max;
			}
			else
			{
				while(clip>0 && ammo<max)
				{
					clip--;
					ammo++;
				}
			}

			SetEntProp(helditem, Prop_Data, "m_iClip1", clip);
			SetEntProp(client, Prop_Data, "m_iAmmo", 0, _, type);
		}
	}

	// CTFDroppedWeapon::Create deletes tf_dropped_weapon if there too many in map, pretend entity is marking for deletion so it doesnt actually get deleted
	ArrayList list = new ArrayList();
	int entity = MaxClients+1;
	while((entity=FindEntityByClassname(entity, "tf_dropped_weapon")) > MaxClients)
	{
		int flags = GetEntProp(entity, Prop_Data, "m_iEFlags");
		if(flags & EFL_KILLME)
			continue;

		SetEntProp(entity, Prop_Data, "m_iEFlags", flags|EFL_KILLME);
		list.Push(entity);
	}

	//Pass client as NULL, only used for deleting existing dropped weapon which we do not want to happen
	entity = SDKCall_CreateDroppedWeapon(-1, spawn, angles, weapon.Model, GetEntityAddress(helditem)+view_as<Address>(offset));

	offset = list.Length;
	for(int i; i<offset; i++)
	{
		int ent = list.Get(i);
		int flags = GetEntProp(ent, Prop_Data, "m_iEFlags");
		flags = flags &= ~EFL_KILLME;
		SetEntProp(ent, Prop_Data, "m_iEFlags", flags);
	}

	delete list;

	bool result;
	if(entity != INVALID_ENT_REFERENCE)
	{
		DispatchSpawn(entity);

		//Check if weapon is not marked for deletion after spawn, otherwise we may get bad physics model leading to a crash
		if(GetEntProp(entity, Prop_Data, "m_iEFlags") & EFL_KILLME)
		{
			LogError("Unable to create dropped weapon with model '%s'", weapon.Model);
		}
		else
		{
			SDKCall_InitDroppedWeapon(entity, client, helditem, swap, false);

			if(swap)
				Items_SwitchItem(client, helditem);

			TF2_RemoveItem(client, helditem);

			if(swap)
				Items_ShowItemMenu(client);

			if(weapon.Skin >= 0)
			{
				SetVariantInt(weapon.Skin);
				AcceptEntityInput(entity, "Skin");
			}

			TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
			result = true;
		}
	}

	if(type != -1)
		SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, type);

	return result;
}

void Items_DropAllItems(int client)
{
	static float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);

	int i, entity;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		Items_DropItem(client, entity, pos, ang, false);
	}
}

bool Items_Pickup(int client, int index, int entity=-1)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
	{
		bool full;
		if(Items_CanGiveItem(client, weapon.Type, full))
		{
			bool newWep = entity==-1;
			Items_CreateWeapon(client, index, true, newWep, newWep, entity);
			ClientCommand(client, "playgamesound AmmoPack.Touch");
			if(index == 30012)
			{
				GiveAchievement(Achievement_FindO5, client);
			}
			else if(weapon.Type==1 && Classes_GetByName("dboi")==Client[client].Class)
			{
				GiveAchievement(Achievement_FindGun, client);
			}
			return true;
		}

		ClientCommand(client, "playgamesound items/medshotno1.wav");

		BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
		if(bf)
		{
			char buffer[64];
			FormatEx(buffer, sizeof(buffer), "%T", full ? "inv_full" : "type_full", client);
			bf.WriteString(buffer);
			bf.WriteString("ico_notify_highfive");
			bf.WriteByte(0);
			EndMessage();
		}
	}
	return false;
}

void Items_ShowItemMenu(int client)
{
	int max = Classes_GetMaxItems(client, 0);
	Items_Items(client, 0, max);

	Menu menu = new Menu(Items_ShowItemMenuH);
	menu.SetTitle("Inventory            ");

	SetGlobalTransTarget(client);
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int fists = -1;
	int items;
	char buffer[64], num[16];
	ArrayList list = Items_ArrayList(client, _, true);
	int length = list.Length;
	WeaponEnum weapon;
	for(int i; i<length; i++)
	{
		int entity = list.Get(i);
		int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if(Items_GetWeaponByIndex(index, weapon))
		{
			if(weapon.OnItem != INVALID_FUNCTION)
			{
				Call_StartFunction(null, weapon.OnItem);
				Call_PushCell(client);
				Call_PushCell(0);
				Call_PushCellRef(max);
				Call_Finish();
			}

			if(weapon.Hidden)
			{
				max--;
				continue;
			}

			if(index == 5 && fists == -1)
			{
				// Special hardcoded exception for no-weapon fists
				fists = entity;
				continue;
			}

			IntToString(EntIndexToEntRef(entity), num, sizeof(num));
			FormatEx(buffer, sizeof(buffer), "%t", weapon.Display);
			menu.AddItem(num, buffer, active==entity ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
		else
		{
			IntToString(EntIndexToEntRef(entity), num, sizeof(num));
			FormatEx(buffer, sizeof(buffer), "%t", "weapon_0");
			menu.AddItem(num, buffer, active==entity ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}

		items++;
	}
	delete list;

	if(max > 1)
	{
		SetEntProp(client, Prop_Send, "m_bWearingSuit", false);

		if(fists != -1)
			max--;

		for(; items<max; items++)
		{
			menu.AddItem("-1", ""); 
		}

		if(fists != -1)
		{
			for(; items<9; items++)
			{
				menu.AddItem("-1", "", ITEMDRAW_SPACER);
			}

			IntToString(EntIndexToEntRef(fists), num, sizeof(num));
			FormatEx(buffer, sizeof(buffer), "%t", "weapon_5");
			menu.AddItem(num, buffer, active==fists ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}

		menu.Pagination = false;
		menu.OptionFlags |= MENUFLAG_NO_SOUND;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		delete menu;
		SetEntProp(client, Prop_Send, "m_bWearingSuit", true);
	}
}

public int Items_ShowItemMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(IsPlayerAlive(client))
			{
				char buffer[16];
				menu.GetItem(choice, buffer, sizeof(buffer));

				int entity = StringToInt(buffer);
				if(entity == -1)
				{
					int i;
					while((entity=Items_Iterator(client, i, true)) != -1)
					{
						if(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 5)
						{
							SetActiveWeapon(client, entity);
							break;
						}
					}
				}
				else
				{
					entity = EntRefToEntIndex(entity);
					if(entity > MaxClients)
					{
						SetActiveWeapon(client, entity);
						SZF_DropItem(client);
					}
				}

				Items_ShowItemMenu(client);
				ClientCommand(client, "playgamesound common/wpn_moveselect.wav");
			}
		}
	}
}

bool Items_IsHoldingWeapon(int client)
{
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(entity>MaxClients && IsValidEntity(entity) && HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
	{
		WeaponEnum weapon;
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || !weapon.Hide)
			return true;
	}
	return false;
}

int Items_OnKeycard(int client, any access)
{
	int value;
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(entity>MaxClients && IsValidEntity(entity))
	{
		WeaponEnum weapon;
		if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
		{
			if(weapon.OnCard != INVALID_FUNCTION)
			{
				Call_StartFunction(null, weapon.OnCard);
				Call_PushCell(client);
				Call_PushCell(access);
				Call_Finish(value);
			}
		}
	}
	return value;
}

Action Items_OnDamage(int victim, int attacker, int &inflictor, float &damage, int &damagetype, int &entity, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action action;
	if(IsValidEntity(entity) && entity>MaxClients && HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
	{
		WeaponEnum weapon;
		if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
		{
			if(weapon.OnDamage != INVALID_FUNCTION)
			{
				Call_StartFunction(null, weapon.OnDamage);
				Call_PushCell(attacker);
				Call_PushCell(victim);
				Call_PushCellRef(inflictor);
				Call_PushFloatRef(damage);
				Call_PushCellRef(damagetype);
				Call_PushCellRef(entity);
				Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
				Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
				Call_PushCell(damagecustom);
				Call_Finish(action);
			}
		}
	}
	return action;
}

bool Items_OnRunCmd(int client, int &buttons, int &holding)
{
	bool changed;
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(entity>MaxClients && IsValidEntity(entity))
	{
		WeaponEnum weapon;
		if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
		{
			if(weapon.OnButton != INVALID_FUNCTION)
			{
				Call_StartFunction(null, weapon.OnButton);
				Call_PushCell(client);
				Call_PushCell(entity);
				Call_PushCellRef(buttons);
				Call_PushCellRef(holding);
				Call_Finish(changed);
			}
		}
	}
	return changed;
}

bool Items_ShowItemDesc(int client, int entity)
{
	char buffer[16];
	FormatEx(buffer, sizeof(buffer), "info_%d", GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"));
	if(!TranslationPhraseExists(buffer))
		return false;

	PrintKeyHintText(client, "%t", buffer);
	return true;
}

float Items_Radio(int client)
{
	float distance = 1.0;
	int i, entity;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
			continue;

		if(weapon.OnRadio != INVALID_FUNCTION)
		{
			Call_StartFunction(null, weapon.OnRadio);
			Call_PushCell(client);
			Call_PushCell(entity);
			Call_PushFloatRef(distance);

			bool finished;
			Call_Finish(finished);
			if(finished)
				break;
		}
	}
	return distance;
}

void Items_Ammo(int client, int type, int &ammo)
{
	int i, entity;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.OnAmmo==INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, weapon.OnAmmo);
		Call_PushCell(client);
		Call_PushCell(type);
		Call_PushCellRef(ammo);
		Call_Finish();
	}
}

void Items_Items(int client, int type, int &amount)
{
	int i, entity;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.OnItem==INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, weapon.OnItem);
		Call_PushCell(client);
		Call_PushCell(type);
		Call_PushCellRef(amount);
		Call_Finish();
	}
}

void Items_Speed(int client, float &speed)
{
	int i, entity;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.OnSpeed==INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, weapon.OnSpeed);
		Call_PushCell(client);
		Call_PushFloatRef(speed);
		Call_Finish();
	}
}

void Items_Sprint(int client, float &drain)
{
	int i, entity;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.OnSprint==INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, weapon.OnSprint);
		Call_PushCell(client);
		Call_PushFloatRef(drain);
		Call_Finish();
	}
}

int Items_GetTranName(int index, char[] buffer, int length)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
		return strcopy(buffer, length, weapon.Display);

	return strcopy(buffer, length, "weapon_0");
}

int Items_GetItemsOfType(int client, int type)
{
	int count;
	int max = GetMaxWeapons(client);
	WeaponEnum weapon;
	for(int i; i<max; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity<=MaxClients || !IsValidEntity(entity))
			continue;

		if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) && weapon.Type==type)
			count++;
	}
	return count;
}

void RemoveAndSwitchItem(int client, int weapon)
{
	Items_SwitchItem(client, weapon);
	TF2_RemoveItem(client, weapon);
	Items_ShowItemMenu(client);
}

static void SpawnPlayerPickup(int client, const char[] classname, bool timed=false)
{
	int entity = CreateEntityByName(classname);
	if(entity > MaxClients)
	{
		static float pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] += 20.0;
		DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client), 4);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);

		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);

		if(timed)
			CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

static int GetMaxWeapons(int client)
{
	static int max;
	if(!max)
		max = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

	return max;
}

public bool Items_NoneDrop(int client, int weapon, bool &swap)
{
	return false;
}

public bool Items_DeleteDrop(int client, int weapon, bool &swap)
{
	if(swap)
		Items_SwitchItem(client, weapon);

	TF2_RemoveItem(client, weapon);
	return false;
}

public bool Items_PainKillerDrop(int client, int weapon, bool &swap)
{
	if(swap)
		Items_SwitchItem(client, weapon);

	TF2_RemoveItem(client, weapon);
	SpawnPlayerPickup(client, "item_healthkit_small");
	return false;
}

public bool Items_HealthKitDrop(int client, int weapon, bool &swap)
{
	if(swap)
		Items_SwitchItem(client, weapon);

	TF2_RemoveItem(client, weapon);
	SpawnPlayerPickup(client, "item_healthkit_medium");
	return false;
}

public bool Items_RadioDrop(int client, int weapon, bool &swap)
{
	if(swap)
		Items_SwitchItem(client, weapon);

	swap = false;
	return true;
}

public bool Items_ArmorDrop(int client, int weapon, bool &swap)
{
	int ammo[AMMO_MAX];
	Classes_GetMaxAmmoList(client, ammo);

	for(int i; i<AMMO_MAX; i++)
	{
		if(ammo[i] && GetEntProp(client, Prop_Data, "m_iAmmo", _, i)>ammo[i])
		{
			SetEntProp(client, Prop_Data, "m_iAmmo", ammo[i], _, i);
		}
	}
	return true;
}

public Action Items_DisarmerHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapo, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsSCP(victim) && !IsFriendly(Client[victim].Class, Client[client].Class))
	{
		bool cancel;
		if(!Client[victim].Disarmer)
		{
			cancel = Items_IsHoldingWeapon(victim);
			if(!cancel)
			{
				TF2_AddCondition(victim, TFCond_PasstimePenaltyDebuff);
				BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", victim));
				if(bf)
				{
					char buffer[64];
					FormatEx(buffer, sizeof(buffer), "%T", "disarmed", client);
					bf.WriteString(buffer);
					bf.WriteString("ico_notify_flag_moving_alt");
					bf.WriteByte(view_as<int>(TFTeam_Red));
					EndMessage();
				}

				SZF_DropItem(victim);
				Items_DropAllItems(victim);
				for(int i; i<AMMO_MAX; i++)
				{
					SetEntProp(victim, Prop_Data, "m_iAmmo", 0, _, i);
				}
				FakeClientCommand(victim, "use tf_weapon_fists");
				Items_ShowItemMenu(client);

				ClassEnum class;
				if(Classes_GetByIndex(Client[victim].Class, class) && class.Group==2 && !class.Vip)
					GiveAchievement(Achievement_DisarmMTF, client);

				CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
				Client[victim].Disarmer = client;
				SDKCall_SetSpeed(victim);
			}
		}

		if(!cancel)
		{
			//Client[victim].Disarmer = client;
			//SDKCall_SetSpeed(victim);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Items_HeadshotHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(GetEntProp(victim, Prop_Data, "m_LastHitGroup") != HITGROUP_HEAD ||
	  (IsSCP(victim) && Client[victim].Class!=Classes_GetByName("scp0492")))
		return Plugin_Continue;

	damagetype |= DMG_CRIT;
	return Plugin_Changed;
}

public Action Items_LogicerHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	bool changed;
	bool isSCP = IsSCP(victim);
	if(isSCP)
	{
		damage /= 2.0;
		changed = true;
	}

	if((!isSCP || Client[victim].Class==Classes_GetByName("scp0492")) &&
	   GetEntProp(victim, Prop_Data, "m_LastHitGroup") == HITGROUP_HEAD)
	{
		damagetype |= DMG_CRIT;
		changed = true;
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

public void Items_LogicerSpeed(int client, float &speed)
{
	speed *= 0.91;
}

public void Items_LogicerSprint(int client, float &drain)
{
	drain *= 1.24;
}

public void Items_ChaosSpeed(int client, float &speed)
{
	speed *= 0.99;
}

public void Items_ChaosSprint(int client, float &drain)
{
	drain *= 1.02;
}

public void Items_ExplosiveHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	ClientCommand(victim, "dsp_player %d", GetRandomInt(32, 34));
}

public Action Items_FlashHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	FadeMessage(victim, 36, 768, 0x0012, 200, 200, 200, 200);
	ClientCommand(victim, "dsp_player %d", GetRandomInt(35, 37));
	return Plugin_Continue;
}

public void Items_BuilderCreate(int client, int entity)
{
	for(int i; i<4; i++)
	{
		SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", i!=3, _, i);
	}
}

public bool Items_MicroButton(int client, int weapon, int &buttons, int &holding)
{
	int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	int ammo = GetAmmo(client, type);
	static float charge[MAXTF2PLAYERS];
	if(ammo<2 || !(buttons & IN_ATTACK))
	{
		charge[client] = 0.0;
		TF2Attrib_SetByDefIndex(weapon, 821, 1.0);
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 99.0);
		return false;
	}

	buttons &= ~IN_JUMP|IN_SPEED;

	if(charge[client])
	{
		float engineTime = GetEngineTime();
		if(charge[client] == FAR_FUTURE)
		{
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
		}
		else if(charge[client] < engineTime)
		{
			charge[client] = FAR_FUTURE;
			TF2Attrib_SetByDefIndex(weapon, 821, 0.0);
		}
		else
		{
			TF2Attrib_SetByDefIndex(weapon, 821, 1.0);
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", (charge[client]-engineTime)*16.5);

			static float time[MAXTF2PLAYERS];
			if(time[client] < engineTime)
			{
				time[client] = engineTime+0.45;
				if(type != -1)
					SetEntProp(client, Prop_Data, "m_iAmmo", ammo-1, _, type);
			}
		}
	}
	else
	{
		charge[client] = GetEngineTime()+6.0;
	}
	return true;
}

public bool Items_FragButton(int client, int weapon, int &buttons, int &holding)
{
	if(!holding)
	{
		bool short = view_as<bool>(buttons & IN_ATTACK2);
		if(short || (buttons & IN_ATTACK))
		{
			holding = short ? IN_ATTACK2 : IN_ATTACK;
			RemoveAndSwitchItem(client, weapon);
			Config_DoReaction(client, "throwgrenade");

			int entity = CreateEntityByName("prop_physics_multiplayer");
			if(IsValidEntity(entity))
			{
				DispatchKeyValue(entity, "physicsmode", "2");

				static float ang[3], pos[3], vel[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				GetClientEyeAngles(client, ang);
				pos[2] += 63.0;

				vel[0] = Cosine(DegToRad(ang[0]))*Cosine(DegToRad(ang[1]))*1200.0;
				vel[1] = Cosine(DegToRad(ang[0]))*Sine(DegToRad(ang[1]))*1200.0;
				vel[2] = Sine(DegToRad(ang[0]))*-1200.0;

				if(short)
					ScaleVector(vel, 0.5);

				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));

				SetEntityModel(entity, "models/weapons/w_models/w_grenade_grenadelauncher.mdl");
				SetEntProp(entity, Prop_Send, "m_nSkin", 0);

				DispatchSpawn(entity);
				TeleportEntity(entity, pos, ang, vel);

				CreateTimer(5.0, Items_FragTimer, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return false;
}

public Action Items_FragTimer(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity > MaxClients)
	{
		static float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		int explosion = CreateEntityByName("env_explosion");
		if(IsValidEntity(explosion))
		{
			DispatchKeyValueVector(explosion, "origin", pos);
			DispatchKeyValue(explosion, "iMagnitude", "500");
			DispatchKeyValue(explosion, "iRadiusOverride", "350");
			//DispatchKeyValue(explosion, "flags", "516");

			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", client);
			DispatchSpawn(explosion);

			//CreateTimer(3.0, Timer_RemoveEntity, AttachParticle(explosion, "Explosion_CoreFlash", _, false), TIMER_FLAG_NO_MAPCHANGE);
			//CreateTimer(3.0, Timer_RemoveEntity, AttachParticle(explosion, "ExplosionCore_buildings", _, false), TIMER_FLAG_NO_MAPCHANGE);

			AcceptEntityInput(explosion, "Explode");
			AcceptEntityInput(explosion, "Kill");
		}

		explosion = CreateEntityByName("env_physexplosion");
		if(IsValidEntity(explosion))
		{
			DispatchKeyValueVector(explosion, "origin", pos);
			DispatchKeyValue(explosion, "magnitude", "500");
			DispatchKeyValue(explosion, "radius", "300");
			DispatchKeyValue(explosion, "flags", "19");

			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", client);
			DispatchSpawn(explosion);

			HookSingleEntityOutput(explosion, "OnPushedPlayer", Items_FragHook);
			AcceptEntityInput(explosion, "Explode");

			UnhookSingleEntityOutput(explosion, "OnPushedPlayer", Items_FragHook);
			AcceptEntityInput(explosion, "Kill");
		}

		AcceptEntityInput(entity, "Kill");
	}
}

public void Items_FragHook(const char[] output, int caller, int activator, float delay)
{
	if(activator > 0 && activator <= MaxClients)
		ClientCommand(activator, "dsp_player %d", GetRandomInt(32, 34));
}

public bool Items_FlashButton(int client, int weapon, int &buttons, int &holding)
{
	if(!holding)
	{
		bool short = view_as<bool>(buttons & IN_ATTACK2);
		if(short || (buttons & IN_ATTACK))
		{
			holding = short ? IN_ATTACK2 : IN_ATTACK;
			RemoveAndSwitchItem(client, weapon);
			Config_DoReaction(client, "throwgrenade");

			int entity = CreateEntityByName("prop_physics_multiplayer");
			if(IsValidEntity(entity))
			{
				DispatchKeyValue(entity, "physicsmode", "2");

				static float ang[3], pos[3], vel[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				GetClientEyeAngles(client, ang);
				pos[2] += 63.0;

				vel[0] = Cosine(DegToRad(ang[0]))*Cosine(DegToRad(ang[1]))*1200.0;
				vel[1] = Cosine(DegToRad(ang[0]))*Sine(DegToRad(ang[1]))*1200.0;
				vel[2] = Sine(DegToRad(ang[0]))*-1200.0;

				if(short)
					ScaleVector(vel, 0.5);

				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
				SetEntProp(entity, Prop_Data, "m_iHammerID", Client[client].Class);

				SetEntityModel(entity, "models/workshop/weapons/c_models/c_quadball/w_quadball_grenade.mdl");
				SetEntProp(entity, Prop_Send, "m_nSkin", 1);

				DispatchSpawn(entity);
				TeleportEntity(entity, pos, ang, vel);

				CreateTimer(3.0, Items_FlashTimer, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return false;
}

public Action Items_FlashTimer(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity > MaxClients)
	{
		static float pos1[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos1);

		int i = CreateEntityByName("env_explosion");
		if(IsValidEntity(i))
		{
			DispatchKeyValueVector(i, "origin", pos1);
			DispatchKeyValue(i, "iMagnitude", "0");
			DispatchKeyValue(i, "flags", "532");

			SetEntPropEnt(i, Prop_Send, "m_hOwnerEntity", GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));
			DispatchSpawn(i);

			//CreateTimer(2.0, Timer_RemoveEntity, AttachParticle(i, "Explosions_MA_Flash_1", _, false), TIMER_FLAG_NO_MAPCHANGE);

			AcceptEntityInput(i, "Explode");
			AcceptEntityInput(i, "Kill");
		}

		int class = GetEntProp(entity, Prop_Data, "m_iHammerID");
		for(i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && !IsFriendly(class, Client[i].Class))
			{
				static float pos2[3];
				GetClientEyePosition(i, pos2);
				if(GetVectorDistance(pos1, pos2, true) < 250000.0)
				{
					FadeMessage(i, 1000, 1000, 0x0001, 200, 200, 200, 255);
					ClientCommand(i, "dsp_player %d", GetRandomInt(35, 37));
				}
			}
		}

		AcceptEntityInput(entity, "Kill");
	}
}

public bool Items_PainKillerButton(int client, int weapon, int &buttons, int &holding)
{
	if(holding)
	{
		return false;
	}
	else if(buttons & IN_ATTACK)
	{
		holding = IN_ATTACK;

		ApplyHealEvent(client, 6);

		SetEntityHealth(client, GetClientHealth(client)+6);
		StartHealingTimer(client, 0.4, 1, 50);
	}
	else if(buttons & IN_ATTACK2)
	{
		holding = IN_ATTACK2;

		SpawnPlayerPickup(client, "item_healthkit_small");
	}
	else
	{
		return false;
	}

	RemoveAndSwitchItem(client, weapon);
	return false;
}

public bool Items_HealthKitButton(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && ((buttons & IN_ATTACK) || (buttons & IN_ATTACK2)))
	{
		holding = (buttons & IN_ATTACK) ? IN_ATTACK : IN_ATTACK2;
		SpawnPlayerPickup(client, "item_healthkit_medium");
		RemoveAndSwitchItem(client, weapon);
	}
	return false;
}

public bool Items_AdrenalineButton(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;
		RemoveAndSwitchItem(client, weapon);
		StartHealingTimer(client, 0.334, 1, 60, true);
		TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, 20.0, client);
		Client[client].Extra3 = GetEngineTime()+20.0;
		FadeClientVolume(client, 0.3, 2.5, 17.5, 2.5);
	}
	return false;
}

public bool Items_RadioButton(int client, int entity, int &buttons, int &holding)
{
	if(!holding)
	{
		if(buttons & IN_ATTACK)
		{
			holding = IN_ATTACK;

			int clip = GetEntProp(entity, Prop_Data, "m_iClip1");
			if(clip > 3)
			{
				clip = 0;
			}
			else
			{
				clip++;
			}

			SetEntProp(entity, Prop_Data, "m_iClip1", clip);
		}
		else if(buttons & IN_ATTACK2)
		{
			holding = IN_ATTACK2;

			int clip = GetEntProp(entity, Prop_Data, "m_iClip1");
			if(clip < 1)
			{
				clip = 4;
			}
			else
			{
				clip--;
			}

			SetEntProp(entity, Prop_Data, "m_iClip1", clip);
		}
	}
	return false;
}

public bool Items_500Button(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;
		RemoveAndSwitchItem(client, weapon);

		if(GetClientHealth(client) < 26)
			GiveAchievement(Achievement_Survive500, client);

		SpawnPlayerPickup(client, "item_healthkit_full", true);
		StartHealingTimer(client, 0.334, 1, 36, true);
		Client[client].Extra2 = 0;

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.Group==1)
			Gamemode_GiveTicket(1, 2);
	}
	return false;
}

public bool Items_207Button(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;
		RemoveAndSwitchItem(client, weapon);

		int current = GetClientHealth(client);
		int max = Classes_GetMaxHealth(client);
		if(current < max)
		{
			int health = max/3;
			if(current+health > max)
				health = max-current;

			SetEntityHealth(client, current+health);
			ApplyHealEvent(client, health);
		}

		if(Client[client].Extra2 < 4)
		{
			StartHealingTimer(client, 2.5, -1, 250, _, true);
			Client[client].Extra2++;
		}

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.Group==1)
			Gamemode_GiveTicket(1, 2);
	}
	return false;
}

public bool Items_018Button(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;
		RemoveAndSwitchItem(client, weapon);
		TF2_AddCondition(client, TFCond_CritCola, 6.0);
		TF2_AddCondition(client, TFCond_RestrictToMelee, 6.0);

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.Group==1)
			Gamemode_GiveTicket(1, 2);
	}
	return false;
}

public bool Items_268Button(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;

		float engineTime = GetEngineTime();
		static float delay[MAXTF2PLAYERS];
		if(delay[client] > engineTime)
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			PrintCenterText(client, "%T", "in_cooldown", client);
			return false;
		}

		delay[client] = engineTime+90.0;
		TF2_AddCondition(client, TFCond_Stealthed, 15.0);
		ClientCommand(client, "playgamesound misc/halloween/spell_stealth.wav");

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.Group==1)
			Gamemode_GiveTicket(1, 1);
	}
	return false;
}

public bool Items_RadioRadio(int client, int entity, float &multi)
{
	static float time[MAXTF2PLAYERS];
	bool remove, off;
	float engineTime = GetEngineTime();
	switch(GetEntProp(entity, Prop_Data, "m_iClip1"))
	{
		case 1:
		{
			multi = 2.6;
			if(time[client]+60.0 < engineTime)
				remove = true;
		}
		case 2:
		{
			multi = 3.5;
			if(time[client]+30.0 < engineTime)
				remove = true;
		}
		case 3:
		{
			multi = 5.7;
			if(time[client]+12.5 < engineTime)
				remove = true;
		}
		case 4:
		{
			multi = 10.8;
			if(time[client]+5.0 < engineTime)
				remove = true;
		}
		default:
		{
			off = true;
		}
	}

	if(remove)
	{
		time[client] = engineTime;
		int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
		if(type != -1)
		{
			int ammo = GetAmmo(client, type);
			if(ammo > 0)
			{
				SetEntProp(client, Prop_Data, "m_iAmmo", ammo-1, _, type);
			}
			else
			{
				multi = 1.0;
				off = true;
			}
		}
	}
	return !off;
}

public void Items_LightAmmo(int client, int type, int &ammo)
{
	if(ammo == 2)	// 9mm
		ammo += 30;
}

public void Items_LightItem(int client, int type, int &amount)
{
	if(type == 1)	// Weapons
		amount++;
}

public void Items_CombatAmmo(int client, int type, int &ammo)
{
	switch(type)
	{
		case 2:	// 9mm
		{
			ammo += 90;
		}
		case 6, 7:	// 7mm, 5mm
		{
			ammo += 80;
		}
		case 10:	// 4mag
		{
			ammo += 30;
		}
		case 11:	// 12ga
		{
			ammo += 40;
		}
	}
}

public void Items_CombatItem(int client, int type, int &amount)
{
	switch(type)
	{
		case 1:	// Weapons
			amount ++;

		case 7:	// Grenades
			amount++;
	}
}

public void Items_CombatSprint(int client, float &drain)
{
	drain *= 1.1;
}

public void Items_HeavyAmmo(int client, int type, int &ammo)
{
	switch(type)
	{
		case 2:	// 9mm
		{
			ammo += 170;
		}
		case 6, 7:	// 7mm, 5mm
		{
			ammo += 160;
		}
		case 10:	// 4mag
		{
			ammo += 50;
		}
		case 11:	// 12ga
		{
			ammo += 60;
		}
	}
}

public void Items_HeavyItem(int client, int type, int &amount)
{
	switch(type)
	{
		case 1:	// Weapons
			amount += 2;

		case 3:	// Medical
			amount++;

		case 7:	// Grenades
			amount++;
	}
}

public void Items_HeavySpeed(int client, float &speed)
{
	speed *= 0.95;
}

public void Items_HeavySprint(int client, float &drain)
{
	drain *= 1.2;
}

public int Items_KeycardJan(int client, AccessEnum access)
{
	if(access == Access_Main)
		return 1;

	return 0;
}

public int Items_KeycardSci(int client, AccessEnum access)
{
	if(access == Access_Main)
		return 2;

	return 0;
}

public int Items_KeycardZon(int client, AccessEnum access)
{
	if(access==Access_Main || access==Access_Checkpoint)
		return 1;

	return 0;
}

public int Items_KeycardRes(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Main:
			return 2;

		case Access_Checkpoint:
			return 1;

		default:
			return 0;
	}
}

public int Items_KeycardGua(int client, AccessEnum access)
{
	if(access==Access_Main || access==Access_Checkpoint || access==Access_Armory)
		return 1;

	return 0;
}

public int Items_KeycardCad(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Main:
			return 2;

		case Access_Checkpoint, Access_Armory:
			return 1;

		default:
			return 0;
	}
}

public int Items_KeycardLie(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Main, Access_Armory:
			return 2;

		case Access_Exit, Access_Checkpoint:
			return 1;

		default:
			return 0;
	}
}

public int Items_KeycardCom(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Armory:
			return 3;

		case Access_Main:
			return 2;

		case Access_Exit, Access_Checkpoint, Access_Intercom:
			return 1;

		default:
			return 0;
	}
}

public int Items_KeycardEng(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Main:
			return 3;

		case Access_Warhead, Access_Checkpoint, Access_Intercom:
			return 1;

		default:
			return 0;
	}
}

public int Items_KeycardFac(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Main:
			return 3;

		case Access_Exit, Access_Warhead, Access_Checkpoint, Access_Intercom:
			return 1;

		default:
			return 0;
	}
}

public int Items_KeycardCha(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Armory:
			return 3;

		case Access_Main:
			return 2;

		case Access_Exit, Access_Checkpoint, Access_Intercom:
			return 1;

		default:
			return 0;
	}
}

public int Items_KeycardAll(int client, AccessEnum access)
{
	if(access==Access_Main || access==Access_Armory)
		return 3;

	return 1;
}

public int Items_KeycardScp(int client, AccessEnum access)
{
	if(access == Access_Checkpoint)
		return 1;

	return 0;
}