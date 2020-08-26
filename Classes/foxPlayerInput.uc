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
var Vector CachedPlayerViewOffset;

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
	&& Pawn.Weapon.SmallViewOffset != CachedPlayerViewOffset) {
		Pawn.Weapon.DisplayFOV = GetHorPlusFOV(Pawn.Weapon.default.DisplayFOV, 4 / 3.f);

		//Fix bad DisplayFOV calculation in Pawn.CalcDrawOffset()
		//PlayerViewOffset is unfortunately set every Weapon.RenderOverlays() call - so hijack SmallViewOffset
		if (Outer.bSmallWeapons) {
			Pawn.Weapon.SmallEffectOffset = Pawn.Weapon.default.SmallEffectOffset;
			CachedPlayerViewOffset = Pawn.Weapon.default.SmallViewOffset;
		}
		else {
			Pawn.Weapon.SmallEffectOffset = Pawn.Weapon.default.EffectOffset;
			CachedPlayerViewOffset = Pawn.Weapon.default.PlayerViewOffset;
		}
		CachedPlayerViewOffset *= Pawn.Weapon.DisplayFOV / Pawn.Weapon.default.DisplayFOV;
		Pawn.Weapon.SmallViewOffset = CachedPlayerViewOffset;
		class'PlayerController'.default.bSmallWeapons = true;
	}
}

function HandleWideHUD()
{
	local string WideHUDType;
	local class<HUD> HudClass;
	local class<Scoreboard> ScoreboardClass;

	switch (Level.Game.HUDType) {
		case "XInterface.HudCDeathMatch": WideHUDType = "HUDFix.HudWDeathMatch"; break;
		case "XInterface.HudCTeamDeathMatch": WideHUDType = "HUDFix.HudWTeamDeathMatch"; break;
		case "XInterface.HudCCaptureTheFlag": WideHUDType = "HUDFix.HudWCaptureTheFlag"; break;
		case "Onslaught.ONSHUDOnslaught": Level.Game.HUDType = "HUDFix.ONSHUDWOnslaught"; break;
		case "SkaarjPack.HudInvasion": WideHUDType = "HUDFix.HudWInvasion"; break;
		case "UT2k4Assault.HUD_Assault": Level.Game.HUDType = "HUDFix.HUDWAssault"; break;
		case "BonusPack.HudLMS": WideHUDType = "HUDFix.HudWLMS"; break;
		case "XInterface.HudCDoubleDomination": WideHUDType = "HUDFix.HudWDoubleDomination"; break;
		case "XInterface.HudCBombingRun": WideHUDType = "HUDFix.HudWBombingRun"; break;
		case "BonusPack.HudMutant": WideHUDType = "HUDFix.HudWMutant"; break;
		//case "Jailbreak.JBInterfaceHUD": WideHUDType = "HUDFix.JBWInterfaceHUD"; break;
	}
	if (WideHUDType != "") {
		HudClass = class<HUD>(DynamicLoadObject(WideHUDType, class'Class'));
		ScoreboardClass = class<Scoreboard>(DynamicLoadObject(Level.Game.ScoreBoardType, class'Class'));
		if (HudClass != None && ScoreboardClass != None)
			Outer.ClientSetHUD(HudClass, ScoreboardClass);
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
