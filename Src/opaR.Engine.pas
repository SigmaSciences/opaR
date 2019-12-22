unit opaR.Engine;

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

Since we don't have interface helpers in Delphi, implement any methods returning
an interface within this class, rather than in an associated class helper.

-------------------------------------------------------------------------------}

{ TODO : Generic GetFunction }
{ TODO : EnableLock - needed? Do stress-tests. }

interface

uses
  //Winapi.Windows,
  System.SysUtils,
  System.Classes,

  opaR.SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.StartupParameter,
  opaR.Devices.ConsoleDevice,
  opaR.Devices.NullCharacterDevice,
  opaR.Devices.CharacterDeviceAdapter,
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.Environment,
  opaR.NativeUtility,
  opaR.Internals.Windows.RStart,
  opaR.Exception,
  opaR.Expression;

type
  TREngine = class(TInterfacedObject, IREngine)
  private
    class var FEngine: IREngine;
    class var FEnvironmentIsSet: boolean;
    class var FdllHandle: HMODULE;
    class var FDefaultDevice: ICharacterDevice;
    FRapi: TRapi;
    FIsRunning: boolean;
    FId: string;
    FStartupParameter: TStartupParameter;
    FDeviceAdapter: TCharacterDeviceAdapter;
    FEmptyEnvironment: IREnvironment;
    FGlobalEnvironment: IREnvironment;
    FAutoPrint: boolean;
    function GetHandle: HMODULE;
    function LoadRDLL: HMODULE;
    class function CreateInstance(const ID: string): IREngine;
    function GetDisposed: boolean;
    function GetEmptyEnvironment: IREnvironment;
    function GetNilValue: PSEXPREC;
    function GetGlobalEnvironment: IREnvironment;
    procedure CheckEngineIsRunning;
    procedure SetCstackChecking;
    procedure SetSymbolValue(symbolName: string; symbolValue: integer);
    procedure SetAutoPrint(const Value: boolean);
    function GetAutoPrint: boolean;
    function GetIsRunning: boolean;
    function GetRapi: TRapi;
  public
    constructor Create(const aID: string);
    destructor Destroy; override;
    function DllVersion: string;
    class function BuildRArgv(parameter: TStartupParameter): TPAnsiCharArray;
    class function EngineName: string;
    class function GetInstance(initialize: boolean = true; parameter:
        TStartupParameter = nil; device: ICharacterDevice = nil): IREngine;
    class procedure SetEnvironmentVariables(aRHomeDir: string = '');
    class procedure InitializeClassVariables;

    function CreateCharacter(value: string): ICharacterVector;
    function CreateInteger(value: integer): IIntegerVector;
    function CreateLogical(value: LongBool): ILogicalVector;
    function CreateNumeric(value: double): INumericVector;
    function CreateRaw(value: Byte): IRawVector;

    function CreateCharacterVector(arr: TArray<string>): ICharacterVector;
    function CreateIntegerVector(arr: TArray<integer>): IIntegerVector;
    function CreateLogicalVector(arr: TArray<LongBool>): ILogicalVector;
    function CreateNumericVector(arr: TArray<double>): INumericVector;
    function CreateRawVector(arr: TArray<Byte>): IRawVector;

    function CreateIntegerMatrix(value: TDynMatrix<integer>): IIntegerMatrix;
    function CreateNumericMatrix(value: TDynMatrix<double>): INumericMatrix;
    function CreateCharacterMatrix(value: TDynMatrix<string>): ICharacterMatrix;
    function CreateLogicalMatrix(value: TDynMatrix<LongBool>): ILogicalMatrix;

    function Evaluate(statement: string): ISymbolicExpression;
    function EvaluateAsList(statement: string): IGenericVector;
    function GetPredefinedSymbol(symbolName: string): ISymbolicExpression;
    function GetPredefinedSymbolPtr(symbolName: string): PSEXPREC;
    function GetSymbol(symbolName: string): ISymbolicExpression; overload;
    function GetSymbol(symbolName: string; env: IREnvironment): ISymbolicExpression; overload;
    function GetVisible: boolean;
    procedure Initialize(parameter: TStartupParameter = nil;
      device: ICharacterDevice = nil; setupMainLoop: boolean = true);
    procedure SetSymbol(name: string; expression: ISymbolicExpression); overload;
    procedure SetSymbol(name: string; expression: ISymbolicExpression; environment: IREnvironment); overload;
    property AutoPrint: boolean read GetAutoPrint write SetAutoPrint;
    property Disposed: boolean read GetDisposed;
    property EmptyEnvironment: IREnvironment read GetEmptyEnvironment;
    property GlobalEnvironment: IREnvironment read GetGlobalEnvironment;
    property Handle: HMODULE read GetHandle;
    property IsRunning: boolean read GetIsRunning;
    property NilValue: PSEXPREC read GetNilValue;
    property Rapi: TRapi read GetRapi;
  end;

