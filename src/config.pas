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
    Timezone    : String;

    constructor create;
    destructor  destroy; override;

    procedure readConfig;
  end;


implementation

  uses
    Logger,
    SysUtils,
    StrUtils;

  const
    COMMENT_TK     = '#';
    NAME_TK        = 'name';
    LAT_TK         = 'lat';
    LNG_TK         = 'long';
    UTC_OFFSET_TK  = 'UTCoffset';
    TIMEZONE_TK    = 'Timezone';

constructor TConfig.create;
  begin
    name      := 'default';
    lat       := 51.4779;
    lng       := 0.0;
    UTCoffset := 0.0;
    Timezone  := 'UTC';

    readConfig;
  end;


destructor TConfig.destroy;
  begin
    inherited Destroy;
  end;


function GetValue(keyValue : String;
                  value    : real;
                  limit    : real)
        : real;

  var
    code         : Integer;
    valReal      : Real;

  begin
    log.level := LLINFO;

    GetValue := value;
    val (keyValue, valReal, code);

    if (code <> 0)
    then
      log.error ('Real conversion error of ' + keyValue);

    if (abs(valReal) > limit)
    then
      log.warn(keyValue + ' out of range, check gemical.cnf')
    else
      GetValue := valReal;
  end;


procedure TConfig.readConfig;
  var
    cnfFile      : Text;

    currentLn    : String;

    parts        : TStringArray;

  begin
    log.level := LLINFO;

    (* Open the config file for reading *)
    assign (cnfFile, 'GEMICAL.CNF');
    reset  (cnfFile);

    while (NOT eof (cnfFile))
    do
    begin
      readln (cnfFile, currentLn );
      
      // Split at the first equals sign into parts[] array
      parts := SplitString(currentLn, '=');

      name := parts[0];

      case parts[0] of
        COMMENT_TK:
          break;

        NAME_TK:       (* Get the name *)
          name := parts[1];

        LAT_TK:        (* Get the latitude, if it is invalid, keep default *)
          lat := GetValue(parts[1], lat, 90.0);

        LNG_TK:        (* Get the longitude, if it is invalid, keep default *)
          lng := GetValue(parts[1], lng, 180.0);

        UTC_OFFSET_TK: (* Get the UTC offset, if it is invalid, keep default *)
          UTCoffset := GetValue(parts[1], UTCoffset, 12.0);

        TIMEZONE_TK:   (* Get the local Timezone *)
          Timezone := parts[1];
      end;  (* case *)
    end;  (* while *)

    log.debug ('location = ' + name);
    log.debug ('lat = ', lat);
    log.debug ('lng = ', lng);
    log.debug ('UTC = ', UTCoffset);

    close(cnfFile);
  end;

end.