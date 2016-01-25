unit opaR.DynamicVector;

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

R.NET uses the object type in DynamicVector. 

-------------------------------------------------------------------------------}

{ TODO : TDynamicVector - Tests for SymbolicExpressionType.SymbolicExpression }
{ TODO : TDynamicVector - Implement SymbolicExpressionType.ComplexVector }

interface

uses
  System.Variants,

  opaR.SEXPREC,
  opaR.Interfaces,
  opaR.Utils,
  opaR.Vector,
  opaR.ProtectedPointer,
  opaR.DLLFunctions;

type
  TDynamicVector = class(TRVector<Variant>, IDynamicVector)
  private
    function ReadBoolean(Ptr: PSEXPREC; offset: integer): LongBool;
    function ReadByte(Ptr: PSEXPREC; offset: integer): Byte;
    function ReadDouble(Ptr: PSEXPREC; offset: integer): double;
    function ReadInteger(Ptr: PSEXPREC; offset: integer): integer;
    function ReadString(Ptr: PSEXPREC; ix, offset: integer): string;
    function ReadSymbolicExpression(Ptr: PSEXPREC; ix: integer): ISymbolicExpression;
    procedure WriteBoolean(value: LongBool; Ptr: PSEXPREC; offset: integer);
    procedure WriteByte(value: Byte; Ptr: PSEXPREC; offset: integer);
    procedure WriteDouble(value: Extended; Ptr: PSEXPREC; offset: integer);
    procedure WriteInteger(value: integer; Ptr: PSEXPREC; offset: integer);
    procedure WriteString(const value: string; Ptr: PSEXPREC; ix: integer);
    procedure WriteSymbolicExpression(const expr: ISymbolicExpression; Ptr: PSEXPREC; ix: integer);
  protected
    function GetDataSize: integer; override;
    function GetValue(ix: integer): Variant; override;
    procedure SetValue(ix: integer; value: Variant); override;
  public
    function GetArrayFast: TArray<Variant>; override;
    procedure SetVectorDirect(const values: TArray<Variant>); override;
  end;

implementation

uses
  opaR.EngineExtension,
  opaR.VECTOR_SEXPREC,
  opaR.Factor,
  opaR.SymbolicExpression;

{ TDynamicVector }

//------------------------------------------------------------------------------
function TDynamicVector.GetArrayFast: TArray<Variant>;
var
  i: integer;
begin
  SetLength(result, VectorLength);
  for i := 0 to VectorLength - 1 do
    result[i] := GetValue(i);
end;
//------------------------------------------------------------------------------
function TDynamicVector.GetDataSize: integer;
begin
  case Type_ of
    TSymbolicExpressionType.NumericVector: result := SizeOf(double);
    TSymbolicExpressionType.IntegerVector: result := SizeOf(integer);
    TSymbolicExpressionType.CharacterVector: result := SizeOf(PSEXPREC);
    TSymbolicExpressionType.LogicalVector: result := SizeOf(LongBool);
    TSymbolicExpressionType.RawVector: result := SizeOf(byte);
    //TSymbolicExpressionType.ComplexVector: result
    else
      result := SizeOf(PSEXPREC);   // -- The default, used for ISymbolicExpression.
  end;
end;
//------------------------------------------------------------------------------
function TDynamicVector.GetValue(ix: integer): Variant;
var
  offset: integer;
  Ptr: PSEXPREC;
  fac: IFactor;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Dynamic Vector index out of bounds');

  { TODO : No protected pointer in R.NET code - not necessary? Then remove from other vector types? }
  offset := GetOffset(ix);
  Ptr := DataPointer;

  case Type_ of
    TSymbolicExpressionType.NumericVector: result := ReadDouble(Ptr, offset);
    TSymbolicExpressionType.IntegerVector: begin
      if IsFactor then
      begin
        fac := self.AsFactor;
        result := fac.GetFactor(ix);
      end
      else
        result := ReadInteger(Ptr, offset);
    end;
    TSymbolicExpressionType.CharacterVector: result := ReadString(Ptr, ix, offset);
    TSymbolicExpressionType.LogicalVector: result := ReadBoolean(Ptr, offset);
    TSymbolicExpressionType.RawVector: result := ReadByte(Ptr, offset);
    else          // -- The default, used for ISymbolicExpression.
      result := ReadSymbolicExpression(Ptr, ix);
  end;
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadBoolean(Ptr: PSEXPREC; offset: integer): LongBool;
var
  PData: PLongBool;
