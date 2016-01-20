unit opaR.NumericMatrix;

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
  Winapi.Windows,

  opaR.Utils,
  opaR.Matrix,
  opaR.ProtectedPointer,
  opaR.Interfaces;

type
  TNumericMatrix = class(TRMatrix<double>, INumericMatrix)
  protected
    function GetDataSize: integer; override;
    function GetValue(rowIndex, columnIndex: integer): double; override;
    procedure InitMatrixFastDirect(matrix: TDynMatrix<double>); override;
    procedure SetValue(rowIndex, columnIndex: integer; value: double); override;
  public
    constructor Create(engine: IREngine; numRows, numCols: integer); overload;
    constructor Create(engine: IREngine; matrix: TDynMatrix<double>); overload;
    function GetArrayFast: TDynMatrix<double>; override;
  end;

implementation

{ TNumericMatrix }

//------------------------------------------------------------------------------
constructor TNumericMatrix.Create(engine: IREngine; numRows,
  numCols: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.NumericVector, numRows, numCols);
end;
//------------------------------------------------------------------------------
constructor TNumericMatrix.Create(engine: IREngine;
  matrix: TDynMatrix<double>);
begin
  inherited Create(engine, TSymbolicExpressionType.NumericVector, matrix);
end;
//------------------------------------------------------------------------------
function TNumericMatrix.GetArrayFast: TDynMatrix<double>;
var
  i: integer;
  j: integer;
  //vecSize: integer;
  //PData: PDouble;
  //offset: integer;
begin
  SetLength(result, RowCount, ColumnCount);
  //vecSize := RowCount * DataSize;

  for i := 0 to RowCount - 1 do
    for j := 0 to ColumnCount - 1 do
      result[i, j] := GetValue(i, j);

  // -- Different memory layout so can't copy blocks.
  {for i := 0 to ColumnCount - 1 do
  begin
    offset := NativeInt(i * vecSize);
    PData := PDouble(NativeInt(DataPointer) + offset);
    CopyMemory(PDouble(result[i]), PData, vecSize);
  end;}
end;
//------------------------------------------------------------------------------
function TNumericMatrix.GetDataSize: integer;
begin
  result := SizeOf(double);
end;
//------------------------------------------------------------------------------
function TNumericMatrix.GetValue(rowIndex, columnIndex: integer): double;
var
  pp: TProtectedPointer;
  PData: PDouble;
  offset: integer;
begin
  if (rowIndex < 0) or (rowIndex >= RowCount) then
    raise EopaRException.Create('Error: row index out of bounds');

  if (columnIndex < 0) or (columnIndex >= ColumnCount) then
    raise EopaRException.Create('Error: column index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(rowIndex, columnIndex);
    PData := PDouble(NativeInt(DataPointer) + offset);
    result := PData^;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TNumericMatrix.InitMatrixFastDirect(matrix: TDynMatrix<double>);
var
  numRows: integer;
  numCols: integer;
  i: integer;
  j: integer;
  //vecSize: integer;
  //PData: PDouble;
  //offset: integer;
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

  // -- Copy each column of the delphi array as a single block.
  {vecSize := numRows * DataSize;
  for i := 0 to numCols - 1 do
  begin
    offset := NativeInt(i * vecSize);
    PData := PDouble(NativeInt(DataPointer) + offset);
    CopyMemory(PData, PDouble(matrix[i]), vecSize);
  end;}
end;
//------------------------------------------------------------------------------
procedure TNumericMatrix.SetValue(rowIndex, columnIndex: integer;
  value: double);
var
  pp: TProtectedPointer;
  PData: PDouble;
  offset: integer;
begin
  if (rowIndex < 0) or (rowIndex >= RowCount) then
    raise EopaRException.Create('Error: row index out of bounds');

  if (columnIndex < 0) or (columnIndex >= ColumnCount) then
    raise EopaRException.Create('Error: column index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    offset := GetOffset(rowIndex, columnIndex);
    PData := PDouble(NativeInt(DataPointer) + offset);
    PData^ := value;
  finally
    pp.Free;
  end;
end;

end.
