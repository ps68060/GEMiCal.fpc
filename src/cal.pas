{$B+,D-,I-,L-,P-,Q-,R-,S-,T-,V-,X+,Z-}
{$mode objfpc}

unit Cal;

(* AUTHOR  : P SLEGG
   DATE    : 17th May 2020 Version 1
   PURPOSE : TCal object for ICS file.
*)

interface
  uses
    Objects,
    Event;

const
  MAXEVENTS = 999;

type
  TCal = class
    version   : String;
    eventList : array [0..MAXEVENTS] of PEvent;
    entries   : Integer;

    constructor Create;
    destructor  Destroy; override;

    Procedure LoadICS (directory : String);
    Procedure DivideIcs (const calName : String);
    Procedure Sort;

  end;

implementation

  uses
    SysUtils,
    Logger;

  constructor TCal.Create;
  var
    i : Integer;
  begin
    version := '2.0';
    entries := 0;

    for i := 0 to MAXEVENTS do
    begin
      new (eventList[i]);
      eventList[i]^.init;
    end;
  end;


  destructor TCal.Destroy;
  var
    i : Integer;
  begin
    for i := 0 to MAXEVENTS do
    begin
      dispose(eventList[i], Done);
    end;
    
    inherited Destroy;
  end;


  Procedure TCal.LoadICS (directory : String);
  (*
   * Purpose : Load all the *.ics files from the <directory>.
   *)

  var
    log     : TLogger;
    attr    : Word;
    fileRec : TRawbyteSearchRec;
    calName : String;

  begin
    log := TLogger.Create(LLINFO);

    entries := 0;
    if (findFirst(directory + '/*.ics', FAANYFILE, fileRec) = 0) then
    begin
      repeat
        log.debug ('Loading ' + fileRec.name);
        calName := directory + '/' +  fileRec.name;

        DivideIcs (calName);
      until FindNext(fileRec) <> 0;

      FindClose(fileRec);
    end;

    log.Free;

  end;


  Procedure TCal.DivideIcs (const calName : String);

  (*
   * Purpose : Read an ICS file and get all the Events
   *           into EventsList.
   *           Return the number of events.
   *)

  var
    log      : TLogger;
    calFile  : Text;

    checkStart  : String;
    currentLn   : String;

    i           : Integer;

  begin
    log := TLogger.Create(LLDEBUG);
    log.debug('DivideIcs: ');

    checkStart := 'BEGIN:VEVENT';

    (* Open the calendar file for reading *)
    assign (calFile, calName);
    reset  (calFile);

    log.debug ('Reading from ' + calName);

    while ( NOT eof(calFile) ) 
    do
    begin

      readln ( calFile, currentLn );
      log.debug (currentLn);

      if ( pos (checkStart, currentLn) = 1 )
      then
      begin
        new (eventList[entries]);
        eventList[entries]^.init;
      
        eventList[entries]^.getEvent(calFile);
        eventList[entries]^.filename := calName;

        inc (entries);
      end;

    end;

    log.debug('loaded ', entries );
    log.Free;
  end;


  Procedure TCal.Sort;
  var
    log     : TLogger;
    i, j    : Integer;
    swapper : PEvent;

  begin
    log := TLogger.Create(LLINFO);

    log.debug ('Starting sort of ', entries);

    for i := 0 to entries - 1
    do
    begin

      for j := i + 1 to entries
      do
      begin

        if (eventList[i]^.startDate.epoch  >
            eventList[j]^.startDate.epoch )
        then
        begin
          (*
          writeln('Before swap ', i, ' ', j);
          eventList[i]^.writeEvent;
          eventList[j]^.writeEvent;
          *)

          swapper            := eventList[i];
          eventList[i]       := eventList[j];
          eventList[j]       := swapper;

          (*
          writeln;
          writeln('After swap');
          eventList[i]^.writeEvent;
          eventList[j]^.writeEvent;
          writeln;
          writeln;
          *)
        end; (* if *)

      end;
    end;

    log.debug('Sorted');

    log.Free;

  end;


end.