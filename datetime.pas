unit datetime;


(* AUTHOR  : P SLEGG
   DATE    : 17th May 2020 Version 1
   PURPOSE : TDateTime object for the parsed an converted ICS Event.
*)

interface
  uses
    Objects;

const
  daySec  = 86400;
  hourSec = 3600;
  minSec  = 60;

  mon1   : array [1..12] of String
         = ('January', 'February', 'March',     'April',   'May',      'June',
            'July',    'August',   'September', 'October', 'November', 'December');

  mon2   : array [1..12] of String
         = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

  daysMon : array [1..12] of Integer
          = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

  day1   : array [0..6] of String
         = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');

  day2   : array [0..6] of String
         = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

type
  PDateTime = ^TDateTime;
  TDateTime = object(TObject)
    tz      : String;

    isoDate : String;
    isoTime : String;
    epoch   : LongInt;
    julian  : Double;

    day     : Integer;

    constructor init;
    destructor  done; virtual;

    procedure dtStr2Obj(dtString : String);

    function getYYYYFromIso
            : Integer;

    function getMMFromIso
            : Integer;

    function getDDFromIso
            : Integer;

    function getHrFromIso
            : Integer;

    function getMinFromIso
            : Integer;
            
    function getSecFromIso
            : Integer;

    procedure calcEpoch;

    function julianDate
            : Double;

    procedure dayOfWeek;

    procedure writeDT;

    function humanDateTime
            : String;

    function isAllDay
            : Boolean;

  end;


  function date2Str(year, month, day : Word;
                    human : Boolean)
          : String;

  function time2Str(hour, minute, second : Word;
                    human : Boolean)
          : String;

  procedure timeBetween(epoch1, epoch2:LongInt;
                        var dd,
                            hh,
                            mi,
                            ss : Integer;
                        var future : Boolean);

  function isLeapDay(y : Integer)
          : Boolean;

  function daysInMonth(myDate : PDateTime)
          :Integer;


implementation

uses
    Logger,
    StrSubs;

  constructor TDateTime.init;
  begin
    isoDate := '19700101';

    isoTime := '000000';
    tz   := '';

    epoch  := 0;
    julian := 2440587.5;
    day    := 4;
  end;

  destructor TDateTime.done;
  begin

  end;


  procedure TDateTime.dtStr2Obj(dtString : String);
  var
   code : Integer;
   date1, date2 : Double;
   logger       : PLogger;

  begin
    new(logger);
    logger^.init;
    logger^.level := INFO;

    logger^.log(DEBUG, 'converting date-time  ' + dtString);

    isoDate := SubStr(dtString, 1, 8);
    isoTime := COPY(dtString, 10, 6);
