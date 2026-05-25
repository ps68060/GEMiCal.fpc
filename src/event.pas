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
    summary     : String;
    description : String;
    dtStart     : String;
    dtStartTz   : String;
    dtEnd       : String;
    dtEndTz     : String;
    location    : String;

    startDate   : TDateStruct;
    endDate     : TDateStruct;

    alarmAction      : String;
    alarmTrigger     : String;
    alarmDescription : String;

    constructor create;
    destructor  destroy; override;

    Function GetEvent (VAR calFile : Text)
            : Boolean;

    Function GetAlarm (var calFile : Text)
            : Boolean;

    Procedure WriteEvent;

    Function IsMonthEvent (calDate : TDateTime)
            : Boolean;
  end;


implementation

  uses
    Token,
    Logger;

  const
    endEventTk   = 'END:VEVENT';
    createdTk    = 'CREATED';
    dtStartTk    = 'DTSTART';
    dtEndTk      = 'DTEND';
    SummaryTk    = 'SUMMARY';
    descrTk      = 'DESCRIPTION';
    locationTk   = 'LOCATION';
    recurRuleTk  = 'RRULE';

    beginAlarmTk  = 'BEGIN:VALARM';
    endAlarmTk    = 'END:VALARM';
    triggerTk     = 'TRIGGER:';
    alarmDescTk   = 'DESCRIPTION:';
    alarmActionTk = 'ACTION:';

constructor TEvent.create;
  begin
    filename    := '';
    created     := '';
    summary     := '';
    description := '';
    dtstart     := '';
    dtstartTz   := '';
    dtend       := '';
    dtendTz     := '';
    location    := '';

    alarmAction      := '';
    alarmTrigger     := '';
    alarmDescription := '';

    startDate := TDateStruct.create;
    endDate   := TDateStruct.create;
  end;

destructor TEvent.destroy;
  begin
    startDate.free;
    endDate.free;

    inherited destroy;
  end;


function TEvent.GetEvent (VAR calFile : Text)
        : Boolean;

  (*
   * Purpose : Get one iCS event.
   *)

  var
    convStr      : String;
    currentLn    : String;

    alarm        : Boolean;
    endEvent     : Boolean;

    tokens       : TToken;

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
      if ( pos(endEventTk, currentLn) = 1 )
      then
      begin
        endEvent := TRUE;
      end

      else
      begin
        tokens := TToken.Create;
        tokens.tokeniseIcal(currentLn);

        if (tokens.StartsWith(createdTk))
        then
          created := tokens.part[2];

        if (tokens.StartsWith(dtStartTk))
        then
        begin
          dtStart   := tokens.part[2];
          dtStartTz := tokens.part[1];
        end;

        if ( tokens.StartsWith(dtEndTk))
        then
        begin
          dtEnd   := tokens.part[2];
          dtEndTz := tokens.part[1];
        end;

        if ( tokens.StartsWith(SummaryTk))
           and (NOT alarm)
        then
          summary := tokens.part[2];

        if ( tokens.StartsWith(descrTk))
           and (NOT alarm)
        then
          description := tokens.part[2];

        if ( tokens.StartsWith(locationTk))
           and (NOT alarm)
        then
          location := tokens.part[2];

        if (NOT alarm )
            and (tokens.StartsWith(beginAlarmTk))
        then
          alarm := GetAlarm(calFile);

        if (tokens.StartsWith(endAlarmTk))
        then
          alarm := FALSE;

        tokens.Free;

      end;  (* if *)

    end;  (* while *)


    if (length(dtStart) > 0)
    then
    begin
      startDate.CreateFromISO(dtStart);
    end;

    if (length(dtEnd) > 0)
    then
    begin
      endDate.CreateFromISO(dtEnd);
    end
    else
    begin
      endDate.CreateFromISO(dtStart);
    end;

    GetEvent := TRUE;
    writeEvent;

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
      if ( pos(endAlarmTk, currentLn) = 1 )
      then
      begin

        endAlarm := TRUE;

      end
      else
      begin

        if (pos(triggerTk, currentLn) = 1 )
        then
          alarmTrigger := COPY (currentLn, 9, length(currentLn));

        if (pos(alarmActionTk, currentLn) = 1 )
        then
          alarmAction  := COPY (currentLn, 8, length(currentLn));

        if (pos(alarmDescTk, currentLn) = 1 )
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


procedure TEvent.WriteEvent;

  begin
    write('Event on     : ');
    startDate.WriteDateStrc;

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

end.