begin
  PData := PLongBool(NativeInt(Ptr) + offset);
  result := PData^;
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadByte(Ptr: PSEXPREC; offset: integer): Byte;
var
  PData: PByte;
begin
  PData := PByte(NativeInt(Ptr) + offset);
  result := PData^;
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadDouble(Ptr: PSEXPREC; offset: integer): double;
var
  PData: PDouble;
begin
  PData := PDouble(NativeInt(Ptr) + offset);
  result := PData^;
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadInteger(Ptr: PSEXPREC; offset: integer): integer;
var
  PData: PInteger;
begin
  PData := PInteger(NativeInt(Ptr) + offset);
  result := PData^;
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadString(Ptr: PSEXPREC; ix, offset: integer): string;
var
  PPtr: PSEXPREC;
  PData: PSEXPREC;
  offsetVec: integer;
begin
  PPtr := PSEXPREC(PPointerArray(Ptr)^[ix]);
  if (PPtr = TEngineExtension(Engine).NAStringPointer) or (PPtr = nil) then
    result := ''
  else
  begin
    offsetVec := SizeOf(TVECTOR_SEXPREC);
    PData := PSEXPREC(NativeInt(PPtr) + offsetVec);

    result := String(AnsiString(PAnsiChar(PData)));
  end;
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadSymbolicExpression(Ptr: PSEXPREC;
  ix: integer): ISymbolicExpression;
var
  PPtr: PSEXPREC;
begin
  PPtr := PSEXPREC(PPointerArray(DataPointer)^[ix]);

  if (PPtr = nil) or (PPtr = TEngineExtension(Engine).NilValue) then
    result := nil
  else
    result := TSymbolicExpression.Create(Engine, PPtr);
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.SetValue(ix: integer; value: Variant);
var
  offset: integer;
  Ptr: PSEXPREC;
  fac: IFactor;
  expr: ISymbolicExpression;
  Intf: IInterface;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  offset := GetOffset(ix);
  Ptr := DataPointer;

  case Type_ of
    TSymbolicExpressionType.NumericVector: WriteDouble(value, Ptr, offset);
    TSymbolicExpressionType.IntegerVector: begin
      if IsFactor then
      begin
        fac := self.AsFactor;
        fac.SetFactor(ix, value);
      end
      else
        WriteInteger(value, Ptr, offset);
    end;
    TSymbolicExpressionType.CharacterVector: WriteString(value, Ptr, ix);
    TSymbolicExpressionType.LogicalVector: WriteBoolean(value, Ptr, offset);
    TSymbolicExpressionType.RawVector: WriteByte(value, Ptr, offset);
    else               // -- The default, used for ISymbolicExpression.
    begin
      Intf := value;
      expr := Intf as ISymbolicExpression;
      WriteSymbolicExpression(expr, Ptr, ix);
    end;
  end;
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.SetVectorDirect(const values: TArray<Variant>);
var
  i: integer;
begin
  // -- We have to copy the values individually, even for doubles and integers.
  for i := 0 to Length(values) - 1 do
    SetValue(i, values[i]);
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteBoolean(value: LongBool; Ptr: PSEXPREC;
  offset: integer);
var
  PData: PLongBool;
begin
  PData := PLongBool(NativeInt(Ptr) + offset);
  PData^ := value;
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteByte(value: Byte; Ptr: PSEXPREC; offset: integer);
var
  PData: PByte;
begin
  PData := PByte(NativeInt(Ptr) + offset);
  PData^ := value;
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteDouble(value: Extended; Ptr: PSEXPREC;
  offset: integer);
var
  PData: PDouble;
begin
  PData := PDouble(NativeInt(Ptr) + offset);
  PData^ := value;
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteInteger(value: integer; Ptr: PSEXPREC;
  offset: integer);
var
  PData: PInteger;
begin
  PData := PInteger(NativeInt(Ptr) + offset);
  PData^ := value;
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteString(const value: string; Ptr: PSEXPREC;
  ix: integer);
var
  PData: PSEXPREC;
begin
  if value = '' then
    PData := TEngineExtension(Engine).NAStringPointer
  else
    PData := Engine.Rapi.MakeChar(PAnsiChar(AnsiString(value)));

  PPointerArray(Ptr)^[ix] := PData;
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteSymbolicExpression(const expr: ISymbolicExpression;
  Ptr: PSEXPREC; ix: integer);
var
  PData: PSEXPREC;
begin
  if expr = nil then
    PData := TEngineExtension(Engine).NilValue
  else
    PData := expr.Handle;

  PPointerArray(DataPointer)^[ix] := PData;
end;

end.
