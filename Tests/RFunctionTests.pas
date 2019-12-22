unit RFunctionTests;

interface

uses
  TestFramework,
  System.Classes,
  System.SysUtils,
  System.Math,
  System.Variants,

  Generics.Tuples,

  opaR.TestUtils,
  opaR.Interfaces,
  opaR.Engine,
  opaR.SymbolicExpression,
  opaR.NumericVector,
  opaR.CharacterVector,
  opaR.IntegerVector,
  opaR.LogicalVector,
  opaR.RawVector,
  opaR.Utils;

type
  TRFunctionTests = class(TTestCase)
  private
    FEngine: IREngine;
    function CreateSexp(value: variant): ISymbolicExpression;
    function tc(argname: string; value: variant): TTuple<string, ISymbolicExpression>;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure BuiltinFunction_Tests;
    procedure DataFrameReturned_Tests;
    procedure GenericFunction_Tests;
    procedure SpecialFunctions_Tests;
    procedure StatsFunctions_Tests;
  end;

implementation

{ TRFunctionTests }

//------------------------------------------------------------------------------
procedure TRFunctionTests.BuiltinFunction_Tests;
var
  abs: IRFunction;
  arr: TArray<double>;
  absValues: TArray<double>;
  expected: TArray<double>;
begin
  abs := FEngine.GetSymbol('abs').AsFunction;
  CheckEquals(Ord(TSymbolicExpressionType.BuiltinFunction), Ord((abs as ISymbolicExpression).Type_));

  arr := TopaRArrayUtils.GenerateDoubleArray(-2, 2);
  absValues := abs.Invoke(FEngine.CreateNumericVector(arr) as ISymbolicExpression).AsNumeric.ToArray;

  CheckEquals(Length(arr), Length(absValues));
  expected := TArray<double>.Create(2, 1, 0, 1, 2);
  CheckEquals(true, TopaRArrayUtils.DoubleArraysEqual(expected, absValues));
end;
//------------------------------------------------------------------------------
function TRFunctionTests.CreateSexp(value: variant): ISymbolicExpression;
var
  t: TVarType;
begin
  t := VarType(value);
  case t of
    varUString: result := TCharacterVector.Create(FEngine, TArray<string>.Create(VarToStr(value)));
    varInteger: result := TIntegerVector.Create(FEngine, TArray<integer>.Create(value));
    varDouble: result := TNumericVector.Create(FEngine, TArray<double>.Create(value));
    varBoolean: result := TLogicalVector.Create(FEngine, TArray<LongBool>.Create(value));
    varByte: result := TRawVector.Create(FEngine, TArray<Byte>.Create(value));
  end;
end;
//------------------------------------------------------------------------------
procedure TRFunctionTests.DataFrameReturned_Tests;
var
  funcDef: string;
  fn1: IRFunction;
  expr: ISymbolicExpression;
  df10: IDataFrame;
  nm: INumericMatrix;
begin
  funcDef := 'function() {return(data.frame(a=1:4, b=5:8))}';
  fn1 := FEngine.Evaluate(funcDef).AsFunction;
  expr := fn1.Invoke;
  CheckEquals(true, expr.IsDataFrame);
  CheckEquals(true, expr.IsList);
  df10 := expr.AsDataFrame;
  CheckNotEquals(true, df10 = nil);
  CheckEquals(4, df10[3, 0]);
  CheckEquals(8, df10[3, 1]);

  funcDef := 'function(lyrics) {return(data.frame(a=1:4, b=5:8))}';
  fn1 := FEngine.Evaluate(funcDef).AsFunction;
  expr := fn1.Invoke(FEngine.CreateCharacter('Wo willst du hin?') as ISymbolicExpression);
  CheckEquals(true, expr.IsDataFrame);
  CheckEquals(true, expr.IsList);
  df10 := expr.AsDataFrame;
  CheckNotEquals(true, df10 = nil);

  funcDef := 'function() {return(as.matrix(data.frame(a=1:4, b=5:8)))}';
  fn1 := FEngine.Evaluate(funcDef).AsFunction;
  expr := fn1.Invoke;
  CheckEquals(false, expr.IsDataFrame);
  CheckEquals(false, expr.IsList);
  df10 := expr.AsDataFrame;
  CheckEquals(true, df10 = nil);
  nm := expr.AsNumericMatrix;
  CheckNotEquals(true, nm = nil);
  CheckEquals(true, expr.IsMatrix);
