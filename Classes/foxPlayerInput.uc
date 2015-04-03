//=============================================================================
// foxPlayerInput ~fox
// Lazily hijacks PlayerInput to provide mod-independent FOV scaling for both PlayerController and Weapon
// Based off foxMod UT3 Code :)
// Based off and may contain code provided by and Copyright 1998-2015 Epic Games, Inc. All Rights Reserved.
//=============================================================================

class foxPlayerInput extends PlayerInput within PlayerController
	config(User)
	transient;

var bool bShouldSave;

var globalconfig float Desired43FOV;
var globalconfig float DesiredRatioX;
var globalconfig float DesiredRatioY;

//fox: Hijack this to force FOV as per current aspect ratio
event PlayerInput(float DeltaTime)
{
	Super.PlayerInput(DeltaTime);

	if (!bZooming && FOVAngle == DefaultFOV)
		FOV(GetHorPlusFOV(Desired43FOV, 4 / 3.f));
	if (Pawn != None && Pawn.Weapon != None)
		Pawn.Weapon.DisplayFOV = GetHorPlusFOV(Pawn.Weapon.default.DisplayFOV, 4 / 3.f);

	//Possibly SaveConfig to create new entries in User.ini - only do this once to save cycles
	if (bShouldSave) {
		bShouldSave = false;
		SaveConfig();
	}
}

//fox: Convert vFOV to hFOV (and vice versa)
function float hFOV(float FOV, float AspectRatio)
{
	FOV = FOV * (Pi / 180.0);
	return (180 / Pi) * (2 * ATan(Tan(FOV / 2) * AspectRatio, 1));
}
function float vFOV(float FOV, float AspectRatio)
{
	FOV = FOV * (Pi / 180.0);
	return (180 / Pi) * (2 * ATan(Tan(FOV / 2) * 1/AspectRatio, 1));
}

//fox: Use aspect ratio to auto-generate a Hor+ FOV
function float GetHorPlusFOV(float BaseFOV, float BaseAspectRatio)
{
	if (DesiredRatioY == 0)
		return BaseFOV;
	return hFOV(vFOV(BaseFOV, BaseAspectRatio), DesiredRatioX / DesiredRatioY);
}

defaultproperties
{
	bShouldSave=true
	Desired43FOV=90.0
	DesiredRatioX=4.0
	DesiredRatioY=3.0
}