implementation

uses
  opaR.EngineExtension,
  opaR.NumericVector,
  opaR.IntegerVector,
  opaR.LogicalVector,
  opaR.CharacterVector,
  opaR.RawVector,
  opaR.IntegerMatrix,
  opaR.CharacterMatrix,
  opaR.NumericMatrix,
  opaR.LogicalMatrix;

const
  {$IFDEF WIN32}
  EnvironmentDependentMaxSizeString = '4294967295';
  {$ENDIF}

  {$IFDEF WIN64}
  EnvironmentDependentMaxSizeString = '18446744073709551615';
  {$ENDIF}

  {$IFDEF MACOS32}
  EnvironmentDependentMaxSizeString = '4294967295';
  {$ENDIF}

{ TREngine }

//------------------------------------------------------------------------------
procedure TREngine.CheckEngineIsRunning;
begin
  if not FIsRunning then
    raise EopaRException.Create('This engine is not running. You may have forgotten to call Initialize');
end;
//------------------------------------------------------------------------------
constructor TREngine.Create(const aID: string);
begin
  // -- In R.NET the REngine class descends from UnmanagedDll and the R DLL
  // -- is loaded in the latter's constructor. Since we don't need any interop
  // -- we just load the DLL here in the TREngine constructor.
  FIsRunning := false;
  FId := aID;
  FAutoPrint := true;

  if not FEnvironmentIsSet then
    SetEnvironmentVariables;

  FdllHandle := LoadRDLL;
end;
//------------------------------------------------------------------------------
function TREngine.CreateCharacter(value: string): ICharacterVector;
begin
  result := CreateCharacterVector(TArray<string>.Create(value));
end;
//------------------------------------------------------------------------------
function TREngine.CreateCharacterVector(arr: TArray<string>): ICharacterVector;
begin
  if FdllHandle = 0 then
    raise EopaRException.Create('Error: Null R DLL handle');

  if not FIsRunning then
    raise EopaRException.Create('Error: R Engine is not running');

  result := TCharacterVector.Create(self as IREngine, arr);
end;
//------------------------------------------------------------------------------
class function TREngine.GetInstance(initialize: boolean = true; parameter:
    TStartupParameter = nil; device: ICharacterDevice = nil): IREngine;
begin
  // -- Normally, dllName will be empty at this point.
  if FEngine = nil then
  begin
    FEngine := CreateInstance(EngineName);

    if initialize then
      FEngine.Initialize(parameter, device);
  end;

  if FEngine.Disposed then
    raise EopaRException.Create('The single REngine instance has already been shut down. Multiple engine restart is not possible.');
  result := FEngine;
end;
//------------------------------------------------------------------------------
function TREngine.GetIsRunning: boolean;
begin
  result := FIsRunning;
end;
//------------------------------------------------------------------------------
function TREngine.LoadRDLL: HMODULE;
var
  correctRDllName: string;
begin
  correctRDllName := REnvironmentPaths.RLibraryFileName;
  result := SafeLoadLibrary(correctRDllName);

  if result = 0 then
  begin
    raise EopaRException.CreateFmt('Unable to load the R library: "%s". ' +
          'The current R_HOME value is "%s"', [correctRDllName, REnvironmentPaths.RHome]);
  end;
