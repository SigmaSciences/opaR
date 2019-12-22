unit opaR.NumericMatrix;

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
  TNumericMatrix = class(TRMatrix<double>, INumericMatrix)
  protected
    function GetDataSize: integer; override;
    function GetValueForAbsoluteIndex(const aAbsoluteVectorIndex: integer): double;
        override;
    procedure SetValueForAbsoluteIndex(const aAbsoluteVectorIndex: integer; const
        value: double); override;
  public
    constructor Create(const engine: IREngine; numRows, numCols: integer); overload;
    constructor Create(const engine: IREngine; matrix: TDynMatrix<double>); overload;
  end;

implementation

uses
  opaR.VectorUtils;

{ TNumericMatrix }

//------------------------------------------------------------------------------
constructor TNumericMatrix.Create(const engine: IREngine; numRows,
  numCols: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.NumericVector, numRows, numCols);
end;
//------------------------------------------------------------------------------
constructor TNumericMatrix.Create(const engine: IREngine;
  matrix: TDynMatrix<double>);
begin
  inherited Create(engine, TSymbolicExpressionType.NumericVector, matrix);
end;
//------------------------------------------------------------------------------
function TNumericMatrix.GetDataSize: integer;
begin
  result := SizeOf(double);
end;

function TNumericMatrix.GetValueForAbsoluteIndex(const aAbsoluteVectorIndex:
    integer): double;
var
  PData: PDouble;
begin
  inherited;
  PData := TVectorAccessUtility.GetPointerToRealInVector(Engine, Handle, aAbsoluteVectorIndex);
  result := PData^;
end;

procedure TNumericMatrix.SetValueForAbsoluteIndex(const aAbsoluteVectorIndex:
    integer; const value: double);
var
  PData: PDouble;
begin
  inherited;
  PData := TVectorAccessUtility.GetPointerToRealInVector(Engine, Handle, aAbsoluteVectorIndex);
  PData^ := value;
end;


end.
