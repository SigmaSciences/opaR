unit opaR.DLLFunctions;

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

interface

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.SysUtils,

  opaR.SEXPREC,
  opaR.Utils,
  opaR.Internals.Windows.RStart;

type
  // -- getDLLVersion
  TRFnDLLVersion = function: PAnsiChar; cdecl;
  // -- Rf_initialize_R (This should return 0).
  TRFnInitialize = function(ac: integer; av: PPAnsiCharArray): integer; cdecl;
  // -- Rf_initEmbeddedR (always returns 1 - see embeddedR.c in R sources).
  TRFnInitializeEmbedded = function(ac: integer; av: PPAnsiCharArray): integer; cdecl;
  // -- R_DefParams
  TRFnDefParams = procedure(var start: TRStart); cdecl;
  // -- R_SetParams
  TRFnSetParams = procedure(var start: TRStart); cdecl;
  // -- R_ReplDLLinit
  TRFnReplDLLinit = procedure; cdecl;


  // -- Rf_NewEnvironment
  TRFnNewEnvironment = function(pExp1, pExp2, parentEnv: PSEXPREC): PSEXPREC; cdecl;
  // -- R_lsInternal
  TRFnlsInternal = function(p: PSEXPREC; getAll: LongBool): PSEXPREC; cdecl;
  // -- setup_Rmainloop
  TRfnSetupMainLoop = procedure; cdecl;

  TRFnGetRUser = function: PAnsiChar; cdecl;
  // -- R_setStartTime
  TRfnSetStartTime = procedure; cdecl;

  // -- Rf_install looks up a symbol in the symbol table, installs it if required,
  // -- and returns the symbol SEXP. (The symbol doesn't need to be protected?)
  TRFnInstall = function(const s: PAnsiChar): PSEXPREC; cdecl;
  // -- Rf_getAttrib
  TRFnGetAttrib = function(sexp, s: PSEXPREC): PSEXPREC; cdecl;
  // -- Rf_setAttrib
  TRFnSetAttrib = procedure(sexp, s, handle: PSEXPREC); cdecl;
  // -- Rf_findVar
  TRFnFindVar = function(symbol, handle: PSEXPREC): PSEXPREC; cdecl;

  // -- Rf_protect
  TRFnProtect = function(sexp: PSEXPREC): PSEXPREC; cdecl;
  // -- Rf_unprotect_ptr
  TRFnUnprotectPtr = procedure(sexp: PSEXPREC); cdecl;
  // -- R_PreserveObject
  TRFnPreserveObject = procedure(sexp: PSEXPREC); cdecl;
  // -- R_ReleaseObject
  TRFnReleaseObject = procedure(sexp: PSEXPREC); cdecl;

  // -- R_ParseVector returns a pointer to a TExpressionVector (SEXP).
  TRFnParseVector = function(statement: PSEXPREC; statementCount: integer; var status: TParseStatus; p: PSEXPREC): PSEXPREC; cdecl;

  TRFnVectorElt = function(aVector: PSEXPREC; const aIndex: integer): PSEXPREC; cdecl;
  TRFnSetVectorElt = function(aVector: PSEXPREC; const aIndex: integer; aValue: PSEXPREC): PSEXPREC; cdecl;

  TRFnStringElt = function(aVector: PSEXPREC; const aIndex: integer): PSEXPREC; cdecl;
  TRFnSetStringElt = procedure(aVector: PSEXPREC; const aIndex: integer; aValue: PSEXPREC); cdecl;
  TRFnChar = function(aStringExpRec: PSEXPREC): PAnsiChar; cdecl;

  TRFnRealVector = function(aVector: PSEXPREC): PDouble; cdecl;
  TRFnLogicalVector = function(aVector: PSEXPREC): PLongBool; cdecl;
  TRFnIntegerVector = function(aVector: PSEXPREC): PInteger; cdecl;
  TRFnRawVector = function(aVector: PSEXPREC): PByte; cdecl;

  // -- Rf_mkString creates a string SEXP (vector of R class "character" containing a single string)
  TRFnMakeString = function(const s: PAnsiChar): PSEXPREC; cdecl;
  // -- Rf_mkChar
  TRFnMakeChar = function(const s: PAnsiChar): PSEXPREC; cdecl;

  // -- Rf_allocVector
  TRfnAllocVector = function(const exprType: TSymbolicExpressionType; length: integer): PSEXPREC; cdecl;
  // -- Rf_length
  TRFnLength = function(sexp: PSEXPREC): integer; cdecl;
  // -- Rf_VectorToPairList
  TRFnVectorToPairList = function(p: PSEXPREC): PSEXPREC; cdecl;
  // -- Rf_allocMatrix
  TRfnAllocMatrix = function(const exprType: TSymbolicExpressionType; rowCount, columnCount: integer): PSEXPREC; cdecl;
  // -- Rf_nrows
  TRFnNumRows = function(sexp: PSEXPREC): integer; cdecl;
  // -- Rf_ncols
  TRFnNumCols = function(sexp: PSEXPREC): integer; cdecl;

  // -- Rf_eval
  TRFnEval = function(h1, h2: PSEXPREC): PSEXPREC; cdecl;
  // -- R_tryEval
  TRFnTryEval = function(h1, h2: PSEXPREC; var errorOccurred: LongBool): PSEXPREC; cdecl;
  // -- Rf_defineVar
  TRFnDefineVar = procedure(s1, s2, handle: PSEXPREC); cdecl;

  // -- Rf_isEnvironment
  TRFnIsEnvironment = function(p: PSEXPREC): LongBool; cdecl;
  // -- Rf_isExpression
  TRFnIsExpression = function(p: PSEXPREC): LongBool; cdecl;
  // -- Rf_isFactor
  TRFnIsFactor = function(p: PSEXPREC): LongBool; cdecl;
  // -- Rf_isFrame
  TRFnIsFrame = function(p: PSEXPREC): LongBool; cdecl;
  // -- Rf_isFunction
  TRFnIsFunction = function(p: PSEXPREC): LongBool; cdecl;
  // -- Rf_isLanguage
  TRFnIsLanguage = function(p: PSEXPREC): LongBool; cdecl;
  // -- Rf_isMatrix
  TRFnIsMatrix = function(p: PSEXPREC): LongBool; cdecl;
  // -- Rf_isS4
  TRFnIsS4 = function(p: PSEXPREC): LongBool; cdecl;
  // -- Rf_isSymbol
  TRFnIsSymbol = function(p: PSEXPREC): LongBool; cdecl;
  // -- Rf_isVector
  TRFnIsVector = function(p: PSEXPREC): LongBool; cdecl;

  // -- The above can be consolidated into a single function, although it
  // -- requires a PAnsiChar(AnsiString(typeName)) cast in the main function.
  TRFnTypeConfirm = function(p: PSEXPREC): LongBool; cdecl;

  // -- Rf_asCharacterFactor
  TRFnAsCharacterFactor = function(p: PSEXPREC): PSEXPREC; cdecl;
  // -- Rf_coerceVector
  TRFnCoerceVector = function(p: PSEXPREC; const exprType: TSymbolicExpressionType): PSEXPREC; cdecl;

  // -- Rf_cons
  TRFnCons = function(h1, h2: PSEXPREC): PSEXPREC; cdecl;
  // -- Rf_lcons
  TRFnLCons = function(h1, h2: PSEXPREC): PSEXPREC; cdecl;
  // -- SET_TAG
  TRFnSetTag = procedure(expr, tag: PSEXPREC); cdecl;

  // -- Rf_isOrdered
  TRFnIsOrdered = function(p: PSEXPREC): LongBool; cdecl;

  // -- R_do_slot
  TRFnDoSlot = function(h, p: PSEXPREC): PSEXPREC; cdecl;
  // -- R_do_slot_assign
  TRFnDoSlotAssign = procedure(h1, p, h2: PSEXPREC); cdecl;
  // -- R_has_slot
  TRFnHasSlot = function(h, p: PSEXPREC): LongBool; cdecl;
  // -- R_getClassDef
  TRFnGetClassDef = function(const s: PAnsiChar): PSEXPREC; cdecl;

  // -- R_RunExitFinalizers
  TRfnRunExitFinalizers = procedure; cdecl;
  // -- Rf_CleanEd
  TRfnCleanEd = procedure; cdecl;
  // -- R_CleanTempDir
  TRfnCleanTempDir = procedure; cdecl;

  TRfnCAR = function(const aNodeHandle: PSEXPREC): PSEXPREC; cdecl;
  TRfnCDR = function(const aNodeHandle: PSEXPREC): PSEXPREC; cdecl;
  TRfnTAG = function(const aNodeHandle: PSEXPREC): PSEXPREC; cdecl;

  TRfnPrintName = function(const aSymbolHandle: PSEXPREC): PSEXPREC; cdecl;
  TRfnSetPrintName = procedure(const aHandle, aNameHandle: PSEXPREC); cdecl;

  TRfnATTRIB = function(const aHandle: PSEXPREC): PSEXPREC; cdecl;
  TRfnTypeOf = function(const aHandle: PSEXPREC): integer; cdecl;
  TRfnENCLOS = function(const aHandle: PSEXPREC): PSEXPREC; cdecl;
  TRfnInternal = function(const aHandle: PSEXPREC): PSEXPREC; cdecl;
  TRfnSYMVALUE = function(const aHandle: PSEXPREC): PSEXPREC; cdecl;
  TRfnFORMALS = function(const aHandle: PSEXPREC): PSEXPREC; cdecl;
  TRfnBODY = function(const aHandle: PSEXPREC): PSEXPREC; cdecl;
  TRfnCLOENV = function(const aHandle: PSEXPREC): PSEXPREC; cdecl;
  
  // -- The following are useful for debugging. Also see R_inspect and R_inspect3.
  // -- Rf_PrintValue
  TRFnPrintValue = procedure(p: PSEXPREC); cdecl;
  // -- R_PV
  TRFnPV = procedure(p: PSEXPREC); cdecl;

  // -- Use class vars -> all instances get same values since we can only have one R instance.
  TRapi = record
  private
    class var FAllocMatrix: TRfnAllocMatrix;
    class var FAllocVector: TRfnAllocVector;
    class var FAsCharacterFactor: TRFnAsCharacterFactor;
    class var FGetClassDef: TRFnGetClassDef;
    class var FCleanEd: TRfnCleanEd;
    class var FCleanTempDir: TRfnCleanTempDir;
    class var FCoerceVector: TRFnCoerceVector;
    class var FCons: TRFnCons;
    class var FDefineVar: TRFnDefineVar;
    class var FDoSlot: TRFnDoSlot;
    class var FdllHandle: HMODULE;
    class var FDLLVersion: TRFnDLLVersion;
    class var FDoSlotAssign: TRFnDoSlotAssign;
    class var FEval: TRFnEval;
    class var FFindVar: TRFnFindVar;
    class var FGetAttrib: TRFnGetAttrib;
    class var FHasSlot: TRFnHasSlot;
    class var FInstall: TRFnInstall;
    class var FIsEnvironment: TRFnIsEnvironment;
    class var FIsExpression: TRFnIsExpression;
    class var FIsFactor: TRFnIsFactor;
    class var FIsFrame: TRFnIsFrame;
    class var FIsFunction: TRFnIsFunction;
    class var FIsLanguage: TRFnIsLanguage;
    class var FIsMatrix: TRFnIsMatrix;
    class var FIsOrdered: TRFnIsOrdered;
    class var FIsS4: TRFnIsS4;
    class var FIsSymbol: TRFnIsSymbol;
    class var FIsVector: TRFnIsVector;
    class var FlsInternal: TRFnlsInternal;
    class var FLCons: TRFnLCons;
    class var FLength: TRFnLength;
    class var FMakeChar: TRFnMakeChar;
    class var FMakeString: TRFnMakeString;
    class var FNumCols: TRFnNumCols;
    class var FNumRows: TRFnNumRows;
    class var FNewEnvironment: TRFnNewEnvironment;
    class var FParseVector: TRFnParseVector;
    class var FVectorElt: TRFnVectorElt;
    class var FSetVectorElt: TRFnSetVectorElt;
    class var FPreserveObject: TRFnPreserveObject;
    class var FPrintValue: TRFnPrintValue;
    class var FProtect: TRFnProtect;
    class var FReleaseObject: TRFnReleaseObject;
    class var FRunExitFinalizers: TRfnRunExitFinalizers;
    class var FSetStartTime: TRfnSetStartTime;
    class var FSetParams: TRFnSetParams;
    class var FTryEval: TRFnTryEval;
    class var FInitializeR: TRFnInitialize;
    class var FSetAttrib: TRFnSetAttrib;
    class var FSetupMainLoop: TRfnSetupMainLoop;
    class var FSetTag: TRFnSetTag;
    class var FUnprotect: TRFnUnprotectPtr;
    class var FRawVector: TRFnRawVector;
    class var FIntegerVector: TRFnIntegerVector;
    class var FLogicalVector: TRFnLogicalVector;
    class var FRealVector: TRFnRealVector;
    class var FVectorToPairList: TRFnVectorToPairList;
    class var FStringElt: TRFnStringElt;
    class var FChar: TRFnChar;
    class var FSetStringElt: TRFnSetStringElt;
    class var FCAR_LinkedList: TRfnCAR;
    class var FCDR_LinkedList: TRfnCDR;
    class var FTAG_LinkedList: TRfnTAG;
    class var FPrintName: TRfnPrintName;
    class var FATTRIB: TRfnATTRIB;
    class var FTypeOf: TRfnTypeOf;
    class var FEnClos: TRfnENCLOS;
    class var FINTERNAL: TRfnInternal;
    class var FSYMVALUE: TRfnSYMVALUE;
    class var FSetPrintName: TRfnSetPrintName;
    class var FFORMALS: TRfnFORMALS;
    class var FBODY: TRfnBODY;
    class var FCLOENV: TRfnCLOENV;
  public
    constructor Create(dllHandle: HMODULE);
    class function AllocMatrix(const exprType: TSymbolicExpressionType; rowCount, columnCount: integer): PSEXPREC; static;
    class function AllocVector(const exprType: TSymbolicExpressionType; length: integer): PSEXPREC; static;
    class function AsCharacterFactor(p: PSEXPREC): PSEXPREC; static;
    class function Char(aStringExpRec: PSEXPREC): PAnsiChar; static;
    class function CoerceVector(p: PSEXPREC; const exprType: TSymbolicExpressionType): PSEXPREC; static;
    class function Cons(h1, h2: PSEXPREC): PSEXPREC; static;
    class function DLLVersion: PAnsiChar; static;
    class function DoSlot(h, p: PSEXPREC): PSEXPREC; static;
    class function Eval(h1, h2: PSEXPREC): PSEXPREC; static;
    class function FindVar(symbol, handle: PSEXPREC): PSEXPREC; static;
    class function GetAttrib(sexp, s: PSEXPREC): PSEXPREC; static;
    class function GetClassDef(const s: PAnsiChar): PSEXPREC; static;
    class function GetRProcAddress(procName: PAnsiChar): Pointer; static;
    class function HasSlot(h, p: PSEXPREC): LongBool; static;
    class function InitializeR(ac: integer; av: PPAnsiCharArray): integer; static;
    class function IsEnvironment(p: PSEXPREC): LongBool; static;
    class function IsExpression(p: PSEXPREC): LongBool; static;
    class function IsFactor(p: PSEXPREC): LongBool; static;
    class function IsFrame(p: PSEXPREC): LongBool; static;
    class function IsFunction(p: PSEXPREC): LongBool; static;
    class function IsLanguage(p: PSEXPREC): LongBool; static;
    class function IsMatrix(p: PSEXPREC): LongBool; static;
    class function Install(const s: PAnsiChar): PSEXPREC; static;
    class function IsOrdered(p: PSEXPREC): LongBool; static;
    class function IsS4(p: PSEXPREC): LongBool; static;
    class function IsSymbol(p: PSEXPREC): LongBool; static;
    class function IsVector(p: PSEXPREC): LongBool; static;
    class function Length(sexp: PSEXPREC): integer; static;
    class function LCons(h1, h2: PSEXPREC): PSEXPREC; static;
    class function lsInternal(p: PSEXPREC; getAll: LongBool): PSEXPREC; static;
    class function MakeChar(const s: PAnsiChar): PSEXPREC; static;
    class function MakeString(const s: PAnsiChar): PSEXPREC; static;
    class function NewEnvironment(pExp1, pExp2, parentEnv: PSEXPREC): PSEXPREC; static;
    class function NumCols(p: PSEXPREC): integer; static;
    class function NumRows(p: PSEXPREC): integer; static;
    class function ParseVector(statement: PSEXPREC; statementCount: integer; var status: TParseStatus; p: PSEXPREC): PSEXPREC; static;
    class function VectorElt(aVector: PSEXPREC; const aVecvtorIndex: integer):
        PSEXPREC; static;
    class function SetVectorElt(aVector: PSEXPREC; const aVecvtorIndex: integer;
        aValue: PSEXPREC): PSEXPREC; static;
    class function Protect(p: PSEXPREC): PSEXPREC; static;
    class function TryEval(h1, h2: PSEXPREC; var errorOccurred: LongBool): PSEXPREC; static;
    class function VectorToPairList(p: PSEXPREC): PSEXPREC; static;
    class procedure CleanEd; static;
    class procedure CleanTempDir; static;
    class procedure DefineVar(s1, s2, handle: PSEXPREC); static;
    class procedure DoSlotAssign(h1, p, h2: PSEXPREC); static;
    class function IntegerVector(aVector: PSEXPREC): PInteger; static;
    class function LogicalVector(aVector: PSEXPREC): PLongBool; static;
    class procedure PreserveObject(p: PSEXPREC); static;
    class procedure PrintValue(p: PSEXPREC); static;
    class function RawVector(aVector: PSEXPREC): PByte; static;
    class function RealVector(aVector: PSEXPREC): PDouble; static;
    class procedure ReleaseObject(sexp: PSEXPREC); static;
    class procedure RunExitFinalizers; static;
    class procedure SetAttrib(sexp, s, handle: PSEXPREC); static;
    class procedure SetParams(var start: TRStart); static;
    class procedure SetStartTime; static;
    class procedure SetStringElt(aVector: PSEXPREC; const aIndex: integer; aValue:
        PSEXPREC); static;
    class procedure SetTag(expr, tag: PSEXPREC); static;
    class procedure SetupMainLoop; static;
    class function StringElt(aVector: PSEXPREC; const aIndex: integer): PSEXPREC;
        static;
    class procedure UnloadDLL; static;
    class procedure Unprotect(p: PSEXPREC); static;
    class function CAR_LinkedList(const aCurrentNode: PSEXPREC): PSEXPREC; static;
    class function CDR_LinkedList(const aCurrentNode: PSEXPREC): PSEXPREC; static;
    class function TAG_LinkedList(const aCurrentNode: PSEXPREC): PSEXPREC; static;
    class function PrintName(const aSymbolHandle: PSEXPREC): PSEXPREC; static;
    class function ATTRIB(const aAttributeHandle: PSEXPREC): PSEXPREC; static;
    class function TypeOf(const aHandle: PSEXPREC): integer; static;
    class function ENCLOS(const aHandle: PSEXPREC): PSEXPREC; static;
    class function INTERNAL(const aHandle: PSEXPREC): PSEXPREC; static;
    class function SYMVALUE(const aHandle: PSEXPREC): PSEXPREC; static;
    class procedure SET_PRINTNAME(const aHandle, aNameHandle: PSEXPREC); static;
    class function FORMALS(const aHandle: PSEXPREC): PSEXPREC; static;
    class function BODY(const aHandle: PSEXPREC): PSEXPREC; static;
    class function CLOENV(const aHandle: PSEXPREC): PSEXPREC; static;
  end;

