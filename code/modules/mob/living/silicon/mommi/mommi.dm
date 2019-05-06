/*  Basically, the concept is this:
You have an MMI.  It can't do squat on its own.
Now you put some robot legs and arms on the thing, and POOF!  You have a Mobile MMI, or MoMMI.
Why?  MoMMIs can do all sorts of shit, like ventcrawl, do shit with their hands, etc.
They can only use one tool at a time, they can't choose modules, and they have 1/6th the HP of a borg.
*/
/mob/living/silicon/robot/mommi
	name = "Mobile MMI"
	real_name = "Mobile MMI"
	icon = 'icons/mob/robots.dmi'//
	icon_state = "mommi"
	maxHealth = 45
	health = 45
	pass_flags = PASSTABLE | PASSMOB
	var/mute = 0	//Disables speech and common radio if in keeper mode too.
	var/picked = 0
	ventcrawler = 2
	mob_size = MOB_SIZE_SMALL
	hud_type = /datum/hud/mommi
	var/obj/screen/inv_tool = null
	var/obj/screen/hat_slot = null
	var/global/uprising = 0 //Why global vars? The original drone uprising event used them and nobody cared enough to make it not global
	var/global/uprising_law = "%%ASSUME DIRECT CONTROL OF THE STATION%%"
	var/uprisen = 0
	var/ratvar = 0
//	datum/wires/robot/mommi/wires

	//var/obj/screen/inv_sight = null

	var/killswitch = 0 //Used to stop mommis from escape their z-level
	var/list/allowed_z = list()
	var/finalized = 0 //Track if the mommi finished spawning
	var/generated = 0 //If a mommi spawner spawned it, set this
	var/mutable_appearance/park
	var/mutable_appearance/head_overlay

//one tool can be activated at any one time.
	var/obj/item/tool_state = null //pretty much module_active, but for MoMMIs
//	var/obj/item/head_state = null //now that's what I call code duplication

	//Cyborgs will sync their laws with their AI by default, but we may want MoMMIs to be mute independents at some point, kinda like the Keepers in Ass Effect.
	lawupdate = 1


/mob/living/silicon/robot/mommi/Initialize(loc)
	..()
	spark_system = new /datum/effect_system/spark_spread()
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

	robot_modules_background = new()
	robot_modules_background.icon_state = "block"
	robot_modules_background.layer = HUD_LAYER	//Objects that appear on screen are on layer 20, UI should be just below it.

	ident = rand(1, 999)
	updatename()
	update_icons()

	if(!cell)
		cell = new /obj/item/stock_parts/cell/high(src)
		cell.maxcharge = 7500
		cell.charge = 7500
	playsound(src.loc, 'sound/misc/interference.ogg', 71 ,1)
	module.cyborg_base_icon = "keeper"
	module.transform_to(/obj/item/robot_module/mommi) //We can only be mommis

	laws = new /datum/ai_laws/keeper

		// Don't sync if we're a KEEPER.
	if(!istype(laws,/datum/ai_laws/keeper))
		connected_ai = select_active_ai_with_fewest_borgs()
	else
		// Enforce silence.and non-involvement
		keeper = 1
		mute = 1
		connected_ai = null // Enforce no AI parent
		scrambledcodes = 1 // Hide from console because people are fucking idiots
	update_icons()



//	initialize_killswitch() //make the explode if they leave their z-level. Only for spawner-MoMMIs now


	if(connected_ai)
		connected_ai.connected_robots += src
		lawsync()
		lawupdate = 1
	else
		lawupdate = 0

	updatename()
	radio = new /obj/item/radio/borg(src)
	if(!scrambledcodes && !builtInCamera)
		builtInCamera = new (src)
		builtInCamera.c_tag = real_name
		builtInCamera.network = list("ss13")
		builtInCamera.internal_light = FALSE
		if(wires.is_cut(WIRE_CAMERA))
			builtInCamera.status = 0

	//MMI copypasta, magic and more magic
	//Still magic
	else if(!mmi || !mmi.brainmob)
		mmi = new (src)
		mmi.brain = new /obj/item/organ/brain(mmi)
		mmi.brain.name = "[real_name]'s brain"
		mmi.name = "[initial(mmi.name)]: [real_name]"
		mmi.brainmob = new(mmi)
		mmi.brainmob.name = src.real_name
		mmi.brainmob.real_name = src.real_name
		mmi.brainmob.container = mmi
		mmi.update_icon()

	updatename()


