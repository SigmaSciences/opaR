unit opaR.StartupParameter;

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
  System.Sysutils,

  opaR.Utils,
  opaR.Internals.Windows.RStart;

type
  TStartupParameter = class
  private
    procedure SetDefaultParameter;
    procedure SetMinMemorySize(const Value: NativeUInt);
    function GetMinMemorySize: NativeUInt;
    function GetQuiet: LongBool;
    procedure SetQuiet(const Value: LongBool);
    function GetSlave: LongBool;
    procedure SetSlave(const Value: LongBool);
    function GetInteractive: LongBool;
    procedure SetInteractive(const Value: LongBool);
    function GetVerbose: LongBool;
    procedure SetVerbose(const Value: LongBool);
    function GetLoadSiteFile: LongBool;
    procedure SetLoadSiteFile(const Value: LongBool);
    function GetLoadInitFile: LongBool;
    procedure SetLoadInitFile(const Value: LongBool);
    function GetDebugInitFile: LongBool;
    procedure SetDebugInitFile(const Value: LongBool);
    function GetRestoreAction: TStartupRestoreAction;
    procedure SetRestoreAction(const Value: TStartupRestoreAction);
    function GetSaveAction: TStartupSaveAction;
    procedure SetSaveAction(const Value: TStartupSaveAction);
    function GetMinCellSize: NativeUInt;
    procedure SetMinCellSize(const Value: NativeUInt);
    function GetMaxMemorySize: NativeUInt;
    procedure SetMaxMemorySize(const Value: NativeUInt);
    function GetMaxCellSize: NativeUInt;
    procedure SetMaxCellSize(const Value: NativeUInt);
    function GetStackSize: NativeUInt;
    procedure SetStackSize(const Value: NativeUInt);
    function GetNoRenviron: LongBool;
    procedure SetNoRenviron(const Value: LongBool);
    function GetRHome: AnsiString;
    procedure SetRHome(const Value: AnsiString);
    function GetHome: AnsiString;
    procedure SetHome(const Value: AnsiString);
    function GetCharacterMode: TUiMode;
    procedure SetCharacterMode(const Value: TUiMode);
  public
    Start: TRStart;
    constructor Create;
    property CharacterMode: TUiMode read GetCharacterMode write SetCharacterMode;
    property DebugInitFile: LongBool read GetDebugInitFile write SetDebugInitFile;
    property Home: AnsiString read GetHome write SetHome;
    property Interactive: LongBool read GetInteractive write SetInteractive;
    property LoadInitFile: LongBool read GetLoadInitFile write SetLoadInitFile;
    property LoadSiteFile: LongBool read GetLoadSiteFile write SetLoadSiteFile;
    property MaxCellSize: NativeUInt read GetMaxCellSize write SetMaxCellSize;
    property MaxMemorySize: NativeUInt read GetMaxMemorySize write SetMaxMemorySize;
    property MinCellSize: NativeUInt read GetMinCellSize write SetMinCellSize;
    property MinMemorySize: NativeUInt read GetMinMemorySize write SetMinMemorySize;
    property NoRenviron: LongBool read GetNoRenviron write SetNoRenviron;
    property Quiet: LongBool read GetQuiet write SetQuiet;
    property RestoreAction: TStartupRestoreAction read GetRestoreAction write SetRestoreAction;
    property RHome: AnsiString read GetRHome write SetRHome;
    property SaveAction: TStartupSaveAction read GetSaveAction write SetSaveAction;
    property Slave: LongBool read GetSlave write SetSlave;
    property StackSize: NativeUInt read GetStackSize write SetStackSize;
    property Verbose: LongBool read GetVerbose write SetVerbose;
  end;

implementation

const
  {$IFDEF WIN32}
  EnvironmentDependentMaxSize = UInt32.MaxValue;
  {$ENDIF}

  {$IFDEF WIN64}
  EnvironmentDependentMaxSize = High(NativeUInt);
  {$ENDIF}

  {$IFDEF MACOS32}
  EnvironmentDependentMaxSize = UInt32.MaxValue;
  {$ENDIF}

{ TStartupParameter }

//------------------------------------------------------------------------------
constructor TStartupParameter.Create;
begin
  SetDefaultParameter;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetCharacterMode: TUiMode;
begin
  if TOSVersion.Platform <> pfWindows then
    raise ENotSupportedException.Create('CharacterMode is supported only on the Win32NT platform');
  result := self.Start.CharacterMode;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetCharacterMode(const Value: TUiMode);
begin
  if TOSVersion.Platform <> pfWindows then
    raise ENotSupportedException.Create('CharacterMode is supported only on the Win32NT platform');
  self.Start.CharacterMode := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetDebugInitFile: LongBool;
