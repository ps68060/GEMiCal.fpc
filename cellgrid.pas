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
      cell    : array [1..NUMCELLS] of PCalCell;

      constructor init;
      destructor  done; virtual;

      procedure FilterEvents(cal       : PCal;
                             calDate   : PDateTime);

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
      new (cell[i]);
      cell[i]^.init;
      cell[i]^.counter := 0;
    end;

  end;

  destructor TCellGrid.done;
  var
    i : Integer;

  begin
    for i := 1 to NUMCELLS
    do
    begin
      dispose(cell[i], Done);
    end;
  end;


  function SubStr(myStr : String)
          : String;
  begin
    SubStr := Copy(myStr, 1, 16);
  end;


  procedure TCellGrid.FilterEvents(cal       : PCal;
                                   calDate   : PDateTime);

  (* Purpose : Decide which Events should be displayed in the month
               cal     = iCal calendar
               calDate = date of 1st of month *)
  var
    logger       : PLogger;

    endMonthDate : PDateTime;
    daysInMon    : Integer;

    i            : Integer;

    dtStr        : String;

  begin

    new(logger);
    logger^.init;
    logger^.level := INFO;

    logger^.log (DEBUG, 'FilterEvents');

    (* Calculate date of end of month *)
    daysInMon := daysInMonth(calDate);

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

  (* Purpose : Store a single event in the cellGrid *)

  var
    logger      : PLogger;

    summ        : String;
    daysBetween : Real;

    j,
    sDate,
    eDate       : Integer;

  begin

    new(logger);
    logger^.init;
    logger^.level := INFO;

    logger^.logInt(DEBUG, 'end date = ' , cal^.eventList[e]^.endDate^.dd);

    daysBetween :=  (cal^.eventList[e]^.endDate^.epoch -
                     cal^.eventList[e]^.startDate^.epoch) / daySec;

    logger^.logReal(DEBUG, 'event lasts ', daysBetween);

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
      logger^.logInt(DEBUG, 'event date ',  + j);
      logger^.logInt(DEBUG, 'slot ', cell[j]^.counter);

      (* Abbreviate the Event summary and place it in a slot in the Cell *)
      summ := SubStr (cal^.eventList[e]^.summary);
      cell[j]^.summary[cell[j]^.counter] := summ;

      logger^.log(DEBUG, 'Summary ' +
                  cell[j]^.summary[cell[j]^.counter] );

      cell[j]^.eventNum := e;

      inc (cell[j]^.counter );
    end;

    dec (cell[eDate]^.counter );

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