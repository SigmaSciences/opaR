unit opaR.Factor;

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

The port of the Factor type from R.NET is complicated by two Delphi limitations:

1. No RTTI for explicitly-numbered enum types (i.e. initialised enums).
2. No parameterised interface methods.

These impact on the GetFactors<TEnum: record> method: For #1 we need to enforce
the use of non-initialised enums, and for #2 we can just cast to TFactor from
IFactor when calling the method. Enforcement of non-initialised enums isn't a
problem in practice (with respect to using R).

-------------------------------------------------------------------------------}

interface

uses
  Winapi.Windows,
  System.Rtti,
  System.TypInfo,

  opaR.SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.IntegerVector,
  opaR.Interfaces;

type
  TFactor = class(TIntegerVector, IFactor)
  private
    function GetIsOrdered: boolean;
  public
    function GetFactor(index: integer): string;
    function GetFactors: TArray<string>; overload;
    function GetFactors<TEnum: record>(ignoreCase: boolean = false): TArray<TEnum>; overload;
    function GetLevels: TArray<string>;
    procedure SetFactor(index: integer; factorValue: string);
    property IsOrdered: boolean read GetIsOrdered;
  end;

implementation

uses
  opaR.EngineExtension,
  opaR.SymbolicExpression;


{ TFactor }

//------------------------------------------------------------------------------
function TFactor.GetFactor(index: integer): string;
var
  intValue: integer;
begin
  intValue := self[index];
  if intValue <= 0 then
    result := ''
  else
    result := GetLevels[intValue - 1]; // -- zero-based index in Delphi, but 1-based in R.
end;
//------------------------------------------------------------------------------
function TFactor.GetFactors: TArray<string>;
var
  i: integer;
  levels: TArray<string>;
  levelIndices: TArray<integer>;
begin
  levels := GetLevels;
  levelIndices := GetArrayFast;
  SetLength(result, VectorLength);
  for i := 0 to VectorLength - 1 do
    if levelIndices[i] = NACode then
      result[i] := ''
    else
      result[i] := levels[levelIndices[i] - 1];  // -- zero-based index in Delphi, but 1-based in R.
end;
//------------------------------------------------------------------------------
function TFactor.GetFactors<TEnum>(ignoreCase: boolean): TArray<TEnum>;
var
  i: integer;
  typeInf: PTypeInfo;
  levels: TArray<string>;
  intValue: integer;
  strValue: string;
begin
  typeInf := PTypeInfo(TypeInfo(TEnum));

  if (typeInf = nil) then
    raise EopaRException.Create('Error: Only enumerated types with default values are supported');

  if (typeInf^.Kind <> tkEnumeration) then
      raise EopaRException.Create('Error: Only enumerated types are supported');

  levels := GetLevels;
  SetLength(result, VectorLength);

  for i := 0 to VectorLength - 1 do
  begin
    intValue := self[i];
    strValue := levels[intValue - 1];
    // -- Now convert the string to the corresponding enum.
    // -- From http://stackoverflow.com/questions/31601707/generic-functions-for-converting-an-enumeration-to-string-and-back
    case GetTypeData(typeInf)^.OrdType of
      otSByte, otUByte:
        PByte(@result[i])^ := GetEnumValue(typeInf, strValue);
      otSWord, otUWord:
        PWord(@result[i])^ := GetEnumValue(typeInf, strValue);
      otSLong, otULong:
        PCardinal(@result[i])^ := GetEnumValue(typeInf, strValue);
    end;
  end;
end;
//------------------------------------------------------------------------------
function TFactor.GetIsOrdered: boolean;
var
  fnIsOrdered: TRFnIsOrdered;
begin
  fnIsOrdered := GetProcAddress(EngineHandle, 'Rf_isOrdered');
  result := fnIsOrdered(Handle);
end;
//------------------------------------------------------------------------------
function TFactor.GetLevels: TArray<string>;
var
  expr: ISymbolicExpression;
  attr: ISymbolicExpression;
begin
  expr := TEngineExtension(Engine).GetPredefinedSymbol('R_LevelsSymbol');
  attr := GetAttribute(expr);

  result := attr.AsCharacter.ToArray;
end;
//------------------------------------------------------------------------------
procedure TFactor.SetFactor(index: integer; factorValue: string);
var
  i: integer;
  factIndex: integer;
  levels: TArray<string>;
begin
  factIndex := -1;

  if factorValue = '' then
    self[index] := NACode
  else
  begin
    levels := GetLevels;
    for i := 0 to Length(levels) - 1 do
    begin
      if factorValue = levels[i] then
      begin
        factIndex := i;
        break;
      end;
    end;

    if factIndex >= 0 then
      self[index] := factIndex + 1   // -- zero-based index in Delphi, but 1-based in R.
    else
      self[index] := NACode;
  end;
end;

end.