begin
  result := self.Start.Common.DebugInitFile;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetHome: AnsiString;
begin
  if TOSVersion.Platform <> pfWindows then
    raise ENotSupportedException.Create('HOME is supported only on the Win32NT platform');
  result := AnsiString(self.Start.home);
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetHome(const Value: AnsiString);
begin
  if TOSVersion.Platform <> pfWindows then
    raise ENotSupportedException.Create('HOME is supported only on the Win32NT platform');
  self.Start.home := PAnsiChar(Value);
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetDebugInitFile(const Value: LongBool);
begin
  self.Start.Common.DebugInitFile := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetInteractive: LongBool;
begin
  result := self.Start.Common.R_Interactive;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetInteractive(const Value: LongBool);
begin
  self.Start.Common.R_Interactive := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetLoadInitFile: LongBool;
begin
  result := self.Start.Common.LoadInitFile;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetLoadInitFile(const Value: LongBool);
begin
  self.Start.Common.LoadInitFile := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetLoadSiteFile: LongBool;
begin
  result := self.Start.Common.LoadSiteFile;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetLoadSiteFile(const Value: LongBool);
begin
  self.Start.Common.LoadSiteFile := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetMaxCellSize: NativeUInt;
begin
  result := self.Start.Common.max_nsize;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetMaxCellSize(const Value: NativeUInt);
begin
  self.Start.Common.max_nsize := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetMaxMemorySize: NativeUInt;
begin
  result := self.Start.Common.max_vsize;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetMaxMemorySize(const Value: NativeUInt);
begin
  self.Start.Common.max_vsize := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetMinCellSize: NativeUInt;
begin
  result := self.Start.Common.nsize;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetMinCellSize(const Value: NativeUInt);
begin
  self.Start.Common.nsize := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetMinMemorySize: NativeUInt;
begin
  result := self.Start.Common.vsize;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetMinMemorySize(const Value: NativeUInt);
begin
  self.Start.Common.vsize := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetNoRenviron: LongBool;
begin
  result := self.Start.Common.NoRenviron;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetNoRenviron(const Value: LongBool);
begin
  self.Start.Common.NoRenviron := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetQuiet: LongBool;
begin
  result := self.Start.Common.R_Quiet;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetRestoreAction: TStartupRestoreAction;
begin
  result := self.Start.Common.RestoreAction;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetRestoreAction(
  const Value: TStartupRestoreAction);
begin
  self.Start.Common.RestoreAction := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetRHome: AnsiString;
begin
  if TOSVersion.Platform <> pfWindows then
    raise ENotSupportedException.Create('RHOME is supported only on the Win32NT platform');
  result := AnsiString(self.Start.rhome);
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetRHome(const Value: AnsiString);
begin
  if TOSVersion.Platform <> pfWindows then
    raise ENotSupportedException.Create('RHOME is supported only on the Win32NT platform');
  self.Start.rhome := PAnsiChar(Value);
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetQuiet(const Value: LongBool);
begin
  self.Start.Common.R_Quiet := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetSaveAction: TStartupSaveAction;
begin
  result := self.Start.Common.SaveAction;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetSaveAction(const Value: TStartupSaveAction);
begin
  self.Start.Common.SaveAction := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetSlave: LongBool;
begin
  result := self.Start.Common.R_Slave;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetStackSize: NativeUInt;
begin
  result := self.Start.Common.ppsize;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetStackSize(const Value: NativeUInt);
begin
  self.Start.Common.ppsize := UIntPtr(Value);
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetSlave(const Value: LongBool);
begin
  self.Start.Common.R_Slave := Value;
end;
//------------------------------------------------------------------------------
function TStartupParameter.GetVerbose: LongBool;
begin
  result := self.Start.Common.R_Verbose;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetVerbose(const Value: LongBool);
begin
  self.Start.Common.R_Verbose := Value;
end;
//------------------------------------------------------------------------------
procedure TStartupParameter.SetDefaultParameter;
begin
  Quiet := true;
  //Slave := false;
  //Slave := true;       // rlsd
  Interactive := true;
  //Interactive := false;     // rlsd
  //Verbose := false;
  RestoreAction := TStartupRestoreAction.NoRestore;
  SaveAction := TStartupSaveAction.NoSave;
  LoadSiteFile := true;
  LoadInitFile := true;
  //DebugInitFile := false;
  MinMemorySize := 6291456;
  MinCellSize := 350000;

  MaxMemorySize := EnvironmentDependentMaxSize;
  MaxCellSize := EnvironmentDependentMaxSize;
  StackSize := 50000;
  //NoRenviron := false;
  if TOSVersion.Platform = pfWindows then
    CharacterMode := TUiMode.LinkDll;
end;



end.
