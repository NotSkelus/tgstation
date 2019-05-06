 /**
  * nanoui
  *
  * /tg/station user interface library
 **/

 /**
  * nanoui datum (represents a UI).
 **/
/datum/nanoui
	var/mob/user // The mob who opened/is using the UI.
	var/datum/src_object // The object which owns the UI.
	var/title // The title of te UI.
	var/ui_key // The ui_key of the UI. This allows multiple UIs for one src_object.
	var/window_id // The window_id for browse() and onclose().
	var/width = 0 // The window width.
	var/height = 0 // The window height
	var/window_options = list( // Extra options to winset().
	  "focus" = FALSE,
	  "titlebar" = TRUE,
	  "can_resize" = TRUE,
	  "can_minimize" = TRUE,
	  "can_maximize" = FALSE,
	  "can_close" = TRUE,
	  "auto_format" = FALSE
	)
	// the list of stylesheets to apply to this ui
	var/list/stylesheets = list()
	// the list of javascript scripts to use for this ui
	var/list/scripts = list()
	var/interface // The interface (template) to be used for this UI.
	var/autoupdate = 1 // Update the UI every X MC ticks.
	var/autoupdate_tick = 0 //counter for that stuff above
	var/content = "<div id='mainTemplate'></div>"
	var/list/initial_data // The data (and datastructure) used to initialize the UI.
	var/status = UI_INTERACTIVE // The status/visibility of the UI.
	var/datum/ui_state/state = null // Topic state used to determine status/interactability.
	var/datum/nanoui/master_ui // The parent UI.
	var/list/datum/nanoui/children = list() // Children of this UI.
	var/titlebar = TRUE
	var/custom_browser_id = FALSE
	var/ui_screen = "home"

 /**
  * public
  *
  * Create a new UI.
  *
  * required user mob The mob who opened/is using the UI.
  * required src_object datum The object or datum which owns the UI.
  * required ui_key string The ui_key of the UI.
  * required interface string The template used to render the UI.
  * optional title string The title of the UI.
  * optional width int The window width.
  * optional height int The window height.
  * optional master_ui datum/nanoui The parent UI.
  * optional state datum/ui_state The state used to determine status.
  *
  * return datum/nanoui The requested UI.
 **/
/datum/nanoui/New(mob/user, datum/src_object, ui_key, interface, title, width = 0, height = 0, datum/nanoui/master_ui = null, datum/ui_state/state = GLOB.default_state, browser_id = null, ticks_for_autoupdate = 1)
	src.user = user
	src.src_object = src_object
	src.ui_key = ui_key
	src.window_id = browser_id ? browser_id : "[REF(src_object)]-[ui_key]"
	src.custom_browser_id = browser_id ? TRUE : FALSE
	src.autoupdate = ticks_for_autoupdate
	set_interface(interface)

	if(title)
		src.title = sanitize(title)
	if(width)
		src.width = width
	if(height)
		src.height = height

	src.master_ui = master_ui
	if(master_ui)
		master_ui.children += src
	src.state = state

	var/datum/asset/assets = get_asset_datum(/datum/asset/simple/nanoui)
	assets.send(user)

	add_common_assets()

 /**
  * Use this proc to add assets which are common to all nano uis
  *
  * @return nothing
  */
/datum/nanoui/proc/add_common_assets()
	add_script("libraries.min.js") // The jQuery library
	add_script("nano_config.js") // The NanoConfig JS, this is used to store configuration values.
	add_script("nano_update.js") // The NanoUpdate JS, this is used to receive updates and apply them.
	add_script("nano_base_helpers.js") // The NanoBaseHelpers JS, this is used to set up template helpers which are common to all templates
	add_stylesheet("shared.css") // this CSS sheet is common to all UIs
	add_stylesheet("icons.css") // this CSS sheet is common to all UIs



 /**
  * Add a CSS stylesheet to this UI
  *
  * @param file string The name of the CSS file from /nano/css (e.g. "my_style.css")
  *
  * @return nothing
  */
