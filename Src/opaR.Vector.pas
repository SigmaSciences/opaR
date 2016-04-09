unit opaR.Vector;

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

Notes:

1. Use VectorLength instead of Length property - the latter conflicts with the
array Length() function.
2. In R.NET the RVector CopyTo is not abstract - it copies elements from the
internal managed array to a destination managed array.

-------------------------------------------------------------------------------}



interface

uses
  System.Types,

  {$IFNDEF NO_SPRING}
  Spring.Collections,
  {$ENDIF}

  opaR.Interfaces,
  opaR.VectorUtils,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.VECTOR_SEXPREC,
  opaR.SEXPREC,
  opaR.ProtectedPointer,
  opaR.SymbolicExpression;

type
  TRVector<T> = class;

  TVectorEnumerator<T> = class(TInterfacedObject, IVectorEnumerator<T>)
  private
    FVector: TRVector<T>;
    FIndex: Integer;
    function GetCurrent: T; virtual;
  public
    constructor Create(Owner: TRVector<T>);
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  TRVector<T> = class abstract (TSymbolicExpression, IRVector<T>)
  private
    function GetIndex(const name: string): integer;
    function GetLength: integer;
    function GetDataPointer: PSEXPREC;
    procedure SetVector(const values: TArray<T>);
    function GetValueByName(const name: string): T; virtual;
    procedure SetValueByName(const name: string; value: T); virtual;
  protected
    function GetArrayFast: TArray<T>; virtual; abstract;
    function GetDataSize: integer; virtual; abstract;
    function GetOffset(index: integer): integer;
    function GetValue(ix: integer): T; virtual; abstract;
    procedure SetValue(ix: integer; value: T); virtual; abstract;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine;
      expressionType: TSymbolicExpressionType; vecLength: integer); overload;
    {$IFNDEF NO_SPRING}
    constructor Create(const engine: IREngine;
      expressionType: TSymbolicExpressionType; const vector: IEnumerable<T>); overload;
    {$ENDIF}
    function First: T;
    function GetEnumerator: IVectorEnumerator<T>;
    function Names: TArray<string>;
    function ToArray: TArray<T>;
    //procedure CopyTo(destination: TArray<T>; copyCount: integer; sourceIndex: integer = 0; destinationIndex: integer = 0); virtual; abstract;
    procedure SetVectorDirect(const values: TArray<T>); virtual; abstract;
    property DataPointer: PSEXPREC read GetDataPointer;
    property DataSize: integer read GetDataSize;
    property VectorLength: integer read GetLength;
    property Values[ix: integer]: T read GetValue write SetValue; default;
    property Values[const name: string]: T read GetValueByName write SetValueByName; default;
  end;


implementation

uses
  opaR.EngineExtension,
  opaR.CharacterVector;


{ TVectorEnumerator }

//------------------------------------------------------------------------------
constructor TVectorEnumerator<T>.Create(Owner: TRVector<T>);
begin
  inherited Create;
  FVector := Owner;
  FIndex := -1;
end;
//------------------------------------------------------------------------------
function TVectorEnumerator<T>.GetCurrent: T;
begin
  result := FVector.GetValue(FIndex);
end;
//------------------------------------------------------------------------------
function TVectorEnumerator<T>.MoveNext: Boolean;
begin
  result := FIndex < FVector.VectorLength - 1;
  if result then
    Inc(FIndex);
end;


{ TRVector<T> }

//------------------------------------------------------------------------------
constructor TRVector<T>.Create(const engine: IREngine;
  expressionType: TSymbolicExpressionType; vecLength: integer);
var
  pExpr: PSEXPREC;
begin
  if vecLength <= 0 then
    raise EopaRException.Create('Error: Vector length must be greater than zero');

  // -- First get the pointer to the R expression.
  pExpr := Engine.Rapi.AllocVector(expressionType, vecLength);

  inherited Create(engine, pExpr);

  { TODO : TRVector - do we need this empty FArray copy (from R.NET)? }
  //SetLength(FArray, vecLength * DataSize);
  // -- Now copy the array - this just initializes the R vector.
  //CopyMemory(DataPointer, @FArray[0], vecLength * DataSize);