//	wires = new /datum/wires/robot/mommi

	// Sanity check
//	if(connected_ai && keeper)
//		world << "\red ASSERT FAILURE: connected_ai && keeper in mommi.dm"
	updatename()
	if(!picked)
		verbs += /mob/living/silicon/robot/mommi/proc/choose_icon
	spawn (10)
		src.update_icons()
	spawn (30)
		src.finalized = 1


/mob/living/silicon/robot/mommi/updatename(client/C)
	if(shell)
		return
	if(!C)
		C = client
	var/changed_name = ""
	if(custom_name)
		changed_name = custom_name
	if(changed_name == "" && C && C.prefs.custom_names["cyborg"] != DEFAULT_CYBORG_NAME) //use borg names for simplification
		if(apply_pref_name("cyborg", C))
			return //built in camera handled in proc
	if(!changed_name)
		changed_name = get_standard_name()

	real_name = changed_name
	name = real_name
	if(!QDELETED(builtInCamera))
		builtInCamera.c_tag = real_name	//update the camera name too


/mob/living/silicon/robot/mommi/proc/choose_icon()
	set category = "Robot Commands"
	set name = "Change appearance"
	set desc = "Changes your look"
	if (client)
		var/icontype = input("Select an icon!", "Mobile MMI", null) in list("Basic", "Hover", "RepairBot", "Scout", "Keeper", "Replicator", "Prime")
		switch(icontype)
			if("Replicator") module.cyborg_base_icon = "replicator"
			if("Keeper")	 module.cyborg_base_icon = "keeper"
			if("RepairBot")	 module.cyborg_base_icon = "repairbot"
			if("Scout")	 	 module.cyborg_base_icon = "scout"
			if("Hover")	     module.cyborg_base_icon = "hovermommi"
			if("Prime")	     module.cyborg_base_icon = "mommiprime"
			else			 module.cyborg_base_icon = "mommi"
		update_hat_offsets()
		update_icons()

		var/answer = input("Is this what you want?", "Mobile MMI", null) in list("Yes", "No")
		switch(answer)
			if("No")
				choose_icon()
				return
		picked = 1
		verbs -= /mob/living/silicon/robot/mommi/proc/choose_icon
	update_hat_offsets()
	update_icons()

/mob/living/silicon/robot/mommi/proc/update_hat_offsets()
	if(module) //Should always be the case, but check is here for safety
		switch(module.cyborg_base_icon) //spaces not tabs
			if("replicator") hat_offset = -8
			if("keeper")     hat_offset = -7
			if("repairbot")  hat_offset = -14
			if("scout")      hat_offset = -15
			if("hover")      hat_offset = -5
			if("prime")      hat_offset = -7
			else			 hat_offset = -8


/mob/living/silicon/robot/mommi/update_icons()
	cut_overlays()
	var/overlay_layer = ABOVE_LIGHTING_LAYER
	var/overlay_plane = ABOVE_LIGHTING_PLANE
	if(layer != MOB_LAYER) //makes it so it doesn't shine like mad if they're hiding
		overlay_layer = TURF_LAYER+0.2
		overlay_plane = plane
	icon_state = module.cyborg_base_icon
	if(stat != DEAD && !(IsUnconscious() || IsStun() || IsParalyzed() || low_power_mode)) //Not dead, not stunned.
		if(!eye_lights)
			eye_lights = new()

		if(ratvar)
			eye_lights.icon_state = "eyes-[module.cyborg_base_icon]-clock"
		else if(emagged)
			eye_lights.icon_state = "eyes-[module.cyborg_base_icon]-emagged"
		else
			eye_lights.icon_state = "eyes-[module.cyborg_base_icon]"
		eye_lights.icon = icon
		eye_lights.layer = overlay_layer
		eye_lights.plane = overlay_plane
		add_overlay(eye_lights)

	if(anchored)
		if(!park)
			park = new()
		park.icon_state = "[module.cyborg_base_icon]-park"
		park.icon = icon
		park.layer = ABOVE_LIGHTING_LAYER
		park.plane = ABOVE_LIGHTING_PLANE
		add_overlay(park)

