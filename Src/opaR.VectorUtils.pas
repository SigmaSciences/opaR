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

  opaR.SEXPREC;

type
  //IVectorEnumerator = interface
  //  ['{B38F0A35-FCF4-48C9-8C19-ED7DC584E6A1}']
  //  function GetCurrent: Pointer;
  //  function MoveNext: Boolean;
  //  property Current: Pointer read GetCurrent;
  //end;

  IVectorEnumerator<T> = interface{(IVectorEnumerator)}
    function GetCurrent: T;
    function MoveNext: Boolean;
    property Current: T read GetCurrent;
  end;

  // -- Define our own IEnumerable<T> which doesn't depend on the non-generic version.
  IVectorEnumerable<T> = interface
    function GetEnumerator: IVectorEnumerator<T>;
  end;


implementation





end.
