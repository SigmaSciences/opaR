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
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.Vector,
  opaR.Interfaces,
  opaR.ProtectedPointer;

type
  TCharacterVector = class(TRVector<string>, ICharacterVector)
  protected
    function GetDataSize: integer; override;
    function GetValueByIndex(const aIndex: integer): string; override;
    procedure PopulateArrayFastInternal(aArrayToPopulate: TArray<string>); override;
    procedure SetValueByIndex(const aIndex: integer; const aValue: string);
        override;
    procedure SetVectorDirect(const aNewValues: TArray<string>); override;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; vecLength: integer); overload;
    {$IFNDEF NO_SPRING}
    constructor Create(const engine: IREngine; const vector: IEnumerable<string>); overload;
    {$ENDIF}
    constructor Create(const engine: IREngine; const vector: TArray<string>); overload;
  end;

implementation

uses
  opaR.VectorUtils;

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
    SetValueByIndex(ix, val);
    Inc(ix);
  end;
end;
{$ENDIF}
//------------------------------------------------------------------------------
constructor TCharacterVector.Create(const engine: IREngine; const vector: TArray<string>);
var
  len: integer;
  pExpr: PSEXPREC;
begin
  // -- First get the pointer to the R expression.
  len := Length(vector);
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.CharacterVector, len);

  // -- Call the base TSymbolicExpression constructor.
  Create(engine, pExpr);

  // -- Now copy the array data.
  SetVector(vector);
end;
//------------------------------------------------------------------------------
function TCharacterVector.GetDataSize: integer;
begin
  result := SizeOf(PSEXPREC);
end;
//------------------------------------------------------------------------------
function TCharacterVector.GetValueByIndex(const aIndex: integer): string;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  result := TVectorAccessUtility.GetStringValueInVector(Engine, Handle, aIndex);
end;

procedure TCharacterVector.PopulateArrayFastInternal(aArrayToPopulate:
    TArray<string>);
var
  cntr: integer;
begin
  inherited;
  // The result array must have been sized correctly prior to this call
  for cntr := 0 to Length(aArrayToPopulate) - 1 do
    aArrayToPopulate[cntr] := ValueByIndex[cntr];
end;

//------------------------------------------------------------------------------
procedure TCharacterVector.SetValueByIndex(const aIndex: integer; const aValue:
    string);
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  TVectorAccessUtility.SetStringValueInVector(Engine, Handle, aIndex, aValue);
end;

procedure TCharacterVector.SetVectorDirect(const aNewValues: TArray<string>);
var
  cntr: integer;
begin
  inherited;
  for cntr := 0 to VectorLength - 1 do
    ValueByIndex[cntr] := aNewValues[cntr];
end;

end.


