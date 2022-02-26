{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}

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

  var
    logg : PLogger;

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
    attr    : Word;
    fileRec : SearchRec;
    calName : String;

  begin
    new (logg);
    logg^.init;
    logg^.level := INFO;

    findFirst(directory + '/*.ics', attr, fileRec);

    while DosError = 0
    do
    begin
      logg^.log (DEBUG, 'Loading ' + fileRec.name);
      calName := directory + '/' +  fileRec.name;

      DivideIcs (calName);
      inc (entries);

      FindNext( fileRec );
    end;
  
    dec (entries);
    dispose (logg);
  end;


  Procedure TCal.DivideIcs (const calName : String);

  (*
    Purpose : Read an ICS file and get all the Events
              into EventsList.
              Return the number of events.
   *)

  var
    logg   : PLogger;
    calFile  : Text;

    checkStart  : String;
    currentLn   : String;

    i           : Integer;

  begin
    new(logg);
    logg^.init;
    logg^.level := INFO;

    checkStart := 'BEGIN:VEVENT';

    (* Open the calendar file for reading *)
    assign (calFile, calName);
    reset  (calFile);

    logg^.log (DEBUG, 'Reading from ' + calName);

    while ( NOT eof(calFile) ) 
    do
    begin

      readln ( calFile, currentLn );
      logg^.log (DEBUG, currentLn);

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

    logg^.logInt (DEBUG, 'Entries Read = ', entries +1);

    dispose (logg);
  end;


  Procedure TCal.Sort;
  var
    i, j    : Integer;
    swapper : PEvent;

  begin
    new (logg);
    logg^.init;
    logg^.level := INFO;

    logg^.logInt (DEBUG, 'Starting sort of ', entries);

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

    logg^.log(DEBUG, 'Sorted');
    dispose (logg);

  end;


end.