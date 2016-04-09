unit opaR.EngineExtension;

{-------------------------------------------------------------------------------

opaR: object pascal for R

Copyright (C) 2015-2016 Sigma Sciences Ltd.

Originator: Robert L S Devine

Unless you have received this program directly from Sigma Sciences Ltd under
the terms of a commercial license agreement, then this program is licensed
to you under the terms of version 3 of the GNU Affero General Public License.
Please refer to the AGPL licence document at:
http://www.gnu.org/licenses/agpl-3.0.txt for more details.

This program is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
THOSE OF NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

-------------------------------------------------------------------------------}

{-------------------------------------------------------------------------------

Uses the approach described here:
http://delphisorcery.blogspot.co.uk/2013/04/why-no-extension-methods-in-delphi.html

Use the Spring4D collections since this allows us to match as closely as possible
to the code used in R.NET, e.g. with IEnumerable<T> members such as LastOrDefault.

Note that methods returning an interface have been implemented in the base
REngine class (e.g. CreateNumericVector). This code is used to implement
various utility methods.

-------------------------------------------------------------------------------}

{ TODO : "yield return" when implemented in Spring4D. }

interface

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.Types,
  System.RegularExpressions,

  {$IFNDEF NO_SPRING}
  Spring.Collections,
  Spring.Collections.Lists,
  {$ELSE}
  OpaR.NoSpring,
  {$ENDIF}

  opaR.SEXPREC,
  opaR.Utils,
  opaR.Exception,
  opaR.DLLFunctions,
  opaR.ProtectedPointer,
  opaR.SymbolicExpression,
  opaR.Interfaces,
  opaR.Environment;

type
  TEngineExtension = record
  private
    FEngine: IREngine;
    FGlobalEnvironment: IREnvironment;
    function Defer(statement: string): IList<ISymbolicExpression>;
    function EvenStringDelimiters(statement: string; whereHash: TArray<Integer>): integer;
    function GetAnsiString(symbolName: string): AnsiString;
    function IndexOfAll(sourceString, matchString: string): TArray<Integer>;
    function IsClosedString(s: string): boolean;
    function Parse(statement: string; incompleteStatement: TStringBuilder): ISymbolicExpression;
    function ProcessInputString(input: string): TArray<string>;
    function ProcessLine(line: string): TArray<string>;
    function Segment(line: string): IList<string>;
    function SplitOnFirst(statement: string; out rest: string; sep: char): string;
    function SplitOnNewLines(input: string): TArray<string>;
  public
    function CheckUnbound(p: PSEXPREC): boolean;
    function Evaluate(statement: string): ISymbolicExpression;
    function GetPredefinedSymbol(symbolName: string): TSymbolicExpression;
    function GetPredefinedSymbolPtr(symbolName: string): PSEXPREC;
    function GlobalEnvironment: IREnvironment;
    function LastErrorMessage: string;
    function NilValue: PSEXPREC;
    function NilValueExpression: ISymbolicExpression;
    function NAStringPointer: PSEXPREC;
    class operator Implicit(const value: IREngine): TEngineExtension;
  end;

implementation

uses
  opaR.CharacterVector,
  opaR.ExpressionVector,
  opaR.Expression;


{ TEngineExtension }

//------------------------------------------------------------------------------
function TEngineExtension.CheckUnbound(p: PSEXPREC): boolean;
var
  pUnbound: PSEXPREC;
begin
  pUnbound := GetPredefinedSymbolPtr('R_UnboundValue');
  result := pUnbound = p;
end;
//------------------------------------------------------------------------------
function TEngineExtension.Defer(statement: string): IList<ISymbolicExpression>;
var
  i: integer;
  lines: TStringList;
  line: string;
  incompleteStatement: TStringBuilder;
  segmented: IList<string>;
  s: string;
  expr: ISymbolicExpression;
