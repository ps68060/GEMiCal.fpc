unit Config;

interface

  uses
   Objects;


type
  PConfig = ^TConfig;
  TConfig = object(TObject)
    name        : String;
    lat         : Real;
    lng         : Real;
    UTCoffset   : Real;

    constructor init;
    destructor  done; virtual;

    procedure readConfig;
  end;


implementation

uses
  Logger,
  Token;

  const
    latTk        = 'lat';
    lngTk        = 'long';
    UTCoffsetTk  = 'UTCoffset';

  constructor TConfig.init;
  begin
    name := 'default';
    lat  := 51.4779;
    lng  := 0.0;
    UTCoffset := 0.0;
  end;


  destructor TConfig.done;

  begin

  end;


  procedure TConfig.readConfig;
  var
    logger       : PLogger;
    cnfFile      : Text;

    currentLn    : String;
    keyValue     : PToken;
    code         : Integer;

  begin
    new(logger);
    logger^.init;
    logger^.level := DEBUG;

    (* Open the config file for reading *)
    assign (cnfFile, 'gemical.cnf');
    reset  (cnfFile);

    while (NOT eof (cnfFile))
    do
    begin
      readln (cnfFile, currentLn );

      new(keyValue);
      keyValue^.init;

      keyValue^.tokeniseInf(currentLn);

      if ( pos(latTk, currentLn) = 1 )
      then
        val(keyValue^.part[2], lat, code);

      if (code <> 0)
      then
        writeln ('Real conversion error of lat');


      if ( pos(lngTk, currentLn) = 1 )
      then
        val(keyValue^.part[2], lng, code);

      if (code <> 0)
      then
        writeln ('Real conversion error of lng');


      if ( pos(UTCoffsetTk, currentLn) = 1 )
      then
        val(keyValue^.part[2], UTCoffset, code);

      if (code <> 0)
      then
        writeln ('Real conversion error of UTCoffset');

      Dispose (keyValue, Done);
    end;  (* while *)

    logger^.logReal(DEBUG,'lat = ', lat);
    logger^.logReal(DEBUG,'lng = ', lng);
    logger^.logReal(DEBUG,'UTC ', UTCoffset);

    close(cnfFile);
    Dispose (logger, Done);

  end;

end.