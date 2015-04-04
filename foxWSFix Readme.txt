foxWSFix v1.0
Hor+ FOV widescreen support for Unreal Tournament 2004
By fox

Thanks to Steam user Anonanon for suggesting this, as well as Azareal for creating the HUD Scaling Fix mutator: https://forums.epicgames.com/threads/971852-HUD-Scaling-Fix-%28RC3%29

==========
 Features
==========
-- Hor+ FOV support - automatically scales FOV based off aspect ratio and "Desired FOV" setting, configurable via INI or in-game console commands
-- First-person weapons rendered correctly for wider aspect ratios
-- Entirely client-side - compatible with all mods! (see "Other Notes" section below)

=====================
 Install / Uninstall
=====================
First, navigate to the System folder and open up User.ini (e.g. "C:\Games\UT2004\System\User.ini"), making backups first if desired. Find the following line:

    InputClass=Class'Engine.PlayerInput'

Replace every instance of it with the following: (";" denotes a comment and comments out the default line so it is not read by UT)

    ;InputClass=Class'Engine.PlayerInput'
    InputClass=Class'foxWSFix.foxPlayerInput'

Note that there are several InputClass definitions - be sure to change all of them!

To uninstall, simply reverse your changes.

=======
 Usage
=======
foxWSFix can be configured via the following console commands:

    SetFOV <fov>
     * <fov> - new FOV to use, given as a 4:3 ratio FOV (90 @ 4:3 == 106.2602 @ 16:9, etc.)
        e.g. SetFOV 90

    SetRatio <ratio>
     * <ratio> - new Aspect Ratio to use, given as ##x## like SetRes
        e.g. SetRatio 16x9
             SetRatio 1366x768 (just entering in your resolution is fine!)

FOV and Ratio default to 90 and 4x3 respectively, which is UT's default setup.

Unfortunately, Aspect Ratio can not be reliably determined automatically with foxWSFix's current implementation, so it must be set manually. Sorry!

=============
 Other Notes
=============
Should be compatible with all mods, provided they don't use a custom PlayerInput class (they probably won't).

Does not fix HUD stretching, as that would have required more aggressive changes that were a little beyond the scope of this project.
However, Azareal over at the Epic Games Forum has a "HUD Scaling Fix" mutator here: https://forums.epicgames.com/threads/971852-HUD-Scaling-Fix-%28RC3%29

foxWSFix stores its settings in User.ini as such:

    [foxWSFix.foxPlayerInput]
    Desired43FOV=90.000000 ;Desired 4:3 FOV (set via SetFOV in-game)
    DesiredRatioX=4.000000 ;Desired X Ratio (set via SetRatio in-game)
    DesiredRatioY=3.000000 ;Desired Y Ratio (set via SetRatio in-game)

============
 Known Bugs
============
None currently! :)

========================
 Feedback / Source Code
========================
This is a tiny project I started on April 03, 2015, completed within a few hours based on knowledge from working on foxMod for UT3.

If you have any questions or feedback, I'd love to hear them! Feel free to leave a comment on:
Steam   http://steamcommunity.com/id/foxBoxInc/
ModDB   http://www.moddb.com/members/foxunit01/

Source code for the project is included in the "Src" folder so you can laugh at my silly code.
If you would like to build the mod source code, there are convenient batch files provided in the Src folder.
Feel free to use any portion of the project so long as it is properly attributed.

And of course, thanks for trying the mod!
~fox

=========
 Changes
=========
v1.0 (04/03/15):
-- Initial release.
