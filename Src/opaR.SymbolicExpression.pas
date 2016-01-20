unit opaR.SymbolicExpression;

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

SymbolicExpression is a wrapper class for an R SEXPREC structure.

R.NET implements the AsXXXX functions (e.g. AsNumeric) within a SymbolicExpression
extension. However, if we want to use chaining syntax (used in R.NET API examples)
in Delphi then we need to return interfaces from those functions. Since we don't
have interface helpers/extensions in Delphi, the SymbolicExpression extension
methods have been moved into the main SymbolicExpression class definition in opaR.

Notes:

SymbolicExpression in R.NET inherits from IDynamicMetaObjectProvider which
allows the use of dynamic typing, something we don't have in Delphi.

-------------------------------------------------------------------------------}

{ TODO : TSymbolicExpression.AsRawMatrix }


interface

uses
  Winapi.Windows,
  System.Types,
  System.Generics.Defaults,

  opaR.Interfaces,
  opaR.SEXPREC,
  opaR.Utils,
  opaR.DLLFunctions;

type
  TSymbolicExpression = class(TInterfacedObject, ISymbolicExpression)
  private
    FIsProtected: boolean;
    FEngineHandle: HMODULE;
    FHandle: PSEXPREC;
    Fsexp: TSEXPREC;
    FEngine: IREngine;
    function GetIsInvalid: boolean;
    function GetIsProtected: boolean;
    function GetType: TSymbolicExpressionType;
    function GetHandle: PSEXPREC;
    function GetEngineHandle: HMODULE;
    function GetEngine: IREngine;
    //function GetAttribute(attributeName: string): TSymbolicExpression; overload;
    //function GetAttribute(symbol: ISymbolicExpression): TSymbolicExpression; overload;
  protected
    function ConfirmType(typeName: string): boolean;
  public
    constructor Create(engine: IREngine; pExpr: PSEXPREC);
    destructor Destroy; override;

    function AsCharacter: ICharacterVector;
    function AsCharacterMatrix: ICharacterMatrix;
    function AsDataFrame: IDataFrame;
    function AsEnvironment: IREnvironment;
    function AsExpression: IExpression;
    function AsFactor: IFactor;
    function AsFunction: IRFunction;
    function AsInteger: IIntegerVector;
    function AsIntegerMatrix: IIntegerMatrix;
    function AsLanguage: IRLanguage;
    function AsList: IGenericVector;
    function AsLogical: ILogicalVector;
    function AsLogicalMatrix: ILogicalMatrix;
    function AsNumeric: INumericVector;
    function AsNumericMatrix: INumericMatrix;
    function AsRaw: IRawVector;
    function AsS4: IS4Object;
    function AsSymbol: ISymbol;
    function AsVector: IDynamicVector;

    function IsDataFrame: boolean;
    function IsEnvironment: boolean;
    function IsExpression: boolean;
    function IsFactor: boolean;
    function IsFunction: boolean;
    function IsLanguage: boolean;
    function IsList: boolean;
    function IsMatrix: boolean;
    function IsS4: boolean;
    function IsSymbol: boolean;
    function IsVector: boolean;

    function IsEqualTo(other: ISymbolicExpression): boolean;
    function GetAttribute(attributeName: string): ISymbolicExpression; overload;
    function GetAttribute(symbol: ISymbolicExpression): ISymbolicExpression; overload;
    function GetAttributeNames: TArray<string>;
    function GetInternalStructure: TSEXPREC;
    function ReleaseHandle: boolean;
    procedure Preserve;
    procedure SetAttribute(attributeName: string; value: ISymbolicExpression); overload;
    procedure SetAttribute(symbol, value: ISymbolicExpression); overload;
    procedure Unpreserve;
    property Engine: IREngine read GetEngine;
    property EngineHandle: HMODULE read GetEngineHandle;
    property Handle: PSEXPREC read GetHandle;
    property IsInvalid: boolean read GetIsInvalid;
    property IsProtected: boolean read GetIsProtected;
    property Type_: TSymbolicExpressionType read GetType;
  end;

implementation

