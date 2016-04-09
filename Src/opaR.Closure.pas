unit opaR.Closure;

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
  {$IFNDEF NO_SPRING}
  Spring.Collections.Dictionaries,
  {$ELSE}
  System.Generics.Collections,
  {$ENDIF}

  opaR.Utils,
  opaR.SEXPREC,
  opaR.RFunction,
  opaR.Interfaces,
  opaR.PairList,
  opaR.Language,
  opaR.Environment;

type
  TRClosure = class(TRFunction)
  private
    function GetArgumentNames: TArray<string>;
    function GetArguments: IPairList;
    function GetBody: IRLanguage;
    function GetEnvironment: IREnvironment;
  public
    property Arguments: IPairList read GetArguments;
    property Body: IRLanguage read GetBody;
    property Environment: IREnvironment read GetEnvironment;
    function Invoke: ISymbolicExpression; overload; override;
    function Invoke(arg: ISymbolicExpression): ISymbolicExpression; overload; override;
    function Invoke(args: TArray<ISymbolicExpression>): ISymbolicExpression; overload; override;
    function Invoke(args: TDictionary<string, ISymbolicExpression>): ISymbolicExpression; overload; override;
  end;



implementation

uses
  opaR.EngineExtension;

{ TRClosure }

//------------------------------------------------------------------------------
function TRClosure.GetArgumentNames: TArray<string>;
begin
  { TODO : TRClosure.GetArgumentNames }         // -- Not used internally by R.NET - implement later.
  raise EopaRException.Create('TRClosure.GetArgumentNames not yet implemented');
  result := nil;
end;
//------------------------------------------------------------------------------
function TRClosure.GetArguments: IPairList;
var
  sexp: TSEXPREC;
begin
  sexp := GetInternalStructure;
  result := TPairList.Create(Engine, sexp.closxp.formals);
end;
//------------------------------------------------------------------------------
function TRClosure.GetBody: IRLanguage;
var
  sexp: TSEXPREC;
begin
  sexp := GetInternalStructure;
  result := TRLanguage.Create(Engine, sexp.closxp.body);
end;
//------------------------------------------------------------------------------
function TRClosure.GetEnvironment: IREnvironment;
var
  sexp: TSEXPREC;
begin
  sexp := GetInternalStructure;
  result := TREnvironment.Create(Engine, sexp.closxp.env);
end;
//------------------------------------------------------------------------------
function TRClosure.Invoke(arg: ISymbolicExpression): ISymbolicExpression;
var
  arr: TArray<ISymbolicExpression>;
begin
  arr := TArray<ISymbolicExpression>.Create(arg);
  result := Invoke(arr);
end;
//------------------------------------------------------------------------------
function TRClosure.Invoke(args: TArray<ISymbolicExpression>): ISymbolicExpression;
begin
  result := InvokeOrderedArguments(args);
end;
//------------------------------------------------------------------------------
function TRClosure.Invoke(args: TDictionary<string, ISymbolicExpression>): ISymbolicExpression;
begin
  { TODO : TRClosure.Invoke(args: TDictionary) }
  raise EopaRException.Create('TRClosure.Invoke with dictionary not yet implemented');
  result := nil;
end;
//------------------------------------------------------------------------------
function TRClosure.Invoke: ISymbolicExpression;
begin
  result := CreateCallAndEvaluate(TEngineExtension(Engine).NilValue);
end;

end.