end;
//------------------------------------------------------------------------------
constructor TRVector<T>.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
{$IFNDEF NO_SPRING}
constructor TRVector<T>.Create(const engine: IREngine;
  expressionType: TSymbolicExpressionType; const vector: IEnumerable<T>);
begin
  Create(engine, expressionType, vector.Count);
  SetVector(vector.ToArray);
end;
{$ENDIF}
//------------------------------------------------------------------------------
function TRVector<T>.First: T;
begin
  result := GetValue(0);
end;
//------------------------------------------------------------------------------
function TRVector<T>.GetDataPointer: PSEXPREC;
var
  offset: integer;
  h: PSEXPREC;
begin
  // -- TVECTOR_SEXPREC is the header of the vector, with the actual data behind it.
  offset := SizeOf(TVECTOR_SEXPREC);
  h := Handle;
  result := PSEXPREC(NativeInt(h) + offset);
end;
//------------------------------------------------------------------------------
function TRVector<T>.GetEnumerator: IVectorEnumerator<T>;
begin
  result := TVectorEnumerator<T>.Create(self);
end;
//------------------------------------------------------------------------------
function TRVector<T>.GetLength: integer;
begin
  result := Engine.Rapi.Length(Handle);     // -- Handle is the pointer (PSEXPREC) to the underlying SEXPREC structure.
end;
//------------------------------------------------------------------------------
function TRVector<T>.GetOffset(index: integer): integer;
begin
  result := DataSize * index;
end;
//------------------------------------------------------------------------------
function TRVector<T>.GetValueByName(const name: string): T;
var
  ix: integer;
begin
  ix := GetIndex(name);
  if ix > -1 then
    result := GetValue(ix);
end;
//------------------------------------------------------------------------------
function TRVector<T>.Names: TArray<string>;
var
  namesSymbol: ISymbolicExpression;
  namesExpr: ISymbolicExpression;
  namesVector: ICharacterVector;
  vecLength: integer;
  i: integer;
begin
  namesSymbol := TEngineExtension(Engine).GetPredefinedSymbol('R_NamesSymbol');

  namesExpr := GetAttribute(namesSymbol);
  if namesExpr = nil then
    Exit(nil);

  namesVector := (namesExpr as TSymbolicExpression).AsCharacter;
  if namesVector = nil then
    Exit(nil);

  vecLength := namesVector.VectorLength;
  SetLength(result, vecLength);
  for i := 0 to vecLength - 1 do
    result[i] := namesVector[i];
end;
//------------------------------------------------------------------------------
procedure TRVector<T>.SetValueByName(const name: string; value: T);
var
  ix: integer;
begin
  ix := GetIndex(name);
  if ix > -1 then
    SetValue(ix, value);
end;
//------------------------------------------------------------------------------
function TRVector<T>.GetIndex(const name: string): integer;
var
  namesArray: TArray<string>;
  i: integer;
begin
  result := -1;
  if name = '' then
    raise EopaRException.Create('Indexing a vector by name requires a non-null name argument');

  namesArray := Names;
  if Length(namesArray) = 0 then
    raise EopaRException.Create('The vector has no names defined - indexing it by name cannot be supported');

  for i := 0 to Length(namesArray) - 1 do
  begin
    if namesArray[i] = name then
    begin
      result := i;
      break;
    end;
  end;
end;
//------------------------------------------------------------------------------
procedure TRVector<T>.SetVector(const values: TArray<T>);
var
  pp: TProtectedPointer;
begin
  if (Length(values) <> self.VectorLength) then
    raise EopaRException.Create('Error: The length of the array provided differs from the vector length');

  pp := TProtectedPointer.Create(self);
  try
    SetVectorDirect(values);
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
function TRVector<T>.ToArray: TArray<T>;
var
  pp: TProtectedPointer;
begin
  pp := TProtectedPointer.Create(self);
  try
    result := GetArrayFast;
  finally
    pp.Free;
  end;
end;

end.
