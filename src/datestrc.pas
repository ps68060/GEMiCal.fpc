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
  mon1   : array [1..12] of String
         = ('January', 'February', 'March',     'April',   'May',      'June',
            'July',    'August',   'September', 'October', 'November', 'December');

  mon2   : array [1..12] of String
         = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

  day1   : array [0..6] of String
         = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');

  day2   : array [0..6] of String
         = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

type
  TDateStruct = class
//    isoDate    : String;
//    isoTime    : String;
    epoch      : LongInt;

    fpDateTime : TDateTime;  // plan is to store as date-time as UTC
    tz         : String;     // and retain the original timezone string for reference

///    day     : Integer;

    constructor Create;
    destructor  Destroy; override;

    constructor CreateFromISO(dtString : String);

//    function getYYYYFromIso
//            : Integer;

//    function getMMFromIso
//            : Integer;

//    function getDDFromIso
//            : Integer;

//    function getHrFromIso
//            : Integer;

//    function getMinFromIso
//            : Integer;
            
//    function getSecFromIso
//            : Integer;

    procedure WriteDateStrc;

    function BSTstart
            : TDateTime;

    function BSTend
            : TDateTime;
  end;


implementation

uses
    Logger,
    StrSubs;

constructor TDateStruct.Create;
  var
    iso8601 : String;

  begin
//    isoDate := '19700101';

//    isoTime := '000000';
    tz      := '+0000';

    epoch  := 0;
///    day    := 4;
    
    iso8601 := '19700101T000000+0000';  //concat(isoDate, 'T', isoTime, tz);
    fpDateTime := ISO8601ToDate(iso8601, false);
  end;


destructor TDateStruct.Destroy;
  begin
    inherited Destroy;
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

//    isoDate := Copy(dtString, 1, 8);
//    isoTime := Copy(dtString, 10, 6);

    if (length(dtString) >= 16 )
    then
      tz := Copy (dtString, 16, length(dtString) );

    fpDateTime := ISO8601ToDate(dtString, false);

    epoch      := DateTimeToUnix(fpDateTime);

    log.debug('TDateStruct: epoch= ', epoch);
  end;

(*
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
*)

(*function TDateStruct.getMMFromIso
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
*)
(*
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
*)
(*
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
*)
(*
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
*)
(*
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
*)

procedure TDateStruct.WriteDateStrc;
  begin
    writeln(//'ISO ', isoDate, 'T', isoTime, tz,
            ' DateTime ', fpDateTime,
            ' epoch ',    epoch
           );
  end;


function TDateStruct.BSTstart
        : TDateTime;
    (* Purpose : Calculate the date of the last Sunday in March for a given year
     *  inputs  : year = the year for which to calculate the last Sunday in March
     *  returns : the date of the last Sunday in March (1 to 31)
     *)
  var
    lDate      : TDateTime;
    lastSunday : Integer;
  begin
    BSTstart := fpDateTime;
    lDate := EncodeDate(YearOf(fpDateTime), 3, 31);

    lastSunday := 31 - DayOfWeek(lDate) + 1; // Calculate the last Sunday
    BSTstart := RecodeDay(lDate, lastSunday);
    BSTstart := RecodeTime(BSTstart, 2, 0, 0, 0);  // Set time to 2:00am
  end;


function TDateStruct.BSTend
        : TDateTime;
    (* Purpose : Calculate the date of the last Sunday in October for a given year
     *  inputs  : year = the year for which to calculate the last Sunday in October
     *  returns : the date of the last Sunday in October (1 to 31)
     *)
  var
    lDate      : TDateTime;
    lastSunday : Integer;
  begin
    BSTend := fpDateTime;
    lDate := EncodeDate(YearOf(fpDateTime), 10, 31);

    lastSunday := 31 - DayOfWeek(lDate) + 1; // Calculate the last Sunday
    BSTend := RecodeDay(lDate, lastSunday);
    BSTend := RecodeTime(BSTend, 1, 0, 0, 0);  // Set time to 1:00am
  end;

end.
