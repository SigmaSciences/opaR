unit opaR.RFunction;

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

Requires:

1. Spring.Collections.Dictionaries from Spring4D.org
2. Generics.Tuples from https://github.com/malcolmgroves/generics.tuples

-------------------------------------------------------------------------------}

interface

uses
  Winapi.Windows,

  Spring.Collections.Dictionaries,
  Generics.Tuples,

  opaR.SEXPREC,
  opaR.DLLFunctions,
  opaR.Interfaces,
  opaR.SymbolicExpression,
  opaR.ProtectedPointer;

type
  TRFunction = class abstract (TSymbolicExpression, IRFunction)
  private
    function EvaluateCall(p: PSEXPREC): PSEXPREC;
    function InvokeNamedFast(args: TArray<TTuple<string, ISymbolicExpression>>): ISymbolicExpression;
  protected
    function CreateCallAndEvaluate(Ptr: PSEXPREC): ISymbolicExpression;
    function InvokeOrderedArguments(args: TArray<ISymbolicExpression>): ISymbolicExpression;
    function InvokeViaPairlist(argNames: TArray<string>; args: TArray<ISymbolicExpression>): ISymbolicExpression;
  public
    constructor Create(engine: IREngine; pExpr: PSEXPREC);
    function Invoke: ISymbolicExpression; overload; virtual; abstract;
    function Invoke(arg: ISymbolicExpression): ISymbolicExpression; overload; virtual; abstract;
    function Invoke(args: TArray<ISymbolicExpression>): ISymbolicExpression; overload; virtual; abstract;
    function Invoke(args: TDictionary<string, ISymbolicExpression>): ISymbolicExpression; overload; virtual; abstract;
    function InvokeNamed(args: TArray<TTuple<string, ISymbolicExpression>>): ISymbolicExpression;
    function InvokeStrArgs(args: TArray<string>): ISymbolicExpression;
  end;

implementation

uses
  opaR.CharacterVector,
  opaR.GenericVector,
  opaR.PairList,
  opaR.Exception,
  opaR.EngineExtension;

{ TRFunction }

//------------------------------------------------------------------------------
constructor TRFunction.Create(engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
function TRFunction.CreateCallAndEvaluate(Ptr: PSEXPREC): ISymbolicExpression;
var
  lCons: TRFnLCons;
  p: PSEXPREC;
  pp: TProtectedPointer;
  p2: PSEXPREC;
begin
  // -- Rf_lcons creates an expression.
  // -- Ptr is a (PairList) pointer passed from InvokeOrderedArguments.
  lCons := GetProcAddress(EngineHandle, 'Rf_lcons');
  p := lCons(Handle, Ptr);

  pp := TProtectedPointer.Create(Engine, p);
  try
    p2 := EvaluateCall(p);
    result := TSymbolicExpression.Create(Engine, p2);
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
function TRFunction.EvaluateCall(p: PSEXPREC): PSEXPREC;
var
  evalPtr: PSEXPREC;
  tryEval: TRFnTryEval;
  errorOccurred: LongBool;
  pp: TProtectedPointer;
begin
  tryEval := GetProcAddress(EngineHandle, 'R_tryEval');
  evalPtr := tryEval(p, TEngineExtension(Engine).GlobalEnvironment.Handle, errorOccurred);

  if errorOccurred then
    raise EopaREvaluationException.Create(TEngineExtension(Engine).LastErrorMessage);

  pp := TProtectedPointer.Create(Engine, evalPtr);
  try
    result := evalPtr;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
function TRFunction.InvokeNamed(args: TArray<TTuple<string, ISymbolicExpression>>): ISymbolicExpression;
begin
  result := InvokeNamedFast(args);
end;
//------------------------------------------------------------------------------
function TRFunction.InvokeNamedFast(
  args: TArray<TTuple<string, ISymbolicExpression>>): ISymbolicExpression;
var
  i: integer;
  argument: PSEXPREC;
  cons: TRFnCons;
  install: TRFnInstall;
  setTag: TRFnSetTag;
  expr: ISymbolicExpression;
  name: string;
begin
  cons := GetProcAddress(EngineHandle, 'Rf_cons');
  install := GetProcAddress(EngineHandle, 'Rf_install');
  setTag := GetProcAddress(EngineHandle, 'SET_TAG');
  argument := TEngineExtension(Engine).NilValue;

  for i := Length(args) - 1 downto 0 do
  begin
    expr := args[i].Value2;
    argument := cons(expr.Handle, argument);
    name := args[i].Value1;
    if name <> '' then
      setTag(argument, install(PAnsiChar(AnsiString(name))));
  end;

  result := CreateCallAndEvaluate(argument);
end;
//------------------------------------------------------------------------------
function TRFunction.InvokeOrderedArguments(
  args: TArray<ISymbolicExpression>): ISymbolicExpression;
var
  i: integer;
  argument: PSEXPREC;
  cons: TRFnCons;
begin
  // -- Rf_cons creates a PairList.
  cons := GetProcAddress(EngineHandle, 'Rf_cons');
  argument := TEngineExtension(Engine).NilValue;
  for i := Length(args) - 1 downto 0 do
    argument := cons(args[i].Handle, argument);

  result := CreateCallAndEvaluate(argument);
end;
//------------------------------------------------------------------------------
function TRFunction.InvokeStrArgs(args: TArray<string>): ISymbolicExpression;
var
  i: integer;
  exprArray: TArray<ISymbolicExpression>;
begin
  SetLength(exprArray, Length(args));
  for i := 0 to Length(args) - 1 do
    exprArray[i] := TEngineExtension(Engine).Evaluate(args[i]) as TSymbolicExpression;

  result := Invoke(exprArray);
end;
//------------------------------------------------------------------------------
function TRFunction.InvokeViaPairlist(argNames: TArray<string>;
  args: TArray<ISymbolicExpression>): ISymbolicExpression;
var
  names: ICharacterVector;
  arguments: IGenericVector;
  pairList: IPairList;
  h: PSEXPREC;
begin
  pairList := nil;
  names := TCharacterVector.Create(Engine, argNames);
  arguments := TGenericVector.Create(Engine, args);

  arguments.SetNames(names);
  pairList := arguments.ToPairlist;
  h := pairList.Handle;

  if h <> nil then
    result := CreateCallAndEvaluate(h)
  else
    result := nil;
end;

end.
