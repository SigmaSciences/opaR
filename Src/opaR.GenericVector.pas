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
  Winapi.Windows,
  Spring.Collections,

  opaR.SEXPREC,
  opaR.VECTOR_SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.Vector,
  opaR.Interfaces,
  opaR.ProtectedPointer,
  opaR.SymbolicExpression,
  opaR.PairList,
  opaR.CharacterVector;

type
  TGenericVector = class(TRVector<ISymbolicExpression>, IGenericVector)
  protected
    function GetDataSize: integer; override;
    function GetValue(ix: integer): ISymbolicExpression; override;
    procedure SetValue(ix: integer; value: ISymbolicExpression); override;
  public
    constructor Create(engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(engine: IREngine; vecLength: integer); overload;
    constructor Create(engine: IREngine; vector: IEnumerable<TSymbolicExpression>); overload;
    constructor Create(engine: IREngine; vector: TArray<ISymbolicExpression>); overload;
    function GetArrayFast: TArray<ISymbolicExpression>; override;
    function ToPairlist: IPairlist;
    procedure SetNames(names: TArray<string>); overload;
    procedure SetNames(names: ICharacterVector); overload;
    procedure SetVectorDirect(values: TArray<ISymbolicExpression>); override;
  end;

implementation

uses
  opaR.EngineExtension;

{ TGenericVector }

//------------------------------------------------------------------------------
constructor TGenericVector.Create(engine: IREngine; vecLength: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.ExpressionVector, vecLength);
end;
//------------------------------------------------------------------------------
constructor TGenericVector.Create(engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
constructor TGenericVector.Create(engine: IREngine;
  vector: IEnumerable<TSymbolicExpression>);
var
  ix: integer;
  val: TSymbolicExpression;
  len: integer;
  pExpr: PSEXPREC;
  allocVec: TRfnAllocVector;
begin
  // -- First get the pointer to the R expression.
  len := vector.Count;
  allocVec := GetProcAddress(engine.Handle, 'Rf_allocVector');
  pExpr := allocVec(TSymbolicExpressionType.ExpressionVector, len);

  // -- Call the base TSymbolicExpression constructor.
  Create(engine, pExpr);

  ix := 0;
  for val in vector do
  begin
    SetValue(ix, val);
    Inc(ix);
  end;
end;
//------------------------------------------------------------------------------
constructor TGenericVector.Create(engine: IREngine;
  vector: TArray<ISymbolicExpression>);
var
  ix: integer;
  len: integer;
  pExpr: PSEXPREC;
  allocVec: TRfnAllocVector;
begin
  // -- First get the pointer to the R expression.
  len := Length(vector);
  allocVec := GetProcAddress(engine.Handle, 'Rf_allocVector');
  pExpr := allocVec(TSymbolicExpressionType.ExpressionVector, len);

  // -- Call the base TSymbolicExpression constructor.
  Create(engine, pExpr);

  // -- Now copy the array data.
  for ix := 0 to len - 1 do
    SetValue(ix, vector[ix]);
end;
//------------------------------------------------------------------------------
function TGenericVector.GetArrayFast: TArray<ISymbolicExpression>;
var
  i: integer;
begin
  SetLength(result, VectorLength);
  for i := 0 to VectorLength - 1 do
    result[i] := GetValue(i);
end;
//------------------------------------------------------------------------------
function TGenericVector.GetDataSize: integer;
begin
  result := SizeOf(PSEXPREC);
end;
//------------------------------------------------------------------------------
function TGenericVector.GetValue(ix: integer): ISymbolicExpression;
var
  PPtr: PSEXPREC;
  pp: TProtectedPointer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    PPtr := PSEXPREC(PPointerArray(DataPointer)^[ix]);

    if (PPtr = nil) or (PPtr = TEngineExtension(Engine).NilValue) then
      result := nil
    else
      result := TSymbolicExpression.Create(Engine, PPtr);
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TGenericVector.SetNames(names: TArray<string>);
var
  cv: ICharacterVector;
begin
  cv := TCharacterVector.Create(Engine, names);
  SetNames(cv);
end;
//------------------------------------------------------------------------------
procedure TGenericVector.SetNames(names: ICharacterVector);
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
//-- Note that TGenericVector does not get involved in any lifetime management
//-- of TSymbolicExpression objects - in SetValue we just copy the pointer
//-- value to the internal R vector.
procedure TGenericVector.SetValue(ix: integer; value: ISymbolicExpression);
var
  PData: PSEXPREC;
  pp: TProtectedPointer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    if value = nil then
      PData := TEngineExtension(Engine).NilValue
    else
      PData := value.Handle;

    PPointerArray(DataPointer)^[ix] := PData;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TGenericVector.SetVectorDirect(values: TArray<ISymbolicExpression>);
var
  i: integer;
begin
  for i := 0 to VectorLength - 1 do
    SetValue(i, values[i]);
end;
//------------------------------------------------------------------------------
function TGenericVector.ToPairlist: IPairlist;
var
  p: PSEXPREC;
  vectorToPairList: TRFnVectorToPairList;
begin
  vectorToPairList := GetProcAddress(EngineHandle, 'Rf_VectorToPairList');
  p := vectorToPairList(Handle);
  result := TPairList.Create(Engine, p);
end;

end.


