{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}
{$mode objfpc}

unit IcsAlarm;

(* AUTHOR  : P Slegg
 * DATE    : 2026-05-05    Version 1
 * PURPOSE : TAlarm object for iCal Events.
 *)

interface
  uses
    Objects,
    DateTime;

type
  TAlarm = class(TObject)
    alarmAction      : String;
    alarmTrigger     : String;
    alarmDescription : String;

    constructor create;
    destructor  destroy; override;
  end;
  

implementation

  const
     beginAlarmTk  = 'BEGIN:VALARM';
     endAlarmTk    = 'END:VALARM';
     triggerTk     = 'TRIGGER:';
     alarmDescTk   = 'DESCRIPTION:';
     alarmActionTk = 'ACTION:';

constructor TAlarm.create;
  begin
    alarmAction      := '';
    alarmTrigger     := '';
    alarmDescription := '';
  end;

destructor TAlarm.destroy;
    begin
      inherited destroy;
    end;

constructor TAlarm.create(calFile : Text);
  (*  Purpose:
   *  Create an Alarm object from the current position in the calendar file.
   *  The file should be positioned at the start of the alarm definition, i.e.
   *  the line "BEGIN:VALARM" should have just been read.
   *)
  var
    currentLn    : String;
    endAlarm     : Boolean;

  begin
    endAlarm := FALSE;

    while (NOT eof (calFile) 
           AND NOT endAlarm )
    do
    begin
      readln (calFile, currentLn);

      tokens.Create;
      tokens.tokeniseIcal(currentLn);

      (* Look for End Alarm *)
      if ( tokens.startsWith(endAlarmTk) )
      then
      begin
        endAlarm := TRUE;
      end

      else
      begin
        if (tokens.startsWith(triggerTk) )
        then
          alarmTrigger := tokens.part[2];

        if (tokens.startsWith(alarmActionTk) )
        then
          alarmAction  := tokens.part[2];

        if (tokens.startsWith(alarmDescTk) )
        then
          alarmDescription := tokens.part[2];

      end;  (* if *)

      tokens.Free;
    end;  (* while *)

  end;
end.