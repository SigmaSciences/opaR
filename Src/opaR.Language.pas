unit opaR.Language;

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
  opaR.DLLFunctions,
  opaR.SymbolicExpression,
  opaR.Pairlist,
  opaR.Interfaces;

type
  TRLanguage = class(TSymbolicExpression, IRLanguage)
  public
    function FunctionCall: IPairList;
  end;


implementation

{ TRLanguage }

//------------------------------------------------------------------------------
function TRLanguage.FunctionCall: IPairList;
var
  pairCount: integer;
  rLength: TRFnLength;
  sexp: TSEXPREC;
begin
  rLength := GetProcAddress(EngineHandle, 'Rf_length');
  pairCount := rLength(Handle);
  if pairCount < 2 then
    result := nil
  else
  begin
    sexp := GetInternalStructure;
    result := TPairList.Create(Engine, sexp.listsxp.cdrval);
  end;
end;

end.