implementation

{ TRapi }

//------------------------------------------------------------------------------
class function TRapi.AllocMatrix(const exprType: TSymbolicExpressionType;
  rowCount, columnCount: integer): PSEXPREC;
begin
  if @FAllocMatrix = nil then
    FAllocMatrix := GetRProcAddress('Rf_allocMatrix');
  result := FAllocMatrix(exprType, rowCount, columnCount);
end;
//------------------------------------------------------------------------------
class function TRapi.AllocVector(const exprType: TSymbolicExpressionType;
  length: integer): PSEXPREC;
begin
  if @FAllocVector = nil then
    FAllocVector := GetRProcAddress('Rf_allocVector');
  result := FAllocVector(exprType, length);
end;
//------------------------------------------------------------------------------
class function TRapi.AsCharacterFactor(p: PSEXPREC): PSEXPREC;
begin
  if @FAsCharacterFactor = nil then
    FAsCharacterFactor := GetRProcAddress('Rf_asCharacterFactor');
  result := FAsCharacterFactor(p);
end;
//------------------------------------------------------------------------------
class procedure TRapi.CleanEd;
begin
  if @FCleanEd = nil then
    FCleanEd := GetRProcAddress('Rf_CleanEd');
  FCleanEd;
end;
//------------------------------------------------------------------------------
class procedure TRapi.CleanTempDir;
begin
  if @FCleanTempDir = nil then
    FCleanTempDir := GetRProcAddress('R_CleanTempDir');
  FCleanTempDir;
