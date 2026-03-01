{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}
{$mode objfpc}

unit Logger;

interface
  uses
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

    procedure info (message  : String);
    procedure debug(message  : String);
    procedure warn (message  : String);
    procedure error(message  : String);


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


procedure TLogger.info(message  : String);
begin

  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLINFO, message);

end;


procedure TLogger.debug(message  : String);
begin

  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLDEBUG, message);

end;


procedure TLogger.warn(message  : String);
begin

  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLWARN, message);

end;


procedure TLogger.error(message  : String);
begin

  (**  writeln (ord(level), ' ; ', ord(msgLevel) );**)
  log(LLERROR, message);

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