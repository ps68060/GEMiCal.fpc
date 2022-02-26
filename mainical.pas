unit MainIcal;

interface

uses
  OWindows,

  DlgAbout,
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


  PNavPrevYear = ^TNavPrevYear;
  TNavPrevYear = OBJECT(TKeyMenu)
                  procedure Work; VIRTUAL;
                end;

  PNavNextYear = ^TNavNextYear;
  TNavNextYear = OBJECT(TKeyMenu)
                  procedure Work; VIRTUAL;
                end;

  TMyApplication = OBJECT(TApplication)
                     iCal       : PCal;
                     winCal     : PWinCal;

                     destructor done; virtual;
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
    gem,
    aes,
    DateTime,
    CellGrid,

    Logger;


(* ------------------------------------------------------------------------------- *)

var

  myFile,
  myPath        : String;

  directory     : String;
  logg          : PLogger;


  destructor TMyApplication.done;
  begin

  end;


procedure TMyApplication.INITInstance;
var
  appDeskMenu    : PDeskMenu;
  appLoadMenu    : PLoadMenu;
  appDialogMenu  : PDialogMenu;
  appCalMenu     : PCalMenu;
  appNavPrevMon  : PNavPrevMon;
  appNavNextMon  : PNavNextMon;

  appNavPrevYear : PNavPrevYear;
  appNavNextYear : PNavNextYear;
                     
begin

  new(logg);
  logg^.init;
  logg^.level := INFO;

  (* Get current path *)
  GetDir (0, directory);

  LoadResource ('GEMICAL.RSC','');

  (* Load and set-up the menu *)
  LoadMenu (TREE000);

  appDeskMenu := new (PDeskMenu,  Init(@SELF, K_Ctrl, Ctrl_I, M_INFO,     M_DESK1));

  (* File Menu *)
  apploadMenu := new (PLoadMenu,  Init(@SELF, K_Ctrl, Ctrl_L, M_FOLDER,   M_DESK2));

  appDialogMenu := new (PDialogMenu, Init(@SELF, K_Ctrl, Ctrl_C, M_DIALOG,   M_DESK2));    (* This needs to be pointer DialogMenu *)
  appCalMenu    := new (PCalMenu,    Init(@SELF, K_Ctrl, Ctrl_M, M_CALENDAR, M_DESK2));

  (* Navigation menu *)
  appNavPrevMon := new (PNavPrevMon,   Init(@SELF, K_Ctrl, Ctrl_O, M_MONTHPREV, M_DESK3));
  appNavNextMon := new (PNavNextMon,   Init(@SELF, K_Ctrl, Ctrl_K, M_MONTHNEXT, M_DESK3));

  appNavPrevYear := new (PNavPrevYear,  Init(@SELF, K_Ctrl, Ctrl_H, M_YEARPREV,  M_DESK3));
  appNavNextYear := new (PNavNextYear,  Init(@SELF, K_Ctrl, Ctrl_J, M_YEARNEXT,  M_DESK3));

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
  logg^.level := INFO;

  logg^.log(DEBUG, 'INIT Main Window');

  if MyApplication.winCal = NIL
  then
  begin

    myApplication.winCal := new(PWinCal, init(NIL, 'GEMiCal') );

    LoadCal;

    MyApplication.iCal^.sort;

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

  dispose(logg);

end;


procedure TLoadMenu.Work;

var
  year,
  month,
  day,
  dayOfWeek : Word;

  dtStr     : String;

begin
  logg^.log(DEBUG, 'Load Menu Work');

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

    GetDate (year, month, day, dayOfWeek) ;

    dtStr := date2str(year, month, 1, FALSE);

    FilterCal(dtStr);

    MyApplication.WinCal^.ForceRedraw;

    ArrowMouse;
    logg^.log(DEBUG, 'Loaded');
  end;

end;


procedure TCalMenu.Work;
begin
  logg^.log(DEBUG, 'CalMenu Work');

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

  dtStr       : String;

begin
  logg^.log(DEBUG, 'Prev Month Work');

  month := displayDate^.getMMFromIso;
  year  := displayDate^.getYYYYFromIso;

  dec (month);

  if (month < 1)
  then
  begin
    month := 12;
    dec (year);
  end;

  dtStr := date2str(year, month, 1, FALSE);

  FilterCal(dtStr);

  MyApplication.WinCal^.ForceRedraw;

end;


procedure TNavNextMon.Work;
var
  month,
  year        : Word;

  dtStr       : String;

begin
  logg^.log(DEBUG, 'Next Month Work');

  month := displayDate^.getMMFromIso;
  year  := displayDate^.getYYYYFromIso;

  inc (month);

  if (month > 12)
  then
  begin
    month := 1;
    inc (year);
  end;

  dtStr := date2str(year, month, 1, FALSE);

  FilterCal(dtStr);

  MyApplication.WinCal^.ForceRedraw;

end;


procedure TNavPrevYear.Work;
var
  year        : Word;

  dtStr       : String;

begin
  logg^.log(DEBUG, 'Prev Year Work');

  year  := displayDate^.getYYYYFromIso;

  dec (year);

  dtStr := date2str(year, displayDate^.getMMFromIso, 1, FALSE);

  FilterCal(dtStr);

  MyApplication.WinCal^.ForceRedraw;

end;


procedure TNavNextYear.Work;
var
  year        : Word;

  dtStr       : String;

begin
  logg^.log(DEBUG, 'Next Year Work');

  year  := displayDate^.getYYYYFromIso;

  inc (year);

  dtStr := date2str(year, displayDate^.getMMFromIso, 1, FALSE);

  FilterCal(dtStr);

  MyApplication.WinCal^.ForceRedraw;

end;


procedure LoadCal;

begin

  new(myApplication.iCal);
  myApplication.iCal^.init;

  logg^.log(DEBUG, 'Load ICS files from ' + directory);

  (* Load iCal events *)
  myApplication.iCal^.loadICS(directory);

  logg^.logInt(DEBUG, 'loaded ', myApplication.iCal^.entries );

end;


procedure FilterCal(dtStr : String);

begin
  logg^.log(DEBUG, 'FilterCal ' );

  if (displayDate <> NIL)
  then
    dispose (displayDate, done);

  new (displayDate);
  displayDate^.init;
  displayDate^.dtStr2Obj(dtStr);

  logg^.log(DEBUG, 'Filter ' + dtStr );

  if (cellGr <> NIL)
  then
    dispose (cellGr, done);

  new (cellGr);
  cellGr^.init;
  cellGr^.FilterEvents(myApplication.iCal,
                       displayDate);
  logg^.log(DEBUG, 'Cal displayed');

end;

end.
