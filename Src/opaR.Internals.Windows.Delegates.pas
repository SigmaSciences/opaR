unit opaR.Internals.Windows.Delegates;

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

Note that we've used the .NET "Delegates" terminology here.

-------------------------------------------------------------------------------}

interface

uses
  opaR.Utils;

type
  // -- PAnsiChar type is used for UnmanagedType.LPStr. Note that the buffer
  // -- param is a StringBuilder in RDotNet, while prompt is a string.
  Tblah1 = function(prompt, buffer: PAnsiChar; length: integer; history: LongBool): LongBool; cdecl;
  Tblah2 = procedure(const buffer: PAnsiChar; length: integer); cdecl;
  Tblah3 = procedure; cdecl;
  Tblah4 = procedure(const msg: PAnsiChar); cdecl;
  Tblah5 = function(const question: PAnsiChar): TYesNoCancel; cdecl;
  Tblah6 = procedure(which: TBusyType); cdecl;
  Tblah7 = procedure(const buffer: PAnsiChar; length: integer; outputType: TConsoleOutputType); cdecl;

implementation

end.
