unit DlgAbout;

interface

  uses
    OTypes,
    OWindows,
    ODialogs;

{$I gemical.i}

const
  dDate    = '16.01.2022';
  dVersion = '0.0';                          (**  not used yet **)

type
  PDeskMenu    = ^TDeskMenu;   (* About *)

  (* Menu1 > About *)
  TDeskMenu  =  OBJECT(TKeyMenu)
                  d_Headline,
                  d_Infoline    : PStatic;   (* Text-element     *)
                  d_Frame       : PGroupBox; (* Groupbox-element *)
                  d_Icon        : PIcon;     (* PIcon-element    *)
                  o_Help,
                  d_Exit        : PButton;   (* Button-element   *)
                  procedure Work; VIRTUAL;
                end;

  PAboutDial   = ^TAboutDial;


  TAboutDial =  OBJECT(TDialog)
                  function OK   : Boolean;        VIRTUAL;
                  function HELP : Boolean;        VIRTUAL;
                  function GetIconTitle : String; VIRTUAL;
                end;



implementation


procedure TDeskMenu.Work;
begin

  if aDialog = NIL
  then
  begin
    aDialog := NEW (PAboutDial, INIT(NIL, 'InfoDialog', TREE001));
    new (d_Headline, INIT(aDialog, D_HEAD, 15, TRUE, 'The Title !'));
    new (d_Frame,    INIT(aDialog, D_BOX, 'Info', 'A Frame !'));

    new (d_Infoline, INIT(adialog, D_INFO, 26, FALSE, 'Version date'));
    d_Infoline^.SetText('' + dDate + ' ½ P.Slegg');

    new (d_Exit, INIT(aDialog, D_OK,   id_OK,   TRUE,  'Exit this dialog'));
    new (o_Help, INIT(aDialog, D_HELP, id_HELP, FALSE, 'Helptext'));
  end;

  if aDialog <> NIL
  then
    aDialog^.MakeWindow;

end;


function TAboutDial.OK: Boolean;
begin
  OK := TRUE;
end;  


function TAboutDial.HELP: Boolean;
begin
  Application^.Alert(@self,1,NO_ICON,'Enter a Latitude and Longitude and'+
                                     '|convert to a Grid Reference'+
                                     '|or vice versa.','&OK');
  HELP := FALSE;
end;


function TAboutDial.GetIconTitle: String;
begin
  GetIconTitle := 'INFO';
end;

end.