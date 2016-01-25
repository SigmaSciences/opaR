unit opaR.ProtectedPointer;

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

TProtectedPointer acts as a wrapper around a SEXPREC, preventing it being
destroyed by the R garbage collector.

-------------------------------------------------------------------------------}


interface

uses
  opaR.SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.Interfaces;

type
  TProtectedPointer = class
  private
    FEngineHandle: HMODULE;
    FHandle: PSEXPREC;
    FEngine: IREngine;
  public
    constructor Create(sexp: ISymbolicExpression); overload;
    constructor Create(const engine: IREngine; p: PSEXPREC); overload;
    destructor Destroy; override;
  end;

implementation


{ TProtectedPointer }

//------------------------------------------------------------------------------
constructor TProtectedPointer.Create(const engine: IREngine; p: PSEXPREC);
begin
  FHandle := p;
  FEngineHandle := engine.Handle;
  FEngine := engine;

  if FEngineHandle = 0 then
    raise EopaRException.Create('Null engine handle in ProtectedPointer constructor');

  engine.Rapi.Protect(FHandle);
end;
//------------------------------------------------------------------------------
constructor TProtectedPointer.Create(sexp: ISymbolicExpression);
begin
  FHandle := sexp.Handle;
  FEngineHandle := sexp.EngineHandle;
  FEngine := sexp.Engine;

  sexp.Engine.Rapi.Protect(FHandle);
end;
//------------------------------------------------------------------------------
destructor TProtectedPointer.Destroy;
begin
  FEngine.Rapi.Unprotect(FHandle);
  inherited;
end;


end.
