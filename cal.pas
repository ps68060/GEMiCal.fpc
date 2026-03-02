{$B+,D-,I-,L-,P-,Q-,R-,S-,T-,V-,X+,Z-}

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
  maxEvents = 999;

type
  PCal = ^TCal;
  TCal = object(TObject)
    version   : String;
    eventList : array [0..maxEvents] of PEvent;
    entries   : Integer;

    constructor init;
    destructor  done; virtual;

    Procedure LoadICS (directory : String);
    Procedure DivideIcs (const calName : String);
    Procedure Sort;

  end;

implementation

  uses
    Dos,
    Logger;

  constructor TCal.init;
  var
    i : Integer;
  begin
    version := '2.0';
    entries := 0;
  end;


  destructor TCal.done;
  var
    i : Integer;
  begin
    for i := 0 to entries
    do
    begin
      dispose(eventList[i], Done);
    end;
  end;


  Procedure TCal.LoadICS (directory : String);
  (*
    Purpose : Load all the *.ics files from the <directory>.
  *)

  var
    log     : TLogger;
    attr    : Word;
    fileRec : SearchRec;
    calName : String;

  begin
    log := TLogger.Create(LLINFO);

    findFirst(directory + '/*.ics', attr, fileRec);

    while DosError = 0
    do
    begin
      log.debug ('Loading ' + fileRec.name);
      calName := directory + '/' +  fileRec.name;

      DivideIcs (calName);
      inc (entries);

      FindNext( fileRec );
    end;
  
    dec (entries);

    log.debug('loaded ', entries );
    log.Free;

  end;


  Procedure TCal.DivideIcs (const calName : String);

  (*
    Purpose : Read an ICS file and get all the Events
              into EventsList.
              Return the number of events.
   *)

  var
    log      : TLogger;
    calFile  : Text;

    checkStart  : String;
    currentLn   : String;

    i           : Integer;

  begin
    log := TLogger.Create(LLINFO);

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

    dec (entries);

    log.debug ('Entries Read = ', entries +1);

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

        if (eventList[i]^.startDate^.epoch  >
            eventList[j]^.startDate^.epoch )
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