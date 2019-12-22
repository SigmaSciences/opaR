unit opaR.NativeUtility;

{-------------------------------------------------------------------------------

opaR: object pascal for R

Copyright (C) 2015-2016 Sigma Sciences Ltd.

Originator: Robert L S Devine

Unless you have received this program directly from Sigma Sciences Ltd under
the terms of a commercial license agreement, then this program is licensed
to you under the terms of version 3 of the GNU Affero General Public License.
Please refer to the AGPL licence document at:
http://www.gnu.org/licenses/agpl-3.0.txt for more details.

This program is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
THOSE OF NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

-------------------------------------------------------------------------------}


interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Types,
  System.StrUtils,

  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  System.Win.Registry,
  {$ENDIF}

  opaR.Utils;

type
  TRegKey = record
    RootKey: NativeUInt;
    SubKeyPath: string;
  end;

  TFileVersionInfo = record
  private
    procedure BuildFromString(versionStr: string);
  public
    Major: integer;
    Minor: integer;
    Build: integer;
    constructor Create(mjr, mnr, bld: integer); overload;
    constructor Create(versionStr: string); overload;
    function IsGreaterThan(const aTestInfo: TFileVersionInfo): boolean;
    function IsLessThan(const aTestInfo: TFileVersionInfo): boolean;
    function IsEqualTo(const aTestInfo: TFileVersionInfo): boolean;
  end;
  
  TREnvironmentPaths = class
  strict private
    FRHome: string;
    FRLibraryDirectory: string;
    FLogger: TStringList;
    procedure FindRPathFromRHomeWindows;
    function GetRCoreRegistryKeyWin32: TRegKey;
    function FindInstallationPathFromRegistry(const aRegistryKey: TRegKey): string;
    function FindNewestRInstallationFromRegistry(const aRegistryKey: TRegKey):
        string;
    function TryToFindRHomeFromEnvironmentVariables: boolean;
    procedure FindRHomeFromSystemRegistry;
    procedure GetRhomeWindows;
    procedure FindRHomeValue;
    procedure FindRLibraryFilePathFromRHome;
    procedure ClearSavedEnvironmentPaths;
    procedure SetRHomeEnvironmentVariable;
    procedure AddRLibraryPathToPathEnvVariable;
    procedure SetEnvironmentVariables;
  public
    constructor Create;
    destructor Destroy; override;
    procedure FindRInstallPathAndSetEnvVariables(const aDefaultRHomeValue: string =
        '');
    procedure GetLoggerText(const aStringsToPopulate: TStrings);
    function RLibraryFileName: string;
    property RHome: string read FRHome;
    property RLibraryDirectory: string read FRLibraryDirectory;
  end;

function REnvironmentPaths: TREnvironmentPaths;

implementation

uses
  System.RegularExpressions;

const
  INSTALLPATH_KEY = 'InstallPath';
  R_CORE_REGISTRY_PATH = 'SOFTWARE\R-core\';
  R_HOME_ENVIRONMENT_VARIABLE = 'R_HOME';
  VERSION_NUMBER_REGEX = '^\d+\.\d+\.\d+$';

var
  glREnvironmentPaths: TREnvironmentPaths = nil;

function REnvironmentPaths: TREnvironmentPaths;
begin
  if not Assigned(glREnvironmentPaths) then
    glREnvironmentPaths := TREnvironmentPaths.Create;

  Result := glREnvironmentPaths;
end;

function CompareRVersion(List: TStringList; Index1, Index2: Integer): Integer;
var
  version1: TFileVersionInfo;
  version2: TFileVersionInfo;
begin
  version1 := TFileVersionInfo.Create(List[Index1]);
  version2 := TFileVersionInfo.Create(List[Index2]);

  if version1.IsEqualTo(version2) then
    result := 0
  else if version1.IsGreaterThan(version2) then
    result := -1
  else
    result := 1;
end;


constructor TREnvironmentPaths.Create;
begin
  inherited;
  FLogger := TStringList.Create;
  ClearSavedEnvironmentPaths;
end;

destructor TREnvironmentPaths.Destroy;
begin
  FLogger.Free;
  inherited;
end;

procedure TREnvironmentPaths.ClearSavedEnvironmentPaths;
begin
  FRHome := '';
  FRLibraryDirectory := '';
end;

function TREnvironmentPaths.FindInstallationPathFromRegistry(const
    aRegistryKey: TRegKey): string;
var
  registry: TRegistry;
