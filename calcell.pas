unit CalCell;

interface

  uses
    Objects,
    CellEvnt;

  type
    PCalCell  = ^TCalCell;
    TCalCell  = Object(TObject)
      cellEvents : array [0..9] of TCellEvent;
      eventNum   : Integer;
      counter    : Integer;

      constructor init;
      destructor  done; virtual;
    end;


implementation

  constructor TCalCell.init;
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

  destructor TCalCell.done;
  var
    i : Integer;

  begin

    for i := 0 to 9
    do
    begin
      cellEvents[i].Free;
    end;
  end;

end.