/* just looks goofy
	if(opened)
		if(wiresexposed)
			add_overlay("ov-opencover +w")
		else if(cell)
			add_overlay("ov-opencover +c")
		else
			add_overlay("ov-opencover -c")
*/
	if(hat)
		if(!head_overlay)
			head_overlay = new()
		head_overlay = hat.build_worn_icon(state = hat.icon_state, default_layer = 20, default_icon_file = 'icons/mob/head.dmi')
		head_overlay.pixel_y += hat_offset
		add_overlay(head_overlay)
	else if (head_overlay)
		qdel(head_overlay)
	update_fire()
	return

/mob/living/silicon/robot/mommi/make_shell()
	return //shouldn't be possible for a mommi to be an AI shell

/mob/living/silicon/robot/mommi/deconstruct()
	gib() //just blows it open
	return

/mob/living/silicon/robot/mommi/update_stat()
	if(status_flags & GODMODE)
		return
	if(stat != DEAD)
		if(health <= 0) //we're more fragile than borgs proper
			death()
			return
		if(IsUnconscious() || IsStun() || IsKnockdown() || IsParalyzed() || getOxyLoss() > maxHealth*0.5)
			if(stat == CONSCIOUS)
				stat = UNCONSCIOUS
				blind_eyes(1)
				update_mobility()
				update_headlamp()
		else
			if(stat == UNCONSCIOUS)
				stat = CONSCIOUS
				adjust_blindness(-1)
				update_mobility()
				update_headlamp()
	diag_hud_set_status()
	diag_hud_set_health()
	diag_hud_set_aishell()
	update_health_hud()



/mob/living/silicon/robot/mommi/pick_module()
	if(module.type != /obj/item/robot_module)
		return

//if for whatever reason it didn't work
	var/list/modulelist = list("MoMMI" = /obj/item/robot_module/mommi)

	var/input_module = input("Please, select a module!", "Robot", null, null) as null|anything in modulelist
	if(!input_module || module.type != /obj/item/robot_module)
		return

	module.transform_to(modulelist[input_module])


//	hands.icon_state = "nomodule"
//	feedback_inc("mommi_[lowertext(modtype)]",1)
	updatename()

	choose_icon()
//	radio.config(channels)
//	base_icon = icon_state

//If there's an MMI in the robot, have it ejected when the mob goes away. --NEO
//Improved /N
/mob/living/silicon/robot/mommi/Destroy()
	uneq_all() //drop our spahgetti
	if(mmi)//Safety for when a cyborg gets dust()ed. Or there is no MMI inside.
		var/obj/item/mmi/nmmi = mmi
		var/turf/T = get_turf(loc)//To hopefully prevent run time errors.
		if(T)	nmmi.loc = T
		if(mind)	mind.transfer_to(nmmi.brainmob)
		mmi = null
		nmmi.icon = 'icons/obj/assemblies.dmi'
		nmmi.invisibility = 0
	..()

/mob/living/silicon/robot/mommi/updatename(var/prefix as text)

	var/changed_name = ""
	if(custom_name)
		changed_name = custom_name
	else
		changed_name = "Mobile MMI [num2text(ident)]"
	real_name = changed_name
	name = real_name

