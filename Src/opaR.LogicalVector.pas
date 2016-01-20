unit opaR.LogicalVector;

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
  Winapi.Windows,

  Spring.Collections,

  opaR.SEXPREC,
  opaR.Utils,
  opaR.Interfaces,
  opaR.Vector,
  opaR.DLLFunctions;


type
  TLogicalVector = class(TRVector<LongBool>, ILogicalVector)
  protected
    function GetDataSize: integer; override;
    function GetValue(ix: integer): LongBool; override;
    procedure SetValue(ix: integer; value: LongBool); override;
  public
    constructor Create(engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(engine: IREngine; vecLength: integer); overload;
    constructor Create(engine: IREngine; vector: IEnumerable<LongBool>); overload;
    constructor Create(engine: IREngine; vector: TArray<LongBool>); overload;
    function GetArrayFast: TArray<LongBool>; override;
    procedure SetVectorDirect(values: TArray<LongBool>); override;
  end;


implementation

uses
  opaR.ProtectedPointer;

{ TLogicalVector }

//------------------------------------------------------------------------------
constructor TLogicalVector.Create(engine: IREngine; vecLength: integer);
begin
  // -- The base constructor calls Rf_allocVector
  inherited Create(engine, TSymbolicExpressionType.LogicalVector, vecLength);
end;
//------------------------------------------------------------------------------
constructor TLogicalVector.Create(engine: IREngine; vector: IEnumerable<LongBool>);
begin
  inherited Create(engine, TSymbolicExpressionType.LogicalVector, vector);
end;
//------------------------------------------------------------------------------
constructor TLogicalVector.Create(engine: IREngine; vector: TArray<LongBool>);
var
  pExpr: PSEXPREC;
  allocVec: TRfnAllocVector;
begin
  // -- First get the pointer to the R expression.
  allocVec := GetProcAddress(engine.Handle, 'Rf_allocVector');
  pExpr := allocVec(TSymbolicExpressionType.NumericVector, Length(vector));

  Create(engine, pExpr);

  // -- Now copy the array data.
  CopyMemory(DataPointer, PLongBool(vector), Length(vector) * DataSize);
end;
//------------------------------------------------------------------------------
constructor TLogicalVector.Create(engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
function TLogicalVector.GetArrayFast: TArray<LongBool>;
begin
  SetLength(result, self.VectorLength);
  CopyMemory(PLongBool(result), DataPointer, self.VectorLength * DataSize);
end;
//------------------------------------------------------------------------------
function TLogicalVector.GetDataSize: integer;
begin
  result := SizeOf(LongBool);
end;
//------------------------------------------------------------------------------
function TLogicalVector.GetValue(ix: integer): LongBool;
var
  pp: TProtectedPointer;
  PData: PLongBool;
  offset: integer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(ix);
    PData := PLongBool(NativeInt(DataPointer) + offset);
    result := PData^;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TLogicalVector.SetValue(ix: integer; value: LongBool);
var
  pp: TProtectedPointer;
  PData: PLongBool;
  offset: integer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(ix);
    PData := PLongBool(NativeInt(DataPointer) + offset);
    PData^ := value;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TLogicalVector.SetVectorDirect(values: TArray<LongBool>);
begin
  // -- Delphi, .NET and R all use contiguous memory blocks for 1D arrays.
  CopyMemory(DataPointer, PLongBool(values), Length(values) * DataSize);
end;

end.