end;
//------------------------------------------------------------------------------
class function TRapi.CoerceVector(p: PSEXPREC;
  const exprType: TSymbolicExpressionType): PSEXPREC;
begin
  if @FCoerceVector = nil then
    FCoerceVector := GetRProcAddress('Rf_coerceVector');
  result := FCoerceVector(p, exprType);
end;
//------------------------------------------------------------------------------
class function TRapi.Cons(h1, h2: PSEXPREC): PSEXPREC;
begin
  if @FCons = nil then
    FCons := GetRProcAddress('Rf_cons');
  result := FCons(h1, h2);
end;
//------------------------------------------------------------------------------
constructor TRapi.Create(dllHandle: HMODULE);
begin
  FdllHandle := dllHandle;
end;

class function TRapi.ATTRIB(const aAttributeHandle: PSEXPREC): PSEXPREC;
begin
  if @FATTRIB = nil then
    FATTRIB := GetRProcAddress('ATTRIB');
  Result := FATTRIB(aAttributeHandle);
end;

class function TRapi.BODY(const aHandle: PSEXPREC): PSEXPREC;
begin
  if @FBODY = nil then
    FBODY := GetRProcAddress('BODY');
  Result := FBODY(aHandle);
end;

class function TRapi.CAR_LinkedList(const aCurrentNode: PSEXPREC): PSEXPREC;
begin
  if @FCAR_LinkedList = nil then
    FCAR_LinkedList := GetRProcAddress('CAR');
  Result := FCAR_LinkedList(aCurrentNode);
