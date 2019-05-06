/obj/screen/robot/mommi
	icon = 'icons/mob/screen_cyborg.dmi'

/obj/screen/robot/mommi/module
	name = "mommi module"
	icon_state = "nomod"

/obj/screen/robot/mommi/module/Click()
	if(..())
		return
	var/mob/living/silicon/robot/mommi/R = usr
	if(!R.picked)
		R.choose_icon()

	if(R.module.type != /obj/item/robot_module)
		R.hud_used.toggle_show_mommi_modules()
		return 1

/obj/screen/robot/mommi/module1
	name = "module1"
	icon_state = "inv1"

/obj/screen/robot/mommi/module1/Click()
	if(istype(usr, /mob/living/silicon/robot/mommi))
		var/mob/living/silicon/robot/mommi/M = usr
		M.toggle_module(INV_SLOT_TOOL)

/obj/screen/robot/mommi/hat
	name = "hat"
	icon = 'icons/mob/screen_plasmafire.dmi'
	icon_state = "head"

/obj/screen/robot/mommi/hat/Click(location, control, params)
	var/mob/living/silicon/robot/mommi/M = usr
	if(istype(usr, /mob/living/silicon/robot/mommi))
		M.attack_ui(SLOT_HEAD)
/*
/obj/screen/robot/mommi/module3
	name = "module3"
	icon_state = "inv3"

/obj/screen/robot/mommi/module3/Click()
	var/mob/living/silicon/robot/R = usr
	R.toggle_module(3)
*/

/obj/screen/robot/mommi/radio
	name = "radio"
	icon_state = "radio"

/obj/screen/robot/mommi/radio/Click()
	var/mob/living/silicon/robot/mommi/M = usr
	if (ismommi(M))
		M.radio.interact(M)

/obj/screen/robot/mommi/store
	name = "store"
	icon_state = "store"

/obj/screen/robot/mommi/store/Click()
	var/mob/living/silicon/robot/mommi/M = usr
	if (ismommi(M))
		M.uneq_active()


/datum/hud/mommi/New(mob/owner)
	..()
	var/mob/living/silicon/robot/mommi/mymobM = owner
	var/obj/screen/using


//Radio
	using = new /obj/screen/robot/mommi/radio()
	using.screen_loc = ui_borg_radio
	static_inventory += using

//Module select

	using = new /obj/screen/robot/mommi/module1()
	using.screen_loc = ui_inv1
	using.name = "tool_slot"
	static_inventory += using
	mymobM.inv_tool = using

//End of module select

//Photography stuff
/*
	using = new /obj/screen/ai/image_take()
	using.screen_loc = ui_borg_camera
	static_inventory += using

	using = new /obj/screen/ai/image_view()
	using.screen_loc = ui_borg_album
	static_inventory += using
*/

//Sec/Med HUDs
	using = new /obj/screen/ai/sensors()
	using.screen_loc = ui_borg_sensor
	static_inventory += using


	//Intent
	using = new /obj/screen/act_intent()
	using.icon = 'icons/mob/screen_cyborg.dmi'
	using.icon_state = mymob.a_intent
	using.screen_loc = ui_borg_intents
	static_inventory += using
	action_intent = using


	using = new /obj/screen/robot/mommi/hat()
	using.name = "head"
	using.screen_loc = ui_borg_thrusters
	static_inventory += using
	mymobM.hat_slot = using

	using = new/obj/screen/language_menu //They can't speak, but it's there if they get emagged/ratvared
	using.screen_loc = ui_borg_language_menu
	static_inventory += using

//Headlamp control
	using = new /obj/screen/robot/lamp()
	using.screen_loc = ui_borg_lamp
	static_inventory += using
	mymobM.lamp_button = using



	//Health
	healths = new /obj/screen/healths/robot()
	infodisplay += healths


	//Installed Module
	using = new /obj/screen/robot/mommi/module()
	using.screen_loc = ui_inv3
	static_inventory += using

//Store
	module_store_icon = new /obj/screen/robot/mommi/store()
	module_store_icon.screen_loc = ui_borg_store

	pull_icon = new /obj/screen/pull()
	pull_icon.icon = 'icons/mob/screen_cyborg.dmi'
	pull_icon.update_icon(mymob)
	pull_icon.screen_loc = ui_borg_pull
	hotkeybuttons += pull_icon


	zone_select = new /obj/screen/zone_sel/robot()
	zone_select.update_icon(mymob)
	static_inventory += zone_select

	return


/datum/hud/proc/toggle_show_mommi_modules()
	if(!ismommi(mymob)) return

	var/mob/living/silicon/robot/mommi/r = mymob

	r.shown_robot_modules = !r.shown_robot_modules
	update_robot_modules_display()

/datum/hud/mommi/update_robot_modules_display(mob/viewer) //mostly copypasted from robot one
	if(!ismommi(mymob)) return

	var/mob/living/silicon/robot/mommi/R = mymob

	var/mob/screenmob = viewer || R

	if(!R.module)
		return

	if(!R.client)
		return

	if(R.shown_robot_modules && screenmob.hud_used.hud_shown)
		//Modules display is shown
		screenmob.client.screen += module_store_icon	//"store" icon

		if(!R.module.modules)
			to_chat(usr, "<span class='danger'>Selected module has no modules to select</span>")
			return

		if(!R.robot_modules_background)
			return

		var/display_rows = CEILING(length(R.module.get_inactive_modules()) / 8, 1)
		R.robot_modules_background.screen_loc = "CENTER-4:16,SOUTH+1:7 to CENTER+3:16,SOUTH+[display_rows]:7"
		screenmob.client.screen += R.robot_modules_background

		var/x = -4	//Start at CENTER-4,SOUTH+1
		var/y = 1

		for(var/atom/movable/A in R.module.get_inactive_modules())
			//Module is not currently active
			screenmob.client.screen += A
			if(x < 0)
				A.screen_loc = "CENTER[x]:16,SOUTH+[y]:7"
			else
				A.screen_loc = "CENTER+[x]:16,SOUTH+[y]:7"
			A.layer = ABOVE_HUD_LAYER
			A.plane = ABOVE_HUD_PLANE

			x++
			if(x == 4)
				x = -4
				y++

	else
		//Modules display is hidden

		for(var/atom/A in R.module.get_inactive_modules())
			//Module is not currently active
			screenmob.client.screen -= A
		R.shown_robot_modules = 0
		screenmob.client.screen -= R.robot_modules_background
	persistent_inventory_update(R)


/datum/hud/mommi/persistent_inventory_update(mob/viewer)
	if(!mymob)
		return
	var/mob/living/silicon/robot/mommi/M = mymob

	var/mob/screenmob = viewer || M

	if(screenmob.hud_used)
		if(screenmob.hud_used.hud_shown)
			var/obj/item/I = M.tool_state
			if(I)
				I.screen_loc = ui_inv1
				screenmob.client.screen += I
				I.layer = ABOVE_HUD_LAYER
				I.plane = ABOVE_HUD_PLANE
			I = M.hat
			if(M.hat)
				I.screen_loc = ui_borg_thrusters
				screenmob.client.screen += I
				I.layer = ABOVE_HUD_LAYER
				I.plane = ABOVE_HUD_PLANE

		else
			for(var/obj/item/I in M.contents)
				screenmob.client.screen -= I