begin
  Result := '';

  FLogger.Add(Format('Looking for the %s registry value for the registry key: %s',
                    [INSTALLPATH_KEY, aRegistryKey.SubKeyPath]));

  registry := TRegistry.Create(KEY_READ);
  registry.RootKey := aRegistryKey.RootKey;
  try
    if not registry.OpenKeyReadOnly(aRegistryKey.SubKeyPath) then
      raise EopaRException.CreateFmt('Failed to open registry path: "%s"', [aRegistryKey.SubKeyPath]);

    if registry.ValueExists(INSTALLPATH_KEY) then
    begin
      result := registry.ReadString(INSTALLPATH_KEY);
      FLogger.Add(Format('Found %s: "%s"', [INSTALLPATH_KEY, result]));
    end
    else
    begin
      FLogger.Add(Format('Registry key %s does not have value %s',
            [aRegistryKey.SubKeyPath, INSTALLPATH_KEY]));
    end;

    registry.CloseKey;
  finally
    registry.Free;
  end;
end;

function TREnvironmentPaths.FindNewestRInstallationFromRegistry(const
    aRegistryKey: TRegKey): string;
var
  registry: TRegistry;
  subKeys: TStringList;
  rVersion: string;
  curRegKey: TRegKey;
begin
  Result := '';

  registry := TRegistry.Create(KEY_READ);
  registry.RootKey := aRegistryKey.RootKey;

  subKeys := TStringList.Create;

  try
    if not registry.OpenKeyReadOnly(aRegistryKey.SubKeyPath) then
      raise EopaRException.CreateFmt('Failed to open registry path: "%s"', [aRegistryKey.SubKeyPath]);

    registry.GetKeyNames(subKeys);
    registry.CloseKey;

    subKeys.CustomSort(CompareRVersion);

    FLogger.Add('Potential versions of R from the system registry:');
    FLogger.AddStrings(subKeys);

    curRegKey.RootKey := aRegistryKey.RootKey;
    for rVersion in subKeys do
    begin
      curRegKey.SubKeyPath := aRegistryKey.SubKeyPath + '\' + rVersion;
      result := FindInstallationPathFromRegistry(curRegKey);
      if result <> '' then
        break;
    end;
  finally
    registry.Free;
    subKeys.Free;
  end;
end;

procedure TREnvironmentPaths.FindRHomeFromSystemRegistry;
var
  regKeyRCore: TRegKey;
  installDir: string;
begin
  regKeyRCore := GetRCoreRegistryKeyWin32;
  installDir := FindInstallationPathFromRegistry(regKeyRCore);
  if installDir = '' then
  begin
    FLogger.Add(Format('Registry value %s not found in root R registry. ' +
          'Now find the most recent installation of R', [INSTALLPATH_KEY]));
    installDir := FindNewestRInstallationFromRegistry(regKeyRCore);
  end;

  FRHome := installDir;
  if not DirectoryExists(FRHome) then
    raise EopaRException.Create('The installation path of R in the ' +
        'system registry no longer points to a valid folder. Found : ' + FRHome);
end;

procedure TREnvironmentPaths.FindRHomeValue;
begin
  case TOSVersion.Platform of
    pfWindows: GetRhomeWindows;
    else
      raise EopaRException.Create('Error: Platform not supported');
  end;
end;

procedure TREnvironmentPaths.GetRhomeWindows;
begin
  if not TryToFindRHomeFromEnvironmentVariables then
  begin
    FLogger.Add('The R home path was not found in the environment ' +
                  'variables, now checking the system registry');

    FindRHomeFromSystemRegistry;
  end;



  if FRHome = '' then
  begin
    raise EopaRException.Create('Unable to find the R library from the ' +
        'system registry. Please check if R is installed on your computer');
  end;
end;

function TREnvironmentPaths.TryToFindRHomeFromEnvironmentVariables: boolean;
var
  rHomeEnv: string;
begin
  Result := False;
  rHomeEnv := GetEnvironmentVariable(R_HOME_ENVIRONMENT_VARIABLE);

  if rHomeEnv <> '' then
  begin
    FLogger.Add(Format('The %s enviroment variable has value: %s',
                [R_HOME_ENVIRONMENT_VARIABLE, rHomeEnv]));
    Result := True;
    if DirectoryExists(rHomeEnv) then
      FRHome := rHomeEnv
    else
      raise EopaRException.CreateFMT('The %s environment variable was set ' +
          'to an invalid path!: %s', [R_HOME_ENVIRONMENT_VARIABLE, rHomeEnv]);
  end
  else
  begin
    FLogger.Add(Format('The %s enviroment variable was not set',
                [R_HOME_ENVIRONMENT_VARIABLE]));
  end;
end;

