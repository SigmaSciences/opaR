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
  opaR.Utils,
  opaR.DLLFunctions,
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
    function GetValueByName(const name: string): T;
    procedure SetValueByName(const name: string; value: T);
  protected
    procedure PopulateArrayFastInternal(aArrayToPopulate: TArray<T>); virtual;
        abstract;
    function GetDataSize: integer; virtual; abstract;
    function GetValueByIndex(const aIndex: integer): T; virtual; abstract;
    procedure SetValueByIndex(const aIndex: integer; const value: T); virtual;
        abstract;
    procedure SetVectorDirect(const aNewValues: TArray<T>); virtual; abstract;
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
    procedure SetVector(const aNewValues: TArray<T>);
    function ToArray: TArray<T>;
    property DataSize: integer read GetDataSize;
    property VectorLength: integer read GetLength;
    property ValueByIndex[const aIndex: integer]: T read GetValueByIndex
        write SetValueByIndex; default;
    property ValueByName[const name: string]: T read GetValueByName write
        SetValueByName;
  end;


  TRObjectVector<TObj> = class abstract (TRVector<TObj>)
  protected
    function GetValueByIndex(const aIndex: integer): TObj; override;
    procedure SetValueByIndex(const aIndex: integer; const aValue: TObj); override;
    function ConvertPSEXPRECToValue(const aValue: PSEXPREC): TObj; virtual; abstract;
    function ConvertValueToPSEXPREC(const aValue: TObj): PSEXPREC; virtual; abstract;
    procedure PopulateArrayFastInternal(aArrayToPopulate: TArray<TObj>); override;
    procedure SetVectorDirect(const aNewValues: TArray<TObj>); override;
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
  result := FVector.GetValueByIndex(FIndex);
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

  Create(engine, pExpr);
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
  result := GetValueByIndex(0);
end;

function TRVector<T>.ToArray: TArray<T>;
var
  pp: TProtectedPointer;
begin
  SetLength(result, VectorLength);
  pp := TProtectedPointer.Create(self);
  try
    PopulateArrayFastInternal(result);
  finally
    pp.Free;
  end;
end;
////------------------------------------------------------------------------------
function TRVector<T>.GetEnumerator: IVectorEnumerator<T>;
begin
  result := TVectorEnumerator<T>.Create(self);
end;
//------------------------------------------------------------------------------
function TRVector<T>.GetLength: integer;
begin
  result := Engine.Rapi.Length(Handle);     // -- Handle is the pointer (PSEXPREC) to the underlying SEXPREC structure.
end;
////------------------------------------------------------------------------------
function TRVector<T>.GetValueByName(const name: string): T;
var
  ix: integer;
begin
  ix := GetIndex(name);
  if ix > -1 then
    result := GetValueByIndex(ix);
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
    SetValueByIndex(ix, value);
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
procedure TRVector<T>.SetVector(const aNewValues: TArray<T>);
var
  pp: TProtectedPointer;
begin
  if (Length(aNewValues) <> self.VectorLength) then
    raise EopaRException.Create('Error: The length of the array provided differs from the vector length');

  pp := TProtectedPointer.Create(self);
  try
    SetVectorDirect(aNewValues);
  finally
    pp.Free;
  end;
end;

procedure TRObjectVector<TObj>.SetVectorDirect(const aNewValues: TArray<TObj>);
var
  cntr: integer;
begin
  inherited;
  for cntr := 0 to VectorLength - 1 do
    ValueByIndex[cntr] := aNewValues[cntr];
end;

//------------------------------------------------------------------------------

function TRObjectVector<TObj>.GetValueByIndex(const aIndex: integer): TObj;
var
  PPtr: PSEXPREC;
  pp: TProtectedPointer;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    PPtr := Engine.Rapi.VectorElt(Handle, aIndex);

    result := ConvertPSEXPRECToValue(PPtr);
  finally
    pp.Free;
  end;
end;

procedure TRObjectVector<TObj>.SetValueByIndex(const aIndex: integer; const
    aValue: TObj);
var
  PData: PSEXPREC;
  pp: TProtectedPointer;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    PData := ConvertValueToPSEXPREC(aValue);

    Engine.Rapi.SetVectorElt(Handle, aIndex, PData);
  finally
    pp.Free;
  end;
end;

procedure TRObjectVector<TObj>.PopulateArrayFastInternal(aArrayToPopulate:
    TArray<TObj>);
var
  cntr: integer;
begin
  inherited;
  // The result array must have been sized correctly prior to this call
  for cntr := 0 to Length(aArrayToPopulate) - 1 do
    aArrayToPopulate[cntr] := ValueByIndex[cntr];
end;

end.
