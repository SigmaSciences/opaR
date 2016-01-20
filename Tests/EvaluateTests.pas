unit EvaluateTests;

{-------------------------------------------------------------------------------

This group of tests covers the use of "Evaluate" for a number of different
input scripts.

-------------------------------------------------------------------------------}

interface

uses
  System.Math,
  TestFramework,

  opaR.Engine,
  opaR.SymbolicExpression,
  opaR.Interfaces;

type
  TEvaluateTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Eval_Test1;
  end;

implementation

{ TEvaluateTests }

//------------------------------------------------------------------------------
procedure TEvaluateTests.Eval_Test1;
begin

end;
//------------------------------------------------------------------------------
procedure TEvaluateTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TEvaluateTests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TEvaluateTests.Suite);

end.
