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
    NAME_TK        = 'name';
    LAT_TK         = 'lat';
    LNG_TK         = 'long';
    UTC_OFFSET_TK  = 'UTCoffset';

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


  function getValue(keyValue : TToken; value : real; limit: real) : real;
  var
    log          : TLogger;

    code         : Integer;
    valReal      : Real;

  begin
    log := TLogger.Create(LLINFO);

    getValue := value;
    val(keyValue.part[1], valReal, code);
    
    if (code <> 0)
    then
      log.error ('Real conversion error of ' + keyValue.part[0] + '=', keyValue.part[1]);
    
    if (abs(valReal) > limit)
    then
      log.warn(keyValue.part[0] + ' out of range, check gemical.cnf')
    else
      getValue := valReal;

    log.Free;

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

      keyValue := TToken.Create;
      keyValue.tokeniseInf(currentLn);

      (* Get the name *)
      if ( pos(NAME_TK, currentLn) = 1 )
      then
        name := keyValue.part[1];

      (* Get the latitude, if it is invalid, keep default *)
      if ( pos(LAT_TK, currentLn) = 1 )
      then
        lat := getValue(keyValue, lat, 90.0);

      (* Get the longitude, if it is invalid, keep default *)
      if ( pos(LNG_TK, currentLn) = 1 )
      then
        lng := getValue(keyValue, lng, 180.0);

      (* Get the UTC offset, if it is invalid, keep default *)
      if ( pos(UTC_OFFSET_TK, currentLn) = 1 )
      then
        UTCoffset := getValue(keyValue, UTCoffset, 12.0);

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