end;
//------------------------------------------------------------------------------
procedure TRFunctionTests.GenericFunction_Tests;
var
  defPrintPairlist: string;
  sl: TStringList;
  funcDef: string;
  f2: IRFunction;
  args: TArray<TTuple<string, ISymbolicExpression>>;
  rtn: string;
  arg1: double;
  arg2: integer;

  group1: INumericVector;
  group2: INumericVector;
  studentTest: IRFunction;
  testResult: IGenericVector;
  expr: ISymbolicExpression;
begin
  defPrintPairlist := TopaRArrayUtils.PrintPairlist;

  sl := TStringList.Create;
  sl.Add('setGeneric( ' + QuotedStr('f2') +  ', function(x, ...) {');
  sl.Add('standardGeneric(' + QuotedStr('f2') + ')');
  sl.Add('} )');
  sl.Add('setMethod( ' + QuotedStr('f2') + ', ' + QuotedStr('integer') + ', function(x, ...) { paste( ' + QuotedStr('f2.integer called:') + ', printPairList(...) ) } )');
  sl.Add('setMethod( ' + QuotedStr('f2') + ', ' + QuotedStr('numeric') + ', function(x, ...) { paste( ' + QuotedStr('f2.numeric called:') + ', printPairList(...) ) } )');
  funcDef := sl.Text;
  sl.Free;

  FEngine.Evaluate(defPrintPairlist);
  FEngine.Evaluate(funcDef);

  f2 := FEngine.GetSymbol('f2').AsFunction;
  arg1 := 1.0;   // -- Force the variant to double.

  args := TArray<TTuple<string, ISymbolicExpression>>.Create(tc('x', arg1), tc('b', '2'), tc('c', '3'));
  rtn := f2.InvokeNamed(args).AsCharacter.ToArray[0];
  CheckEquals('f2.numeric called:  b=2; c=3', f2.InvokeNamed(args).AsCharacter.ToArray[0]);

  args := TArray<TTuple<string, ISymbolicExpression>>.Create(tc('x', arg1), tc('b', '2.1'), tc('c', '3'));
  rtn := f2.InvokeNamed(args).AsCharacter.ToArray[0];
  CheckEquals('f2.numeric called:  b=2.1; c=3', f2.InvokeNamed(args).AsCharacter.ToArray[0]);

  args := TArray<TTuple<string, ISymbolicExpression>>.Create(tc('x', arg1), tc('c', '3'), tc('b', '2'));
  rtn := f2.InvokeNamed(args).AsCharacter.ToArray[0];
  CheckEquals('f2.numeric called:  c=3; b=2', f2.InvokeNamed(args).AsCharacter.ToArray[0]);

  arg2 := 1;     // -- Force the variant to integer.
  args := TArray<TTuple<string, ISymbolicExpression>>.Create(tc('x', arg2), tc('b', '2'), tc('c', '3'));
  rtn := f2.InvokeNamed(args).AsCharacter.ToArray[0];
  CheckEquals('f2.integer called:  b=2; c=3', f2.InvokeNamed(args).AsCharacter.ToArray[0]);

  args := TArray<TTuple<string, ISymbolicExpression>>.Create(tc('x', arg2), tc('c', '3'), tc('b', '2'));
  rtn := f2.InvokeNamed(args).AsCharacter.ToArray[0];
  CheckEquals('f2.integer called:  c=3; b=2', f2.InvokeNamed(args).AsCharacter.ToArray[0]);

  // -- The next test is similar to TUnivariateStatsTests.tTest_Test, but uses
  // -- a different approach -> Evaluate('t.test').AsFunction.
  group1 := FEngine.Evaluate('group1 <- c(30.02, 29.99, 30.11, 29.97, 30.01, 29.99)').AsNumeric;
  group2 := FEngine.Evaluate('group2 <- c(29.89, 29.93, 29.72, 29.98, 30.02, 29.98)').AsNumeric;
  studentTest := FEngine.Evaluate('t.test').AsFunction;
  testResult := studentTest.Invoke(TArray<ISymbolicExpression>.Create(group1 as ISymbolicExpression, group2 as ISymbolicExpression)).AsList;
  Check(SameValue(0.090773324285671, testResult.ValueByName['p.value'].AsNumeric.First));

  expr := studentTest.Invoke(TArray<ISymbolicExpression>.Create(FEngine.Evaluate('1:10'), FEngine.Evaluate('7:20')));
  Check(SameValue(1.85528183251e-05, expr.AsList.ValueByName['p.value'].AsNumeric[0]));