uses
  opaR.InternalString,
  opaR.EngineExtension,
  opaR.CharacterVector,
  opaR.CharacterMatrix,
  opaR.IntegerVector,
  opaR.DataFrame,
  opaR.Factor,
  opaR.Closure,
  opaR.BuiltInFunction,
  opaR.SpecialFunction,
  opaR.IntegerMatrix,
  opaR.GenericVector,
  opaR.NumericVector,
  opaR.NumericMatrix,
  opaR.LogicalVector,
  opaR.S4Object,
  opaR.Environment,
  opaR.Expression,
  opaR.Language,
  opaR.LogicalMatrix,
  opaR.RawVector,
  opaR.Symbol,
  opaR.DynamicVector;

{ TSymbolicExpression }

//------------------------------------------------------------------------------
function TSymbolicExpression.AsCharacter: ICharacterVector;
var
  p: PSEXPREC;
  charFac: TRFnAsCharacterFactor;
  coerceVec: TRFnCoerceVector;
begin
  if not IsVector then Exit(nil);

  if IsFactor then
  begin
    charFac := GetProcAddress(EngineHandle, 'Rf_asCharacterFactor');
    p := charFac(Handle);
  end
  else
  begin
    coerceVec := GetProcAddress(EngineHandle, 'Rf_coerceVector');
    p := coerceVec(Handle, TSymbolicExpressionType.CharacterVector);
  end;
  result := TCharacterVector.Create(Engine, p);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsCharacterMatrix: ICharacterMatrix;
var
  rowCount: integer;
  columnCount: integer;
  fnNumRows: TRFnNumRows;
  fnNumCols: TRFnNumCols;
  fnLength: TRFnLength;
  fnCoerceVector: TRFnCoerceVector;
  coercedPtr: PSEXPREC;
  vec: IIntegerVector;
  dimSymbol: ISymbolicExpression;
begin
  if not IsVector then Exit(nil);

  rowCount := 0;
  columnCount := 0;

  if self.IsMatrix then
  begin
    if self.Type_ = TSymbolicExpressionType.CharacterVector then
    begin
      result := TCharacterMatrix.Create(Engine, Handle);
      Exit;
    end
    else
    begin
      fnNumRows := GetProcAddress(EngineHandle, 'Rf_nrows');
      rowCount := fnNumRows(Handle);
      fnNumCols := GetProcAddress(EngineHandle, 'Rf_ncols');
      columnCount := fnNumCols(Handle);
    end;
  end;

  if columnCount = 0 then
  begin
    fnLength := GetProcAddress(EngineHandle, 'Rf_length');
    rowCount := fnLength(Handle);
    columnCount := 1;
  end;

  fnCoerceVector := GetProcAddress(EngineHandle, 'Rf_coerceVector');
  coercedPtr := fnCoerceVector(Handle, TSymbolicExpressionType.CharacterVector);
  vec := TIntegerVector.Create(Engine, [rowCount, columnCount]);
  dimSymbol := TEngineExtension(Engine).GetPredefinedSymbol('R_DimSymbol');

  result := TCharacterMatrix.Create(Engine, coercedPtr);
  (result as TSymbolicExpression).SetAttribute(dimSymbol as ISymbolicExpression, vec as ISymbolicExpression);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsDataFrame: IDataFrame;
