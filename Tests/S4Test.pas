unit S4Test;

interface

uses
  System.SysUtils,
  TestFramework,

  Spring.Collections,

  opaR.TestUtils,
  opaR.Engine,
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.CharacterVector;


type
  TS4Tests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure GetSlotTypes_Test;
    procedure HasSlot_Test;
    procedure GetSlot_Test;
    procedure SetSlot_Test;
  end;

implementation

{ TS4Tests }

//------------------------------------------------------------------------------
procedure TS4Tests.GetSlotTypes_Test;
var
  s4: IS4Object;
  test: string;
  foo: string;
  actual: IDictionary<string, string>;
begin
  test := QuotedStr('testclass');
  foo := QuotedStr('s4');
  s4 := FEngine.Evaluate('new(' + test + ', foo= ' + foo + ', bar=1:4)').AsS4;
  actual := s4.GetSlotTypes;

  CheckEquals(2, actual.Count);
  CheckEquals(true, actual.ContainsKey('foo'));
  CheckEquals('character', actual['foo']);
  CheckEquals(true, actual.ContainsKey('bar'));
  CheckEquals('integer', actual['bar']);
end;
//------------------------------------------------------------------------------
procedure TS4Tests.GetSlot_Test;
var
  s4: IS4Object;
  test: string;
  foo: string;
  vec: IIntegerVector;
begin
  test := QuotedStr('testclass');
  foo := QuotedStr('s4');
  s4 := FEngine.Evaluate('new(' + test + ', foo= ' + foo + ', bar=1:4)').AsS4;
  foo := s4['foo'].AsCharacter.First;   // -- R.NET test uses a GetSlot method here.
  CheckEquals(foo, 's4');
  vec := s4['bar'].AsInteger;
  CheckEquals(true, TopaRArrayUtils.IntArraysEqual(TArray<integer>.Create(1, 2, 3, 4), vec.ToArray));
end;
//------------------------------------------------------------------------------
procedure TS4Tests.HasSlot_Test;
var
  s4: IS4Object;
  test: string;
  foo: string;
begin
  test := QuotedStr('testclass');
  foo := QuotedStr('s4');
  s4 := FEngine.Evaluate('new(' + test + ', foo= ' + foo + ', bar=1:4)').AsS4;
  CheckEquals(true, s4.HasSlot('foo'));
  CheckEquals(true, s4.HasSlot('bar'));
  CheckEquals(false, s4.HasSlot('baz'));
end;
//------------------------------------------------------------------------------
procedure TS4Tests.SetSlot_Test;
var
  s4: IS4Object;
  test: string;
  foo: string;
  vec: IIntegerVector;
begin
  test := QuotedStr('testclass');
  foo := QuotedStr('s4');
  s4 := FEngine.Evaluate('new(' + test + ', foo= ' + foo + ', bar=1:4)').AsS4;
  foo := s4['foo'].AsCharacter.First;   // -- R.NET test uses a GetSlot method here.
  CheckEquals(foo, 's4');
  s4['foo'] := TCharacterVector.Create(FEngine, TArray<string>.Create('new value'));
  foo := s4['foo'].AsCharacter.First;
  CheckEquals(foo, 'new value');
end;
//------------------------------------------------------------------------------
procedure TS4Tests.SetUp;
var
  test: string;
  charType: string;
  intType: string;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;

  // -- Define the test class at the Setup stage.
  test := QuotedStr('testclass');
  charType := QuotedStr('character');
  intType := QuotedStr('integer');
  FEngine.Evaluate('setClass(' + test + ', representation(foo=' + charType + ', bar=' + intType + '))');
end;
//------------------------------------------------------------------------------
procedure TS4Tests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TS4Tests.Suite);

end.
