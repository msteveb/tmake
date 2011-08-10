/* Takes a boolean and a variable number of element id arguments.
 * Shows or hides the elements according to 'show'
 */
function show_hide_elements(show)
{
	var display = show ? '' : 'none';

	for (var i=1; i < arguments.length; i++) {
		var id = document.getElementById(arguments[i]);
		if (id) {
			id.style.display = display;
		}
	}
}

/* Takes a variable number of element ids.
 * Sets each element to be enabled.
 */
function enable_elements()
{
	for (var i=0; i < arguments.length; i++) {
		var id = document.getElementById(arguments[i]);
		if (id) {
			id.disabled = false;
		}
	}
}

/* Takes a variable number of element ids.
 * Sets each element to be disabled.
 */
function disable_elements()
{
	for (var i=0; i < arguments.length; i++) {
		var id = document.getElementById(arguments[i]);
		if (id) {
			id.disabled = true;
		}
	}
}

function set_select_options(sel, selected, options)
{
	/* Remove existing children */
	if (sel.hasChildNodes()) {
		while (sel.childNodes.length >= 1) {
			sel.removeChild(sel.firstChild);
		}
	}

	/* Add new children */
	for (var i=0; i < options.length; i+=2) {
		var o = document.createElement('option');
		o.value = options[i];
		o.text = options[i+1];
		try {
			sel.add(o, null);
		} catch (err) {
			/* Poor old IE6 and IE7 don't know about the second parameter */
			sel.add(o);
		}
		if (o.value == selected) {
			o.selected = true;
		}
	}
}

function set_style_rule(selector, rule, value)
{
	/* The first stylesheet is always basic.css, so skip it */
	for (var i=1; i < document.styleSheets.length; i++) {
		var cssrules = document.styleSheets[i].cssRules;
		for (var j=0; j < cssrules.length; j++) {
			if (cssrules[j].selectorText == selector) {
				cssrules[j].style[rule] = value;
			}
		}
	}
}

function show_hide_inline_help(show)
{
	if (show) {
		set_style_rule('.subhelp', 'display', '');
		set_style_rule('.inlinepagehelp', 'display', '');
		set_style_rule('.elemrowhelp', 'border-top-style', 'solid');
	}
	else {
		set_style_rule('.subhelp', 'display', 'none');
		set_style_rule('.inlinepagehelp', 'display', 'none');
		set_style_rule('.elemrowhelp', 'border-top-style', 'none');
	}
}

/* ajax helper - GET only */
function xmlhttpGet(url, on_done_function) {
	var xmlHttpReq = false;
	var self = this;
	// Mozilla/Safari
	if (window.XMLHttpRequest) {
		self.xmlHttpReq = new XMLHttpRequest();
	}
	// IE
	else if (window.ActiveXObject) {
		self.xmlHttpReq = new ActiveXObject("Microsoft.XMLHTTP");
	}
	self.xmlHttpReq.open('GET', url, true);
	self.xmlHttpReq.onreadystatechange = function() {
		if (self.xmlHttpReq.readyState == 4) {
			on_done_function(self.xmlHttpReq.responseText);
		}
	}
	self.xmlHttpReq.send(null);
	return 1;
}

/* firmware upgrade */
function upgrade_get_status() {
	xmlhttpGet('upgradestatus', upgrade_status_callback);
}

function upgrade_set_status(str) {
	document.getElementById('upgradestatus').innerHTML = str;
}

function upgrade_set_rebooting() {
	upgrade_set_status('Standby, system is rebooting...' + reboottimeout);
	if (reboottimeout-- <= 0) {
		/* Done: refresh the page */
		window.location = window.location.href;
	}
	else {
		setTimeout(upgrade_set_rebooting, 1000);
	}
}

function table_cell_width_percent(percent)
{
	/* IE doesn't like table cells with a width of 0% or 100% */
	if (percent == 0) {
		percent = 1;
	}
	else if (percent == 100) {
		percent = 99;
	}
	return percent + '%';
}

function upgrade_status_callback(str) {
	var result = str.split(' ');
	var percent = 0;

	if (result[1] == 'OK') {
		percent = result[3];
		first++;
		if (percent >= 95) {
			percent = 100;
		}
	} else if (first && str == '') {
		percent = 100;
	}

	document.getElementById('done').width = table_cell_width_percent(percent);
	document.getElementById('togo').width = table_cell_width_percent(100 - percent);

	if (percent == 100) {
		document.getElementById('upgradeheader').innerHTML = 'Rebooting';
		upgrade_set_rebooting();
	}
	else {
		if (percent > 0) {
			upgrade_set_status('Upgrade in progress, please wait...');
		}
		/* Update progress every second */
		setTimeout(upgrade_get_status, 1000);
	}
}

// vim: se ts=4:
