{$I projopts.i}
{$mode objfpc}

unit MainIcal;

interface

uses
  owindows,

  DlgAbout,
  DlgConv,
  Cal,
  WinCal,
  Tos, aes, vdi,
  DateUtils,
  SysUtils;

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

  procedure FilterCal;

var
  myApplication : TMyApplication;


implementation

  uses
    Dos,
    gem,
    Logger,
    DateStrc,
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
    appDeskMenu    : PDeskMenu;
    appLoadMenu    : PLoadMenu;
    appDialogMenu  : PDialogMenu;
    appCalMenu     : PCalMenu;
    appNavPrevMon  : PNavPrevMon;
    appNavNextMon  : PNavNextMon;

    appNavPrevYear : PNavPrevYear;
    appNavNextYear : PNavNextYear;

  begin
    log.level := LLINFO;

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
  end;


procedure TMyApplication.INITMainWindow;
  var
    year,
    month,
    day,
    dayNumber : Word;

  begin
    log.level := LLDEBUG;
    log.debug('INIT Main Window');

    if MyApplication.winCal = NIL
    then
    begin
      myApplication.winCal := new(PWinCal, init(NIL, 'GEMiCal') );

      LoadCal;

      // calDate holds the date for the displayed calendar month.
      // Initially set to the current month.
      // Used to filter the events for the month.
      // Updated when the user navigates to a different month or year.

      GetDate (year, month, day, dayNumber);
      myApplication.winCal^.calDate := EncodeDateTime(year, month, 1, 00, 00, 00, 000);

      if (myApplication.iCal.entries > 0)
      then
      begin
///        MyApplication.iCal.sort;
           myApplication.iCal.eventList.sort(startDate.fpDate, true); // sort by start date, then by end date
        FilterCal;
      end;
    end;

    if MyApplication.winCal <> NIL
    then
      MyApplication.winCal^.MakeWindow;

    //myApplication.winCal^.calDate.free //todo ???;
  end;


procedure TLoadMenu.Work;
  begin
    log.level := LLINFO;
    log.info('Load Menu Work');

    if FileSelect(NIL, 'Load ICS file ', '*.*', myPath, myFile, TRUE)
    then
    begin
      BusyMouse;

      myApplication.iCal.Free;
      directory := myPath;
      LoadCal;

      if (myApplication.iCal.entries > 0)
      then
      begin
        myApplication.iCal.sort;
        FilterCal;
      end;

      MyApplication.WinCal^.ForceRedraw;

      ArrowMouse;
      log.debug('Loaded');
    end;
  end;


procedure TCalMenu.Work;
  begin
    log.level := LLINFO;
    log.debug('CalMenu Work');

    if aDialog <> NIL
    then
      aDialog^.MakeWindow;

    (* Window *)
    if MyApplication.WinCal = NIL
    then
    begin
      MyApplication.WinCal := new(PWinCal, Init(NIL, dAppName));
      MyApplication.WinCal^.SetSubTitle('Calendar Month');
    end;

    if MyApplication.WinCal <> NIL
    then
      MyApplication.WinCal^.MakeWindow;
  end;


procedure TNavPrevMon.Work;
  begin
    log.level := LLINFO;
    log.debug('Prev Month Work');

    myApplication.winCal^.calDate := IncMonth(myApplication.winCal^.calDate, -1);

    FilterCal;

    MyApplication.WinCal^.ForceRedraw;
  end;


procedure TNavNextMon.Work;
  begin
    log.level := LLINFO;
    log.debug('Next Month Work');

    myApplication.winCal^.calDate := IncMonth(myApplication.winCal^.calDate, 1);
  
    FilterCal;

    MyApplication.WinCal^.ForceRedraw;
  end;


procedure TNavPrevYear.Work;
  begin
    log.level := LLINFO;
    log.debug('Prev Year Work');

    myApplication.winCal^.calDate := IncYear(myApplication.winCal^.calDate, -1);

    FilterCal;

    MyApplication.WinCal^.ForceRedraw;
  end;


procedure TNavNextYear.Work;
  begin
    log.level := LLINFO;
    log.debug('Next Year Work');

    myApplication.winCal^.calDate := IncYear(myApplication.winCal^.calDate, 1);

    FilterCal;

    MyApplication.WinCal^.ForceRedraw;
  end;


procedure LoadCal;
(*
 * Purpose: Load all the *.ics files in directory.
 *)
  begin
    log.level := LLINFO;
    myApplication.iCal := TCal.Create;

    log.debug('Load ICS files from ' + directory);

    (* Load iCal events *)
    myApplication.iCal.loadICS(directory);
  
    log.debug('loaded ', myApplication.iCal.entries );
  end;


procedure FilterCal;
  (*
   * Purpose: Get the events for the date.
   *)
  begin
    log.level := LLDEBUG;
    log.debug('FilterCal: start');
    log.debug('FilterCal: date= ', DateToISO8601(myApplication.winCal^.calDate, false) );

    if (cellGr <> NIL)
    then
      cellGr.Free;

    cellGr := TCellGrid.Create;
    cellGr.FilterEvents(myApplication.iCal,
                      myApplication.winCal^.calDate);
    log.debug('FilterCal: done');

  end;

end.
