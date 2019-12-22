unit opaR.VectorUtils;

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

Define our own generic interfaces - don't bother with the non-generic ones.

Note that our generic interfaces should not have GUIDs.

-------------------------------------------------------------------------------}

interface

uses
  System.Types,
  opaR.Interfaces,
  opaR.SEXPREC;

type

  TVectorAccessUtility = class
  public
    class function GetPointerToIntegerInVector(const aEngine: IREngine; const
        aVectorHandle: PSEXPREC; const aIndex: integer): PInteger; static;
    class function GetPointerToRawInVector(const aEngine: IREngine; const
        aVectorHandle: PSEXPREC; const aIndex: integer): PByte; static;
    class function GetPointerToLogicalInVector(const aEngine: IREngine; const
        aVectorHandle: PSEXPREC; const aIndex: integer): PLongBool; static;
    class function GetPointerToRealInVector(const aEngine: IREngine; const
        aVectorHandle: PSEXPREC; const aIndex: integer): PDouble; static;
    class function GetStringValueInVector(const aEngine: IREngine; const
        aVectorHandle: PSEXPREC; const aIndex: integer): string; static;
    class procedure SetStringValueInVector(const aEngine: IREngine; const
        aVectorHandle: PSEXPREC; const aIndex: integer; const aValue: string);
        static;
  end;


implementation

uses
  opaR.EngineExtension;


class function TVectorAccessUtility.GetPointerToIntegerInVector(const aEngine:
    IREngine; const aVectorHandle: PSEXPREC; const aIndex: integer): PInteger;
begin
  Result := aEngine.Rapi.IntegerVector(aVectorHandle);
  Inc(Result, aIndex);
end;

class function TVectorAccessUtility.GetPointerToLogicalInVector(const aEngine:
    IREngine; const aVectorHandle: PSEXPREC; const aIndex: integer): PLongBool;
begin
  Result := aEngine.Rapi.LogicalVector(aVectorHandle);
  Inc(Result, aIndex);
end;

class function TVectorAccessUtility.GetPointerToRawInVector(const aEngine:
    IREngine; const aVectorHandle: PSEXPREC; const aIndex: integer): PByte;
begin
  Result := aEngine.Rapi.RawVector(aVectorHandle);
  Inc(Result, aIndex);
end;

class function TVectorAccessUtility.GetPointerToRealInVector(const aEngine:
    IREngine; const aVectorHandle: PSEXPREC; const aIndex: integer): PDouble;
begin
  Result := aEngine.Rapi.RealVector(aVectorHandle);
  Inc(Result, aIndex);
end;

class function TVectorAccessUtility.GetStringValueInVector(const aEngine:
    IREngine; const aVectorHandle: PSEXPREC; const aIndex: integer): string;
var
  PStringAsCHARSXP: PSEXPREC;
  PData: PAnsiChar;
begin
  // -- Each string is stored in a global pool of C-style strings, and the
  // -- parent vector is an array of CHARSXP pointers to those strings.
  PStringAsCHARSXP := aEngine.RApi.StringElt(aVectorHandle, aIndex);

  if (PStringAsCHARSXP = TEngineExtension(aEngine).NAStringPointer) or
      (PStringAsCHARSXP = nil) then
    result := ''
  else
  begin
    // -- At this point we have a pointer to the character vector, so we now
    // -- need to get the actual (char *) for the data
    PData := aEngine.RApi.Char(PStringAsCHARSXP);

    result := String(AnsiString(PData));
  end;
end;

class procedure TVectorAccessUtility.SetStringValueInVector(const aEngine:
    IREngine; const aVectorHandle: PSEXPREC; const aIndex: integer; const
    aValue: string);
var
  PData: PSEXPREC;
begin
  if aValue = '' then
    PData := TEngineExtension(aEngine).NAStringPointer
  else
  begin
    PData := aEngine.Rapi.MakeChar(PAnsiChar(AnsiString(aValue)));;
  end;

  aEngine.Rapi.SetStringElt(aVectorHandle, aIndex, PData);
end;





end.
