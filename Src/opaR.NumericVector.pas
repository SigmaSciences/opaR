unit opaR.NumericVector;

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
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.Types,

  {$IFNDEF NO_SPRING}
    Spring.Collections,
  {$ENDIF}

  opaR.Interfaces,
  opaR.SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.Vector,
  opaR.ProtectedPointer;


type
  TNumericVector = class(TRVector<double>, INumericVector)
  protected
    function GetDataSize: integer; override;
    function GetValue(ix: integer): double; override;
    procedure SetValue(ix: integer; value: double); override;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; vecLength: integer); overload;
    {$IFNDEF NO_SPRING}
      constructor Create(const engine: IREngine; const vector: IEnumerable<double>); overload;
    {$ENDIF}
    constructor Create(const engine: IREngine; const vector: TArray<double>); overload;
    function GetArrayFast: TArray<double>; override;
    procedure CopyTo(const destination: TArray<double>; copyCount: integer; sourceIndex: integer = 0; destinationIndex: integer = 0); //override;
    procedure SetVectorDirect(const values: TArray<double>); override;
  end;


implementation


{ TNumericVector }

//------------------------------------------------------------------------------
constructor TNumericVector.Create(const engine: IREngine; vecLength: integer);
begin
  // -- The base constructor calls Rf_allocVector
  inherited Create(engine, TSymbolicExpressionType.NumericVector, vecLength);
end;
//------------------------------------------------------------------------------
constructor TNumericVector.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  // -- pExpr is a pointer to a numeric vector.
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
{$IFNDEF NO_SPRING}
  constructor TNumericVector.Create(const engine: IREngine; const vector: IEnumerable<double>);
  begin
    // -- The base constructor calls SetVector(vector.ToArray), which in turn
    // -- calls SetVectorDirect (implemented in this class).
    inherited Create(engine, TSymbolicExpressionType.NumericVector, vector);
  end;
{$ENDIF}
//------------------------------------------------------------------------------
constructor TNumericVector.Create(const engine: IREngine; const vector: TArray<double>);
var
  pExpr: PSEXPREC;
begin
  // -- There's no base constructor that uses a TArray parameter, so build
  // -- everything we need here. R.NET calls the base constructor that uses
  // -- the vector length, but this seems to create an extra array. ??

  // -- First get the pointer to the R expression.
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.NumericVector, Length(vector));

  Create(engine, pExpr);

  // -- Now copy the array data.
  CopyMemory(DataPointer, PDouble(vector), Length(vector) * DataSize);
end;
//------------------------------------------------------------------------------
function TNumericVector.GetArrayFast: TArray<double>;
begin
  SetLength(result, self.VectorLength);
  CopyMemory(PDouble(result), DataPointer, self.VectorLength * DataSize);
end;
//------------------------------------------------------------------------------
function TNumericVector.GetDataSize: integer;
begin
  result := SizeOf(double);
end;
//------------------------------------------------------------------------------
function TNumericVector.GetValue(ix: integer): double;
var
  pp: TProtectedPointer;
  PData: PDouble;
  offset: integer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(ix);
    PData := PDouble(NativeInt(DataPointer) + offset);
    result := PData^;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TNumericVector.SetValue(ix: integer; value: double);
var
  pp: TProtectedPointer;
  PData: PDouble;
  offset: integer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(ix);
    PData := PDouble(NativeInt(DataPointer) + offset);
    PData^ := value;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TNumericVector.SetVectorDirect(const values: TArray<double>);
begin
  // -- Delphi, .NET and R all use contiguous memory blocks for 1D arrays.
  CopyMemory(DataPointer, PDouble(values), Length(values) * DataSize);
end;
//------------------------------------------------------------------------------
procedure TNumericVector.CopyTo(const destination: TArray<double>; copyCount,
  sourceIndex, destinationIndex: integer);
var
  offset: integer;
  PData: PDouble;
  PDestination: PDouble;
begin
  if Length(destination) = 0 then
    raise EopaRException.Create('Error: Destination array cannot be nil');

  if (copyCount <= 0) then
    raise EopaRException.Create('Error: Number of elements to copy must be > 0');

  if (sourceIndex < 0) or (VectorLength < sourceIndex + copyCount) then
    raise EopaRException.Create('Error: Source array index out of bounds');

  if (destinationIndex < 0) or (Length(destination) < destinationIndex + copyCount) then
    raise EopaRException.Create('Error: Destination array index out of bounds');

  offset := GetOffset(sourceIndex);
  PData := PDouble(NativeInt(DataPointer) + offset);
  PDestination := PDouble(NativeInt(PDouble(destination)) + destinationIndex * SizeOf(double));
  CopyMemory(PDestination, PData, copyCount * DataSize);
end;

end.





