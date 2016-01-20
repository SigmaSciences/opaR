unit CharacterVectorTests;

interface

uses
  System.SysUtils,
  TestFramework,

  opaR.Engine,
  opaR.CharacterVector,
  opaR.Interfaces;

type
  TCharacterVectorTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure CharacterVector_ArrayInitialisation_Test;
    procedure CharacterVector_Evaluate_Test;
    procedure CharacterVector_ToArray_Test;
    procedure CharacterVector_SetVectorDirect_Test;
  end;


implementation

{ TCharacterVectorTests }

//------------------------------------------------------------------------------
procedure TCharacterVectorTests.CharacterVector_ArrayInitialisation_Test;
var
  arr: TArray<string>;
  vec: ICharacterVector;
begin
  arr := TArray<string>.Create('aaa', 'bbb', 'ccc', 'ddd', 'eee');
  vec := TCharacterVector.Create(FEngine, arr);

  CheckEquals(5, vec.VectorLength);
  CheckEquals('bbb', vec[1]);
  CheckEquals('eee', vec[4]);
end;
//------------------------------------------------------------------------------
procedure TCharacterVectorTests.CharacterVector_Evaluate_Test;
var
  s1: string;
  s2: string;
  vec: ICharacterVector;
begin
  s1 := QuotedStr('foo');
  s2 := QuotedStr('bar');
  vec := FEngine.Evaluate('c(' + s1 + ', NA,' + s2 + ')').AsCharacter;

  CheckEquals(3, vec.VectorLength);
  CheckEquals('foo', vec[0]);
  CheckEquals('', vec[1]);
  CheckEquals('bar', vec[2]);
end;
//------------------------------------------------------------------------------
procedure TCharacterVectorTests.CharacterVector_SetVectorDirect_Test;
var
  arr: TArray<string>;
  vec: ICharacterVector;
begin
  arr := TArray<string>.Create('aaa', 'bbb', 'ccc', 'ddd', 'eee');
  vec := TCharacterVector.Create(FEngine, Length(arr));
  vec.SetVectorDirect(arr);

  CheckEquals(5, vec.VectorLength);
  CheckEquals('bbb', vec[1]);
  CheckEquals('eee', vec[4]);
end;
//------------------------------------------------------------------------------
procedure TCharacterVectorTests.CharacterVector_ToArray_Test;
var
  arr1: TArray<string>;
  arr2: TArray<string>;
  vec: ICharacterVector;
begin
  arr1 := TArray<string>.Create('aaa', 'bbb', 'ccc', 'ddd', 'eee');
  vec := TCharacterVector.Create(FEngine, arr1);

  arr2 := vec.ToArray;

  CheckEquals('bbb', vec[1]);
  CheckEquals('eee', vec[4]);
end;
//------------------------------------------------------------------------------
procedure TCharacterVectorTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TCharacterVectorTests.TearDown;
begin
  inherited;

end;


initialization
  TestFramework.RegisterTest(TCharacterVectorTests.Suite);

end.
