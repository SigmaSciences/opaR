unit IntegerVectorTests;

interface

uses
  TestFramework,

  opaR.Engine,
  opaR.Interfaces,
  opaR.SymbolicExpression,
  opaR.IntegerVector;

type
  TIntegerVectorTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure IntegerVector_ArrayInitialisation_Test;
    procedure IntegerVector_ToArray_Test;
    procedure IntegerVector_SetVectorDirect_Test;
  end;


implementation

{ TIntegerVectorTests }

//------------------------------------------------------------------------------
procedure TIntegerVectorTests.IntegerVector_ArrayInitialisation_Test;
var
  arr: TArray<integer>;
  vec: IIntegerVector;
begin
  arr := TArray<integer>.Create(10, 20, 30, 40, 50);
  vec := TIntegerVector.Create(FEngine, arr);

  CheckEquals(true, (vec as TSymbolicExpression).IsVector);
  CheckEquals(5, vec.VectorLength);
  CheckEquals(20, vec[1]);
  CheckEquals(50, vec[4]);
end;
//------------------------------------------------------------------------------
procedure TIntegerVectorTests.IntegerVector_SetVectorDirect_Test;
var
  arr: TArray<integer>;
  vec: IIntegerVector;
begin
  arr := TArray<integer>.Create(10, 20, 30, 40, 50);
  vec := TIntegerVector.Create(FEngine, Length(arr));
  vec.SetVectorDirect(arr);

  CheckEquals(true, (vec as TSymbolicExpression).IsVector);
  CheckEquals(5, vec.VectorLength);
  CheckEquals(20, vec[1]);
  CheckEquals(50, vec[4]);
end;
//------------------------------------------------------------------------------
procedure TIntegerVectorTests.IntegerVector_ToArray_Test;
var
  arr1: TArray<integer>;
  arr2: TArray<integer>;
  vec: IIntegerVector;
begin
  arr1 := TArray<integer>.Create(10, 20, 30, 40, 50);
  vec := TIntegerVector.Create(FEngine, arr1);

  CheckEquals(true, (vec as TSymbolicExpression).IsVector);
  arr2 := vec.ToArray;

  CheckEquals(20, arr2[1]);
  CheckEquals(50, arr2[4]);
end;
//------------------------------------------------------------------------------
procedure TIntegerVectorTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TIntegerVectorTests.TearDown;
begin
  inherited;

end;



initialization
  TestFramework.RegisterTest(TIntegerVectorTests.Suite);

end.