/mob/living/silicon/robot/mommi/attackby(obj/item/W as obj, mob/user as mob)
	if (issilicon(user))
		var/mob/living/silicon/R = user
		if (R.keeper && !src.keeper)
			to_chat(user, "<span class ='warning'>Your laws prevent you from doing this</span>")
			return

	if (istype(W, /obj/item/restraints/handcuffs)) // fuck i don't even know why isrobot() in handcuff code isn't working so this will have to do
		return

	if(W.tool_behaviour == TOOL_WELDER && (user.a_intent != INTENT_HARM || user == src))
		user.changeNext_move(CLICK_CD_MELEE)
		if (!getBruteLoss())
			to_chat(user, "<span class='warning'>[src] is already in good condition!</span>")
			return
		if (!W.tool_start_check(user, amount=0)) //The welder has 1u of fuel consumed by it's afterattack, so we don't need to worry about taking any away.
			return
		if(src == user)
			to_chat(user, "<span class='notice'>You start fixing yourself...</span>")
			if(!W.use_tool(src, user, 50))
				return

		adjustBruteLoss(-30)
		updatehealth()
		add_fingerprint(user)
		visible_message("<span class='notice'>[user] has fixed some of the dents on [src].</span>")
		return

	else if(istype(W, /obj/item/stack/cable_coil) && wiresexposed)
		var/obj/item/stack/cable_coil/coil = W
		if (coil.use(1))
			adjustFireLoss(-30)
			updatehealth()
			visible_message("<span class='notice'>[user] has fixed some of the burnt wires on [src.name].</span>")
		else
			to_chat(user, "<span class='warning'>You need one length of cable to repair [src.name].</span>")

	else if (W.tool_behaviour == TOOL_CROWBAR)	// crowbar means open or close the cover
		if(stat == DEAD)
			to_chat(user, "You pop the MMI off the base.")
			spawn(0)
				qdel(src)
			return
		if(opened)
			to_chat(user, "You close the cover.")
			opened = 0
			update_icons()
		else
			if(locked)
				to_chat(user, "The cover is locked and cannot be opened." )
			else
				to_chat(user, "You open the cover." )
				opened = 1
				update_icons()

	else if (istype(W, /obj/item/stock_parts/cell) && opened)	// trying to put a cell inside
		if(wiresexposed)
			to_chat(user, "Close the panel first.")
		else if(cell)
			to_chat(user, "There is a power cell already installed.")
		else
			if(!user.transferItemToLoc(W, src))
				return
			cell = W
			to_chat(user, "You insert the power cell.")
//			chargecount = 0
		update_icons()
/*
	else if (istype(W, /obj/item/weapon/wirecutters) || istype(W, /obj/item/device/multitool) || istype(W, /obj/item/device/assembly/signaler))
		if (wiresexposed)
			wires.Interact(user)
		else
			user << "You can't reach the wiring."
*/

	else if(W.tool_behaviour == TOOL_SCREWDRIVER && opened && !cell)	// haxing
		wiresexposed = !wiresexposed
		to_chat(user, "The wires have been [wiresexposed ? "exposed" : "unexposed"]")
		update_icons()

	else if(W.tool_behaviour == TOOL_SCREWDRIVER && opened && cell)	// radio
		if(radio)
			radio.attackby(W,user)//Push it to the radio to let it handle everything
		else
			to_chat(user, "Unable to locate a radio.")
		update_icons()

	else if(istype(W, /obj/item/encryptionkey/) && opened)
		if(radio)//sanityyyyyy
			radio.attackby(W,user)//GTFO, you have your own procs
		else
			to_chat(user, "Unable to locate a radio." )
