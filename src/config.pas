{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}
{$mode objfpc}

unit Config;

interface
  uses
   Objects;


type
  TConfig = class
    name        : String;
    lat         : Real;
    lng         : Real;
    UTCoffset   : Real;

    constructor create;
    destructor  destroy; override;

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

  constructor TConfig.create;
  begin
    name      := 'default';
    lat       := 51.4779;
    lng       := 0.0;
    UTCoffset := 0.0;

    readConfig;
  end;


  destructor TConfig.destroy;
  begin
    inherited Destroy;
  end;


  procedure TConfig.readConfig;
  var
    log          : TLogger;
    cnfFile      : Text;

    currentLn    : String;
    keyValue     : TToken;
    code         : Integer;

    valReal      : Real;

  begin
    log := TLogger.Create(LLINFO);

    (* Open the config file for reading *)
    assign (cnfFile, 'GEMICAL.CNF');
    reset  (cnfFile);

    while (NOT eof (cnfFile))
    do
    begin
      readln (cnfFile, currentLn );

      keyValue.Create;

      keyValue.tokeniseInf(currentLn);

      (* Get the name *)
      if ( pos(nameTk, currentLn) = 1 )
      then
        name := keyValue.part[1];


      (* Get the latitude, if it is invalid, keep default *)
      if ( pos(latTk, currentLn) = 1 )
      then
      begin
        val(keyValue.part[1], valReal, code);

        if (code <> 0)
        then
          writeln ('Real conversion error of lat: ', keyValue.part[1]);

        if (abs(valReal) > 90.0)
        then
          log.info('lat invalid, check gemical.cnf')
        else
          lat := valReal;

      end;


      (* Get the longitude, if it is invalid, keep default *)
      if ( pos(lngTk, currentLn) = 1 )
      then
      begin
        val(keyValue.part[1], valReal, code);

        if (code <> 0)
        then
          writeln ('Real conversion error of lng: ', keyValue.part[1]);

        if (abs(valReal) > 180.0)
        then
          log.info('long invalid, check gemical.cnf')
        else
          lng := valReal;

      end;

      (* Get the UTC offset, if it is invalid, keep default *)
      if ( pos(UTCoffsetTk, currentLn) = 1 )
      then
      begin
        val(keyValue.part[1], valReal, code);

        if (code <> 0)
        then
          writeln ('Real conversion error of UTCoffset: ', keyValue.part[1]);

        if (abs(valReal) > 12.0)
        then
          log.info('UTCoffset invalid, check gemical.cnf')
        else
          UTCoffset := valReal;

      end;

      keyValue.Free;
    end;  (* while *)

    log.debug ('location = ' + name);
    log.debug ('lat = ', lat);
    log.debug ('lng = ', lng);
    log.debug ('UTC = ', UTCoffset);

    close(cnfFile);
    log.Free;

  end;

end.