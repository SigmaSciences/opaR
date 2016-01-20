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
  opaR.SEXPREC,
  opaR.Utils,
  opaR.Internals.Windows.RStart;

type
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

  TRfnSetupMainLoop = procedure; cdecl;

  TRFnGetRUser = function: PAnsiChar; cdecl;

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


  // -- The following are useful for debugging. Also see R_inspect and R_inspect3.
  // -- Rf_PrintValue
  TRFnPrintValue = procedure(p: PSEXPREC); cdecl;
  // -- R_PV
  TRFnPV = procedure(p: PSEXPREC); cdecl;

implementation

end.
