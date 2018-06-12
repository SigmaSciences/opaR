unit opaR.LogicalMatrix;

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
  TLogicalMatrix = class(TRMatrix<LongBool>, ILogicalMatrix)
  protected
    function GetDataSize: integer; override;
    function GetValueForAbsoluteIndex(const aAbsoluteVectorIndex: integer):
        LongBool; override;
    procedure SetValueForAbsoluteIndex(const aAbsoluteVectorIndex: integer; const
        value: LongBool); override;
  public
    constructor Create(const engine: IREngine; numRows, numCols: integer); overload;
    constructor Create(const engine: IREngine; matrix: TDynMatrix<LongBool>); overload;
  end;

implementation

uses
  opaR.VectorUtils;

{ TLogicalMatrix }

//------------------------------------------------------------------------------
constructor TLogicalMatrix.Create(const engine: IREngine; numRows,
  numCols: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.LogicalVector, numRows, numCols);
end;
//------------------------------------------------------------------------------
constructor TLogicalMatrix.Create(const engine: IREngine;
  matrix: TDynMatrix<LongBool>);
begin
  inherited Create(engine, TSymbolicExpressionType.LogicalVector, matrix);
end;
//------------------------------------------------------------------------------
function TLogicalMatrix.GetDataSize: integer;
begin
  result := SizeOf(LongBool);
end;

function TLogicalMatrix.GetValueForAbsoluteIndex(const aAbsoluteVectorIndex:
    integer): LongBool;
var
  PData: PLongBool;
begin
  inherited;
  PData := TVectorAccessUtility.GetPointerToLogicalInVector(Engine, Handle, aAbsoluteVectorIndex);
  result := PData^;
end;

procedure TLogicalMatrix.SetValueForAbsoluteIndex(const aAbsoluteVectorIndex:
    integer; const value: LongBool);
var
  PData: PLongBool;
begin
  inherited;
  PData := TVectorAccessUtility.GetPointerToLogicalInVector(Engine, Handle, aAbsoluteVectorIndex);
  PData^ := value;
end;

end.
