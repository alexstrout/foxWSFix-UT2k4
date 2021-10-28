//Lazily hijacks PlayerInput to provide mod-independent FOV scaling for both PlayerController and Weapon
class foxPlayerInput extends PlayerInput within PlayerController
	config(User)
	transient;

var bool bDoInit;
var bool bDoErrorInit;

var float CachedResScaleX;
var float CachedDefaultFOV;
var float CachedDesiredFOV;

var float CachedASTurretMinPlayerFOV;

struct WeaponInfo
{
	var class<Weapon> WeaponClass;
	var vector DefaultPlayerViewOffset;
	var vector DefaultEffectOffset;
	var vector DefaultSmallViewOffset;
	var vector DefaultSmallEffectOffset;
};
var WeaponInfo CachedWeaponInfo;

var globalconfig bool bInputClassErrorCheck;
var globalconfig float Desired43FOV;
var globalconfig bool bCorrectZoomFOV;
var globalconfig bool bCorrectWeaponFOV;
var globalconfig bool bCorrectMouseSensitivity;
var globalconfig float Desired43MouseSensitivity;

struct WideHUDMapStruct
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
}

//fox: Check various PlayerController classes for correct InputClass (and possibly just add it if missing)
function CheckControllerInputClass(class<PlayerController> ControllerClass, string FriendlyName)
{
	if (ControllerClass.default.InputClass != class'foxPlayerInput') {
		ClientMessage("foxWSFix: " $ FriendlyName $ " InputClass is: " $ ControllerClass.default.InputClass);

		//Just add InputClass if missing
		if (ControllerClass.default.InputClass == None) {
			ClientMessage("foxWSFix: Attempting to add missing InputClass line...");
			ControllerClass.default.InputClass = class'foxPlayerInput';
			ControllerClass.static.StaticSaveConfig();
			ClientMessage("foxWSFix: " $ FriendlyName $ " InputClass is now: " $ ControllerClass.default.InputClass);
		}
		ClientMessage("foxWSFix: Please verify User.ini settings!");
	}
}

