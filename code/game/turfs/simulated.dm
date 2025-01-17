/turf/simulated
	name = "station"

	var/thermite = 0
	var/can_thermite = 1
	oxygen = MOLES_O2STANDARD
	nitrogen = MOLES_N2STANDARD
	var/to_be_destroyed = 0 //Used for fire, if a melting temperature was reached, it will be destroyed
	var/max_fire_temperature_sustained = 0 //The max temperature of the fire which it was subjected to
	var/can_exist_under_lattice = 0 //If 1, RemoveLattice() is not called when a turf is changed to this.

	var/datum/custom_painting/advanced_graffiti
	var/image/advanced_graffiti_overlay

/turf/simulated/proc/render_advanced_graffiti(var/mob/user)
	if (!advanced_graffiti)
		return FALSE
	overlays -= advanced_graffiti_overlay
	advanced_graffiti_overlay = image(advanced_graffiti.render_on(icon(icon, icon_state)))
	advanced_graffiti_overlay.layer = ADVANCED_GRAFFITI_LAYER
	//advanced_graffiti_overlay.SwapColor("#aaaaaaff", "#ffffff00")
	overlays += advanced_graffiti_overlay

/turf/simulated/New()
	..()

	if(istype(loc, /area/chapel))
		holy = 1
	levelupdate()

/turf/simulated/proc/AddTracks(var/typepath,var/bloodDNA,var/comingdir,var/goingdir,var/bloodcolor=DEFAULT_BLOOD,var/luminous=FALSE)
	var/obj/effect/decal/cleanable/blood/tracks/tracks = locate(typepath) in src
	if(!tracks)
		tracks = new typepath(src)
	tracks.AddTracks(bloodDNA,comingdir,goingdir,bloodcolor,luminous)

/turf/simulated/Entered(atom/A, atom/OL)
	if(movement_disabled && usr.ckey != movement_disabled_exception)
		to_chat(usr, "<span class='warning'>Movement is admin-disabled.</span>")//This is to identify lag problems

		return

	if (istype(A,/mob/living/carbon))
		var/mob/living/carbon/M = A
		if(!M.on_foot())
			return ..()
		if(istype(M, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = M

			// Tracking blood
			var/list/bloodDNA = null
			var/bloodcolor=""

			// Do we have shoes?
			if(H.shoes)
				var/obj/item/clothing/shoes/S = H.shoes
				if(S.track_blood && S.blood_DNA)
					bloodDNA   = S.blood_DNA
					bloodcolor = S.blood_color
					S.track_blood = max(round(S.track_blood - 1, 1),0)
			else
				if(H.track_blood && H.feet_blood_DNA)
					bloodDNA   = H.feet_blood_DNA
					bloodcolor = H.feet_blood_color
					H.track_blood = max(round(H.track_blood - 1, 1),0)

			if (bloodDNA)
				AddTracks(H.get_footprint_type(),bloodDNA,H.dir,0,bloodcolor,H.luminous_feet()) // Coming
				var/turf/simulated/from = get_step(H,opposite_dirs[H.dir])
				if(istype(from) && from)
					from.AddTracks(H.get_footprint_type(),bloodDNA,0,H.dir,bloodcolor,H.luminous_feet()) // Going

			bloodDNA = null

			// Floorlength braids?  Enjoy your tripping.
			if(H.my_appearance.h_style && !H.check_hidden_head_flags(HIDEHEADHAIR))
				var/datum/sprite_accessory/hair_style = hair_styles_list[H.my_appearance.h_style]
				if(hair_style && (hair_style.flags & HAIRSTYLE_CANTRIP))
					if(H.m_intent == "run" && prob(5))
						if (H.Slip(4, 5))
							step(H, H.dir)
							to_chat(H, "<span class='notice'>You tripped over your hair!</span>")
	..()

//returns 1 if made bloody, returns 0 otherwise
/turf/simulated/add_blood(var/mob/living/carbon/human/M)
	if (!..())
		return FALSE

	for(var/obj/effect/decal/cleanable/blood/B in contents)
		if(!B.blood_DNA[M.dna.unique_enzymes])
			B.blood_DNA[M.dna.unique_enzymes] = M.dna.b_type
			B.virus2 = virus_copylist(M.virus2)
		had_blood = TRUE
		return TRUE //we bloodied the floor

	blood_splatter(src,M,1)
	had_blood = TRUE
	return TRUE //we bloodied the floor

// Only adds blood on the floor -- Skie
/turf/simulated/proc/add_blood_floor(var/mob/living/carbon/M)
	if (ishuman(M))
		add_blood(M)
	else if(istype(M, /mob/living/carbon/monkey))
		blood_splatter(src,M,1)
	else if( istype(M, /mob/living/carbon/alien ))
		var/obj/effect/decal/cleanable/blood/xeno/this = new /obj/effect/decal/cleanable/blood/xeno(src)
		this.blood_DNA["UNKNOWN BLOOD"] = "X*"
	else if( istype(M, /mob/living/silicon/robot ))
		new /obj/effect/decal/cleanable/blood/oil(src)