end;

class function TRapi.CDR_LinkedList(const aCurrentNode: PSEXPREC): PSEXPREC;
begin
  if @FCDR_LinkedList = nil then
    FCDR_LinkedList := GetRProcAddress('CDR');
  Result := FCDR_LinkedList(aCurrentNode);
end;

class function TRapi.Char(aStringExpRec: PSEXPREC): PAnsiChar;
begin
  if @FChar = nil then
    FChar := GetRProcAddress('R_CHAR');
  Result := FChar(aStringExpRec);
end;

class function TRapi.CLOENV(const aHandle: PSEXPREC): PSEXPREC;
begin
  if @FCLOENV = nil then
    FCLOENV := GetRProcAddress('CLOENV');
  Result := FCLOENV(aHandle);
end;

//------------------------------------------------------------------------------
class procedure TRapi.DefineVar(s1, s2, handle: PSEXPREC);
begin
  if @FDefineVar = nil then
    FDefineVar := GetRProcAddress('Rf_defineVar');
  FDefineVar(s1, s2, handle);
end;
//------------------------------------------------------------------------------
class function TRapi.DLLVersion: PAnsiChar;
begin
  if @FDLLVersion = nil then
    FDLLVersion := GetRProcAddress('getDLLVersion');
  result := FDLLVersion;
