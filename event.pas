{$B+,D-,I-,L-,N-,P-,Q-,R+,S-,T-,V-,X+,Z-}

unit Event;

(* AUTHOR  : P Slegg
   DATE    : 16th May 2020 Version 0
   PURPOSE : TEvent object for iCal Events.
*)

interface
  uses
    Objects,
    DateTime,
    Logger;


type
  PEvent = ^TEvent;
  TEvent = object(TObject)
    created     : String;
    summary     : String;
    description : String;
    dtStart     : String;
    dtEnd       : String;
    location    : String;

    startDate   : PDateTime;
    endDate     : PDateTime;

    alarmAction      : String;
    alarmTrigger     : String;
    alarmDescription : String;

    constructor init;
    destructor  done; virtual;

    Function GetEvent (VAR calFile : Text)
            : Boolean;

    Function GetAlarm (var calFile : Text)
            : Boolean;

    Procedure WriteEvent;

    Function isMonthEvent (y, m : Word)
            : Boolean;
  end;


implementation

  constructor TEvent.init;
  begin
    created     := '';
    summary     := '';
    description := '';
    dtstart     := '';
    dtend       := '';
    location    := '';

    alarmAction      := '';
    alarmTrigger     := '';
    alarmDescription := '';

    new (startDate);
    startDate^.init;

    new (endDate);
    endDate^.init;
  end;

  destructor TEvent.done;
  begin
    Dispose(startDate, Done);
    Dispose(endDate, Done);
  end;


  Function TEvent.GetEvent (VAR calFile : Text)
          : Boolean;

  (*
    Purpose : Get one iCS event.
   *)

  var
    logger       : PLogger;

    checkEnd,
    convStr      : String;

    currentLn    : String;

    alarm        : Boolean;
    endEvent     : Boolean;

  begin
    new(logger);
    logger^.init;

    logger^.level := INFO;

    checkEnd     := 'END:VEVENT';
    endEvent     := FALSE;
    alarm        := FALSE;

    while (NOT eof (calFile) 
           AND NOT endEvent )
    do
    begin

      readln ( calFile, currentLn );
      logger^.log (DEBUG, currentLn);

      (* Look for End Event *)
      if ( pos(checkEnd, currentLn) = 1 )
      then
      begin

        endEvent := TRUE;

      end
      else
      begin
        if ( pos('CREATED:', currentLn) = 1 )
        then
          created := COPY (currentLn, 9, length(currentLn));

        if ( pos('DTSTART', currentLn) = 1 )
        then
          dtStart := COPY (currentLn, pos(':', currentLn)+1, length(currentLn));

        if ( pos('DTEND', currentLn) = 1 )
        then
          dtEnd   := COPY (currentLn, pos(':', currentLn)+1, length(currentLn));

        if ( pos('SUMMARY', currentLn) = 1 )
           and (NOT alarm)
        then
          summary := COPY (currentLn, pos(':', currentLn)+1, length(currentLn));

        if ( pos('DESCRIPTION:', currentLn) = 1 )
           and (NOT alarm)
        then
          description := COPY (currentLn, 13, length(currentLn));

        if ( pos('LOCATION:', currentLn) = 1 )
           and (NOT alarm)
        then
          location := COPY (currentLn, 10, length(currentLn));


        if (NOT alarm)
            and (pos('BEGIN:VALARM', currentLn) = 1 )
        then
        begin
          alarm := GetAlarm(calFile);
        end;

        if (pos('END:VALARM', currentLn) = 1 )
        then
          alarm := FALSE;

      end;  (* if *)

    end;  (* while *)


    if (length(dtStart) > 0)
    then
    begin
      startDate^.dtStr2Obj(dtStart);
    end;


    if (length(dtEnd) > 0)
    then
    begin
      endDate^.dtStr2Obj(dtEnd);
    end;

    Dispose(logger, Done);

    GetEvent := TRUE;

  end;


  Function TEvent.GetAlarm (var calFile : Text)
          : Boolean;
  var
    currentLn    : String;

    checkEnd     : String;
    endAlarm     : Boolean;

  begin
    checkEnd := 'END:VALARM';
    endAlarm := FALSE;

    while (NOT eof (calFile) 
           AND NOT endAlarm )
    do
    begin

      readln ( calFile, currentLn );

      (* Look for End Alarm *)
      if ( pos(checkEnd, currentLn) = 1 )
      then
      begin

        endAlarm := TRUE;

      end
      else
      begin

        if (pos('TRIGGER:', currentLn) = 1 )
        then
          alarmTrigger := COPY (currentLn, 9, length(currentLn));

        if (pos('ACTION:', currentLn) = 1 )
        then
          alarmAction  := COPY (currentLn, 8, length(currentLn));

        if (pos('DESCRIPTION:', currentLn) = 1 )
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
    startDate^.writeDT;

    WriteNN (summary);
    WriteNN (description);

    write('Location     : ');
    WriteNN (location);

    WriteNN (alarmTrigger);

    write('Event ends   : ');
    endDate^.writeDT;
  end;


  Function TEvent.isMonthEvent (y, m : Word)
          : Boolean;

  (* Purpose : Determine if thisEvent falls within the period (month)
               There are 4 cases in the period:
               1: overlap start of period
               2: contained within period
               3: overlap end of period
               4: start before, end after period

               and 2 cases outside the period:
               5: start/end before period
               6: start/end after period
   *)

  var
    pStart,
    pEnd   : PDateTime;

    daysInMon : Integer;

  begin
    isMonthEvent := FALSE;

    new(pStart);
    pStart^.init;
    pStart^.dtStr2Obj(date2Str(y, m, 1, FALSE) + ' ' + time2Str(0, 0, 0, FALSE) );

    daysInMon := daysMon[m];
    if (m = 2) and (isLeapDay(y))
    then
      daysInMon := 29;

    new(pEnd);
    pEnd^.init;
    pEnd^.dtStr2Obj(date2Str(y, m, daysInMon, FALSE) + ' ' + time2Str(23, 59, 59, FALSE) );

    (* Does the event start/end overlap with the period start/end ? *)

    if      (startDate^.epoch > pStart^.epoch)
        and (startDate^.epoch < pEnd^.epoch)
      or
            (endDate^.epoch > pStart^.epoch)
        and (endDate^.epoch < pEnd^.epoch)
      or
            (startDate^.epoch < pStart^.epoch)
        and (endDate^.epoch   > pEnd^.epoch)
    then
    begin
      isMonthEvent := TRUE;
      writeln ('Current event');
    end;

    Dispose (pStart, Done);
    Dispose (pEnd,   Done);

  end;


end.