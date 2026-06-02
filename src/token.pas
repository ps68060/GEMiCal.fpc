{$I projopts.i}
{$mode objfpc}

unit Token;

(* AUTHOR  : P Slegg
 * DATE    : 19th Dec 2021 Version 1
 * PURPOSE : TToken object for lines of either iCal Event or INF key=value.
*)

interface
  uses
    Objects;


  type

    TToken = class
      part : array [0..3] of String;

    constructor Create;
    destructor  Destroy; override;

    procedure TokeniseIcal (line : String);

    procedure TokeniseInf  (line : String);

    function StartsWith (const token : String) : Boolean;

  end;


implementation

  uses
    StrUtils,
    Logger;

constructor TToken.Create;
  var
    i : Integer;
  begin
//    for i := 0 to 3
//    do
//      part[i] := '';
  end;

destructor TToken.Destroy;
  begin
    inherited Destroy;
  end;


procedure splitAt(divider     : Char;
                  line        : String;
                  var  before,
                       after       : String
                 );
  var
    posn        : Integer;

  begin
    posn := pos(divider, line);

    if (posn > 0)
    then
    begin
      before := COPY (line, 1,      posn-1 );
      after  := COPY (line, posn+1, MAXINT );
    end
    else
    begin
      before := line;
      after  := '';
    end;

  end;


function TToken.StartsWith (const token : String)
        : Boolean;
  begin
    startsWith := pos(token, part[0]) = 1;
  end;


procedure TToken.TokeniseIcal (line : String);
  (*
   * Purpose : Tokenise an iCal line into tag, qualifier and value.
   * The tag is the part before the first colon,
   *  the value is the part after.
   * The tag may have a qualifier separated by a semi-colon.
   * e.g. "DTSTART;VALUE=DATE:20220101" would be tokenised as
   *       part[0] = "DTSTART"
   *       part[1] = "VALUE=DATE"
   *       part[2] = "20220101"
   * or  "DTSTART;TZID=Europe/London:20200516T000000" would be tokenised as
   *       part[0] = "DTSTART"
   *       part[1] = "TZID=Europe/London"
   *       part[2] = "20200516T000000"
   *)
  var
    posn         : Integer;

  begin
    log.level := LLINFO;

    (* Token before colon *)
    splitAt (':', line, part[0], part[2]);

    (* Split part 0 at semi-colon *)
    splitAt (';', part[0], part[0], part[1]);

//    log.debug('tag    = ' + part[0]);
//    log.debug('qual   = ' + part[1]);
 
//    log.debug('value  = ' + part[2]);

  end;


procedure TToken.TokeniseInf (line : String);
  var
    posn         : Integer;

  begin
    log.level := LLINFO;

    (* Token before equals *)
    splitAt ('=', line, part[0], part[1]);

    log.debug('key    = ' + part[0]);
    log.debug('value  = ' + part[1]);
 
  end;

end.
