{$I projopts.i}
{$mode objfpc}
{$modeswitch advancedrecords}

unit Event;

(* AUTHOR  : P Slegg
 * DATE    : 2020-05-16    Version 0
 *           2026-02-23    Version 1
 * Purpose : TEvent object for iCal Events.
 *)

interface
  uses
    Objects,
    Constant,
    DateStrc,
    IcsAlarm,
    RRule;

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

    alarm       : TAlarm;
    recurRule   : TRRule;

    constructor Create;
    destructor  Destroy; override;

    function GetEvent (VAR calFile : Text)
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
    SysUtils,
    StrUtils,
    DateUtils,
    Logger;

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
   * property-name;property-paramter:property-value
   * is divided into propName, paramStr, value
   *
   * sample of lines that are handled:
   *      UID:uid1@example.com
   *      DTSTART:19960918T143000Z
   *      DTEND;TZID=America/New_York:19980312T093000
   *      SUMMARY:Atari Conference
   *      END:VEVENT
   *)

  var
    currentLn    : String;

    endEvent     : Boolean;

    offset       : String;

    parts,
    leftParts    : TStringArray;

    propName,
    paramStr,
    value        : String;

  begin
    log.level := LLDEBUG;

    endEvent     := FALSE;

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
        // Split at the first colon into parts[] array
        parts := SplitString(currentLn, ':');

        if Length(parts) < 2
        then
        begin
          log.error('Invalid iCal Event', currentLn);
          Exit;
        end;

        // Split parts[0] at the semi-colon. i.e property-name;property-parameters
        leftParts := SplitString(parts[0], ';');
        propName  := leftParts[0];

        value     := parts[1];
        if Length(leftParts) > 1
        then
          paramStr := leftParts[1]
        else
          paramStr := '';    // No property-parameters

        case propName of
          CREATED_TK:
            created := value;

          UID_TK:
            uid := value;

          (*       propname = "DTSTART"
           *       paramStr = "TZID=Europe/London"
           *       value    = "20200516T000000"
           *)
          DTSTART_TK:
            begin
              dtStart   := value;
              dtStartTz := GetTimeZone(paramStr);
            end;

          DTEND_TK:
            begin
              dtEnd   := value;
              dtEndTz := GetTimeZone(paramStr);
            end;

          SUMMARY_TK:
            summary := value;

          DESCR_TK:
            description := value;

          LOCATION_TK:
            location := value;

          BEGIN_ALARM_TK:
            alarm.ParseAlarm(calFile);

          RECUR_RULE_TK:
            recurrule.ParseRRule(value, recurRule)
        end;  (* case *)

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
  (* Purpose : Return the time zone from the TZID string, e.g. "TZID=Europe/London" *)
  var
    parts    : TStringArray;

  begin
    // Split TZID at the Equals sign.
    parts := SplitString(TZIdString, '=');  // e.g. "TZID=Europe/London".

    if (parts[0] = TZID_TK)
    then
      GetTimeZone := parts[1]
    else
      GetTimeZone := '';
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

    WriteNN (alarm.alarmTrigger);
    
    WriteNN (recurRule.freq);

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
    
    daysInMon  : Word;

    startsBeforeMonthEnd,
    endsAfterMonthStart  : Boolean;

  begin
    log.level := LLDEBUG;

    isMonthEvent         := FALSE;
    startsBeforeMonthEnd := FALSE;
    endsAfterMonthStart  := FALSE;

    daysInMon := DaysInMonth(calDate);

    pStart := RecodeDay(calDate, 1);
    pstart := RecodeTime(pStart, 0, 0, 0, 000);
    
    pEnd   := RecodeDay(calDate, daysInMon);
    pEnd   := RecodeTime(pEnd, 23, 59, 59, 999);

    (* Does the event start/end overlap with the period start/end ?
     *  1: event starts before month end
     *  2: event ends   after  month start
     *  3: event starts before month and ends after the month
     *)
    (* start before pEnd *)
    if      (startDate.fpDateTime < pEnd )       // 1b: event starts before end of month
    then
      startsBeforeMonthEnd := TRUE;

    (* end after pStart *)
    if      (endDate.fpDateTime > pStart )       // 2a: event ends after 1st of month
    then
      endsAfterMonthStart := TRUE;
      
  log.debug('startsBeforeMonthEnd=', startsBeforeMonthEnd);
  log.debug('endsAfterMonthStart=', endsAfterMonthStart);
    if  (startsBeforeMonthEnd and endsAfterMonthStart)
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
    log.debug ('InScope: start date = ' , DateToISO8601(startDate.fpDateTime) );
    log.debug ('InScope: end date = ' ,   DateToISO8601(endDate.fpDateTime) );

    yearScopeStart := RecodeYear(calDate, YearOf(calDate) - 2);
    yearScopeEnd   := RecodeYear(calDate, YearOf(calDate) + 2);

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
