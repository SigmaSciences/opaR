unit opaR.Devices.CharacterDeviceAdapter;

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

{ TODO : TCharacterDeviceAdapter - Unix functions. }

interface

uses
  WinApi.Windows,
  System.SysUtils,
  System.AnsiStrings,
  System.Classes,

  opaR.StartupParameter,
  opaR.DLLFunctions,
  opaR.Utils,
  opaR.Interfaces;

type
  TCharacterDeviceAdapter = class
  private
    class var FLastDevice: ICharacterDevice;
    FDevice: ICharacterDevice;
    FDLLHandle: HMODULE;
    class function ToNativeUnixPath(path: AnsiString): AnsiString;
    class function GetDevice: ICharacterDevice; static;
  public
    constructor Create(device: ICharacterDevice);
    procedure Install(engine: IREngine; parameter: TStartupParameter);
    procedure SetupWindowsDevice(parameter: TStartupParameter);
    class property Device: ICharacterDevice read GetDevice;
  end;

  function ReadConsole(prompt, buffer: PAnsiChar; count: integer; history: LongBool): LongBool; cdecl;
  procedure WriteConsole(const buffer: PAnsiChar; length: integer); cdecl;
  procedure WriteConsoleEx(const buffer: PAnsiChar; length: integer; outputType: TConsoleOutputType); cdecl;
  procedure Callback; cdecl;
  procedure ShowMessage(const msg: PAnsiChar); cdecl;
  function Ask(const question: PAnsiChar): TYesNoCancel; cdecl;
  procedure Busy(which: TBusyType); cdecl;


implementation

//------------------------------------------------------------------------------
function ReadConsole(prompt, buffer: PAnsiChar; count: integer; history: LongBool): LongBool; cdecl;
var
  input: string;
begin
  result := false;
  if assigned(TCharacterDeviceAdapter.Device) then
  begin
    input := TCharacterDeviceAdapter.Device.ReadConsole(string(prompt), count, history);
    result := input <> '';
    input := input + #10;
    buffer := PAnsiChar(AnsiString(input));
  end;
end;
//------------------------------------------------------------------------------
procedure WriteConsole(const buffer: PAnsiChar; length: integer); cdecl;
begin
  WriteConsoleEx(buffer, length, TConsoleOutputType.None_);
end;
//------------------------------------------------------------------------------
procedure WriteConsoleEx(const buffer: PAnsiChar; length: integer; outputType: TConsoleOutputType); cdecl;
begin
  //OutputDebugString(PWideChar(string(buffer)));
  if assigned(TCharacterDeviceAdapter.Device) then
    TCharacterDeviceAdapter.Device.WriteConsole(string(buffer), length, TConsoleOutputType.None_);
end;
//------------------------------------------------------------------------------
procedure Callback; cdecl;
begin
  if assigned(TCharacterDeviceAdapter.Device) then
    TCharacterDeviceAdapter.Device.Callback;
end;
//------------------------------------------------------------------------------
procedure ShowMessage(const msg: PAnsiChar); cdecl;
begin
  if assigned(TCharacterDeviceAdapter.Device) then
    TCharacterDeviceAdapter.Device.ShowMessage(string(msg));
end;
//------------------------------------------------------------------------------
function Ask(const question: PAnsiChar): TYesNoCancel; cdecl;
begin
  if assigned(TCharacterDeviceAdapter.Device) then
    result := TCharacterDeviceAdapter.Device.Ask(string(question))
  else
    result := TYesNoCancel.Cancel;
end;
//------------------------------------------------------------------------------
procedure Busy(which: TBusyType); cdecl;
begin
  if assigned(TCharacterDeviceAdapter.Device) then
    TCharacterDeviceAdapter.Device.Busy(which);
end;



{ TCharacterDeviceAdapter }

//------------------------------------------------------------------------------
constructor TCharacterDeviceAdapter.Create(device: ICharacterDevice);
begin
  if device <> nil then
  begin
    FLastDevice := device;
    FDevice := device;
  end
  else
    raise EopaRException.Create('Nil device in TCharacterDeviceAdapter constructor');
end;
//------------------------------------------------------------------------------
class function TCharacterDeviceAdapter.GetDevice: ICharacterDevice;
begin
  if FDevice = nil then
    result := FLastDevice
  else
    result := FDevice;
end;
//------------------------------------------------------------------------------
procedure TCharacterDeviceAdapter.Install(engine: IREngine; parameter: TStartupParameter);
begin
  FDLLHandle := engine.Handle;
  case TOSVersion.Platform of
    pfWindows: begin
      SetupWindowsDevice(parameter);
    end;

    pfMacOS, pfLinux: begin
      { TODO : TCharacterDeviceAdapter.Install - pfMacOS/pfLinux }
    end
    else
      raise EopaRException.Create('Error: Platform not supported');
  end;
end;
//------------------------------------------------------------------------------
procedure TCharacterDeviceAdapter.SetupWindowsDevice(
  parameter: TStartupParameter);
var
  getRUser: TRFnGetRUser;
  home: AnsiString;
begin
  if parameter.RHome = '' then
    parameter.RHome := ToNativeUnixPath(AnsiString(GetEnvironmentVariable('R_HOME')));

  if parameter.Home = '' then
  begin
    getRUser := GetProcAddress(FDLLHandle, 'getRUser');
    home := getRUser;
    parameter.Home := ToNativeUnixPath(home);
  end;

  parameter.Start.ReadConsole := ReadConsole;
  parameter.Start.WriteConsole := WriteConsole;
  parameter.Start.WriteConsoleEx := WriteConsoleEx;
  parameter.Start.CallBack := Callback;
  parameter.Start.ShowMessage := ShowMessage;
  parameter.Start.YesNoCancel := Ask;
  parameter.Start.Busy := Busy;
end;
//------------------------------------------------------------------------------
class function TCharacterDeviceAdapter.ToNativeUnixPath(
  path: AnsiString): AnsiString;
begin
  result := AnsiReplaceStr(path, '\', '/');
end;



end.
