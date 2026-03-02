{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}
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


    procedure logBool(msgLevel : TLogLevel;
                      message  : String;
                      logical  : Boolean );

    procedure logInt(msgLevel : TLogLevel;
                     message  : String;
                     int      : Integer );

    procedure logLongInt(msgLevel : TLogLevel;
                         message  : String;
                         int      : LongInt );

    procedure logWord(msgLevel : TLogLevel;
                      message  : String;
                      myWord   : Word );

    procedure logReal(msgLevel : TLogLevel;
                      message  : String;
                      myReal   : Real );
  end;


implementation

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
begin

  writeln (ord(level), ' ; ', ord(msgLevel) );

  if (ord(level) >= ord(msgLevel) )
  then
    writeln(message);

end;


procedure TLogger.info(const message  : ShortString);
begin
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLINFO, message);
end;

procedure TLogger.info(const message  : ShortString; value : integer);
begin
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLINFO, message + ': ' + IntToStr(value));
end;

procedure TLogger.info(const message  : ShortString; value : boolean);
begin
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
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
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLINFO, message + ': ' + s);
end;

procedure TLogger.info(const message : ShortString; const value : Shortstring);
begin
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLINFO, message + ': ' + value);
end;


procedure TLogger.debug(const message : ShortString);
begin
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLDEBUG, message);
end;

procedure TLogger.debug(const message  : ShortString; value : integer);
begin
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLDEBUG, message + ': ' + IntToStr(value));
end;

procedure TLogger.debug(const message : ShortString; value : boolean);
begin
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  if value
  then
    log(LLDEBUG, message + ': TRUE')
  else
    log(LLDEBUG, message + ': FALSE')
end;

procedure TLogger.debug(const message: ShortString; value : real);
var
  s : Shortstring;
begin
  str(value:0:6, s);
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLDEBUG, message + ': ' + s);
end;

procedure TLogger.debug(const message : ShortString; const value : ShortString);
begin
  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLDEBUG, message + ': ' + value);
end;


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


procedure TLogger.logBool(msgLevel : TLogLevel;
                          message  : String;
                          logical  : Boolean );
var
  s        : string;
begin
  log (msgLevel, message + ':' + BoolToStr(logical, True));
end;


procedure TLogger.logInt(msgLevel : TLogLevel;
                         message  : String;
                         int      : Integer );
begin

  if (ord(level) >= ord(msgLevel) )
  then
    writeln(message, int);

end;


procedure TLogger.logLongInt(msgLevel : TLogLevel;
                             message  : String;
                             int      : LongInt );
begin

  if (ord(level) >= ord(msgLevel) )
  then
    writeln(message, int);

end;


procedure TLogger.logWord(msgLevel : TLogLevel;
                          message  : String;
                          myWord   : Word );
begin

  if (ord(level) >= ord(msgLevel) )
  then
    writeln(message, myWord);

end;



procedure TLogger.logReal(msgLevel : TLogLevel;
                          message  : String;
                          myReal   : Real );
begin

  if (ord(level) >= ord(msgLevel) )
  then
    writeln(message, myReal:10:5);

end;

end.