unit opaR.CharacterVector;

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

Since Delphi strings are managed types, we cannot simply copy blocks of memory
to and from the R environment. Each string has to be copied individually, which
in turn obviously means poorer performance compared with, e.g., numeric vectors.

-------------------------------------------------------------------------------}

interface

uses
  {$IFNDEF NO_SPRING}
  Spring.Collections,
  {$ENDIF}

  opaR.SEXPREC,
  opaR.VECTOR_SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.Vector,
  opaR.Interfaces,
  opaR.ProtectedPointer;

type
  TCharacterVector = class(TRVector<string>, ICharacterVector)
  private
    function mkChar(const s: string): PSEXPREC;
  protected
    function GetDataSize: integer; override;
    function GetValue(ix: integer): string; override;
    procedure SetValue(ix: integer; value: string); override;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; vecLength: integer); overload;
    {$IFNDEF NO_SPRING}
    constructor Create(const engine: IREngine; const vector: IEnumerable<string>); overload;
    {$ENDIF}
    constructor Create(const engine: IREngine; const vector: TArray<string>); overload;
    function GetArrayFast: TArray<string>; override;
    function ToArray: TArray<string>;
    procedure CopyTo(const destination: TArray<string>; copyCount: integer; sourceIndex: integer = 0; destinationIndex: integer = 0); //override;
    procedure SetVectorDirect(const values: TArray<string>); override;
  end;

implementation

uses
  opaR.EngineExtension;

{ TCharacterVector }

//------------------------------------------------------------------------------
constructor TCharacterVector.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
constructor TCharacterVector.Create(const engine: IREngine; vecLength: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.CharacterVector, vecLength);
end;
//------------------------------------------------------------------------------
{$IFNDEF NO_SPRING}
constructor TCharacterVector.Create(const engine: IREngine; const vector: IEnumerable<string>);
var
  ix: integer;
  val: string;
  len: integer;
  pExpr: PSEXPREC;
begin
  // -- First get the pointer to the R expression.
  len := vector.Count;
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.CharacterVector, len);

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
procedure TCharacterVector.CopyTo(const destination: TArray<string>; copyCount,
  sourceIndex, destinationIndex: integer);
var
  i: integer;
  j: integer;
begin
  if (destinationIndex + copyCount) > Length(destination) then
    raise EopaRException.Create('Error: Number of copied elements exceeds destination length');

  if (sourceIndex + copyCount) > VectorLength then
    raise EopaRException.Create('Error: Number of copied elements exceeds source length');

  j := destinationIndex;
  for i := sourceIndex to sourceIndex + copyCount - 1 do
  begin
    destination[j] := self[i];
    j := j + 1;
  end;
end;
//------------------------------------------------------------------------------
constructor TCharacterVector.Create(const engine: IREngine; const vector: TArray<string>);
var
  i: integer;
  len: integer;
  pExpr: PSEXPREC;
begin
  // -- First get the pointer to the R expression.
  len := Length(vector);
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.CharacterVector, len);

  // -- Call the base TSymbolicExpression constructor.
  Create(engine, pExpr);

  // -- Now copy the array data.
  for i := 0 to len - 1 do
    SetValue(i, vector[i]);
end;
//------------------------------------------------------------------------------
function TCharacterVector.GetArrayFast: TArray<string>;
var
  i: integer;
begin
  SetLength(result, VectorLength);
  for i := 0 to VectorLength - 1 do
    result[i] := GetValue(i);
end;
//------------------------------------------------------------------------------
function TCharacterVector.GetDataSize: integer;
begin
  result := SizeOf(PSEXPREC);
end;
//------------------------------------------------------------------------------
function TCharacterVector.mkChar(const s: string): PSEXPREC;
begin
  // -- The call to Rf_mkChar gets us a CHARSXP, either from R's global cache
  // -- or by creating a new one.
  result := Engine.Rapi.MakeChar(PAnsiChar(AnsiString(s)));
end;
//------------------------------------------------------------------------------
function TCharacterVector.GetValue(ix: integer): string;
var
  offset: integer;
  PPtr: PSEXPREC;
  PData: PSEXPREC;
  pp: TProtectedPointer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    // -- Each string is stored in a global pool of C-style strings, and the
    // -- parent vector is an array of CHARSXP pointers to those strings.
    PPtr := PSEXPREC(PPointerArray(DataPointer)^[ix]);

    if (PPtr = TEngineExtension(Engine).NAStringPointer) or (PPtr = nil) then
      result := ''
    else
    begin
      // -- At this point we have a pointer to the character vector, so we now
      // -- need to offset by the TVECTOR_SEXPREC header size to get the pointer
      // -- to the string.
      offset := SizeOf(TVECTOR_SEXPREC);
      PData := PSEXPREC(NativeInt(PPtr) + offset);

      result := String(AnsiString(PAnsiChar(PData)));
    end;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TCharacterVector.SetValue(ix: integer; value: string);
var
  PData: PSEXPREC;
  pp: TProtectedPointer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    if value = '' then
      PData := TEngineExtension(Engine).NAStringPointer
    else
      PData := mkChar(value);

    PPointerArray(DataPointer)^[ix] := PData;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TCharacterVector.SetVectorDirect(const values: TArray<string>);
var
  i: integer;
begin
  // -- Since strings are managed types we can't use CopyMemory as in the
  // -- NumericVector, so this will be relatively slow.
  for i := 0 to Length(values) - 1 do
    SetValue(i, values[i]);
end;
//------------------------------------------------------------------------------
function TCharacterVector.ToArray: TArray<string>;
var
  pp: TProtectedPointer;
begin
  SetLength(result, VectorLength);
  pp := TProtectedPointer.Create(self);
  try
    result := GetArrayFast;
  finally
    pp.Free;
  end;
end;

end.


