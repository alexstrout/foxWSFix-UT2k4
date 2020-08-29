foxWSFix v2.0.0
Widescreen FOV and HUD support for Unreal Tournament 2004
By fox

Thanks to Steam user Anonanon for originally suggesting this, as well as Azarael for creating the HUD Scaling Fix mutator:
https://forums.epicgames.com/threads/971852-HUD-Scaling-Fix-%28RC3%29

==========
 Features
==========
-- Widescreen FOV support based on aspect ratio and in-game FOV setting, including vehicles and weapon zoom
-- Widescreen HUD support with aspect-correct rendering, based on Azarael's HUD Scaling Fix Mutator
-- Aspect-correct rendering for first-person weapons
-- Entirely client-side - no mutators required

=====================
 Install / Uninstall
=====================
First, navigate to the System folder and open up User.ini (e.g. "C:\Games\UT2004\System\User.ini"), making backups first if desired.
Find the following section:

	[XGame.xPlayer]

Under this section, find the following line:

	InputClass=Class'Engine.PlayerInput'

And replace it with the following: (";" denotes a comment and comments out the default line so it is not read by UT)

	;InputClass=Class'Engine.PlayerInput'
	InputClass=Class'foxWSFix.foxPlayerInput'

Note that there are several InputClass definitions - be sure to change this for [XGame.xPlayer] only!

Next, open up ut2004.ini (e.g. "C:\Games\UT2004\System\ut2004.ini")
Find the following section:

	[Engine.Engine]

Under this section, find the following line:

	GUIController=GUI2K4.UT2K4GUIController

And replace it with the following:

	;GUIController=GUI2K4.UT2K4GUIController
	GUIController=foxWSFix.foxUT2K4GUIController

To uninstall, simply reverse your changes.

=======
 Usage
=======
Once installed, foxWSFix requires no configuration. However, you may need to manually adjust your resolution to your native resolution.
This can be done via the game's built-in console command:

	SetRes <resolution>
	 * <resolution> - new resolution to use, given as ##x##
		e.g. SetRes 1920x1080
			 SetRes 3360x1440

In-game FOV can be adjusted via the menu as normal, or via a new console command:

	SetFOV <fov>
	 * <fov> - new FOV to use, given as a 4:3 ratio FOV (90 @ 4:3 == 106.2602 @ 16:9, etc.)
		e.g. SetFOV 90

=============
 Other Notes
=============
The FOV changes should be compatible with all mods, provided they don't use a custom PlayerInput class (they probably won't).

However, widescreen HUDs are provided for vanilla HUDs only.

foxWSFix stores its settings in User.ini as such:

	[foxWSFix.foxPlayerInput]
	Desired43FOV=90.000000
	bCorrectMouseSensitivity=True
	WideHUDMap=(HudClass=Class'UT2k4Assault.HUD_Assault',WideHUD="foxWSFix.foxWideHUD_Assault")
	WideHUDMap=(HudClass=Class'XInterface.HudCBombingRun',WideHUD="foxWSFix.foxWideHudCBombingRun")
	WideHUDMap=(HudClass=Class'XInterface.HudCCaptureTheFlag',WideHUD="foxWSFix.foxWideHudCCaptureTheFlag")
	WideHUDMap=(HudClass=Class'XInterface.HudCDeathmatch',WideHUD="foxWSFix.foxWideHudCDeathMatch")
	WideHUDMap=(HudClass=Class'XInterface.HudCDoubleDomination',WideHUD="foxWSFix.foxWideHudCDoubleDomination")
	WideHUDMap=(HudClass=Class'XInterface.HudCTeamDeathMatch',WideHUD="foxWSFix.foxWideHudCTeamDeathMatch")
	WideHUDMap=(HudClass=Class'SkaarjPack.HUDInvasion',WideHUD="foxWSFix.foxWideHUDInvasion")
	WideHUDMap=(HudClass=Class'BonusPack.HudLMS',WideHUD="foxWSFix.foxWideHudLMS")
	WideHUDMap=(HudClass=Class'BonusPack.HudMutant',WideHUD="foxWSFix.foxWideHudMutant")
	WideHUDMap=(HudClass=Class'Onslaught.ONSHUDOnslaught',WideHUD="foxWSFix.foxWideONSHUDOnslaught")

Additional WideHUDMap lines may be added or replaced for custom HUD replacements. (e.g. to use HUDFix's UT2k3 widescreen HUDs)

============
 Known Bugs
============
Some HUDs still have elements that don't quite scale correctly, particularly with ultra-wide (32:9 or greater) ratios.
	(e.g. Assault Rifle grenade counter, on-screen objectives, etc.)
Unfortunately, many of these are drawn by objects outside of the HUD itself, making them difficult to correct with client-side changes.
However, these are generally pretty minor, and the main HUD elements should always scale correctly.

========================
 Feedback / Source Code
========================
If you have any questions or feedback, feel free to leave a comment on Steam:
https://steamcommunity.com/app/13230/discussions/0/611702631218438023/

Source code for the project is included in the "Src" folder so you can laugh at my silly code. Also available at: https://www.taraxis.com/foxwsfix-ut2k4
If you would like to build the mod source code, there is a convenient batch file provided in the Src folder.
Just add the following to the [Editor.EditorEngine] section in ut2004.ini:

	EditPackages=foxWSFix

And of course, thanks for trying the mod!
~fox

=========
 Changes
=========
v2.0 (???):
-- Configurable client-side HUD loading, no mutator required
-- Integration / reimplementation of Azarael's HUD Scaling Fix HUDs, fixing a few minor bugs (such as Adrenaline meter not scaling in CTF)
-- Automatic aspect ratio determination (SetRatio removed, no longer needed)
-- FOV adjustment now applies to weapon zoom etc. and is driven by menu FOV setting (or SetFOV as before)
-- Fixed issue where input settings weren't saved when adjusted in-game
-- Mouse sensitivity now matches 4:3 sensitivity regardless of aspect ratio (still affected by further FOV changes like zoom)

v1.11 (10/07/15):
-- Fixed optimization-related general protection fault

v1.1 (10/07/15):
-- Optimizations to avoid recalculating view FOV and weapon FOV every frame (oops!)
-- Don't use FOV function as that calls SaveConfig every run, leading to performance issues (oops!)

v1.0 (04/03/15):
-- Initial release.
