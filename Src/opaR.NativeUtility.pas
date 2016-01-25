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
    function IsGreaterThan(testInfo: TFileVersionInfo): boolean;
    function IsLessThan(testInfo: TFileVersionInfo): boolean;
  end;

  TNativeUtility = class
  private
    class var FLogger: TStringList;
    class procedure CheckPlatformWin32;
    class procedure FindRPaths(var path: string; var homeDir: string; logger: TStringList); overload;
    class procedure SetenvPrepend(path: string; envVarName: string = 'PATH');
    class procedure WriteToLogger(output: string; logger: TStringList);
    class function ConstructRPath(homeDir: string): string;
    //class function FileVersionInfoFromString(versionStr: string): TFileVersionInfo;
    class function FindRPathWindows(homeDir: string): string;
    class function GetRCoreRegistryKeyWin32(logger: TStringList): TRegKey;
    class function GetRhomeWin32NT(logger: TStringList): string;
    class function GetRInstallPathFromRCoreRegKey(key: TRegKey; logger: TStringList): string;
    class function PrependToEnv(path: string; envVarName: string = 'PATH'): string;
  public
    class function FindRHome(path: string = ''; logger: TStringList = nil): string;
    class function FindRPathFromRegistry(logger: TStringList = nil): string;
    class function FindRPath(homeDir: string = ''): string;
    class function FindRPaths(var path: string; var homeDir: string): string; overload;
    class function GetRLibraryFileName: string;
    class function GetRVersionFromRegistry(logger: TStringList = nil): TFileVersionInfo;
    class procedure Initialize;
    class procedure Finalize;
    class procedure SetEnvironmentVariables(path: string = ''; homeDir: string = '');
  end;

implementation

const
  installPathKey = 'InstallPath';
  currentVersionKey = 'Current Version';


{ TNativeUtility }

//------------------------------------------------------------------------------
class procedure TNativeUtility.CheckPlatformWin32;
begin
  if TOSVersion.Platform <> pfWindows then
    raise ENotSupportedException.Create('This method is supported only on the Win32NT platform');
end;
//------------------------------------------------------------------------------
class function TNativeUtility.ConstructRPath(homeDir: string): string;
var
  path: string;
  version: TFileVersionInfo;
  testInfo: TFileVersionInfo;
begin
  case TOSVersion.Platform of
    pfWindows: begin
      path := TPath.Combine(homeDir, 'bin');
      version := GetRVersionFromRegistry;

      if version.IsLessThan(testInfo.Create(2, 12, 0)) then
        result := path
      else
        {$IFDEF CPUX64}
        result := TPath.Combine(path, 'x64');
        {$ELSE}
        result := TPath.Combine(path, 'i386');
        {$ENDIF}
    end;
  end;
end;
//------------------------------------------------------------------------------
///	<summary>
///	FileVersionInfoFromString assumes the Major.Minor.Build format.
///	</summary>
{class function TNativeUtility.FileVersionInfoFromString(
  versionStr: string): TFileVersionInfo;
var
  ix1: integer;
  ix2: integer;
  buildString: string;
begin
  ix1 := Pos('.', versionStr);
  if ix1 > 0 then
  begin
    result.Major := StrToInt(Copy(versionStr, 1, ix1 - 1));
    ix2 := Pos('.', versionStr, ix1 + 1);
    if ix2 > ix1 then
    begin
      result.Minor := StrToInt(Copy(versionStr, ix1 + 1, ix2 - ix1 - 1));
      ix1 := ix2;
      ix2 := Pos('.', versionStr, ix1 + 1);
      if ix2 > 0 then
        raise EopaRException.Create('Error: Version string does not follow Major.Minor.Build format.');

      buildString := Copy(versionStr, ix1 + 1, Length(versionStr) - ix1);
      result.Build := StrToInt(buildString);
    end;
  end;
end;}
//------------------------------------------------------------------------------
class procedure TNativeUtility.Finalize;
begin
  FLogger.Free;
end;
//------------------------------------------------------------------------------
class function TNativeUtility.FindRHome(path: string;
  logger: TStringList): string;
var
  rHome: string;
begin
  case TOSVersion.Platform of
    pfWindows: begin
      rHome := GetRhomeWin32NT(logger);
    end;

    pfMacOS: begin
      { TODO : TNativeUtility.FindRHome - pfMacOS }
    end;

    pfLinux: begin
      { TODO : TNativeUtility.FindRHome - pfLinux }
    end
    else
      raise EopaRException.Create('Error: Platform not supported');
  end;
  result := rHome;
