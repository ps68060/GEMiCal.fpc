{$I projopts.i}
{$mode objfpc}
{$modeswitch typehelpers}

unit strnghlp;

(* AUTHOR  : P SLEGG
   DATE    : 14th June 2026 Version 1
   PURPOSE : TStringHelper.
*)


interface

type
  TStringArray = array of String;
  
  function Contains(const data : array of ShortString; const S: String)
          : Boolean;


implementation

function Contains(const data : array of ShortString; const S: String)
        : Boolean;
  var
    i        : Integer;

  begin
    for i := 0 to High(data)
    do
      if data[i] = S
      then
        Exit(True);
    
    Result := False;
  end;

end.