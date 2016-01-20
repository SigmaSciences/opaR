unit opaR.BuiltInFunction;

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
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.RFunction;

type
  TRBuiltInFunction = class(TRFunction)
  public
    function Invoke: ISymbolicExpression; overload; override;
    function Invoke(arg: ISymbolicExpression): ISymbolicExpression; overload; override;
    function Invoke(args: TArray<ISymbolicExpression>): ISymbolicExpression; overload; override;
  end;

implementation

uses
  opaR.EngineExtension;

{ TRBuiltInFunction }

//------------------------------------------------------------------------------
function TRBuiltInFunction.Invoke(
  args: TArray<ISymbolicExpression>): ISymbolicExpression;
begin
  result := InvokeOrderedArguments(args);
end;
//------------------------------------------------------------------------------
function TRBuiltInFunction.Invoke(
  arg: ISymbolicExpression): ISymbolicExpression;
var
  arr: TArray<ISymbolicExpression>;
begin
  arr := TArray<ISymbolicExpression>.Create(arg);
  result := Invoke(arr);
end;
//------------------------------------------------------------------------------
function TRBuiltInFunction.Invoke: ISymbolicExpression;
begin
  result := CreateCallAndEvaluate(TEngineExtension(Engine).NilValue);
end;

end.