/datum/nanoui/proc/add_stylesheet(file)
	stylesheets.Add(file)

 /**
  * Add a JavsScript script to this UI
  *
  * @param file string The name of the JavaScript file from /nano/js (e.g. "my_script.js")
  *
  * @return nothing
  */
/datum/nanoui/proc/add_script(file)
	scripts.Add(file)


 /**
  * public
  *
  * Open this UI (and initialize it with data).
 **/
/datum/nanoui/proc/open()
	if(!user || !user.client)
		return // Bail if there is no client.

	update_status(push = 0) // Update the window status.
	if(status < UI_UPDATE)
		return // Bail if we're not supposed to open.

	if(!initial_data)
		set_initial_data(src_object.ui_data_empty(user)) // Get the UI data.

	var/window_size = ""
	if(width && height) // If we have a width and height, use them.
		window_size = "size=[width]x[height];"

	user << browse(get_html(), "window=[window_id];[window_size][list2params(window_options)]") // Open the window.
	if (!custom_browser_id)
		winset(user, window_id, "on-close=\"nanoclose [REF(src)]\"") // Instruct the client to signal UI when the window is closed.
	SSnanoui.on_open(src)

 /**
  * public
  *
  * Reinitialize the UI.
  * (Possibly with a new interface and/or data).
  *
  * optional template string The name of the new interface.
  * optional data list The new initial data.
 **/
/datum/nanoui/proc/reinitialize(interface, list/data)
	if(interface)
		set_interface(interface) // Set a new interface.
	if(data)
		set_initial_data(data) // Replace the initial_data.
	open()

 /**
  * public
  *
  * Close the UI, and all its children.
 **/
/datum/nanoui/proc/close()
	user << browse(null, "window=[window_id]") // Close the window.
	src_object.ui_close()
	SSnanoui.on_close(src)
	for(var/datum/nanoui/child in children) // Loop through and close all children.
		child.close()
	children.Cut()
	state = null
	master_ui = null
	qdel(src)

 /**
  * public
  *
  * Sets the browse() window options for this UI.
  *
  * required window_options list The window options to set.
 **/
/datum/nanoui/proc/set_window_options(list/window_options)
	src.window_options = window_options

 /**
  * public
  *
  * Set the style for this UI.
  *
  * required style string The new UI style.
 **/

/datum/nanoui/proc/set_style(style)
	src.stylesheets += lowertext(style)

 /**
  * public
  *
  * Set the interface (template) for this UI.
  *
  * required interface string The new UI interface.
 **/
/datum/nanoui/proc/set_interface(interface) //like add_template of the old nanoUI but with only main
	src.interface = "[lowertext(interface)].tmpl"

 /**
  * public
  *
  * Enable/disable auto-updating of the UI.
  *
  * required state bool Enable/disable auto-updating.
 **/
/datum/nanoui/proc/set_autoupdate(state = 1)
	autoupdate = state

 /**
  * private
  *
  * Set the data to initialize the UI with.
  * The datastructure cannot be changed by subsequent updates.
  *
  * optional data list The data/datastructure to initialize the UI with.
 **/

 /**
  * Set the initial data for the ui. This is vital as the data structure set here cannot be changed when pushing new updates.
  *
  * @param data /list The list of data for this ui
  *
  * @return nothing
  */
/datum/nanoui/proc/set_initial_data(list/data)
	if(isnull(data))
		data = list()
	initial_data = list()
	initial_data["ui"] = get_default_data()
	initial_data["data"] = data

 /**
  * Add default data to the data being sent to the ui.
  *
  * @param
  *
  * @return /list data to add
  */
/datum/nanoui/proc/get_default_data()
	. = list(
			"status" = status,
			"user" = list("name" = user.name),
			"screen" = 	ui_screen,
			)
	return


 /**
  * Return the HTML header content for this UI
  *
  * @return string HTML header content
  */
