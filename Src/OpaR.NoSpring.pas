unit OpaR.NoSpring;

interface

uses
  System.Generics.Collections,
  System.SysUtils;

type
  IDictionary<TKey,TValue>=interface
    ['{99914228-5158-4F15-AFED-E20160B337C5}']
    function GetItem(const Key: TKey): TValue;
    procedure SetItem(const Key: TKey; const Value: TValue);

    procedure Add(const Key: TKey; const Value: TValue);
    Function Count:integer;
    function ContainsKey(const Key: TKey): Boolean;
    property Items[const Key: TKey]: TValue read GetItem write SetItem; default;
  end;

  IList<T>=interface
    ['{EE9BC2EF-B2BA-4283-9824-57E40C9E9C43}']
   function GetEnumerator: TList<T>.TEnumerator;
   function Add(const Value: T): Integer;
   function LastOrDefault:T;
   procedure AddRange(const Values: array of T);
   function ToArray: TArray<T>;
  end;


  TRefCountedList<T>=class(TInterfacedObject,IList<T>)
  private
    FList:TList<T>;
  public
   function GetEnumerator: TList<T>.TEnumerator;
   function Add(const Value: T): Integer;
   function LastOrDefault:T;
   procedure AddRange(const Values: array of T);
   function ToArray: TArray<T>;
    constructor Create;
    Destructor Destroy; override;
  end;

  TRefCountedDictionary<TKey,TValue>=class(TInterfacedObject,IDictionary<TKey,TValue>)
  private
    FDictionary:TDictionary<TKey,TValue>;
    function GetItem(const Key: TKey): TValue;
    procedure SetItem(const Key: TKey; const Value: TValue);

  public
    constructor Create;
    Destructor Destroy; override;
    procedure Add(const Key: TKey; const Value: TValue);
    function ContainsKey(const Key: TKey): Boolean;
    Function Count:integer;
    property Items[const Key: TKey]: TValue read GetItem write SetItem; default;
  end;

  TCollections=class
  public
    class function CreateList<T>: IList<T>;
    class function CreateDictionary<TKey,TValue>:IDictionary<TKey,TValue>;
  end;

implementation


{ TRefCountedList<T> }


Destructor TRefCountedList<T>.Destroy;
begin
  FList.Free;
  inherited;
end;

function TRefCountedList<T>.Add(const Value: T): Integer;
begin
  result:=FList.Add(Value);
end;

procedure TRefCountedList<T>.AddRange(const Values: array of T);
begin
  FList.AddRange(Values);
end;

function TRefCountedList<T>.GetEnumerator: TList<T>.TEnumerator;
begin
  result:=FList.GetEnumerator;
end;

constructor TRefCountedList<T>.Create;
begin
  inherited;
  FList:=TList<T>.Create;
end;


function TRefCountedList<T>.LastOrDefault: T;
begin
  if FList.Count>0 then
    result:=FList[FList.Count-1]
  else
    result:=Default(T);
end;


function TRefCountedList<T>.ToArray: TArray<T>;
begin
  result:=FList.ToArray;
end;


{ TCollections }

class function TCollections.CreateDictionary<TKey, TValue>: IDictionary<TKey, TValue>;
begin
  result:=TRefCountedDictionary<TKey,TValue>.Create;
end;

class function TCollections.CreateList<T>: IList<T>;
begin
  result := TRefCountedList<T>.Create;
end;

{ TRefCountedDictionary<TKey, TValue> }

procedure TRefCountedDictionary<TKey, TValue>.Add(const Key: TKey;
  const Value: TValue);
begin
  FDictionary.Add(key,value);
end;

function TRefCountedDictionary<TKey, TValue>.ContainsKey(
  const Key: TKey): Boolean;
begin
  result := FDictionary.ContainsKey(Key);
end;

function TRefCountedDictionary<TKey, TValue>.Count: integer;
begin
  result:=FDictionary.Count;
end;

constructor TRefCountedDictionary<TKey, TValue>.Create;
begin
  inherited;
  FDictionary:=TDictionary<TKey,TValue>.Create;
end;

destructor TRefCountedDictionary<TKey, TValue>.Destroy;
begin
  FDictionary.Free;
  inherited;
end;

function TRefCountedDictionary<TKey, TValue>.GetItem(const Key: TKey): TValue;
begin
  result:=FDictionary.Items[key];
end;

procedure TRefCountedDictionary<TKey, TValue>.SetItem(const Key: TKey;
  const Value: TValue);
begin
  FDictionary.Items[key]:=Value;
end;

end.
