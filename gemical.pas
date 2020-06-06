{$B+,D+,G-,I-,L-,P-,Q-,R+,S-,T-,V-,X+,Z-}
{$X+}
{$M 32768}

PROGRAM GemICal;

uses
  Gem,
  OWindows,

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
                     FileMenu   : PFileMenu;
                     ConvMenu   : PConvMenu;
                     WinCal     : PWinCal;
                     procedure INITInstance;   VIRTUAL;
                     procedure INITMainWindow; VIRTUAL;
                   end;


(* ------------------------------------------------------------------------------- *)

var
  MyApplication : TMyApplication;

  myFile,
  myPath        : String;

(* ------------------------------------------------------------------------------- *)

procedure TMyApplication.INITInstance;
begin
  LoadResource ('GEMICAL.RSC','');

  (* Load and set-up the menu *)
  LoadMenu (TREE000);

  new (PDeskMenu,  INIT(@SELF, K_Ctrl, Ctrl_I, M_INFO,     M_DESK1));
(**  new (FileMenu,   INIT(@SELF, K_Ctrl, Ctrl_B, M_FOLDER,   M_DESK2));   **)
  new (PLoadMenu,  INIT(@SELF, K_Ctrl, Ctrl_L, M_FOLDER,   M_DESK2));
  new (ConvMenu,   INIT(@SELF, K_Ctrl, Ctrl_C, M_DIALOG,   M_DESK2));    (* This needs to be pointer DialogMenu *)
  new (PCalMenu,   Init(@SELF, K_Ctrl, Ctrl_M, M_CALENDAR, M_DESK2));

  INHERITED INITInstance;
  SetQuit (M_END, M_DESK2);

end;


procedure TMyApplication.INITMainWindow;
begin
  writeln ('INIT Main Window');

  if MyApplication.WinCal = NIL
  then
  begin
    MyApplication.WinCal := new(PWinCal, init(NIL, 'GEMiCal') );
    MyApplication.WinCal^.calDate^.yyyy := 2020;
    MyApplication.WinCal^.calDate^.mm := 6;
  end;

  if MyApplication.WinCal <> NIL
  then
    MyApplication.WinCal^.MakeWindow;

end;


(* ------------------------------------------------------------------------------- *)


procedure TFileMenu.Work;
begin
  writeln ('FileMenu Work');

  if MyApplication.WinCal = NIL
  then
    MyApplication.WinCal := new(PWinCal, INIT(NIL,'GEMiCal') );

  if MyApplication.WinCal <> NIL
  then
    MyApplication.WinCal^.MakeWindow;

end;


procedure TLoadMenu.Work;
begin
  writeln ('Load Menu Work');
  if FileSelect(NIL, 'Load ICS file ', '*.*', myPath, myFile, TRUE)
  then
  begin
    BusyMouse;
    MyApplication.FileMenu^.Work;

	(**			MyApplication.TBrowser^.Clear;
				MyApplication.TBrowser^.Read(PFAD+DATEI);
				{# so wird eine Zeile angefÅgt #}
	(**			{MyApplication.TBrowser^.AddLine('--- EOF ---');} 
				MyApplication.TBrowser^.SetTitle(' '+DATEI+' ');  **)

    ArrowMouse;
  end;

end;


procedure TCalMenu.Work;
begin
  writeln ('CalMenu Work');

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
  MyApplication.INIT(dAppName);
  MyApplication.Run;
  MyApplication.Done;
end.
