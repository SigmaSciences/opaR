unit opaR.InternalString;

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

The R.NET version of InternalString includes:
            1. Implicit cast for the string (operator overloading not available in Delphi/Win)
            2. GetInternalValue - returns null

Since there's no "null" for Delphi strings just implement ToString.

-------------------------------------------------------------------------------}


interface

uses
  Winapi.Windows,

  opaR.VECTOR_SEXPREC,
  opaR.SEXPREC,
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.DLLFunctions;


type
  TInternalString = class(TSymbolicExpression, IInternalString)
  public
    constructor Create(engine: IREngine; pExpr: PSEXPREC); overload;
    constructor Create(engine: IREngine; s: string); overload;
    function ToString: string; override;
  end;

implementation

{ TInternalString }

//------------------------------------------------------------------------------
constructor TInternalString.Create(engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
constructor TInternalString.Create(engine: IREngine; s: string);
var
  makeChar: TRFnMakeChar;
  pExpr: PSEXPREC;
begin
  makeChar := GetProcAddress(engine.Handle, 'Rf_mkChar');
  pExpr := makeChar(PAnsiChar(AnsiString(s)));

  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
function TInternalString.ToString: string;
begin
  result := String(AnsiString(PAnsiChar(NativeUInt(Handle) + SizeOf(TVECTOR_SEXPREC))));
end;

end.
