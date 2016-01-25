unit opaR.Expression;

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

The constructor requires a pointer (p) to an R expression, which is in turn
stored in the Handle property of the base class.

-------------------------------------------------------------------------------}

interface

uses
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.SEXPREC,
  opaR.Environment,
  opaR.SymbolicExpression,
  opaR.Interfaces;


type
  TExpression = class(TSymbolicExpression, IExpression)
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC);
    function Evaluate(const environment: IREnvironment): ISymbolicExpression;
    function TryEvaluate(const environment: IREnvironment; out rtn: ISymbolicExpression): boolean;
  end;


implementation


{ TExpression }

//------------------------------------------------------------------------------
constructor TExpression.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
{ TODO : check engine match }
function TExpression.Evaluate(const environment: IREnvironment): ISymbolicExpression;
var
  PPtr: PSEXPREC;
begin
  if environment = nil then
    raise EopaRException.Create('Null environment passed to Expression.Evaluate');

  //if environment.Engine <> Engine then
  //  raise EopaRException.Create('REngine mismatch in Expression.Evaluate');

  PPtr := Engine.Rapi.Eval(Handle, environment.Handle);
  result := TSymbolicExpression.Create(Engine, PPtr);
end;
//------------------------------------------------------------------------------
{ TODO : check engine match }
function TExpression.TryEvaluate(const environment: IREnvironment;
  out rtn: ISymbolicExpression): boolean;
var
  errorOccurred: LongBool;
  PPtr: PSEXPREC;
begin
  if environment = nil then
    raise EopaRException.Create('Null environment passed to Expression.TryEvaluate');

  //if environment.Engine <> Engine then
  //  raise EopaRException.Create('REngine mismatch in Expression.TryEvaluate');

  PPtr := Engine.Rapi.TryEval(Handle, environment.Handle, errorOccurred);

  if errorOccurred then
    rtn := nil
  else
    rtn := TSymbolicExpression.Create(Engine, PPtr);

  result := not errorOccurred;
end;

end.
