//=============================================================================
// foxPlayerInput ~fox
// Lazily hijacks PlayerInput to provide mod-independent FOV scaling for both PlayerController and Weapon
// Based off foxMod UT3 Code :)
// Based off and may contain code provided by and Copyright 1998-2015 Epic Games, Inc. All Rights Reserved.
//=============================================================================

class foxPlayerInput extends PlayerInput within PlayerController
	config(User)
	transient;

var bool bDoInit;

var float CachedResScaleX;
var float CachedDefaultFOV;
var float CachedDesiredFOV;

var float CachedASTurretMinPlayerFOV;

var byte CachedInventoryGroup;
var byte CachedGroupOffset;

var globalconfig float Desired43FOV;

const DEGTORAD = 0.01745329251994329576923690768489; //Pi / 180
const RADTODEG = 57.295779513082320876798154814105; //180 / Pi

//fox: Set "desired" 4:3 FOV via console command (and menu if foxUT2K4Tab_PlayerSettings GUI override is active)
exec function SetFOV(float F)
{
	Desired43FOV = F;
	SaveConfig();

	//This will force a new weapon position / FOV calculation
	CachedResScaleX = default.CachedResScaleX;

	//... And this will correct our next FOV
	DesiredFOV = F;
}

//fox: Hijack this to force FOV per current aspect ratio - done every frame as a lazy catch-all since we're only hooking clientside PlayerInput
event PlayerInput(float DeltaTime)
{
	Super.PlayerInput(DeltaTime);

	//Do initialization stuff here, since we don't have init events
	if (bDoInit) {
		bDoInit = false;

		//Write settings to ini if first run
		SaveConfig();

		//Attempt to load widescreen HUDs (if not already done)
		LoadWideHUD();
		return;
	}

	//Detect screen aspect ratio changes and queue FOV / WeaponFOV updates
	if (myHUD.ResScaleX != CachedResScaleX) {
		CachedResScaleX = myHUD.ResScaleX;
		CachedDefaultFOV = default.CachedDefaultFOV;
		CachedDesiredFOV = default.CachedDesiredFOV;
		CachedInventoryGroup = default.CachedInventoryGroup;
		CachedGroupOffset = default.CachedGroupOffset;
		return;
	}

	//Attempt to set an accurate FOV for our aspect ratio
	if (DefaultFOV != CachedDefaultFOV) {
		CachedDefaultFOV = GetHorPlusFOV(Desired43FOV);
		DefaultFOV = CachedDefaultFOV;
		return;
	}

	//Actually set this FOV, including when we're zoomed
	if (DesiredFOV != DefaultFOV
	&& DesiredFOV != CachedDesiredFOV) {
		//Special exception for ASTurrets, due to how they handle zooming
		if (ASTurret(Pawn) != None) {
			FixASTurretFOV(ASTurret(Pawn));
			return;
		}
		CachedDesiredFOV = GetHorPlusFOV(DesiredFOV);
		DesiredFOV = CachedDesiredFOV;
		return;
	}

	//Oh no! Work around weapon respawn bug where position isn't set correctly on respawn
	if (Level.TimeSeconds - Pawn.SpawnTime < 0.5) {
		CachedInventoryGroup = default.CachedInventoryGroup;
		CachedGroupOffset = default.CachedGroupOffset;
		//Bit of a hack, just allow Weapon to process every tick during respawn to minimize "pop"
		//return;
	}

	//Set weapon FOV as well - only need to do once per weapon switch
	//Note: We can't cache / compare the weapon due to memory fault, but we can cache / compare the FOV
	if (Pawn != None && Pawn.Weapon != None
	&& (Pawn.Weapon.InventoryGroup != CachedInventoryGroup || Pawn.Weapon.GroupOffset != CachedGroupOffset))
		ApplyWeaponFOV(Pawn.Weapon);
}
function FixASTurretFOV(ASTurret V)
{
	if (V.MinPlayerFOV != CachedASTurretMinPlayerFOV) {
		CachedASTurretMinPlayerFOV = GetHorPlusFOV(V.default.MinPlayerFOV);
		V.MinPlayerFOV = CachedASTurretMinPlayerFOV;
	}
}
function ApplyWeaponFOV(Weapon Weap)
{
	//First set the new FOV...
	Weap.DisplayFOV = GetHorPlusFOV(Weap.default.DisplayFOV);

	//And remember our selected weapon
	CachedInventoryGroup = Weap.InventoryGroup;
	CachedGroupOffset = Weap.GroupOffset;

	//Fix bad DisplayFOV calculation in Pawn.CalcDrawOffset()
	//PlayerViewOffset is unfortunately set every Weapon.RenderOverlays() call - so hijack SmallViewOffset!
	if (bSmallWeapons) {
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
	class'PlayerController'.default.bSmallWeapons = true; //Must set specifically this for Weapon.RenderOverlays()
}

//fox: Attempt to dynamically load widescreen HUD
function LoadWideHUD()
{
	local string WideHUDType;
	local class<HUD> HudClass;

	switch (myHUD.Class) {
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
			ClientSetHUD(HudClass, myHUD.ScoreBoard.Class);
	}
}

//fox: Convert vFOV to hFOV (and vice versa)
function float hFOV(float BaseFOV, float AspectRatio)
{
	return 2 * ATan(Tan(BaseFOV / 2f) * AspectRatio, 1);
}
function float vFOV(float BaseFOV, float AspectRatio)
{
	return 2 * ATan(Tan(BaseFOV / 2f) / AspectRatio, 1);
}

//fox: Use screen aspect ratio to auto-generate a Hor+ FOV
function float GetHorPlusFOV(float BaseFOV)
{
	return RADTODEG * hFOV(vFOV(BaseFOV * DEGTORAD, 4/3f), (myHUD.ResScaleX * 4) / (myHUD.ResScaleY * 3));
}

//fox: Fix options menu not saving
exec function foxPlayerInputApplyDoubleClickTime()
{
	//Hack - DoubleClickTime setting doesn't apply mid-game, so fix it here
	//Note that foxUT2K4Tab_IForceSettings GUI override must be active for this to fire
	//So we'll include it in the other updates too just in-case
	DoubleClickTime = class'PlayerInput'.default.DoubleClickTime;
}
function UpdateSensitivity(float F)
{
	Super.UpdateSensitivity(F);
	class'PlayerInput'.default.MouseSensitivity = MouseSensitivity;
	class'PlayerInput'.static.StaticSaveConfig();
	foxPlayerInputApplyDoubleClickTime();
}
function UpdateAccel(float F)
{
	Super.UpdateAccel(F);
	class'PlayerInput'.default.MouseAccelThreshold = MouseAccelThreshold;
	class'PlayerInput'.static.StaticSaveConfig();
	foxPlayerInputApplyDoubleClickTime();
}
function UpdateSmoothing(int Mode)
{
	Super.UpdateSmoothing(Mode);
	class'PlayerInput'.default.MouseSmoothingMode = MouseSmoothingMode;
	class'PlayerInput'.static.StaticSaveConfig();
	foxPlayerInputApplyDoubleClickTime();
}
exec function SetSmoothingStrength(float F)
{
	Super.SetSmoothingStrength(F);
	class'PlayerInput'.default.MouseSmoothingStrength = MouseSmoothingStrength;
	class'PlayerInput'.static.StaticSaveConfig();
	foxPlayerInputApplyDoubleClickTime();
}
function InvertMouse(optional string Invert)
{
	Super.InvertMouse(Invert);
	class'PlayerInput'.default.bInvertMouse = bInvertMouse;
	class'PlayerInput'.static.StaticSaveConfig();
	foxPlayerInputApplyDoubleClickTime();
}

defaultproperties
{
	bDoInit=true
	Desired43FOV=90f
	CachedInventoryGroup=255
	CachedGroupOffset=255
}
