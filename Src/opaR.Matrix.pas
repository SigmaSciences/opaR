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
  Winapi.Windows,

  opaR.SEXPREC,
  opaR.VECTOR_SEXPREC,
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
    function GetDataPointer: PSEXPREC;
    function GetItemCount: integer;
    function GetRowCount: integer;
    function GetValueByName(rowName, columnName: string): T; virtual;
    procedure GetRowAndColumnIndex(rowName, columnName: string; var rowIndex: integer;
      var columnIndex: integer);
    procedure SetValueByName(rowName, columnName: string; value: T); virtual;
  protected
    function GetDataSize: integer; virtual; abstract;
    function GetOffset(rowIndex, columnIndex: integer): integer;
    function GetValue(rowIndex, columnIndex: integer): T; virtual; abstract;
    procedure InitMatrixFastDirect(matrix: TDynMatrix<T>); virtual; abstract;
    procedure SetValue(rowIndex, columnIndex: integer; value: T); virtual; abstract;
  public
    constructor Create(engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(engine: IREngine;
      expressionType: TSymbolicExpressionType; rowCount, columnCount: integer); overload;
    constructor Create(engine: IREngine;
      expressionType: TSymbolicExpressionType; matrix: TDynMatrix<T>); overload;
    function ColumnNames: TArray<string>;
    function GetArrayFast: TDynMatrix<T>; virtual; abstract;
    function ToArray: TDynMatrix<T>;
    function RowNames: TArray<string>;
    procedure CopyTo(destination: TDynMatrix<T>; rowCount, columnCount: integer;
      sourceRowIndex: integer = 0; sourceColumnIndex: integer = 0;
        destinationRowIndex: integer = 0; destinationColumnIndex: integer = 0);
    property ColumnCount: integer read GetColumnCount;
    property DataPointer: PSEXPREC read GetDataPointer;
    property DataSize: integer read GetDataSize;
    property ItemCount: integer read GetItemCount;
    property RowCount: integer read GetRowCount;
    property Values[rowIndex, columnIndex: integer]: T read GetValue write SetValue; default;
    property Values[rowName, columnName: string]: T read GetValueByName write SetValueByName; default;
  end;

implementation

uses
  opaR.EngineExtension,
  opaR.CharacterVector;

{ TRMatrix<T> }

//------------------------------------------------------------------------------
constructor TRMatrix<T>.Create(engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
constructor TRMatrix<T>.Create(engine: IREngine;
  expressionType: TSymbolicExpressionType; rowCount, columnCount: integer);
var
  pExpr: PSEXPREC;
  allocVec: TRfnAllocMatrix;
begin
  if rowCount <= 0 then
    raise EopaRException.Create('Error: Matrix rowCount must be greater than zero');

  if columnCount <= 0 then
    raise EopaRException.Create('Error: Matrix columnCount must be greater than zero');

  // -- First get the pointer to the R expression.
  allocVec := GetProcAddress(engine.Handle, 'Rf_allocMatrix');
  pExpr := allocVec(expressionType, rowCount, columnCount);

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
constructor TRMatrix<T>.Create(engine: IREngine;
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
//------------------------------------------------------------------------------
function TRMatrix<T>.GetColumnCount: integer;
var
  numCols: TRFnNumCols;
begin
  numCols := GetProcAddress(EngineHandle, 'Rf_ncols');
  result := numCols(Handle);
end;
//------------------------------------------------------------------------------
function TRMatrix<T>.GetDataPointer: PSEXPREC;
var
  offset: integer;
  h: PSEXPREC;
begin
  // -- TVECTOR_SEXPREC is the header of the vector, with the actual data behind it.
  offset := SizeOf(TVECTOR_SEXPREC);
  h := Handle;
  result := PSEXPREC(NativeInt(h) + offset);
end;
//------------------------------------------------------------------------------
function TRMatrix<T>.GetItemCount: integer;
begin
  result := RowCount * ColumnCount;
end;
//------------------------------------------------------------------------------
function TRMatrix<T>.GetOffset(rowIndex, columnIndex: integer): integer;
begin
  { TODO : Depends on whether the matrix is row or column-major? }
  result := DataSize * (columnIndex * RowCount + rowIndex);
end;
//------------------------------------------------------------------------------
procedure TRMatrix<T>.GetRowAndColumnIndex(rowName, columnName: string;
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
var
  numRows: TRFnNumRows;
begin
  numRows := GetProcAddress(EngineHandle, 'Rf_nrows');
  result := numRows(Handle);
end;
//------------------------------------------------------------------------------
function TRMatrix<T>.GetValueByName(rowName, columnName: string): T;
var
  rowIndex: integer;
  columnIndex: integer;
begin
  GetRowAndColumnIndex(rowName, columnName, rowIndex, columnIndex);
  if (rowIndex > -1) and (columnIndex > -1) then
    GetValue(rowIndex, columnIndex);
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
//------------------------------------------------------------------------------
procedure TRMatrix<T>.SetValueByName(rowName, columnName: string; value: T);
var
  rowIndex: integer;
  columnIndex: integer;
begin
  GetRowAndColumnIndex(rowName, columnName, rowIndex, columnIndex);
  if (rowIndex > -1) and (columnIndex > -1) then
    SetValue(rowIndex, columnIndex, value);
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
