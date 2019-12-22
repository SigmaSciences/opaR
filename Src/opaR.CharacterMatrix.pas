unit opaR.CharacterMatrix;

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
  opaR.SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions,
  opaR.Matrix,
  opaR.ProtectedPointer,
  opaR.Interfaces;

type
  TCharacterMatrix = class(TRMatrix<string>, ICharacterMatrix)
  protected
    function GetDataSize: integer; override;
    function GetValueForAbsoluteIndex(const aAbsoluteVectorIndex: integer): string;
        override;
    procedure SetValueForAbsoluteIndex(const aAbsoluteVectorIndex: integer; const
        value: string); override;
  public
    constructor Create(const engine: IREngine; numRows, numCols: integer); overload;
    constructor Create(const engine: IREngine; matrix: TDynMatrix<string>); overload;
  end;

implementation

uses
  opaR.VectorUtils;

{ TCharacterMatrix }

//------------------------------------------------------------------------------
constructor TCharacterMatrix.Create(const engine: IREngine; numRows,
  numCols: integer);
begin
  inherited Create(engine, TSymbolicExpressionType.CharacterVector, numRows, numCols);
end;
//------------------------------------------------------------------------------
constructor TCharacterMatrix.Create(const engine: IREngine;
  matrix: TDynMatrix<string>);
begin
  inherited Create(engine, TSymbolicExpressionType.CharacterVector, matrix);
end;
//------------------------------------------------------------------------------
function TCharacterMatrix.GetDataSize: integer;
begin
  result := SizeOf(PSEXPREC);
end;

function TCharacterMatrix.GetValueForAbsoluteIndex(const aAbsoluteVectorIndex:
    integer): string;
begin
  result := TVectorAccessUtility.GetStringValueInVector(Engine, Handle, aAbsoluteVectorIndex);
end;

procedure TCharacterMatrix.SetValueForAbsoluteIndex(const aAbsoluteVectorIndex:
    integer; const value: string);
begin
  inherited;
  TVectorAccessUtility.SetStringValueInVector(Engine, Handle, aAbsoluteVectorIndex, value);
end;

//------------------------------------------------------------------------------


end.
