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
    CalCell;

  const
    NUMCELLS  = 31;

  type
    TCellGrid = class
      calCell    : array [1..NUMCELLS] of TCalCell;

      constructor Create;
      destructor  Destroy; override;

      procedure FilterEvents(cal       : TCal;
                             calDate   : TDateStruct);

      procedure FilterEvent(cal       : TCal;
                            calDate   : TDateStruct;
                            daysInMon : Integer;
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

  (* Purpose : Decide which Events should be displayed in the month
   *           cal     = iCal calendar
   *           calDate = date of 1st of month
   *)

  var
    endMonthDate : TDateStruct;
    i            : Integer;
    dtStr        : String;

  begin
    log.level := LLDEBUG;
    log.debug ('CELLGRID.FilterEvents');

    (* Calculate date of end of month *)
    dtStr := date2Str(YearOf(calDate), MonthOf(calDate), DaysInMonth(calDate), FALSE);
    log.debug('CELLGRID.FilterEvents end of Month ', dtStr);

    endMonthDate := TDateStruct.createFromIso(dtStr);
//    endMonthDate.dtStr2Obj(dtStr);

    log.debug('CELLGRID.FilterEvents  1st epoch= ', DateTimeToUnix(calDate) );
    log.debug('CELLGRID.FilterEvents last epoch= ', DateTimeToUnix(endMonthDate) );

    for i := 0 to cal.entries do
    begin

      (*  calDate is date of month to be displayed *)
      if      (cal.eventList[i].startDate.epoch < DateTimeToUnix(endMonthDate) )
          and (    (cal.eventList[i].endDate.epoch   > DateTimeToUnix(calDate) )
                or (cal.eventList[i].endDate.epoch = 0) )
      then
      begin
        log.debug ('CELLGRID: IN Scope', i );

        FilterEvent(cal, calDate, daysInMon, i);
      end;

    end;  (* for *)

    endMonthDate.free;
  end;


procedure TCellGrid.FilterEvent(cal       : TCal;
                                calDate   : TDateTime;
                                daysInMon : Integer;
                                e         : Integer);

  (* Purpose : Store a single event in the cellGrid *)

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
    log.debug ('FilterEvent: end date = ' , cal.eventList[e].endDate.getDDFromIso);
    log.debug ('FilterEvent: epoch', cal.eventList[e].endDate.epoch);

    daysBetween :=  (cal.eventList[e].endDate.epoch -
                     cal.eventList[e].startDate.epoch) / daySec;

    log.debug ('FilterEvent: event lasts ', daysBetween);

    (* Does the event Start in the displayed month ? *)
    if (cal.eventList[e].startDate.getMMFromIso = MonthOf(calDate) )
    then
      sDate := cal.eventList[e].startDate.getDDFromIso
    else
      sDate := 1;

    allDay := cal.eventList[e].endDate.isAllDay;

    (* Does the event End after the displayed month ? *)
    if (cal.eventList[e].endDate.getMMFromIso > MonthOf(calDate) )
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
      log.debug ('FilterEvent: event date ',  + j);
      log.debug ('FilterEvent: slot ', calCell[j].counter);
      
      cal.eventList[e].writeEvent;

      (* Abbreviate the Event summary and place it in a slot in the calCell *)
      summ  := Copy (cal.eventList[e].summary,  1, SUMMARY_LEN);
      locat := Copy (cal.eventList[e].location, 1, SUMMARY_LEN);

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