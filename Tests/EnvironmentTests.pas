unit EnvironmentTests;

interface

uses
  TestFramework,

  opaR.Engine,
  opaR.Environment,
  opaR.NumericVector,
  opaR.Interfaces;

type
  TEnvironmentTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure GlobalEnvironment_Test;
    procedure NewEnvironment_Test;
  end;


implementation

{ TEnvironmentTests }

//------------------------------------------------------------------------------
procedure TEnvironmentTests.GlobalEnvironment_Test;
var
  globalEnv: IREnvironment;
  arrSymbolNames: TArray<string>;
  i: integer;
  arr1: TArray<double>;
  vec: INumericVector;
begin
  // -- In this test we add some symbols to the global environment and check
  // -- that we can retrieve them.
  globalEnv := FEngine.GlobalEnvironment;

  arr1 := TArray<double>.Create(1.0, 2.0, 3.0, 4.0, 5.0);
  vec := TNumericVector.Create(FEngine, arr1);
  globalEnv.SetSymbol('vec1', (vec as ISymbolicExpression));

  FEngine.Evaluate('x <- 3');
  FEngine.Evaluate('y <- 4');

  arrSymbolNames := globalEnv.GetSymbolNames(false);

  CheckEquals(3, Length(arrSymbolNames));
  CheckEquals('vec1', arrSymbolNames[0]);
  CheckEquals('x', arrSymbolNames[1]);
  CheckEquals('y', arrSymbolNames[2]);
end;
//------------------------------------------------------------------------------
procedure TEnvironmentTests.NewEnvironment_Test;
var
  globalEnv: IREnvironment;
  newEnv: IREnvironment;
  arrSymbolNames: TArray<string>;
begin
  globalEnv := FEngine.GlobalEnvironment;

  // -- Create a new environment (with the global as it's parent), name it and
  // -- add a couple of variables to it.
  newEnv := TREnvironment.Create(FEngine, globalEnv);
  globalEnv.SetSymbol('e', newEnv);

  // -- Note that we qualify the variable names with the new env name.
  FEngine.Evaluate('e$x <- 3');
  FEngine.Evaluate('e$y <- 4');

  arrSymbolNames := newEnv.GetSymbolNames(false);

  CheckEquals(2, Length(arrSymbolNames));
  CheckEquals('x', arrSymbolNames[0]);
  CheckEquals('y', arrSymbolNames[1]);
end;
//------------------------------------------------------------------------------
procedure TEnvironmentTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TEnvironmentTests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TEnvironmentTests.Suite);

end.
