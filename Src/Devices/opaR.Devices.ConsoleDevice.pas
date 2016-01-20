unit opaR.Devices.ConsoleDevice;

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

{-------------------------------------------------------------------------------

NOTE: Use of a standard ConsoleDevice requires there to be an active Console,
which is obviously the case if the application has been created as a console
app. For GUI apps in debug mode, go to Project Options and under Linking select
"Generate console application" as TRUE. This will create a console window in
conjunction with the GUI.

-------------------------------------------------------------------------------}

{ TODO : TConsoleDevice - Unix functions. }

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Types,

  opaR.Utils,
  opaR.Interfaces;

type
  TConsoleDevice = class(TInterfacedObject, ICharacterDevice)
  public
    function ReadConsole(prompt: string; capacity: integer; history: boolean): string;
    procedure WriteConsole(output: string; length: integer; outputType: TConsoleOutputType);
    procedure ShowMessage(msg: string);
    procedure Busy(which: TBusyType);
    procedure Callback;
    function Ask(question: string): TYesNoCancel;
    // -- Unix-only from this point.
    procedure Suicide(msg: string);
    procedure ResetConsole;
    procedure FlushConsole;
    procedure ClearErrorConsole;
    procedure CleanUp(saveAction: TStartupSaveAction; status: integer; runLast: boolean);
    function ShowFiles(files, headers: TArray<string>; title: string; delete: boolean; pager: string): boolean;
    function ChooseFile(create: boolean): string;
    procedure EditFile(fileName: string);
    //SymbolicExpression LoadHistory(Language call, SymbolicExpression operation, Pairlist args, REnvironment environment);
    //function LoadHistory: TSymbolicExpression;
    //SymbolicExpression SaveHistory(Language call, SymbolicExpression operation, Pairlist args, REnvironment environment);
    //function SaveHistory: TSymbolicExpression;
    //SymbolicExpression AddHistory(Language call, SymbolicExpression operation, Pairlist args, REnvironment environment);
    //function AddHistory: TSymbolicExpression;
    // -- End Unix-only
  end;

implementation


{ TConsoleDevice }

//------------------------------------------------------------------------------
function TConsoleDevice.Ask(question: string): TYesNoCancel;
var
  input: string;
  trs: string;
begin
  Writeln(Format('%s, y/n/c', [question]));
  ReadLn(input);
  trs := LowerCase(Trim(input));
  if (trs = '') or (Length(trs) > 1) then
    result := TYesNoCancel.Cancel
  else
  begin
    if trs = 'y' then
      result := TYesNoCancel.Yes
    else if trs = 'n' then
      result := TYesNoCancel.No
    else
      result := TYesNoCancel.Cancel;
  end;
end;
//------------------------------------------------------------------------------
procedure TConsoleDevice.Busy(which: TBusyType);
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
procedure TConsoleDevice.Callback;
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
function TConsoleDevice.ChooseFile(create: boolean): string;
begin
  { TODO : TConsoleDevice.ChooseFile - Check for Linux/OSX. }
end;
//------------------------------------------------------------------------------
procedure TConsoleDevice.CleanUp(saveAction: TStartupSaveAction;
  status: integer; runLast: boolean);
begin
  { TODO : TConsoleDevice.ChooseFile - Check for Linux/OSX. }
end;
//------------------------------------------------------------------------------
procedure TConsoleDevice.ClearErrorConsole;
begin
  { TODO : TConsoleDevice.ClearErrorConsole - Check for Linux/OSX. }
end;
//------------------------------------------------------------------------------
procedure TConsoleDevice.EditFile(fileName: string);
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
procedure TConsoleDevice.FlushConsole;
begin
  { TODO : TConsoleDevice.FlushConsole - Check for Linux/OSX. }
end;
//------------------------------------------------------------------------------
function TConsoleDevice.ReadConsole(prompt: string; capacity: integer;
  history: boolean): string;
var
  rtn: string;
begin
  WriteLn(prompt);
  ReadLn(rtn);
  result := rtn;
end;
//------------------------------------------------------------------------------
procedure TConsoleDevice.ResetConsole;
begin
  { TODO : TConsoleDevice.ResetConsole - Check for Linux/OSX. }
end;
//------------------------------------------------------------------------------
function TConsoleDevice.ShowFiles(files, headers: TArray<string>; title: string;
  delete: boolean; pager: string): boolean;
begin
  { TODO : TConsoleDevice.ShowFiles - Check for Linux/OSX. }
end;
//------------------------------------------------------------------------------
procedure TConsoleDevice.ShowMessage(msg: string);
begin
  WriteLn(msg);
end;
//------------------------------------------------------------------------------
procedure TConsoleDevice.Suicide(msg: string);
begin
  if (TOSVersion.Platform = pfLinux) or (TOSVersion.Platform = pfMacOS) then
  begin
    WriteLn(msg);
    Halt;     { TODO : Suicide error code? }
  end;
end;
//------------------------------------------------------------------------------
procedure TConsoleDevice.WriteConsole(output: string; length: integer;
  outputType: TConsoleOutputType);
begin
  //OutputDebugString(PWideChar(output));    // -- Use this to write to the IDE event window.
  Writeln(output);
end;

end.
