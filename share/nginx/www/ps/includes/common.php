<?php
/**
 *	This file is part of PsychoStats.
 *
 *	Written by Jason Morriss <stormtrooper@psychostats.com>
 *	Copyright 2008 Jason Morriss
 *
 *	PsychoStats is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	PsychoStats is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with PsychoStats.  If not, see <http://www.gnu.org/licenses/>.
 *
 *	Version: $Id: common.php 565 2008-10-10 12:27:02Z lifo $
 *
 *	Common entry point for all pages within PsychoStats.
 *      This file will setup the environment and initialize all objects needed.
 *      All pages must include this file first and foremost.
**/

// verify the page was viewed from a valid entry point.
if (!defined("PSYCHOSTATS_PAGE")) die("Unauthorized access to " . basename(__FILE__));

//define("PS_DEBUG", true);
//define("PS_THEME_DEV", true);

// Global PsychoStats version and release date. 
// These are updated automatically by the release packaging script 'rel.pl'.
define("PS_VERSION", '3.2');
define("PS_RELEASE_DATE", 'today');

// define the directory where we live. Since this file is always 1 directory deeper
// we know the parent directory is the actual root. DOCUMENT_ROOT.
define("PS_ROOTDIR", dirname(dirname(__FILE__)));

// enable some sane error reporting (ignore notice errors) and turn off the magic. 
// we also want to to disable E_STRICT.
// error_reporting(E_ALL & ~E_NOTICE & ~E_DEPRECATED); 
error_reporting(0);
set_magic_quotes_runtime(0);
/**/
ini_set('display_errors', 'On');
ini_set('log_errors', 'On');
/**/

// disable automatic compression since we allow the admin specify this with
// our own handler.
ini_set('zlib.output_compression', 'Off');

// setup global timer so we can show the 0.0000 benchmark on pages.
$TIMER = null;
if (!defined("NO_TIMER")) {
	require_once(PS_ROOTDIR . "/includes/class_timer.php");
	$TIMER = new Timer();
}

// IIS does not have REQUEST_URI defined (apache specific).
// This URI is handy in certain pages so we create it if needed.
if (empty($_SERVER['REQUEST_URI'])) {
	$_SERVER['REQUEST_URI'] = $_SERVER['SCRIPT_NAME'];
	if (!empty($_SERVER['QUERY_STRING'])) {
		$_SERVER['REQUEST_URI'] .= '?' . $_SERVER['QUERY_STRING'];
	}
}

// read in all of our required libraries for basic functionality!
require_once(PS_ROOTDIR . "/includes/functions.php");
require_once(PS_ROOTDIR . "/includes/class_DB.php");
require_once(PS_ROOTDIR . "/includes/class_PS.php");
require_once(PS_ROOTDIR . "/includes/class_CMS.php");

// load the basic config
$dbtype = $dbhost = $dbport = $dbname = $dbuser = $dbpass = $dbtblprefix = '';
require_once(PS_ROOTDIR . "/config.php");

// Initialize our global variables for PsychoStats. 
// Lets be nice to the global Name Space.
$ps		= null;				// global PsychoStats object
$cms 		= null;				// global PsychoCMS object
$PHP_SELF 	= $_SERVER['PHP_SELF'];		// this is used so much we make sure it's global
// Sanitize PHP_SELF and avoid XSS attacks.
// We use the constant in places we know we'll be outputting $PHP_SELF to the user
define(SAFE_PHP_SELF, htmlentities($_SERVER['PHP_SELF'], ENT_QUOTES, 'UTF-8'));

// start PS object; all $dbxxxx variables are loaded from config.php
#$ps = new PS(array(
// $ps = PsychoStats::create(array(
$PsychoDBS= new PsychoStats();
$ps = $PsychoDBS->create(array(
	'fatal'		=> 0,
	'dbtype'	=> $dbtype,
	'dbhost'	=> $dbhost,
	'dbport'	=> $dbport,
	'dbname'	=> $dbname,
	'dbuser'	=> $dbuser,
	'dbpass'	=> $dbpass,
	'dbtblprefix'	=> $dbtblprefix
));

// initialize some defaults if no pre-set values are present for required directories and urls
$t =& $ps->conf['theme']; //shortcut
if (empty($t['script_url'])) {
	$t['script_url'] = dirname($_SERVER['SCRIPT_NAME']); //dirname($PHP_SELF);
	if (defined("PSYCHOSTATS_ADMIN_PAGE") or defined("PSYCHOSTATS_SUBPAGE")) {
		$t['script_url'] = dirname($t['script_url']);
	}
}
// template directory is figured out here now, instead of leaving it null for theme class so that the admin
// pages can properly detect the main theme directory.
if (empty($t['template_dir'])) {
	$t['template_dir'] = catfile(PS_ROOTDIR, 'themes');
}
if (empty($t['root_img_dir'])) $t['root_img_dir'] = catfile(PS_ROOTDIR, 'img');
if (empty($t['root_img_url'])) $t['root_img_url'] = catfile(rtrim($t['script_url'], '/\\'), 'img');
if (empty($t['overlays_dir'])) $t['overlays_dir'] = catfile($t['root_img_dir'], 'overlays');
if (empty($t['overlays_url'])) $t['overlays_url'] = catfile($t['root_img_url'], 'overlays');
if (empty($t['weapons_dir'])) $t['weapons_dir'] = catfile($t['root_img_dir'], 'weapons');
if (empty($t['weapons_url'])) $t['weapons_url'] = catfile($t['root_img_url'], 'weapons');
if (empty($t['roles_dir'])) $t['roles_dir'] = catfile($t['root_img_dir'], 'roles');
if (empty($t['roles_url'])) $t['roles_url'] = catfile($t['root_img_url'], 'roles');
if (empty($t['flags_dir'])) $t['flags_dir'] = catfile($t['root_img_dir'], 'flags');
if (empty($t['flags_url'])) $t['flags_url'] = catfile($t['root_img_url'], 'flags');
if (empty($t['icons_dir'])) $t['icons_dir'] = catfile($t['root_img_dir'], 'icons');
if (empty($t['icons_url'])) $t['icons_url'] = catfile($t['root_img_url'], 'icons');
if (empty($t['maps_dir'])) $t['maps_dir'] = catfile($t['root_img_dir'], 'maps');
if (empty($t['maps_url'])) $t['maps_url'] = catfile($t['root_img_url'], 'maps');

// verify the compile_dir is valid. create it if possible.
// If the dir is not valid try to find a valid directory or at least print out why.
// TODO ...

unset($t);

// start the PS CMS object
$cms = new PsychoCMS(array(
	'dbhandle'	=> &$ps->db,	// reuse db connection
	'plugin_dir'	=> PS_ROOTDIR . '/plugins',
	'site_url'	=> $site_url,	// from config.php
));

$cms->init();

?>