end;
//------------------------------------------------------------------------------
class function TNativeUtility.FindRPath(homeDir: string): string;
begin
  case TOSVersion.Platform of
    pfWindows: begin
      result := FindRPathWindows(homeDir);
    end;

    pfMacOS: begin
      { TODO : TNativeUtility.FindRPath - pfMacOS }
    end;

    pfLinux: begin
      { TODO : TNativeUtility.FindRPath - pfLinux }
    end
    else
      raise EopaRException.Create('Error: Platform not supported');
  end;
end;
//------------------------------------------------------------------------------
class function TNativeUtility.FindRPathFromRegistry(
  logger: TStringList): string;
var
  is64bit: boolean;
  coreKey: TRegKey;
  installPath: string;
  versionInfo: TFileVersionInfo;
  testInfo: TFileVersionInfo;
  bin: string;
begin
  CheckPlatformWin32;
  is64bit := TOSVersion.Architecture = arIntelx64;
  coreKey := GetRCoreRegistryKeyWin32(logger);
  installPath := GetRInstallPathFromRCoreRegKey(coreKey, logger);
  versionInfo := GetRVersionFromRegistry(logger);
  bin := TPath.Combine(installPath, 'bin');

  // -- Up to 2.11.x, DLLs are installed in R_HOME\bin.
  // -- From 2.12.0, DLLs are installed in the one level deeper directory.
  if versionInfo.IsLessThan(testInfo.Create(2, 12, 0)) then
    result := bin
  else
    if is64bit then
      result := TPath.Combine(bin, 'x64')
    else
      result := TPath.Combine(bin, 'i386');
end;
//------------------------------------------------------------------------------
class function TNativeUtility.FindRPaths(var path: string; var homeDir: string): string;
begin
  FindRPaths(path, homeDir, FLogger);
  result := FLogger.Text;
end;
//------------------------------------------------------------------------------
class function TNativeUtility.FindRPathWindows(homeDir: string): string;
begin
  if homeDir = '' then
    result := FindRPathFromRegistry
  else
    result := ConstructRPath(homeDir);
end;
//------------------------------------------------------------------------------
class procedure TNativeUtility.FindRPaths(var path: string; var homeDir: string;
  logger: TStringList);
var
  printPath: string;
  printHome: string;
begin
  if path = '' then printPath := 'null' else printPath := path;
  if homeDir = '' then printHome := 'null' else printHome := homeDir;
  logger.Add(Format('Caller provided path = "%s", homeDir = "%s"', [printPath, printHome]));

  if homeDir = '' then
  begin
    homeDir := GetEnvironmentVariable('R_HOME');
    if homeDir = '' then printHome := 'null' else printHome := homeDir;
    logger.Add(Format('opaR looked for preset R_HOME env. var. and found: "%s"', [printHome]));
  end;

  if homeDir = '' then
  begin
    homeDir := FindRHome(path, logger);
    if homeDir = '' then printHome := 'null' else printHome := homeDir;
    logger.Add(Format('opaR looked for platform-specific way (e.g. win registry) and found: "%s"', [printHome]));

    if not (homeDir = '') then
    begin
      if path = '' then
      begin
        path := FindRPath(homeDir);
        if path = '' then printPath := 'null' else printPath := path;
        logger.Add(Format('opaR trying to find rPath based on rHome; Deduced: "%s"', [printPath]));
      end;

      if path = '' then
      begin
        path := FindRPath;
        if path = '' then printPath := 'null' else printPath := path;
        logger.Add(Format('opaR trying to find rPath independently of rHome; Deduced: "%s"', [printPath]));
      end;
    end
    else
    begin
      homeDir := FindRHome(path);
      if homeDir = '' then printHome := 'null' else printHome := homeDir;
      logger.Add(Format('opaR trying to find rHome based on rPath; Deduced: "%s"', [printHome]));
    end;
  end;

  if homeDir = '' then
    logger.Add('Error: R_HOME was not provided and a suitable path could not be found by opaR');
end;
//------------------------------------------------------------------------------
class function TNativeUtility.GetRLibraryFileName: string;
begin
  case TOSVersion.Platform of
    pfWindows: result := 'R.DLL';
    pfMacOS: result := 'libR.dylib';
    pfLinux: result := 'libR.so';
    else
      raise EopaRException.Create('Error: Platform not supported');
  end;
