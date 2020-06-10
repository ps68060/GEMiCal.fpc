{$B+,D+,G-,I-,L-,P-,Q-,R+,S-,T-,V-,X+,Z-}
{$X+}
{$M 32768}

program GemICal;

uses
  Dos,
  Gem,
  OWindows,

  Cal,
  DateTime,
  Logger,

  DlgAbout,
  DlgConv,
  WinCal;

{$I gemical.i}

type
  (* Each object has variables and methods associated with it. *)

  (* Main Menu *)

  PFileMenu    = ^TFileMenu;

  PLoadMenu    = ^TLoadMenu;

  PCalMenu     = ^TCalMenu;

  TFileMenu  =  OBJECT(TKeyMenu)
                  procedure Work; VIRTUAL;
                END;

  TLoadMenu =  OBJECT(TKeyMenu)
                 procedure Work; VIRTUAL;
               end;

  (* Menu2 > Calendar Window *)
  TCalMenu  =   OBJECT(TKeyMenu)
                  procedure Work; VIRTUAL;
                end;

  TMyApplication = OBJECT(TApplication)
                     fileMenu   : PFileMenu;
                     convMenu   : PConvMenu;
                     winCal     : PWinCal;
                     procedure INITInstance;   VIRTUAL;
                     procedure INITMainWindow; VIRTUAL;
                   end;


(* ------------------------------------------------------------------------------- *)

var
  MyApplication : TMyApplication;

  myFile,
  myPath        : String;

  directory     : String;
  logger        : PLogger;

(* ------------------------------------------------------------------------------- *)

procedure TMyApplication.INITInstance;
begin
  LoadResource ('GEMICAL.RSC','');

  (* Load and set-up the menu *)
  LoadMenu (TREE000);

  new (PDeskMenu,  INIT(@SELF, K_Ctrl, Ctrl_I, M_INFO,     M_DESK1));
(**  new (FileMenu,   INIT(@SELF, K_Ctrl, Ctrl_B, M_FOLDER,   M_DESK2));   **)
  new (PLoadMenu,  INIT(@SELF, K_Ctrl, Ctrl_L, M_FOLDER,   M_DESK2));
  new (convMenu,   INIT(@SELF, K_Ctrl, Ctrl_C, M_DIALOG,   M_DESK2));    (* This needs to be pointer DialogMenu *)
  new (PCalMenu,   Init(@SELF, K_Ctrl, Ctrl_M, M_CALENDAR, M_DESK2));

  INHERITED INITInstance;
  SetQuit (M_END, M_DESK2);

end;


procedure LoadCal;
var
  year,
  month,
  day,
  dayOfWeek : Word;

  dtStr     : String;

begin
    new(myApplication.winCal^.cal);
    myApplication.winCal^.cal^.init;

    (* Load iCal events *)
    myApplication.winCal^.cal^.loadICS(directory);

    logger^.logInt(DEBUG, 'entries ', myApplication.winCal^.cal^.entries );

    myApplication.winCal^.cal^.sort;

    (* Display this month's calendar *)
    GetDate (year, month, day, dayOfWeek) ;
    dtStr := date2Str(year, month, 1, FALSE);

    new(MyApplication.winCal^.calDate);
    myApplication.winCal^.calDate^.init;

    myApplication.winCal^.calDate^.dtStr2Obj(dtStr);
    myApplication.winCal^.calDate^.dayOfWeek;

end;


procedure TMyApplication.INITMainWindow;

begin
  logger^.level := DEBUG;

  logger^.log(DEBUG, 'INIT Main Window');

  if MyApplication.winCal = NIL
  then
  begin
    myApplication.winCal := new(PWinCal, init(NIL, 'GEMiCal') );

    LoadCal;
  end;

  if MyApplication.winCal <> NIL
  then
    MyApplication.winCal^.MakeWindow;

end;

(* ------------------------------------------------------------------------------- *)

procedure TLoadMenu.Work;
begin
  writeln ('Load Menu Work');
  if FileSelect(NIL, 'Load ICS file ', '*.*', myPath, myFile, TRUE)

  then
  begin
    BusyMouse;
    Dispose(myApplication.winCal^.cal, Done);

    directory := myPath;
    LoadCal;

    ArrowMouse;

    MyApplication.FileMenu^.Work;

  end;

end;


procedure TFileMenu.Work;
begin
  logger^.log(DEBUG, 'FileMenu Work');

  if MyApplication.WinCal = NIL
  then
    MyApplication.WinCal := new(PWinCal, INIT(NIL,'GEMiCal') );

  if MyApplication.WinCal <> NIL
  then
    MyApplication.WinCal^.MakeWindow;

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

(* ----------------------------------------------------------------- *)

(* ---------------------------- M A I N ---------------------------- *)

begin
  new(logger);
  logger^.init;
  logger^.level := INFO;

  directory := 'e:\develop\pascal\gemical\';

  MyApplication.INIT(dAppName);
  MyApplication.Run;
  MyApplication.Done;

  Dispose (logger, Done);
end.
