unit opaR.RawVector;

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
  TRawVector = class(TRVector<Byte>, IRawVector)
  protected
    function GetDataSize: integer; override;
    function GetValueByIndex(const aIndex: integer): Byte; override;
    procedure PopulateArrayFastInternal(aArrayToPopulate: TArray<Byte>); override;
    procedure SetValueByIndex(const aIndex: integer; const aValue: Byte); override;
    procedure SetVectorDirect(const aNewValues: TArray<Byte>); override;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine; vecLength: integer); overload;
    {$IFNDEF NO_SPRING}
      constructor Create(const engine: IREngine; const vector: IEnumerable<Byte>); overload;
    {$ENDIF}
    constructor Create(const engine: IREngine; const vector: TArray<Byte>); overload;
  end;

implementation

uses
  opaR.VectorUtils;

{ TRawVector }
//------------------------------------------------------------------------------
constructor TRawVector.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
constructor TRawVector.Create(const engine: IREngine; vecLength: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.RawVector, vecLength);
end;
//------------------------------------------------------------------------------
constructor TRawVector.Create(const engine: IREngine; const vector: TArray<Byte>);
var
  pExpr: PSEXPREC;
begin
  // -- First get the pointer to the R expression.
  pExpr := Engine.Rapi.AllocVector(TSymbolicExpressionType.RawVector, Length(vector));

  Create(engine, pExpr);

  // -- Now copy the array data.
  SetVector(vector);
end;
//------------------------------------------------------------------------------
{$IFNDEF NO_SPRING}
constructor TRawVector.Create(const engine: IREngine;
  const vector: IEnumerable<Byte>);
begin
  inherited Create(engine, TSymbolicExpressionType.RawVector, vector);
end;
{$ENDIF}
//------------------------------------------------------------------------------
function TRawVector.GetDataSize: integer;
begin
  result := SizeOf(Byte);
end;
//------------------------------------------------------------------------------
function TRawVector.GetValueByIndex(const aIndex: integer): Byte;
var
  PData: PByte;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  PData := TVectorAccessUtility.GetPointerToRawInVector(Engine, Handle, aIndex);
  result := PData^;
end;

procedure TRawVector.PopulateArrayFastInternal(aArrayToPopulate: TArray<Byte>);
var
  PData: PByte;
  PSource: PByte;
begin
  inherited;
  PData := @(aArrayToPopulate[0]);
  PSource := TVectorAccessUtility.GetPointerToRawInVector(Engine, Handle, 0);
  CopyMemory(PData, PSource, Length(aArrayToPopulate) * DataSize);
end;

//------------------------------------------------------------------------------
procedure TRawVector.SetValueByIndex(const aIndex: integer; const aValue: Byte);
var
  PData: PByte;
begin
  if (aIndex < 0) or (aIndex >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  PData := TVectorAccessUtility.GetPointerToRawInVector(Engine, Handle, aIndex);
  PData^ := aValue;
end;

procedure TRawVector.SetVectorDirect(const aNewValues: TArray<Byte>);
var
  PData: PByte;
  PSource: PByte;
begin
  inherited;
  PData := TVectorAccessUtility.GetPointerToRawInVector(Engine, Handle, 0);
  PSource := @(aNewValues[0]);
  CopyMemory(PData, PSource, Length(aNewValues) * DataSize);
end;

end.
