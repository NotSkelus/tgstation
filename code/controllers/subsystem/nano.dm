SUBSYSTEM_DEF(nanoui)
	name = "nanoui"
	wait = 9
	flags = SS_NO_INIT
	priority = FIRE_PRIORITY_TGUI //same priority for now
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/list/currentrun = list()
	var/list/open_uis = list() // A list of open UIs, grouped by src_object and ui_key.
	var/list/processing_uis = list() // A list of processing UIs, ungrouped.
//	var/basehtml // The HTML base used for all UIs.
	var/list/asset_files = list()

/datum/controller/subsystem/nanoui/PreInit()
//	basehtml = file2text('nanoui/nanoui.html')
	loadfiles()

/datum/controller/subsystem/nanoui/proc/loadfiles()
	//Generate list of files to send to client for nano UI's
	var/list/nano_asset_dirs = list(\
		"nano/css/",\
		"nano/images/",\
		"nano/js/",\
		"nano/templates/"\
	)
	var/list/filenames = null
	for (var/path in nano_asset_dirs)
		filenames = flist(path)
		for(var/filename in filenames)
			//Ignore directories
			if(copytext(filename, length(filename)) != "/")
				if(fexists(path + filename))
					asset_files.Add(fcopy_rsc(path + filename))



/datum/controller/subsystem/nanoui/Shutdown()
	close_all_uis()

/datum/controller/subsystem/nanoui/stat_entry()
	..("P:[processing_uis.len]")

/datum/controller/subsystem/nanoui/fire(resumed = 0)
	if (!resumed)
		src.currentrun = processing_uis.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun

	while(currentrun.len)
		var/datum/nanoui/ui = currentrun[currentrun.len]
		currentrun.len--
		if(ui && ui.user && ui.src_object)
			ui.process()
		else
			processing_uis.Remove(ui)
		if (MC_TICK_CHECK)
			return

