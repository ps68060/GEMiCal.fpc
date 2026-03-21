{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}
{$mode objfpc}

unit CalCell;

interface

  uses
    Objects,
    CellEvnt;

  type
    TCalCell  = class
      cellEvents : array [0..9] of TCellEvent;
      eventNum   : Integer;
      counter    : Integer;

      constructor Create;
      destructor  Destroy; virtual;
    end;


implementation

  constructor TCalCell.Create;
  var
    i : Integer;

  begin
    counter    := 0;
    eventNum   := 0;

    for i := 0 to 9
    do
    begin
      cellEvents[i] := TCellEvent.Create;
    end;

  end;


  destructor TCalCell.Destroy;
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