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
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; parent: IREnvironment); overload;
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
constructor TREnvironment.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
constructor TREnvironment.Create(const engine: IREngine; parent: IREnvironment);
var
  pExpr: PSEXPREC;
  nilPtr: PSEXPREC;
begin
  nilPtr := TEngineExtension(engine).NilValue;
  pExpr := engine.Rapi.NewEnvironment(nilPtr, nilPtr, parent.Handle);

  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
function TREnvironment.GetParent: IREnvironment;
var
  p: PSEXPREC;
begin
  p := Engine.Rapi.ENCLOS(Handle);
  if p = nil then
    result := nil
  else
    result := TREnvironment.Create(Engine, p);
end;
//------------------------------------------------------------------------------
function TREnvironment.GetSymbol(symbolName: string): ISymbolicExpression;
var
  installedName: PSEXPREC;
  pVar: PSEXPREC;
begin
  result := nil;

  if symbolName = '' then
    raise EopaRException.Create('Symbol name cannot be null');

  installedName := Engine.Rapi.Install(PAnsiChar(AnsiString(symbolName)));
  pVar := Engine.Rapi.FindVar(installedName, Handle);

  if TEngineExtension(Engine).CheckUnbound(pVar) then
    raise EopaREvaluationException.CreateFmt('Error: Object %s not found', [QuotedStr(symbolName)]);

  if TSymbolicExpressionType(Engine.Rapi.TypeOf(pVar)) = TSymbolicExpressionType.Promise then
    pVar := Engine.Rapi.Eval(pVar, Handle);

  result := TSymbolicExpression.Create(Engine, pVar);
end;
//------------------------------------------------------------------------------
function TREnvironment.GetSymbolNames(
  includeSpecialFunctions: LongBool): TArray<string>;
var
  Ptr: PSEXPREC;
  symbolNames: ICharacterVector;
begin
  Ptr := Engine.Rapi.lsInternal(Handle, includeSpecialFunctions);

  symbolNames := TCharacterVector.Create(Engine, Ptr);

  result := symbolNames.ToArray;
end;
//------------------------------------------------------------------------------
procedure TREnvironment.SetSymbol(symbolName: string;
  expression: ISymbolicExpression);
var
  installedName: PSEXPREC;
begin
  if symbolName = '' then
    raise EopaRException.Create('Symbol name cannot be null');

  if expression = nil then
    expression := TSymbolicExpression.Create(Engine, TEngineExtension(Engine).NilValue);

  //if expression.Engine <> self.Engine then            { TODO : Engine mismatch }
  //  raise EopaRException.Create('Engine mismatch');

  installedName := Engine.Rapi.Install(PAnsiChar(AnsiString(symbolName)));
  Engine.Rapi.DefineVar(installedName, expression.Handle, Handle);
end;

end.
