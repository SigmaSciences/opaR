unit opaR.Exception;

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
  System.TypInfo,

  opaR.Utils;

type
  EopaRParseException = class(EopaRException)
  private
    FStatus: TParseStatus;
    FErrorStatement: string;
  public
    constructor Create(status: TParseStatus; errorStatement, errorMsg: string);
    property ErrorStatement: string read FErrorStatement;
    property Status: TParseStatus read FStatus;
  end;

  EopaREvaluationException = class(EopaRException)
  public
    constructor Create(errorMsg: string);
  end;

implementation


{ TopaRParseException }

//------------------------------------------------------------------------------
constructor EopaRParseException.Create(status: TParseStatus; errorStatement,
  errorMsg: string);
begin
  inherited CreateFmt('Status %s for %s : %s', [GetEnumName(TypeInfo(TParseStatus), Ord(status)), errorStatement, errorMsg]);
end;


{ EopaREvaluationException }

//------------------------------------------------------------------------------
constructor EopaREvaluationException.Create(errorMsg: string);
begin
  inherited CreateFmt('%s', [errorMsg]);
end;

end.
