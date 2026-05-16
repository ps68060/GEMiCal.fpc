{$I projopts.i}
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
    code         : Integer;
    valReal      : Real;

  begin
    log.level := LLINFO;

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

  end;


  procedure TConfig.readConfig;
  var
    cnfFile      : Text;

    currentLn    : String;
    tokens       : TToken;
    code         : Integer;

    valReal      : Real;

  begin
    log.level := LLINFO;

    (* Open the config file for reading *)
    assign (cnfFile, 'GEMICAL.CNF');
    reset  (cnfFile);

    while (NOT eof (cnfFile))
    do
    begin
      readln (cnfFile, currentLn );

      tokens := TToken.Create;
      tokens.tokeniseInf(currentLn);

      (* Get the name *)
      if ( tokens.StartsWith(NAME_TK) )
      then
        name := tokens.part[1];

      (* Get the latitude, if it is invalid, keep default *)
      if ( tokens.StartsWith(LAT_TK) )
      then
        lat := getValue(tokens, lat, 90.0);

      (* Get the longitude, if it is invalid, keep default *)
      if ( tokens.StartsWith(LNG_TK) )
      then
        lng := getValue(tokens, lng, 180.0);

      (* Get the UTC offset, if it is invalid, keep default *)
      if ( tokens.StartsWith(UTC_OFFSET_TK) )
      then
        UTCoffset := getValue(tokens, UTCoffset, 12.0);

      tokens.Free;
    end;  (* while *)

    log.debug ('location = ' + name);
    log.debug ('lat = ', lat);
    log.debug ('lng = ', lng);
    log.debug ('UTC = ', UTCoffset);

    close(cnfFile);

  end;

end.