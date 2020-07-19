unit MainIcal;

interface

uses
  OWindows,

  DlgConv,
  Cal,
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

  procedure FilterCal(dtStr : String);

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
  logger^.level := INFO;

  (* Get current path *)
  GetDir (0, directory);

  LoadResource ('GEMICAL.RSC','');

  (* Load and set-up the menu *)
  LoadMenu (TREE000);

  new (PDeskMenu,  Init(@SELF, K_Ctrl, Ctrl_I, M_INFO,     M_DESK1));

  new (PLoadMenu,  Init(@SELF, K_Ctrl, Ctrl_L, M_FOLDER,   M_DESK2));
  new (convMenu,   Init(@SELF, K_Ctrl, Ctrl_C, M_DIALOG,   M_DESK2));    (* This needs to be pointer DialogMenu *)
  new (PCalMenu,   Init(@SELF, K_Ctrl, Ctrl_M, M_CALENDAR, M_DESK2));

  new (PNavPrevMon,   Init(@SELF, K_Ctrl, Ctrl_O, M_MONTHPREV, M_DESK3));
  new (PNavNextMon,   Init(@SELF, K_Ctrl, Ctrl_K, M_MONTHNEXT, M_DESK3));

  INHERITED INITInstance;
  SetQuit (M_END, M_DESK2);

end;


procedure TMyApplication.INITMainWindow;

var
  year,
  month,
  day,
  dayOfWeek : Word;

  dtStr     : String;

begin
  logger^.level := INFO;

  logger^.log(DEBUG, 'INIT Main Window');

  if MyApplication.winCal = NIL
  then
  begin
    myApplication.winCal := new(PWinCal, init(NIL, 'GEMiCal') );

    LoadCal;

    GetDate (year, month, day, dayOfWeek) ;
    dtStr := date2str(year, month, 1, FALSE);

    new (displayDate);
    displayDate^.init;
    displayDate^.dtStr2Obj(dtStr);

    FilterCal(dtStr);

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

  dtStr     : String;

begin
  logger^.log(DEBUG, 'Load Menu Work');

  if FileSelect(NIL, 'Load ICS file ', '*.*', myPath, myFile, TRUE)
  then
  begin
    BusyMouse;

    Dispose(myApplication.iCal, Done);
    if (cellGr <> NIL)
    then
      Dispose(cellGr, Done);

    new (cellGr);
    cellGr^.init;

    directory := myPath;

    LoadCal;

    myApplication.iCal^.sort;
    logger^.log(DEBUG, 'Sorted');

    GetDate (year, month, day, dayOfWeek) ;

    dtStr := date2str(year, month, 1, FALSE);

    FilterCal(dtStr);

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


procedure TNavPrevMon.Work;
var
  month,
  year        : Word;

  dtStr     : String;

begin
  logger^.log(DEBUG, 'Prev Month Menu Work');

  month := displayDate^.mm;
  year  := displayDate^.yyyy;

  dec (month);

  if (month < 1)
  then
  begin
    month := 12;
    dec (year);
  end;

  dtStr := date2str(year, month, 1, FALSE);

  FilterCal(dtStr);

end;


procedure TNavNextMon.Work;
var
  month,
  year        : Word;

  dtStr     : String;

begin
  logger^.log(DEBUG, 'Next Month Menu Work');

  month := displayDate^.mm;
  year  := displayDate^.yyyy;

  inc (month);

  if (month > 12)
  then
  begin
    month := 1;
    inc (year);
  end;

  dtStr := date2str(year, month, 1, FALSE);

  FilterCal(dtStr);

end;


procedure LoadCal;

begin

  new(myApplication.iCal);
  myApplication.iCal^.init;

  logger^.log(DEBUG, 'Load ICS files from ' + directory);

  (* Load iCal events *)
  myApplication.iCal^.loadICS(directory);

  logger^.logInt(DEBUG, 'loaded ', myApplication.iCal^.entries );

end;


procedure FilterCal(dtStr : String);

begin
  logger^.log(DEBUG, 'FilterCal ' );

  if (displayDate <> NIL)
  then
    dispose (displayDate, done);

  new (displayDate);
  displayDate^.init;
  displayDate^.dtStr2Obj(dtStr);

  logger^.log(DEBUG, 'Filter ' + dtStr );

  if (cellGr <> NIL)
  then
    dispose (cellGr, done);

  new (cellGr);
  cellGr^.init;
  cellGr^.FilterEvents(myApplication.iCal,
                       displayDate);
  logger^.log(DEBUG, 'Cal displayed');
end;

end.
