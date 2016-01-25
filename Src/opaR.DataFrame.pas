unit opaR.DataFrame;

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

{ TODO : GetArrayValue (and variants) have unnecessary vec creation - get the values directly. }
{ TODO : DataFrame GetRow/GetRows mapping a specified class. }
{ TODO : Row() with TInvokeableVariantType as return type, allowing dynamic method invocation. }

interface

uses
  System.Rtti,

  Spring.Collections,

  opaR.SEXPREC,
  opaR.Utils,
  opaR.Interfaces,
  opaR.Vector,
  opaR.DynamicVector;

type
  TDataFrame = class(TRVector<IDynamicVector>, IDataFrame)
  private
    function GetColumnCount: integer;
    function GetRowCount: integer;
    function GetRowNames: TArray<string>;
    function GetArrayValue(rowIndex, columnIndex: integer): Variant;
    function RowIndexFromName(rowName: string): integer;
    procedure SetArrayValue(rowIndex, columnIndex: integer;
      const Value: Variant);
    function GetArrayValueByName(rowName, columnName: string): Variant;
    procedure SetArrayValueByName(rowName, columnName: string;
      const Value: Variant);
    function GetArrayValueByIndexAndName(rowIndex: integer; columnName: string): Variant;
    procedure SetArrayValueByIndexAndName(rowIndex: integer; columnName: string;
      const Value: Variant);
    function GetColumnNames: TArray<string>;
  protected
    function GetDataSize: integer; override;
    function GetValue(columnIndex: integer): IDynamicVector; override;
    procedure SetValue(columnIndex: integer; value: IDynamicVector); override;
  public
    function GetArrayFast: TArray<IDynamicVector>; reintroduce;
    function GetRow(rowIndex: integer): IDataFrameRow;
    function GetRows: IList<IDataFrameRow>;
    procedure SetVectorDirect(const values: TArray<IDynamicVector>); override;
    property ColumnCount: integer read GetColumnCount;
    property ColumnNames: TArray<string> read GetColumnNames;
    property RowCount: integer read GetRowCount;
    property RowNames: TArray<string> read GetRowNames;
    property Values[rowIndex, columnIndex: integer]: Variant read GetArrayValue write SetArrayValue; default;
    property Values[rowIndex: integer; columnName: string]: Variant read GetArrayValueByIndexAndName write SetArrayValueByIndexAndName; default;
    property Values[rowName, columnName: string]: Variant read GetArrayValueByName write SetArrayValueByName; default;
  end;

implementation

uses
  opaR.EngineExtension,
  opaR.SymbolicExpression,
  opaR.CharacterVector,
  opaR.DataFrameRow;

const
  cRowNamesSymbolName = 'R_RowNamesSymbol';

{ TDataFrame }

//------------------------------------------------------------------------------
function TDataFrame.GetArrayFast: TArray<IDynamicVector>;
var
  i: integer;
begin
  SetLength(result, ColumnCount);
  for i := 0 to ColumnCount - 1 do
    result[i] := GetValue(i);
end;
//------------------------------------------------------------------------------
function TDataFrame.GetArrayValue(rowIndex, columnIndex: integer): Variant;
var
  vec: IDynamicVector;
begin
  vec := self[columnIndex];
  result := vec[rowIndex];
end;
//------------------------------------------------------------------------------
function TDataFrame.GetArrayValueByIndexAndName(rowIndex: integer;
  columnName: string): Variant;
var
  vec: IDynamicVector;
begin
  vec := self[columnName];
  result := vec[rowIndex];
end;
//------------------------------------------------------------------------------
function TDataFrame.GetArrayValueByName(rowName, columnName: string): Variant;
var
  vec: IDynamicVector;
  ix: integer;
begin
  vec := self[columnName];

  ix := RowIndexFromName(rowName);
  result := vec[ix];
end;
//------------------------------------------------------------------------------
function TDataFrame.GetColumnCount: integer;
begin
  result := VectorLength;
end;
//------------------------------------------------------------------------------
function TDataFrame.GetColumnNames: TArray<string>;
begin
  result := Names;
end;
//------------------------------------------------------------------------------
function TDataFrame.GetDataSize: integer;
begin
  result := SizeOf(PSEXPREC);
end;
//------------------------------------------------------------------------------
function TDataFrame.GetRow(rowIndex: integer): IDataFrameRow;
begin
  result := TDataFrameRow.Create(self, rowIndex);
end;
//------------------------------------------------------------------------------
function TDataFrame.GetRowCount: integer;
var
  vec: IDynamicVector;