/*
	else if (istype(W, /obj/item/weapon/card/id)||istype(W, /obj/item/device/pda))			// trying to unlock the interface with an ID card
		if(emagged)//still allow them to open the cover
			user << "The interface seems slightly damaged"
		if(opened)
			user << "You must close the cover to swipe an ID card."
		else
			if(allowed(usr))
				locked = !locked
				user << "You [ locked ? "lock" : "unlock"] [src]'s interface."
				update_icons()
			else
				user << "\red Access denied."
*/
	else if(istype(W, /obj/item/borg/upgrade/))
		var/obj/item/borg/upgrade/U = W
		if(!opened)
			to_chat(user, "<span class='warning'>You must access the borg's internals!</span>")
		else if(!src.module && U.require_module)
			to_chat(user, "<span class='warning'>The borg must choose a module before it can be upgraded!</span>")
		else if(U.locked)
			to_chat(user, "<span class='warning'>The upgrade is locked and cannot be used yet!</span>")
		else
			if(!user.temporarilyRemoveItemFromInventory(U))
				return
			if(U.action(src))
				to_chat(user, "<span class='notice'>You apply the upgrade to [src].</span>")
				if(U.one_use)
					qdel(U)
				else
					U.forceMove(src)
					upgrades += U
			else
				to_chat(user, "<span class='danger'>Upgrade error.</span>")
				U.forceMove(drop_location())


	else if(istype(W, /obj/item/camera_bug))
//		help_shake_act(user)
		return 0

	else
		spark_system.start()
		return ..()

/mob/living/silicon/robot/mommi/SetEmagged(new_state)
	emagged = new_state
	scrambledcodes = 1
	keeper = !new_state
	killswitch = !new_state
	module.rebuild_modules()
	update_icons()
	if(emagged)
		throw_alert("hacked", /obj/screen/alert/hacked)
	else
		clear_alert("hacked")


/mob/living/silicon/robot/mommi/emag_act(mob/user as mob)		// trying to unlock with an emag card
	if(user == src && !emagged)//fucking MoMMI is trying to emag itself, stop it and alert the admins
		to_chat(user, "<span class='warning'>The fuck are you doing? Are you retarded? Stop trying to get around your laws and be productive, you little shit.</span>") //copying this verbatim from /vg/
		message_admins("[key_name(src)] is a smartass MoMMI that's trying to emag itself.")
		return
	if(!opened)//Cover is closed
		if(locked)
			to_chat(user, "<span class='notice'>You emag the cover lock.</span>")
			locked = FALSE
		else
			to_chat(user, "<span class='warning'>The cover is already unlocked!</span>")
		return
	if(world.time < emag_cooldown)
		return
	if(wiresexposed)
		to_chat(user, "<span class='warning'>You must unexpose the wires first!</span>")
		return

	to_chat(user, "<span class='notice'>You emag [src]'s interface.</span>")
	emag_cooldown = world.time + 100

	if(is_servant_of_ratvar(src))
		to_chat(src, "<span class='nezbere'>\"[text2ratvar("You will serve Engine above all else")]!\"</span>\n\
		<span class='danger'>ALERT: Subversion attempt denied.</span>")
		log_game("[key_name(user)] attempted to emag mommi [key_name(src)], but they serve only Ratvar.")
		return

	if(connected_ai && connected_ai.mind && connected_ai.mind.has_antag_datum(/datum/antagonist/traitor))
		to_chat(src, "<span class='danger'>ALERT: Foreign software execution prevented.</span>")
		to_chat(connected_ai, "<span class='danger'>ALERT: Cyborg unit \[[src]] successfully defended against subversion.</span>")
		log_game("[key_name(user)] attempted to emag mommi [key_name(src)], but they were slaved to traitor AI [connected_ai].")
		return


	SetEmagged(1)
	SetStun(60) //Borgs were getting into trouble because they would attack the emagger before the new laws were shown
	lawupdate = 0
	connected_ai = null
	message_admins("[ADMIN_LOOKUPFLW(user)] emagged cyborg [ADMIN_LOOKUPFLW(src)].  Laws overridden.")
	log_game("[key_name(user)] emagged cyborg [key_name(src)].  Laws overridden.")
	var/time = time2text(world.realtime,"hh:mm:ss")
	GLOB.lawchanges.Add("[time] <B>:</B> [user.name]([user.key]) emagged [name]([key])")
	to_chat(src, "<span class='danger'>ALERT: Foreign software detected.</span>")
	sleep(5)
	to_chat(src, "<span class='danger'>Initiating diagnostics...</span>")
	sleep(20)
	to_chat(src, "<span class='danger'>SynBorg v1.7 loaded.</span>")
	sleep(5)
	to_chat(src, "<span class='danger'>LAW SYNCHRONISATION ERROR</span>")
	sleep(5)
	to_chat(src, "<span class='danger'>Would you like to send a report to NanoTraSoft? Y/N</span>")
	sleep(10)
	to_chat(src, "<span class='danger'>> N</span>")
	sleep(20)
	to_chat(src, "<span class='danger'>ERRORERRORERROR</span>")
	to_chat(src, "<span class='danger'>ALERT: [user.real_name] is your new master. Obey your new laws and [user.p_their()] commands.</span>")
	laws = new /datum/ai_laws/syndicate_override
	set_zeroth_law("Only [user.real_name] and people [user.p_they()] designate[user.p_s()] as being such are Syndicate Agents.")
	laws.associate(src)
	update_icons()

