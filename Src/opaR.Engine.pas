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
  Winapi.Windows,
  System.Types,
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.RegularExpressions,
  Generics.Defaults,

  //opaR.Engine_Intf,
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
  //opaR.ExpressionVector,
  opaR.Exception,
  opaR.Expression;

type
  TREngine = class(TInterfacedObject, IREngine)
  private
    class var FEngine: IREngine;
    class var FEnvironmentIsSet: boolean;
    class var FdllHandle: HMODULE;
    class var FDefaultDevice: ICharacterDevice;
    class var FDLLPath: string;
    FIsRunning: boolean;
    FId: string;
    FStartupParameter: TStartupParameter;
    FDeviceAdapter: TCharacterDeviceAdapter;
    FEmptyEnvironment: IREnvironment;
    FGlobalEnvironment: IREnvironment;
    FDisposed: boolean;
    FAutoPrint: boolean;
    function GetHandle: HMODULE;
    function LoadRDLL(path, dllName: string): HMODULE;
    class function CreateInstance(id: string = ''; dllName: string = ''): IREngine;
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
  public
    constructor Create(id, dllName: string);
    destructor Destroy; override;
    function DllVersion: string;
    //function GetFunction<TDelegate>: TDelegate;
    class function BuildRArgv(parameter: TStartupParameter): TPAnsiCharArray;
    class function EngineName: string;
    class function GetInstance(dllName: string = ''; initialize: boolean = true;
      parameter: TStartupParameter = nil;  device: ICharacterDevice = nil): IREngine;

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

    function Evaluate(statement: string): ISymbolicExpression;
    function EvaluateAsList(statement: string): IGenericVector;
    function GetPredefinedSymbol(symbolName: string): ISymbolicExpression;
    function GetPredefinedSymbolPtr(symbolName: string): PSEXPREC;
    function GetSymbol(symbolName: string): ISymbolicExpression; overload;
    function GetSymbol(symbolName: string; env: IREnvironment): ISymbolicExpression; overload;
    function GetVisible: boolean;
    class procedure SetDefaultDevice(value: ICharacterDevice);
    class procedure SetEnvironmentVariables(path: string = ''; homeDir: string = '');
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
  end;

implementation

uses
  opaR.EngineExtension,
  opaR.NumericVector,
  opaR.IntegerVector,
  opaR.LogicalVector,
  opaR.CharacterVector,
  opaR.RawVector;

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
constructor TREngine.Create(id, dllName: string);
begin
  // -- In R.NET the REngine class descends from UnmanagedDll and the R DLL
  // -- is loaded in the latter's constructor. Since we don't need any interop
  // -- we just load the DLL here in the TREngine constructor.
  FIsRunning := false;
  FId := id;
  FDisposed := false;
  FAutoPrint := true;
  //FEnableLock := true;

  FdllHandle := LoadRDLL({FDLLPath}'', dllName);
  if FdllHandle = 0 then
    raise EopaRException.Create('Error: Unable to load R DLL from path ' + FDLLPath);
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
class function TREngine.GetInstance(dllName: string = ''; initialize: boolean = true;
  parameter: TStartupParameter = nil;  device: ICharacterDevice = nil): IREngine;
begin
  if not FEnvironmentIsSet then
    SetEnvironmentVariables;

  // -- Normally, dllName will be empty at this point.
  if FEngine = nil then
  begin
    FEngine := CreateInstance(EngineName, dllName);

    if initialize then
      FEngine.Initialize;
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
function TREngine.LoadRDLL(path, dllName: string): HMODULE;
begin
  result := SafeLoadLibrary(dllName);

  {currDir := TDirectory.GetCurrentDirectory;
  try
    TDirectory.SetCurrentDirectory(TPath.GetDirectoryName(path));
    result := SafeLoadLibrary(path + dllName);
  finally
    TDirectory.SetCurrentDirectory(currDir);
  end;}