end;
//------------------------------------------------------------------------------
class function TREngine.CreateInstance(const ID: string): IREngine;
begin
  if Trim(ID) = '' then
    raise EopaRException.Create('Error: Empty ID is not allowed');

  result := TREngine.Create(ID);
end;
//------------------------------------------------------------------------------
function TREngine.CreateInteger(value: integer): IIntegerVector;
begin
  result := CreateIntegerVector(TArray<integer>.Create(value));
end;
//------------------------------------------------------------------------------
function TREngine.CreateIntegerVector(arr: TArray<integer>): IIntegerVector;
begin
  if FdllHandle = 0 then
    raise EopaRException.Create('Error: Null R DLL handle');

  if not FIsRunning then
    raise EopaRException.Create('Error: R Engine is not running');

  result := TIntegerVector.Create(self as IREngine, arr);
end;
//------------------------------------------------------------------------------
function TREngine.CreateLogical(value: LongBool): ILogicalVector;
begin
  result := CreateLogicalVector(TArray<LongBool>.Create(value));
end;
//------------------------------------------------------------------------------
function TREngine.CreateLogicalVector(arr: TArray<LongBool>): ILogicalVector;
begin
  if FdllHandle = 0 then
    raise EopaRException.Create('Error: Null R DLL handle');

  if not FIsRunning then
    raise EopaRException.Create('Error: R Engine is not running');

  result := TLogicalVector.Create(self as IREngine, arr);
end;
//------------------------------------------------------------------------------
function TREngine.CreateNumeric(value: double): INumericVector;
begin
  result := CreateNumericVector(TArray<double>.Create(value));
end;
//------------------------------------------------------------------------------
function TREngine.CreateNumericVector(arr: TArray<double>): INumericVector;
begin
  if FdllHandle = 0 then
    raise EopaRException.Create('Error: Null R DLL handle');

  if not FIsRunning then
    raise EopaRException.Create('Error: R Engine is not running');

  result := TNumericVector.Create(self as IREngine, arr);
end;
//------------------------------------------------------------------------------
function TREngine.CreateRaw(value: Byte): IRawVector;
begin
  result := CreateRawVector(TArray<Byte>.Create(value));
end;
//------------------------------------------------------------------------------
function TREngine.CreateRawVector(arr: TArray<Byte>): IRawVector;
begin
  if FdllHandle = 0 then
    raise EopaRException.Create('Error: Null R DLL handle');

  if not FIsRunning then
    raise EopaRException.Create('Error: R Engine is not running');

  result := TRawVector.Create(self as IREngine, arr);
end;
//------------------------------------------------------------------------------
function TREngine.CreateIntegerMatrix(value: TDynMatrix<integer>): IIntegerMatrix;
begin
  if FdllHandle = 0 then
    raise EopaRException.Create('Error: Null R DLL handle');

  if not FIsRunning then
    raise EopaRException.Create('Error: R Engine is not running');

  result := TIntegerMatrix.Create(self as IREngine, value);
end;
//------------------------------------------------------------------------------
function TREngine.CreateNumericMatrix(value: TDynMatrix<double>): INumericMatrix;
begin
  if FdllHandle = 0 then
    raise EopaRException.Create('Error: Null R DLL handle');

  if not FIsRunning then
    raise EopaRException.Create('Error: R Engine is not running');

  result := TNumericMatrix.Create(self as IREngine, value);
end;
//------------------------------------------------------------------------------
function TREngine.CreateCharacterMatrix(value: TDynMatrix<string>): ICharacterMatrix;
begin
  if FdllHandle = 0 then
    raise EopaRException.Create('Error: Null R DLL handle');

  if not FIsRunning then
    raise EopaRException.Create('Error: R Engine is not running');

  result := TCharacterMatrix.Create(self as IREngine, value);
end;
//------------------------------------------------------------------------------
function TREngine.CreateLogicalMatrix(value: TDynMatrix<LongBool>): ILogicalMatrix;
begin
  if FdllHandle = 0 then
    raise EopaRException.Create('Error: Null R DLL handle');

  if not FIsRunning then
    raise EopaRException.Create('Error: R Engine is not running');

  result := TLogicalMatrix.Create(self as IREngine, value);
