unit opaR.Environment;

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
  Winapi.Windows,
  System.SysUtils,
  System.Types,

  opaR.Utils,
  opaR.SEXPREC,
  opaR.DLLFunctions,
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.Exception;


type
  TREnvironment = class(TSymbolicExpression, IREnvironment)
  private
    function GetParent: IREnvironment;
    //function GetEngineHandle: HMODULE;
    //function GetHandle: PSEXPREC;
  public
    constructor Create(engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(engine: IREngine; parent: IREnvironment); overload;
    //function GetInternalStructure: TSEXPREC;
    function GetSymbol(symbolName: string): ISymbolicExpression;
    function GetSymbolNames(includeSpecialFunctions: LongBool): TArray<string>;
    procedure SetSymbol(symbolName: string; expression: ISymbolicExpression);
    //property EngineHandle: HMODULE read GetEngineHandle;
    //property Handle: PSEXPREC read GetHandle;
    property Parent: IREnvironment read GetParent;
  end;


implementation

uses
  opaR.EngineExtension,
  opaR.CharacterVector;

{ TREnvironment }

//------------------------------------------------------------------------------
constructor TREnvironment.Create(engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
constructor TREnvironment.Create(engine: IREngine; parent: IREnvironment);
var
  newEnv: TRFnNewEnvironment;
  pExpr: PSEXPREC;
  nilPtr: PSEXPREC;
begin
  newEnv := GetProcAddress(engine.Handle, 'Rf_NewEnvironment');
  nilPtr := TEngineExtension(engine).NilValue;
  pExpr := newEnv(nilPtr, nilPtr, parent.Handle);

  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
function TREnvironment.GetParent: IREnvironment;
var
  sexp: TSEXPREC;
  p: PSEXPREC;
begin
  sexp := GetInternalStructure;
  p := sexp.envsxp.enclos;
  if p = nil then
    result := nil
  else
    result := TREnvironment.Create(Engine, p);
end;
//------------------------------------------------------------------------------
function TREnvironment.GetSymbol(symbolName: string): ISymbolicExpression;
var
  install: TRFnInstall;
  findVar: TRFnFindVar;
  eval: TRFnEval;
  installedName: PSEXPREC;
  pVar: PSEXPREC;
  sexp: TSEXPREC;
begin
  result := nil;

  if symbolName = '' then
    raise EopaRException.Create('Symbol name cannot be null');

  install := GetProcAddress(EngineHandle, 'Rf_install');
  installedName := install(PAnsiChar(AnsiString(symbolName)));

  findVar := GetProcAddress(EngineHandle, 'Rf_findVar');
  pVar := findVar(installedName, Handle);

  if TEngineExtension(Engine).CheckUnbound(pVar) then
    raise EopaREvaluationException.CreateFmt('Error: Object %s not found', [QuotedStr(symbolName)]);

  sexp := pVar^;
  if TSymbolicExpressionType(sexp.sxpinfo.type_) = TSymbolicExpressionType.Promise then
  begin
    eval := GetProcAddress(EngineHandle, 'Rf_eval');
    pVar := eval(pVar, Handle);
  end;
  result := TSymbolicExpression.Create(Engine, pVar);
end;
//------------------------------------------------------------------------------
function TREnvironment.GetSymbolNames(
  includeSpecialFunctions: LongBool): TArray<string>;
var
  fnlsInternal: TRFnlsInternal;
  Ptr: PSEXPREC;
  symbolNames: ICharacterVector;
  len: integer;
begin
  fnlsInternal := GetProcAddress(EngineHandle, 'R_lsInternal');
  Ptr := fnlsInternal(Handle, includeSpecialFunctions);

  symbolNames := TCharacterVector.Create(Engine, Ptr);
  len := symbolNames.VectorLength;
  SetLength(result, len);
  symbolNames.CopyTo(result, len);
end;
//------------------------------------------------------------------------------
procedure TREnvironment.SetSymbol(symbolName: string;
  expression: ISymbolicExpression);
var
  install: TRFnInstall;
  installedName: PSEXPREC;
  defineVar: TRFnDefineVar;
begin
  if symbolName = '' then
    raise EopaRException.Create('Symbol name cannot be null');

  if expression = nil then
    expression := TSymbolicExpression.Create(Engine, TEngineExtension(Engine).NilValue);

  //if expression.Engine <> self.Engine then            { TODO : Engine mismatch }
  //  raise EopaRException.Create('Engine mismatch');

  install := GetProcAddress(EngineHandle, 'Rf_install');
  installedName := install(PAnsiChar(AnsiString(symbolName)));

  defineVar := GetProcAddress(EngineHandle, 'Rf_defineVar');
  defineVar(installedName, expression.Handle, Handle);
end;

end.
