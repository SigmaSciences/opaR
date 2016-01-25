unit opaR.IntegerMatrix;

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
  opaR.Utils,
  opaR.Matrix,
  opaR.ProtectedPointer,
  opaR.Interfaces;

type
  TIntegerMatrix = class(TRMatrix<integer>, IIntegerMatrix)
  protected
    function GetDataSize: integer; override;
    function GetValue(rowIndex, columnIndex: integer): integer; override;
    procedure InitMatrixFastDirect(matrix: TDynMatrix<integer>); override;
    procedure SetValue(rowIndex, columnIndex: integer; value: integer); override;
  public
    constructor Create(const engine: IREngine; numRows, numCols: integer); overload;
    constructor Create(const engine: IREngine; matrix: TDynMatrix<integer>); overload;
    function GetArrayFast: TDynMatrix<integer>; override;
  end;


implementation

{ TIntegerMatrix }

//------------------------------------------------------------------------------
constructor TIntegerMatrix.Create(const engine: IREngine; numRows,
  numCols: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.IntegerVector, numRows, numCols);
end;
//------------------------------------------------------------------------------
constructor TIntegerMatrix.Create(const engine: IREngine;
  matrix: TDynMatrix<integer>);
begin
  inherited Create(engine, TSymbolicExpressionType.IntegerVector, matrix);
end;
//------------------------------------------------------------------------------
function TIntegerMatrix.GetArrayFast: TDynMatrix<integer>;
var
  i: integer;
  j: integer;
begin
  SetLength(result, RowCount, ColumnCount);

  for i := 0 to RowCount - 1 do
    for j := 0 to ColumnCount - 1 do
      result[i, j] := GetValue(i, j);
end;
//------------------------------------------------------------------------------
function TIntegerMatrix.GetDataSize: integer;
begin
  result := SizeOf(integer);
end;
//------------------------------------------------------------------------------
function TIntegerMatrix.GetValue(rowIndex, columnIndex: integer): integer;
var
  pp: TProtectedPointer;
  PData: PInteger;
  offset: integer;
begin
  if (rowIndex < 0) or (rowIndex >= RowCount) then
    raise EopaRException.Create('Error: row index out of bounds');

  if (columnIndex < 0) or (columnIndex >= ColumnCount) then
    raise EopaRException.Create('Error: column index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(rowIndex, columnIndex);
    PData := PInteger(NativeInt(DataPointer) + offset);
    result := PData^;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TIntegerMatrix.InitMatrixFastDirect(matrix: TDynMatrix<integer>);
var
  numRows: integer;
  numCols: integer;
  i: integer;
  j: integer;
begin
  numRows := Length(matrix);
  if numRows <= 0 then
    raise EopaRException.Create('Error: Matrix rowCount must be greater than zero');

  // -- Default memory layout for R is column-major, while Delphi is row-major,
  // -- so can't copy blocks.
  { TODO : An R matrix can be created as row-major, but need to test for this before copying blocks. }
  numCols := Length(matrix[0]);
  for i := 0 to numRows - 1 do
    for j := 0 to numCols - 1 do
      SetValue(i, j, matrix[i, j]);
end;
//------------------------------------------------------------------------------
procedure TIntegerMatrix.SetValue(rowIndex, columnIndex, value: integer);
var
  pp: TProtectedPointer;
  PData: PInteger;
  offset: integer;
begin
  if (rowIndex < 0) or (rowIndex >= RowCount) then
    raise EopaRException.Create('Error: row index out of bounds');

  if (columnIndex < 0) or (columnIndex >= ColumnCount) then
    raise EopaRException.Create('Error: column index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(rowIndex, columnIndex);
    PData := PInteger(NativeInt(DataPointer) + offset);
    PData^ := value;
  finally
    pp.Free;
  end;
end;

end.