(*
    val ( COPY (dtString, 10, 2), hh24, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of hh24 at ', code, ' in ', dtString);

    val ( COPY (dtString, 12, 2), mi, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of mi at ', code, ' in ', dtString);

    val ( COPY (dtString, 14, 2), ss, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of ss at ', code, ' in ', dtString);
*)
    if (length(dtString) >= 16 )
    then
      tz := COPY (dtString, 16, length(dtString) );

    logger^.log(DEBUG, 'dtStr2Obj date ' + isoDate);
  (*  logger^.log(DEBUG, 'dtStr2Obj time ' + isoTime);*)

    date2 := julianDate;
    (*writeln('JDN      ', date2:12:2 ); *)

    calcEpoch;
    (*writeln('epoch = ', epoch); *)

    dayOfWeek;

    Dispose (logger, Done);
  end;



  function TDateTime.getYYYYFromIso
          : Integer;
  var
    code  : Integer;
    year4 : Integer;

  begin
    year4 := 1970;
    val ( COPY (isoDate, 1, 4), year4, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of year at ', code, ' in ', isoDate);

    getYYYYFromIso := year4;

  end;


  function TDateTime.getMMFromIso
          : Integer;
  var
    code   : Integer;
    month2 : Integer;

  begin
    month2 := 1;
    val ( COPY (isoDate, 5, 2), month2, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of month at ', code, ' in ', isoDate);

    getMMFromIso := month2;

  end;


  function TDateTime.getDDFromIso
          : Integer;
  var
    code   : Integer;
    day2   : Integer;

  begin
    day2 := 1;
    val ( COPY (isoDate, 7, 2), day2, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of day-date at ', code, ' in ', isoDate);

    getDDFromIso := day2;

  end;


  function TDateTime.getHrFromIso
          : Integer;
  var
    code   : Integer;
    hr2    : Integer;

  begin
    hr2 := 0;
    val ( COPY (isoTime, 1, 2), hr2, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of hour at ', code, ' in ', isoTime);

    getHrFromIso := hr2;

  end;


  function TDateTime.getMinFromIso
          : Integer;
  var
    code   : Integer;
    min2   : Integer;

  begin
    min2 := 0;
    val ( COPY (isoTime, 3, 2), min2, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of mi at ', code, ' in ', isoTime);

    getMinFromIso := min2;

  end;


  function TDateTime.getSecFromIso
          : Integer;
  var
    code   : Integer;
    sec2   : Integer;

  begin
    sec2 := 0;
    val ( COPY (isoTime, 5, 2), sec2, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of ss at ', code, ' in ', isoTime);

    getSecFromIso := sec2;

  end;



  procedure TDateTime.calcEpoch;
  const
    epochJD = 2440587.50;  (*  1970/01/01 00:00:00 *)

  var
    calc : LongInt;

  begin

    (*writeln (yyyy, '/', mm, '/', dd, ' ', hh24, ':', mi, ':', ss); *)

    epoch := trunc( julianDate - epochJD ) * daySec;

    epoch := epoch + trunc(getHrFromIso) * hourSec;

    epoch := epoch + getMinFromIso   * 60;

    epoch := epoch + getSecFromIso;

  end;


  function TDateTime.julianDate
          : Double;
  var
    y, m, d  : double;

    lyyyy,
    lmm,
    ldd      : integer;

    part1,
    part2,
    part3,
    part4    : double;

    logger   : PLogger;

  begin
    new(logger);
    logger^.init;
    logger^.level := INFO;
    
    lyyyy := getYYYYFromIso;
    lmm   := getMMFromIso;
    ldd   := getDDFromIso;

    part1 := (1461 * (lyyyy + 4800 + trunc((lmm - 14) / 12) )) div 4;
    part2 := (367 * (lmm - 2 - 12 * ((lmm - 14) div 12))) div 12 ;
    part3 := (3 * ((lyyyy + 4900 + (lmm - 14) div 12) div 100)) div 4 ;
    part4 := ldd - 32075 ;

    (*
    writeln('part1 : ', part1:20:10);
    writeln('part2 : ', part2:20:10);
    writeln('part3 : ', part3:20:10);
    writeln('part4 : ', part4:20:10);
    *)

    julian := part1 + part2 - part3 + part4;

    (* Julian day is based on midday so if the hour is less than 12 it is the previous day. *)
    if (getHrFromIso < 12)
    then
      julian := julian - 0.5;

    logger^.logReal(DEBUG, 'Julian date is ', julian);
    Dispose (logger, Done);

    julianDate := julian;
  end;


  procedure TDateTime.dayOfWeek;
  var
    t : array [0..11] of Integer;
    lyyyy,
    lmm,
    ldd    : Integer;
    d      : Real;

  begin
    t[0] := 0;
    t[1] := 3;
    t[2] := 2;

    t[3] := 5;
    t[4] := 0;
    t[5] := 3;

    t[6] := 5;
    t[7] := 1;
    t[8] := 4;

    t[9]  := 6;
    t[10] := 2;
    t[11] := 4;

    lyyyy := getYYYYFromIso;
    lmm   := getMMFromIso; 
    ldd   := getDDFromIso;

    if (lmm < 3)
    then
      lyyyy := lyyyy - 1;

    d :=  ( lyyyy + lyyyy div 4 - lyyyy div 100 + lyyyy div 400 + trunc(t[lmm-1]) + trunc(ldd) ) ;
    d := d - 7 * (int(d/7) );

    day := trunc(d);
  end;


  procedure TDateTime.writeDT;
  begin
    writeln(isoDate, ' ',
            isoTime,
            tz
           );
  end;


  function TDateTime.humanDateTime
          : String;
  var
    thisDate,
    thisTime : String;

  begin
    thisDate := date2Str(getYYYYFromIso, getMMFromIso,  getDDFromIso,  true);
    thistime := time2Str(getHrFromIso,   getMinFromIso, getSecFromIso, true);

    humanDateTime := concat(thisDate, thisTime);

  end;


  function date2Str(year, month, day : Word;
                    human : Boolean)
          : String;
  var
    dtStr : String;
  begin
    (*writeln('Date is ', year, '/', month, '/', day ); *)

    if (human)
    then
    begin
      dtStr := IntToStr(trunc(year ) ) + '.';
      dtStr := dtStr + LPad( IntToStr(trunc(month) ), 2, '0' ) + '.';
      dtStr := dtStr + LPad( IntToStr(trunc(day)   ), 2, '0' );
    end

    else
    begin
      dtStr := IntToStr(trunc(year ) );
      dtStr := dtStr + LPad( IntToStr(trunc(month) ), 2, '0' );
      dtStr := dtStr + LPad( IntToStr(trunc(day)   ), 2, '0' );
    end;

    date2Str := dtStr;
  end;


  function time2Str(hour, minute, second : Word;
                    human : Boolean)
          : String;
  var
    logger  : PLogger;
    tmStr   : String;

  begin
    new(logger);
    logger^.init;
    logger^.level := INFO;

    (*writeln('Time is ', hour, ':', minute, ':', second ); *)

    if (human)
    then
    begin
      logger^.log(DEBUG, 'human format');
      tmStr :=         LPad( IntToStr(trunc(hour  ) ), 2, '0' ) + ':';
      tmStr := tmStr + LPad( IntToStr(trunc(minute) ), 2, '0' ) + ':';
      tmStr := tmStr + LPad( IntToStr(trunc(second) ), 2, '0' );
    end

    else
    begin
      tmStr :=         LPad( IntToStr(trunc(hour  ) ), 2, '0' );
      tmStr := tmStr + LPad( IntToStr(trunc(minute) ), 2, '0' );
      tmStr := tmStr + LPad( IntToStr(trunc(second) ), 2, '0' );
    end;

    (*writeln(tmStr); *)

    Dispose (logger, Done);

    time2Str := tmStr;

  end;


  procedure timeBetween(epoch1, epoch2:LongInt;
                        var dd,
                            hh,
                            mi,
                            ss : Integer;
                        var future : Boolean);
  var
    diffSec,
    remSec  : LongInt;

    logger  : PLogger;

  begin
    new(logger);
    logger^.init;
    logger^.level := INFO;

    logger^.logLongInt(DEBUG, 'epoch1 ', epoch1);
    logger^.logLongInt(DEBUG, 'epoch2 ', epoch2);

    if (epoch1 < epoch2)
    then
    begin
      diffSec := epoch2 - epoch1;
      future  := FALSE;
    end
    else
    begin
      diffSec := epoch1 - epoch2;
      future   := TRUE;
    end;

    (*writeln('diffsec = ', diffSec);  *)
    dd     := diffSec div daySec;

    remSec := diffsec mod daySec;
    hh     := remSec  div hourSec;

    remSec := remSec mod hourSec;
    mi     := remSec div minSec;

    ss     := remSec mod minSec;

    Dispose (logger, Done);
  end;


  function isLeapDay(y : Integer)
          : Boolean;
  begin

    if (y mod 4) = 0
    then
    begin

      if (y mod 100) = 0
      then
      begin
        if (y mod 400) = 0
        then
          isLeapDay := TRUE
        else
          isLeapDay := FALSE;
      end
      else
        isLeapDay := TRUE;
    end
    else
      isLeapDay := FALSE;
  end;


  function daysInMonth(myDate : PDateTime)
          :Integer;
  (* Purpose : Calculate date of end of month *)
  begin
    daysInMonth := daysMon[myDate^.getMMFromIso];

    if (myDate^.getMMFromIso = 2) and (isLeapDay(myDate^.getYYYYFromIso))
    then
      daysInMonth := 29;
  end;


  function TDateTime.isAllDay
          : Boolean;
  (* Purpose : Is this an all day event ? *)

  var
    logger       : PLogger;

  begin
    new(logger);
    logger^.init;
    logger^.level := INFO;

    if     (getHrFromIso  = 0)
       and (getMinFromIso = 0)
       and (getSecFromIso = 0)
    then
      isAllDay := true
    else
      isAllDay := false;

    if     (getYYYYFromIso = 1970)
       and (getMMFromIso   = 1)
       and (getDDFromIso   = 1)
    then
    begin
      isAllDay := true;
    end;

    Dispose (logger, Done);

  end;

end.
