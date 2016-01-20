program opaRTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  FastMM4,
  DUnitTestRunner,
  NumericVectorTests in 'NumericVectorTests.pas',
  IntegerVectorTests in 'IntegerVectorTests.pas',
  MiscellaneousTests in 'MiscellaneousTests.pas',
  EnvironmentTests in 'EnvironmentTests.pas',
  CharacterVectorTests in 'CharacterVectorTests.pas',
  ErrorHandlingTests in 'ErrorHandlingTests.pas',
  UnivariateStatsTests in 'UnivariateStatsTests.pas',
  DataFrameTests in 'DataFrameTests.pas',
  MatrixTests in 'MatrixTests.pas',
  EvaluateTests in 'EvaluateTests.pas',
  opaR.TestUtils in 'opaR.TestUtils.pas',
  FactorTests in 'FactorTests.pas',
  ListTests in 'ListTests.pas',
  RFunctionTests in 'RFunctionTests.pas',
  S4ClassTests in 'S4ClassTests.pas',
  S4Test in 'S4Test.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := True;

  DUnitTestRunner.RunRegisteredTests;
end.

