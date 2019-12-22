unit opaR.Symbol;

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
  System.SysUtils,

  opaR.SEXPREC,
  opaR.InternalString,
  opaR.SymbolicExpression,
  opaR.Interfaces;


type
  TSymbol = class(TSymbolicExpression, ISymbol)
  private
    function GetPrintName: string;
    //class function GetOffsetOf(fieldName: string): integer;
    procedure SetPrintName(const Value: string);
    function GetValue: ISymbolicExpression;
    function GetInternal: ISymbolicExpression;
  public
    property PrintName: string read GetPrintName write SetPrintName;
    property Internal: ISymbolicExpression read GetInternal;
    property Value: ISymbolicExpression read GetValue;
  end;


implementation

uses
  opaR.EngineExtension;

{ TSymbol }

//------------------------------------------------------------------------------
function TSymbol.GetInternal: ISymbolicExpression;
begin
  if Engine.Rapi.INTERNAL(Handle) = TEngineExtension(Engine).NilValue then
    result := nil
  else
    result := TSymbolicExpression.Create(Engine, Engine.Rapi.INTERNAL(Handle));
end;

//------------------------------------------------------------------------------
function TSymbol.GetPrintName: string;
var
  internalStr: IInternalString;
begin
  internalStr := TInternalString.Create(Engine, Engine.Rapi.PrintName(Handle));
  result := internalStr.ToString;
end;
//------------------------------------------------------------------------------
function TSymbol.GetValue: ISymbolicExpression;
begin
  if Engine.RApi.SYMVALUE(Handle) = TEngineExtension(Engine).NilValue then
    result := nil
  else
    result := TSymbolicExpression.Create(Engine, Engine.RApi.SYMVALUE(Handle));
end;
//------------------------------------------------------------------------------
procedure TSymbol.SetPrintName(const Value: string);
var
  PtrName: PSEXPREC;
  internalStr: IInternalString;
begin
  if Trim(Value) = '' then
    PtrName := TEngineExtension(Engine).NilValue
  else
  begin
    internalStr := TInternalString.Create(Engine, Value);
    PtrName := internalStr.Handle;
  end;

  Engine.Rapi.SET_PRINTNAME(Handle, PtrName);
end;

end.
