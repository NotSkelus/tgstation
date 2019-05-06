/obj/item/implant/mindshield
	name = "loyalty implant"
	desc = "Makes you loyal or such."
	activated = 0

/obj/item/implant/mindshield/get_data()
	var/dat = {"<b>Implant Specifications:</b><BR>
				<b>Name:</b> Nanotrasen Employee Management Implant<BR>
				<b>Life:</b> Ten years.<BR>
				<b>Important Notes:</b> Personnel injected with this device tend to be much more loyal to the company.<BR>
				<HR>
				<b>Implant Details:</b><BR>
				<b>Function:</b> Contains a small pod of nanobots that protects the host's mental functions from manipulation.<BR>
				<b>Special Features:</b> Will prevent and cure most forms of brainwashing.<BR>
				<b>Integrity:</b> Implant will last so long as the nanobots are inside the bloodstream."}
	return dat


/obj/item/implant/mindshield/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	if(..())
		if(!target.mind)
			target.add_trait(TRAIT_MINDSHIELD, "implant")
			target.sec_hud_set_implants()
			return TRUE

		if(target.mind.has_antag_datum(/datum/antagonist/brainwashed))
			target.mind.remove_antag_datum(/datum/antagonist/brainwashed)

		var/datum/antagonist/hivemind/host = target.mind.has_antag_datum(/datum/antagonist/hivemind) //Releases the target from mind control beforehand
		if(host)
			var/datum/mind/M = host.owner
			if(M)
				var/obj/effect/proc_holder/spell/target_hive/hive_control/the_spell = locate(/obj/effect/proc_holder/spell/target_hive/hive_control) in M.spell_list
				if(the_spell && the_spell.active)
					the_spell.release_control()

		if(target.mind.has_antag_datum(/datum/antagonist/rev/head) || target.mind.has_antag_datum(/datum/antagonist/hivemind) || target.mind.unconvertable)
			if(!silent)
				target.visible_message("<span class='warning'>[target] seems to resist the implant!</span>", "<span class='warning'>You feel the corporate tendrils of Nanotrasen try to invade your mind!</span>")
			removed(target, 1)
			qdel(src)
			return FALSE

		var/datum/antagonist/hivevessel/woke = target.is_wokevessel()
		if(is_hivemember(target))
			for(var/datum/antagonist/hivemind/hive in GLOB.antagonists)
				if(hive.hivemembers.Find(target))
					var/mob/living/carbon/C = hive.owner.current.get_real_hivehost()
					if(C)
						C.apply_status_effect(STATUS_EFFECT_HIVE_TRACKER, target, woke?TRACKER_AWAKENED_TIME:TRACKER_MINDSHIELD_TIME)
						target.apply_status_effect(STATUS_EFFECT_HIVE_TRACKER, C, TRACKER_DEFAULT_TIME)
						if(C.mind) //If you were using mind control, too bad
							C.apply_status_effect(STATUS_EFFECT_HIVE_RADAR)
							to_chat(C, "<span class='assimilator'>We detect a surge of psionic energy from a far away vessel before they disappear from the hive. Whatever happened, there's a good chance they're after us now.</span>")
			to_chat(target, "<span class='assimilator'>You hear supernatural wailing echo throughout your mind as you are finally set free. Deep down, you can feel the lingering presence of those who enslaved you... as can they!</span>")
			target.apply_status_effect(STATUS_EFFECT_HIVE_RADAR)
			remove_hivemember(target)

		if(woke)
			woke.one_mind.remove_member(target.mind)
			target.mind.remove_antag_datum(/datum/antagonist/hivevessel)

		var/datum/antagonist/rev/rev = target.mind.has_antag_datum(/datum/antagonist/rev)
		if(rev)
			rev.remove_revolutionary(FALSE, user)
		if(!silent)
			if(target.mind in SSticker.mode.cult)
				to_chat(target, "<span class='warning'>You feel the corporate tendrils of Nanotrasen try to invade your mind!</span>")
			else
				to_chat(target, "<span class='notice'>You feel a surge of loyalty towards Nanotrasen.</span>")
		target.add_trait(TRAIT_MINDSHIELD, "implant")
		target.sec_hud_set_implants()
		return TRUE
	return FALSE

/obj/item/implant/mindshield/removed(mob/target, silent = FALSE, special = 0)
	if(..())
		if(isliving(target))
			var/mob/living/L = target
			L.remove_trait(TRAIT_MINDSHIELD, "implant")
			L.sec_hud_set_implants()
		if(target.stat != DEAD && !silent)
			to_chat(target, "<span class='boldnotice'>You feel a sense of liberation as Nanotrasen's grip on your mind fades away.</span>")
		return 1
	return 0

/obj/item/implanter/mindshield
	name = "implanter (Loyalty)"
	imp_type = /obj/item/implant/mindshield

/obj/item/implantcase/mindshield
	name = "implant case - 'Loyalty'"
	desc = "A glass case containing a loyalty implant."
	imp_type = /obj/item/implant/mindshield
