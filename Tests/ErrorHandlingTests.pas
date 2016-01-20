unit ErrorHandlingTests;

{-------------------------------------------------------------------------------

In these tests we check that we properly capture errors raised by R, and
reproduce those described in the R.NET tests.

-------------------------------------------------------------------------------}

interface

uses
  System.SysUtils,
  TestFramework,

  opaR.TestUtils,

  opaR.Engine,
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.Exception;


type
  TErrorHandlingTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure FailedExpressionParsing_Test;
    procedure FailedExpressionEvaluation_Test;
    procedure FailedExpressionParsingMissingParenthesis_Test;
    procedure FailedExpressionUnboundSymbol_Test;
    procedure FailedExpressionUnboundSymbolEvaluation_Test;
  end;


implementation

{ TErrorHandlingTests }

//------------------------------------------------------------------------------
procedure TErrorHandlingTests.FailedExpressionEvaluation_Test;
var
  expectedMsg: string;
begin
  expectedMsg := 'Error in fail("bailing out") : the message is bailing out' + #10;

  CheckException(EopaREvaluationException,
                procedure
                begin
                  FEngine.Evaluate('fail <- function(msg) {stop(paste( ' + QuotedStr('the message is') + ', msg))}');
                  FEngine.Evaluate('fail(' + QuotedStr('bailing out') + ')');
                end,
                expectedMsg);
end;
//------------------------------------------------------------------------------
procedure TErrorHandlingTests.FailedExpressionParsingMissingParenthesis_Test;
var
  expectedMsg: string;
begin
  expectedMsg := 'Error: object ' + QuotedStr('x1') + ' not found' + #10;

  CheckException(EopaREvaluationException,
                procedure
                begin
                  FEngine.Evaluate('x1 <- rep(c(TRUE,FALSE), 55');
                  FEngine.Evaluate('x1')
                end,
                expectedMsg);
end;
//------------------------------------------------------------------------------
procedure TErrorHandlingTests.FailedExpressionParsing_Test;
var
  expectedMsg: string;
begin
  expectedMsg := 'Status Error for function(k) substitute(bar(x) = k)' + #10 + ' : unexpected ' + QuotedStr('=');

  CheckException(EopaRParseException,
                procedure
                begin
                  FEngine.Evaluate('function(k) substitute(bar(x) = k)')
                end,
                expectedMsg);
end;
//------------------------------------------------------------------------------
procedure TErrorHandlingTests.FailedExpressionUnboundSymbolEvaluation_Test;
var
  expectedMsg: string;
begin
  expectedMsg := 'Error: object ' + QuotedStr('x2') + ' not found' + #10;

  CheckException(EopaREvaluationException,
                procedure
                begin
                  FEngine.Evaluate('x2')
                end,
                expectedMsg);
end;
//------------------------------------------------------------------------------
procedure TErrorHandlingTests.FailedExpressionUnboundSymbol_Test;
var
  expectedMsg: string;
begin
  expectedMsg := 'Error: Object ' + QuotedStr('x3') + ' not found';

  CheckException(EopaREvaluationException,
                procedure
                begin
                  FEngine.GetSymbol('x3')
                end,
                expectedMsg);
end;
//------------------------------------------------------------------------------
procedure TErrorHandlingTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TErrorHandlingTests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TErrorHandlingTests.Suite);

end.