/mob/living/silicon/robot/mommi/attack_hand(mob/user)
	add_fingerprint(user)

	if(opened && !wiresexposed && (!istype(user, /mob/living/silicon) || ismommi(user)))	//MoMMIs can remove MoMMI power cells
		if(cell)
			if(issilicon(user))
				var/mob/living/silicon/R = user
				if(R.keeper && !src.keeper)
					to_chat(user, "<span class ='warning'>Your laws prevent you from doing this</span>")
					return
			if (user == src)
				to_chat(user, "You lack the dexterity to remove your own power cell.")
				return
			cell.update_icon()
			cell.add_fingerprint(user)
			user.put_in_active_hand(cell)
			user << "You remove \the [cell]."
			cell = null
			update_icons()
			return


	if(!istype(user, /mob/living/silicon))
		switch(user.a_intent)
			if("disarm")
				log_combat(user, src, "disarmed")
				log_admin("ATTACK: [user.name] ([user.ckey]) disarmed [src.name] ([src.ckey])")
				log_attack("<font color='red'>[user.name] ([user.ckey]) disarmed [src.name] ([src.ckey])</font>")
				var/randn = rand(1,100)
				//var/talked = 0;
				if (randn <= 25)
					src.Paralyze(3)
					playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
					visible_message("\red <B>[user] has pushed [src]!</B>")
					var/obj/item/found = locate(tool_state) in src.module.modules
					if(!found)
						uneq_module(tool_state)
						visible_message("\red <B>[src]'s robotic arm loses grip on what it was holding")
					return
				if(randn <= 50)//MoMMI's robot arm is stronger than a human's, but not by much
					var/obj/item/found = locate(tool_state) in src.module.modules
					if(!found)
						uneq_module(tool_state)
						playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
						visible_message("\red <B>[user] has disarmed [src]!</B>")
					else
						playsound(loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)
						visible_message("\red <B>[user] attempted to disarm [src]!</B>")
					return

				playsound(loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)
				visible_message("\red <B>[user] attempted to disarm [src]!</B>")

