unit opaR.TestUtils;

{-------------------------------------------------------------------------------

opaR: object pascal for R

Define a class helper for TestFramework.TAbstractTest using the same approach
as in Spring4D (Spring.TestUtils.pas), but with an an extra message parameter
that allows us to compare the exception message to the expected message.

By checking the exception message we can validate the error message returned
from R (see TEngineExtension.LastErrorMessage).

-------------------------------------------------------------------------------}

interface

uses
  System.SysUtils,
  System.Math,
  System.Classes,

  TestFramework;


type
  TAbstractTestHelper = class helper for TAbstractTest
  public
    procedure CheckException(expected: ExceptionClass; method: TProc;
      const expectedMsg: string = ''; const msg: string = ''); overload;
  end;

  TopaRArrayUtils = class
  public
    class function GenerateDoubleArray(low, high: integer): TArray<double>;
    class function GenerateIntArray(low, high: integer): TArray<integer>;
    class function DoubleArraysEqual(expectedArray, testArray: TArray<double>): boolean;
    class function IntArraysEqual(expectedArray, testArray: TArray<integer>): boolean;
    class function StringArraysEqual(expectedArray, testArray: TArray<string>): boolean;
    class function PrintPairlist: string;
  end;

implementation

const
  epsilon = 0.000000000000005;

{ TAbstractTestHelper }

//------------------------------------------------------------------------------
//-- Following code derived from CheckException in Spring.TestUtils.pas
procedure TAbstractTestHelper.CheckException(expected: ExceptionClass;
  method: TProc; const expectedMsg: string; const msg: string);
begin
  FCheckCalled := True;
  try
    method;
  except
    on E: Exception do
    begin
      if not Assigned(expected) then
        raise
      else if not E.InheritsFrom(expected) then
        FailNotEquals(expected.ClassName, E.ClassName, msg, ReturnAddress)
      else
        expected := nil;

      // -- opaR-specific code.
      if expectedMsg <> '' then
        CheckEquals(E.Message, expectedMsg);
    end;
  end;

  if Assigned(expected) then
    FailNotEquals(expected.ClassName, 'nothing', msg, ReturnAddress);
end;


{ TopaRArrayChecks }

//------------------------------------------------------------------------------
class function TopaRArrayUtils.DoubleArraysEqual(expectedArray,
  testArray: TArray<double>): boolean;
var
  i: integer;
begin
  if Length(expectedArray) <> Length(testArray) then
    Exit(false);

  result := true;
  for i := 0 to Length(expectedArray) - 1 do
    if not SameValue(expectedArray[i], testArray[i], epsilon) then Exit(false);
end;
//------------------------------------------------------------------------------
class function TopaRArrayUtils.GenerateDoubleArray(low,
  high: integer): TArray<double>;
var
  i: integer;
begin
  SetLength(result, high - low + 1);
  for i := 0 to high - low do
    result[i] := i + low;
end;
//------------------------------------------------------------------------------
class function TopaRArrayUtils.GenerateIntArray(low,
  high: integer): TArray<integer>;
var
  i: integer;
begin
  SetLength(result, high - low + 1);
  for i := 0 to high - low do
    result[i] := i + low;
end;
//------------------------------------------------------------------------------
class function TopaRArrayUtils.IntArraysEqual(expectedArray,
  testArray: TArray<integer>): boolean;
var
  i: integer;
begin
  if Length(expectedArray) <> Length(testArray) then
    Exit(false);

  result := true;
  for i := 0 to Length(expectedArray) - 1 do
    if not expectedArray[i] = testArray[i] then Exit(false);
end;
//------------------------------------------------------------------------------
class function TopaRArrayUtils.PrintPairlist: string;
var
  defPrintPairlist: TStringList;
begin
  defPrintPairlist := TStringList.Create;
  defPrintPairlist.Add('printPairList <- function(...) {');
  defPrintPairlist.Add('a <- list(...)');
  defPrintPairlist.Add('namez <- names(a)');
  defPrintPairlist.Add('r <- ' + QuotedStr(''));
  defPrintPairlist.Add('if(length(a)==0) return(' + QuotedStr('empty pairlist') + ')');
  defPrintPairlist.Add('for(i in 1:length(a)) {');
  defPrintPairlist.Add('name <- namez[i]');
  defPrintPairlist.Add('r <- paste(r, paste0(name, ' + QuotedStr('=') + ', a[[i]], sep=' + QuotedStr(';') +'))');
  defPrintPairlist.Add('}');
  defPrintPairlist.Add('substring(r, 1, (nchar(r)-1))');
  defPrintPairlist.Add('}');

  try
    result := defPrintPairlist.Text;
  finally
    defPrintPairlist.Free;
  end;
end;
//------------------------------------------------------------------------------
class function TopaRArrayUtils.StringArraysEqual(expectedArray,
  testArray: TArray<string>): boolean;
var
  i: integer;
begin
  if Length(expectedArray) <> Length(testArray) then
    Exit(false);

  result := true;
  for i := 0 to Length(expectedArray) - 1 do
    if expectedArray[i] <> testArray[i] then Exit(false);
end;

end.
