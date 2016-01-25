unit opaR.Interfaces;

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
  System.Variants,

  Spring.Collections,
  Spring.Collections.Dictionaries,
  Generics.Tuples,      // from https://github.com/malcolmgroves/generics.tuples

  opaR.SEXPREC,
  opaR.Utils,
  opaR.VectorUtils,
  opaR.StartupParameter,
  opaR.DLLFunctions;

type
  ICharacterVector = interface;
  ICharacterMatrix = interface;
  IDataFrame = interface;
  IFactor = interface;
  IIntegerVector = interface;
  IIntegerMatrix = interface;
  IGenericVector = interface;
  INumericVector = interface;
  INumericMatrix = interface;
  IRFunction = interface;
  ILogicalVector = interface;
  IS4Object = interface;
  IREnvironment = interface;
  IExpression = interface;
  IRLanguage = interface;
  IPairList = interface;
  ILogicalMatrix = interface;
  IRawVector = interface;
  ISymbol = interface;
  IDynamicVector = interface;
  ICharacterDevice = interface;
  IREngine = interface;

  ISymbolicExpression = interface
    ['{2C80F611-F3A7-49CF-B8EE-D96868F08BFF}']
    function GetAttribute(attributeName: string): ISymbolicExpression; overload;
    function GetAttribute(symbol: ISymbolicExpression): ISymbolicExpression; overload;
    function GetAttributeNames: TArray<string>;
    function GetInternalStructure: TSEXPREC;
    function ReleaseHandle: boolean;
    procedure Preserve;
    procedure SetAttribute(attributeName: string; value: ISymbolicExpression); overload;
    procedure SetAttribute(symbol, value: ISymbolicExpression); overload;
    procedure Unpreserve;

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

    function GetEngine: IREngine;
    function GetHandle: PSEXPREC;
    function GetEngineHandle: HMODULE;
    function GetIsInvalid: boolean;
    function GetIsProtected: boolean;
    function GetType: TSymbolicExpressionType;
    property Engine: IREngine read GetEngine;
    property EngineHandle: HMODULE read GetEngineHandle;
    property Handle: PSEXPREC read GetHandle;
    property IsInvalid: boolean read GetIsInvalid;
    property IsProtected: boolean read GetIsProtected;
    property Type_: TSymbolicExpressionType read GetType;
  end;

  IREngine = interface
    ['{DAAC4C57-9430-49D1-9370-BAA61A8E5B4C}']
    function CreateCharacter(value: string): ICharacterVector;
    function CreateInteger(value: integer): IIntegerVector;
    function CreateLogical(value: LongBool): ILogicalVector;
    function CreateNumeric(value: double): INumericVector;
    function CreateRaw(value: Byte): IRawVector;
    function CreateCharacterVector(arr: TArray<string>): ICharacterVector;
    function CreateIntegerVector(arr: TArray<integer>): IIntegerVector;
    function CreateLogicalVector(arr: TArray<LongBool>): ILogicalVector;
    function CreateNumericVector(arr: TArray<double>): INumericVector;
    function CreateRawVector(arr: TArray<Byte>): IRawVector;
    function GetAutoPrint: boolean;
    function GetDisposed: boolean;
    function GetGlobalEnvironment: IREnvironment;
    function GetHandle: HMODULE;
    function GetNilValue: PSEXPREC;
    function GetRapi: TRapi;
    function Evaluate(statement: string): ISymbolicExpression;
    function EvaluateAsList(statement: string): IGenericVector;
    function GetPredefinedSymbolPtr(symbolName: string): PSEXPREC;
    function GetSymbol(symbolName: string): ISymbolicExpression; overload;
    function GetSymbol(symbolName: string; env: IREnvironment): ISymbolicExpression; overload;
    function GetVisible: boolean;
    procedure Initialize(parameter: TStartupParameter = nil;
      device: ICharacterDevice = nil; setupMainLoop: boolean = true);
    procedure SetAutoPrint(const Value: boolean);
    procedure SetSymbol(name: string; expression: ISymbolicExpression);
    property AutoPrint: boolean read GetAutoPrint write SetAutoPrint;
    property Disposed: boolean read GetDisposed;
    property GlobalEnvironment: IREnvironment read GetGlobalEnvironment;
    property Handle: HMODULE read GetHandle;      // -- The R DLL handle.
    property NilValue: PSEXPREC read GetNilValue;
    property Rapi: TRapi read GetRapi;
  end;

  IREnvironment = interface(ISymbolicExpression)
    ['{A6176D6D-F993-4073-BDB0-179F2D13E313}']
    function GetParent: IREnvironment;
    function GetSymbol(symbolName: string): ISymbolicExpression;
    function GetSymbolNames(includeSpecialFunctions: LongBool): TArray<string>;
    procedure SetSymbol(symbolName: string; expression: ISymbolicExpression);
    property Parent: IREnvironment read GetParent;
  end;

  { TODO : ICharacterDevice unix history methods. }
  ICharacterDevice = interface
    ['{03ECE5E9-A2B6-4778-8F6D-3A62267E62B3}']
    function ReadConsole(prompt: string; capacity: integer; history: boolean): string;
    procedure WriteConsole(output: string; length: integer; outputType: TConsoleOutputType);
    procedure ShowMessage(msg: string);
    procedure Busy(which: TBusyType);
    procedure Callback;
    function Ask(question: string): TYesNoCancel;
    // -- Unix-only from this point.
    procedure Suicide(msg: string);
    procedure ResetConsole;
    procedure FlushConsole;
    procedure ClearErrorConsole;
    procedure CleanUp(saveAction: TStartupSaveAction; status: integer; runLast: boolean);
    function ShowFiles(files, headers: TArray<string>; title: string; delete: boolean; pager: string): boolean;
    function ChooseFile(create: boolean): string;
    procedure EditFile(fileName: string);
    //SymbolicExpression LoadHistory(Language call, SymbolicExpression operation, Pairlist args, REnvironment environment);
    //function LoadHistory: TSymbolicExpression;
    //SymbolicExpression SaveHistory(Language call, SymbolicExpression operation, Pairlist args, REnvironment environment);
    //function SaveHistory: TSymbolicExpression;
    //SymbolicExpression AddHistory(Language call, SymbolicExpression operation, Pairlist args, REnvironment environment);
    //function AddHistory: TSymbolicExpression;
    // -- End Unix-only
  end;

  IExpression = interface(ISymbolicExpression)
    ['{D6787CE5-AF89-45A4-9514-A43B3A06CDBE}']
    function Evaluate(const environment: IREnvironment): ISymbolicExpression;
    function TryEvaluate(const environment: IREnvironment; out rtn: ISymbolicExpression): boolean;
  end;

  IInternalString = interface(ISymbolicExpression)
    ['{C6E5C3CF-52DD-4AED-8EB4-FB12E70CD189}']
    function ToString: string;
  end;

  IRLanguage = interface(ISymbolicExpression)
    ['{BB012D72-46D4-4423-B17A-4FC62A96FCCB}']
    function FunctionCall: IPairList;
  end;

  ISymbol = interface(ISymbolicExpression)
    ['{6738C7E1-A663-4A65-9F90-7BBFA131310F}']
    function GetInternal: ISymbolicExpression;
    function GetPrintName: string;
    function GetValue: ISymbolicExpression;
    procedure SetPrintName(const Value: string);
    property Internal: ISymbolicExpression read GetInternal;
    property PrintName: string read GetPrintName write SetPrintName;
    property Value: ISymbolicExpression read GetValue;
  end;

  IPairList = interface(ISymbolicExpression)
    ['{8706ADBA-75E9-4B75-8B61-109C540E2D85}']
    function GetCount: integer;
    function First: ISymbol;
    function GetEnumerator: IVectorEnumerator<ISymbol>;
    function ToArray: TArray<ISymbol>;
    function ToTupleArray: TArray<ITuple<ISymbol, ISymbolicExpression>>;
    property Count: integer read GetCount;
  end;

  IRFunction = interface(ISymbolicExpression)
    ['{E21B9496-03F9-4BB1-BEF9-F8E5EC7CA36F}']
    function Invoke: ISymbolicExpression; overload;
    function Invoke(arg: ISymbolicExpression): ISymbolicExpression; overload;
    function Invoke(args: TArray<ISymbolicExpression>): ISymbolicExpression; overload;
    function Invoke(args: TDictionary<string, ISymbolicExpression>): ISymbolicExpression; overload;
    function InvokeNamed(args: TArray<TTuple<string, ISymbolicExpression>>): ISymbolicExpression;
    function InvokeStrArgs(args: TArray<string>): ISymbolicExpression;
  end;

  IS4Object = interface(ISymbolicExpression)
    ['{3EDF40F0-B3C5-4AB6-9ABC-F510074F0ECB}']
    function GetValueByName(name: string): ISymbolicExpression;
    function GetSlotNames: TArray<string>;
    function GetSlotCount: integer;
    procedure SetValueByName(name: string; value: ISymbolicExpression);
    function GetClassDefinition: IS4Object;
    function GetSlotTypes: IDictionary<string, string>;
    function HasSlot(slotName: string): boolean;
    property SlotCount: integer read GetSlotCount;
    property SlotNames: TArray<string> read GetSlotNames;
    property Values[name: string]: ISymbolicExpression read GetValueByName write SetValueByName; default;
  end;

  IRVector<T> = interface(IVectorEnumerable<T>)
    ['{C194BD39-04F7-4C6B-8E65-4C4E15B37E98}']
    function First: T;
    function GetArrayFast: TArray<T>;
    function GetLength: integer;
    function ToArray: TArray<T>;
    function GetValue(ix: integer): T;
    procedure SetValue(ix: integer; value: T);
    function GetValueByName(const name: string): T;
    procedure SetValueByName(const name: string; value: T);
    procedure SetVectorDirect(const values: TArray<T>);
    property Values[ix: integer]: T read GetValue write SetValue; default;
    property Values[const name: string]: T read GetValueByName write SetValueByName; default;
    property VectorLength: integer read GetLength;
  end;

  INumericVector = interface(IRVector<double>)
    ['{C7DB9E76-8F0D-41CA-AD3D-1A6B0FF2A167}']
    function ToArray: TArray<double>;
    procedure CopyTo(const destination: TArray<double>; copyCount: integer; sourceIndex: integer = 0; destinationIndex: integer = 0);
    procedure SetVectorDirect(const values: TArray<double>);
  end;

  ICharacterVector = interface(IRVector<string>)
    ['{1B3FAD8F-7156-4016-8D71-45276D068651}']
    function ToArray: TArray<string>;
    procedure CopyTo(const destination: TArray<string>; copyCount: integer; sourceIndex: integer = 0; destinationIndex: integer = 0);
  end;

  IExpressionVector = interface(IRVector<IExpression>)
    ['{96A16C79-CCE4-4937-9652-9E4189215839}']
  end;

  IIntegerVector = interface(IRVector<integer>)
    ['{032F9C91-E144-4388-B596-934E0C0331CF}']
    procedure CopyTo(const destination: TArray<integer>; copyCount: integer; sourceIndex: integer = 0; destinationIndex: integer = 0);
  end;

  ILogicalVector = interface(IRVector<LongBool>)
    ['{C102EAC3-5929-481D-A389-1C6D3F372940}']
  end;

  IRawVector = interface(IRVector<Byte>)
    ['{5CC5E04F-E88F-4CB6-A607-ECA33C9D891A}']
    procedure CopyTo(const destination: TArray<Byte>; copyCount: integer; sourceIndex: integer = 0; destinationIndex: integer = 0);
  end;

  IFactor = interface(IIntegerVector)
    ['{E4FA559B-BD7B-4352-ACF6-352C13DF0C8E}']
    function GetIsOrdered: boolean;
    function GetFactor(index: integer): string;
    function GetFactors: TArray<string>; //overload;
    // -- Delphi doesn't allow parameterised interface methods.
    //function GetFactors<TEnum: record>(ignoreCase: boolean = false): TArray<TEnum>; overload;
    function GetLevels: TArray<string>;
    procedure SetFactor(index: integer; factorValue: string);
    property IsOrdered: boolean read GetIsOrdered;
  end;

  IDynamicVector = interface(IRVector<variant>)
    ['{461421FA-84EA-46F1-B147-5E510C72DFAA}']
  end;

  IGenericVector = interface(IRVector<ISymbolicExpression>)
    ['{591195D7-0744-4DE1-B94B-5ED3731FEB4B}']
    function GetArrayFast: TArray<ISymbolicExpression>;
    function ToPairlist: IPairlist;
    procedure SetNames(const names: TArray<string>); overload;
    procedure SetNames(const names: ICharacterVector); overload;
  end;

  IDataFrameRow = interface
    ['{895F7AD7-9640-4283-857A-EB526E1CF499}']
    function GetValue(ix: integer): Variant;
    procedure SetValue(ix: integer; const Value: Variant);
    function GetValueByName(name: string): Variant;
    procedure SetValueByName(name: string; const Value: Variant);
    function GetRowIndex: integer;
    property RowIndex: integer read GetRowIndex;
    property Values[ix: integer]: Variant read GetValue write SetValue; default;
    property Values[name: string]: Variant read GetValueByName write SetValueByName; default;
  end;

  IDataFrame = interface(IRVector<IDynamicVector>)
    ['{FFCC9740-B61A-44E9-B982-FEAA702DDFEA}']
    function GetColumnCount: integer;
    function GetColumnNames: TArray<string>;
    function GetRowCount: integer;
    function GetRowNames: TArray<string>;
    function GetArrayValue(rowIndex, columnIndex: integer): Variant;
    procedure SetArrayValue(rowIndex, columnIndex: integer;
      const Value: Variant);
    function GetArrayValueByName(rowName, columnName: string): Variant;
    procedure SetArrayValueByName(rowName, columnName: string;
      const Value: Variant);
    function GetArrayValueByIndexAndName(rowIndex: integer; columnName: string): Variant;
    procedure SetArrayValueByIndexAndName(rowIndex: integer; columnName: string;
      const Value: Variant);
    function GetArrayFast: TArray<IDynamicVector>; //reintroduce;
    function GetRow(rowIndex: integer): IDataFrameRow;
    function GetRows: IList<IDataFrameRow>;
    procedure SetVectorDirect(const values: TArray<IDynamicVector>); //override;
    property ColumnCount: integer read GetColumnCount;
    property ColumnNames: TArray<string> read GetColumnNames;
    property RowCount: integer read GetRowCount;
    property RowNames: TArray<string> read GetRowNames;
    property Values[rowIndex, columnIndex: integer]: Variant read GetArrayValue write SetArrayValue; default;
    property Values[rowIndex: integer; columnName: string]: Variant read GetArrayValueByIndexAndName write SetArrayValueByIndexAndName; default;
    property Values[rowName, columnName: string]: Variant read GetArrayValueByName write SetArrayValueByName; default;
  end;

  IRMatrix<T> = interface
    ['{30FC36D1-A371-4811-99DD-B0901C42FE17}']
    function GetArrayFast: TDynMatrix<T>;
    function GetColumnCount: integer;
    function GetRowCount: integer;
    function GetValue(rowIndex, columnIndex: integer): T;
    procedure SetValue(rowIndex, columnIndex: integer; value: T);
    property ColumnCount: integer read GetColumnCount;
    property RowCount: integer read GetRowCount;
    property Values[rowIndex, columnIndex: integer]: T read GetValue write SetValue; default;
  end;

  IIntegerMatrix = interface(IRMatrix<integer>)
    ['{B359EC74-9E35-42B2-9F99-D0DACFD6008E}']
  end;

  INumericMatrix = interface(IRMatrix<double>)
    ['{E80AECBC-C7DA-48E1-A305-6E509E5FCB08}']
  end;

  ICharacterMatrix = interface(IRMatrix<string>)
    ['{729CAB2D-5BAD-4499-9775-94EBAD3B52FC}']
  end;

  ILogicalMatrix = interface(IRMatrix<LongBool>)
    ['{74D68060-74A2-4DC4-B476-7C22E79B8354}']
  end;

implementation

end.
