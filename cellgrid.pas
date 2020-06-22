unit CellGrid;

interface

uses
  Objects;

const
  NUMCELLS  = 31;

type

  PCellGrid = ^TCellGrid;

  TCellGrid = Object(TObject)
    cells : array [1..NUMCELLS] of Integer;

    constructor init;
    destructor  done; virtual;

  end;


implementation

  constructor TCellGrid.init;
  var
    i : Integer;

  begin
    for i := 1 to NUMCELLS
    do
      cells[i] := 0;

  end;

  destructor TCellGrid.done;
  begin

  end;

end.