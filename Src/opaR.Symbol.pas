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
    class function GetOffsetOf(fieldName: string): integer;
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
var
  sexp: TSEXPREC;
begin
  sexp := GetInternalStructure;
  if sexp.symsxp.internal = TEngineExtension(Engine).NilValue then  { TODO : R.NET checks sexp.symsxp.value??? }
    result := nil
  else
    result := TSymbolicExpression.Create(Engine, sexp.symsxp.internal);
end;
//------------------------------------------------------------------------------
class function TSymbol.GetOffsetOf(fieldName: string): integer;
begin
  { TODO : TSymbol.GetOffsetOf - possibly not needed. }
  result := 0;
end;
//------------------------------------------------------------------------------
function TSymbol.GetPrintName: string;
var
  sexp: TSEXPREC;
  internalStr: IInternalString;
begin
  sexp := GetInternalStructure;

  internalStr := TInternalString.Create(Engine, sexp.symsxp.pname);
  result := internalStr.ToString;
end;
//------------------------------------------------------------------------------
function TSymbol.GetValue: ISymbolicExpression;
var
  sexp: TSEXPREC;
begin
  sexp := GetInternalStructure;
  if sexp.symsxp.value = TEngineExtension(Engine).NilValue then
    result := nil
  else
    result := TSymbolicExpression.Create(Engine, sexp.symsxp.value);
end;
//------------------------------------------------------------------------------
procedure TSymbol.SetPrintName(const Value: string);
var
  Ptr: PSEXPREC;
  sexp: TSEXPREC;
  internalStr: IInternalString;
begin
  if Trim(Value) = '' then
    Ptr := TEngineExtension(Engine).NilValue
  else
  begin
    internalStr := TInternalString.Create(Engine, Value);
    Ptr := internalStr.Handle;
  end;

  sexp := GetInternalStructure;
  sexp.symsxp.pname := Ptr;
end;

end.
