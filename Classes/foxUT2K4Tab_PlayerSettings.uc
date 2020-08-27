//==============================================================================
//	Description
//
//	Created by Ron Prestenback
//	© 2003, Epic Games, Inc.  All Rights Reserved
//==============================================================================
class foxUT2K4Tab_PlayerSettings extends UT2K4Tab_PlayerSettings;

//fox: Don't populate our widescreen-adjusted FOV in this menu (this will be corrected in-game after)
function InternalOnLoadINI(GUIComponent Sender, string s)
{
	local PlayerController PC;

	Super.InternalOnLoadINI(Sender, s);

	PC = PlayerOwner();
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
	local PlayerController PC;

	Super.SaveSettings();

	PC = PlayerOwner();
	PC.ConsoleCommand("SetFOV" @ iFOV);
}

defaultproperties
{
}
