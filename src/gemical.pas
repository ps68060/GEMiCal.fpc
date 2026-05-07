{$I projopts.i}
{$APPTYPE GUI}
{$M 32768}


program GemICal;

uses
  MainIcal;

(* ---------------------------- M A I N ---------------------------- *)

begin

  MyApplication.INIT(dAppName);
  MyApplication.Run;

  myApplication.iCal.Free;

  MyApplication.Done;

end.
