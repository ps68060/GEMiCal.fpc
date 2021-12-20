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
    nameTk       = 'name';
    latTk        = 'lat';
    lngTk        = 'long';
    UTCoffsetTk  = 'UTCoffset';

  constructor TConfig.init;
  begin
    name      := 'default';
    lat       := 51.4779;
    lng       := 0.0;
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

    valReal      : Real;

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

      (* Get the name *)
      if ( pos(nameTk, currentLn) = 1 )
      then
        name := keyValue^.part[2];


      (* Get the latitude, if it is invalid, keep default *)
      if ( pos(latTk, currentLn) = 1 )
      then
      begin
        val(keyValue^.part[2], valReal, code);

        if (code <> 0)
        then
          writeln ('Real conversion error of lat');

        if (abs(valReal) > 90.0)
        then
          logger^.log(INFO, 'lat invalid, check gemical.cnf')
        else
          lat := valReal;

      end;


      (* Get the longitude, if it is invalid, keep default *)
      if ( pos(lngTk, currentLn) = 1 )
      then
      begin
        val(keyValue^.part[2], valReal, code);

        if (code <> 0)
        then
          writeln ('Real conversion error of lng');

        if (abs(valReal) > 180.0)
        then
          logger^.log(INFO, 'long invalid, check gemical.cnf')
        else
          lng := valReal;

      end;

      (* Get the UTC offset, if it is invalid, keep default *)
      if ( pos(UTCoffsetTk, currentLn) = 1 )
      then
      begin
        val(keyValue^.part[2], valReal, code);

        if (code <> 0)
        then
          writeln ('Real conversion error of UTCoffset');

        if (abs(valReal) > 12.0)
        then
          logger^.log(INFO, 'UTCoffset invalid, check gemical.cnf')
        else
          UTCoffset := valReal;

      end;

      Dispose (keyValue, Done);
    end;  (* while *)

    logger^.log(DEBUG, 'location = ' + name);
    logger^.logReal(DEBUG,'lat = ', lat);
    logger^.logReal(DEBUG,'lng = ', lng);
    logger^.logReal(DEBUG,'UTC ',   UTCoffset);

    close(cnfFile);
    Dispose (logger, Done);

  end;

end.