class foxUT2K4Tab_PlayerSettings extends UT2K4Tab_PlayerSettings;

//fox: Don't populate our widescreen-adjusted FOV in this menu (this will be corrected in-game after)
function InternalOnLoadINI(GUIComponent Sender, string s)
{
	Super.InternalOnLoadINI(Sender, s);

	switch (GUIMenuOption(Sender)) {
		case nu_FOV:
			//iFOV = PC.DefaultFOV; //This is our current wide FOV
			iFOV = class'foxPlayerInput'.default.Desired43FOV; //This is our normal "desired" 4:3 FOV
			iFOVD = iFOV;
			nu_FOV.SetValue(iFOV);
			break;
	}
}

//fox: Both FOV and bSmallWeapons could be (re)applied depending on bSave, so notify foxPlayerInput here
//This keeps us from ending up with wild FOVs or non-corrected weapons (e.g. Sniper Rifle clipping)
function SaveSettings()
{
	Super.SaveSettings();

	//Set our "desired" 4:3 FOV via SetFOV
	PlayerOwner().ConsoleCommand("SetFOV" @ iFOV);

	//Also explicitly save value in case we're not in-game and foxPlayerInput isn't set for Engine.PlayerController
	class'foxPlayerInput'.default.Desired43FOV = iFOV;
	class'foxPlayerInput'.static.StaticSaveConfig();
}
