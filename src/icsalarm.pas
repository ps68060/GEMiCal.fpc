{$I projopts.i}
{$mode objfpc}
{$modeswitch advancedrecords}

unit IcsAlarm;

(* AUTHOR  : P Slegg
 * DATE    : 2026-05-05    Version 1
 * PURPOSE : TAlarm object for iCal Events.
 *)

interface
  uses
    Objects,
    SysUtils,
    StrUtils,
    Constant,
    DateStrc;

type

  TAlarm = record
    alarmAction      : String;
    alarmTrigger     : String;
    alarmDescription : String;

    procedure ParseAlarm(var calFile : Text);

  end;

  

implementation
  uses
    Logger;


procedure TAlarm.ParseAlarm(var calFile : Text);
  (*  Purpose:
   *  Create an Alarm object from the current position in the calendar file.
   *  The file should be positioned at the start of the alarm definition, i.e.
   *  the line "BEGIN:VALARM" should have just been read.
   *)
  var
    currentLn    : String;
    endAlarm     : Boolean;

    parts,
    leftParts    : TStringArray;

    propName,
    paramStr,
    value        : String;

  begin
    log.info('Alarm trigger not yet handled. ' + value);
    endAlarm := FALSE;

    while (NOT eof (calFile) 
           AND NOT endAlarm )
    do
    begin
      readln (calFile, currentLn);

      (* Look for End Alarm *)
      if ( pos(END_ALARM_TK, currentLn) = 1 )
      then
      begin
        endAlarm := TRUE;
      end

      else
      begin
        // Split at the first colon into parts[] array
        parts := SplitString(currentLn, ':');

        if Length(parts) < 2
        then
        begin
          log.error('Invalid iCal Alarm', currentLn);
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
          TRIGGER_TK :
            alarmTrigger := value;
            
          ALARM_ACTION_TK:
            alarmAction  := value;

          ALARM_DESC_TK:
            alarmDescription := value;
        end;  // case

      end;  (* if *)

    end;  (* while *)

  end;
end.