//fox: Hijack this to force FOV per current aspect ratio - done every frame as a lazy catch-all since we're only hooking clientside PlayerInput
event PlayerInput(float DeltaTime)
{
	Super.PlayerInput(DeltaTime);

	//Do initialization stuff here, since we don't have init events
	if (bDoInit) {
		bDoInit = false;

		//Check for errors if requested
		if (bInputClassErrorCheck
		&& (class'PlayerController'.default.InputClass != class'foxPlayerInput' || class'xPlayer'.default.InputClass != class'foxPlayerInput')) {
			if (bDoErrorInit && Level.TimeSeconds > 3f) {
				bDoErrorInit = false;
				ClientMessage("foxWSFix Warning: One or more errors occurred. To skip this error check, set bInputClassErrorCheck=false in User.ini");
				CheckControllerInputClass(class'PlayerController', "[Engine.PlayerController]");
				CheckControllerInputClass(class'xPlayer', "[XGame.xPlayer]");

				//Write settings to ini once if stuck on errors
				SaveConfig();
			}

			//Just bail here, resetting bDoInit so we don't do our normal hooks
			bDoInit = true;
			return;
		}

		//Write settings to ini if first run
		SaveConfig();

		//Just hook our custom UT2K4SettingsPage tabs here
		class'UT2K4SettingsPage'.default.PanelClass[2] = "foxWSFix.foxUT2K4Tab_PlayerSettings";
		class'UT2K4SettingsPage'.default.PanelClass[4] = "foxWSFix.foxUT2K4Tab_IForceSettings";

		//Attempt to load widescreen HUDs (if not already done)
		LoadWideHUD();
		return;
	}

	//Detect screen aspect ratio changes and queue FOV / WeaponFOV updates
	if (myHUD.ResScaleX != CachedResScaleX) {
		CachedResScaleX = myHUD.ResScaleX;
		CachedDefaultFOV = default.CachedDefaultFOV;
		CachedDesiredFOV = default.CachedDesiredFOV;
		UpdateCachedWeaponInfo(None);
		CorrectMouseSensitivity();
		return;
	}

	//Attempt to set an accurate FOV for our aspect ratio
	if (DefaultFOV != CachedDefaultFOV) {
		CachedDefaultFOV = GetHorPlusFOV(Desired43FOV);
		DefaultFOV = CachedDefaultFOV;
		DesiredFOV = CachedDefaultFOV;
		return;
	}

	//Attempt to do the same when we're zoomed in or out
	if (bCorrectZoomFOV
	&& DesiredFOV != DefaultFOV
	&& DesiredFOV != CachedDesiredFOV) {
		//Special exception for ASTurrets, due to how they handle zooming
		if (ASTurret(Pawn) != None) {
			FixASTurretFOV(ASTurret(Pawn));
			return;
		}
		//Special exception for ASVehicle_SpaceFighter_Human (and Skaarj)
		if (ASVehicle_SpaceFighter_Human(Pawn) != None)
			return;
		CachedDesiredFOV = GetHorPlusFOV(DesiredFOV);
		DesiredFOV = CachedDesiredFOV;
		return;
	}

	//Oh no! Work around weapon respawn bug where position isn't set correctly on respawn
	//Also work around losing CachedWeaponInfo on ServerTravel, due to getting recreated
	if (Pawn == None || Pawn.Weapon == None || Level.bLevelChange) {
		UpdateCachedWeaponInfo(None);
		return;
	}

	//Set weapon FOV as well - only once per weapon
	if (Pawn.Weapon.Class != CachedWeaponInfo.WeaponClass)
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
	local float ScaleFactor;

	//Abort if we don't want to correct visual weapon FOV
	if (!bCorrectWeaponFOV)
		return;

	//First reset our "default default" values before doing anything else
	UpdateCachedWeaponInfo(Weap);

	//Set the new FOV
	Weap.DisplayFOV = GetHorPlusFOV(Weap.default.DisplayFOV);

	//Fix bad DisplayFOV calculation in Pawn.CalcDrawOffset()
	ScaleFactor = Weap.DisplayFOV / Weap.default.DisplayFOV;
	Weap.default.PlayerViewOffset *= ScaleFactor;
	Weap.default.EffectOffset *= ScaleFactor;
	Weap.default.SmallViewOffset *= ScaleFactor;
	Weap.default.SmallEffectOffset *= ScaleFactor;

	//Must set OldMesh's values directly (if applicable)
	if (Weap.bUseOldWeaponMesh) {
		Weap.OldPlayerViewOffset = Weap.default.OldPlayerViewOffset * ScaleFactor;
		Weap.OldSmallViewOffset = Weap.default.OldSmallViewOffset * ScaleFactor;
		Weap.bInitOldMesh = true; //Force a ViewOffset update
	}
}
function UpdateCachedWeaponInfo(Weapon Weap)
{
	if (CachedWeaponInfo.WeaponClass != None) {
		//ClientMessage("UpdateCachedWeaponInfo from " $ CachedWeaponInfo.WeaponClass @ CachedWeaponInfo.WeaponClass.default.PlayerViewOffset);
		CachedWeaponInfo.WeaponClass.default.PlayerViewOffset = CachedWeaponInfo.DefaultPlayerViewOffset;
		CachedWeaponInfo.WeaponClass.default.EffectOffset = CachedWeaponInfo.DefaultEffectOffset;
		CachedWeaponInfo.WeaponClass.default.SmallViewOffset = CachedWeaponInfo.DefaultSmallViewOffset;
		CachedWeaponInfo.WeaponClass.default.SmallEffectOffset = CachedWeaponInfo.DefaultSmallEffectOffset;
	}
	if (Weap == None)
		CachedWeaponInfo.WeaponClass = None;
	else {
		//ClientMessage("UpdateCachedWeaponInfo to " $ Weap.Class @ Weap.default.PlayerViewOffset);
		CachedWeaponInfo.WeaponClass = Weap.Class;
		CachedWeaponInfo.DefaultPlayerViewOffset = Weap.default.PlayerViewOffset;
		CachedWeaponInfo.DefaultEffectOffset = Weap.default.EffectOffset;
		CachedWeaponInfo.DefaultSmallViewOffset = Weap.default.SmallViewOffset;
		CachedWeaponInfo.DefaultSmallEffectOffset = Weap.default.SmallEffectOffset;
	}
}

