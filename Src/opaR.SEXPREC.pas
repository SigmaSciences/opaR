unit opaR.SEXPREC;

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
  opaR.Utils;

type
  PSEXPREC = ^TSEXPREC;
  TPSEXPRECArray = array of PSEXPREC;

  Tvecsxp = packed record
    length: integer;
    truelength: integer;
  end;

  Tprimsxp = packed record
    offset: integer;
  end;

  Tsymsxp = packed record
    pname: PSEXPREC;
    value: PSEXPREC;
    internal: PSEXPREC;
  end;

  Tlistsxp = packed record
    carval: PSEXPREC;
    cdrval: PSEXPREC;
    tagval: PSEXPREC;
  end;

  Tenvsxp = packed record
    frame: PSEXPREC;
    enclos: PSEXPREC;
    hashtab: PSEXPREC;
  end;

  Tclosxp = packed record
    formals: PSEXPREC;
    body: PSEXPREC;
    env: PSEXPREC;
  end;

  Tpromsxp = packed record
    value: PSEXPREC;
    expr: PSEXPREC;
    env: PSEXPREC;
  end;


  // -- TSEXP includes a union in the C definition - see the following article for
  // -- conversion: http://praxis-velthuis.de/rdc/articles/articles-convert.html#unions
  TSEXPREC = packed record
    sxpinfo: Tsxpinfo;
    attrib: PSEXPREC;
    gengc_next_node: PSEXPREC;
    gengc_prev_node: PSEXPREC;

    // -- Translation of the union member "u".
    case integer of
      1: (primsxp: Tprimsxp);
      2: (symsxp: Tsymsxp);
      3: (listsxp: Tlistsxp);
      4: (envsxp: Tenvsxp);
      5: (closxp: Tclosxp);
      6: (promsxp: Tpromsxp);
  end;




implementation

end.