procedure TREnvironmentPaths.FindRInstallPathAndSetEnvVariables(const
    aDefaultRHomeValue: string = '');
begin
  ClearSavedEnvironmentPaths;

  if aDefaultRHomeValue <> '' then
    FLogger.Add(Format('Using user input R home value: "%s"', [aDefaultRHomeValue]));

  if aDefaultRHomeValue <> '' then
    FRHome := aDefaultRHomeValue
  else
    FindRHomeValue;

  FindRLibraryFilePathFromRHome;

  FLogger.Add(Format('We have determined that the correct R home value is: "%s"', [RHome]));
  FLogger.Add(Format('We have determined that the R library directory is: "%s"', [RLibraryDirectory]));

  SetEnvironmentVariables;
end;

procedure TREnvironmentPaths.FindRLibraryFilePathFromRHome;
begin
  case TOSVersion.Platform of
    pfWindows: FindRPathFromRHomeWindows;
    else
      raise EopaRException.Create('Error: Platform not supported');
  end;
end;

procedure TREnvironmentPaths.FindRPathFromRHomeWindows;
var
  pathToBinFolder: string;
  pathWithBitVersion: string;
begin
  pathToBinFolder := TPath.Combine(RHome, 'bin');

  if not DirectoryExists(pathToBinFolder) then
    raise EOpaRException.Create('Unable to find R installation directory: ' + pathToBinFolder);


  {$IFDEF CPUX64}
  pathWithBitVersion := TPath.Combine(pathToBinFolder, 'x64');
  {$ELSE}
  pathWithBitVersion := TPath.Combine(pathToBinFolder, 'i386');
  {$ENDIF}

  // Prior to version 2.12.0 of R, the R.dll file was kept directly in the bin
  // folder. This changed when R changed to installing the x32 and x64 versions
  // in parallel folders in tthe bin folder.
  if DirectoryExists(pathWithBitVersion) then
    FRLibraryDirectory := pathWithBitVersion
  else
    FRLibraryDirectory := pathToBinFolder;
end;

function TREnvironmentPaths.RLibraryFileName: string;
begin
  case TOSVersion.Platform of
    pfWindows: result := 'R.DLL';
    pfMacOS: result := 'libR.dylib';
    pfLinux: result := 'libR.so';
    else
      raise EopaRException.Create('Error: Platform not supported');
  end;
end;

function TREnvironmentPaths.GetRCoreRegistryKeyWin32: TRegKey;
var
  Reg: TRegistry;
  subKey: string;
begin
  Reg := TRegistry.Create(KEY_READ);
  Reg.RootKey := HKEY_LOCAL_MACHINE;

  result.RootKey := 0;
  result.SubKeyPath := '';

  try
    if not Reg.OpenKeyReadOnly(R_CORE_REGISTRY_PATH) then
    begin
      FLogger.Add('HKEY_LOCAL_MACHINE\SOFTWARE\R-core not found');
      FLogger.Add('Trying HKEY_CURRENT_USER\SOFTWARE\R-core');

      Reg.RootKey := HKEY_CURRENT_USER;
      if not Reg.OpenKeyReadOnly(R_CORE_REGISTRY_PATH) then
        raise EopaRException.Create('Windows Registry key "SOFTWARE\R-core" not found in either HKEY_LOCAL_MACHINE or HKEY_CURRENT_USER');
    end;
    Reg.CloseKey;

  {$IFNDEF CPUX64}
    subKey := 'R';
  {$ELSE}
    subKey := 'R64';
  {$ENDIF}

    if Reg.OpenKeyReadOnly(R_CORE_REGISTRY_PATH + subKey) then
    begin
      result.RootKey := Reg.RootKey;
      result.SubKeyPath := R_CORE_REGISTRY_PATH + subKey;
    end
    else
    begin
      raise EopaRException.CreateFmt('Windows Registry sub-key %s of key %s was not found',
              [subKey, R_CORE_REGISTRY_PATH]);
    end;
    Reg.CloseKey;
  finally
    Reg.Free;
  end;
end;

procedure TREnvironmentPaths.GetLoggerText(const aStringsToPopulate: TStrings);
begin
  aStringsToPopulate.AddStrings(FLogger);
end;

procedure TREnvironmentPaths.SetEnvironmentVariables;
begin
  SetRHomeEnvironmentVariable;
  AddRLibraryPathToPathEnvVariable;
end;

procedure TREnvironmentPaths.SetRHomeEnvironmentVariable;
var
  rHomeEnvVarName: PWideChar;
  rHomeEnvVarValue: PWideChar;
