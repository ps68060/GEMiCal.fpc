{$I projopts.i}
{$mode objfpc}

unit DateStrc;

(* AUTHOR  : P SLEGG
   DATE    : 17th May 2020 Version 1
   PURPOSE : TDateStruct object for the parsed an converted ICS Event.
*)

interface
  uses
    Objects,
    SysUtils,
    DateUtils,
    StrngHlp;

  const
    mon1   : array [1..12] of String
           = ('January', 'February', 'March',     'April',   'May',      'June',
              'July',    'August',   'September', 'October', 'November', 'December');

    mon2   : array [1..12] of String
           = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

    day1   : array [1..7] of String
           = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');

    day2   : array [1..7] of String
           = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

    function BSTstart(dateTime : TDateTime)
            : TDateTime;

    function BSTend(dateTime : TDateTime)
            : TDateTime;

    function IsBST(dateTime : TDateTime)
            : Boolean;

    function TimeZoneToOffset(tzIdStr: String; dateTime : TDateTime)
            : String;


type
  TDateStruct = class
    fpDateTime : TDateTime;  // plan is to store as date-time as UTC
    tz         : String;     // and retain the original timezone string for reference

    constructor Create;
    destructor  Destroy; override;

    constructor CreateFromISO(iso8601 : String);

    procedure WriteDateStrc;

  end;


implementation

uses
    Logger;

constructor TDateStruct.Create;
  var
    iso8601 : String;
    validDT  : Boolean;

  begin
    tz      := '+0000';
    
    iso8601 := '19700101T000000+0000';  //concat(isoDate, 'T', isoTime, tz);
    validDT := TryISOStrToDateTime(iso8601, fpDateTime);
  end;


destructor TDateStruct.Destroy;
  begin
    inherited Destroy;
  end;


constructor TDateStruct.CreateFromISO(iso8601 : String);
  (* Purpose : Initialise the TDateStruct from an ISO8601 date-time string
   *   iso8601 : ISO8601 format used in ical/ics
   *              YYYYMMDDThhnnss
   *              where the date and time are separated by a 'T' and the time is in 24 hour format.
   *)
  var
    validDT  : Boolean;

  begin
    log.level := LLINFO;
    log.debug('CREATE from ISO date-time  ' + iso8601);

    if (length(iso8601) >= 16 )
    then
      tz := Copy (iso8601, 16, length(iso8601) );

    validDT := TryISOStrToDateTime(iso8601, fpDateTime);
    log.debug('TDateStruct: fpDateTime= ', fpDateTime);
  end;


procedure TDateStruct.WriteDateStrc;
  begin
    writeln(' DateTime ', fpDateTime);
  end;


function IsBST(dateTime : TDateTime)
        : Boolean;
  begin
    isBST :=   (BSTStart(dateTime) < dateTime)
           and (BSTEnd(dateTime)   > dateTime);
  end;


function BSTstart(dateTime : TDateTime)
        : TDateTime;
    (* Purpose : Calculate the date of the last Sunday in March for a given year
     *  inputs  : year = the year for which to calculate the last Sunday in March
     *  returns : the date of the last Sunday in March (1 to 31)
     *)
  var
    lDate      : TDateTime;
    lastSunday : Integer;
  begin
    lDate := EncodeDate(YearOf(dateTime), 3, 31);

    lastSunday := 31 - DayOfWeek(lDate) + 1;       // Calculate the last Sunday (Delphi convention is 1=Sunday)
    BSTstart := RecodeDay(lDate, lastSunday);      // Set date to clock change day
    BSTstart := RecodeTime(BSTstart, 2, 0, 0, 0);  // Set time to 2:00am
  end;


function BSTend(dateTime : TDateTime)
        : TDateTime;
    (* Purpose : Calculate the date of the last Sunday in October for a given year
     *  inputs  : year = the year for which to calculate the last Sunday in October
     *  returns : the date of the last Sunday in October (1 to 31)
     *)
  var
    lDate      : TDateTime;
    lastSunday : Integer;
  begin
    lDate := EncodeDate(YearOf(dateTime), 10, 31);

    lastSunday := 31 - DayOfWeek(lDate) + 1;   // Calculate the last Sunday
    BSTend := RecodeDay(lDate, lastSunday);    // Set date to clock change day
    BSTend := RecodeTime(BSTend, 1, 0, 0, 0);  // Set time to 1:00am
  end;


function TimeZoneToOffset(tzIdStr: String; dateTime : TDateTime)
        : String;
        
  const
    ZoneEuropeWest : array of String
         = ('Europe/London',
            'Europe/Dublin',
            'Europe/Lisbon',
            'Atlantic/Canary'); 

    ZoneEuropeEast : array of String
         = ('Europe/Paris',
            'Europe/Amsterdam',
            'Europe/Berlin',
            'Europe/Brussels',
            'Europe/Budapest',
            'Europe/Copenhagen',
            'Europe/Madrid',
            'Europe/Oslo',
            'Europe/Prague',
            'Europe/Rome',
            'Europe/Stockholm',
            'Europe/Vienna',
            'Europe/Warsaw',
            'Europe/Zurich');

    ZoneAsiaWest : array of String
         = ('Europe/Athens',
            'Europe/Bucharest',
            'Europe/Helsinki',
            'Europe/Riga',
            'Europe/Sofia',
            'Europe/Tallinn',
            'Europe/Vilnius',
            'Asia/Nicosia',
            'Asia/Famagusta');

  var
    summerTime : Boolean;

  begin
      log.level := LLDEBUG;
    writeln ('TimeZone= ', tzidstr);

    if (tzidstr = 'Atlantic/Reykjavik')
    then
      Exit ('+00:00');

    summerTime := IsBST(dateTime);
    // Share the same offset and clock change rules as London
    if Contains(ZoneEuropeWest, tzIdStr)
    then
    begin
      log.debug('TZ is London like');

      if summerTime
      then
        Exit('+01:00')
      else
        Exit('+00:00');
    end;

    // Share the same offset and clock change rules as Paris
    if Contains(ZoneEuropeEast, tzIdStr)
    then
    begin
      log.debug('TZ is Paris like');
      if summerTime
      then
        Exit('+02:00')
      else
        Exit('+01:00');
    end;

    if Contains(ZoneAsiaWest, tzIdStr)
    then
    begin
      log.debug('TZ is Athens like');

      if summerTime
      then
        Exit('+03:00')
      else
        Exit('+02:00');
    end;
  end;

end.
