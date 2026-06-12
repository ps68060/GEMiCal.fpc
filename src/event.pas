{$I projopts.i}
{$mode objfpc}

unit Event;

(* AUTHOR  : P Slegg
 * DATE    : 2020-05-16    Version 0
 *           2026-02-23    Version 1
 * Purpose : TEvent object for iCal Events.
 *)

interface
  uses
    Objects,
    DateStrc,
    DateUtils;


type
  TEvent = class
    filename    : String;
    created     : String;
    uid         : String;
    summary     : String;
    description : String;
    dtStart     : String;
    dtStartTz   : String;
    allDay      : Boolean;
    dtEnd       : String;
    dtEndTz     : String;
    location    : String;

    startDate   : TDateStruct;
    endDate     : TDateStruct;

    alarmAction      : String;
    alarmTrigger     : String;
    alarmDescription : String;

    constructor Create;
    destructor  Destroy; override;

    function GetEvent (VAR calFile : Text)
            : Boolean;

    function GetAlarm (var calFile : Text)
            : Boolean;

    procedure DebugEvent;

    function IsMonthEvent (calDate : TDateTime)
            : Boolean;

  function InScope(calDate : TDateTime)
          : Boolean;
    procedure SaveEvent(var calFile : Text);

    function GetTimeZone(TZIdString: String)
            : String;
  end;


implementation

  uses
    Token,
    Logger;

  const
    BEGIN_EVENT_TK = 'BEGIN:VEVENT';
    END_EVENT_TK   = 'END:VEVENT';

    CREATED_TK    = 'CREATED';
    UID_TK        = 'UID';

    DTSTART_TK    = 'DTSTART';
    DTEND_TK      = 'DTEND';
    TZID_TK       = 'TZID';

    SUMMARY_TK    = 'SUMMARY';
    DESCR_TK      = 'DESCRIPTION';
    LOCATION_TK   = 'LOCATION';
    RECUR_RULE_TK = 'RRULE';

    BEGIN_ALARM_TK  = 'BEGIN:VALARM';
    END_ALARM_TK    = 'END:VALARM';
    TRIGGER_TK      = 'TRIGGER:';
    ALARM_DESC_TK   = 'DESCRIPTION:';
    ALARM_ACTION_TK = 'ACTION:';

constructor TEvent.Create;
  begin
    filename    := '';
    created     := '';
    uid         := '';
    summary     := '';
    description := '';
    dtstart     := '';
    dtstartTz   := '';
    allDay      := TRUE;
    dtend       := '';
    dtendTz     := '';
    location    := '';

    alarmAction      := '';
    alarmTrigger     := '';
    alarmDescription := '';

    startDate := TDateStruct.create;
    endDate   := TDateStruct.create;
  end;

destructor TEvent.Destroy;
  begin
    startDate.free;
    endDate.free;

    inherited Destroy;
  end;


