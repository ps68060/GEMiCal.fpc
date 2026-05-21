{$I projopts.i}
{$mode objfpc}

unit
  DateStrc;

(* AUTHOR  : P SLEGG
   DATE    : 17th May 2020 Version 1
   PURPOSE : TDateStruct object for the parsed an converted ICS Event.
*)

interface
  uses
    Objects,
    SysUtils,
    DateUtils;

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
  TDateStruct = class
    isoDate    : String;
    isoTime    : String;
    tz         : String;

    fpDateTime : TDateTime;
    epoch      : LongInt;
    julianDate : Double;

    day     : Integer;

    constructor Create;
    destructor  Destroy; override;

    constructor CreateFromISO(dtString : String);

    constructor CreateFromWords(yyyy, mm, dd,
                              hh, nn, ss : Word);


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

    procedure CalcJulianDate;

    procedure dayOfWeek;

    procedure WriteDateStrc;

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

  function daysInMonth(myDate : TDateStruct)
          :Integer;


implementation

uses
    Logger,
    StrSubs;

constructor TDateStruct.Create;
  var
    iso8601 : String;

  begin
    isoDate := '19700101';

    isoTime := '000000';
    tz      := '+0000';

    epoch  := 0;
    julianDate := 2440587.5;
    day    := 4;
    
    iso8601 := concat(isoDate, 'T', isoTime);
    fpDateTime := ISO8601ToDate(iso8601, false);
  end;


destructor TDateStruct.Destroy;
  begin
    inherited destroy;
  end;


constructor TDateStruct.CreateFromISO(dtString : String);
  (* Purpose : Initialise the TDateStruct from an ISO8601 date-time string
   *   dtString : ISO8601 format used in ical/ics
   *              YYYYMMDDThhnnss
   *              where the date and time are separated by a 'T' and the time is in 24 hour format.
   *)
  var
   jd     : Double;

  begin
    log.level := LLINFO;

    log.debug('CREATE from ISO date-time  ' + dtString);

    isoDate := Copy(dtString, 1, 8);
    isoTime := Copy(dtString, 10, 6);

    if (length(dtString) >= 16 )
    then
      tz := Copy (dtString, 16, length(dtString) );

    fpDateTime := ISO8601ToDate(dtString, false);

    julianDate := DateTimeToJulianDate(fpDateTime);
    epoch      := DateTimeToUnix(fpDateTime);
    day        := DayOfTheWeek(fpDateTime);

    log.debug('TDateStruct: epoch= ', epoch);
    log.debug('TDateStruct: julianDate= ', julianDate);
    log.debug('TDateStruct: day= ', day);
  end;


constructor TDateStruct.CreateFromWords(yyyy, mm, dd,
                                        hh, nn, ss : Word);
  var
    lIsoDate : String;
    lIsoTime : String;
    lIsoDateTime : String;

  begin
    lIsoDate := date2Str(yyyy, mm, dd, FALSE);
    lIsoTime := time2Str(hh, nn, ss, FALSE);
    
    lIsoDateTime := concat(isoDate, 'T', isoTime);
    CreateFromISO(lIsoDateTime);
  end;


procedure TDateStruct.dtStr2Obj(dtString : String);
  var
   jd : Double;

  begin
    log.level := LLDEBUG;
    log.debug('converting date-time  ' + dtString);

    isoDate := Copy(dtString, 1, 8);
    isoTime := Copy(dtString, 10, 6);

    if (length(dtString) >= 16 )
    then
      tz := Copy (dtString, 16, length(dtString) );

    log.debug('dtStr2Obj date ' + isoDate);
    //log.debug('dtStr2Obj time ' + isoTime);

    CalcJulianDate;
    calcEpoch;

    dayOfWeek;

  end;


function TDateStruct.getYYYYFromIso
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

///    getYYYYFromIso := StrToIntDef(Copy(isoDate, 1, 4), 1970);
  end;


function TDateStruct.getMMFromIso
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


function TDateStruct.getDDFromIso
        : Integer;
  var
    code   : Integer;
    dd     : Integer;

  begin
    dd := 1;
    val ( COPY (isoDate, 7, 2), dd, code );
    if (code <> 0)
    then
      writeln ('Integer conversion error of day-date at ', code, ' in ', isoDate);

    getDDFromIso := dd;
  end;


function TDateStruct.getHrFromIso
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


function TDateStruct.getMinFromIso
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


function TDateStruct.getSecFromIso
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



procedure TDateStruct.calcEpoch;
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


procedure TDateStruct.CalcJulianDate;
  var
    y, m, d  : double;

    lyyyy,
    lmm,
    ldd      : integer;

    part1,
    part2,
    part3,
    part4    : double;

  begin
    log.level := LLINFO;

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

    julianDate := part1 + part2 - part3 + part4;

    (* Julian day is based on midday so if the hour is less than 12 it is the previous day. *)
    if (getHrFromIso < 12)
    then
      julianDate := julianDate - 0.5;

    log.debug('Julian date is ', julianDate);
  end;


procedure TDateStruct.dayOfWeek;
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


procedure TDateStruct.WriteDateStrc;
  begin
    writeln(isoDate, 'T',
            isoTime,
            tz, ' ',
            fpDateTime, ' ',
            epoch, ' ',
            julianDate, ' ',
            day1[day]
           );
  end;


