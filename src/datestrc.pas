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

    day     : Integer;

    constructor Create;
    destructor  Destroy; override;

    constructor CreateFromISO(dtString : String);

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

    procedure dayOfWeek;

    procedure WriteDateStrc;

    function isAllDay
            : Boolean;

  end;


  function date2Str(year, month, day : Word;
                    human : Boolean)
          : String;

  function time2Str(hour, minute, second : Word;
                    human : Boolean)
          : String;

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

    epoch      := DateTimeToUnix(fpDateTime);
    day        := DayOfTheWeek(fpDateTime);

    log.debug('TDateStruct: epoch= ', epoch);
    log.debug('TDateStruct: day= ', day);
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
    writeln('ISO ', isoDate, 'T', isoTime, tz,
            ' DateTime ', fpDateTime,
            ' epoch ',    epoch,
            ' ',          day1[day]
           );
  end;

(*
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
*)
(*
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
    time2Str := tmStr;

  end;
*)

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
