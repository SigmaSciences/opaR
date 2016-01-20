unit opaR.Internals.Unix.RStart;

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

Note the use of LongBool for compatibility with the R DLL.

-------------------------------------------------------------------------------}


interface

uses
  opaR.Utils;

type
  TRStart = {packed} record       // -- Use of "packed" causes an AV on Windows x64
    R_Quiet: LongBool;
    R_Slave: LongBool;
    R_Interactive: LongBool;
    R_Verbose: LongBool;
    LoadSiteFile: LongBool;
    LoadInitFile: LongBool;
    DebugInitFile: LongBool;
    RestoreAction: TStartupRestoreAction;
    SaveAction: TStartupSaveAction;
    vsize: NativeUInt;
    nsize: NativeUInt;
    max_vsize: NativeUInt;
    max_nsize: NativeUInt;
    ppsize: NativeUInt;
    NoRenviron: LongBool;
  end;

implementation

end.
