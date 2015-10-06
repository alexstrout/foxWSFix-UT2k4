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
var float CachedFOV;
var Weapon CachedWeapon;

var globalconfig float Desired43FOV;
var globalconfig float DesiredRatioX;
var globalconfig float DesiredRatioY;

//fox: Hijack this to force FOV per current aspect ratio - done every frame as a lazy catch-all since we're only hooking clientside PlayerInput
event PlayerInput(float DeltaTime)
{
	Super.PlayerInput(DeltaTime);

	//Possibly SaveConfig to create new entries in User.ini - only do this once to save cycles
	//This will also set our CachedFOV so we don't recalculate it every frame
	if (bShouldSave) {
		bShouldSave = false;
		CachedFOV = GetHorPlusFOV(Desired43FOV, 4 / 3.f);
		SaveConfig();
	}

	//Set our FOV if we're not zooming
	if (!bZooming && FOVAngle == DefaultFOV)
		FOV(CachedFOV);

	//Set weapon FOV as well - only need to do once per weapon switch
	//Note: CachedWeapon defaults to None, but still need a None check in case some mod or whatever sets Weapon to None (who knows)
	if (Pawn != None && Pawn.Weapon != None && Pawn.Weapon != CachedWeapon) {
		CachedWeapon = Pawn.Weapon;
		CachedWeapon.DisplayFOV = GetHorPlusFOV(CachedWeapon.default.DisplayFOV, 4 / 3.f);
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

//fox: In-game set functions
exec function SetFOV(float FOV)
{
	Desired43FOV = FOV;
	bShouldSave = true;
}
exec function SetRatio(string Ratio)
{
	local array<string> R;

	Split(Ratio, "x", R);
	DesiredRatioX = float(R[0]);
	DesiredRatioY = float(R[1]);
	bShouldSave = true;
}

defaultproperties
{
	bShouldSave=true
	CachedFOV=90.0
	CachedWeapon=None
	Desired43FOV=90.0
	DesiredRatioX=4.0
	DesiredRatioY=3.0
}
