unit CellGrid;

interface

  uses
    Objects,

    Cal,
    DateTime,
    CalCell;

  const
    NUMCELLS  = 31;

  type
    PCellGrid = ^TCellGrid;
    TCellGrid = Object(TObject)
      summary : array [1..NUMCELLS] of 
                  array [1..5] of String;
      cells   : array [1..NUMCELLS] of PCalCell;

      constructor init;
      destructor  done; virtual;

      procedure FilterEvents(cal       : PCal;
                             calDate   : PDateTime;
                             daysInMon : Integer);

      procedure FilterEvent(cal       : PCal;
                            calDate   : PDateTime;
                            daysInMon : Integer;
                            e         : Integer);
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
    begin
      new (cells[i]);
      cells[i]^.init;
    end;

  end;

  destructor TCellGrid.done;
  var
    i : Integer;

  begin
    for i := 1 to NUMCELLS
    do
    begin
      dispose(cells[i], Done);
    end;
  end;


  function SubStr(myStr : String)
          : String;
  begin
    SubStr := Copy(myStr, 1, 16);
  end;


  procedure TCellGrid.FilterEvents(cal       : PCal;
                                   calDate   : PDateTime;
                                   daysInMon : Integer);

  (* Purpose : Decide which Events should be displayed in the month *)

  var
    logger       : PLogger;

    endMonthDate : PDateTime;

    row,
    col,
    i            : Integer;

    dtStr        : String;

  begin

    new(logger);
    logger^.init;
    logger^.level := INFO;

    dtStr := date2Str(calDate^.yyyy, calDate^.mm, daysInMon, FALSE);

    new(endMonthDate);
    endMonthDate^.init;
    endMonthDate^.dtStr2Obj(dtStr);

    logger^.logLongInt(DEBUG, ' 1st epoch ', calDate^.epoch);
    logger^.logLongInt(DEBUG, 'last epoch ', endMonthDate^.epoch);

    for i := 0 to cal^.entries do
    begin

      (*  calDate is 1st of month *)
      if      (cal^.eventList[i]^.startDate^.epoch < endMonthDate^.epoch)
          and (cal^.eventList[i]^.endDate^.epoch   > calDate^.epoch)
      then
      begin
        logger^.logInt (DEBUG, 'IN Scope', i );
        FilterEvent(cal, calDate, daysInMon, i);
      end;

    end;  (* for *)

    Dispose (endMonthDate, Done);
    Dispose (logger, Done);

  end;


  procedure TCellGrid.FilterEvent(cal       : PCal;
                                  calDate   : PDateTime;
                                  daysInMon : Integer;
                                  e         : Integer);

  (* Purpose : Display a single event  *)

  var
    logger    : PLogger;

    row,
    col         : Integer;

    summ        : String;
    daysBetween : Real;

    j,
    sDate,
    eDate       : Integer;

  begin

    new(logger);
    logger^.init;
    logger^.level := INFO;

    daysBetween :=  (cal^.eventList[e]^.endDate^.epoch -
                     cal^.eventList[e]^.startDate^.epoch) / daySec;

    logger^.logReal(INFO, 'event lasts ', daysBetween);


    if (cal^.eventList[e]^.startDate^.mm = calDate^.mm)
    then
      sDate := cal^.eventList[e]^.startDate^.dd
    else
      sDate := 1;

    if (cal^.eventList[e]^.endDate^.mm = calDate^.mm)
    then
      eDate := cal^.eventList[e]^.endDate^.dd (** + round(daysBetween) **)
    else
      eDate := daysInMon;

    for j := sDate to eDate
    do
    begin
      logger^.logInt(INFO, 'event date ',  + j);

      calcCell (calDate^.day, j, row, col); 
      (* calcPos was here *)

      logger^.logInt (DEBUG, 'row ', row);
      logger^.logInt (DEBUG, 'col ', col);

      summ := SubStr (cal^.eventList[e]^.summary);
(*
      v_gtext(vdiHandle,
              newX + x + Attr.boxWidth,
              newY + y - Attr.boxHeight - 10 + cellGrid^.cells[j]^.count * Attr.boxHeight,
              summ );
*)
      logger^.log(DEBUG, 'Summary ' + cal^.eventList[e]^.summary );
      inc (cells[j]^.counter );
    end;

    Dispose(logger, Done);

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