function TEvent.GetEvent (VAR calFile : Text)
        : Boolean;

  (*
   * Purpose : Get one iCS event.
   *)

  var
    currentLn    : String;

    alarm        : Boolean;
    endEvent     : Boolean;

    tokens       : TToken;
    offset       : String;

  begin
    log.level := LLINFO;

    endEvent     := FALSE;
    alarm        := FALSE;

    while (NOT eof (calFile) 
           AND NOT endEvent )
    do
    begin

      readln ( calFile, currentLn );
      log.debug(currentLn);

      (* Look for End Event *)
      if ( pos(END_EVENT_TK, currentLn) = 1 )
      then
      begin
        endEvent := TRUE;
      end

      else
      begin
        tokens := TToken.Create;
        tokens.tokeniseIcal(currentLn);  // Split string at : and ; and store in tokens.part[0..n]

        if (tokens.StartsWith(CREATED_TK))
        then
          created := tokens.part[2];

        if (tokens.StartsWith(UID_TK))
        then
          uid := tokens.part[2];

        if (tokens.StartsWith(DTSTART_TK))
        then
        begin
          (*       part[0] = "DTSTART"
           *       part[1] = "TZID=Europe/London"
           *       part[2] = "20200516T000000"
           *)
          dtStart   := tokens.part[2];
          dtStartTz := GetTimeZone(tokens.part[1]);
        end;

        if (tokens.StartsWith(DTEND_TK))
        then
        begin
          dtEnd   := tokens.part[2];
          dtEndTz := GetTimeZone(tokens.part[1]);
        end;

        if ( tokens.StartsWith(SUMMARY_TK))
           and (NOT alarm)
        then
          summary := tokens.part[2];

        if ( tokens.StartsWith(DESCR_TK))
           and (NOT alarm)
        then
          description := tokens.part[2];

        if ( tokens.StartsWith(LOCATION_TK))
           and (NOT alarm)
        then
          location := tokens.part[2];

        if (NOT alarm )
            and (tokens.StartsWith(BEGIN_ALARM_TK))
        then
          alarm := GetAlarm(calFile);

        if (tokens.StartsWith(END_ALARM_TK))
        then
          alarm := FALSE;

        tokens.Free;

      end;  (* if *)

    end;  (* while *)


    if (length(dtStart) > 0)
    then
    begin
      startDate.CreateFromISO(dtStart);

      if (length(dtStartTz) > 0)
      then
      begin
        offset := TimeZoneToOffset(dtStart, startDate.fpDateTime);
        dtStart := Concat(dtStart, offset);
        log.debug('Time with Offset=', dtStart);
      end;  

      if (pos(dtStart, 'T') = 0)  // No time so it is an all day event
      then
        allDay := TRUE
      else
        allDay := FALSE;

    end;

    if (length(dtEnd) > 0)
    then
    begin
      endDate.CreateFromISO(dtEnd);

      if (length(dtEndTz) > 0)
      then
      begin
        offset := TimeZoneToOffset(dtEnd, endDate.fpDateTime);
        dtEnd := Concat(dtEnd, offset);
        log.debug('Time with Offset=', dtEnd);
      end;
    end

    else
    begin
      endDate.CreateFromISO(dtStart);
    end;

    GetEvent := TRUE;
    DebugEvent;

  end;


function TEvent.GetTimeZone(TZIdString: String)
        : String;
  begin
    (* Purpose : Return the time zone from the TZID string, e.g. "TZID=Europe/London" *)
    subtokens := TToken.Create;
    subtokens.TokeniseInf(TZIdString); // e.g. "TZID=Europe/London".  Split string at =

    if (subTokens.StartsWith(TZID_TK))
    then
      GetTimeZone := subTokens.part[2]
    else
      GetTimeZone := '';

    subTokens.Destroy;
  end;

function TEvent.GetAlarm (var calFile : Text)
        : Boolean;
  var
    currentLn    : String;

    endAlarm     : Boolean;

  begin
    endAlarm := FALSE;

    while (NOT eof (calFile) 
           AND NOT endAlarm )
    do
    begin

      readln ( calFile, currentLn );

      (* Look for End Alarm *)
      if ( pos(END_ALARM_TK, currentLn) = 1 )
      then
      begin

        endAlarm := TRUE;

      end
      else
      begin

        if (pos(TRIGGER_TK, currentLn) = 1 )
        then
          alarmTrigger := COPY (currentLn, 9, length(currentLn));

        if (pos(ALARM_ACTION_TK, currentLn) = 1 )
        then
          alarmAction  := COPY (currentLn, 8, length(currentLn));

        if (pos(ALARM_DESC_TK, currentLn) = 1 )
        then
          alarmDescription := COPY (currentLn, 13, length(currentLn));

      end;  (* if *)

    end;  (* while *)

    GetAlarm := TRUE;
  end;


procedure WriteNN(myString : String);
  begin
    if (length(myString) > 0 )
    then
      writeln (myString);
  end;


procedure TEvent.DebugEvent;

  begin
    write('Event on     : ');
    startDate.WriteDateStrc;
    
    write('uid          : ');
    WriteNN (uid);

    WriteNN (summary);
    WriteNN (description);

    write('Location     : ');
    WriteNN (location);

    WriteNN (alarmTrigger);

    write('Event ends   : ');
    endDate.WriteDateStrc;
  end;


