{$I projopts.i}
{$mode objfpc}

unit Cal;

(* Author  : P SLEGG
 * Date    : 17th May 2020 Version 1
 * Purpose : TCal object for ICS file.
*)

interface
  uses
    Objects,
    Constant,
    Event;

type
  TCal = class
    version   : String;
    eventList : array of TEvent;
    entries   : Integer;

    constructor Create;
    destructor  Destroy; override;

    procedure LoadIcs (directory : String);
    procedure DivideIcs (const calName : String);
    procedure Sort;
    
    procedure WriteIcsHeader(var calFile : Text);
    procedure WriteIcsFooter(var calFile : Text);
    procedure SaveIcs (directory : String);
    procedure UpdateIcs (directory : String, filename : String, TEvent : event);
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
    log.debug('TCal.Create');
  end;


destructor TCal.Destroy;
  var
    i : Integer;
  begin
    for i := 0 to length(eventList) - 1 do
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

  const
    BEGIN_EVENT_TK = 'BEGIN:VEVENT';
  var
    calFile  : Text;
    currentLn   : String;

  begin
    log.level := LLDEBUG;
    log.debug('DivideIcs: ');

    (* Open the calendar file for reading *)
    assign (calFile, calName);
    reset  (calFile);

    log.debug ('Reading from ' + calName);

    while ( NOT eof(calFile) ) 
    do
    begin

      readln ( calFile, currentLn );
      log.debug ('entries=', entries);
      //log.debug (currentLn);

      if (Pos(BEGIN_EVENT_TK, currentLn) = 1 )
      then
      begin
        entries := length(eventList);
        SetLength(eventList, entries + 1);
        eventList[entries] := TEvent.Create;
      
        eventList[entries].getEvent(calFile);
        eventList[entries].filename := calName;
      end;

    end;

    log.debug('DivideIcs: loaded ', entries );

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

        if (eventList[i].startDate.fpDateTime  >
            eventList[j].startDate.fpDateTime )
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


procedure TCal.UpdateIcs (directory : String, filename : String, TEvent : event);
  (*
   * Purpose : Update an existing ics file.
   *           Read the existing file
   *           Write the content to a new temporary file
   *           until reaching the closing footer.
   *  inputs : directory
   *           filename of file to be read
   *           event to be added to the ics file.
   *)
  var
    inFile,
    tempFile       : Text;

    tempFileName,
    line           : String;

  begin
    log.level := LLDEBUG;

    (* Check if the file exists *)
    if not FileExists(FileName)
    then
      Exit;

    (* Open the input file for reading *)
    assign (inFile, directory + filename);
    reset (inFile);

    tempFileName := directory + '/calTemp.ics';
    assign (tempFile, tempFilename);
    rewrite (tempFile);

    while not EOF(inFile) do
    begin
      readln (inFile, line);

      if line = END_CAL_TK
      then
      begin
        event.SaveEvent(tempFilename);
        WriteIcsFooter(tempFilename);
      else
        writeln (tempFilename, line);
    end;

    close (inFile);
    close (tempFile);

    delete(filename);
    rename(tempFilename, filename);
    log.debug ('Updated ics file ', directory + '/' + filename);
  end;

end.