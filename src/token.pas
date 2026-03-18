{$B+,D-,I-,L-,N-,P-,Q-,R+,S-,T-,V-,X+,Z-}
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
  public
    part : array [0..3] of String;

    constructor Create;
    destructor  Destroy; override;

    procedure TokeniseIcal (line : String);

    procedure TokeniseInf  (line : String);
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
    inherited destroy;
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


  procedure TToken.TokeniseIcal (line : String);
  var
    log          : TLogger;
    posn         : Integer;

  begin
//    log := TLogger.Create(LLDEBUG);

    splitAt (':', line, part[0], part[2]);
    // Token before colon

    // Split part 0 at semi-colon
    splitAt (';', part[0], part[0], part[1]);

//    log.debug('tag    = ' + part[0]);
//    log.debug('qual   = ' + part[1]);
 
//    log.debug('value  = ' + part[2]);

//    log.Free;
  end;


  procedure TToken.TokeniseInf (line : String);
  var
    log          : TLogger;
    posn         : Integer;

  begin
    log := TLogger.Create(LLINFO);

    (* Token before equals *)
    splitAt ('=', line, part[0], part[1]);

    log.debug('key    = ' + part[0]);
    log.debug('value  = ' + part[1]);
 
    log.Free;
  end;

end.