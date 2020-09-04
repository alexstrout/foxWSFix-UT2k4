class foxUT2K4Tab_IForceSettings extends UT2K4Tab_IForceSettings;

//fox: Don't populate our widescreen-adjusted sensitivity in this menu (this will be corrected in-game after)
function InternalOnLoadINI(GUIComponent Sender, string s)
{
	Super.InternalOnLoadINI(Sender, s);

	//Don't use this if it hasn't been set yet
	if (class'foxPlayerInput'.default.Desired43MouseSensitivity == -1f)
		return;

	switch (Sender) {
		case fl_Sensitivity:
			fSens = class'foxPlayerInput'.default.Desired43MouseSensitivity;
			fl_Sensitivity.SetComponentValue(fSens,true);
			break;
	}
}

//fox: Fix DoubleClickTime not applying in-game via special ConsoleCommand
function SaveSettings()
{
	Super.SaveSettings();

	//Work around our double-click time not being applied in-game
	PlayerOwner().ConsoleCommand("foxPlayerInputApplyDoubleClickTime");

	//Also explicitly save value in case we're not in-game and foxPlayerInput isn't set for Engine.PlayerController
	class'foxPlayerInput'.default.Desired43MouseSensitivity = fSens;
	class'foxPlayerInput'.static.StaticSaveConfig();
}
