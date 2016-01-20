unit opaR.Devices.NullCharacterDevice;

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
  System.Types,

  opaR.Utils,
  opaR.Interfaces;

type
  TNullCharacterDevice = class(TInterfacedObject, ICharacterDevice)
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
    function LoadHistory(call: IRLanguage; operation: ISymbolicExpression; args: IPairlist; environment: IREnvironment): ISymbolicExpression;
    function SaveHistory(call: IRLanguage; operation: ISymbolicExpression; args: IPairlist; environment: IREnvironment): ISymbolicExpression;
    function AddHistory(call: IRLanguage; operation: ISymbolicExpression; args: IPairlist; environment: IREnvironment): ISymbolicExpression;
    // -- End Unix-only
  end;

implementation

uses
  opaR.EngineExtension;

{ TNullCharacterDevice }

//------------------------------------------------------------------------------
function TNullCharacterDevice.AddHistory(call: IRLanguage;
  operation: ISymbolicExpression; args: IPairlist;
  environment: IREnvironment): ISymbolicExpression;
begin
  result := TEngineExtension(environment.Engine).NilValueExpression;
end;
//------------------------------------------------------------------------------
function TNullCharacterDevice.Ask(question: string): TYesNoCancel;
begin
  result := TYesNoCancel.Cancel;    // -- The default value.
end;
//------------------------------------------------------------------------------
procedure TNullCharacterDevice.Busy(which: TBusyType);
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
procedure TNullCharacterDevice.Callback;
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
function TNullCharacterDevice.ChooseFile(create: boolean): string;
begin
  result := '';
end;
//------------------------------------------------------------------------------
procedure TNullCharacterDevice.CleanUp(saveAction: TStartupSaveAction;
  status: integer; runLast: boolean);
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
procedure TNullCharacterDevice.ClearErrorConsole;
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
procedure TNullCharacterDevice.EditFile(fileName: string);
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
procedure TNullCharacterDevice.FlushConsole;
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
function TNullCharacterDevice.LoadHistory(call: IRLanguage;
  operation: ISymbolicExpression; args: IPairlist;
  environment: IREnvironment): ISymbolicExpression;
begin
  result := TEngineExtension(environment.Engine).NilValueExpression;
end;
//------------------------------------------------------------------------------
function TNullCharacterDevice.ReadConsole(prompt: string; capacity: integer;
  history: boolean): string;
begin
  result := '';
end;
//------------------------------------------------------------------------------
procedure TNullCharacterDevice.ResetConsole;
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
function TNullCharacterDevice.SaveHistory(call: IRLanguage;
  operation: ISymbolicExpression; args: IPairlist;
  environment: IREnvironment): ISymbolicExpression;
begin
  result := TEngineExtension(environment.Engine).NilValueExpression;
end;
//------------------------------------------------------------------------------
function TNullCharacterDevice.ShowFiles(files, headers: TArray<string>;
  title: string; delete: boolean; pager: string): boolean;
begin
  result := false;
end;
//------------------------------------------------------------------------------
procedure TNullCharacterDevice.ShowMessage(msg: string);
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
procedure TNullCharacterDevice.Suicide(msg: string);
begin
  // -- Do nothing.
end;
//------------------------------------------------------------------------------
procedure TNullCharacterDevice.WriteConsole(output: string; length: integer;
  outputType: TConsoleOutputType);
begin
  // -- Do nothing.
end;


end.
