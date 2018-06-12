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

  {$IFNDEF NO_SPRING}
  Spring.Collections,
  {$ELSE}
  opaR.NoSpring,
  {$ENDIF}

  opaR.SEXPREC,
  opaR.Utils,
  opaR.Interfaces,
  opaR.Vector,
  opaR.DynamicVector;

type
  TDataFrame = class(TRObjectVector<IDynamicVector>, IDataFrame)
  strict private
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
    function ConvertPSEXPRECToValue(const aValue: PSEXPREC): IDynamicVector;
        override;
    function ConvertValueToPSEXPREC(const aValue: IDynamicVector): PSEXPREC;
        override;
  public
    function GetRow(rowIndex: integer): IDataFrameRow;
    function GetRows: IList<IDataFrameRow>;
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

function TDataFrame.ConvertPSEXPRECToValue(const aValue: PSEXPREC):
    IDynamicVector;
begin
  if (aValue = nil) or (aValue = TEngineExtension(Engine).NilValue) then
    result := nil
  else
    result := TDynamicVector.Create(Engine, aValue);
end;

function TDataFrame.ConvertValueToPSEXPREC(const aValue: IDynamicVector):
    PSEXPREC;
begin
  if aValue = nil then
    result := TEngineExtension(Engine).NilValue
  else
    result := (aValue as TSymbolicExpression).Handle;
end;

{ TDataFrame }

//------------------------------------------------------------------------------
function TDataFrame.GetArrayValue(rowIndex, columnIndex: integer): Variant;
var
  vec: IDynamicVector;
begin
  vec := ValueByIndex[columnIndex];
  result := vec[rowIndex];
end;
//------------------------------------------------------------------------------
function TDataFrame.GetArrayValueByIndexAndName(rowIndex: integer;
  columnName: string): Variant;
var
  vec: IDynamicVector;
begin
  vec := ValueByName[columnName];
  result := vec[rowIndex];
end;
//------------------------------------------------------------------------------
function TDataFrame.GetArrayValueByName(rowName, columnName: string): Variant;
var
  vec: IDynamicVector;
  ix: integer;
begin
  vec := ValueByName[columnName];

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
    vec := ValueByIndex[0];
    result := vec.VectorLength;
  end;
end;
//------------------------------------------------------------------------------
function TDataFrame.GetRowNames: TArray<string>;
var
  rowNamesSymbol: ISymbolicExpression;
  rowNamesExpr: ISymbolicExpression;
  rowNamesVector: ICharacterVector;
begin
  rowNamesSymbol := TEngineExtension(Engine).GetPredefinedSymbol(cRowNamesSymbolName);

  rowNamesExpr := GetAttribute(rowNamesSymbol);
  if rowNamesExpr = nil then Exit(nil);

  rowNamesVector := rowNamesExpr.AsCharacter;
  if rowNamesVector = nil then Exit(nil);

  result := rowNamesVector.ToArray;
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
procedure TDataFrame.SetArrayValue(rowIndex, columnIndex: integer;
  const Value: Variant);
var
  vec: IDynamicVector;
begin
  vec := ValueByIndex[columnIndex];
  vec[rowIndex] := Value;
end;
//------------------------------------------------------------------------------
procedure TDataFrame.SetArrayValueByIndexAndName(rowIndex: integer;
  columnName: string; const Value: Variant);
var
  vec: IDynamicVector;
begin
  vec := ValueByName[columnName];
  vec[rowIndex] := Value;
end;
//------------------------------------------------------------------------------
procedure TDataFrame.SetArrayValueByName(rowName, columnName: string;
  const Value: Variant);
var
  vec: IDynamicVector;
  ix: integer;
begin
  vec := ValueByName[columnName];
  ix := RowIndexFromName(rowName);
  vec[ix] := Value;
end;


end.

