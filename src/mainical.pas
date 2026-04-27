{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}
{$mode objfpc}

unit MainIcal;

interface

uses
  owindows,

  DlgAbout,
  DlgConv,
  Cal,
  WinCal,
  Tos, aes, vdi;

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
                     iCal       : TCal;
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
    Logger,
    DateTime,
    CellGrid;


(* ------------------------------------------------------------------------------- *)

var

  myFile,
  myPath        : String;

  directory     : String;

  destructor TMyApplication.done;
  begin

  end;


procedure TMyApplication.INITInstance;
var
  log            : TLogger;

  appDeskMenu    : PDeskMenu;
  appLoadMenu    : PLoadMenu;
  appDialogMenu  : PDialogMenu;
  appCalMenu     : PCalMenu;
  appNavPrevMon  : PNavPrevMon;
  appNavNextMon  : PNavNextMon;

  appNavPrevYear : PNavPrevYear;
  appNavNextYear : PNavNextYear;
                     
begin
  log := TLogger.Create(LLINFO);

  (* Get current path *)
  GetDir (0, directory);

  LoadResource ('GEMICAL.RSC','');

  (* Load and set-up the menu *)
  LoadMenu (TREE000);

  appDeskMenu := new (PDeskMenu,  Init(@SELF, K_Ctrl, Ctrl_I, M_INFO,     M_DESK1));       (* Info *)

  (* File Menu *)
  apploadMenu := new (PLoadMenu,  Init(@SELF, K_Ctrl, Ctrl_L, M_FOLDER,   M_DESK2));       (* Load *)

  appDialogMenu := new (PDialogMenu, Init(@SELF, K_Ctrl, Ctrl_C, M_DIALOG,   M_DESK2));    (* This needs to be pointer DialogMenu *)
  appCalMenu    := new (PCalMenu,    Init(@SELF, K_Ctrl, Ctrl_M, M_CALENDAR, M_DESK2));    (* Display calendar *)

  (* Navigation menu *)
  appNavPrevMon  := new (PNavPrevMon,  Init(@SELF, K_Ctrl, Ctrl_O, M_MONTHPREV, M_DESK3));
  appNavNextMon  := new (PNavNextMon,  Init(@SELF, K_Ctrl, Ctrl_K, M_MONTHNEXT, M_DESK3));

  appNavPrevYear := new (PNavPrevYear, Init(@SELF, K_Ctrl, Ctrl_H, M_YEARPREV,  M_DESK3));
  appNavNextYear := new (PNavNextYear, Init(@SELF, K_Ctrl, Ctrl_J, M_YEARNEXT,  M_DESK3));

  INHERITED INITInstance;
  SetQuit (M_END, M_DESK2);
  
  log.Free;

end;


procedure TMyApplication.INITMainWindow;

var
  log       : TLogger;
  year,
  month,
  day,
  dayOfWeek : Word;

  dtStr     : String;

begin
  log := TLogger.Create(LLDEBUG);
  log.info('INIT Main Window');

  if MyApplication.winCal = NIL
  then
  begin

    myApplication.winCal := new(PWinCal, init(NIL, 'GEMiCal') );

    GetDate (year, month, day, dayOfWeek) ;
    dtStr := date2str(year, month, 1, FALSE);

    new (displayDate);
    displayDate^.init;
    displayDate^.dtStr2Obj(dtStr);

    LoadCal;

    if (myApplication.iCal.entries > 0)
    then
    begin
      MyApplication.iCal.sort;
      FilterCal(dtStr);
    end;

  end;

  if MyApplication.winCal <> NIL
  then
    MyApplication.winCal^.MakeWindow;

  log.Free;

end;


procedure TLoadMenu.Work;

var
  log       : TLogger;
  year,
  month,
  day,
  dayOfWeek : Word;

  dtStr     : String;

begin
  log := TLogger.Create(LLINFO);

  log.info('Load Menu Work');

  if FileSelect(NIL, 'Load ICS file ', '*.*', myPath, myFile, TRUE)
  then
  begin
    BusyMouse;

    myApplication.iCal.Free;

    // todo - is cellGr needed ?
    if (cellGr <> NIL)
    then
      cellGr.Free;

    cellGr := TCellGrid.Create;

    directory := myPath;

    GetDate (year, month, day, dayOfWeek) ;
    dtStr := date2str(year, month, 1, FALSE);

    LoadCal;
   
    if (myApplication.iCal.entries > 0)
    then
    begin
      myApplication.iCal.sort;
      FilterCal(dtStr);
    end;

    MyApplication.WinCal^.ForceRedraw;

    ArrowMouse;
    log.debug('Loaded');
  end;

  log.Free;

end;


procedure TCalMenu.Work;
var
  log       : TLogger;

begin
  log := TLogger.Create(LLINFO);
  log.debug('CalMenu Work');

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

  log.Free;

end;


procedure TNavPrevMon.Work;
var
  log        : TLogger;
  month,
  year        : Word;

  dtStr       : String;

begin
  log := TLogger.Create(LLINFO);
  log.debug('Prev Month Work');


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

  log.Free;

end;


procedure TNavNextMon.Work;
var
  log        : TLogger;
  month,
  year        : Word;

  dtStr       : String;

begin
  log := TLogger.Create(LLINFO);
  log.debug('Next Month Work');

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

  log.Free;

end;


procedure TNavPrevYear.Work;
var
  log       : TLogger;
  year      : Word;

  dtStr     : String;

begin
  log := TLogger.Create(LLINFO);
  log.debug('Prev Year Work');

  year  := displayDate^.getYYYYFromIso;

  dec (year);

  dtStr := date2str(year, displayDate^.getMMFromIso, 1, FALSE);

  FilterCal(dtStr);

  MyApplication.WinCal^.ForceRedraw;

  log.Free;

end;


procedure TNavNextYear.Work;
var
  log       : TLogger;
  year        : Word;

  dtStr     : String;

begin
  log := TLogger.Create(LLINFO);
  log.debug('Next Year Work');

  year  := displayDate^.getYYYYFromIso;

  inc (year);

  dtStr := date2str(year, displayDate^.getMMFromIso, 1, FALSE);

  FilterCal(dtStr);

  MyApplication.WinCal^.ForceRedraw;

  log.Free;

end;


procedure LoadCal;
var
  log       : TLogger;

begin
  log := TLogger.Create(LLINFO);

  myApplication.iCal := TCal.Create;

  log.debug('Load ICS files from ' + directory);

  (* Load iCal events *)
  myApplication.iCal.loadICS(directory);
  
  log.debug('loaded ', myApplication.iCal.entries );

  log.Free;

end;


procedure FilterCal(dtStr : String);
(*
 * PURPOSE: Get the events for the date.
 *)

var
  log       : TLogger;

begin
  log := TLogger.Create(LLINFO);
  log.debug('FilterCal ' );

  if (displayDate <> NIL)
  then
    dispose (displayDate, done);

  new (displayDate);
  displayDate^.init;
  displayDate^.dtStr2Obj(dtStr);

  log.debug('Filter ' + dtStr );

  if (cellGr <> NIL)
  then
    cellGr.Free;

  cellGr := TCellGrid.Create;
  cellGr.FilterEvents(myApplication.iCal,
                      displayDate);
  log.debug('Cal displayed');
  
  log.Free;

end;

end.
