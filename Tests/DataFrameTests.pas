unit DataFrameTests;

{-------------------------------------------------------------------------------

The "iris" dataset is included in R as a standard dataset and is used as the
basis of the tests in this group.

-------------------------------------------------------------------------------}

interface

uses
  System.Math,
  TestFramework,

  opaR.Engine,
  opaR.SymbolicExpression,
  opaR.Interfaces;

type
  TDataFrameTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Iris_Test;
    procedure IrisSubset_Test;
    procedure DataFrameRow_Test;
  end;

implementation

{ TDataFrameTests }

//------------------------------------------------------------------------------
procedure TDataFrameTests.DataFrameRow_Test;
var
  irisDF: IDataFrame;
  row: IDataFrameRow;
begin
  irisDF := FEngine.Evaluate('iris').AsDataFrame;
  row := irisDF.GetRow(0);

  Check(SameValue(5.1, row[0]));
  Check(SameValue(3.5, row['Sepal.Width']));
  Check(SameValue(1.4, row[2]));
  Check(SameValue(0.2, row[3]));
  CheckEquals('setosa', row[4]);
end;
//------------------------------------------------------------------------------
procedure TDataFrameTests.IrisSubset_Test;
var
  iris50: IDataFrame;
  row1: IDataFrameRow;
  row50: IDataFrameRow;
begin
  iris50 := FEngine.Evaluate('iris[1:50,]').AsDataFrame;
  row1 := iris50.GetRow(0);
  row50 := iris50.GetRow(49);

  CheckEquals(50, iris50.RowCount);

  // -- Check the first row, getting the columns by name.
  Check(SameValue(5.1, row1['Sepal.Length']));
  Check(SameValue(3.5, row1['Sepal.Width']));
  Check(SameValue(1.4, row1['Petal.Length']));
  Check(SameValue(0.2, row1['Petal.Width']));
  CheckEquals('setosa', row1['Species']);

  // -- Check the last row.
  Check(SameValue(5.0, row50[0]));
  Check(SameValue(3.3, row50['Sepal.Width']));
  Check(SameValue(1.4, row50[2]));
  Check(SameValue(0.2, row50[3]));
  CheckEquals('setosa', row50[4]);
end;
//------------------------------------------------------------------------------
procedure TDataFrameTests.Iris_Test;
var
  irisDF: IDataFrame;
begin
  irisDF := FEngine.Evaluate('iris').AsDataFrame;

  CheckEquals(150, irisDF.RowCount);
  Check(SameValue(3.7, irisDF[10, 'Sepal.Width']));
  CheckEquals('setosa', irisDF[10, 4]);

  // -- Note that opaR is using the default row names for "iris", in contrast
  // -- to R.NET which enforces the existence of specified row names.
  // -- The following line therefore raises an exception in R.NET.
  Check(SameValue(3.1, irisDF['10', 'Sepal.Width']));

  Check(SameValue(5.4, irisDF[10, 0]));
  Check(SameValue(4.6, irisDF[47, 0]));
  Check(SameValue(3.1, irisDF[52, 1]));
  Check(SameValue(3.9, irisDF[59, 2]));
  Check(SameValue(2.3, irisDF[141, 3]));
  CheckEquals('virginica', irisDF[149, 4]);
end;
//------------------------------------------------------------------------------
procedure TDataFrameTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TDataFrameTests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TDataFrameTests.Suite);

end.