function TDateStruct.humanDateTime
        : String;
  var
    thisDate,
    thisTime : String;

  begin
    thisDate := date2Str(getYYYYFromIso, getMMFromIso,  getDDFromIso,  true);
    thistime := time2Str(getHrFromIso,   getMinFromIso, getSecFromIso, true);

    humanDateTime := concat(thisDate, ' ', thisTime);

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
      dtStr := Str(trunc(year ) ) + '.';
      dtStr := dtStr + LPad( Str(trunc(month) ), 2, '0' ) + '.';
      dtStr := dtStr + LPad( Str(trunc(day)   ), 2, '0' );
    end

    else
    begin
      dtStr := Str(trunc(year ) );
      dtStr := dtStr + LPad( Str(trunc(month) ), 2, '0' );
      dtStr := dtStr + LPad( Str(trunc(day)   ), 2, '0' );
    end;

    date2Str := dtStr;
  end;


function time2Str(hour, minute, second : Word;
                  human : Boolean)
        : String;
  var
    tmStr   : String;

  begin
    log.level := LLINFO;

    (*writeln('Time is ', hour, ':', minute, ':', second ); *)

    if (human)
    then
    begin
      log.debug('human format');
      tmStr :=         LPad( Str(trunc(hour  ) ), 2, '0' ) + ':';
      tmStr := tmStr + LPad( Str(trunc(minute) ), 2, '0' ) + ':';
      tmStr := tmStr + LPad( Str(trunc(second) ), 2, '0' );
    end

    else
    begin
      tmStr :=         LPad( Str(trunc(hour  ) ), 2, '0' );
      tmStr := tmStr + LPad( Str(trunc(minute) ), 2, '0' );
      tmStr := tmStr + LPad( Str(trunc(second) ), 2, '0' );
    end;

    (*writeln(tmStr); *)
    time2Str := tmStr;

  end;


procedure EpochToYMD(epoch: LongInt;
                     var yy, mm, dd : Integer);
  (* Purpose : Convert epoch seconds to year, month, day 
   * Standard Gregorian calendar conversion.
   * This uses March as the first month of the year to simplify leap year calculations.
   * epoch zero is 1970-01-01 and 719468 days before that is 0000-03-01.
    * Algorithm from https://howardhinnant.github.io/date_algorithms.html#civil_from_days
   *)
  const
    SECS_PER_DAY = 86400;
    DAY_OFFSET   = 719468;  // days from 0000-03-01 to 1970-01-01

  var
    zz,
    era,
    doe,
    yoe,
    doy, mp: LongInt;
 
  begin
    // Convert seconds to days
    zz := epoch div SECS_PER_DAY + DAY_OFFSET;  // days since 0000-03-01

    era := zz div 146097;
    doe := zz - era * 146097;          // day of era (number of days in 400 years)
    yoe := (doe - doe div 1460
            + doe div 36524            // days in 100 years
            - doe div 146096)
           div 365;

    yy := yoe + era * 400;
    
    doy := doe - (365 * yoe + yoe div 4 - yoe div 100);
    mp := (5 * doy + 2) div 153;
    
    dd := doy - (153 * mp + 2) div 5 + 1;
    mm := mp + 3;

    if mm > 12 then
    begin
      mm := mm - 12;
      inc(yy);
    end;

  end;


procedure EpochToHMS(epoch : LongInt;
                     var hh,
                         nn,
                         ss : Integer);
  (* Purpose : Convert epoch seconds to hour, minute, second
   *)
  var
    tt: LongInt;

  begin
    tt := epoch mod 86400;
    if tt < 0
      then tt := tt + 86400;

    hh := tt div 3600;
    nn := (tt div 60) mod 60;
    ss := tt mod 60;
  end;


function IsoDateFromEpoch(epoch : LongInt)
        : String;
  (* Purpose : Convert epoch seconds to ISO date string YYYY-MM-DD
   *)
  var
    yy, mm, dd : Integer;
    hh, nn, ss : Integer;

  begin
    EpochToYMD(epoch, yy, mm, dd);
    EpochToHMS(epoch, hh, nn, ss);

    IsoDateFromEpoch := Format('%04d-%02d-%02dT%02d:%02d:%02d',
                                [yy,  mm,  dd,  hh,  nn, ss]);
  end;


procedure timeBetween(epoch1, epoch2 : LongInt;
                      var dd,
                          hh,
                          mi,
                          ss : Integer;
                      var future : Boolean);
  var
    diffSec,
    remSec  : LongInt;

  begin
    log.level := LLINFO;

    log.debug('epoch1 ', epoch1);
    log.debug('epoch2 ', epoch2);

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


function daysInMonth(myDate : TDateStruct)
        :Integer;
  (* Purpose : Calculate date of end of month *)

  begin
    daysInMonth := daysMon[myDate.getMMFromIso];

    if (myDate.getMMFromIso = 2) and (isLeapDay(myDate.getYYYYFromIso))
    then
      daysInMonth := 29;
  end;


function TDateStruct.isAllDay
        : Boolean;
  (* Purpose : Is this an all day event ? *)

  begin
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

  end;

end.