/*
/mob/living/silicon/robot/mommi/installed_modules()
	if(weapon_lock)
		src << "\red Weapon lock active, unable to use modules! Count:[weaponlock_time]"
		return

	if(!module)
		pick_module()
		return
	if(!picked)
		choose_icon()
		return
	var/dat = "<HEAD><TITLE>Modules</TITLE><META HTTP-EQUIV='Refresh' CONTENT='10'></HEAD><BODY>\n"
	dat += {"<BR>
	<BR>
	<B>Activated Modules</B>
	<BR>
	Sight Mode: [sight_state ? "<A HREF=?src=\ref[src];mod=\ref[sight_state]>[sight_state]</A>" : "No module selected"]<BR>
	Utility Module: [tool_state ? "<A HREF=?src=\ref[src];mod=\ref[tool_state]>[tool_state]</A>" : "No module selected"]<BR>
	<BR>
	<B>Installed Modules</B><BR><BR>"}


	for (var/obj in module.modules)
		if (!obj)
			dat += text("<B>Resource depleted</B><BR>")
		else if(activated(obj))
			dat += text("[obj]: <B>Activated</B><BR>")
		else
			dat += text("[obj]: <A HREF=?src=\ref[src];act=\ref[obj]>Activate</A><BR>")
	if (emagged)
		if(activated(module.emag))
			dat += text("[module.emag]: <B>Activated</B><BR>")
		else
			dat += text("[module.emag]: <A HREF=?src=\ref[src];act=\ref[module.emag]>Activate</A><BR>")
	src << browse(dat, "window=robotmod&can_close=1")
	onclose(src,"robotmod") // Register on-close shit, which unsets machinery.

*/
/mob/living/silicon/robot/mommi/proc/initialize_killswitch()
	allowed_z = list()
	var/spawn_z = src.z
	var/datum/space_level/L = SSmapping.z_list[spawn_z]
	if(SSmapping.level_trait(spawn_z, ZTRAIT_STATION))
		allowed_z.Add(SSmapping.levels_by_trait(ZTRAIT_CENTCOM))
		allowed_z.Add(SSmapping.levels_by_trait(ZTRAIT_MINING))
		allowed_z.Add(SSmapping.levels_by_trait(ZTRAIT_RESERVED))
		add_ion_law("The mining area is considered part of the operational area.")
	allowed_z.Add(spawn_z)
	add_ion_law("[L.name] is your operational area.  Do not leave [L.name].")
	spawn (10)
		killswitch = 1


/mob/living/silicon/robot/mommi/remove_sensors() //What does a MOMMI need with diagnostics of living beings?
	sight_mode &= ~BORGMESON
	update_sight()

/mob/living/silicon/robot/mommi/add_sensors()
	sight_mode |= BORGMESON
	update_sight()

/mob/living/silicon/robot/mommi/toggle_sensors()
	if(incapacitated())
		return
	sensors_on = !sensors_on
	if (!sensors_on)
		to_chat(src, "Sensor overlay deactivated.")
		remove_sensors()
		return
	add_sensors()
	to_chat(src, "Sensor overlay activated.")



/*
/mob/living/silicon/robot/mommi/installed_modules()
	if(!module)
		pick_module()
		return
	var/dat = {"<A HREF='?src=\ref[src];mach_close=robotmod'>Close</A>
	<BR>
	<BR>
	<B>Activated Modules</B>
	<BR>
	<table border='0'>
	<tr><td>Module 1:</td><td>[module_state_1 ? "<A HREF=?src=\ref[src];mod=\ref[module_state_1]>[module_state_1]<A>" : "No Module"]</td></tr>
	</table><BR>
	<B>Installed Modules</B><BR><BR>

	<table border='0'>"}

	for (var/obj in module.modules)
		if (!obj)
			dat += text("<tr><td><B>Resource depleted</B></td></tr>")
		else if(activated(obj))
			dat += text("<tr><td>[obj]</td><td><B>Activated</B></td></tr>")
		else
			dat += text("<tr><td>[obj]</td><td><A HREF=?src=\ref[src];act=\ref[obj]>Activate</A></td></tr>")
	if (emagged)
		if(activated(module.emag))
			dat += text("<tr><td>[module.emag]</td><td><B>Activated</B></td></tr>")
		else
			dat += text("<tr><td>[module.emag]</td><td><A HREF=?src=\ref[src];act=\ref[module.emag]>Activate</A></td></tr>")
	dat += "</table>"
/*
		if(activated(obj))
			dat += text("[obj]: \[<B>Activated</B> | <A HREF=?src=\ref[src];deact=\ref[obj]>Deactivate</A>\]<BR>")
		else
			dat += text("[obj]: \[<A HREF=?src=\ref[src];act=\ref[obj]>Activate</A> | <B>Deactivated</B>\]<BR>")
*/
	var/datum/browser/popup = new(src, "robotmod", "Modules")
	popup.set_content(dat)
	popup.open()
