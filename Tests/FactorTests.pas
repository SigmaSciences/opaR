unit FactorTests;

interface

uses
  System.SysUtils,
  TestFramework,

  opaR.TestUtils,

  opaR.Engine,
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.Factor;

type
  // -- Remember that we require a non-initalised enum.
  TGroup = (Treatment, Control);

  TFactorTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure AsCharacterFactors_Test;
    procedure GetFactorsEnum_Test;
    procedure GetLevels_Test;
    procedure IsOrderedFalse_Test;
    procedure IsOrderedTrue_Test;
    procedure Length_Test;
    procedure MissingValues_Test;
  end;


implementation

{ TFactorTests }

//------------------------------------------------------------------------------
procedure TFactorTests.AsCharacterFactors_Test;
var
  charVec: ICharacterVector;
begin
  charVec := FEngine.Evaluate('as.factor(rep(letters[1:3], 5))').AsCharacter;
  CheckEquals(15, charVec.VectorLength);
  CheckEquals('a', charVec[0]);
  CheckEquals('b', charVec[1]);
  CheckEquals('c', charVec[2]);
  CheckEquals('a', charVec[0]);
end;
//------------------------------------------------------------------------------
procedure TFactorTests.GetFactorsEnum_Test;
var
  code: string;
  t: string;
  c: string;
  factor: IFactor;
  expected: TArray<TGroup>;
  factors: TArray<TGroup>;
  i: integer;
  arraysEqual: boolean;
begin
  t := QuotedStr('T');
  c := QuotedStr('C');
  code := 'factor(c(rep(' + t + ', 3), rep(' + c + ', 5), rep(' + t + ', 4), rep(' + c + ', 2)), levels=c(' + t + ', ' + c + '), labels=c(' + QuotedStr('Treatment') + ', ' + QuotedStr('Control') + '))';
  factor := FEngine.Evaluate(code).AsFactor;
  factors := (factor as TFactor).GetFactors<TGroup>;
  expected := TArray<TGroup>.Create(Treatment, Treatment, Treatment,
                                    Control, Control, Control, Control, Control,
                                    Treatment, Treatment, Treatment, Treatment,
                                    Control, Control);

  CheckEquals(14, Length(factors));
  CheckEquals(14, Length(expected));

  if Length(factors) = Length(expected) then
  begin
    arraysEqual := true;
    for i := 0 to Length(factors) - 1 do
    begin
      if factors[i] <> expected[i] then
      begin
        arraysEqual := false;
        break;
      end;
    end;
    CheckEquals(true, arraysEqual);
  end;
end;
//------------------------------------------------------------------------------
procedure TFactorTests.GetLevels_Test;
var
  fac: IFactor;
  levelA: string;
  levelB: string;
  levelC: string;
  levels: TArray<string>;
  expected: TArray<string>;
begin
  levelA := QuotedStr('A');
  levelB := QuotedStr('B');
  levelC := QuotedStr('C');

  fac := FEngine.Evaluate('fac <- factor(c(' + levelA + ',' + levelB + ',' + levelA + ','
    + levelC + ',' + levelB + '))').AsFactor;
  levels := fac.GetLevels;
  expected := TArray<string>.Create('A', 'B', 'C');
  CheckEquals(true, TopaRArrayUtils.StringArraysEqual(expected, levels));

  levelA := QuotedStr('1st');
  levelB := QuotedStr('2nd');
  levelC := QuotedStr('3rd');
  // -- Note the #10 (CR) in the code string.
  fac := FEngine.Evaluate('levels(fac) <- c(' + levelA + ', ' + levelB + ', ' + levelC + ')' + #10 + 'fac').AsFactor;
  levels := fac.GetLevels;
  expected := TArray<string>.Create('1st', '2nd', '3rd');
  CheckEquals(true, TopaRArrayUtils.StringArraysEqual(expected, levels));
end;
//------------------------------------------------------------------------------
procedure TFactorTests.IsOrderedFalse_Test;
var
  fac: IFactor;
  levelA: string;
  levelB: string;
  levelC: string;
begin
  levelA := QuotedStr('A');
  levelB := QuotedStr('B');
  levelC := QuotedStr('C');

  fac := FEngine.Evaluate('factor(c(' + levelA + ',' + levelB + ',' + levelA + ','
    + levelC + ',' + levelB + '), ordered=FALSE)').AsFactor;
  CheckEquals(false, fac.IsOrdered);
end;
//------------------------------------------------------------------------------
procedure TFactorTests.IsOrderedTrue_Test;
var
  fac: IFactor;
  levelA: string;
  levelB: string;
  levelC: string;
begin
  levelA := QuotedStr('A');
  levelB := QuotedStr('B');
  levelC := QuotedStr('C');

  fac := FEngine.Evaluate('factor(c(' + levelA + ',' + levelB + ',' + levelA + ','
    + levelC + ',' + levelB + '), ordered=TRUE)').AsFactor;
  CheckEquals(true, fac.IsOrdered);
end;
//------------------------------------------------------------------------------
procedure TFactorTests.Length_Test;
var
  fac: IFactor;
  levelA: string;
  levelB: string;
  levelC: string;
begin
  levelA := QuotedStr('A');
  levelB := QuotedStr('B');
  levelC := QuotedStr('C');

  fac := FEngine.Evaluate('factor(c(' + levelA + ',' + levelB + ',' + levelA + ','
    + levelC + ',' + levelB + '))').AsFactor;
  CheckEquals(5, fac.VectorLength);
end;
//------------------------------------------------------------------------------
procedure TFactorTests.MissingValues_Test;
var
  fac1: IFactor;
  levelA: string;
  levelB: string;
  levelC: string;
  factors: TArray<string>;
  expected: TArray<string>;
begin
  levelA := QuotedStr('A');
  levelB := QuotedStr('B');
  levelC := QuotedStr('C');

  fac1 := FEngine.Evaluate('fac1 <- factor(c(' + levelA + ',' + levelB + ',' + levelA + ', NA,'
    + levelC + ',' + levelB + '), ordered=TRUE)').AsFactor;
  expected := TArray<string>.Create('A', 'B', 'A', '', 'C', 'B');
  factors := fac1.GetFactors;
  CheckEquals(true, TopaRArrayUtils.StringArraysEqual(expected, factors));

  levelA := QuotedStr('1st');
  levelB := QuotedStr('2nd');
  levelC := QuotedStr('3rd');
  // -- Note the #10 (CR) in the code string.
  fac1 := FEngine.Evaluate('levels(fac1) <- c(' + levelA + ', ' + levelB + ', ' + levelC + ')' + #10 + 'fac1').AsFactor;
  expected := TArray<string>.Create('1st', '2nd', '1st', '', '3rd', '2nd');
  factors := fac1.GetFactors;
  CheckEquals(true, TopaRArrayUtils.StringArraysEqual(expected, factors));
end;
//------------------------------------------------------------------------------
procedure TFactorTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TFactorTests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TFactorTests.Suite);

end.
