unit MatrixTests;

interface

uses
  System.Math,
  TestFramework,

  opaR.Engine,
  opaR.SymbolicExpression,
  opaR.Interfaces;

type
  TMatrixTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure CharacterMatrix_Test;
    procedure Dim_Test;
    procedure IntegerMatrix_Test;
    procedure NumericMatrix_Test;
  end;


implementation

{ TMatrixTests }

//------------------------------------------------------------------------------
//-- This test starts with the standard iris dataset and coerces it to a
//-- character matrix.
procedure TMatrixTests.CharacterMatrix_Test;
var
  iris: IDataFrame;
  matrix: ICharacterMatrix;
begin
  iris := FEngine.Evaluate('iris').AsDataFrame;
  // -- Because there is a non-numeric column in iris, R coerces all columns
  // -- to character type.
  matrix := FEngine.Evaluate('iris.mat <- as.matrix(iris)').AsCharacterMatrix;

  CheckEquals(150, matrix.RowCount);
  CheckEquals(5, matrix.ColumnCount);
  CheckEquals(true, (matrix as TSymbolicExpression).IsMatrix);

  CheckEquals('5.4', matrix[10, 0]);
  CheckEquals('4.6', matrix[47, 0]);
  CheckEquals('3.1', matrix[52, 1]);
  CheckEquals('3.9', matrix[59, 2]);
  CheckEquals('2.3', matrix[141, 3]);
  CheckEquals('virginica', matrix[149, 4]);
end;
//------------------------------------------------------------------------------
//-- Note that Dim_Test also tests the ILogicalVector type.
procedure TMatrixTests.Dim_Test;
var
  dimVec: IIntegerVector;
  boolVec: ILogicalVector;
begin
  FEngine.Evaluate('vec <- 1:24');
  dimVec := FEngine.Evaluate('dim(vec) <- c(6, 4)').AsInteger;

  // -- dimVec holds the matrix dimensions in a 2-element vector.
  CheckEquals(true, (dimVec as TSymbolicExpression).IsVector);
  CheckEquals(2, dimVec.VectorLength);
  CheckEquals(6, dimVec[0]);
  CheckEquals(4, dimVec[1]);

  boolVec := FEngine.Evaluate('is.matrix(vec)').AsLogical;
  CheckEquals(1, boolVec.VectorLength);
  CheckEquals(true, boolVec[0]);
end;
//------------------------------------------------------------------------------
//-- This test constructs an integer matrix from an integer vector using the
//-- dim() function.
procedure TMatrixTests.IntegerMatrix_Test;
var
  vec: IIntegerVector;
  vec2: IIntegerVector;
  matrix1: IIntegerMatrix;
  matrix2: IIntegerMatrix;
begin
  vec := FEngine.Evaluate('vec <- 1:25').AsInteger;
  FEngine.Evaluate('dim(vec) <- c(5, 5)');
  matrix1 := FEngine.Evaluate('vec').AsIntegerMatrix;

  CheckEquals(5, matrix1.RowCount);
  CheckEquals(5, matrix1.ColumnCount);
  CheckEquals(6, matrix1[0, 1]);
  CheckEquals(21, matrix1[0, 4]);
  CheckEquals(5, matrix1[4, 0]);
  CheckEquals(25, matrix1[4, 4]);

  // -- The default in R is to fill columns first.
  // -- Use byrow=TRUE to fill rows first.
  vec2 := FEngine.Evaluate('vec2 <- 1:25').AsInteger;
  FEngine.Evaluate('mtx <- matrix(vec2, 5, byrow=TRUE)');
  matrix2 := FEngine.Evaluate('mtx').AsIntegerMatrix;

  CheckEquals(5, matrix2.RowCount);
  CheckEquals(5, matrix2.ColumnCount);
  CheckEquals(2, matrix2[0, 1]);
  CheckEquals(5, matrix2[0, 4]);
  CheckEquals(21, matrix2[4, 0]);
  CheckEquals(25, matrix2[4, 4]);
end;
//------------------------------------------------------------------------------
//-- This test starts with the standard iris dataset and extracts the first
//-- four columns (which are numeric) to create a numeric matrix.
procedure TMatrixTests.NumericMatrix_Test;
var
  iris: IDataFrame;
  matrix: INumericMatrix;
begin
  iris := FEngine.Evaluate('iris').AsDataFrame;
  matrix := FEngine.Evaluate('iris.mat <- as.matrix(iris[,1:4])').AsNumericMatrix;

  CheckEquals(150, matrix.RowCount);
  CheckEquals(4, matrix.ColumnCount);
  Check(SameValue(5.4, matrix[10, 0]));
  Check(SameValue(4.6, matrix[47, 0]));
  Check(SameValue(3.1, matrix[52, 1]));
  Check(SameValue(3.9, matrix[59, 2]));
  Check(SameValue(2.3, matrix[141, 3]));
end;
//------------------------------------------------------------------------------
procedure TMatrixTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TMatrixTests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TMatrixTests.Suite);

end.
