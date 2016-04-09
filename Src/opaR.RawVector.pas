unit opaR.RawVector;

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
  TRawVector = class(TRVector<Byte>, IRawVector)
  protected
    function GetDataSize: integer; override;
    function GetValue(ix: integer): Byte; override;
    procedure SetValue(ix: integer; value: Byte); override;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; vecLength: integer); overload;
    {$IFNDEF NO_SPRING}
      constructor Create(const engine: IREngine; const vector: IEnumerable<Byte>); overload;
    {$ENDIF}
    constructor Create(const engine: IREngine; const vector: TArray<Byte>); overload;
    function GetArrayFast: TArray<Byte>; override;
    procedure CopyTo(const destination: TArray<Byte>; copyCount: integer; sourceIndex: integer = 0; destinationIndex: integer = 0); //override;
    procedure SetVectorDirect(const values: TArray<Byte>); override;
  end;

implementation

{ TRawVector }

//------------------------------------------------------------------------------
procedure TRawVector.CopyTo(const destination: TArray<Byte>; copyCount,
  sourceIndex, destinationIndex: integer);
var
  offset: integer;
  PData: PByte;
  PDestination: PByte;
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
  PData := PByte(NativeInt(DataPointer) + offset);
  PDestination := PByte(NativeInt(PByte(destination)) + destinationIndex * SizeOf(Byte));
  CopyMemory(PDestination, PData, copyCount * DataSize);
end;
//------------------------------------------------------------------------------
constructor TRawVector.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
constructor TRawVector.Create(const engine: IREngine; vecLength: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.RawVector, vecLength);
end;
//------------------------------------------------------------------------------
constructor TRawVector.Create(const engine: IREngine; const vector: TArray<Byte>);
var
  pExpr: PSEXPREC;
begin
  // -- First get the pointer to the R expression.
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.RawVector, Length(vector));

  Create(engine, pExpr);

  // -- Now copy the array data.
  CopyMemory(DataPointer, PByte(vector), Length(vector) * DataSize);
end;
//------------------------------------------------------------------------------
{$IFNDEF NO_SPRING}
  constructor TRawVector.Create(const engine: IREngine;
    const vector: IEnumerable<Byte>);
  begin
    inherited Create(engine, TSymbolicExpressionType.RawVector, vector);
  end;
{$ENDIF}
//------------------------------------------------------------------------------
function TRawVector.GetArrayFast: TArray<Byte>;
begin
  SetLength(result, self.VectorLength);
  CopyMemory(PByte(result), DataPointer, self.VectorLength * DataSize);
end;
//------------------------------------------------------------------------------
function TRawVector.GetDataSize: integer;
begin
  result := SizeOf(Byte);
end;
//------------------------------------------------------------------------------
function TRawVector.GetValue(ix: integer): Byte;
var
  pp: TProtectedPointer;
  PData: PByte;
  offset: integer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(ix);
    PData := PByte(NativeInt(DataPointer) + offset);
    result := PData^;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TRawVector.SetValue(ix: integer; value: Byte);
var
  pp: TProtectedPointer;
  PData: PByte;
  offset: integer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(ix);
    PData := PByte(NativeInt(DataPointer) + offset);
    PData^ := value;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TRawVector.SetVectorDirect(const values: TArray<Byte>);
begin
  CopyMemory(DataPointer, PByte(values), Length(values) * DataSize);
end;

end.
