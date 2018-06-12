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
  TIntegerVector = class(TRVector<integer>, IIntegerVector)
  protected
    function GetDataSize: integer; override;
    function GetValueByIndex(const aIndex: integer): integer; override;
    procedure SetValueByIndex(const aIndex, aValue: integer); override;
    function GetNACode: integer;
    procedure PopulateArrayFastInternal(aArrayToPopulate: TArray<Integer>);
        override;
    procedure SetVectorDirect(const aNewValues: TArray<Integer>); override;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; vecLength: integer); overload;
    {$IFNDEF NO_SPRING}
    constructor Create(const engine: IREngine; const vector: IEnumerable<integer>); overload;
    {$ENDIF}
    constructor Create(const engine: IREngine; const vector: TArray<integer>); overload;
    property NACode: integer read GetNACode;
  end;

implementation

uses
  opaR.VectorUtils;

{ TIntegerVector }
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
  SetVector(vector);
end;
//------------------------------------------------------------------------------
{$IFNDEF NO_SPRING}
constructor TIntegerVector.Create(const engine: IREngine;
  const vector: IEnumerable<integer>);
begin
  // -- The base constructor calls SetVector(vector.ToArray), which in turn
  // -- calls SetVectorDirect (implemented in this class).
  inherited Create(engine, TSymbolicExpressionType.IntegerVector, vector);
end;
{$ENDIF}
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
function TIntegerVector.GetValueByIndex(const aIndex: integer): integer;
var
  PData: PInteger;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');


  PData := TVectorAccessUtility.GetPointerToIntegerInVector(Engine, Handle, aIndex);
  result := PData^;
end;

procedure TIntegerVector.PopulateArrayFastInternal(aArrayToPopulate:
    TArray<Integer>);
var
  PData: PInteger;
  PSource: PInteger;
begin
  inherited;
  PData := @(aArrayToPopulate[0]);
  PSource := TVectorAccessUtility.GetPointerToIntegerInVector(Engine, Handle, 0);
  CopyMemory(PData, PSource, Length(aArrayToPopulate) * DataSize);
end;

//------------------------------------------------------------------------------
procedure TIntegerVector.SetValueByIndex(const aIndex, aValue: integer);
var
  PData: PInteger;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  PData := TVectorAccessUtility.GetPointerToIntegerInVector(Engine, Handle, aIndex);
  PData^ := aValue;
end;

procedure TIntegerVector.SetVectorDirect(const aNewValues: TArray<Integer>);
var
  PData: PInteger;
  PSource: PInteger;
begin
  inherited;
  PData := TVectorAccessUtility.GetPointerToIntegerInVector(Engine, Handle, 0);
  PSource := @(aNewValues[0]);
  CopyMemory(PData, PSource, Length(aNewValues) * DataSize);
end;

end.



