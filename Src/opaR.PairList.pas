unit opaR.PairList;

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

This is a wrapper class for a PairList created by a call to Rf_VectorToPairList.
Early versions of R exposed PairLists more extensively - now they are rarely
encountered by users.

Pairlists in R are stored as a chain of nodes, where each node points to the
location of the next node in the chain, in addition to the node's contents and
the node's "name".

-------------------------------------------------------------------------------}

interface

uses
  Generics.Tuples,    // from https://github.com/malcolmgroves/generics.tuples

  opaR.DLLFunctions,
  opaR.Utils,
  opaR.SEXPREC,
  opaR.Symbol,
  opaR.SymbolicExpression,
  opaR.Interfaces;

type
  TPairList = class(TSymbolicExpression, IPairList, IVectorEnumerable<ISymbol>)
  private
    type
      TEnumerator = class(TInterfacedObject, IVectorEnumerator<ISymbol>)
      private
        FIndex: integer;
        FPairList: TPairList;
        FCurrentNode: PSEXPREC;
        function GetCurrent: ISymbol;
      public
        constructor Create(const pairList: TPairList);
        function MoveNext: Boolean;
        property Current: ISymbol read GetCurrent;
      end;
  private
    function GetCount: integer;
  public
    constructor Create(const engine: IREngine; pExpr: PSEXPREC);
    function First: ISymbol;
    function GetEnumerator: IVectorEnumerator<ISymbol>;
    function ToArray: TArray<ISymbol>;
    function ToTupleArray: TArray<ITuple<ISymbol, ISymbolicExpression>>;
    property Count: integer read GetCount;
  end;

implementation

uses
  opaR.EngineExtension;

{ TPairList }

//------------------------------------------------------------------------------
constructor TPairList.Create(const engine: IREngine; pExpr: PSEXPREC);
begin
  // -- The pExpr is that returned from a call to Rf_VectorToPairList in the calling code.
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
function TPairList.First: ISymbol;
begin
  result := TSymbol.Create(Engine, Engine.Rapi.TAG_LinkedList(Handle));
end;
//------------------------------------------------------------------------------
///	<summary>
///	This returns the number of nodes.
///	</summary>
function TPairList.GetCount: integer;
begin
  result := Engine.Rapi.Length(Handle);
end;
//------------------------------------------------------------------------------
function TPairList.GetEnumerator: IVectorEnumerator<ISymbol>;
begin
  result := TEnumerator.Create(self);
end;
//------------------------------------------------------------------------------
///	<summary>
///	opaR method - Not in R.NET 1.6.5
///	</summary>
function TPairList.ToTupleArray: TArray<ITuple<ISymbol, ISymbolicExpression>>;
var
  i: integer;
  expr: PSEXPREC;
  newSymbol: TSymbol;
  newExpresson: TSymbolicExpression;
begin
  SetLength(result, self.Count);
  expr := Handle;

  for i := 0 to self.Count - 1 do
  begin
    newSymbol := TSymbol.Create(Engine, Engine.Rapi.TAG_LinkedList(expr));
    newExpresson := TSymbolicExpression.Create(Engine, Engine.Rapi.CAR_LinkedList(expr));
    result[i] := TTuple<ISymbol, ISymbolicExpression>.Create(newSymbol, newExpresson);

    expr := Engine.Rapi.CDR_LinkedList(expr);
  end;
end;
//------------------------------------------------------------------------------
///	<summary>
///	opaR method - Not in R.NET 1.6.5
///	</summary>
function TPairList.ToArray: TArray<ISymbol>;
var
  i: integer;
  expr: PSEXPREC;
begin
  SetLength(result, self.Count);
  expr := Handle;
  result[0] := TSymbol.Create(Engine, Engine.Rapi.TAG_LinkedList(expr));

  for i := 1 to self.Count - 1 do
  begin
    result[i] := TSymbol.Create(Engine, Engine.Rapi.TAG_LinkedList(expr));
    expr := Engine.Rapi.CDR_LinkedList(expr);
  end;
end;



{ TPairList.TEnumerator }

//------------------------------------------------------------------------------
constructor TPairList.TEnumerator.Create(const pairList: TPairList);
begin
  FIndex := -1;
  FPairList := pairList;
end;
//------------------------------------------------------------------------------
function TPairList.TEnumerator.GetCurrent: ISymbol;
begin
  result := TSymbol.Create(FPairList.Engine, FPairList.Engine.Rapi.TAG_LinkedList(FCurrentNode));
end;
//------------------------------------------------------------------------------
function TPairList.TEnumerator.MoveNext: Boolean;
var
  curType: integer;
begin
  result := FIndex < FPairList.Count - 1;
  if result then
  begin
    if FIndex = -1 then
      FCurrentNode := FPairList.Handle
    else
    begin
      curType := FPairList.Engine.Rapi.TypeOf(FCurrentNode);
      if curType <> Ord(TSymbolicExpressionType.Null) then
        FCurrentNode := FPairList.Engine.Rapi.CDR_LinkedList(FCurrentNode);
    end;

    Inc(FIndex);
  end;
end;

end.
