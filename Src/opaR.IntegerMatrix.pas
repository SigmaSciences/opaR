unit opaR.IntegerMatrix;

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
  opaR.Matrix,
  opaR.ProtectedPointer,
  opaR.Interfaces;

type
  TIntegerMatrix = class(TRMatrix<integer>, IIntegerMatrix)
  protected
    function GetDataSize: integer; override;
    function GetValueForAbsoluteIndex(const aAbsoluteVectorIndex: integer):
        integer; override;
    procedure SetValueForAbsoluteIndex(const aAbsoluteVectorIndex, value: integer);
        override;
  public
    constructor Create(const engine: IREngine; numRows, numCols: integer); overload;
    constructor Create(const engine: IREngine; matrix: TDynMatrix<integer>); overload;
  end;


implementation

uses
  opaR.VectorUtils;

{ TIntegerMatrix }

//------------------------------------------------------------------------------
constructor TIntegerMatrix.Create(const engine: IREngine; numRows,
  numCols: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.IntegerVector, numRows, numCols);
end;
//------------------------------------------------------------------------------
constructor TIntegerMatrix.Create(const engine: IREngine;
  matrix: TDynMatrix<integer>);
begin
  inherited Create(engine, TSymbolicExpressionType.IntegerVector, matrix);
end;
//------------------------------------------------------------------------------
function TIntegerMatrix.GetDataSize: integer;
begin
  result := SizeOf(integer);
end;

function TIntegerMatrix.GetValueForAbsoluteIndex(const aAbsoluteVectorIndex:
    integer): integer;
var
  PData: PInteger;
begin
  PData := TVectorAccessUtility.GetPointerToIntegerInVector(Engine, Handle, aAbsoluteVectorIndex);
  result := PData^;
end;

procedure TIntegerMatrix.SetValueForAbsoluteIndex(const aAbsoluteVectorIndex,
    value: integer);
var
  PData: PInteger;
begin
  inherited;
  PData := TVectorAccessUtility.GetPointerToIntegerInVector(Engine, Handle, aAbsoluteVectorIndex);
  PData^ := value;
end;

end.




