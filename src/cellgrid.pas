{$I projopts.i}
{$mode objfpc}

unit CellGrid;

(* PURPOSE: Cell-Grid - array of days of the month holding events (TCalCell). 
 *)

interface

  uses
    Objects,

    Cal,
    DateStrc,
    CalCell,
    DateUtils,
    SysUtils;

  const
    NUMCELLS  = 31;

  type
    TCellGrid = class
      calCell    : array [1..NUMCELLS] of TCalCell;

      constructor Create;
      destructor  Destroy; override;

      procedure FilterEvents(cal       : TCal;
                             calDate   : TDateTime);

      procedure FilterEvent(event     : TEvent;
                            calDate   : TDateTime;
                            e         : Integer);
    end;


    procedure CalcCellGrid(day,
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
      calCell[i] := TCalCell.Create;
    end;

  end;

destructor TCellGrid.Destroy;
  var
    i : Integer;

  begin
    for i := 1 to NUMCELLS
    do
    begin
      calCell[i].Free;
    end;

    inherited Destroy;
  end;


procedure TCellGrid.FilterEvents(cal       : TCal;
                                 calDate   : TDateTime);

  (* Purpose : Decide which Events should be displayed in the focus month defined by calDate.
   *           cal     = iCal calendar
   *           calDate = date of 1st of focus month
   *
   *           For each event in the calendar, check if it is in the month to be displayed.
   *           If it is, then call FilterEvent to get the event details and
   *           store the events in the cellGrid.
   *)

  var
    endMonthDate : TDateTime;
    i            : Integer;
    dtStr        : String;

  begin
    log.level := LLDEBUG;
    log.debug ('CELLGRID.FilterEvents');

    (* Calculate date of end of month *)
    dtStr := date2Str(YearOf(calDate), MonthOf(calDate), DaysInMonth(calDate), FALSE);
    log.debug('CELLGRID.FilterEvents end of Month ', dtStr);

    endMonthDate := ISO8601ToDate(dtStr);
//    endMonthDate.dtStr2Obj(dtStr);

    log.debug('CELLGRID.FilterEvents  1st epoch= ', DateTimeToUnix(calDate) );
    log.debug('CELLGRID.FilterEvents last epoch= ', DateTimeToUnix(endMonthDate) );

    for i := 0 to cal.entries do
    begin

      (*  calDate is 1st date of focus month to be displayed *)
      if (cal.eventList[i].IsMonthEvent(YearOf(calDate), MonthOf(calDate)))
      then
      begin
        log.debug ('CELLGRID: IN Scope', i );

        FilterEvent(cal.eventList[i], calDate, i);
      end;

    end;  (* for *)
  end;


procedure TCellGrid.FilterEvent(event     : TEvent;
                                calDate   : TDateTime;
                                e         : Integer);

  (* Purpose : Store a single event in the cellGrid
   *           cal     = iCal calendar
   *           calDate = date of 1st of month
   *           e       = event number in calendar
   *           Check event, if it starts in the month to be displayed. If not, then use 1st of month as start date.
   *           Check event, if it ends in the month to be displayed.   If not, then use last day of month as end date.
   *           Iterate through the days of the event and store the event summary and location in the cellGrid for each day.
   *)

  const
    SUMMARY_LEN = 30;

  var
    summ,
    locat       : String;

    daysBetween : Real;

    allDay      : Boolean;

    j,
    sDate,
    eDate       : Integer;

  begin
    log.level := LLDEBUG;
    log.debug ('FilterEvent: end date = ' , event.endDate.getDDFromIso);
    log.debug ('FilterEvent: epoch', event.endDate.epoch);

    daysBetween :=  (event.endDate.epoch -
                     event.startDate.epoch) / daySec;

    log.debug ('FilterEvent: event lasts ', daysBetween);

    (* Does the event Start in the displayed month ? *)
    if (event.startDate.getMMFromIso = MonthOf(calDate) )
    then
      sDate := event.startDate.getDDFromIso
    else
      sDate := 1;

    allDay := event.endDate.isAllDay;

    (* Does the event End after the displayed month ? *)
    if (event.endDate.getMMFromIso > MonthOf(calDate) )
    then
      eDate := DaysInMonth(calDate)

    else
      (* All Day events *)
      if     (allDay)
      then
        eDate := sDate
      else
        eDate := event.endDate.getDDFromIso;


    (* Iterate days and put info into cells. *)
    for j := sDate to eDate
    do
    begin
      log.debug ('FilterEvent: event date ',  + j);
      log.debug ('FilterEvent: slot ', calCell[j].counter);
      
      event.writeEvent;

      (* Abbreviate the Event summary and place it in a slot in the calCell *)
      summ  := Copy (event.summary,  1, SUMMARY_LEN);
      locat := Copy (event.location, 1, SUMMARY_LEN);

      calCell[j].cellEvents[calCell[j].counter]
                  .summary   := summ;

      calCell[j].cellEvents[calCell[j].counter]
                  .location  := locat;

      calCell[j].cellEvents[calCell[j].counter]
                  .timeStart.dtStr2Obj(cal.eventList[e].dtStart);

      log.debug( 'FilterEvent: Summary ' +
                 calCell[j].cellEvents[calCell[j].counter].summary );

      calCell[j].eventNum := e;

      inc (calCell[j].counter );
    end;

  end;


procedure CalcCellGrid(day,
                       firstDay : Integer;
                       var row,
                           col : Integer);
  (* Purpose : Calculate the row and column of the calendar day
   * inputs  : firstDay = the day number of the 1st of the month
   *           day      = the date in the month
   * returns:  row 0 to 5
   *           col 0 to 6
   *)

  begin
    log.level := LLINFO;
    row := (day - 1 + firstDay) div 7;
    col := (day - 1 + firstDay) mod 7;

    log.debug ('CELLGRID: day ', day);
    log.debug ('CELLGRID: row ', row);
    log.debug ('CELLGRID: col ', col);

  end;

end.