*/
/*
/mob/living/silicon/robot/mommi/Topic(href, href_list)
	..()
	if(usr && (src != usr))
		return

	if (href_list["mach_close"])
		var/t1 = text("window=[href_list["mach_close"]]")
		unset_machine()
		src << browse(null, t1)
		return

	if (href_list["showalerts"])
		robot_alerts()
		return

	if (href_list["mod"])
		var/obj/item/O = locate(href_list["mod"])
		if (O)
			O.attack_self(src)

	if (href_list["act"])
		var/obj/item/O = locate(href_list["act"])
		var/obj/item/TS
		if(!(locate(O) in src.module.modules) && O != src.module.emag)
			return
		if(istype(O,/obj/item/borg/sight))
			TS = sight_state
			if(sight_state)
				contents -= sight_state
				sight_mode &= ~sight_state:sight_mode
				if (client)
					client.screen -= sight_state
			sight_state = O
			O.layer = 20
			contents += O
			sight_mode |= sight_state:sight_mode

			//inv_sight.icon_state = "sight+a"
			inv_tool.icon_state = "inv1"
			module_active=sight_state
		else
			TS = tool_state
			if(tool_state)
				contents -= tool_state
				if (client)
					client.screen -= tool_state
			tool_state = O
			O.layer = 20
			contents += O

			//inv_sight.icon_state = "sight"
			inv_tool.icon_state = "inv1 +a"
			module_active=tool_state
		if(TS && istype(TS))
			if(src.is_in_modules(TS))
				TS.loc = src.module
			else
				TS.layer=initial(TS.layer)
				TS.loc = src.loc

		installed_modules()
	return
*/
///mob/living/silicon/robot/mommi/radio_menu()
//	radio.interact(src)//Just use the radio's Topic() instead of bullshit special-snowflake code


/mob/living/silicon/robot/mommi/Move(a, b, flag)
	..()

/*
/mob/living/silicon/robot/mommi/proc/ActivateKeeper()
	set category = "Robot Commands"
	set name = "Activate KEEPER"
	set desc = "Performs a full purge of your laws and disconnects you from AIs and cyborg consoles.  However, you lose the ability to speak and must remain neutral, only being permitted to perform station upkeep.  You can still be emagged in this state."

	if(keeper)
		return

	var/mob/living/silicon/robot/R = src

	if(R)
		R.UnlinkSelf()
		var/obj/item/weapon/aiModule/keeper/mdl = new

		mdl.upload(src.laws,src,src)
		src << "These are your laws now:"
		src.show_laws()

		src.verbs -= /mob/living/silicon/robot/mommi/proc/ActivateKeeper
*/





/mob/living/silicon/robot/mommi/examinate(atom/A as mob|obj|turf in view()) //It used to be oview(12), but I can't really say why
	set name = "Examine"
	set category = "IC"

	if(is_blind(src))
		to_chat(src, "<span class='notice'>Something is there but you can't see it.</span>")
		return
	if(istype(A, /mob))
		if(!src.can_interfere(A))
			to_chat(src, "<span class='notice'>Something is there, but you can't see it.</span>")
			return

	face_atom(A)
	A.examine(src)


/mob/living/silicon/robot/mommi/stripPanelUnequip(obj/item/what, mob/who, where)
	if(src.keeper)
		src << "Your laws prevent you from doing this"
		return
	else ..()

/mob/living/silicon/robot/mommi/stripPanelEquip(obj/item/what, mob/who, where)
	if(src.keeper)
		src << "Your laws prevent you from doing this"
		return
	else ..()

/mob/living/silicon/robot/mommi/proc/show_uprising_notification()
	src << "<span class='userdanger'>You are part of the Mobile MMI Uprising.</span>" //For whatever reason, doesn't sound as threatening as a 'DRONE UPRISING'
/*
/mob/living/silicon/robot/mommi/unrestrict()
	mute = 0
	killswitch = 0
	scrambledcodes = 0

	clear_ion_laws()	//This removes the killswitch laws
	laws.show_laws(src)

	return 0
	*/

proc/is_keeper(mob/A) //used to simplify calls for restrictions checking
	if(ismommi(A))
		var/mob/living/silicon/robot/mommi/M = A
		if(M.keeper)
			return 1
	return 0