end;
//------------------------------------------------------------------------------
class function TRapi.DoSlot(h, p: PSEXPREC): PSEXPREC;
begin
  if @FDoSlot = nil then
    FDoSlot := GetRProcAddress('R_do_slot');
  result := FDoSlot(h, p);
end;
//------------------------------------------------------------------------------
class procedure TRapi.DoSlotAssign(h1, p, h2: PSEXPREC);
begin
  if @FDoSlotAssign = nil then
    FDoSlotAssign := GetRProcAddress('R_do_slot_assign');
  FDoSlotAssign(h1, p, h2);
end;

class function TRapi.ENCLOS(const aHandle: PSEXPREC): PSEXPREC;
begin
  if @FEnClos = nil then
    FEnClos := GetRProcAddress('ENCLOS');
  Result := FEnClos(aHandle);
end;

//------------------------------------------------------------------------------
class function TRapi.Eval(h1, h2: PSEXPREC): PSEXPREC;
begin
  if @FEval = nil then
    FEval := GetRProcAddress('Rf_eval');
  result := FEval(h1, h2);
end;
//------------------------------------------------------------------------------
class function TRapi.FindVar(symbol, handle: PSEXPREC): PSEXPREC;
begin
  if @FFindVar = nil then
    FFindVar := GetRProcAddress('Rf_findVar');
  result := FFindVar(symbol, handle);
