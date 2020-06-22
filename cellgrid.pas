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


  procedure CalcCell(day,
                     firstDay : Integer;
                     var row,
                         col : Integer);

implementation

uses
  Logger;

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


  procedure CalcCell(day,
                     firstDay : Integer;
                     var row,
                         col : Integer);
  (* Purpose : Calculate the row and column of the calendar day
     firstDay = the day number of the 1st of the month
     day      = the date in the month

     returns:
     row = row    0 to 6
     col = column 0 to 5
   *)

  var
    logger    : PLogger;

  begin

    new(logger);
    logger^.init;
    logger^.level := INFO;

    row := (day - 1 + firstDay) div 7;
    col := (day - 1 + firstDay) mod 7;

    logger^.logInt(DEBUG, 'day ', day);
    logger^.logInt(DEBUG, 'row ', row);
    logger^.logInt(DEBUG, 'col ', col);

    Dispose (logger, Done);
  end;

end.