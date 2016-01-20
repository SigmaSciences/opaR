unit opaR.VECTOR_SEXPREC;

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

VECTOR_SEXPREC is a reduced version of SEXPREC used as a header in vector nodes.
Note that it must be kept in sync with SEXPREC.

-------------------------------------------------------------------------------}

interface

uses
  opaR.Utils,
  opaR.SEXPREC;

type
  TVECTOR_SEXPREC = packed record
  private
    function GetLength: integer;
    function GetTrueLength: integer;
  public
    sxpinfo: Tsxpinfo;
    attrib: PSEXPREC;
    gengc_next_node: PSEXPREC;
    gengc_prev_node: PSEXPREC;
    vecsxp: Tvecsxp;
    property Length: integer read GetLength;
    property TrueLength: integer read GetTrueLength;
  end;

implementation


{ TVECTOR_SEXPREC }

//------------------------------------------------------------------------------
function TVECTOR_SEXPREC.GetLength: integer;
begin
  result := vecsxp.length;
end;
//------------------------------------------------------------------------------
function TVECTOR_SEXPREC.GetTrueLength: integer;
begin
  result := vecsxp.truelength;
end;

end.