begin
  if statement = '' then
    raise EopaRException.Create('Error: Empty statement in Defer');

  // -- We don't have the .NET "yield return" construct in Delphi so we
  // -- need to create and populate a list (although see future DSharp/Spring4D).
  result := TCollections.CreateList<ISymbolicExpression>;

  lines := TStringList.Create;
  incompleteStatement := TStringBuilder.Create;
  try
    lines.Text := statement;
    for i := 0 to lines.Count - 1 do
    begin
      line := lines.Strings[i];
      segmented := Segment(line);
      for s in segmented do
      begin
        expr := Parse(s, incompleteStatement);
        if expr <> nil then
          result.Add(expr);
      end;
    end;
  finally
    lines.Free;
    incompleteStatement.Free;
  end;
end;
//------------------------------------------------------------------------------
function TEngineExtension.Evaluate(statement: string): ISymbolicExpression;
begin
  result := Defer(statement).LastOrDefault;
end;
//------------------------------------------------------------------------------
function TEngineExtension.EvenStringDelimiters(statement: string;
  whereHash: TArray<Integer>): integer;
var
  i: integer;
  subString: string;
begin
  result := -1;
  for i := 1 to Length(whereHash) do
  begin
    subString := Copy(statement, 1, whereHash[i]);
    if IsClosedString(subString) then
    begin
      result := whereHash[i];
      break;
    end;
  end;
end;
//------------------------------------------------------------------------------
function TEngineExtension.GetAnsiString(symbolName: string): AnsiString;
var
  ptr: pointer;
begin
  //ptr := GetProcAddress(FEngine.Handle, PAnsiChar(AnsiString(symbolName)));
  ptr := FEngine.Rapi.GetRProcAddress(PAnsiChar(AnsiString(symbolName)));
  result := AnsiString(PAnsiChar(ptr));
end;
//------------------------------------------------------------------------------
function TEngineExtension.LastErrorMessage: string;
var
  statement: string;
  status: TParseStatus;
  p1: PSEXPREC;
  p2: PSEXPREC;
  vector: IExpressionVector;
  expr: ISymbolicExpression;
  charVec: ICharacterVector;
  msgs: TArray<string>;
  errMessage: IExpression;
begin
  //if errMessage = nil then
  //begin
    statement := 'geterrmessage()' + #10;

    p1 := FEngine.Rapi.MakeString(PAnsiChar(AnsiString(statement)));
    p2 := FEngine.Rapi.ParseVector(p1, -1, status, NilValue);  // -- Note -1 for max number of expressions to parse.

    vector := TExpressionVector.Create(FEngine, p2);

    if status <> TParseStatus.OK then
      raise EopaRParseException.Create(status, statement, '');
    if vector.VectorLength = 0 then
      raise EopaRParseException.Create(status, statement, 'Failed to create expression vector in GetLastErrorMessage');

    errMessage := vector.First;

    if errMessage.TryEvaluate(GlobalEnvironment, expr) then
    begin
      charVec := (expr as TSymbolicExpression).AsCharacter;

      msgs := charVec.ToArray;
      //msgs := expr.AsCharacter.ToArray;
      if Length(msgs) > 1 then
        raise EopaRException.Create('Unexpected multiple error messages returned');
      if Length(msgs)  = 0 then
        raise EopaRException.Create('No error messages returned (zero length)');
      result := msgs[0];
    end
    else
      raise EopaRException.Create('Unable to retrieve an R error message. Evaluating "geterrmessage()" fails. The R engine is not in a working state.');
  //end;
end;
//------------------------------------------------------------------------------
function TEngineExtension.GlobalEnvironment: IREnvironment;
var
  p: PSEXPREC;
begin
  if FGlobalEnvironment = nil then
  begin
    p := GetPredefinedSymbolPtr('R_GlobalEnv');
    FGlobalEnvironment := TREnvironment.Create(FEngine, p);
  end;

  result := FGlobalEnvironment;
end;
//------------------------------------------------------------------------------
function TEngineExtension.GetPredefinedSymbol(
  symbolName: string): TSymbolicExpression;