end;
//------------------------------------------------------------------------------
class function TNativeUtility.GetRCoreRegistryKeyWin32(
  logger: TStringList): TRegKey;
var
  Reg: TRegistry;
  subKey: string;
begin
  CheckPlatformWin32;

  Reg := TRegistry.Create(KEY_READ);
  Reg.RootKey := HKEY_LOCAL_MACHINE;

  try
    if not Reg.OpenKeyReadOnly('SOFTWARE\R-core') then
    begin
      WriteToLogger('Local machine SOFTWARE\R-core not found - trying current user', logger);
      Reg.RootKey := HKEY_CURRENT_USER;
      if not Reg.OpenKeyReadOnly('Software\R-core') then
        raise EopaRException.Create('Windows Registry key "SOFTWARE\R-core" not found in either HKEY_LOCAL_MACHINE or HKEY_CURRENT_USER');
    end;
    Reg.CloseKey;

    {$IFNDEF CPUX64}
      subKey := 'R';
    {$ELSE}
      subKey := 'R64';
    {$ENDIF}

    if Reg.OpenKeyReadOnly('SOFTWARE\R-core\' + subKey) then
    begin
      result.RootKey := Reg.RootKey;
      result.SubKeyPath := 'SOFTWARE\R-core\' + subKey;
    end
    else
      raise EopaRException.CreateFmt('Windows Registry sub-key %s of key %s was not found', [subKey, 'Software\R-core\']);
  finally
    Reg.Free;
  end;
end;
//------------------------------------------------------------------------------
class function TNativeUtility.GetRhomeWin32NT(logger: TStringList): string;
var
  rCoreKey: TRegKey;
begin
  rCoreKey := GetRCoreRegistryKeyWin32(logger);
  result := GetRInstallPathFromRCoreRegKey(rCoreKey, logger);
end;
//------------------------------------------------------------------------------
//-- "GetRInstallPathFromRCoreKegKey" in R.NET.
class function TNativeUtility.GetRInstallPathFromRCoreRegKey(key: TRegKey;
  logger: TStringList): string;
var
  Reg: TRegistry;
  installPath: string;
  currentVersion: string;
  keyNames: TStringList;
  valueNames: TStringList;
begin
  Reg := TRegistry.Create(KEY_READ);
  keyNames := TStringList.Create;
  valueNames := TStringList.Create;
  Reg.RootKey := key.RootKey;

  try
    if Reg.OpenKeyReadOnly(key.SubKeyPath) then
    begin
      Reg.GetKeyNames(keyNames);
      Reg.GetValueNames(valueNames);

      if valueNames.Count = 0 then
      begin
        WriteToLogger('Did not find any value names under ' + key.SubKeyPath, logger);
        { TODO : GetRInstallPathFromRCoreRegKey -> Recurse. }
      end
      else
      begin
        if valueNames.IndexOf(installPathKey) > -1 then
        begin
          WriteToLogger('Found sub-key InstallPath under ' + key.SubKeyPath, logger);
          installPath := Reg.ReadString(installPathKey);
        end
        else
        begin
          WriteToLogger('Did not find sub-key InstallPath under ' + key.SubKeyPath, logger);
          if valueNames.IndexOf(currentVersionKey) > -1 then
          begin
            WriteToLogger('Found sub-key Current Version under ' + key.SubKeyPath, logger);
            currentVersion := Reg.ReadString(currentVersionKey);
            // -- If we haven't found the InstallPath at the R core level then it will hopefully be under the version number sub-key.
            Reg.CloseKey;
            Reg.OpenKeyReadOnly(key.SubKeyPath + '\' + currentVersion);
            installPath := Reg.ReadString(installPathKey);
          end
          else
            WriteToLogger('Sub key ' + currentVersion + ' not found in ' + key.SubKeyPath, logger);
        end;
      end;
    end;
  finally
    Reg.Free;
    keyNames.Free;
    valueNames.Free;
  end;
  result := installPath;
end;
//------------------------------------------------------------------------------
class function TNativeUtility.GetRVersionFromRegistry(
  logger: TStringList): TFileVersionInfo;
var
  i: integer;
  ix: integer;
  coreKey: TRegKey;
  currentVersion: string;
  Reg: TRegistry;
  keyNames: TStringList;
  newestVersion: TFileVersionInfo;
  testVersion: TFileVersionInfo;
begin
  coreKey := GetRCoreRegistryKeyWin32(logger);

  Reg := TRegistry.Create(KEY_READ);
  Reg.RootKey := coreKey.RootKey;
  ix := 0;

  try
    if Reg.OpenKeyReadOnly(coreKey.SubKeyPath) then
      currentVersion := Reg.ReadString(currentVersionKey);

    if currentVersion = '' then
    begin
      keyNames := TStringList.Create;
      try
        Reg.GetKeyNames(keyNames);
        if keyNames.Count > 0 then
        begin
          // -- We can't assume the first value is the version number we need
          // -- since there might be more than one version of R installed.
          // -- We also can't assume the last in the list is the latest version.
          newestVersion.Create(0, 0, 0);
          for i := 0 to keyNames.Count - 1 do
          begin
            if Pos('.', keyNames[i], 1) > 0 then
            begin
              testVersion.Create(keyNames[i]);
              if testVersion.IsGreaterThan(newestVersion) then
              begin
                newestVersion := testVersion;
                ix := i;
              end;
            end;
          end;

          currentVersion := keyNames[ix];
        end;
      finally
        keyNames.Free;
      end;
    end;
  finally
    Reg.Free;
  end;

  result.Create(currentVersion);
end;
//------------------------------------------------------------------------------
class procedure TNativeUtility.Initialize;
begin
  FLogger := TStringList.Create;
end;
//------------------------------------------------------------------------------
class function TNativeUtility.PrependToEnv(path, envVarName: string): string;
var
  currentPathEnv: string;
  paths: TStringDynArray;
begin
  currentPathEnv := GetEnvironmentVariable(envVarName);
  paths := SplitString(currentPathEnv, TPath.PathSeparator);
  if paths[0] = path then
    result := currentPathEnv
  else
    result := path + TPath.PathSeparator + currentPathEnv;
end;
//------------------------------------------------------------------------------
class procedure TNativeUtility.SetEnvironmentVariables(path, homeDir: string);
begin
  FLogger.Clear;

  if (path <> '') and (not DirectoryExists(path)) then
    raise EopaRException.CreateFmt('Directory does not exist: %s', [path]);
  if (homeDir <> '') and (not DirectoryExists(homeDir)) then
    raise EopaRException.CreateFmt('Directory does not exist: %s', [homeDir]);

  FindRPaths(path, homeDir, FLogger);

  if homeDir = '' then
    raise EopaRException.Create('Error: R_HOME was not provided and a suitable path could not be found by opaR');

  SetenvPrepend(path);

  // -- R.NET:  It is highly recommended to use the 8.3 short path format on windows (R.NET).
  // -- opaR:   Use of the short path name gives an empty rhome in TRStart - needs investigation.
  //if TOSVersion.Platform = pfWindows then
  //  homeDir := ExtractShortPathName(homeDir);

  if not DirectoryExists(homeDir) then
    raise EopaRException.CreateFmt('Directory %s does not exist - cannot set the environment variable R_HOME to that value', [homeDir]);

  SetEnvironmentVariable('R_HOME', PWideChar(homeDir));

  if TOSVersion.Platform = pfLinux then
  begin
    { TODO : SetEnvironmentVariables - custom install on Linux. }
  end;
end;
//------------------------------------------------------------------------------
class procedure TNativeUtility.SetenvPrepend(path, envVarName: string);
var
  varValue: PWideChar;
begin
  varValue := PWideChar(PrependToEnv(path, envVarName));
  SetEnvironmentVariable('PATH', varValue);
end;
//------------------------------------------------------------------------------
class procedure TNativeUtility.WriteToLogger(output: string;
  logger: TStringList);
begin
  if assigned(logger) then
    logger.Add(output);
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
//------------------------------------------------------------------------------
function TFileVersionInfo.IsGreaterThan(testInfo: TFileVersionInfo): boolean;
begin
  result := (self.Major > testInfo.Major) and (self.Minor > testInfo.Minor);
end;
//------------------------------------------------------------------------------
function TFileVersionInfo.IsLessThan(testInfo: TFileVersionInfo): boolean;
begin
  result := (self.Major < testInfo.Major) and (self.Minor < testInfo.Minor);
end;

initialization
  TNativeUtility.Initialize;

finalization
  TNativeUtility.Finalize;

end.
