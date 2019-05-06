/obj/item/robot_module/mommi
	name = "mobile mmi robot module"
	allow_riding = FALSE
	cyborg_base_icon = "mommi" //produces the icon for the borg and, if no special_light_key is set, the lights
	special_light_key = null//if we want specific lights, use this instead of copying lights in the dmi
	basic_modules = list(
		/obj/item/construction/rcd/borg,
		/obj/item/pipe_dispenser,
		/obj/item/extinguisher,
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/screwdriver/cyborg,
		/obj/item/wrench/cyborg,
		/obj/item/crowbar/cyborg,
		/obj/item/wirecutters/cyborg,
		/obj/item/multitool/cyborg,
		/obj/item/t_scanner,
		/obj/item/analyzer,
		/obj/item/geiger_counter/cyborg,
		/obj/item/areaeditor/blueprints/cyborg,
		/obj/item/electroadaptive_pseudocircuit,
		/obj/item/stack/sheet/metal/cyborg,
		/obj/item/stack/sheet/glass/cyborg,
		/obj/item/stack/sheet/rglass/cyborg,
		/obj/item/storage/bag/ore/cyborg,
		/obj/item/pickaxe/drill/cyborg,
		/obj/item/t_scanner/adv_mining_scanner,
		/obj/item/stack/cable_coil/cyborg)
	emag_modules = list(/obj/item/borg/stun)
	ratvar_modules = list(
		/obj/item/clockwork/slab/cyborg/mommi,
		/obj/item/clockwork/replica_fabricator/cyborg)
	magpulsing = TRUE

/obj/item/robot_module/mommi/do_transform_animation()
	return