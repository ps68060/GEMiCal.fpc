unit DlgConv;


interface

  uses
    OTypes,
    OWindows,
    ODialogs;

{$I gemical.i}

const
  dAppName = 'GEMiCal';

type
  PDialogMenu  = ^TDialogMenu;

  (* Menu2 > Dialogue Dialogue *)
  TDialogMenu  =  OBJECT(TKeyMenu)
                    o_Button_A,
                    o_Button_B,
                    o_Button_C,
                    o_Button_D,
                    o_Exit        : PButton;
                    o_Box         : PGroupBox;
                    procedure Work; VIRTUAL;
                  end;


  PDialogDial  = ^TDialogDial; 
  TDialogDial  =  OBJECT(TDialog)
                    function ExitDlg (anIndx: Integer): Boolean; VIRTUAL;
                    function OK                       : Boolean; VIRTUAL;
                    function GetIconTitle: String;               VIRTUAL;
                  end;


implementation

var
  Buffer     : RECORD
                 Latitude
                ,Longitude : String[7];
               end;


procedure TDialogMenu.Work;

(* Purpose Create and render the Calendar Dialogue. *)

begin

  (* Create dialogue *)
  if aDialog = NIL
  then
  begin
    aDialog := new (PDialogDial, INIT (NIL, dAppName, TREE002));

    new (o_Exit,     INIT (aDialog, B_EXIT,       id_NO, TRUE,       (* id_NO calls the .ExitDlg function *)
                           'Close the dialog'));

    new (o_Button_A, INIT (aDialog, B_PREV_MONTH, id_OK, TRUE,       (* id_OK calls the .OK function *)
                           'Prev Month'));

    new (o_Button_B, INIT (aDialog, B_NEXT_MONTH, id_OK, TRUE,
                           'Next Month'));

    new (o_Button_C, INIT (aDialog, B_PREV_YEAR, id_OK, TRUE,
                           'Prev Year'));

    new (o_Button_D, INIT (aDialog, B_NEXT_YEAR, id_OK, TRUE,
                           'Prev Year'));
(**
    new (o_Box,      INIT (ADialog, D_BOX,    'A Box',
                           'Lat, Long Datum'));
**)
    aDialog^.TransferBuffer := @Buffer;

  end;

  (* Display the dialogue *)
  if aDialog <> NIL
  then
    aDialog^.MakeWindow;

end;


function TDialogDial.OK: Boolean;

(* Purpose : If any OK button is pressed then this routine is called *)

VAR
  i,
  AnIndx  : Integer;
  Valid   : Boolean;

  Msg,
  Latitude, Longitude,
  Easting,  Northing  : String;


begin
  Valid := INHERITED OK;

  if Valid = TRUE
  then
  begin

    (* Convert from Latitude/Longitude to Grid reference *)

    Latitude  := Buffer.Latitude;
    Longitude := Buffer.Longitude;

(**      Application^.Alert( @self, 1, NO_ICON, 'OK DIALOG button 1'
                                           + '| Lat = ' + Latitude
                                           + '| Long= ' + Longitude, '&OK');
**)

  end;  (* if valid *)

  OK := FALSE;                                        (* Determines whether the Dialog exits afterwards. *)

end;  


function TDialogDial.ExitDlg (AnIndx:Integer): Boolean;

(* Purpose : If any EXIT button is pressed this routine is called *)

begin
  (**WRITELN ('EXITDLG ', AnIndx); **)
  ExitDlg := TRUE;                                    (* Determines whether the Dialog exits afterwards. *)

  CASE AnIndx OF
    B_PREV_MONTH:
    begin
      (**WRITELN('Button A = <', MyApplication.Desk2Menu^.o_Button_A^.GetText, '>'); **)
(***
      IF MyApplication.Desk2Menu^.o_Button_A^.GetText = 'To Grid'
      THEN
        MyApplication.Desk2Menu^.o_Button_A^.SetText  ('&To Polar')

      ELSE
        MyApplication.Desk2Menu^.o_Button_A^.SetText  ('&To Grid ');
***)
      ExitDlg := FALSE;                               (* Determines whether the Dialog exits afterwards. *)

    end;

  end;
end;  

function TDialogDial.GetIconTitle : String;
begin
  GetIconTitle := 'Button';
end;


end.