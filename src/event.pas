{$mode objfpc}
unit Event;

(* AUTHOR  : P Slegg
   DATE    : 2020-05-16    Version 0
             2026-02-23    Version 1
   PURPOSE : TEvent object for iCal Events.
*)

interface
  uses
    Objects,
    DateTime;


type
  TEvent = class
  public
    filename    : String;
    created     : String;
    summary     : String;
    description : String;
    dtStart     : String;
    dtStartTz   : String;
    dtEnd       : String;
    dtEndTz     : String;
    location    : String;

    startDate   : TDateTime;
    endDate     : TDateTime;

    alarmAction      : String;
    alarmTrigger     : String;
    alarmDescription : String;

    constructor Create;
    destructor  Destroy; override;

    Function GetEvent (VAR calFile : Text)
            : Boolean;

    Function GetAlarm (var calFile : Text)
            : Boolean;

    Procedure WriteEvent;

    Function isMonthEvent (y, m : Word)
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

  constructor TEvent.Create;
  begin
    filename    := '';
    created     := '';
    summary     := '';
    description := '';
    dtstart     := '';
    dtend       := '';
    location    := '';

    alarmAction      := '';
    alarmTrigger     := '';
    alarmDescription := '';

    startDate := TDateTime.create;
    endDate   := TDateTime.create;
  end;

  destructor TEvent.Destroy;
  begin
    startDate.Free;
    endDate.Free;
    inherited destroy;
  end;


  Function TEvent.GetEvent (VAR calFile : Text)
          : Boolean;

  (*
   * Purpose : Get one iCS event.
   *)

  var
    log          : TLogger;

    convStr      : String;

    currentLn    : String;

    alarm        : Boolean;
    endEvent     : Boolean;

    tokens       : TToken;

  begin
    log := TLogger.Create(LLINFO);

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
        tokens.Create;
        tokens.tokeniseIcal(currentLn);

        if ( pos(createdTk, tokens.part[0]) = 1 )
        then
          created := tokens.part[2];

        if ( pos(dtStartTk, tokens.part[0]) = 1 )
        then
        begin
          dtStart   := tokens.part[2];
          dtStartTz := tokens.part[1];
        end;

        if ( pos(dtEndTk, tokens.part[0]) = 1 )
        then
        begin
          dtEnd   := tokens.part[2];
          dtEndTz := tokens.part[1];
        end;

        if ( pos(SummaryTk, tokens.part[0]) = 1 )
           and (NOT alarm)
        then
          summary := tokens.part[2];

        if ( pos(descrTk, tokens.part[0]) = 1 )
           and (NOT alarm)
        then
          description := tokens.part[2];

        if ( pos(locationTk, tokens.part[0]) = 1 )
           and (NOT alarm)
        then
          location := tokens.part[2];

        if (NOT alarm)
            and (pos(beginAlarmTk, tokens.part[0]) = 1 )
        then
        begin
          alarm := GetAlarm(calFile);
        end;

        if (pos(endAlarmTk, tokens.part[0]) = 1 )
        then
          alarm := FALSE;

        tokens.Free;

      end;  (* if *)

    end;  (* while *)


    if (length(dtStart) > 0)
    then
    begin
      startDate.dtStr2Obj(dtStart);
    end;


    if (length(dtEnd) > 0)
    then
    begin
      endDate.dtStr2Obj(dtEnd);
    end
    else
    begin
      endDate.dtStr2Obj(dtStart);
    end;

    GetEvent := TRUE;
    (*writeEvent;*)

    log.Free;
  end;


  Function TEvent.GetAlarm (var calFile : Text)
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


  Procedure WriteNN(myString : String);
  begin
    if (length(myString) > 0 )
    then
      writeln (myString);
  end;


  Procedure TEvent.WriteEvent;

  begin
    write('Event on     : ');
    startDate.writeDT;

    WriteNN (summary);
    WriteNN (description);

    write('Location     : ');
    WriteNN (location);

    WriteNN (alarmTrigger);

    write('Event ends   : ');
    endDate.writeDT;
  end;


  Function TEvent.isMonthEvent (y, m : Word)
          : Boolean;

  (* Purpose : Determine if thisEvent falls within the period (month)
   *           There are 4 cases in the period:
   *           1: overlap start of period
   *           2: contained within period
   *           3: overlap end of period
   *           4: start before, end after period
   *
   *           and 2 cases outside the period:
   *           5: start/end before period
   *           6: start/end after period
   *)

  var
    pStart,
    pEnd   : TDateTime;

    daysInMon : Integer;

  begin
    isMonthEvent := FALSE;

    pStart := TDateTime.create;
    pStart.dtStr2Obj(date2Str(y, m, 1, FALSE) + ' ' + time2Str(0, 0, 0, FALSE) );

    daysInMon := daysMon[m];
    if (m = 2) and (isLeapDay(y))
    then
      daysInMon := 29;

    pEnd := TDateTime.create;
    pEnd.dtStr2Obj(date2Str(y, m, daysInMon, FALSE) + ' ' + time2Str(23, 59, 59, FALSE) );

    (* Does the event start/end overlap with the period start/end ? *)

    if      (startDate.epoch > pStart.epoch)
        and (startDate.epoch < pEnd.epoch)
      or
            (endDate.epoch > pStart.epoch)
        and (endDate.epoch < pEnd.epoch)
      or
            (startDate.epoch < pStart.epoch)
        and (endDate.epoch   > pEnd.epoch)
    then
    begin
      isMonthEvent := TRUE;
      writeln ('Current event');
    end;

    pStart.Free;
    pEnd.Free;
  end;


end.