end;
//------------------------------------------------------------------------------
class procedure TREngine.SetEnvironmentVariables(aRHomeDir: string = '');
begin
  if not FEnvironmentIsSet then
  begin
    REnvironmentPaths.FindRInstallPathAndSetEnvVariables(aRHomeDir);
    FEnvironmentIsSet := true;
  end;
end;
//------------------------------------------------------------------------------
procedure TREngine.SetSymbol(name: string; expression: ISymbolicExpression);
begin
  CheckEngineIsRunning;
  GlobalEnvironment.SetSymbol(name, expression);
end;
//------------------------------------------------------------------------------
procedure TREngine.SetSymbol(name: string; expression: ISymbolicExpression;
  environment: IREnvironment);
begin
  CheckEngineIsRunning;
  if environment = nil then
    environment := GlobalEnvironment;

  environment.SetSymbol(name, expression);
end;
//------------------------------------------------------------------------------
procedure TREngine.SetSymbolValue(symbolName: string; symbolValue: integer);
var
  p: PInteger;
begin
  p := FRapi.GetRProcAddress(PAnsiChar(AnsiString(symbolName)));
  if p = nil then
    raise EopaRException.Create('Error: Could not retrieve a pointer for the symbol ' + symbolName);

  p^ := symbolValue;
end;
//------------------------------------------------------------------------------
destructor TREngine.Destroy;
begin
  FIsRunning := false;

  if not Disposed then
  begin
    // -- Clean up the R environment.
    FRapi.RunExitFinalizers;
    FRapi.CleanEd;
    FRapi.CleanTempDir;
  end;

  FreeAndNil(FStartupParameter);
  FreeAndNil(FDeviceAdapter);

  // -- FreeLibrary caused an intermittent AV in FMX in earlier versions.
  // -- Leave this comment in place for future reference.
  FRapi.UnloadDLL;
  FdllHandle := 0;

  inherited;
end;
//------------------------------------------------------------------------------
function TREngine.GetAutoPrint: boolean;
begin
  result := FAutoPrint;
end;
//------------------------------------------------------------------------------
function TREngine.GetDisposed: boolean;
begin
  result := (FDllHandle = 0);
end;
//------------------------------------------------------------------------------
function TREngine.GetEmptyEnvironment: IREnvironment;
var
  p: PSEXPREC;
begin
  CheckEngineIsRunning;
  if FEmptyEnvironment = nil then
  begin
    p := GetPredefinedSymbolPtr('R_EmptyEnv');
    FEmptyEnvironment := TREnvironment.Create(FEngine, p);
  end;

  result := FEmptyEnvironment;
end;
//------------------------------------------------------------------------------
function TREngine.DllVersion: string;
begin
  result := String(AnsiString(FRapi.DLLVersion));
end;
//------------------------------------------------------------------------------
class function TREngine.EngineName: string;
begin
  result := 'opaR';
end;
//------------------------------------------------------------------------------
function TREngine.Evaluate(statement: string): ISymbolicExpression;
begin
  CheckEngineIsRunning;

  result := TEngineExtension(self as IREngine).Evaluate(statement);
end;
//------------------------------------------------------------------------------
function TREngine.EvaluateAsList(statement: string): IGenericVector;
var
  expr: TSymbolicExpression;
begin
  CheckEngineIsRunning;

  expr := TEngineExtension(self as IREngine).Evaluate(statement) as TSymbolicExpression;
  result := expr.AsList;
end;
//------------------------------------------------------------------------------
function TREngine.GetHandle: HMODULE;
begin
  result := FdllHandle;
end;
//------------------------------------------------------------------------------
function TREngine.GetNilValue: PSEXPREC;
begin
  result := GetPredefinedSymbolPtr('R_NilValue');
end;
//------------------------------------------------------------------------------
function TREngine.GetPredefinedSymbol(symbolName: string): ISymbolicExpression;
var
  p: PSEXPREC;
begin
  p := GetPredefinedSymbolPtr(symbolName);
  result := TSymbolicExpression.Create(FEngine, p);
end;
//------------------------------------------------------------------------------
function TREngine.GetPredefinedSymbolPtr(symbolName: string): PSEXPREC;
var
  ptr: Pointer;