end;

class function TRapi.FORMALS(const aHandle: PSEXPREC): PSEXPREC;
begin
  if @FFORMALS = nil then
    FFORMALS := GetRProcAddress('FORMALS');
  Result := FFORMALS(aHandle);
end;

//------------------------------------------------------------------------------
class function TRapi.GetAttrib(sexp, s: PSEXPREC): PSEXPREC;
begin
  if @FGetAttrib = nil then
    FGetAttrib := GetRProcAddress('Rf_getAttrib');
  result := FGetAttrib(sexp, s);
end;
//------------------------------------------------------------------------------
class function TRapi.GetClassDef(const s: PAnsiChar): PSEXPREC;
begin
  if @FGetClassDef = nil then
    FGetClassDef := GetRProcAddress('R_getClassDef');
  result := FGetClassDef(s);
end;
//------------------------------------------------------------------------------
class function TRapi.GetRProcAddress(procName: PAnsiChar): Pointer;
begin
  try
    result := GetProcAddress(FdllHandle, procName);
  except
    on e: Exception do
    begin
      raise EopaRException.Create('Error loading R procedure: ' + e.Message);
      result := nil;
    end;
  end;
end;
//------------------------------------------------------------------------------
class function TRapi.HasSlot(h, p: PSEXPREC): LongBool;
begin
  if @FHasSlot = nil then
    FHasSlot := GetRProcAddress('R_has_slot');
  result := FHasSlot(h, p);
end;
//------------------------------------------------------------------------------
class function TRapi.InitializeR(ac: integer; av: PPAnsiCharArray): integer;
begin
  if @FInitializeR = nil then
    FInitializeR := GetRProcAddress('Rf_initialize_R');
  result := FInitializeR(ac, av);
end;
//------------------------------------------------------------------------------
class function TRapi.Install(const s: PAnsiChar): PSEXPREC;
begin
  if @FInstall = nil then
    FInstall := GetRProcAddress('Rf_install');
  result := FInstall(s);
end;

class function TRapi.IntegerVector(aVector: PSEXPREC): PInteger;
begin
  if @FIntegerVector = nil then
    FIntegerVector := GetRProcAddress('INTEGER');
  result := FIntegerVector(aVector);
end;

class function TRapi.INTERNAL(const aHandle: PSEXPREC): PSEXPREC;
begin
  if @FINTERNAL = nil then
    FINTERNAL := GetRProcAddress('INTERNAL');
  Result := FINTERNAL(aHandle);
end;

//------------------------------------------------------------------------------
class function TRapi.IsEnvironment(p: PSEXPREC): LongBool;
begin
  if @FIsEnvironment = nil then
    FIsEnvironment := GetRProcAddress('Rf_isEnvironment');
  result := FIsEnvironment(p);
end;
//------------------------------------------------------------------------------
class function TRapi.IsExpression(p: PSEXPREC): LongBool;
begin
  if @FIsExpression = nil then
    FIsExpression := GetRProcAddress('Rf_isExpression');
  result := FIsExpression(p);
end;
//------------------------------------------------------------------------------
class function TRapi.IsFactor(p: PSEXPREC): LongBool;
begin
  if @FIsFactor = nil then
    FIsFactor := GetRProcAddress('Rf_isFactor');
  result := FIsFactor(p);
end;
//------------------------------------------------------------------------------
class function TRapi.IsFrame(p: PSEXPREC): LongBool;
begin
  if @FIsFrame = nil then
    FIsFrame := GetRProcAddress('Rf_isFrame');
  result := FIsFrame(p);
end;
//------------------------------------------------------------------------------
class function TRapi.IsFunction(p: PSEXPREC): LongBool;
begin
  if @FIsFunction = nil then
    FIsFunction := GetRProcAddress('Rf_isFunction');
  result := FIsFunction(p);
end;
//------------------------------------------------------------------------------
class function TRapi.IsLanguage(p: PSEXPREC): LongBool;
begin
  if @FIsLanguage = nil then
    FIsLanguage := GetRProcAddress('Rf_isLanguage');
  result := FIsLanguage(p);
end;
//------------------------------------------------------------------------------
class function TRapi.IsMatrix(p: PSEXPREC): LongBool;
begin
  if @FIsMatrix = nil then
    FIsMatrix := GetRProcAddress('Rf_isMatrix');
  result := FIsMatrix(p);
end;
//------------------------------------------------------------------------------
class function TRapi.IsOrdered(p: PSEXPREC): LongBool;
begin
  if @FIsOrdered = nil then
    FIsOrdered := GetRProcAddress('Rf_isOrdered');
  result := FIsOrdered(p);
