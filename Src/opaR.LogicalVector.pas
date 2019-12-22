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
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}

  {$IFNDEF NO_SPRING}
    Spring.Collections,
  {$ENDIF}

  opaR.SEXPREC,
  opaR.Utils,
  opaR.Interfaces,
  opaR.Vector,
  opaR.DLLFunctions;


type
  TLogicalVector = class(TRVector<LongBool>, ILogicalVector)
  protected
    function GetDataSize: integer; override;
    function GetValueByIndex(const aIndex: integer): LongBool; override;
    procedure PopulateArrayFastInternal(aArrayToPopulate: TArray<LongBool>);
        override;
    procedure SetValueByIndex(const aIndex: integer; const aValue: LongBool);
        override;
    procedure SetVectorDirect(const aNewValues: TArray<LongBool>); override;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; vecLength: integer); overload;
    {$IFNDEF NO_SPRING}
      constructor Create(const engine: IREngine; const vector: IEnumerable<LongBool>); overload;
    {$ENDIF}
    constructor Create(const engine: IREngine; const vector: TArray<LongBool>); overload;
  end;


implementation

uses
  opaR.ProtectedPointer, opaR.VectorUtils;

{ TLogicalVector }

//------------------------------------------------------------------------------
constructor TLogicalVector.Create(const engine: IREngine; vecLength: integer);
begin
  // -- The base constructor calls Rf_allocVector
  inherited Create(engine, TSymbolicExpressionType.LogicalVector, vecLength);
end;
//------------------------------------------------------------------------------
{$IFNDEF NO_SPRING}
  constructor TLogicalVector.Create(const engine: IREngine; const vector: IEnumerable<LongBool>);
  begin
    inherited Create(engine, TSymbolicExpressionType.LogicalVector, vector);
  end;
{$ENDIF}
//------------------------------------------------------------------------------
constructor TLogicalVector.Create(const engine: IREngine; const vector: TArray<LongBool>);
var
  pExpr: PSEXPREC;
begin
  // -- First get the pointer to the R expression.
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.LogicalVector, Length(vector));

  Create(engine, pExpr);

  // -- Now copy the array data.
  SetVector(vector);
end;
//------------------------------------------------------------------------------
constructor TLogicalVector.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
function TLogicalVector.GetDataSize: integer;
begin
  result := SizeOf(LongBool);
end;
//------------------------------------------------------------------------------
function TLogicalVector.GetValueByIndex(const aIndex: integer): LongBool;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  result := TVectorAccessUtility.GetPointerToLogicalInVector(Engine, Handle, aIndex)^;
end;

procedure TLogicalVector.PopulateArrayFastInternal(aArrayToPopulate:
    TArray<LongBool>);
var
  PData: PLongBool;
  PSource: PLongBool;
begin
  inherited;
  PData := @(aArrayToPopulate[0]);
  PSource := TVectorAccessUtility.GetPointerToLogicalInVector(Engine, Handle, 0);
  CopyMemory(PData, PSource, Length(aArrayToPopulate) * DataSize);
end;

//------------------------------------------------------------------------------
procedure TLogicalVector.SetValueByIndex(const aIndex: integer; const aValue:
    LongBool);
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  TVectorAccessUtility.GetPointerToLogicalInVector(Engine, Handle, aIndex)^ := aValue;
end;

procedure TLogicalVector.SetVectorDirect(const aNewValues: TArray<LongBool>);
var
  PData: PLongBool;
  PSource: PLongBool;
begin
  inherited;
  PData := TVectorAccessUtility.GetPointerToLogicalInVector(Engine, Handle, 0);
  PSource := @(aNewValues[0]);
  CopyMemory(PData, PSource, Length(aNewValues) * DataSize);
end;

end.