begin
  FLogger.Add(Format('Setting R_HOME environment variable to: "%s"', [RHome]));
  rHomeEnvVarName := R_HOME_ENVIRONMENT_VARIABLE;
  rHomeEnvVarValue := PWideChar(RHome);
  SetEnvironmentVariable(rHomeEnvVarName, rHomeEnvVarValue);
end;

procedure TREnvironmentPaths.AddRLibraryPathToPathEnvVariable;
var
  pathEnvVarName: PWideChar;
  pathValueStart: string;
  currentPaths: TStringDynArray;
  pathValueWithR: PWideChar;
  alreadyHasRPath: boolean;
  cntr: Integer;
begin
  pathEnvVarName := 'PATH';
  pathValueStart := GetEnvironmentVariable(pathEnvVarName);

  alreadyHasRPath := False;
  currentPaths := SplitString(pathValueStart, TPath.PathSeparator);
  for cntr := 0 to Length(currentPaths) - 1 do
  begin
    if SameText(RLibraryDirectory, currentPaths[cntr]) then
    begin
      alreadyHasRPath := True;
      break;
    end;
  end;

  if not alreadyHasRPath then
  begin
    FLogger.Add(Format('Adding the R library path to the PATH ' +
            'environment variable: "%s"', [RLibraryDirectory]));

    pathValueWithR := PWideChar(Format('%s;%s', [pathValueStart, RLibraryDirectory]));
    SetEnvironmentVariable(pathEnvVarName, pathValueWithR);
  end
  else
  begin
    FLogger.Add(Format('R library path is already in the PATH ' +
            'environment variable: "%s"', [RLibraryDirectory]));
  end;
end;


{ TFileVersionInfo }

//------------------------------------------------------------------------------
///	<summary>
///	BuildFromString assumes the Major.Minor.Build format.
///	</summary>
procedure TFileVersionInfo.BuildFromString(versionStr: string);
var
  ix1: integer;
  ix2: integer;
  buildString: string;
begin
  if not TRegEx.IsMatch(versionStr, VERSION_NUMBER_REGEX) then
  begin
    Major := 0;
    Minor := 0;
    Build := 0;
  end
  else
  begin
    ix1 := Pos('.', versionStr);
    if ix1 > 0 then
    begin
      self.Major := StrToInt(Copy(versionStr, 1, ix1 - 1));
      ix2 := Pos('.', versionStr, ix1 + 1);
      if ix2 > ix1 then
      begin
        self.Minor := StrToInt(Copy(versionStr, ix1 + 1, ix2 - ix1 - 1));
        ix1 := ix2;
        ix2 := Pos('.', versionStr, ix1 + 1);
        if ix2 > 0 then
          raise EopaRException.Create('Error: Version string does not follow Major.Minor.Build format.');

        buildString := Copy(versionStr, ix1 + 1, Length(versionStr) - ix1);
        self.Build := StrToInt(buildString);
      end;
    end;
  end;
end;
//------------------------------------------------------------------------------
constructor TFileVersionInfo.Create(mjr, mnr, bld: integer);
begin
  self.Major := mjr;
  self.Minor := mnr;
  self.Build := bld;
end;
//------------------------------------------------------------------------------
constructor TFileVersionInfo.Create(versionStr: string);
begin
  BuildFromString(versionStr);
end;

function TFileVersionInfo.IsEqualTo(const aTestInfo: TFileVersionInfo): boolean;
begin
  result := (self.Major = aTestInfo.Major) and
            (self.Minor = aTestInfo.Minor) and
            (self.Build = aTestInfo.Build);
end;

//------------------------------------------------------------------------------
function TFileVersionInfo.IsGreaterThan(const aTestInfo: TFileVersionInfo):
    boolean;
begin
  result := False;
  if self.Major > aTestInfo.Major then
    result := True
  else if self.Major = aTestInfo.Major then
  begin
    if (self.Minor > aTestInfo.Minor) then
      result := True
    else if (self.Minor = aTestInfo.Minor) and (self.Build > aTestInfo.Build) then
      result := True;
  end;
end;
//------------------------------------------------------------------------------
function TFileVersionInfo.IsLessThan(const aTestInfo: TFileVersionInfo):
    boolean;
begin
  result := False;
  if self.Major < aTestInfo.Major then
    result := True
  else if self.Major = aTestInfo.Major then
  begin
    if (self.Minor < aTestInfo.Minor) then
      result := True
    else if (self.Minor = aTestInfo.Minor) and (self.Build < aTestInfo.Build) then
      result := True;
  end;
end;

initialization
finalization
  FreeAndNil(glREnvironmentPaths);

end.
