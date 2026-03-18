{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}
{$mode objfpc}

unit MainIcal;

interface

uses
  owindows,

  DlgAbout,
  DlgConv,
  Cal,
  DateTime,
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
                   public
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
  conf          : TConfig;

implementation

  uses
    Dos,
    gem,
    Logger,
    CellGrid;


(* ------------------------------------------------------------------------------- *)

var

  myFile,
  myPath        : String;

  directory     : String;
  displayDate   : DateTime.TDateTime;


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

  conf := TConfig.Create;

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

  conf.Free;
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

    myApplication.winCal^.displayDate.dtStr2Obj(dtStr);
    log.debug('displayDate = ', myApplication.winCal^.displayDate.isoDate);

    LoadCal;

    if (myApplication.iCal^.entries > 0)
    then
    begin
      MyApplication.iCal^.sort;
      log.debug('INITMainWindow: call FilterCal');
      FilterCal(dtStr);
    end;

  end;

  if MyApplication.winCal <> NIL
  then
    MyApplication.winCal^.MakeWindow;

  displayDate.Free;
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

    Dispose(myApplication.iCal, Done);
    if (cellGr <> NIL)
    then
      Dispose(cellGr, Done);

    new (cellGr);
    cellGr^.init;

    directory := myPath;

    GetDate (year, month, day, dayOfWeek) ;
    dtStr := date2str(year, month, 1, FALSE);
    myApplication.winCal^.displayDate.dtStr2Obj(dtStr);

    LoadCal;
   
    if (myApplication.iCal^.entries > 0)
    then
    begin
      myApplication.iCal^.sort;
      log.debug('LoadMenu.Work: call FilterCal');
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


  month := displayDate.getMMFromIso;
  year  := displayDate.getYYYYFromIso;

  dec (month);

  if (month < 1)
  then
  begin
    month := 12;
    dec (year);
  end;

  dtStr := date2str(year, month, 1, FALSE);
  myApplication.winCal^.displayDate.dtStr2Obj(dtStr);

  log.debug('PrevMon.Work: call FilterCal');
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

  month := displayDate.getMMFromIso;
  year  := displayDate.getYYYYFromIso;

  inc (month);

  if (month > 12)
  then
  begin
    month := 1;
    inc (year);
  end;

  dtStr := date2str(year, month, 1, FALSE);
  myApplication.winCal^.displayDate.dtStr2Obj(dtStr);

  log.debug('NextMon.Work: call FilterCal');
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

  year  := displayDate.getYYYYFromIso;

  dec (year);

  dtStr := date2str(year, displayDate.getMMFromIso, 1, FALSE);
  myApplication.winCal^.displayDate.dtStr2Obj(dtStr);

  log.debug('PrevYear.Work: call FilterCal');
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

  year  := displayDate.getYYYYFromIso;

  inc (year);

  dtStr := date2str(year, displayDate.getMMFromIso, 1, FALSE);
  myApplication.winCal^.displayDate.dtStr2Obj(dtStr);

  log.debug('NextYear.Work: call FilterCal');
  FilterCal(dtStr);

  MyApplication.WinCal^.ForceRedraw;

  log.Free;

end;


procedure LoadCal;
var
  log       : TLogger;

begin
  log := TLogger.Create(LLINFO);

  new(myApplication.iCal);
  myApplication.iCal^.init;

  log.debug('Load ICS files from ' + directory);

  (* Load iCal events *)
  myApplication.iCal^.loadICS(directory);
  
  log.debug('loaded ', myApplication.iCal^.entries );

  log.Free;

end;


procedure FilterCal(dtStr : String);
var
  log       : TLogger;

begin
  log := TLogger.Create(LLDEBUG);
  log.debug('FilterCal ' + dtStr);

//  if (displayDate = NIL)
//  then
//    displayDate := TDateTime.create;

//  displayDate.dtStr2Obj(dtStr);
  myApplication.winCal^.displayDate.dtStr2Obj(dtStr);

  if (cellGr <> NIL)
  then
    dispose (cellGr, done);

  new (cellGr);
  cellGr^.init;
  cellGr^.FilterEvents(myApplication.iCal,
                       displayDate);
  log.debug('Cal displayed');

//  displayDate.Free;
  log.Free;

end;

end.
