unit opaR.Matrix;

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
  opaR.SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.SymbolicExpression,
  opaR.ProtectedPointer,
  opaR.Interfaces;

type
  TRMatrix<T> = class abstract (TSymbolicExpression, IRMatrix<T>)
  private
    procedure InitMatrixFast(matrix: TDynMatrix<T>);
    function GetColumnCount: integer;
    function GetItemCount: integer;
    function GetRowCount: integer;
    function GetValueByName(const rowName, columnName: string): T;
    procedure GetRowAndColumnIndex(const rowName, columnName: string; var rowIndex: integer;
      var columnIndex: integer);
    procedure SetValueByName(const rowName, columnName: string; const value: T);
    function GetValueByIndex(const rowIndex, columnIndex: integer): T;
    procedure InitMatrixFastDirect(matrix: TDynMatrix<T>);
    procedure SetValueByIndex(const rowIndex, columnIndex: integer; const value: T);
  protected
    function GetValueForAbsoluteIndex(const aAbsoluteVectorIndex: integer): T;
        virtual; abstract;
    procedure SetValueForAbsoluteIndex(const aAbsoluteVectorIndex: integer; const
        value: T); virtual; abstract;
    function GetDataSize: integer; virtual; abstract;
    function GetArrayFast: TDynMatrix<T>;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(const engine: IREngine;
      expressionType: TSymbolicExpressionType; rowCount, columnCount: integer); overload;
    constructor Create(const engine: IREngine;
      expressionType: TSymbolicExpressionType; matrix: TDynMatrix<T>); overload;
    function ColumnNames: TArray<string>;
    function ToArray: TDynMatrix<T>;
    function RowNames: TArray<string>;
    procedure CopyTo(destination: TDynMatrix<T>; rowCount, columnCount: integer;
      sourceRowIndex: integer = 0; sourceColumnIndex: integer = 0;
        destinationRowIndex: integer = 0; destinationColumnIndex: integer = 0);
    property ColumnCount: integer read GetColumnCount;
    property DataSize: integer read GetDataSize;
    property ItemCount: integer read GetItemCount;
    property RowCount: integer read GetRowCount;
    property ValueByIndex[const rowIndex, columnIndex: integer]: T read GetValueByIndex write SetValueByIndex; default;
    property ValueByName[const rowName, columnName: string]: T read GetValueByName write SetValueByName;
  end;

implementation

uses
  opaR.EngineExtension,
  opaR.CharacterVector;

{ TRMatrix<T> }

//------------------------------------------------------------------------------
constructor TRMatrix<T>.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
constructor TRMatrix<T>.Create(const engine: IREngine;
  expressionType: TSymbolicExpressionType; rowCount, columnCount: integer);
var
  pExpr: PSEXPREC;
begin
  if rowCount <= 0 then
    raise EopaRException.Create('Error: Matrix rowCount must be greater than zero');

  if columnCount <= 0 then
    raise EopaRException.Create('Error: Matrix columnCount must be greater than zero');

  // -- First get the pointer to the R expression.
  pExpr := Engine.Rapi.AllocMatrix(expressionType, rowCount, columnCount);

  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
function TRMatrix<T>.ColumnNames: TArray<string>;
var
  dimNamesSymbol: ISymbolicExpression;
  dimNames: ISymbolicExpression;
  colNames: ICharacterVector;
  vecLength: integer;
  i: integer;
begin
  dimNamesSymbol := TEngineExtension(Engine).GetPredefinedSymbol('R_DimNamesSymbol');

  dimNames := GetAttribute(dimNamesSymbol);
  if dimNames = nil then
    Exit(nil);

  colNames := (dimNames as TSymbolicExpression).AsList[1].AsCharacter;
  if colNames = nil then
    Exit(nil);

  vecLength := colNames.VectorLength;
  SetLength(result, vecLength);
  for i := 0 to vecLength - 1 do
    result[i] := colNames[i];
end;
//------------------------------------------------------------------------------
procedure TRMatrix<T>.CopyTo(destination: TDynMatrix<T>; rowCount, columnCount,
  sourceRowIndex, sourceColumnIndex, destinationRowIndex,
  destinationColumnIndex: integer);
var
  i: integer;
  j: integer;
  k: integer;
  l: integer;
begin
  if Length(destination) = 0  then
    raise EopaRException.Create('Error: Destination matrix cannot be nil');

  if (rowCount <= 0) then
    raise EopaRException.Create('Error: Number of rows to copy must be > 0');

  if (columnCount <= 0) then
    raise EopaRException.Create('Error: Number of columns to copy must be > 0');

  if (sourceRowIndex < 0) or (RowCount < sourceRowIndex + rowCount) then
    raise EopaRException.Create('Error: Source row index out of bounds');

  if (sourceColumnIndex < 0) or (ColumnCount < sourceColumnIndex + columnCount) then
    raise EopaRException.Create('Error: Source column index out of bounds');

  if (destinationRowIndex < 0) or (Length(destination) < destinationRowIndex + rowCount) then
    raise EopaRException.Create('Error: Destination row index out of bounds');

  if (destinationColumnIndex < 0) or (Length(destination[0]) < destinationColumnIndex + columnCount) then
    raise EopaRException.Create('Error: Destination column index out of bounds');

  k := destinationRowIndex;
  for i := sourceRowIndex to sourceRowIndex + rowCount - 1 do
  begin
    l := destinationColumnIndex;
    for j := sourceColumnIndex to sourceColumnIndex + columnCount - 1 do
    begin
      destination[k, l] := self[i, j];
      l := l + 1;
    end;
    k := k + 1;
  end;
