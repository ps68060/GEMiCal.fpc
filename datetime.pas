{$B+,D-,G-,I-,L-,P-,Q-,R+,S-,T-,V-,X+,Z-}
unit datetime;

(* AUTHOR  : P SLEGG
   DATE    : 17th May 2020 Version 1
   PURPOSE : TDateTime object for the parsed an converted ICS Event.
*)

interface
  uses
    Objects,
    StrSubs,
    Logger;

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
    yyyy : Integer;
    mm   : Integer;
    dd   : Integer;

    hh24 : Integer;
    mi   : Integer;
    ss   : Integer;
    tz   : String;

    epoch  : LongInt;
    julian : Double;

    day    : Integer;

    constructor init;
    destructor  done; virtual;

    procedure dtStr2Obj(dtString : String);

    procedure calcEpoch;

    function julianDate
            : Double;

    procedure dayOfWeek;

    procedure epoch2Date;

    procedure writeDT;

  end;

  function date2Str(year, month, day : Word;
                    human : Boolean)
          : String;

  function time2Str(hour, minute, second : Word;
                    human : Boolean)
          : String;

  function isLeapDay(y : Integer)
          : Boolean;

  procedure timeBetween(epoch1, epoch2:LongInt;
                        var dd,
                            hh,
                            mi,
                            ss : Integer;
                        var future : Boolean);

implementation

  constructor TDateTime.init;
  begin
    yyyy := 1970;
    mm   := 1;
    dd   := 1;

    hh24 := 0;
    mi   := 0;
    ss   := 0;
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

  begin
    val ( COPY (dtString, 1, 4), yyyy, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of year at ', code, ' in ', dtString);

    val ( COPY (dtString, 5, 2), mm, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of month at ', code, ' in ', dtString);

    val ( COPY (dtString, 7, 2), dd, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of date at ', code, ' in ', dtString);

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

    tz := COPY (dtString, 16, length(dtString) );

    (*writeln (yyyy, mm, dd, ' ', hh24, mi, ss); *)

    date2 := julianDate;
    (*writeln('JDN      ', date2:12:2 ); *)

    calcEpoch;
    (*writeln('epoch = ', epoch); *)

    dayOfWeek;

  end;


  procedure TDateTime.calcEpoch;
  const
    epochJD = 2440587.50;  (*  1970/01/01 00:00:00 *)

  var
    calc : LongInt;

  begin

    (*writeln (yyyy, '/', mm, '/', dd, ' ', hh24, ':', mi, ':', ss); *)

    epoch := trunc( julianDate - epochJD ) * daySec;

    epoch := epoch + trunc(hh24) * hourSec;

    epoch := epoch + mi   * 60;

    epoch := epoch + ss;

    (**
    calc := yyyy;
    epoch := (calc - 1970)    * 31556926;
    epoch := epoch;
    writeln (yyyy, ' : ', epoch);

    calc := mm;
    epoch := epoch + (calc - 1) * 2629743;
    writeln (calc-1:2, ' : ', epoch);

    calc := dd;
    epoch := epoch + (calc - 1) * 86400;
    writeln (calc-1:2, ' : ', epoch);

    calc := hh24;
    epoch := epoch + (calc    ) * hourSec;
    writeln (calc:2, ' : ', epoch);

    calc := mi;
    epoch := epoch + (calc    ) * 60;
    writeln (calc:2, ' : ', epoch);

    calc := ss;
    epoch := epoch + (calc    ); 
    writeln (calc:2, ' : ', epoch);
    **)

  end;


  function TDateTime.julianDate
          : Double;
  var
    y, m, d  : double;
    part1, part2, part3, part4 : double;

  begin
    (* this didn't work.
    y := yyyy;
    m := mm;
    d := dd;

    julian := 1721028.5367 + d + 367*y -7*(y+(m+9)/12) /4-3*((y+(m-9)/7)/100+1)/4 + 275*m/9;
    writeln(julian:20:10);
    *)

    (*
    JDN  = (1461 * (Y + 4800 + (M - 14)/12))/4 +(367 * (M - 2 - 12 * ((M - 14)/12)))/12 - (3 * ((Y + 4900 + (M - 14)/12)/100))/4 + D - 32075 

    julian := (1461 * (vy + 4800 + (vm - 14) / 12)) / 4 + (367 * (vm - 2 - 12 * ((vm - 14) / 12))) / 12 - (3 * ((vy + 4900 + (vm - 14) / 12) / 100)) / 4 + vd - 32075;
    *)

    part1 := (1461 * (yyyy + 4800 + trunc((mm - 14) / 12) )) div 4;
    part2 := (367 * (mm - 2 - 12 * ((mm - 14) div 12))) div 12 ;
    part3 := (3 * ((yyyy + 4900 + (mm - 14) div 12) div 100)) div 4 ;
    part4 := dd - 32075 ;

    (*
    writeln('part1 : ', part1:20:10);
    writeln('part2 : ', part2:20:10);
    writeln('part3 : ', part3:20:10);
    writeln('part4 : ', part4:20:10);
    *)

    julian := part1 + part2 - part3 + part4;

    (* Julian day is based on midday so if the hour is less than 12 it is the previous day. *)
    if (hh24 < 12)
    then
      julian := julian - 0.5;

    (*
     writeln ('Julian date is', julian:20:3);
    *)

    julianDate := julian;
  end;


  procedure TDateTime.dayOfWeek;
  var
    t : array [0..11] of Integer;
    y : Integer;
    d : Real;

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

    y := yyyy;

    if (mm < 3)
    then
      y := y - 1;

    d :=  ( y + y div 4 - y div 100 + y div 400 + trunc(t[mm-1]) + trunc(dd) ) ;
    d := d - 7 * (int(d/7) );

    day := trunc(d);
  end;


  procedure TDateTime.epoch2Date;
  begin
    writeln;
  end;


  procedure TDateTime.writeDT;
  begin
    writeln( yyyy,                        '.',
             lpad(IntToStr(mm),  2, '0'), '.',
             lpad(IntToStr(dd),  2, '0'), ' ',
             lpad(IntToStr(hh24),2, '0'), ':',
             lpad(IntToStr(mi),  2, '0'), ':',
             lpad(IntToStr(ss),  2, '0'), ' ',
             tz
           );
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

end.