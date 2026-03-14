{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}
{$mode objfpc}

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
    TCellGrid = class
    public
      cell    : array [1..NUMCELLS] of TCalCell;

      constructor Create;
      destructor  Destroy; override;

      procedure FilterEvents(cal       : TCal;
                             calDate   : TDateTime);

      procedure FilterEvent(cal       : TCal;
                            calDate   : TDateTime;
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

  constructor TCellGrid.Create;
  var
    i : Integer;

  begin
    for i := 1 to NUMCELLS
    do
    begin
      cell[i].Create;
    end;

  end;

  destructor TCellGrid.Destroy;
  var
    i : Integer;

  begin
    for i := 1 to NUMCELLS
    do
    begin
      cell[i].Free;
    end;
    
    inherited destroy;

  end;


  function SubStr(myStr : String)
          : String;
  begin
    SubStr := Copy(myStr, 1, 30);
  end;


  procedure TCellGrid.FilterEvents(cal       : TCal;
                                   calDate   : TDateTime);

  (* Purpose : Decide which Events should be displayed in the month
   *           cal     = iCal calendar
   *           calDate = date of 1st of month
   *)
  var
    log          : TLogger;

    endMonthDate : TDateTime;
    daysInMon    : Integer;

    i            : Integer;

    dtStr        : String;

  begin

    log := TLogger.Create(LLINFO);

    log.debug ('FilterEvents');

    (* Calculate date of end of month *)
    daysInMon := daysInMonth(calDate);

    dtStr := date2Str(calDate.getYYYYFromIso, calDate.getMMFromIso, daysInMon, FALSE);

    endMonthDate := TDateTime.create;
    endMonthDate.dtStr2Obj(dtStr);

    log.debug(' 1st epoch ', calDate.epoch);
    log.debug('last epoch ', endMonthDate.epoch);

    for i := 0 to cal.entries do
    begin

      (*  calDate is 1st of month *)
      if      (cal.eventList[i].startDate.epoch < endMonthDate.epoch)
          and (    (cal.eventList[i].endDate.epoch   > calDate.epoch)
                or (cal.eventList[i].endDate.epoch = 0) )
      then
      begin
        log.debug ('IN Scope', i );

        FilterEvent(cal, calDate, daysInMon, i);
      end;

    end;  (* for *)

    endMonthDate.Free;
    log.Free;
  end;


  procedure TCellGrid.FilterEvent(cal       : TCal;
                                  calDate   : TDateTime;
                                  daysInMon : Integer;
                                  e         : Integer);

  (* Purpose : Store a single event in the cellGrid *)

  var
    log         : TLogger;

    summ,
    locat       : String;

    daysBetween : Real;

    allDay      : Boolean;

    j,
    sDate,
    eDate       : Integer;

  begin

    log := TLogger.Create(LLINFO);

    log.debug ('end date = ' , cal.eventList[e].endDate.getDDFromIso);

    daysBetween :=  (cal.eventList[e].endDate.epoch -
                     cal.eventList[e].startDate.epoch) / daySec;

    log.debug ('event lasts ', daysBetween);


    (* Does the event Start in the displayed month ? *)

    if (cal.eventList[e].startDate.getMMFromIso = calDate.getMMFromIso)
    then
      sDate := cal.eventList[e].startDate.getDDFromIso
    else
      sDate := 1;


    allDay := cal.eventList[e].endDate.isAllDay;

    (* Does the event End after the displayed month ? *)
    if (cal.eventList[e].endDate.getMMFromIso > calDate.getMMFromIso)
    then
      eDate := daysInMon

    else
      (* All Day events *)
      if     (allDay)
      then
        eDate := sDate
      else
        eDate := cal.eventList[e].endDate.getDDFromIso;


    (* Iterate days and put info into cells. *)

    for j := sDate to eDate
    do
    begin
      log.debug ('event date ', j);
      log.debug ('slot ', cell[j].counter);

      (* Abbreviate the Event summary and place it in a slot in the Cell *)
      summ := SubStr (cal.eventList[e].summary);
      cell[j].cellEvents[cell[j].counter].summary   := summ;

      locat := SubStr (cal.eventList[e].location);
      cell[j].cellEvents[cell[j].counter].location  := locat;

      cell[j].cellEvents[cell[j].counter].timeStart.dtStr2Obj(cal.eventList[e].dtStart);

      log.log(LLDEBUG, 'Summary ' +
                  cell[j].cellEvents[cell[j].counter].summary );

      cell[j].eventNum := e;

      inc (cell[j].counter );
    end;

    log.Free;

  end;


  procedure CalcCell(day,
                     firstDay : Integer;
                     var row,
                         col : Integer);
  (* Purpose : Calculate the row and column of the calendar day
   * inputs  : firstDay = the day number of the 1st of the month
   *           day      = the date in the month
   * returns:  row 0 to 6
   *           col 0 to 5
   *)

  var
    log       : TLogger;

  begin

    log := TLogger.Create(LLINFO);

    row := (day - 1 + firstDay) div 7;
    col := (day - 1 + firstDay) mod 7;

    log.debug ('day ', day);
    log.debug ('row ', row);
    log.debug ('col ', col);

    log.Free;
  end;

end.