unit opaR.CharacterMatrix;

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
  opaR.Matrix,
  opaR.ProtectedPointer,
  opaR.Interfaces;

type
  TCharacterMatrix = class(TRMatrix<string>, ICharacterMatrix)
  private
    function mkChar(s: string): PSEXPREC;
  protected
    function GetDataSize: integer; override;
    function GetValue(rowIndex, columnIndex: integer): string; override;
    procedure InitMatrixFastDirect(matrix: TDynMatrix<string>); override;
    procedure SetValue(rowIndex, columnIndex: integer; value: string); override;
  public
    constructor Create(engine: IREngine; numRows, numCols: integer); overload;
    constructor Create(engine: IREngine; matrix: TDynMatrix<string>); overload;
    function GetArrayFast: TDynMatrix<string>; override;
  end;

implementation

uses
  opaR.EngineExtension;

{ TCharacterMatrix }

//------------------------------------------------------------------------------
constructor TCharacterMatrix.Create(engine: IREngine; numRows,
  numCols: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.CharacterVector, numRows, numCols);
end;
//------------------------------------------------------------------------------
constructor TCharacterMatrix.Create(engine: IREngine;
  matrix: TDynMatrix<string>);
begin
  inherited Create(engine, TSymbolicExpressionType.CharacterVector, matrix);
end;
//------------------------------------------------------------------------------
function TCharacterMatrix.GetArrayFast: TDynMatrix<string>;
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
function TCharacterMatrix.GetDataSize: integer;
begin
  result := SizeOf(PSEXPREC);
end;
//------------------------------------------------------------------------------
function TCharacterMatrix.GetValue(rowIndex, columnIndex: integer): string;
var
  offset: integer;
  PPtr: PSEXPREC;
  PData: PSEXPREC;
  pp: TProtectedPointer;
  ix: integer;
begin
  if (rowIndex < 0) or (rowIndex >= RowCount) then
    raise EopaRException.Create('Error: row index out of bounds');

  if (columnIndex < 0) or (columnIndex >= ColumnCount) then
    raise EopaRException.Create('Error: column index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    // -- Each string is stored in a global pool of C-style strings, and the
    // -- parent vector is an array of CHARSXP pointers to those strings.
    { TODO : ix will be dependent on whether the matrix is stored row or column-major? Check this. }
    ix := columnIndex * RowCount + rowIndex;
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
procedure TCharacterMatrix.InitMatrixFastDirect(matrix: TDynMatrix<string>);
var
  numRows: integer;
  numCols: integer;
  i: integer;
  j: integer;
begin
  numRows := Length(matrix);
  if numRows <= 0 then
    raise EopaRException.Create('Error: Matrix rowCount must be greater than zero');

  numCols := Length(matrix[0]);
  for i := 0 to numRows - 1 do
    for j := 0 to numCols - 1 do
      SetValue(i, j, matrix[i, j]);
end;
//------------------------------------------------------------------------------
function TCharacterMatrix.mkChar(s: string): PSEXPREC;
var
  makeChar: TRFnMakeChar;
begin
  // -- The call to Rf_mkChar gets us a CHARSXP, either from R's global cache
  // -- or by creating a new one.
  makeChar := GetProcAddress(EngineHandle, 'Rf_mkChar');
  result := makeChar(PAnsiChar(AnsiString(s)));
end;
//------------------------------------------------------------------------------
procedure TCharacterMatrix.SetValue(rowIndex, columnIndex: integer;
  value: string);
var
  PData: PSEXPREC;
  pp: TProtectedPointer;
  ix: integer;
begin
  if (rowIndex < 0) or (rowIndex >= RowCount) then
    raise EopaRException.Create('Error: row index out of bounds');

  if (columnIndex < 0) or (columnIndex >= ColumnCount) then
    raise EopaRException.Create('Error: column index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    if value = '' then
      PData := TEngineExtension(Engine).NAStringPointer
    else
      PData := mkChar(value);

    ix := columnIndex * RowCount + rowIndex;
    PPointerArray(DataPointer)^[ix] := PData;
  finally
    pp.Free;
  end;
end;

end.
