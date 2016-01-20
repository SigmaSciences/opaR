unit NumericVectorTests;

interface

uses
  TestFramework,
  System.Math,

  opaR.Interfaces,
  opaR.Engine,
  opaR.SymbolicExpression,
  opaR.NumericVector;


type
  TNumericVectorTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure NumericVector_ArrayInitialisation_Test;
    procedure NumericVector_ToArray_Test;
    procedure NumericVector_SetVectorDirect_Test;
  end;

implementation


{ TNumericVectorTests }

//------------------------------------------------------------------------------
procedure TNumericVectorTests.NumericVector_ArrayInitialisation_Test;
var
  arr: TArray<double>;
  vec: INumericVector;
begin
  arr := TArray<double>.Create(1.1, 2.2, 3.3, 4.4, 5.5);
  vec := TNumericVector.Create(FEngine, arr);

  CheckEquals(true, (vec as TSymbolicExpression).IsVector);
  CheckEquals(5, vec.VectorLength);
  Check(SameValue(2.2, vec[1]));
  Check(SameValue(5.5, vec[4]));
end;
//------------------------------------------------------------------------------
procedure TNumericVectorTests.NumericVector_ToArray_Test;
var
  arr1: TArray<double>;
  arr2: TArray<double>;
  vec: INumericVector;
begin
  arr1 := TArray<double>.Create(1.1, 2.2, 3.3, 4.4, 5.5);
  vec := TNumericVector.Create(FEngine, arr1);

  CheckEquals(true, (vec as TSymbolicExpression).IsVector);
  arr2 := vec.ToArray;

  Check(SameValue(2.2, arr2[1]));
  Check(SameValue(5.5, arr2[4]));
end;
//------------------------------------------------------------------------------
procedure TNumericVectorTests.NumericVector_SetVectorDirect_Test;
var
  arr: TArray<double>;
  vec: INumericVector;
begin
  arr := TArray<double>.Create(1.1, 2.2, 3.3, 4.4, 5.5);
  vec := TNumericVector.Create(FEngine, Length(arr));
  vec.SetVectorDirect(arr);

  CheckEquals(true, (vec as TSymbolicExpression).IsVector);
  CheckEquals(5, vec.VectorLength);
  Check(SameValue(2.2, vec[1]));
  Check(SameValue(5.5, vec[4]));
end;
//------------------------------------------------------------------------------
procedure TNumericVectorTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TNumericVectorTests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TNumericVectorTests.Suite);

end.