var
  p: PSEXPREC;
begin
  p := GetPredefinedSymbolPtr(symbolName);
  result := TSymbolicExpression.Create(FEngine, p);
end;
//------------------------------------------------------------------------------
function TEngineExtension.GetPredefinedSymbolPtr(symbolName: string): PSEXPREC;
var
  ptr: Pointer;
begin
  ptr := FEngine.Rapi.GetRProcAddress(PAnsiChar(AnsiString(symbolName)));
  result := PSEXPREC(PPointer(ptr)^);
end;
//------------------------------------------------------------------------------
class operator TEngineExtension.Implicit(
  const value: IREngine{HMODULE}): TEngineExtension;
begin
  result.FEngine := value;
end;
//------------------------------------------------------------------------------
function TEngineExtension.IndexOfAll(sourceString,
  matchString: string): TArray<Integer>;
var
  i: integer;
  //match: TMatch;
  matches: TMatchCollection;
begin
  matchString := TRegex.Escape(matchString);
  matches := TRegex.Matches(sourceString, matchString);
  SetLength(result, matches.Count);

  // -- Convert the collection of matches into an array.
  for i := 0 to matches.Count - 1 do
    result[i] := matches[i].Index;
  // -- The Linq-based approach used in R.NET is as follows.
  // -- (from match in TRegex.Matches(sourceString, matchString) select match.Index);
end;
//------------------------------------------------------------------------------
function TEngineExtension.IsClosedString(s: string): boolean;
var
  i: integer;
  inSingleQuote: boolean;
  inDoubleQuotes: boolean;
