unit UnivariateStatsTests;

{-------------------------------------------------------------------------------

1. The t-Test tests are based on the one described in the R.NET documentation.

-------------------------------------------------------------------------------}

interface

uses
  System.Math,
  TestFramework,
  Generics.Tuples, // From https://github.com/malcolmgroves/generics.tuples

  opaR.Engine,
  opaR.NumericVector,
  opaR.GenericVector,
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.Pairlist,
  opaR.Symbol;


type
  TUnivariateStatsTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure FTest_Test;
    procedure tTest_Test;
  end;

implementation

{ TUnivariateStatsTests }

//------------------------------------------------------------------------------
//-- In this test use the Engine.Evaluate method to add the data.
procedure TUnivariateStatsTests.FTest_Test;
var
  group1: INumericVector;
  group2: INumericVector;
  testResult: IGenericVector;
  lst: IPairList;
  arrTuple: TArray<ITuple<ISymbol, ISymbolicExpression>>;
  p: double;
  i: integer;
  numVec: INumericVector;
begin
  group1 := FEngine.Evaluate('group1 <- c(175.0, 168.0, 168.0, 190.0, 156.0, 181.0, 182.0, 175.0, 174.0, 179.0)').AsNumeric;
  group2 := FEngine.Evaluate('group2 <- c(185.0, 169.0, 173.0, 173.0, 188.0, 186.0, 175.0, 174.0, 179.0, 180.0)').AsNumeric;

  testResult := FEngine.Evaluate('var.test(group1, group2)').AsList;

  // -- Convert the generic vector to an R PairList.
  lst := testResult.ToPairlist;
  // -- Convert the R PairList to an array of tuples.
  arrTuple := lst.ToTupleArray;

  // -- Check that the PairList and Tuple conversions are working by
  // -- searching for the "statistic" symbol.
  for i := 0 to Length(arrTuple) - 1 do
  begin
    if arrTuple[i].Value1.PrintName = 'statistic' then
    begin
      numVec := arrTuple[i].Value2.AsNumeric;
      p := numVec[0];
      break;
    end;
  end;

  Check(SameValue(0.283425541040142, testResult['p.value'].AsNumeric.First, 0.000000000000001));
  Check(SameValue(2.10278372591006, p, 0.000000000000005));
end;
//------------------------------------------------------------------------------
procedure TUnivariateStatsTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TUnivariateStatsTests.TearDown;
begin
  inherited;

end;
//------------------------------------------------------------------------------
procedure TUnivariateStatsTests.tTest_Test;
var
  group1: INumericVector;
  group2: INumericVector;
  arr1: TArray<double>;
  arr2: TArray<double>;
  testResult: IGenericVector;
  pairList: IPairlist;
  arr: TArray<ISymbol>;
begin
  arr1 := TArray<double>.Create(30.02, 29.99, 30.11, 29.97, 30.01, 29.99);
  group1 := TNumericVector.Create(FEngine, arr1);
  FEngine.SetSymbol('group1', group1 as ISymbolicExpression);

  arr2 := TArray<double>.Create(29.89, 29.93, 29.72, 29.98, 30.02, 29.98);
  group2 := TNumericVector.Create(FEngine, arr2);
  FEngine.SetSymbol('group2', group2 as ISymbolicExpression);

  testResult := FEngine.Evaluate('t.test(group1, group2)').AsList;
  pairList := testResult.ToPairlist;
  arr := pairList.ToArray;

  CheckEquals(9, testResult.VectorLength);
  CheckEquals(9, pairList.Count);
  CheckEquals(9, Length(arr));
  Check(SameValue(0.090773324285671, testResult['p.value'].AsNumeric.First));
  Check(SameValue(1.95900580810807, testResult['statistic'].AsNumeric.First));
  // -- The following is the lower bound of the confidence interval.
  Check(SameValue(-0.0195690896460436, testResult['conf.int'].AsNumeric.First));
  // -- The following is the upper bound of the confidence interval.
  // -- Note that the following fails with the default epsilon in SameValue.
  // -- Float literals in Delphi Win32 are of extended type, so we can use
  // -- 16 digits after the decimal point in the epsilon below.
  // -- One option would be to use the extended type throughout opaR,
  // -- but extended is not supported in Delphi 64-bit.
  Check(SameValue(0.209569089646041, testResult['conf.int'].AsNumeric[1], 0.000000000000001));
end;


initialization
  TestFramework.RegisterTest(TUnivariateStatsTests.Suite);

end.