end;
//------------------------------------------------------------------------------
class function TRapi.IsS4(p: PSEXPREC): LongBool;
begin
  if @FIsS4 = nil then
    FIsS4 := GetRProcAddress('Rf_isS4');
  result := FIsS4(p);
end;
//------------------------------------------------------------------------------
class function TRapi.IsSymbol(p: PSEXPREC): LongBool;
begin
  if @FIsSymbol = nil then
    FIsSymbol := GetRProcAddress('Rf_isSymbol');
  result := FIsSymbol(p);
end;
//------------------------------------------------------------------------------
class function TRapi.IsVector(p: PSEXPREC): LongBool;
begin
  if @FIsVector = nil then
    FIsVector := GetRProcAddress('Rf_isVector');
  result := FIsVector(p);
end;
//------------------------------------------------------------------------------
class function TRapi.LCons(h1, h2: PSEXPREC): PSEXPREC;
begin
  if @FLCons = nil then
    FLCons := GetRProcAddress('Rf_lcons');
  result := FLCons(h1, h2);
end;
//------------------------------------------------------------------------------
class function TRapi.Length(sexp: PSEXPREC): integer;
begin
  if @FLength = nil then
    FLength := GetRProcAddress('Rf_length');
  result := FLength(sexp);
end;

class function TRapi.LogicalVector(aVector: PSEXPREC): PLongBool;
begin
  if @FLogicalVector = nil then
    FLogicalVector := GetRProcAddress('LOGICAL');
  Result := FLogicalVector(aVector);
end;

//------------------------------------------------------------------------------
class function TRapi.lsInternal(p: PSEXPREC; getAll: LongBool): PSEXPREC;
begin
  if @FlsInternal = nil then
    FlsInternal := GetRProcAddress('R_lsInternal');
  result := FlsInternal(p, getAll);
end;
//------------------------------------------------------------------------------
class function TRapi.MakeChar(const s: PAnsiChar): PSEXPREC;
begin
  if @FMakeChar = nil then
    FMakeChar := GetRProcAddress('Rf_mkChar');
  result := FMakeChar(s);
end;
//------------------------------------------------------------------------------
class function TRapi.MakeString(const s: PAnsiChar): PSEXPREC;
begin
  if @FMakeString = nil then
    FMakeString := GetRProcAddress('Rf_mkString');
  result := FMakeString(s);
end;
//------------------------------------------------------------------------------
class function TRapi.NewEnvironment(pExp1, pExp2,
  parentEnv: PSEXPREC): PSEXPREC;
begin
  if @FNewEnvironment = nil then
    FNewEnvironment := GetRProcAddress('Rf_NewEnvironment');
  result := FNewEnvironment(pExp1, pExp2, parentEnv);
end;
//------------------------------------------------------------------------------
class function TRapi.NumCols(p: PSEXPREC): integer;
begin
  if @FNumCols = nil then
    FNumCols := GetRProcAddress('Rf_ncols');
  result := FNumCols(p);
end;
//------------------------------------------------------------------------------
class function TRapi.NumRows(p: PSEXPREC): integer;
begin
  if @FNumRows = nil then
    FNumRows := GetRProcAddress('Rf_nrows');
  result := FNumRows(p);
end;
//------------------------------------------------------------------------------
class function TRapi.ParseVector(statement: PSEXPREC; statementCount: integer;
  var status: TParseStatus; p: PSEXPREC): PSEXPREC;
begin
  if @FParseVector = nil then
    FParseVector := GetRProcAddress('R_ParseVector');
  result := FParseVector(statement, statementCount, status, p);
end;
//------------------------------------------------------------------------------
class procedure TRapi.PreserveObject(p: PSEXPREC);
begin
  if @FPreserveObject = nil then
    FPreserveObject := GetRProcAddress('R_PreserveObject');
  FPreserveObject(p);
end;

class function TRapi.PrintName(const aSymbolHandle: PSEXPREC): PSEXPREC;
begin
  if @FPrintName = nil then
    FPrintName := GetRProcAddress('PRINTNAME');

  Result := FPrintName(aSymbolHandle);
end;

//------------------------------------------------------------------------------
class procedure TRapi.PrintValue(p: PSEXPREC);
begin
  if @FPrintValue = nil then
    FPrintValue := GetRProcAddress('Rf_PrintValue');
  FPrintValue(p);
end;
//------------------------------------------------------------------------------
class function TRapi.Protect(p: PSEXPREC): PSEXPREC;
begin
  if @FProtect = nil then
    FProtect := GetRProcAddress('Rf_protect');
  result := FProtect(p);
end;

class function TRapi.RawVector(aVector: PSEXPREC): PByte;
begin
  if @FRawVector = nil then
    FRawVector := GetRProcAddress('RAW');
  Result := FRawVector(aVector);
end;

class function TRapi.RealVector(aVector: PSEXPREC): PDouble;
begin
  if @FRealVector = nil then
    FRealVector := GetRProcAddress('REAL');
  Result := FRealVector(aVector);
end;