/datum/nanoui/proc/get_header()
	var/head_content = ""

	for (var/filename in scripts)
		head_content += "<script type='text/javascript' src='[filename]'></script> "

	for (var/filename in stylesheets)
		head_content += "<link rel='stylesheet' type='text/css' href='[filename]'> "

	var/templatel_data[0]

	templatel_data["main"] = interface; //force

	var/template_data_json = "{}" // An empty JSON object
	if (templatel_data.len > 0)
		template_data_json = json_encode(templatel_data)

	var/initial_data_json = "{}" // An empty JSON object
	if (initial_data.len > 0)

		initial_data_json = json_encode(initial_data)

	var/url_parameters_json = json_encode(list("src" = "\ref[src]"))

	return {"<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
	<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
	<head>
		<script type='text/javascript'>
			function receiveUpdateData(jsonString)
			{
				// We need both jQuery and NanoUpdate to be able to recieve data
				// At the moment any data received before those libraries are loaded will be lost
				if (typeof NanoUpdate != 'undefined' && typeof jQuery != 'undefined')
				{
					NanoUpdate.receiveUpdateData(jsonString);
				}
			}
		</script>
		[head_content]
	</head>
	<body scroll=auto data-url-parameters='[url_parameters_json]' data-template-data='[template_data_json]' data-initial-data='[initial_data_json]'>
		<div id='uiWrapper'>
			[title ? "<div id='uiTitleWrapper'><div id='uiStatusIcon' class='icon24 uiStatusGood'></div><div id='uiTitle'>[title]</div><div id='uiTitleFluff'></div></div>" : ""]
			<div id='uiContent'>
				<div id='uiNoJavaScript'>Initiating...</div>
	"}

 /**
  * Return the HTML footer content for this UI
  *
  * @return string HTML footer content
  */
/datum/nanoui/proc/get_footer()

	return {"
			</div>
		</div>
	</body>
</html>"}

 /**
  * Return the HTML for this UI
  *
  * @return string HTML for the UI
  */
/datum/nanoui/proc/get_html(var/inline)
	return {"
	[get_header()]
	[content]
	[get_footer()]
	"}

 /*

/datum/nanoui/proc/get_html(var/inline)
	var/html
	html = SSnanoui.basehtml

	//Allow the src object to override the html if needed
	html = src_object.ui_base_html(html)
	//Strip out any remaining custom tags that are used in ui_base_html
	html = replacetext(html, "<!--customheadhtml-->", "")

	// Poplate HTML with JSON if we're supposed to inline.
	if(inline)
		html = replacetextEx(html, "{}", get_json(initial_data))


	//Setup for nanoui stuff, including styles
	html = replacetextEx(html, "\[ref]", "[REF(src)]")
	html = replacetextEx(html, "\[style]", style)
	return html
*/
 /**
  * private
  *
  * Get the config data/datastructure to initialize the UI with.
  *
  * return list The config data.
 **/
/datum/nanoui/proc/get_config_data()
	var/list/config_data = list(
			"title"     = title,
			"status"    = status,
			"screen"	= ui_screen,
			"interface" = interface,
			"window"    = window_id,
			"ref"       = "[REF(src)]",
			"user"      = list(
				"name"  = user.name,
				"ref"   = "[REF(user)]"
			),
			"srcObject" = list(
				"name" = "[src_object]",
				"ref"  = "[REF(src_object)]"
			),
			"titlebar" = titlebar
		)
	return config_data

 /**
  * private
  *
  * Package the data to send to the UI, as JSON.
  * This includes the UI data and config_data.
  *
  * return string The packaged JSON.
 **/
/datum/nanoui/proc/get_json(list/data)
	var/list/json_data = list()
	json_data["ui"] = get_default_data()
	if(isnull(data))
		data = list()
	json_data["data"] = data

	// Generate the JSON.
	var/json = json_encode(json_data)
	// Strip #255/improper.

	json = replacetext(json, "\proper", "")
	json = replacetext(json, "\improper", "")
	return json

 /**
  * private
  *
  * Handle clicks from the UI.
  * Call the src_object's ui_act() if status is UI_INTERACTIVE.
  * If the src_object's ui_act() returns 1, update all UIs attacked to it.
 **/
/datum/nanoui/Topic(href, href_list)
	if(user != usr)
		return // Something is not right here.
	var/action = href_list["action"]
	var/params = href_list; params -= "action"


	if(user?.client?.nanodebug)
		to_chat(user, "SENT: [href]")

	switch(action)
		if("nano:view")
			if(params["screen"])
				ui_screen = params["screen"]
			SSnanoui.update_uis(src_object)
		else
			update_status(push = 0) // Update the window state.
			if(src_object.ui_act(action, params, src, state)) // Call ui_act() on the src_object.
				SSnanoui.update_uis(src_object) // Update if the object requested it.

 /**
  * private
  *
  * Update the UI.
  * Only updates the data if update is true, otherwise only updates the status.
  *
  * optional force bool If the UI should be forced to update.
 **/
/datum/nanoui/process(force = 0)
	var/datum/host = src_object.ui_host(user)
	if(!src_object || !host || !user) // If the object or user died (or something else), abort.
		close()
		return
	if(autoupdate_tick < autoupdate)
		autoupdate_tick++
	if(status && (force || (autoupdate && autoupdate_tick == autoupdate) ) )
		update() // Update the UI if the status and update settings allow it.
	else
		update_status(push = 1) // Otherwise only update status.

 /**
  * private
  *
  * Push data to an already open UI.
  *
  * required data list The data to send.
  * optional force bool If the update should be sent regardless of state.
 **/
/datum/nanoui/proc/push_data(data, force = 0)
	update_status(push = 0) // Update the window state.
	if(status <= UI_DISABLED && !force)
		close() //no point in having a broken template hanging around
		return // Cannot update UI, we have no visibility.

	// Send the new JSON to the update() Javascript function.
	if(user?.client?.nanodebug)
		to_chat(user, get_json(data))
	user << output(list2params(list(get_json(data))), "[custom_browser_id ? "[window_id].[custom_browser_id]" : "[window_id].browser"]:receiveUpdateData")


 /**
  * private
  *
  * Updates the UI by interacting with the src_object again, which will hopefully
  * call try_ui_update on it.
  *
  * optional force_open bool If force_open should be passed to ui_interact.
 **/
/datum/nanoui/proc/update(force_open = FALSE)
	src_object.ui_interact(user, ui_key, src, force_open, master_ui, state)

 /**
  * private
  *
  * Update the status/visibility of the UI for its user.
  *
  * optional push bool Push an update to the UI (an update is always sent for UI_DISABLED).
 **/
/datum/nanoui/proc/update_status(push = 0)
	var/status = src_object.ui_status(user, state)
	if(master_ui)
		status = min(status, master_ui.status)

	set_status(status, push)
	if(status == UI_CLOSE)
		close()

 /**
  * private
  *
  * Set the status/visibility of the UI.
  *
  * required status int The status to set (UI_CLOSE/UI_DISABLED/UI_UPDATE/UI_INTERACTIVE).
  * optional push bool Push an update to the UI (an update is always sent for UI_DISABLED).
 **/
/datum/nanoui/proc/set_status(status, push = 0)
	if(src.status != status) // Only update if status has changed.
		if(src.status == UI_DISABLED)
			src.status = status
			if(push)
				update()
		else
			src.status = status
			if(status == UI_DISABLED || push) // Update if the UI just because disabled, or a push is requested.
				push_data(null, force = 1)

/datum/nanoui/proc/set_titlebar(value)
	titlebar = value
