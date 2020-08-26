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
var byte CachedInventoryGroup;
var byte CachedGroupOffset;
var bool CachedSmallWeapons;

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
		HandleWideHUD();
	}

	//Set our FOV if we're not zooming - like FixFOV function but using CachedFOV instead of explicit defaults
	//Note: Older version just called FOV but that actually calls SaveConfig every run! Oops
	if (!bZooming && FOVAngle == DefaultFOV) {
		FOVAngle = CachedFOV;
		DesiredFOV = CachedFOV;
		DefaultFOV = CachedFOV;
	}

	//Set weapon FOV as well - only need to do once per weapon switch
	//Note: We can't cache / compare the weapon due to memory fault, but we can cache / compare the FOV
	if (Pawn != None && Pawn.Weapon != None
	&& (
		Pawn.Weapon.InventoryGroup != CachedInventoryGroup
		|| Pawn.Weapon.GroupOffset != CachedGroupOffset
		|| Outer.bSmallWeapons != CachedSmallWeapons
	))
		ApplyWeaponFOV(Pawn.Weapon);
}

function ApplyWeaponFOV(Weapon Weap)
{
	//First set the new FOV...
	Weap.DisplayFOV = GetHorPlusFOV(Weap.default.DisplayFOV, 4 / 3.f);

	//And remember our selected weapon
	CachedInventoryGroup = Weap.InventoryGroup;
	CachedGroupOffset = Weap.GroupOffset;

	//Fix bad DisplayFOV calculation in Pawn.CalcDrawOffset()
	//PlayerViewOffset is unfortunately set every Weapon.RenderOverlays() call - so hijack SmallViewOffset!
	CachedSmallWeapons = Outer.bSmallWeapons;
	if (CachedSmallWeapons) {
		if (Weap.default.SmallEffectOffset != vect(0,0,0))
			Weap.SmallEffectOffset = Weap.default.SmallEffectOffset;
		else
			Weap.SmallEffectOffset = Weap.default.EffectOffset
				+ Weap.default.PlayerViewOffset - Weap.default.SmallViewOffset;
		if (Weap.default.SmallViewOffset != vect(0,0,0))
			Weap.SmallViewOffset = Weap.default.SmallViewOffset;
		else
			Weap.SmallViewOffset = Weap.default.PlayerViewOffset;
	}
	else {
		Weap.SmallEffectOffset = Weap.default.EffectOffset;
		Weap.SmallViewOffset = Weap.default.PlayerViewOffset;
	}
	Weap.SmallViewOffset *= Weap.DisplayFOV / Weap.default.DisplayFOV;
	class'PlayerController'.default.bSmallWeapons = true;
}

function HandleWideHUD()
{
	local string WideHUDType;
	local class<HUD> HudClass;

	log("foxPlayerInput" @ GetURLMap() @ Outer.myHUD.Class @ Outer.myHUD.ScoreBoard.Class);
	switch (Outer.myHUD.Class) {
		case class'HudCDeathMatch': WideHUDType = "HUDFix.HudWDeathMatch"; break;
		case class'HudCTeamDeathMatch': WideHUDType = "HUDFix.HudWTeamDeathMatch"; break;
		case class'HudCCaptureTheFlag': WideHUDType = "HUDFix.HudWCaptureTheFlag"; break;
		case class'ONSHUDOnslaught': WideHUDType = "HUDFix.ONSHUDWOnslaught"; break;
		case class'HudInvasion': WideHUDType = "HUDFix.HudWInvasion"; break;
		case class'HUD_Assault': WideHUDType = "HUDFix.HUDWAssault"; break;
		case class'HudLMS': WideHUDType = "HUDFix.HudWLMS"; break;
		case class'HudCDoubleDomination': WideHUDType = "HUDFix.HudWDoubleDomination"; break;
		case class'HudCBombingRun': WideHUDType = "HUDFix.HudWBombingRun"; break;
		case class'HudMutant': WideHUDType = "HUDFix.HudWMutant"; break;
	}
	if (WideHUDType != "") {
		HudClass = class<HUD>(DynamicLoadObject(WideHUDType, class'Class'));
		if (HudClass != None)
			Outer.ClientSetHUD(HudClass, Outer.myHUD.ScoreBoard.Class);
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
	Desired43FOV=90.0
	DesiredRatioX=4.0
	DesiredRatioY=3.0
}
