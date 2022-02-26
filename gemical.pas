{$B+,D+,G-,I-,P-,Q-,R+,S-,T-,V-,X+,Z-}
{$X+}
{$M 32768}

program GemICal;

uses
  MainIcal;

(* ---------------------------- M A I N ---------------------------- *)

begin

  MyApplication.INIT(dAppName);
  MyApplication.Run;

  Dispose(myApplication.iCal, Done);

  MyApplication.Done;

end.