begin
  //ptr := GetProcAddress(FdllHandle, PAnsiChar(AnsiString(symbolName)));
  ptr := FRapi.GetRProcAddress(PAnsiChar(AnsiString(symbolName)));
  result := PSEXPREC(PPointer(ptr)^);
end;
//------------------------------------------------------------------------------
function TREngine.GetRapi: TRapi;
begin
  result := FRapi;
end;
//------------------------------------------------------------------------------
function TREngine.GetSymbol(symbolName: string): ISymbolicExpression;
begin
  result := GlobalEnvironment.GetSymbol(symbolName);
end;
//------------------------------------------------------------------------------
function TREngine.GetSymbol(symbolName: string;
  env: IREnvironment): ISymbolicExpression;
begin
  if env = nil then
    env := GlobalEnvironment;
  result := env.GetSymbol(symbolName);
end;
//------------------------------------------------------------------------------
function TREngine.GetVisible: boolean;
var
  p: PBoolean;
begin
  p := FRapi.GetRProcAddress('R_Visible');
  if p = nil then           // -- R_Visible not exported.
    result := true
  else
    result := p^;
end;
//------------------------------------------------------------------------------
function TREngine.GetGlobalEnvironment: IREnvironment;
var
  p: PSEXPREC;
begin
  CheckEngineIsRunning;
  if FGlobalEnvironment = nil then
  begin
    p := GetPredefinedSymbolPtr('R_GlobalEnv');
    FGlobalEnvironment := TREnvironment.Create(FEngine, p);
  end;

  result := FGlobalEnvironment;
end;
//------------------------------------------------------------------------------
// -- In embeddedR.c, Rf_initEmbeddedR calls Rf_initialize_R and then setup_Rmainloop
// -- immediately afterwards. In RDotNet (and here) the parameters are set after
// -- initializing and before setup_Rmainloop.
procedure TREngine.Initialize(parameter: TStartupParameter = nil; device: ICharacterDevice = nil; setupMainLoop: boolean = true);
var
  status: integer;
  R_argc: integer;
  R_argv: TPAnsiCharArray;
  //replDLLinit: TRFnReplDLLinit;
  memLimit: NativeUInt;
begin
  if FIsRunning then exit;

  if parameter = nil then
    FStartupParameter := TStartupParameter.Create
  else
    FStartupParameter := parameter;

  { TODO : Possibly inject FDeviceAdapter. }
  if device = nil then    // -- R.NET assumes we have a Console - use TNullCharacterDevice here.
    FDeviceAdapter := TCharacterDeviceAdapter.Create(TNullCharacterDevice.Create as ICharacterDevice)
    //FDeviceAdapter := TCharacterDeviceAdapter.Create(TConsoleDevice.Create as ICharacterDevice)
  else
    FDeviceAdapter := TCharacterDeviceAdapter.Create(device);

  // -- TRapi gives access to the exported R DLL API.
  FRapi := TRapi.Create(FdllHandle);

  SetCstackChecking;
  if (not setupMainLoop) then
  begin
    FIsRunning := true;
    exit;
  end;

  FRapi.SetStartTime;

  // -- Build the argument list for the initialization call.
  R_argv := BuildRArgv(FStartupParameter);
  R_argc := Length(R_argv);
  status := FRapi.InitializeR(R_argc, PPAnsiCharArray(@R_argv[0]));

  if status = 0 then
  begin
    SetCstackChecking;

    // -- R_ReplDLLinit is called by RInside, but not by R.NET. It seems to
    // -- have no effect in opaR. Leave the following in place for reference.
    //replDLLinit := GetProcAddress(FdllHandle, 'R_ReplDLLinit');
    //replDLLinit;

    FDeviceAdapter.Install(self, FStartupParameter);

    // -- Retrieving default values is not done in R.NET, and seems to have
    // -- no effect in opaR. Leave the following in place for reference.
    {defParams := GetProcAddress(FdllHandle, 'R_DefParams');
    case TOSVersion.Platform of
      //pfWindows: defParams(FStartupParameter.Start);
      //pfMacOS, pfLinux: defParams(FStartupParameter.Start.Common);
    end;}

    //setParams := GetProcAddress(FdllHandle, 'R_SetParams');
    case TOSVersion.Platform of
      pfWindows: FRapi.SetParams(FStartupParameter.Start);
      //pfMacOS, pfLinux: FRapi.SetParams(FStartupParameter.Start.Common);
    end;

    FRapi.SetupMainLoop;

    SetCstackChecking;
    FIsRunning := true;

    // -- From R.NET sources: Partial Workaround for https://rdotnet.codeplex.com/workitem/110
    if TOSVersion.Platform = pfWindows then
    begin
      memLimit := FStartupParameter.MaxMemorySize div 1048576;
      Evaluate('invisible(memory.limit(' + IntToStr(memLimit) + '))');
    end;
  end
  else
    raise EopaRException.Create('Error: A call to Rf_initialize_R returned a non-zero value (' + IntToStr(status) + ')');
