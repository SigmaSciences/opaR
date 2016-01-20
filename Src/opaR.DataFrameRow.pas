unit opaR.DataFrameRow;

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

{-------------------------------------------------------------------------------

In R.NET, DataFrameRow inherits from DynamicObject allowing us to access the
column names using dynamic properties.

-------------------------------------------------------------------------------}

interface

uses
  System.Variants,

  opaR.Interfaces,
  opaR.DataFrame;


type
  TDataFrameRow = class(TInterfacedObject, IDataFrameRow)
  private
    FDataFrame: TDataFrame;
    FRowIndex: integer;
    function GetRowIndex: integer;
  protected
    function GetValue(ix: integer): Variant;
    procedure SetValue(ix: integer; const Value: Variant);
    function GetValueByName(name: string): Variant;
    procedure SetValueByName(name: string; const Value: Variant);
    function GetInnerValue(ix: integer): Variant;
    procedure SetInnerValue(ix: integer; const Value: Variant);
  public
    constructor Create(df: TDataFrame; rowIndex: integer);
    property DataFrame: TDataFrame read FDataFrame;
    property RowIndex: integer read GetRowIndex;
    property Values[ix: integer]: Variant read GetValue write SetValue; default;
    property Values[name: string]: Variant read GetValueByName write SetValueByName; default;
  end;

implementation

uses
  opaR.DynamicVector,
  opaR.SymbolicExpression;

{ TDataFrameRow }

//------------------------------------------------------------------------------
constructor TDataFrameRow.Create(df: TDataFrame; rowIndex: integer);
begin
  FDataFrame := df;
  FRowIndex := rowIndex;
end;
//------------------------------------------------------------------------------
function TDataFrameRow.GetInnerValue(ix: integer): Variant;
var
  vec: IDynamicVector;
begin
  vec := DataFrame[ix];

  if (vec as TSymbolicExpression).IsFactor then
    result := (vec as TSymbolicExpression).AsInteger[RowIndex]
  else
    result := vec[RowIndex];
end;
//------------------------------------------------------------------------------
function TDataFrameRow.GetRowIndex: integer;
begin
  result := FRowIndex;
end;
//------------------------------------------------------------------------------
function TDataFrameRow.GetValue(ix: integer): Variant;
var
  vec: IDynamicVector;
begin
  vec := DataFrame[ix];
  result := vec[RowIndex];
end;
//------------------------------------------------------------------------------
function TDataFrameRow.GetValueByName(name: string): Variant;
var
  vec: IDynamicVector;
begin
  vec := DataFrame[name];
  result := vec[RowIndex];
end;
//------------------------------------------------------------------------------
procedure TDataFrameRow.SetInnerValue(ix: integer; const Value: Variant);
var
  vec: IDynamicVector;
begin
  vec := DataFrame[ix];

  if (vec as TSymbolicExpression).IsFactor then
    (vec as TSymbolicExpression).AsInteger[RowIndex] := Value.AsInteger
  else
    vec[RowIndex] := Value;
end;
//------------------------------------------------------------------------------
procedure TDataFrameRow.SetValue(ix: integer; const Value: Variant);
var
  vec: IDynamicVector;
begin
  vec := DataFrame[ix];
  vec[RowIndex] := Value;
end;
//------------------------------------------------------------------------------
procedure TDataFrameRow.SetValueByName(name: string; const Value: Variant);
var
  vec: IDynamicVector;
begin
  vec := DataFrame[name];
  vec[RowIndex] := Value;
end;

end.
