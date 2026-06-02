{$I projopts.i}
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
    MAXEVENTS = 9999;
    BEGIN_CAL_TK = 'BEGIN:VCALENDAR';
    END_CAL_TK   = 'END:VCALENDAR';

type
  TCal = class
    version   : String;
    eventList : array [0..MAXEVENTS] of TEvent;
    entries   : Integer;

    constructor Create;
    destructor  Destroy; override;

    procedure LoadIcs (directory : String);
    procedure DivideIcs (const calName : String);
    procedure Sort;
    
    procedure WriteIcsHeader(var calFile : Text);
    procedure WriteIcsFooter(var calFile : Text);
    procedure SaveIcs (directory : String);
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
      eventList[i] := TEvent.create;
    end;
  end;


destructor TCal.Destroy;
  var
    i : Integer;
  begin
    for i := 0 to MAXEVENTS do
    begin
      eventList[i].free;
    end;
    
    inherited Destroy;
  end;


procedure TCal.LoadIcs (directory : String);
  (*
   * Purpose : Load all the *.ics files from the <directory>.
   *)

  var
    attr    : Word;
    fileRec : TRawbyteSearchRec;
    calName : String;

  begin
    log.level := LLDEBUG;

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

  end;


procedure TCal.DivideIcs (const calName : String);
  (*
   * Purpose : Read an ICS file and get all the Events
   *           into EventsList.
   *           Return the number of events.
   *)

  var
    calFile  : Text;

    checkStart  : String;
    currentLn   : String;

    i           : Integer;

  begin
    log.level := LLDEBUG;
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
        eventList[entries] := TEvent.create;
      
        eventList[entries].getEvent(calFile);
        eventList[entries].filename := calName;

        inc (entries);
      end;

    end;

    log.debug('DivideIcd: loaded ', entries );

  end;


procedure TCal.Sort;
  var
    i, j    : Integer;
    swapper : TEvent;

  begin
    log.level := LLDEBUG;

    log.debug ('Starting sort of ', entries);

    for i := 0 to entries - 1
    do
    begin

      for j := i + 1 to entries
      do
      begin

        if (eventList[i].startDate.epoch  >
            eventList[j].startDate.epoch )
        then
        begin
          (*
          writeln('Before swap ', i, ' ', j);
          eventList[i].debugEvent;
          eventList[j].debugEvent;
          *)

          swapper            := eventList[i];
          eventList[i]       := eventList[j];
          eventList[j]       := swapper;

          (*
          writeln;
          writeln('After swap');
          eventList[i].debugEvent;
          eventList[j].debugEvent;
          writeln;
          writeln;
          *)
        end; (* if *)

      end;
    end;

    log.debug('Sorted ', entries);

  end;


procedure TCal.WriteIcsHeader(var calFile : Text);
  begin
    writeln(calFile, BEGIN_CAL_TK);
    writeln(calFile, 'VERSION:2.0');
    writeln(calFile, 'PRODID:-//GEMiCal//ICALTEST//EN');
  end;


procedure TCal.WriteIcsFooter(var calFile : Text);
  begin
    writeln(calFile, END_CAL_TK);
  end;


procedure TCal.SaveIcs (directory : String);
  (*
   * Purpose : Save all the events in the calendar to a file.
   *)
  var
    calFile  : Text;
    i        : Integer;
    
  begin
    log.level := LLDEBUG;
    
    (* Open the calendar file for writing *)
    assign (calFile, directory + '/calTest.ics');
    rewrite (calFile);
    
    WriteIcsHeader(calFile);
    
    for i := 0 to entries - 1 do
    begin
      eventList[i].SaveEvent(calFile);
    end;
    close(calFile);
    
    WriteIcsFooter(calFile);
  end;

end.