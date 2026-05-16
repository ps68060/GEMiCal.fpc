{$I projopts.i}
{$mode objfpc}

unit Logger;

interface
  uses
    SysUtils,
    Objects;

type

  TLogLevel = (LLERROR, LLWARN, LLINFO, LLDEBUG);

  TLogger = class
  public
    level : TLogLevel;

    constructor Create(msgLevel : TLogLevel);
    destructor  Destroy; override;

    procedure log(msgLevel       : TLogLevel;
                  message  : String);

    procedure info (const message : ShortString);                       overload;
    procedure info (const message : ShortString; value : integer);      overload;
    procedure info (const message : ShortString; value : boolean);      overload;
    procedure info (const message : ShortString; value : real);         overload;
    procedure info (const message : ShortString; const value : string); overload;

    procedure debug(const message : ShortString);                       overload;
    procedure debug(const message : ShortString; value : integer);      overload;
    procedure debug(const message : ShortString; value : boolean);      overload;
    procedure debug(const message : ShortString; value : real);         overload;
    procedure debug(const message : ShortString; const value : string); overload;
    
    procedure warn (const message : ShortString);                       overload;
    procedure warn (const message : ShortString; value : integer);      overload;
    procedure warn (const message : ShortString; value : boolean);      overload;
    procedure warn (const message : ShortString; value : real);         overload;
    procedure warn (const message : ShortString; const value : string); overload;

    procedure error(const message : ShortString);                       overload;
    procedure error(const message : ShortString; value : integer);      overload;
    procedure error(const message : ShortString; value : boolean);      overload;
    procedure error(const message : ShortString; value : real);         overload;
    procedure error(const message : ShortString; const value : string); overload;
  end;

var
  LOG : TLogger;   // Global LOGGER like slf4p



implementation
uses
    Dos;

constructor TLogger.Create(msgLevel : TLogLevel);
begin
  inherited Create;
  level := msgLevel;
  (*writeln ('LOGGER ' + 'initiated'); *)
end;


destructor TLogger.Destroy;
begin
  inherited Destroy;
end;


procedure TLogger.log(msgLevel : TLogLevel;
                      message  : String);
var
  year,
  month,
  day,
  dayOfWeek    : Word;

begin
  (*writeln (ord(level), ' ; ', ord(msgLevel) );*)

  if (ord(level) >= ord(msgLevel) )
  then
  begin
    (* Get today's date *)
    GetDate (year, month, day, dayOfWeek);
    writeln(msgLevel, ': ', message);
  end;

end;

// ----- INFO

procedure TLogger.info(const message  : ShortString);
begin
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLINFO, message);
end;

procedure TLogger.info(const message  : ShortString; value : integer);
begin
  log(LLINFO, message + ': ' + IntToStr(value));
end;

procedure TLogger.info(const message  : ShortString; value : boolean);
begin
  if value
  then
    log(LLINFO, message + ': TRUE')
  else
    log(LLINFO, message + ': FALSE');
end;

procedure TLogger.info(const message  : ShortString; value : real);
var
  s : Shortstring;
begin
  str(value:0:6, s);
  log(LLINFO, message + ': ' + s);
end;

procedure TLogger.info(const message : ShortString; const value : Shortstring);
begin
  log(LLINFO, message + ': ' + value);
end;

// ----- DEBUG

procedure TLogger.debug(const message : ShortString);
begin
  log(LLDEBUG, message);
end;

procedure TLogger.debug(const message  : ShortString; value : integer);
begin
  log(LLDEBUG, message + ': ' + IntToStr(value));
end;

procedure TLogger.debug(const message : ShortString; value : boolean);
begin
  if value
  then
    log(LLDEBUG, message + ': TRUE')
  else
    log(LLDEBUG, message + ': FALSE');
end;

procedure TLogger.debug(const message: ShortString; value : real);
var
  s : Shortstring;
begin
  str(value:0:6, s);
  log(LLDEBUG, message + ': ' + s);
end;

procedure TLogger.debug(const message : ShortString; const value : ShortString);
begin
  log(LLDEBUG, message + ': ' + value);
end;

// ----- WARN

procedure TLogger.warn(const message : ShortString);
begin
  log(LLWARN, message);
end;

procedure TLogger.warn(const message : ShortString; value : integer);
begin
  log(LLWARN, message + ': ' + IntToStr(value));
end;

procedure TLogger.warn(const message : ShortString; value : boolean);
begin
  if value
  then
    log(LLWARN, message + ': TRUE')
  else
    log(LLWARN, message + ': FALSE');
end;

procedure TLogger.warn(const message : ShortString; value : real);
var
  s : ShortString;
begin
  str(value:0:6, s);
  log(LLWARN, message + ': ' + s);
end;

procedure TLogger.warn(const message : ShortString; const value: ShortString);
begin
  log(LLWARN, message + ': ' + value);
end;



procedure TLogger.error(const message : ShortString);
begin
  log(LLERROR, message);
end;

procedure TLogger.error(const message : ShortString; value : integer);
begin
  log(LLERROR, message + ': ' + IntToStr(value));
end;

procedure TLogger.error(const message : ShortString; value : boolean);
begin
  if value
  then
    log(LLERROR, message + ': TRUE')
  else
    log(LLERROR, message + ': FALSE');
end;

procedure TLogger.error(const message : ShortString; value : real);
var
  s : ShortString;
begin
  str(value:0:6, s);
  log(LLERROR, message + ': ' + s);
end;

procedure TLogger.error(const message : ShortString; const value : ShortString);
begin
  log(LLERROR, message + ': ' + value);
end;



initialization
  LOG := TLogger.Create(LLINFO);

finalization
  LOG.Free;


end.