end;
//------------------------------------------------------------------------------
procedure TRFunctionTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TRFunctionTests.SpecialFunctions_Tests;
var
  plus: IRFunction;
  isOne: string;
  notOne: string;
  args: TArray<string>;
begin
  plus := FEngine.Evaluate('`if`').AsFunction;
  FEngine.Evaluate('a <- 1');

  isOne := QuotedStr('this is one');
  notOne := QuotedStr('this is not one');
  args := TArray<string>.Create('quote(a==1)', isOne, notOne);
  CheckEquals('this is one', plus.InvokeStrArgs(args).AsCharacter.ToArray[0]);

  FEngine.Evaluate('a <- 2');
  CheckEquals('this is not one', plus.InvokeStrArgs(args).AsCharacter.ToArray[0]);
end;
//------------------------------------------------------------------------------
procedure TRFunctionTests.StatsFunctions_Tests;
var
  valArray: TArray<double>;
  dpois: IRFunction;
  vecx: INumericVector;
  lambda: INumericVector;
  log: ILogicalVector;
  distVal: ISymbolicExpression;
  signif: IRFunction;
  signifValues: TArray<double>;
  expected: TArray<double>;
  vec: IIntegerVector;
begin
  valArray := TopaRArrayUtils.GenerateDoubleArray(0, 7);
  dpois := FEngine.GetSymbol('dpois').AsFunction;

  vecx := FEngine.CreateNumericVector(valArray);
  lambda := FEngine.CreateNumericVector(TArray<double>.Create(0.9));
  log := FEngine.CreateLogicalVector(TArray<LongBool>.Create(false));

  // -- First check that it passes without exceptions.
  distVal := dpois.Invoke(TArray<ISymbolicExpression>.Create(vecx as ISymbolicExpression,
                                                             lambda as ISymbolicExpression,
                                                             log as ISymbolicExpression));

  distVal := dpois.Invoke(TArray<ISymbolicExpression>.Create(vecx as ISymbolicExpression,
                                                             lambda as ISymbolicExpression));
  signif := FEngine.GetSymbol('signif').AsFunction;
  vec := FEngine.CreateIntegerVector(TArray<integer>.Create(2));
  signifValues := signif.Invoke(TArray<ISymbolicExpression>.Create(distVal, vec as ISymbolicExpression)).AsNumeric.ToArray;
  expected := TArray<double>.Create(4.1e-01, 3.7e-01, 1.6e-01, 4.9e-02, 1.1e-02, 2.0e-03, 3.0e-04, 3.9e-05);

  CheckEquals(true, TopaRArrayUtils.DoubleArraysEqual(expected, signifValues));
end;
//------------------------------------------------------------------------------
function TRFunctionTests.tc(argname: string;
  value: variant): TTuple<string, ISymbolicExpression>;
begin
  result := TTuple<string, ISymbolicExpression>.Create(argname, CreateSexp(value));
end;
//------------------------------------------------------------------------------
procedure TRFunctionTests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TRFunctionTests.Suite);

end.