begin
  if not IsDataFrame then Exit(nil);

  result := TDataFrame.Create(Engine, Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsEnvironment: IREnvironment;
begin
  if not IsEnvironment then Exit(nil);

  result := TREnvironment.Create(Engine, Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsExpression: IExpression;
begin
  if not IsExpression then Exit(nil);

  result := TExpression.Create(Engine, Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsFactor: IFactor;
begin
  if not IsFactor then Exit(nil);

  result := TFactor.Create(Engine, Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsFunction: IRFunction;
begin
  case Type_ of
    TSymbolicExpressionType.Closure: result := TRClosure.Create(Engine, Handle);
    TSymbolicExpressionType.BuiltinFunction: result := TRBuiltinFunction.Create(Engine, Handle);
    TSymbolicExpressionType.SpecialFunction: result := TRSpecialFunction.Create(Engine, Handle);
    else
      result := TRBuiltinFunction.Create(Engine, Handle);
  end;
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsInteger: IIntegerVector;
var
  p: PSEXPREC;
  coerceVec: TRFnCoerceVector;
begin
  if not IsVector then Exit(nil);

  coerceVec := GetProcAddress(EngineHandle, 'Rf_coerceVector');
  p := coerceVec(Handle, TSymbolicExpressionType.IntegerVector);

  result := TIntegerVector.Create(Engine, p);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsIntegerMatrix: IIntegerMatrix;
var
  rowCount: integer;
  columnCount: integer;
  fnNumRows: TRFnNumRows;
  fnNumCols: TRFnNumCols;
  fnLength: TRFnLength;
  fnCoerceVector: TRFnCoerceVector;
  coercedPtr: PSEXPREC;
  vec: IIntegerVector;
  dimSymbol: ISymbolicExpression;
begin
  if not self.IsVector then Exit(nil);

  rowCount := 0;
  columnCount := 0;

  if self.IsMatrix then
  begin
    if self.Type_ = TSymbolicExpressionType.IntegerVector then
    begin
      result := TIntegerMatrix.Create(Engine, Handle);
      Exit;
    end
    else
    begin
      fnNumRows := GetProcAddress(EngineHandle, 'Rf_nrows');
      rowCount := fnNumRows(Handle);
      fnNumCols := GetProcAddress(EngineHandle, 'Rf_ncols');
      columnCount := fnNumCols(Handle);
    end;
  end;

  if columnCount = 0 then
  begin
    fnLength := GetProcAddress(EngineHandle, 'Rf_length');
    rowCount := fnLength(Handle);
    columnCount := 1;
  end;

  fnCoerceVector := GetProcAddress(EngineHandle, 'Rf_coerceVector');
  coercedPtr := fnCoerceVector(Handle, TSymbolicExpressionType.IntegerVector);
  vec := TIntegerVector.Create(Engine, [rowCount, columnCount]);
  dimSymbol := TEngineExtension(Engine).GetPredefinedSymbol('R_DimSymbol');

  result := TIntegerMatrix.Create(Engine, coercedPtr);
  (result as TSymbolicExpression).SetAttribute(dimSymbol as ISymbolicExpression, vec as ISymbolicExpression);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsLanguage: IRLanguage;
begin
  if not IsLanguage then Exit(nil);

  result := TRLanguage.Create(Engine, Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsList: IGenericVector;
var
  expr: ISymbolicExpression;
  newExpr: ISymbolicExpression;
  exprArray: TArray<ISymbolicExpression>;
  asListFunction: IRFunction;
begin
  { TODO : TSymbolicExpression.AsList - check engines. }

  expr := TEngineExtension(Engine).Evaluate('invisible(as.list)');
  asListFunction := (expr as TSymbolicExpression).AsFunction;

  SetLength(exprArray, 1);
  exprArray[0] := self;

  newExpr := asListFunction.Invoke(exprArray);
  result := TGenericVector.Create(Engine, newExpr.Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsLogical: ILogicalVector;
var
  p: PSEXPREC;
  coerceVec: TRFnCoerceVector;
begin
  if not IsVector then Exit(nil);

  coerceVec := GetProcAddress(EngineHandle, 'Rf_coerceVector');
  p := coerceVec(Handle, TSymbolicExpressionType.LogicalVector);

  result := TLogicalVector.Create(Engine, p);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsLogicalMatrix: ILogicalMatrix;
var
  rowCount: integer;
  columnCount: integer;
  fnNumRows: TRFnNumRows;
  fnNumCols: TRFnNumCols;
  fnLength: TRFnLength;
  fnCoerceVector: TRFnCoerceVector;
  coercedPtr: PSEXPREC;
  vec: IIntegerVector;
  dimSymbol: ISymbolicExpression;
begin
  if not self.IsVector then Exit(nil);

  rowCount := 0;
  columnCount := 0;

  if self.IsMatrix then
  begin
    if self.Type_ = TSymbolicExpressionType.LogicalVector then
    begin
      result := TLogicalMatrix.Create(Engine, Handle);
      Exit;
    end
    else
    begin
      fnNumRows := GetProcAddress(EngineHandle, 'Rf_nrows');
      rowCount := fnNumRows(Handle);
      fnNumCols := GetProcAddress(EngineHandle, 'Rf_ncols');
      columnCount := fnNumCols(Handle);
    end;
  end;

  if columnCount = 0 then
  begin
    fnLength := GetProcAddress(EngineHandle, 'Rf_length');
    rowCount := fnLength(Handle);
    columnCount := 1;
  end;

  fnCoerceVector := GetProcAddress(EngineHandle, 'Rf_coerceVector');
  coercedPtr := fnCoerceVector(Handle, TSymbolicExpressionType.LogicalVector);
  vec := TIntegerVector.Create(Engine, [rowCount, columnCount]);
  dimSymbol := TEngineExtension(Engine).GetPredefinedSymbol('R_DimSymbol');

  result := TLogicalMatrix.Create(Engine, coercedPtr);
  (result as TSymbolicExpression).SetAttribute(dimSymbol as ISymbolicExpression, vec as ISymbolicExpression);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsNumeric: INumericVector;
var
  p: PSEXPREC;
  coerceVec: TRFnCoerceVector;
begin
  if not IsVector then Exit(nil);

  coerceVec := GetProcAddress(EngineHandle, 'Rf_coerceVector');
  p := coerceVec(Handle, TSymbolicExpressionType.NumericVector);

  result := TNumericVector.Create(Engine, p);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsNumericMatrix: INumericMatrix;
var
  rowCount: integer;
  columnCount: integer;
  fnNumRows: TRFnNumRows;
  fnNumCols: TRFnNumCols;
  fnLength: TRFnLength;
  fnCoerceVector: TRFnCoerceVector;
  coercedPtr: PSEXPREC;
  vec: IIntegerVector;
  dimSymbol: ISymbolicExpression;
begin
  if not self.IsVector then Exit(nil);

  rowCount := 0;
  columnCount := 0;

  if self.IsMatrix then
  begin
    if self.Type_ = TSymbolicExpressionType.NumericVector then
    begin
      result := TNumericMatrix.Create(Engine, Handle);
      Exit;
    end
    else
    begin
      fnNumRows := GetProcAddress(EngineHandle, 'Rf_nrows');
      rowCount := fnNumRows(Handle);
      fnNumCols := GetProcAddress(EngineHandle, 'Rf_ncols');
      columnCount := fnNumCols(Handle);
    end;
  end;

  if columnCount = 0 then
  begin
    fnLength := GetProcAddress(EngineHandle, 'Rf_length');
    rowCount := fnLength(Handle);
    columnCount := 1;
  end;

  fnCoerceVector := GetProcAddress(EngineHandle, 'Rf_coerceVector');
  coercedPtr := fnCoerceVector(Handle, TSymbolicExpressionType.NumericVector);
  vec := TIntegerVector.Create(Engine, [rowCount, columnCount]);
  dimSymbol := TEngineExtension(Engine).GetPredefinedSymbol('R_DimSymbol');

  result := TNumericMatrix.Create(Engine, coercedPtr);
  (result as TSymbolicExpression).SetAttribute(dimSymbol as ISymbolicExpression, vec as ISymbolicExpression);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsRaw: IRawVector;
var
  p: PSEXPREC;
  coerceVec: TRFnCoerceVector;
begin
  if not IsVector then Exit(nil);

  coerceVec := GetProcAddress(EngineHandle, 'Rf_coerceVector');
  p := coerceVec(Handle, TSymbolicExpressionType.RawVector);

  result := TRawVector.Create(Engine, p);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsS4: IS4Object;
begin
  if not IsS4 then Exit(nil);

  result := TS4Object.Create(Engine, Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsSymbol: ISymbol;
begin
  if not IsSymbol then Exit(nil);

  result := TSymbol.Create(Engine, Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.AsVector: IDynamicVector;
var
  p: PSEXPREC;
  coerceVec: TRFnCoerceVector;
begin
  if not IsVector then Exit(nil);

  coerceVec := GetProcAddress(EngineHandle, 'Rf_coerceVector');
  p := coerceVec(Handle, self.Type_);

  result := TDynamicVector.Create(Engine, p);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.ConfirmType(typeName: string): boolean;
var
  typeConfirm: TRFnTypeConfirm;
begin
  typeConfirm := GetProcAddress(EngineHandle, PAnsiChar(AnsiString(typeName)));
  result := typeConfirm(Handle);
end;
//------------------------------------------------------------------------------
constructor TSymbolicExpression.Create(engine: IREngine; pExpr: PSEXPREC);
begin
  FEngine := engine;
  FEngineHandle := engine.Handle; //dllHandle;
  Fsexp := pExpr^;
  FHandle := pExpr;
  Preserve;   // -- Protect the structure from R's garbage collector.
end;
//------------------------------------------------------------------------------
{constructor TSymbolicExpression.Create(dllHandle: HMODULE; pExpr: PSEXPREC);
begin
  
end;}
//------------------------------------------------------------------------------
destructor TSymbolicExpression.Destroy;
begin
  Unpreserve;
  inherited;
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsDataFrame: boolean;
var
  isFrame: TRFnIsFrame;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsDataFrame');

  isFrame := GetProcAddress(EngineHandle, 'Rf_isFrame');
  result := isFrame(Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsEnvironment: boolean;
var
  fnIsEnvironment: TRFnIsEnvironment;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsEnvironment');

  fnIsEnvironment := GetProcAddress(EngineHandle, 'Rf_isEnvironment');
  result := fnIsEnvironment(Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsEqualTo(other: ISymbolicExpression): boolean;
begin
  result := (other <> nil) and (other.Handle = FHandle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsExpression: boolean;
var
  fnIsExpression: TRFnIsExpression;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsExpression');

  fnIsExpression := GetProcAddress(EngineHandle, 'Rf_isExpression');
  result := fnIsExpression(Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsFactor: boolean;
var
  isFactor: TRFnIsFactor;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsFactor');

  isFactor := GetProcAddress(EngineHandle, 'Rf_isFactor');
  result := isFactor(Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsFunction: boolean;
var
  isFunction: TRFnIsFunction;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsFunction');

  isFunction := GetProcAddress(EngineHandle, 'Rf_isFunction');
  result := isFunction(Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsLanguage: boolean;
var
  isLanguage: TRFnIsLanguage;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsLanguage');

  isLanguage := GetProcAddress(EngineHandle, 'Rf_isLanguage');
  result := isLanguage(Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsList: boolean;
var
  len: integer;
  fnLength: TRFnLength;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsList');

  if self.Type_ = TSymbolicExpressionType.List then
    Exit(true);

  fnLength := GetProcAddress(EngineHandle, 'Rf_length');
  len := fnLength(Handle);
  result := (self.Type_ = TSymbolicExpressionType.Pairlist) and (len > 0);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsMatrix: boolean;
var
  fnIsMatrix: TRFnIsMatrix;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsMatrix');

  fnIsMatrix := GetProcAddress(EngineHandle, 'Rf_isMatrix');
  result := fnIsMatrix(Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsS4: boolean;
var
  fnIsS4: TRFnIsS4;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsS4');

  fnIsS4 := GetProcAddress(EngineHandle, 'Rf_isS4');
  result := fnIsS4(Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsSymbol: boolean;
var
  fnIsSymbol: TRFnIsSymbol;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsSymbol');

  fnIsSymbol := GetProcAddress(EngineHandle, 'Rf_isSymbol');
  result := fnIsSymbol(Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.IsVector: boolean;
var
  fnIsVec: TRFnIsVector;
begin
  if self.Handle = nil then
    raise EopaRException.Create('Null expression in TSymbolicExpression.IsVector');

  fnIsVec := GetProcAddress(EngineHandle, 'Rf_isVector');
  result := fnIsVec(Handle);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.GetAttribute(
  attributeName: string): ISymbolicExpression;
var
  installedName: PSEXPREC;
  attribute: PSEXPREC;
  install: TRFnInstall;
  getAttrib: TRFnGetAttrib;
begin
  if attributeName = '' then
    raise EopaRException.Create('Attribute name cannot be null');

  install := GetProcAddress(FEngineHandle, 'Rf_install');
  installedName := install(PAnsiChar(AnsiString(attributeName)));

  getAttrib := GetProcAddress(FEngineHandle, 'Rf_getAttrib');
  attribute := getAttrib(Handle, installedName);
  if attribute = nil then
    result := nil
  else
    result := TSymbolicExpression.Create(FEngine, attribute);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.GetAttribute(
  symbol: ISymbolicExpression): ISymbolicExpression;
var
  attribute: PSEXPREC;
  getAttrib: TRFnGetAttrib;
begin
  if symbol = nil then
    raise EopaRException.Create('Error: Non-null symbol required');

  if symbol.Type_ <> TSymbolicExpressionType.Symbol then
    raise EopaRException.Create('Error: Symbol-type required');

  getAttrib := GetProcAddress(FEngineHandle, 'Rf_getAttrib');
  attribute := getAttrib(Handle, symbol.Handle);
  if attribute = TEngineExtension(Engine).NilValue then
    result := nil
  else
    result := TSymbolicExpression.Create(FEngine, attribute);
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.GetAttributeNames: TArray<string>;
var
  i: integer;
  length: integer;
  vecLength: TRFnLength;
  node: TSEXPREC;
  attribute: TSEXPREC;
  Ptr: PSEXPREC;
  internalStr: TInternalString;
begin
  vecLength := GetProcAddress(FEngineHandle, 'Rf_length');
  length := vecLength(Fsexp.attrib);
  SetLength(result, length);

  Ptr := Fsexp.attrib;
  for i := 0 to length - 1 do
  begin
    node := Ptr^;
    attribute := node.listsxp.tagval^;
    internalStr := TInternalString.Create(FEngine, attribute.symsxp.pname);
    try
      result[i] := internalStr.ToString;
    finally
      internalStr.Free;
    end;
    Ptr := node.listsxp.cdrval;
  end;
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.GetEngine: IREngine;
begin
  result := FEngine;
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.GetEngineHandle: HMODULE;
begin
  //result := FEngineHandle;
  result := FEngine.Handle;
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.GetHandle: PSEXPREC;
begin
  result := FHandle;
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.GetInternalStructure: TSEXPREC;
begin
  result := Fsexp;
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.GetIsInvalid: boolean;
begin
  result := NativeUInt(FHandle) = 0;
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.GetIsProtected: boolean;
begin
  result := FIsProtected;
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.GetType: TSymbolicExpressionType;
begin
  result := TSymbolicExpressionType(Fsexp.sxpinfo.type_);
end;
//------------------------------------------------------------------------------
procedure TSymbolicExpression.Preserve;
var
  preserveObj: TRFnPreserveObject;
begin
  if (not IsInvalid) and (not FIsProtected) then
  begin
    { TODO : Possibly need a lock here - although the RDotNet problems might be GC-related. }
    preserveObj := GetProcAddress(FEngineHandle, 'R_PreserveObject');
    preserveObj(Handle);
    FIsProtected := true;
  end;
end;
//------------------------------------------------------------------------------
function TSymbolicExpression.ReleaseHandle: boolean;
begin
  { TODO : TSymbolicExpression.ReleaseHandle - remove? Unpreserve is called in the destructor. }
  if FIsProtected then
    Unpreserve;
  result := true;
end;
//------------------------------------------------------------------------------
procedure TSymbolicExpression.SetAttribute(symbol, value: ISymbolicExpression);
var
  setAttrib: TRFnSetAttrib;
begin
  if symbol = nil then
    raise EopaRException.Create('Error: Non-null symbol required');

  if symbol.Type_ <> TSymbolicExpressionType.Symbol then
    raise EopaRException.Create('Error: Symbol-type required');

  if value = nil then
    value := TEngineExtension(Engine).NilValueExpression;

  setAttrib := GetProcAddress(FEngineHandle, 'Rf_setAttrib');
  setAttrib(Handle, symbol.Handle, value.Handle);
end;
//------------------------------------------------------------------------------
procedure TSymbolicExpression.SetAttribute(attributeName: string;
  value: ISymbolicExpression);
var
  installedName: PSEXPREC;
  install: TRFnInstall;
  setAttrib: TRFnSetAttrib;
begin
  if attributeName = '' then
    raise EopaRException.Create('Error: Non-null attributeName required');

  if value = nil then
    value := TEngineExtension(Engine).NilValueExpression;

  install := GetProcAddress(FEngineHandle, 'Rf_install');
  installedName := install(PAnsiChar(AnsiString(attributeName)));
  setAttrib := GetProcAddress(FEngineHandle, 'Rf_setAttrib');
  setAttrib(Handle, installedName, value.Handle);
end;
//------------------------------------------------------------------------------
procedure TSymbolicExpression.Unpreserve;
var
  releaseObj: TRFnReleaseObject;
begin
  if (not IsInvalid) and (FIsProtected) then
  begin
    { TODO : Possibly need a lock here - although the RDotNet problems might be GC-related? }
    releaseObj := GetProcAddress(FEngineHandle, 'R_ReleaseObject');
    releaseObj(Handle);
    FIsProtected := false;
  end;
end;

end.
