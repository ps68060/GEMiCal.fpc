{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}

unit Logger;

interface
  uses
    Objects;

type

  a_level = (ERROR, WARN, INFO, DEBUG);

  PLogger = ^TLogger;
  TLogger = object(TObject)
    level : a_level;

    constructor init;
    destructor  done; virtual;

    procedure log(msgLevel : a_level;
                  message  : String);


    procedure logBool(msgLevel : a_level;
                      message  : String;
                      logical  : Boolean );

    procedure logInt(msgLevel : a_level;
                     message  : String;
                     int      : Integer );

    procedure logLongInt(msgLevel : a_level;
                         message  : String;
                         int      : LongInt );
  end;

implementation

constructor TLogger.init;
begin
  (*writeln ('LOGGER ' + 'initiated'); *)
end;

destructor TLogger.done;
begin

end;

procedure TLogger.log(msgLevel : a_level;
                      message  : String);
begin

(**  writeln (ord(level), ' ; ', ord(msgLevel) );**)

  if (ord(level) >= ord(msgLevel) )
  then
    writeln(message);

end;


procedure TLogger.logBool(msgLevel : a_level;
                          message  : String;
                          logical  : Boolean );
begin

  if (ord(level) >= ord(msgLevel) )
  then
    writeln(message, logical);

end;


procedure TLogger.logInt(msgLevel : a_level;
                         message  : String;
                         int      : Integer );
begin

  if (ord(level) >= ord(msgLevel) )
  then
    writeln(message, int);

end;



procedure TLogger.logLongInt(msgLevel : a_level;
                             message  : String;
                             int      : LongInt );
begin

  if (ord(level) >= ord(msgLevel) )
  then
    writeln(message, int);

end;


end.