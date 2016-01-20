unit MiscellaneousTests;

interface

uses
  TestFramework,

  opaR.Engine,
  opaR.InternalString,
  opaR.Interfaces;

type
  TMiscellaneousTests = class(TTestCase)
  private
    FEngine: IREngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure InternalString_Test;
  end;

implementation

{ TInternalStringTests }

//------------------------------------------------------------------------------
procedure TMiscellaneousTests.InternalString_Test;
var
  expr: IInternalString;
begin
  expr := TInternalString.Create(FEngine, 'abc');
  CheckEquals('abc', expr.ToString);
end;
//------------------------------------------------------------------------------
procedure TMiscellaneousTests.SetUp;
begin
  TREngine.SetEnvironmentVariables;
  FEngine := TREngine.GetInstance;
end;
//------------------------------------------------------------------------------
procedure TMiscellaneousTests.TearDown;
begin
  inherited;

end;



initialization
  TestFramework.RegisterTest(TMiscellaneousTests.Suite);

end.
