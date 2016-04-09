unit opaR.S4Object;

interface

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

uses
  {$IFNDEF NO_SPRING}
    Spring.Collections,
  {$ELSE}
    OpaR.NoSpring,
  {$ENDIF}

  opaR.SEXPREC,
  opaR.Utils,
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.DLLFunctions;

type
  TS4Object = class(TSymbolicExpression, IS4Object)
  private
    FSlotNames: TArray<string>;
    FdotSlotNamesFunc: IRFunction;
    function GetValueByName(name: string): ISymbolicExpression;
    function GetSlotNames: TArray<string>;
    function GetSlotCount: integer;
    function mkString(s: string): PSEXPREC;
    procedure CheckSlotName(name: string);
    procedure SetValueByName(name: string; value: ISymbolicExpression);
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC);
    function GetClassDefinition: IS4Object;
    function GetSlotTypes: IDictionary<string, string>;
    function HasSlot(slotName: string): boolean;
    property SlotCount: integer read GetSlotCount;
    property SlotNames: TArray<string> read GetSlotNames;
    property Values[name: string]: ISymbolicExpression read GetValueByName write SetValueByName; default;
  end;

implementation

uses
  opaR.EngineExtension,
  opaR.ProtectedPointer;

{ TS4Object }

//------------------------------------------------------------------------------
procedure TS4Object.CheckSlotName(name: string);
var
  ix: integer;
  s: string;
begin
  ix := -1;
  for s in SlotNames do
  begin
    if s = name then
    begin
      ix := 1;
      break;
    end;
  end;

  if ix < 0 then
    raise EopaRException.CreateFmt('Invalid slot name %s', [name]);
end;
//------------------------------------------------------------------------------
constructor TS4Object.Create(const engine: IREngine; pExpr: PSEXPREC);
var
  expr: ISymbolicExpression;
begin
  if FdotSlotNamesFunc = nil then
  begin
    expr := TEngineExtension(engine).Evaluate('invisible(.slotNames)');
    FdotSlotNamesFunc := (expr as TSymbolicExpression).AsFunction;
  end;

  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
function TS4Object.GetClassDefinition: IS4Object;
var
  classSymbol: ISymbolicExpression;
  className: string;
  Ptr: PSEXPREC;
begin
  classSymbol := TEngineExtension(Engine).GetPredefinedSymbol('R_ClassSymbol');
  className := self.GetAttribute(classSymbol).AsCharacter.First;

  Ptr := Engine.Rapi.GetClassDef(PAnsiChar(AnsiString(className)));

  result := TS4Object.Create(Engine, Ptr);
end;
//------------------------------------------------------------------------------
function TS4Object.GetSlotCount: integer;
begin
  result := Length(SlotNames);
end;
//------------------------------------------------------------------------------
function TS4Object.GetSlotNames: TArray<string>;
var
  args: TArray<ISymbolicExpression>;
  i: integer;
begin
  if Length(FSlotNames) = 0 then
  begin
    SetLength(args, 1);
    args[0] := self;
    FSlotNames := FdotSlotNamesFunc.Invoke(args).AsCharacter.ToArray;
  end;

  SetLength(result, Length(FSlotNames));
  for i := 0 to Length(FSlotNames) - 1 do
    result[i] := FSlotNames[i];
end;
//------------------------------------------------------------------------------
function TS4Object.GetSlotTypes: IDictionary<string, string>;
var
  definition: IS4Object;
  slots: ISymbolicExpression;
  slotsVec: ICharacterVector;
  namesSymbol: ISymbolicExpression;
  namesVec: ICharacterVector;
  s: string;
  ix: integer;
begin
  definition := GetClassDefinition;
  slots := definition['slots'];
  namesSymbol := TEngineExtension(Engine).GetPredefinedSymbol('R_NamesSymbol');

  namesVec := slots.GetAttribute(namesSymbol).AsCharacter;
  slotsVec := slots.AsCharacter;

  if namesVec.VectorLength <> slotsVec.VectorLength then
    raise EopaRException.Create('Vector length mismatch in TS4Object.GetSlotTypes');

  result := TCollections.CreateDictionary<string, string>;
  ix := 0;
  for s in namesVec do
  begin
    result.Add(s, slotsVec[ix]);
    ix := ix + 1;
  end;
end;
//------------------------------------------------------------------------------
function TS4Object.GetValueByName(name: string): ISymbolicExpression;
var
  PSlotValue: PSEXPREC;
  Ptr: PSEXPREC;
  pp: TProtectedPointer;
begin
  CheckSlotName(name);

  pp := TProtectedPointer.Create(self);
  try
    Ptr := mkString(name);
    PSlotValue := Engine.Rapi.DoSlot(Handle, Ptr);
    result := TSymbolicExpression.Create(Engine, PSlotValue);
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
function TS4Object.HasSlot(slotName: string): boolean;
var
  pp: TProtectedPointer;
  Ptr: PSEXPREC;
begin
  pp := TProtectedPointer.Create(self);
  try
    Ptr := mkString(slotName);
    result := Engine.Rapi.HasSlot(Handle, Ptr);
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
function TS4Object.mkString(s: string): PSEXPREC;
begin
  result := Engine.Rapi.MakeString(PAnsiChar(AnsiString(s)));
end;
//------------------------------------------------------------------------------
procedure TS4Object.SetValueByName(name: string; value: ISymbolicExpression);
var
  pp: TProtectedPointer;
  Ptr: PSEXPREC;
begin
  CheckSlotName(name);

  pp := TProtectedPointer.Create(self);
  try
    Ptr := mkString(name);
    Engine.Rapi.DoSlotAssign(Handle, Ptr, value.Handle);
  finally
    pp.Free;
  end;
end;

end.
