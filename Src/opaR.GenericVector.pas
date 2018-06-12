unit opaR.GenericVector;

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

TGenericVector wraps the R list type. Note that this is not the same as a PairList.

-------------------------------------------------------------------------------}

interface

uses
  {$IFNDEF NO_SPRING}
  Spring.Collections,
  {$ENDIF}

  opaR.SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.Vector,
  opaR.Interfaces,
  opaR.ProtectedPointer,
  opaR.SymbolicExpression,
  opaR.PairList,
  opaR.CharacterVector;

type
  TGenericVector = class(TRObjectVector<ISymbolicExpression>, IGenericVector)
  protected
    function GetDataSize: integer; override;
    function ConvertPSEXPRECToValue(const aValue: PSEXPREC): ISymbolicExpression;
        override;
    function ConvertValueToPSEXPREC(const aValue: ISymbolicExpression): PSEXPREC;
        override;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; vecLength: integer); overload;
    {$IFNDEF NO_SPRING}
    constructor Create(const engine: IREngine; const vector: IEnumerable<TSymbolicExpression>); overload;
    {$ENDIF}
    constructor Create(const engine: IREngine; const vector: TArray<ISymbolicExpression>); overload;
    function ToPairlist: IPairlist;
    procedure SetNames(const names: TArray<string>); overload;
    procedure SetNames(const names: ICharacterVector); overload;
  end;

implementation

uses
  opaR.EngineExtension;

{ TGenericVector }

//------------------------------------------------------------------------------
constructor TGenericVector.Create(const engine: IREngine; vecLength: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.ExpressionVector, vecLength);
end;
//------------------------------------------------------------------------------
constructor TGenericVector.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
{$IFNDEF NO_SPRING}
constructor TGenericVector.Create(const engine: IREngine;
  const vector: IEnumerable<TSymbolicExpression>);
var
  ix: integer;
  val: TSymbolicExpression;
  len: integer;
  pExpr: PSEXPREC;
begin
  // -- First get the pointer to the R expression.
  len := vector.Count;
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.ExpressionVector, len);

  // -- Call the base TSymbolicExpression constructor.
  Create(engine, pExpr);

  ix := 0;
  for val in vector do
  begin
    SetValue(ix, val);
    Inc(ix);
  end;
end;
{$ENDIF}
//------------------------------------------------------------------------------
constructor TGenericVector.Create(const engine: IREngine;
  const vector: TArray<ISymbolicExpression>);
var
  len: integer;
  pExpr: PSEXPREC;
begin
  // -- First get the pointer to the R expression.
  len := Length(vector);
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.ExpressionVector, len);

  // -- Call the base TSymbolicExpression constructor.
  Create(engine, pExpr);

  // -- Now copy the array data.
  SetVectorDirect(vector);
end;

function TGenericVector.ConvertPSEXPRECToValue(const aValue: PSEXPREC):
    ISymbolicExpression;
begin
  if (aValue = nil) or (aValue = TEngineExtension(Engine).NilValue) then
    result := nil
  else
    result := TSymbolicExpression.Create(Engine, aValue);
end;

function TGenericVector.ConvertValueToPSEXPREC(const aValue:
    ISymbolicExpression): PSEXPREC;
begin
  if aValue = nil then
    result := TEngineExtension(Engine).NilValue
  else
    result := aValue.Handle;
end;

//------------------------------------------------------------------------------
function TGenericVector.GetDataSize: integer;
begin
  result := SizeOf(PSEXPREC);
end;
//------------------------------------------------------------------------------
procedure TGenericVector.SetNames(const names: TArray<string>);
var
  cv: ICharacterVector;
begin
  cv := TCharacterVector.Create(Engine, names);
  SetNames(cv);
end;
//------------------------------------------------------------------------------
procedure TGenericVector.SetNames(const names: ICharacterVector);
var
  namesSymbol: ISymbolicExpression;
  p: PSEXPREC;
begin
  if names.VectorLength <> VectorLength then
    raise EopaRException.Create('Error: Names vector must be same length as list.');

  p := TEngineExtension(Engine).GetPredefinedSymbolPtr('R_NamesSymbol');
  namesSymbol := TSymbolicExpression.Create(Engine, p);
  SetAttribute(namesSymbol, names as ISymbolicExpression);
end;
//------------------------------------------------------------------------------
function TGenericVector.ToPairlist: IPairlist;
var
  p: PSEXPREC;
begin
  p := Engine.Rapi.VectorToPairList(Handle);
  result := TPairList.Create(Engine, p);
end;

end.