end;
//------------------------------------------------------------------------------
constructor TRMatrix<T>.Create(const engine: IREngine;
  expressionType: TSymbolicExpressionType; matrix: TDynMatrix<T>);
var
  rowCount: integer;
  columnCount: integer;
begin
  rowCount := Length(matrix);
  if rowCount <= 0 then
    raise EopaRException.Create('Error: Matrix rowCount must be greater than zero');

  columnCount := Length(matrix[0]);
  Create(engine, expressionType, rowCount, columnCount);
  InitMatrixFast(matrix);
end;

function TRMatrix<T>.GetArrayFast: TDynMatrix<T>;
var
  i: integer;
  j: integer;
begin
  SetLength(result, RowCount, ColumnCount);

  for i := 0 to RowCount - 1 do
    for j := 0 to ColumnCount - 1 do
      result[i, j] := GetValueByIndex(i, j);
end;

//------------------------------------------------------------------------------
function TRMatrix<T>.GetColumnCount: integer;
begin
  result := Engine.Rapi.NumCols(Handle);
end;
//------------------------------------------------------------------------------
function TRMatrix<T>.GetItemCount: integer;
begin
  result := RowCount * ColumnCount;
end;
//------------------------------------------------------------------------------
procedure TRMatrix<T>.GetRowAndColumnIndex(const rowName, columnName: string;
  var rowIndex, columnIndex: integer);
var
  rowNamesArray: TArray<string>;
  colNamesArray: TArray<string>;
  i: integer;
begin
  rowIndex := -1;
  if rowName = '' then
    raise EopaRException.Create('Indexing a matrix by name requires a non-null row name argument');

  columnIndex := -1;
  if columnName = '' then
    raise EopaRException.Create('Indexing a matrix by name requires a non-null column name argument');

  rowNamesArray := RowNames;
  if Length(rowNamesArray) = 0 then
    raise EopaRException.Create('The matrix has no row names defined - indexing it by name cannot be supported');

  colNamesArray := ColumnNames;
  if Length(colNamesArray) = 0 then
    raise EopaRException.Create('The matrix has no column names defined - indexing it by name cannot be supported');

  for i := 0 to Length(rowNamesArray) - 1 do
  begin
    if rowNamesArray[i] = rowName then
    begin
      rowIndex := i;
      break;
    end;
  end;

  for i := 0 to Length(colNamesArray) - 1 do
  begin
    if colNamesArray[i] = columnName then
    begin
      columnIndex := i;
      break;
    end;
  end;
end;
//------------------------------------------------------------------------------
function TRMatrix<T>.GetRowCount: integer;
begin
  result := Engine.Rapi.NumRows(Handle);
end;

function TRMatrix<T>.GetValueByIndex(const rowIndex, columnIndex: integer): T;
var
  absoluteIndex: integer;
begin
  // R matices are stored by row
  absoluteIndex := columnIndex * RowCount + rowIndex;
  Result := GetValueForAbsoluteIndex(absoluteIndex);
end;

//------------------------------------------------------------------------------
function TRMatrix<T>.GetValueByName(const rowName, columnName: string): T;
var
  rowIndex: integer;
  columnIndex: integer;
begin
  GetRowAndColumnIndex(rowName, columnName, rowIndex, columnIndex);
  if (rowIndex > -1) and (columnIndex > -1) then
    result := GetValueByIndex(rowIndex, columnIndex);
end;
//------------------------------------------------------------------------------
procedure TRMatrix<T>.InitMatrixFast(matrix: TDynMatrix<T>);
var
  pp: TProtectedPointer;
begin
  pp := TProtectedPointer.Create(self);
  try
    InitMatrixFastDirect(matrix);
  finally
    pp.Free;
  end;
end;

procedure TRMatrix<T>.InitMatrixFastDirect(matrix: TDynMatrix<T>);
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
      SetValueByIndex(i, j, matrix[i, j]);
end;

//------------------------------------------------------------------------------
function TRMatrix<T>.RowNames: TArray<string>;
var
  dimNamesSymbol: ISymbolicExpression;
  dimNames: ISymbolicExpression;
  rowNames: ICharacterVector;
  vecLength: integer;
  i: integer;
begin
  dimNamesSymbol := TEngineExtension(Engine).GetPredefinedSymbol('R_DimNamesSymbol');

  dimNames := GetAttribute(dimNamesSymbol);
  if dimNames = nil then
    Exit(nil);

  rowNames := (dimNames as TSymbolicExpression).AsList[0].AsCharacter;
  if rowNames = nil then
    Exit(nil);

  vecLength := rowNames.VectorLength;
  SetLength(result, vecLength);
  for i := 0 to vecLength - 1 do
    result[i] := rowNames[i];
end;

procedure TRMatrix<T>.SetValueByIndex(const rowIndex, columnIndex: integer;
    const value: T);
var
  absoluteIndex: integer;
begin
  // R matices are stored by row
  absoluteIndex := columnIndex * RowCount + rowIndex;
  SetValueForAbsoluteIndex(absoluteIndex, value);
end;

//------------------------------------------------------------------------------
procedure TRMatrix<T>.SetValueByName(const rowName, columnName: string; const value: T);
var
  rowIndex: integer;
  columnIndex: integer;
begin
  GetRowAndColumnIndex(rowName, columnName, rowIndex, columnIndex);
  if (rowIndex > -1) and (columnIndex > -1) then
    SetValueByIndex(rowIndex, columnIndex, value);
end;
//------------------------------------------------------------------------------
function TRMatrix<T>.ToArray: TDynMatrix<T>;
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