end;
//------------------------------------------------------------------------------
class function TREngine.BuildRArgv(parameter: TStartupParameter): TPAnsiCharArray;
var
  i: integer;
  paramList: TStringList;
  intSize: UInt64;
begin
  paramList := TStringList.Create;

  try
    paramList.Add('opaR_app');      // -- ?? What's this for? R.NET adds "rdotnet_app".

    if (parameter.Quiet) and (not parameter.Interactive) then
      paramList.Add('--quiet');

    if (parameter.Slave) then
      paramList.Add('--slave');

    if (not (TOSVersion.Platform = pfWindows)) then
      paramList.Add('--interactive');

    if (parameter.Verbose) then
      paramList.Add('--verbose');

    if (not parameter.LoadSiteFile) then
      paramList.Add('--no-site-file');

    if (not parameter.LoadInitFile) then
      paramList.Add('--no-init-file');

    if (parameter.NoRenviron) then
      paramList.Add('--no-environ');

    case parameter.SaveAction of
      TStartupSaveAction.NoSave: paramList.Add('--no-save');
      TStartupSaveAction.Save: paramList.Add('--save');
    end;

    case parameter.RestoreAction of
      TStartupRestoreAction.NoRestore: paramList.Add('--no-restore-data');
      TStartupRestoreAction.Restore: paramList.Add('--restore');
    end;

    if TOSVersion.Architecture = arIntelX64 then
      intSize := UInt64.MaxValue
    else
      intSize := UInt32.MaxValue;

    // -- If parameter.MaxMemorySize = intSize then do nothing (see https://rdotnet.codeplex.com/workitem/72)
    // -- For Unix leave MaxMemorySize at default - see https://rdotnet.codeplex.com/workitem/137
    if (parameter.MaxMemorySize <> intSize) and (TOSVersion.Platform = pfWindows) then
      paramList.Add('--max-mem-size=' + EnvironmentDependentMaxSizeString);   //IntToStr(parameter.MaxMemorySize) returns -1

    paramList.Add('--max-ppsize=' + IntToStr(parameter.StackSize));

    // -- Convert our string list to an array of PAnsiChar.
    SetLength(result, paramList.Count);
    for i := 0 to paramList.Count - 1 do
      result[i] := PAnsiChar(PAnsiString(paramList.Strings[i]));
  finally
    paramList.Free;
  end;
end;

class procedure TREngine.InitializeClassVariables;
begin
  FEngine := nil;
  FEnvironmentIsSet := False;
  FdllHandle := 0;
  // -- Note that in R.NET the default device is ConsoleDevice.
  FDefaultDevice := TNullCharacterDevice.Create;
end;

//------------------------------------------------------------------------------
procedure TREngine.SetAutoPrint(const Value: boolean);
begin
  FAutoPrint := Value;
end;
//------------------------------------------------------------------------------
procedure TREngine.SetCstackChecking;
begin
  SetSymbolValue('R_CStackLimit', -1);
  case TOSVersion.Platform of
    pfMacOS, pfLinux: SetSymbolValue('R_SignalHandlers', 0);
  end;
end;

initialization
  TREngine.InitializeClassVariables;

end.