function TEvent.IsMonthEvent(calDate : TDateTime)
        : Boolean;

  (* Purpose : Determine if thisEvent falls within the period (month)
   *           There are 4 cases in the period:
   *           1a: overlap start of period
   *           1b: contained within period
   *           2a: overlap end of period
   *           2b: start before, end after period
   *
   *           and 2 cases outside the period:
   *           5: start/end before period
   *           6: start/end after period
   *)

  var
    pStart,
    pEnd       : TDateTime;
    
    pStartUnix,
    pEndUnix   : Int64;

    daysInMon  : Word;

    startsBeforeMonthEnd,
    endsAfterMonthStart : Boolean;

  begin
    log.level := LLDEBUG;

    isMonthEvent := FALSE;
    daysInMon := DaysInMonth(calDate);

    pStart := RecodeDay(calDate, 1);
    pstart := RecodeTime(calDate, 0, 0, 0, 000);
    
    pEnd   := RecodeTime(calDate, 23, 59, 59, 999);
    pEnd   := RecodeDay(calDate, daysInMon);

    pStartUnix := DateTimeToUnix(pStart, false);
    PEndUnix   := DateTimeToUnix(pEnd,   false);

    (* Does the event start/end overlap with the period start/end ?
     *  1: event starts before month end
     *  2: event ends   after  month start
     *  3: event starts before month and ends after the month
     *)
  log.debug('Event.IsMonth startDate=', startDate.fpDateTime);
  log.debug('Event.IsMonth   endDate=', endDate.fpDateTime);

  log.debug('Event.IsMonth pStart=', pStart);
  log.debug('Event.IsMonth   pEnd=', pEnd);

    (* start before pEnd *)
    if      (startDate.epoch < pEndUnix )       // 1b: event starts before end of month
    then
      startsBeforeMonthEnd := true;

    (* end after pStart *)
    if      (endDate.epoch > pStartUnix )       // 2a: event ends after 1st of month
    then
      endsAfterMonthStart := true;

  log.debug('startsBeforeMonthEnd=', startsBeforeMonthEnd);
  log.debug('endsAfterMonthStart=', endsAfterMonthStart);
    if (startsBeforeMonthEnd and endsAfterMonthStart)
    then
    begin
      isMonthEvent := TRUE;
      writeln ('Current event');
    end;

  end;


function TEvent.InScope(calDate : TDateTime)
        : Boolean;
  (* Purpose : Decide if the event is in scope for display in the calendar.
   *           calDate = date of 1st of month to be displayed
   *
   *           For now, the scope is defined as events that start within 2 years before or after the month to be displayed.
   *           This is to avoid displaying events that are too far in the past or future.
   *)
  var
    yearScopeStart,
    yearScopeEnd   : TDateTime;

  begin
    log.level := LLDEBUG;
    log.debug ('InScope: start date = ' , DateToISO8601(event.startDate.fpDateTime) );
    log.debug ('InScope: end date = ' ,   DateToISO8601(event.endDate.fpDateTime) );

    yearScopeStart := RecodeYear(calYearOf(calDate) - 2);
    yearScopeEnd   := RecodeYear(calYearOf(calDate) + 2);

    if (startDate.fpDateTime >= yearScopeStart) and
       (startDate.fpDateTime <= yearScopeEnd)
    then
      InScope := TRUE
    else
      InScope := FALSE;
  end;


procedure TEvent.SaveEvent(var calFile : Text);
  (*
   * Purpose : Write the event to the calendar file.
   *)
  begin
    writeln(calFile, BEGIN_EVENT_TK);
    writeln(calFile, CREATED_TK,  ':', created);
    writeln(calFile, UID_TK,      ':', uid);
    writeln(calFile, DTSTART_TK,  ':', dtStart);

    if (NOT allDay)
    then
      writeln(calFile, DTEND_TK,    ':', dtEnd);

    writeln(calFile, SUMMARY_TK,  ':', summary);
    writeln(calFile, DESCR_TK,    ':', description);
    writeln(calFile, LOCATION_TK, ':', location);
    writeln(calFile, END_EVENT_TK);
  end;

end.