begin
  if ColumnCount = 0 then
    result := 0
  else
  begin
    vec := GetValue(0);
    result := vec.VectorLength;
  end;
end;
//------------------------------------------------------------------------------
function TDataFrame.GetRowNames: TArray<string>;
var
  rowNamesSymbol: ISymbolicExpression;
  rowNamesExpr: ISymbolicExpression;
  rowNamesVector: ICharacterVector;
  length: integer;
begin
  rowNamesSymbol := TEngineExtension(Engine).GetPredefinedSymbol(cRowNamesSymbolName);

  rowNamesExpr := GetAttribute(rowNamesSymbol);
  if rowNamesExpr = nil then Exit(nil);

  rowNamesVector := rowNamesExpr.AsCharacter;
  if rowNamesVector = nil then Exit(nil);

  length := (rowNamesVector as TCharacterVector).VectorLength;
  SetLength(result, length);
  (rowNamesVector as TCharacterVector).CopyTo(result, length);
end;
//------------------------------------------------------------------------------
function TDataFrame.GetRows: IList<IDataFrameRow>;
var
  i: integer;
  numRows: integer;
begin
  numRows := RowCount;
  result := TCollections.CreateList<IDataFrameRow>;

  for i := 0 to numRows - 1 do
    result.Add(GetRow(i));
end;
//------------------------------------------------------------------------------
function TDataFrame.RowIndexFromName(rowName: string): integer;
var
  rowNamesSymbol: ISymbolicExpression;
  rowNamesExpr: ISymbolicExpression;
  rowNamesVector: ICharacterVector;
  i: integer;
  ix: integer;
begin
  ix := -1;
  rowNamesSymbol := TEngineExtension(Engine).GetPredefinedSymbol(cRowNamesSymbolName);

  rowNamesExpr := GetAttribute(rowNamesSymbol);
  if rowNamesExpr = nil then Exit(-1);

  rowNamesVector := rowNamesExpr.AsCharacter;
  if rowNamesVector = nil then Exit(-1);

  for i := 0 to (rowNamesVector as TCharacterVector).VectorLength - 1 do
    if rowNamesVector[i] = rowName then
    begin
      ix := i;
      break;
    end;

  result := ix;
end;
//------------------------------------------------------------------------------
function TDataFrame.GetValue(columnIndex: integer): IDynamicVector;    // GetColumn in R.NET
var
  PPtr: PSEXPREC;
begin
  if (columnIndex < 0) or (columnIndex >= VectorLength) then
    raise EopaRException.Create('Error: DataFrame column index out of bounds');

  PPtr := PSEXPREC(PPointerArray(DataPointer)^[columnIndex]);

  if (PPtr = nil) or (PPtr = TEngineExtension(Engine).NilValue) then
    result := nil
  else
    result := TDynamicVector.Create(Engine, PPtr);
end;
//------------------------------------------------------------------------------
procedure TDataFrame.SetArrayValue(rowIndex, columnIndex: integer;
  const Value: Variant);
var
  vec: IDynamicVector;
begin
  vec := self[columnIndex];
  vec[rowIndex] := Value;
end;
//------------------------------------------------------------------------------
procedure TDataFrame.SetArrayValueByIndexAndName(rowIndex: integer;
  columnName: string; const Value: Variant);
var
  vec: IDynamicVector;
begin
  vec := self[columnName];
  vec[rowIndex] := Value;
end;
//------------------------------------------------------------------------------
procedure TDataFrame.SetArrayValueByName(rowName, columnName: string;
  const Value: Variant);
var
  vec: IDynamicVector;
  ix: integer;
begin
  vec := self[columnName];
  ix := RowIndexFromName(rowName);
  vec[ix] := Value;
end;
//------------------------------------------------------------------------------
procedure TDataFrame.SetValue(columnIndex: integer; value: IDynamicVector);   // SetColumn in R.NET
var
  PData: PSEXPREC;
begin
  if (columnIndex < 0) or (columnIndex >= VectorLength) then
    raise EopaRException.Create('Error: DataFrame column index out of bounds');

  if value = nil then
    PData := TEngineExtension(Engine).NilValue
  else
    PData := (value as TSymbolicExpression).Handle;

  PPointerArray(DataPointer)^[columnIndex] := PData;
end;
//------------------------------------------------------------------------------
procedure TDataFrame.SetVectorDirect(const values: TArray<IDynamicVector>);
var
  i: integer;
begin
  for i := 0 to Length(values) - 1 do
    SetValue(i, values[i]);
end;

end.