begin
  inSingleQuote := false;
  inDoubleQuotes := false;

  for i := 1 to Length(s) do
  begin
    if s[i] = '''' then    // -- Test for single quote.
    begin
      if i > 1 then
        if s[i - 1] = '\' then
          continue;
      if (inDoubleQuotes) then
        continue;
      inSingleQuote := not inSingleQuote;
    end;

    if s[i] = '"' then     // -- Test for double quote.
    begin
      if i > 1 then
        if s[i - 1] = '\' then
          continue;
      if (inSingleQuote) then
        continue;
      inDoubleQuotes := not inDoubleQuotes;
    end;
  end;

  result := (not inSingleQuote) and (not inDoubleQuotes);
end;
//------------------------------------------------------------------------------
function TEngineExtension.NAStringPointer: PSEXPREC;
begin
  result := GetPredefinedSymbolPtr('R_NaString');
end;
//------------------------------------------------------------------------------
function TEngineExtension.NilValue: PSEXPREC;
begin
  result := GetPredefinedSymbolPtr('R_NilValue');
end;
//------------------------------------------------------------------------------
function TEngineExtension.NilValueExpression: ISymbolicExpression;
begin
  result := TSymbolicExpression.Create(FEngine, NilValue);
end;
//------------------------------------------------------------------------------
function TEngineExtension.Parse(statement: string;
  incompleteStatement: TStringBuilder): ISymbolicExpression;
var
  p1: PSEXPREC;
  p2: PSEXPREC;
  pp: TProtectedPointer;
  pp2: TProtectedPointer;
  status: TParseStatus;
  errorStatement: string;
  vector: IExpressionVector;
  parseErrorMsg: AnsiString;

  ge: IREnvironment;
  vec: IExpression;
begin
  incompleteStatement.Append(statement);

  p1 := FEngine.Rapi.MakeString(PAnsiChar(AnsiString(incompleteStatement.ToString)));

  pp := TProtectedPointer.Create(FEngine, p1);
  try
    p2 := FEngine.Rapi.ParseVector(p1, -1, status, NilValue);    // -- Note -1 for max number of expressions to parse.

    case status of
      TParseStatus.OK: begin
        incompleteStatement.Clear;

        vector := TExpressionVector.Create(FEngine, p2);

        pp2 := TProtectedPointer.Create(vector as ISymbolicExpression);
        try
          if vector.VectorLength = 0 then
            result := nil;

          ge := GlobalEnvironment;
          vec := vector.First;

          if not vec.TryEvaluate(ge, result) then
            raise EopaREvaluationException.Create(LastErrorMessage);

          if (FEngine.AutoPrint) and (not result.IsInvalid) and (FEngine.GetVisible) then
            FEngine.Rapi.PrintValue(result.Handle);
        finally
          pp2.Free;
        end;
      end;

      TParseStatus.Incomplete: result := nil;

      TParseStatus.Error: begin
        parseErrorMsg := GetAnsiString('R_ParseErrorMsg');
        errorStatement := incompleteStatement.ToString;
        incompleteStatement.Clear;
        raise EopaRParseException.Create(status, errorStatement, String(parseErrorMsg));
      end;

      else
      begin
        errorStatement := incompleteStatement.ToString;
        incompleteStatement.Clear;
        raise EopaRParseException.Create(status, errorStatement, '');
      end;
    end;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
function TEngineExtension.ProcessInputString(input: string): TArray<string>;
var
  i: integer;
  lines: TArray<string>;
  statements: IList<string>;
begin
  lines := SplitOnNewLines(input);
  statements := TCollections.CreateList<string>;

  for i := 0 to Length(lines) - 1 do
    statements.AddRange(ProcessLine(lines[i]));
  result := statements.ToArray;
end;
//------------------------------------------------------------------------------
function TEngineExtension.ProcessLine(line: string): TArray<string>;
var
  trimmedLine: string;
  theRest: string;
  statement: string;
  subString: string;
  list: IList<string>;
  whereHash: TArray<Integer>;
  firstComment: integer;
  restFirstStatement: string;
  beforeComment: string;
begin
  trimmedLine := Trim(line);

  if trimmedLine = '' then
    exit;

  if trimmedLine[1] = '#' then
  begin
    Setlength(result, 1);
    result[0] := line;
    exit;
  end;

  statement := SplitOnFirst(line, theRest, ';');

  list := TCollections.CreateList<string>;
  if Pos('#', statement) = 0 then
  begin
    list.Add(statement);
    list.AddRange(ProcessLine(theRest));
  end
  else
  begin
    whereHash := IndexOfAll(statement, '#');
    firstComment := EvenStringDelimiters(statement, whereHash);
    if firstComment < 1 then
    begin
      list.Add(statement);
      list.AddRange(processLine(theRest));
    end
    else
    begin
      subString := Copy(statement, 1, firstComment);
      list.Add(subString);
    end;

    { TODO : TREngine.ProcessLine -> beforeComment - necessary? }
    beforeComment := splitOnFirst(statement, restFirstStatement, '#');
  end;

  result := list.ToArray;
end;
//------------------------------------------------------------------------------
function TEngineExtension.Segment(line: string): IList<string>;
var
  i: integer;
  segments: TArray<string>;
  rtn: IList<string>;
begin
  segments := ProcessInputString(line);
  rtn := TCollections.CreateList<string>;

  for i := 0 to Length(segments) - 1 do
  begin
    if i = (Length(segments) - 1) then
    begin
      if segments[i] <> '' then
        rtn.Add(segments[i] + #10);
    end
    else
      rtn.Add(segments[i] + ';');
  end;

  result := rtn;
end;
//------------------------------------------------------------------------------
function TEngineExtension.SplitOnFirst(statement: string; out rest: string;
  sep: char): string;
var
  split: TStringDynArray;
begin
  split := SplitString(statement, sep);
  if Length(split) = 1 then
    rest := ''
  else
    rest := split[1];
  result := split[0];
end;
//------------------------------------------------------------------------------
function TEngineExtension.SplitOnNewLines(input: string): TArray<string>;
begin
  input := StringReplace(input, #13#10, #10, []);
  result := TArray<string>(SplitString(input, #10));
end;

end.
