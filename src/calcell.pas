{$mode objfpc}

unit CalCell;

interface

  uses
    Objects,
    CellEvnt;

  type
    TCalCell  = class
    public
      cellEvents : array [0..9] of TCellEvent;
      eventNum   : Integer;
      counter    : Integer;

      constructor create;
      destructor  destroy; override;
    end;


implementation

  constructor TCalCell.create;
  var
    i : Integer;

  begin
    counter    := 0;
    eventNum   := 0;

    for i := 0 to 9
    do
    begin
      cellEvents[i] := TCellEvent.create;
    end;

  end;

  destructor TCalCell.destroy;
  var
    i : Integer;

  begin

    for i := 0 to 9
    do
    begin
      cellEvents[i].Free;
    end;
  end;
  
  inherited destroy;

end.