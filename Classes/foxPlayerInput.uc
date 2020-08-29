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
var globalconfig bool bCorrectMouseSensitivity;

struct native WideHUDMapStruct
{
	var class HUDClass;
	var string WideHUD;
};
var globalconfig array<WideHUDMapStruct> WideHUDMap;

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
		CorrectMouseSensitivity();
		return;
	}

	//Attempt to set an accurate FOV for our aspect ratio
	if (DefaultFOV != CachedDefaultFOV) {
		CachedDefaultFOV = GetHorPlusFOVClamped(Desired43FOV);
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
	if (Pawn == None || Level.TimeSeconds - Pawn.SpawnTime < 0.5) {
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
	local int i;

	for (i = 0; i < WideHUDMap.Length; i++) {
		if (myHUD.Class == WideHUDMap[i].HUDClass) {
			WideHUDType = WideHUDMap[i].WideHUD;
			break;
		}
	}
	if (WideHUDType != "") {
		HudClass = class<HUD>(DynamicLoadObject(WideHUDType, class'Class'));
		if (HudClass != None) {
			Log("foxWSFix: foxPlayerInput replaced " $ myHUD.Class $ " with " $ HudClass);
			ClientSetHUD(HudClass, myHUD.ScoreBoard.Class);
			return;
		}
		Log("foxWSFix: foxPlayerInput no replacement specified for " $ myHUD.Class);
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
function float GetHorPlusFOVClamped(float BaseFOV)
{
	return FClamp(GetHorPlusFOV(BaseFOV), 1, 170);
}

//fox: Match mouse sensitivity to 90 FOV sensitivity, allowing it to be independent of our aspect ratio
function CorrectMouseSensitivity()
{
	if (!bCorrectMouseSensitivity)
		return;
	MouseSensitivity = class'PlayerInput'.default.MouseSensitivity
		/ (GetHorPlusFOVClamped(Desired43FOV) * 0.01111); //"Undo" PlayerInput FOVScale
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
	CorrectMouseSensitivity();
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
	CachedInventoryGroup=255
	CachedGroupOffset=255
	Desired43FOV=90f
	bCorrectMouseSensitivity=true
	/* WideHUDMap(0)=(HUDClass=class'HudCDeathMatch',WideHUD="HUDFix.HudWDeathMatch")
	WideHUDMap(1)=(HUDClass=class'HudCTeamDeathMatch',WideHUD="HUDFix.HudWTeamDeathMatch")
	WideHUDMap(2)=(HUDClass=class'HudCCaptureTheFlag',WideHUD="HUDFix.HudWCaptureTheFlag")
	WideHUDMap(3)=(HUDClass=class'ONSHUDOnslaught',WideHUD="HUDFix.ONSHUDWOnslaught")
	WideHUDMap(4)=(HUDClass=class'HudInvasion',WideHUD="HUDFix.HudWInvasion")
	WideHUDMap(5)=(HUDClass=class'HUD_Assault',WideHUD="HUDFix.HUDWAssault")
	WideHUDMap(6)=(HUDClass=class'HudLMS',WideHUD="HUDFix.HudWLMS")
	WideHUDMap(7)=(HUDClass=class'HudCDoubleDomination',WideHUD="HUDFix.HudWDoubleDomination")
	WideHUDMap(8)=(HUDClass=class'HudCBombingRun',WideHUD="HUDFix.HudWBombingRun")
	WideHUDMap(9)=(HUDClass=class'HudMutant',WideHUD="HUDFix.HudWMutant") */
	WideHUDMap(0)=(HUDClass=class'HudCDeathMatch',WideHUD="foxWSFix.foxWideHudCDeathMatch")
}
