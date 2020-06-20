{$B+,D+,G-,I-,L-,P-,Q-,R+,S-,T-,V-,X+,Z-}
{$X+}
{$M 32768}

program GemICal;

uses
  MainIcal;

(* ---------------------------- M A I N ---------------------------- *)

begin

  MyApplication.INIT(dAppName);
  MyApplication.Run;

  Dispose(myApplication.winCal^.cal, Done);

  MyApplication.Done;

end.
