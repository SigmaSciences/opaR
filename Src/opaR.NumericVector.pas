unit opaR.NumericVector;

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
  TNumericVector = class(TRVector<double>, INumericVector)
  protected
    function GetDataSize: integer; override;
    function GetValueByIndex(const aIndex: integer): double; override;
    procedure PopulateArrayFastInternal(aArrayToPopulate: TArray<Double>); override;
    procedure SetValueByIndex(const aIndex: integer; const aValue: double);
        override;
    procedure SetVectorDirect(const aNewValues: TArray<double>); override;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; vecLength: integer); overload;
    {$IFNDEF NO_SPRING}
      constructor Create(const engine: IREngine; const vector: IEnumerable<double>); overload;
    {$ENDIF}
    constructor Create(const engine: IREngine; const vector: TArray<double>); overload;
  end;


implementation

uses
  opaR.VectorUtils;


{ TNumericVector }

//------------------------------------------------------------------------------
constructor TNumericVector.Create(const engine: IREngine; vecLength: integer);
begin
  // -- The base constructor calls Rf_allocVector
  inherited Create(engine, TSymbolicExpressionType.NumericVector, vecLength);
end;
//------------------------------------------------------------------------------
constructor TNumericVector.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  // -- pExpr is a pointer to a numeric vector.
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
{$IFNDEF NO_SPRING}
constructor TNumericVector.Create(const engine: IREngine; const vector: IEnumerable<double>);
begin
  // -- The base constructor calls SetVector(vector.ToArray), which in turn
  // -- calls SetVectorDirect (implemented in this class).
  inherited Create(engine, TSymbolicExpressionType.NumericVector, vector);
end;
{$ENDIF}
//------------------------------------------------------------------------------
constructor TNumericVector.Create(const engine: IREngine; const vector: TArray<double>);
var
  pExpr: PSEXPREC;
begin
  // -- There's no base constructor that uses a TArray parameter, so build
  // -- everything we need here. R.NET calls the base constructor that uses
  // -- the vector length, but this seems to create an extra array. ??

  // -- First get the pointer to the R expression.
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.NumericVector, Length(vector));

  Create(engine, pExpr);

  // -- Now copy the array data.
  SetVector(vector);
end;
//------------------------------------------------------------------------------
function TNumericVector.GetDataSize: integer;
begin
  result := SizeOf(double);
end;
//------------------------------------------------------------------------------
function TNumericVector.GetValueByIndex(const aIndex: integer): double;
var
  PData: PDouble;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  PData := TVectorAccessUtility.GetPointerToRealInVector(Engine, Handle, aIndex);
  result := PData^;
end;

procedure TNumericVector.PopulateArrayFastInternal(aArrayToPopulate:
    TArray<Double>);
var
  PData: PDouble;
  PSource: PDouble;
begin
  inherited;
  PData := @(aArrayToPopulate[0]);
  PSource := TVectorAccessUtility.GetPointerToRealInVector(Engine, Handle, 0);
  CopyMemory(PData, PSource, Length(aArrayToPopulate) * DataSize);
end;

//------------------------------------------------------------------------------
procedure TNumericVector.SetValueByIndex(const aIndex: integer; const aValue:
    double);
var
  PData: PDouble;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  PData := TVectorAccessUtility.GetPointerToRealInVector(Engine, Handle, aIndex);
  PData^ := aValue;
end;

procedure TNumericVector.SetVectorDirect(const aNewValues: TArray<double>);
var
  PData: PDouble;
  PSource: PDouble;
begin
  inherited;
  PData := TVectorAccessUtility.GetPointerToRealInVector(Engine, Handle, 0);
  PSource := @(aNewValues[0]);
  CopyMemory(PData, PSource, Length(aNewValues) * DataSize);
end;

end.





