unit Token;

(* AUTHOR  : P Slegg
   DATE    : 19th Dec 2021 Version 1
   PURPOSE : TToken object for lines of either iCal Event or INF key=value.
*)

interface
  uses
    Objects;


type

  PToken = ^TToken;
  TToken = object(TObject)
    part : array [0..3] of String;

    constructor init;
    destructor  done; virtual;

    procedure TokeniseIcal (line : String);

    procedure TokeniseInf  (line : String);
  end;


implementation

uses
  Logger;

  constructor TToken.init;
  var
    i : Integer;
  begin
    for i := 0 to 3
    do
      part[i] := '';
  end;

  destructor TToken.done;
  begin

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
      before := COPY (line, 0,      posn-1 );
      after  := COPY (line, posn+1, length(line) );
    end
    else
    begin
      before := line;
      after  := '';
    end;

  end;


  procedure TToken.TokeniseIcal (line : String);
    var
    logger       : PLogger;
    posn         : Integer;

  begin
    new(logger);
    logger^.init;

    logger^.level := INFO;

    (* Token before colon *)
    splitAt (':', line, part[0], part[2]);

    (* Split part 0 at semi-colon *)
    splitAt (';', part[0], part[0], part[1]);

    logger^.log(DEBUG, 'tag    = ' + part[0]);
    logger^.log(DEBUG, 'qual   = ' + part[1]);
 
    logger^.log (DEBUG, 'value = ' + part[2]);

    dispose(logger);
  end;


  procedure TToken.TokeniseInf (line : String);
  var
    logger       : PLogger;
    posn         : Integer;

  begin
    new(logger);
    logger^.init;

    logger^.level := INFO;

    (* Token before equals *)
    splitAt ('=', line, part[0], part[1]);

    logger^.log(DEBUG, 'key    = ' + part[0]);
    logger^.log(DEBUG, 'value  = ' + part[1]);
 
    dispose(logger);
  end;

end.