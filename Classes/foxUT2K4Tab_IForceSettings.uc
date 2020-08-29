class foxUT2K4Tab_IForceSettings extends UT2K4Tab_IForceSettings;

//fox: Fix DoubleClickTime not applying in-game via special ConsoleCommand
function SaveSettings()
{
	Super.SaveSettings();
	PlayerOwner().ConsoleCommand("foxPlayerInputApplyDoubleClickTime");
}
