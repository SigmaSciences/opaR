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
    function ReadBoolean(const ix: integer): LongBool;
    function ReadByte(const ix: integer): Byte;
    function ReadDouble(const ix: integer): double;
    function ReadInteger(const ix: integer): integer;
    function ReadString(const ix: integer): string;
    function ReadSymbolicExpression(const ix: integer): ISymbolicExpression;
    procedure WriteBoolean(const ix: integer; const value: LongBool);
    procedure WriteByte(const ix: integer; value: Byte);
    procedure WriteDouble(const ix: integer; const value: Extended);
    procedure WriteInteger(const ix, value: integer);
    procedure WriteString(const ix: integer; const value: string);
    procedure WriteSymbolicExpression(const ix: integer; const expr:
        ISymbolicExpression);
  protected
    function GetDataSize: integer; override;
    function GetValueByIndex(const aIndex: integer): Variant; override;
    procedure SetValueByIndex(const aIndex: integer; const aValue: Variant); override;
    procedure SetVectorDirect(const aNewValues: TArray<Variant>); override;
    procedure PopulateArrayFastInternal(aArrayToPopulate: TArray<Variant>);
        override;
  end;

implementation

uses
  opaR.EngineExtension,
  opaR.Factor,
  opaR.SymbolicExpression,
  opaR.VectorUtils;

{ TDynamicVector }
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
function TDynamicVector.GetValueByIndex(const aIndex: integer): Variant;
var
  fac: IFactor;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Dynamic Vector index out of bounds');

  case Type_ of
    TSymbolicExpressionType.NumericVector: result := ReadDouble(aIndex);
    TSymbolicExpressionType.IntegerVector: begin
      if IsFactor then
      begin
        fac := self.AsFactor;
        result := fac.GetFactor(aIndex);
      end
      else
        result := ReadInteger(aIndex);
    end;
    TSymbolicExpressionType.CharacterVector: result := ReadString(aIndex);
    TSymbolicExpressionType.LogicalVector: result := ReadBoolean(aIndex);
    TSymbolicExpressionType.RawVector: result := ReadByte(aIndex);
    else          // -- The default, used for ISymbolicExpression.
      result := ReadSymbolicExpression(aIndex);
  end;
end;

procedure TDynamicVector.PopulateArrayFastInternal(aArrayToPopulate:
    TArray<Variant>);
var
  cntr: integer;
begin
  inherited;
  // The result array must have been sized correctly prior to this call
  for cntr := 0 to Length(aArrayToPopulate) - 1 do
    aArrayToPopulate[cntr] := ValueByIndex[cntr];
end;

//------------------------------------------------------------------------------
function TDynamicVector.ReadBoolean(const ix: integer): LongBool;
var
  PData: PLongBool;
begin
  PData := TVectorAccessUtility.GetPointerToLogicalInVector(Engine, Handle, ix);
  result := PData^;
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadByte(const ix: integer): Byte;
var
  PData: PByte;
begin
  PData := TVectorAccessUtility.GetPointerToRawInVector(Engine, Handle, ix);
  result := PData^;
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadDouble(const ix: integer): double;
var
  PData: PDouble;
begin
  PData := TVectorAccessUtility.GetPointerToRealInVector(Engine, Handle, ix);
  result := PData^;
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadInteger(const ix: integer): integer;
var
  PData: PInteger;
begin
  PData := TVectorAccessUtility.GetPointerToIntegerInVector(Engine, Handle, ix);
  result := PData^;
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadString(const ix: integer): string;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  result := TVectorAccessUtility.GetStringValueInVector(Engine, Handle, ix);
end;
//------------------------------------------------------------------------------
function TDynamicVector.ReadSymbolicExpression(const ix: integer):
    ISymbolicExpression;
var
  PPtr: PSEXPREC;
begin
  PPtr := Engine.RApi.VectorElt(Handle, ix);

  if (PPtr = nil) or (PPtr = TEngineExtension(Engine).NilValue) then
    result := nil
  else
    result := TSymbolicExpression.Create(Engine, PPtr);
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.SetValueByIndex(const aIndex: integer; const aValue: Variant);
var
  fac: IFactor;
  expr: ISymbolicExpression;
  Intf: IInterface;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  case Type_ of
    TSymbolicExpressionType.NumericVector: WriteDouble(aIndex, aValue);
    TSymbolicExpressionType.IntegerVector: begin
      if IsFactor then
      begin
        fac := self.AsFactor;
        fac.SetFactor(aIndex, aValue);
      end
      else
        WriteInteger(aIndex, aValue);
    end;
    TSymbolicExpressionType.CharacterVector: WriteString(aIndex, aValue);
    TSymbolicExpressionType.LogicalVector: WriteBoolean(aIndex, aValue);
    TSymbolicExpressionType.RawVector: WriteByte(aIndex, aValue);
    else               // -- The default, used for ISymbolicExpression.
    begin
      Intf := aValue;
      expr := Intf as ISymbolicExpression;
      WriteSymbolicExpression(aIndex, expr);
    end;
  end;
end;

procedure TDynamicVector.SetVectorDirect(const aNewValues: TArray<Variant>);
var
  cntr: integer;
begin
  inherited;
  for cntr := 0 to VectorLength - 1 do
    ValueByIndex[cntr] := aNewValues[cntr];
end;

//------------------------------------------------------------------------------
procedure TDynamicVector.WriteBoolean(const ix: integer; const value: LongBool);
var
  PData: PLongBool;
begin
  PData := TVectorAccessUtility.GetPointerToLogicalInVector(Engine, Handle, ix);
  PData^ := value;
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteByte(const ix: integer; value: Byte);
var
  PData: PByte;
begin
  PData := TVectorAccessUtility.GetPointerToRawInVector(Engine, Handle, ix);
  PData^ := value;
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteDouble(const ix: integer; const value: Extended);
var
  PData: PDouble;
begin
  PData := TVectorAccessUtility.GetPointerToRealInVector(Engine, Handle, ix);
  PData^ := value;
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteInteger(const ix, value: integer);
var
  PData: PInteger;
begin
  PData := TVectorAccessUtility.GetPointerToIntegerInVector(Engine, Handle, ix);
  PData^ := value;
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteString(const ix: integer; const value: string);
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  TVectorAccessUtility.SetStringValueInVector(Engine, Handle, ix, Value);
end;
//------------------------------------------------------------------------------
procedure TDynamicVector.WriteSymbolicExpression(const ix: integer; const expr:
    ISymbolicExpression);
var
  PData: PSEXPREC;
begin
  if expr = nil then
    PData := TEngineExtension(Engine).NilValue
  else
    PData := expr.Handle;

  Engine.Rapi.SetVectorElt(Handle, ix, PData);
end;

end.
