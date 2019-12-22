unit opaR.Internals.Windows.RStart;

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
  opaR.Utils,
  opaR.Internals.Unix.RStart,
  opaR.Internals.Windows.Delegates;

type
  TUnixRStruct = opaR.Internals.Unix.RStart.TRStart;

  TRStart = {packed} record
    Common: TUnixRStruct;
    rhome: AnsiString;
    home: AnsiString;

    ReadConsole: Tblah1;
    WriteConsole: Tblah2;
    CallBack: Tblah3;
    ShowMessage: Tblah4;
    YesNoCancel: Tblah5;
    Busy: Tblah6;
    CharacterMode: TUiMode;
    WriteConsoleEx: Tblah7;
  end;

implementation

end.
