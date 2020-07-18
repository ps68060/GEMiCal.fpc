unit MainIcal;

interface

uses
  OWindows,

  DlgConv,
  Cal,
  DateTime,
  WinCal;

{$I gemical.i}

const

  dAppName = 'GEMiCal';

type
  (* Each object has variables and methods associated with it. *)

  (* Main Menu *)


  PLoadMenu    = ^TLoadMenu;

  PCalMenu     = ^TCalMenu;

  TLoadMenu =  OBJECT(TKeyMenu)
                 procedure Work; VIRTUAL;
               end;

  (* Menu2 > Calendar Window *)
  TCalMenu  =   OBJECT(TKeyMenu)
                  procedure Work; VIRTUAL;
                end;

  PNavPrevMon = ^TNavPrevMon;
  TNavPrevMon = OBJECT(TKeyMenu)
                  procedure Work; VIRTUAL;
                end;

  PNavNextMon = ^TNavNextMon;
  TNavNextMon = OBJECT(TKeyMenu)
                  procedure Work; VIRTUAL;
                end;

  TMyApplication = OBJECT(TApplication)
                     convMenu   : PConvMenu;
                     iCal       : PCal;
                     winCal     : PWinCal;
                     procedure INITInstance;   VIRTUAL;
                     procedure INITMainWindow; VIRTUAL;
                   end;

  procedure LoadCal;

  procedure FilterCal(displayDate : PDateTime);

  function GetToday(year,
                    month : Word)
          : PDateTime;

var
  myApplication : TMyApplication;


implementation

uses

  Dos,
  Gem,
  Cal,
  DateTime,
  CellGrid,

  DlgAbout,
  DlgConv,
  Logger;


(* ------------------------------------------------------------------------------- *)

var

  myFile,
  myPath        : String;

  directory     : String;
  logger        : PLogger;


procedure TMyApplication.INITInstance;
begin

  new(logger);
  logger^.init;
  logger^.level := DEBUG;

  (* Get current path *)
  GetDir (0, directory);

  LoadResource ('GEMICAL.RSC','');

  (* Load and set-up the menu *)
  LoadMenu (TREE000);

  new (PDeskMenu,  Init(@SELF, K_Ctrl, Ctrl_I, M_INFO,     M_DESK1));

  new (PLoadMenu,  Init(@SELF, K_Ctrl, Ctrl_L, M_FOLDER,   M_DESK2));
  new (convMenu,   Init(@SELF, K_Ctrl, Ctrl_C, M_DIALOG,   M_DESK2));    (* This needs to be pointer DialogMenu *)
  new (PCalMenu,   Init(@SELF, K_Ctrl, Ctrl_M, M_CALENDAR, M_DESK2));

  new (PNavPrevMon,   Init(@SELF, K_Ctrl, Ctrl_V, M_MONTHPREV, M_DESK3));
  new (PNavNextMon,   Init(@SELF, K_Ctrl, Ctrl_X, M_MONTHNEXT, M_DESK3));

  INHERITED INITInstance;
  SetQuit (M_END, M_DESK2);

end;


procedure TMyApplication.INITMainWindow;

var
  year,
  month,
  day,
  dayOfWeek : Word;

begin
  logger^.level := DEBUG;

  logger^.log(DEBUG, 'INIT Main Window');

  if MyApplication.winCal = NIL
  then
  begin
    myApplication.winCal := new(PWinCal, init(NIL, 'GEMiCal') );

    LoadCal;

    GetDate (year, month, day, dayOfWeek) ;
    myApplication.winCal^.calDate := GetToday(year, month);

    FilterCal(myApplication.winCal^.calDate);

  end;

  if MyApplication.winCal <> NIL
  then
    MyApplication.winCal^.MakeWindow;

end;


procedure TLoadMenu.Work;

var
  year,
  month,
  day,
  dayOfWeek : Word;

begin
  logger^.log(DEBUG, 'Load Menu Work');

  if FileSelect(NIL, 'Load ICS file ', '*.*', myPath, myFile, TRUE)
  then
  begin
    BusyMouse;

    Dispose(myApplication.iCal, Done);
    Dispose(cellGr, Done);

    directory := myPath;

    LoadCal;

    GetDate (year, month, day, dayOfWeek) ;
    myApplication.winCal^.calDate := GetToday(year, month);
      
    FilterCal(myApplication.winCal^.calDate);

    ArrowMouse;
    logger^.log(DEBUG, 'Loaded');
  end;

end;


procedure TCalMenu.Work;
begin
  logger^.log(DEBUG, 'CalMenu Work');

  if aDialog <> NIL
  then
    aDialog^.MakeWindow;

  (* Window *)
  if MyApplication.WinCal = NIL
  then
  begin
    MyApplication.WinCal := NEW(PWinCal, Init(NIL, dAppName));
    MyApplication.WinCal^.SetSubTitle('Calendar Month');
  end;

  if MyApplication.WinCal <> NIL
  then
    MyApplication.WinCal^.MakeWindow;

end;


procedure LoadCal;

begin

  new(myApplication.iCal);
  myApplication.iCal^.init;

  logger^.log(DEBUG, 'Load ICS files from ' + directory);

  (* Load iCal events *)
  myApplication.iCal^.loadICS(directory);

  logger^.logInt(DEBUG, 'loaded ', myApplication.iCal^.entries );

  myApplication.iCal^.sort;

  logger^.log(DEBUG, 'Sorted');

end;


procedure FilterCal(displayDate : PDateTime);

begin

  new (cellGr);
  cellGr^.init;
  cellGr^.FilterEvents(myApplication.iCal,
                       displayDate);

  logger^.log(DEBUG, 'Cal displayed');
end;


function GetToday (year,
                   month : Word)
        : PDateTime;
var
  thisDateTime : PDateTime;

  dtStr        : String;

begin

  dtStr := date2Str(year, month, 1, FALSE);

  new(thisDateTime);
  thisDateTime^.init;

  thisDateTime^.dtStr2Obj(dtStr);
  thisDateTime^.dayOfWeek;

  GetToday := thisDateTime;

  logger^.log(DEBUG, 'GetToday');
end;


procedure TNavPrevMon.Work;
var
  month,
  year        : Word;

begin
  logger^.log(DEBUG, 'Prev Month Menu Work');

  month := myApplication.winCal^.calDate^.mm;
  year  := myApplication.winCal^.calDate^.yyyy;

  dec (month);

  if (month < 1)
  then
  begin
    month := 12;
    dec (year);
  end;

  dispose (myApplication.winCal^.calDate, done);

  new (myApplication.winCal^.calDate);
  myApplication.winCal^.calDate^.init;

  myApplication.winCal^.calDate := GetToday(year, month);  

end;


procedure TNavNextMon.Work;
var
  month,
  year        : Word;

begin
  logger^.log(DEBUG, 'Next Month Menu Work');

  month := myApplication.winCal^.calDate^.mm;
  year  := myApplication.winCal^.calDate^.yyyy;

  inc (month);

  if (month > 12)
  then
  begin
    month := 1;
    inc (year);
  end;

  dispose (myApplication.winCal^.calDate, done);

  new (myApplication.winCal^.calDate);
  myApplication.winCal^.calDate^.init;

  myApplication.winCal^.calDate := GetToday(year, month);  

end;

end.