//fox: Attempt to dynamically load widescreen HUD
function LoadWideHUD()
{
	local class<HUD> HudClass;
	local int i;

	for (i = 0; i < WideHUDMap.Length; i++) {
		if (myHUD.Class == WideHUDMap[i].HUDClass) {
			HudClass = class<HUD>(DynamicLoadObject(WideHUDMap[i].WideHUD, class'Class'));
			if (HudClass != None) {
				Log("foxWSFix: foxPlayerInput replaced " $ myHUD.Class $ " with " $ HudClass);
				ClientSetHUD(HudClass, myHUD.ScoreBoard.Class);
				return;
			}
			Log("foxWSFix: foxPlayerInput tried to replace " $ myHUD.Class $ " with " $ WideHUDMap[i].WideHUD $ " but couldn't load class! Skipping...");
		}
	}
	Log("foxWSFix: foxPlayerInput no replacement specified for " $ myHUD.Class);
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
	return FClamp(RADTODEG * hFOV(vFOV(BaseFOV * DEGTORAD, 4/3f), (myHUD.ResScaleX * 4) / (myHUD.ResScaleY * 3)), 1, 170);
}

//fox: Match mouse sensitivity to 90 FOV sensitivity, allowing it to be independent of our aspect ratio
function CorrectMouseSensitivity()
{
	if (!bCorrectMouseSensitivity)
		return;
	if (Desired43MouseSensitivity <= 0f)
		Desired43MouseSensitivity = class'PlayerInput'.default.MouseSensitivity;
	MouseSensitivity = Desired43MouseSensitivity
		/ (GetHorPlusFOV(90f) * 0.01111); //"Undo" PlayerInput FOVScale
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

	Desired43MouseSensitivity = F;
	SaveConfig();
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
	bDoErrorInit=true
	bInputClassErrorCheck=true
	Desired43FOV=90f
	bCorrectZoomFOV=true
	bCorrectWeaponFOV=True	
	bCorrectMouseSensitivity=true
	Desired43MouseSensitivity=-1f
	WideHUDMap(0)=(HUDClass=class'HUD_Assault',WideHUD="foxWSFix.foxWideHUD_Assault")
	WideHUDMap(1)=(HUDClass=class'HudCBombingRun',WideHUD="foxWSFix.foxWideHudCBombingRun")
	WideHUDMap(2)=(HUDClass=class'HudCCaptureTheFlag',WideHUD="foxWSFix.foxWideHudCCaptureTheFlag")
	WideHUDMap(3)=(HUDClass=class'HudCDeathMatch',WideHUD="foxWSFix.foxWideHudCDeathMatch")
	WideHUDMap(4)=(HUDClass=class'HudCDoubleDomination',WideHUD="foxWSFix.foxWideHudCDoubleDomination")
	WideHUDMap(5)=(HUDClass=class'HudCTeamDeathMatch',WideHUD="foxWSFix.foxWideHudCTeamDeathMatch")
	WideHUDMap(6)=(HUDClass=class'HUDInvasion',WideHUD="foxWSFix.foxWideHUDInvasion")
	WideHUDMap(7)=(HUDClass=class'HudLMS',WideHUD="foxWSFix.foxWideHudLMS")
	WideHUDMap(8)=(HUDClass=class'HudMutant',WideHUD="foxWSFix.foxWideHudMutant")
	WideHUDMap(9)=(HUDClass=class'ONSHUDOnslaught',WideHUD="foxWSFix.foxWideONSHUDOnslaught")
}
