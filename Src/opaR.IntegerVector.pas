unit opaR.IntegerVector;

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

  Spring.Collections,

  opaR.Interfaces,
  opaR.SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.Vector,
  opaR.ProtectedPointer;

type
  TIntegerVector = class(TRVector<integer>, IIntegerVector)
  protected
    function GetDataSize: integer; override;
    function GetValue(ix: integer): integer; override;
    procedure SetValue(ix: integer; value: integer); override;
    function GetNACode: integer;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; vecLength: integer); overload;
    constructor Create(const engine: IREngine; const vector: IEnumerable<integer>); overload;
    constructor Create(const engine: IREngine; const vector: TArray<integer>); overload;
    function GetArrayFast: TArray<integer>; override;
    procedure CopyTo(const destination: TArray<integer>; copyCount: integer; sourceIndex: integer = 0; destinationIndex: integer = 0); //override;
    procedure SetVectorDirect(const values: TArray<integer>); override;
    property NACode: integer read GetNACode;
  end;

implementation

{ TIntegerVector }

//------------------------------------------------------------------------------
procedure TIntegerVector.CopyTo(const destination: TArray<integer>; copyCount,
  sourceIndex, destinationIndex: integer);
var
  offset: integer;
  PData: PInteger;
  PDestination: PInteger;
begin
  if destination = nil then
    raise EopaRException.Create('Error: Destination array cannot be nil');

  if (copyCount <= 0) then
    raise EopaRException.Create('Error: Number of elements to copy must be > 0');

  if (sourceIndex < 0) or (VectorLength < sourceIndex + copyCount) then
    raise EopaRException.Create('Error: Source array index out of bounds');

  if (destinationIndex < 0) or (Length(destination) < destinationIndex + copyCount) then
    raise EopaRException.Create('Error: Destination array index out of bounds');

  offset := GetOffset(sourceIndex);
  PData := PInteger(NativeInt(DataPointer) + offset);
  PDestination := PInteger(NativeInt(PInteger(destination)) + destinationIndex * SizeOf(integer));
  CopyMemory(PDestination, PData, copyCount * DataSize);
end;
//------------------------------------------------------------------------------
constructor TIntegerVector.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  // -- pExpr is a pointer to an integer vector.
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
constructor TIntegerVector.Create(const engine: IREngine; vecLength: integer);
begin
  // -- The base constructor calls Rf_allocVector
  inherited Create(engine, TSymbolicExpressionType.IntegerVector, vecLength);
end;
//------------------------------------------------------------------------------
constructor TIntegerVector.Create(const engine: IREngine; const vector: TArray<integer>);
var
  pExpr: PSEXPREC;
begin
  // -- There's no base constructor that uses a TArray parameter, so build
  // -- everything we need here. 

  // -- First get the pointer to the R expression.
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.IntegerVector, Length(vector));

  Create(engine, pExpr);

  // -- Now copy the array data.
  CopyMemory(DataPointer, PInteger(vector), Length(vector) * DataSize);
end;
//------------------------------------------------------------------------------
constructor TIntegerVector.Create(const engine: IREngine;
  const vector: IEnumerable<integer>);
begin
  // -- The base constructor calls SetVector(vector.ToArray), which in turn
  // -- calls SetVectorDirect (implemented in this class).
  inherited Create(engine, TSymbolicExpressionType.IntegerVector, vector);
end;
//------------------------------------------------------------------------------
function TIntegerVector.GetArrayFast: TArray<integer>;
begin
  SetLength(result, self.VectorLength);
  CopyMemory(PInteger(result), DataPointer, self.VectorLength * DataSize);
end;
//------------------------------------------------------------------------------
function TIntegerVector.GetDataSize: integer;
begin
  result := SizeOf(integer);     // -- Note that SizeOf(integer) = 4 on Win32 and x64
end;
//------------------------------------------------------------------------------
function TIntegerVector.GetNACode: integer;
begin
  // -- In .NET int.MinValue = -2147483648, in Delphi and .NET MaxInt = 2147483647.
  result := -1 * MaxInt - 1;
end;
//------------------------------------------------------------------------------
function TIntegerVector.GetValue(ix: integer): integer;
var
  pp: TProtectedPointer;
  PData: PInteger;
  offset: integer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(ix);
    PData := PInteger(NativeInt(DataPointer) + offset);
    result := PData^;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TIntegerVector.SetValue(ix, value: integer);
var
  pp: TProtectedPointer;
  PData: PInteger;
  offset: integer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(ix);
    PData := PInteger(NativeInt(DataPointer) + offset);
    PData^ := value;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TIntegerVector.SetVectorDirect(const values: TArray<integer>);
begin
  // -- Delphi, .NET and R all use contiguous memory blocks for 1D arrays.
  CopyMemory(DataPointer, PInteger(values), Length(values) * DataSize);
end;

end.



