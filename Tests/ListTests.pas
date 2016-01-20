unit ListTests;

interface

uses
  System.Math,
  TestFramework,

  opaR.TestUtils,

  opaR.Engine,
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.Exception;


type
  TListTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure CoercionAsList_Test;
    procedure IsList_Test;
    procedure ListSubsetting_Test;
  end;

implementation

{ TListTests }

//------------------------------------------------------------------------------
procedure TListTests.CoercionAsList_Test;
var
  functionAsList: IGenericVector;
  dataFrame: ISymbolicExpression;
  dataFrameAsList: IGenericVector;
begin
  functionAsList := FEngine.Evaluate('as.list').AsList;
  CheckEquals(3, functionAsList.VectorLength);
  CheckEquals(true, functionAsList[0].IsSymbol);
  CheckEquals(true, functionAsList[1].IsSymbol);
  CheckEquals(true, functionAsList[2].IsLanguage);

  dataFrame := FEngine.Evaluate('data.frame(a = rep(LETTERS[1:3], 2), b = rep(1:3, 2))');
  dataFrameAsList := dataFrame.AsList;
  CheckEquals(2, dataFrameAsList.VectorLength);
  CheckEquals(true, dataFrameAsList[0].IsFactor);
  CheckEquals(6, dataFrameAsList[1].AsInteger.VectorLength);
end;
//------------------------------------------------------------------------------
procedure TListTests.IsList_Test;
var
  exprPairList: ISymbolicExpression;
  exprList: ISymbolicExpression;
begin
  exprPairList := FEngine.Evaluate('pairlist(a=5)');
  exprList := FEngine.Evaluate('list(a=5)');
  CheckEquals(true, exprPairList.IsList);
  CheckEquals(true, exprList.IsList);
end;
//------------------------------------------------------------------------------
procedure TListTests.ListSubsetting_Test;
var
  lst: IGenericVector;
  vec1: INumericVector;
  vec2: INumericVector;
begin
  lst := FEngine.Evaluate('c(1.5, 2.5)').AsList;
  CheckEquals(2, lst.VectorLength);

  vec1 := lst[0].AsNumeric;
  CheckEquals(1, vec1.VectorLength);
  Check(SameValue(1.5, vec1[0]));

  vec2 := lst[1].AsNumeric;
  CheckEquals(1, vec2.VectorLength);
  Check(SameValue(2.5, vec2[0]));
end;
//------------------------------------------------------------------------------
procedure TListTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TListTests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TListTests.Suite);

end.