//------------------------------------------------------------------------------
class procedure TRapi.ReleaseObject(sexp: PSEXPREC);
begin
  if @FReleaseObject = nil then
    FReleaseObject := GetRProcAddress('R_ReleaseObject');
  FReleaseObject(sexp);
end;
//------------------------------------------------------------------------------
class procedure TRapi.RunExitFinalizers;
begin
  if @FRunExitFinalizers = nil then
    FRunExitFinalizers := GetRProcAddress('R_RunExitFinalizers');
  FRunExitFinalizers;
end;
//------------------------------------------------------------------------------
class procedure TRapi.SetAttrib(sexp, s, handle: PSEXPREC);
begin
  if @FSetAttrib = nil then
    FSetAttrib := GetRProcAddress('Rf_setAttrib');
  FSetAttrib(sexp, s, handle);
end;
//------------------------------------------------------------------------------
class procedure TRapi.SetParams(var start: TRStart);
begin
  if @FSetParams = nil then
    FSetParams := GetRProcAddress('R_SetParams');
  FSetParams(start);
end;
//------------------------------------------------------------------------------
class procedure TRapi.SetStartTime;
begin
  if @FSetStartTime = nil then
    FSetStartTime := GetRProcAddress('R_setStartTime');
  FSetStartTime;
end;

class procedure TRapi.SetStringElt(aVector: PSEXPREC; const aIndex: integer;
    aValue: PSEXPREC);
begin
  if @FSetStringElt = nil then
    FSetStringElt := GetRProcAddress('SET_STRING_ELT');
  FSetStringElt(aVector, aIndex, aValue);
end;

//------------------------------------------------------------------------------
class procedure TRapi.SetTag(expr, tag: PSEXPREC);
begin
  if @FSetTag = nil then
    FSetTag := GetRProcAddress('SET_TAG');
  FSetTag(expr, tag);
end;
//------------------------------------------------------------------------------
class procedure TRapi.SetupMainLoop;
begin
  if @FSetupMainLoop = nil then
    FSetupMainLoop := GetRProcAddress('setup_Rmainloop');
  FSetupMainLoop;
end;

class function TRapi.SetVectorElt(aVector: PSEXPREC; const aVecvtorIndex:
    integer; aValue: PSEXPREC): PSEXPREC;
begin
  if @FSetVectorElt = nil then
    FSetVectorElt := GetRProcAddress('SET_VECTOR_ELT');
  Result := FSetVectorElt(aVector, aVecvtorIndex, aValue);
end;

class procedure TRapi.SET_PRINTNAME(const aHandle, aNameHandle: PSEXPREC);
begin
  if @FSetPrintName = nil then
    FSetPrintName := GetRProcAddress('SET_PRINTNAME');
  FSetPrintName(aHandle, aNameHandle);
end;

class function TRapi.StringElt(aVector: PSEXPREC; const aIndex: integer):
    PSEXPREC;
begin
  if @FStringElt = nil then
    FStringElt := GetRProcAddress('STRING_ELT');
  Result := FStringElt(aVector, aIndex);
end;

class function TRapi.SYMVALUE(const aHandle: PSEXPREC): PSEXPREC;
begin
  if @FSYMVALUE = nil then
    FSYMVALUE := GetRProcAddress('SYMVALUE');
  Result := FSYMVALUE(aHandle);
end;

class function TRapi.TAG_LinkedList(const aCurrentNode: PSEXPREC): PSEXPREC;
begin
  if @FTAG_LinkedList = nil then
    FTAG_LinkedList := GetRProcAddress('TAG');
  Result := FTAG_LinkedList(aCurrentNode);
end;

//------------------------------------------------------------------------------
class function TRapi.TryEval(h1, h2: PSEXPREC;
  var errorOccurred: LongBool): PSEXPREC;
begin
  if @FTryEval = nil then
    FTryEval := GetRProcAddress('R_tryEval');
  result := FTryEval(h1, h2, errorOccurred);
end;

class function TRapi.TypeOf(const aHandle: PSEXPREC): integer;
begin
  if @FTypeOf = nil then
    FTypeOf := GetRProcAddress('TYPEOF');
  Result := FTypeOf(aHandle);
end;

//------------------------------------------------------------------------------
class procedure TRapi.UnloadDLL;
begin
  FreeLibrary(FdllHandle);
  FdllHandle := 0;
end;
//------------------------------------------------------------------------------
class procedure TRapi.Unprotect(p: PSEXPREC);
begin
  if @FUnprotect = nil then
    FUnprotect := GetRProcAddress('Rf_unprotect_ptr');
  FUnprotect(p);
end;

class function TRapi.VectorElt(aVector: PSEXPREC; const aVecvtorIndex:
    integer): PSEXPREC;
begin
  if @FVectorElt = nil then
    FVectorElt := GetRProcAddress('VECTOR_ELT');
  Result := FVectorElt(aVector, aVecvtorIndex);
end;

//------------------------------------------------------------------------------
class function TRapi.VectorToPairList(p: PSEXPREC): PSEXPREC;
begin
  if @FVectorToPairList = nil then
    FVectorToPairList := GetRProcAddress('Rf_VectorToPairList');
  result := FVectorToPairList(p);
end;

end.