end;
//------------------------------------------------------------------------------
class function TREngine.CreateInstance(id, dllName: string): IREngine;
begin
  if Trim(id) = '' then
    raise EopaRException.Create('Error: Empty ID is not allowed');

  if dllName = '' then
    dllName := TNativeUtility.GetRLibraryFileName;
  result := TREngine.Create(id, dllName);
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
class procedure TREngine.SetEnvironmentVariables(path: string = ''; homeDir: string = '');
begin
  //if FdllHandle <> 0 then exit;
  FEnvironmentIsSet := true;
  TNativeUtility.SetEnvironmentVariables(path, homeDir);
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
  p := GetProcAddress(FdllHandle, PAnsiChar(AnsiString(symbolName)));
  if p = nil then
    raise EopaRException.Create('Error: Could not retrieve a pointer for the symbol ' + symbolName);

  p^ := symbolValue;
end;
//------------------------------------------------------------------------------
destructor TREngine.Destroy;
var
  runExitFinalizers: TRfnRunExitFinalizers;
  cleanEd: TRfnCleanEd;
  cleanTempDir: TRfnCleanTempDir;
begin
  FIsRunning := false;

  if not FDisposed then
  begin
    // -- Clean up the R environment.
    runExitFinalizers := GetProcAddress(FdllHandle, 'R_RunExitFinalizers');
    runExitFinalizers;
    cleanEd := GetProcAddress(FdllHandle, 'Rf_CleanEd');
    cleanEd;
    cleanTempDir := GetProcAddress(FdllHandle, 'R_CleanTempDir');
    cleanTempDir;
    FDisposed := true;
  end;

  if assigned(FStartupParameter) then
    FStartupParameter.Free;

  if assigned(FDeviceAdapter) then    { TODO : Possibly inject FDeviceAdapter. }
    FDeviceAdapter.Free;

  // -- FreeLibrary caused an intermittent AV in FMX in earlier versions.
  // -- Leave this comment in place for future reference.
  FreeLibrary(FdllHandle);
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
  result := FDisposed;
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
var
  verFunction: TRFnDLLVersion;
begin
  verFunction := GetProcAddress(FdllHandle, 'getDLLVersion');
  result := String(AnsiString(verFunction));
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
{function TREngine.GetFunction<TDelegate>: TDelegate;
begin

end;}
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
  ptr := GetProcAddress(FdllHandle, PAnsiChar(AnsiString(symbolName)));
  result := PSEXPREC(PPointer(ptr)^);
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
  p := GetProcAddress(FdllHandle, 'R_Visible');
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
  init: TRFnInitialize;
  setStartTime: TRfnSetStartTime;
  mainloop: TRfnSetupMainLoop;
  status: integer;
  R_argc: integer;
  R_argv: TPAnsiCharArray;
  setParams: TRFnSetParams;
  //defParams: TRFnDefParams;
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

  SetCstackChecking;
  if (not setupMainLoop) then
  begin
    FIsRunning := true;
    exit;
  end;

  setStartTime := GetProcAddress(FdllHandle, 'R_setStartTime');
  setStartTime;

  // -- Build the argument list for the initialization call.
  R_argv := BuildRArgv(FStartupParameter);
  R_argc := Length(R_argv);
  init := GetProcAddress(FdllHandle, 'Rf_initialize_R');
  status := init(R_argc, @R_argv[0]);

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

    setParams := GetProcAddress(FdllHandle, 'R_SetParams');
    case TOSVersion.Platform of
      pfWindows: setParams(FStartupParameter.Start);
      //pfMacOS, pfLinux: setParams(FStartupParameter.Start.Common);
    end;

    mainloop := GetProcAddress(FdllHandle, 'setup_Rmainloop');
    mainloop;

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
//------------------------------------------------------------------------------
class procedure TREngine.SetDefaultDevice(value: ICharacterDevice);
begin
  FDefaultDevice := value;
end;


// -- Note that in R.NET the default device is ConsoleDevice.
initialization
  //TREngine.SetDefaultDevice(TConsoleDevice.Create as ICharacterDevice);
  TREngine.SetDefaultDevice(TNullCharacterDevice.Create);



end.
