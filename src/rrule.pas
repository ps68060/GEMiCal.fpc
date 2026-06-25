{$I projopts.i}
{$mode objfpc}
{$modeswitch advancedrecords}

unit rrule;

interface

uses
  dateStrc;

type

  TRRule = record
    freq       : String;             // DAILY, WEEKLY, MONTHLY, YEARLY
    interval   : Integer;            // default = 1
    untilDate  : String;             // YYYYMMDD or YYYYMMDDTHHMMSSZ
    count      : Integer;            // number of occurrences
    byDay      : array of String;    // MO,TU,WE,TH,FR,SA,SU
    byMonth    : array of Integer;   // 1..12
    byMonthDay : array of Integer;   // 1..31 or -31..-1
    
    recurUntilDate : DateStrc;

    procedure ParseRRule(const value: String;
                         var rule: TRRule);

  end;


implementation

uses
  SysUtils,
  StrUtils,
  Logger;

const
  FREQ_TK       = 'FREQ';
  INTERVAL_TK   = 'INTERVAL';
  UNTIL_TK      = 'UNTIL';
  COUNT_TK      = 'COUNT';
  BYDAY_TK      = 'BYDAY';
  BYMONTH_TK    = 'BYMONTH';
  BYMONTHDAY_TK = 'BYMONTHDAY';

  FREQ_DAILY_TK    = 'DAILY';
  FREQ_WEEKLY_TK   = 'WEEKLY';
  FREQ_MONTHLY_TK  = 'MONTHLY';
  FREQ_YEARLY_TK   = 'YEARLY';

procedure TRRule.ParseRRule(const value: String);
  (*
   * Purpose: Parse the single line Recur rule by:
   *          1. splitting at the Semi-colons
   *          2. splitting at the Equals.
   * e.g  RRULE:FREQ=DAILY;COUNT=10
   *      RRULE:FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR
   *)
  var
    parts,
    kv         : TStringArray;
    i, j       : Integer;

    key,
    strValue   : String;
    list       : TStringArray;

  begin
    log.info('Recurring event not yet handled. ' + value);
    // Defaults
    freq := '';
    interval := 1;
    untilDate := '';
    count := 0;

    SetLength(byDay, 0);
    SetLength(byMonth, 0);
    SetLength(byMonthDay, 0);
  
    // Split at semicolons: FREQ=DAILY;INTERVAL=2;BYDAY=MO,WE,FR
    parts := SplitString(value, ';');
  
    for i := 0 to High(parts) do
    begin
      kv := SplitString(parts[i], '=');
      if Length(kv) <> 2 then Continue;
  
      key := UpperCase(kv[0]);
      strValue := kv[1];
  
      case key of
        FREQ_TK:
          freq := strValue;
  
        INTERVAL_TK:
          interval := StrToIntDef(strValue, 1);
  
        UNTIL_TK:
          untilDate := strValue;
  
        COUNT_TK:
          count := StrToIntDef(strValue, 0);
  
        BYDAY_TK:
          begin
            list := SplitString(strValue, ',');
            SetLength(byDay, Length(list));

            for j := 0 to High(list) do
              byDay[j] := list[j];
          end;
  
        BYMONTH_TK:
          begin
            list := SplitString(strValue, ',');
            SetLength(byMonth, Length(list));

            for j := 0 to High(list) do
              byMonth[j] := StrToIntDef(list[j], 0);
          end;
  
        BYMONTHDAY_TK:
          begin
            list := SplitString(strValue, ',');
            SetLength(byMonthDay, Length(list));

            for j := 0 to High(list) do
              byMonthDay[j] := StrToIntDef(list[j], 0);
          end;
  
      end;  // case
    end;  // for
  end;


procedure GetRecurEnd(startDate: TDateTime);
  (*
   * Purpose: Determine when the recurring event will end and store as a TDateStruct.
   *)
  var
    endDays     : Integer;
    endDateTime : TDateTime;

  begin
    if Length(untilDate) > 0
    then
    begin
      recurUntilDate := TDateStruct.Create;
      recurUntilDate.CreateFromISO(untilDate);
    end

    else
    begin
      endDays := CalcRecurEnd;
      recurUntilDate := TDateStruct.Create;
      endDateTime := startDate + endDays;
      recurUntilDate.fpDateTime := endDateTime;
    end;
  end;


function CalcRecurEnd : Integer;
  (*
   * Purpose: Calculate the number of days until the recurrence ends based on COUNT.
   *          Supports DAILY, WEEKLY, MONTHLY, and YEARLY frequencies.
   * Returns: Number of days from start to end of recurrence.
   *)
  var
    daysPerUnit: Integer;
  begin
    if count = 0 then
    begin
      Result := 0;
      Exit;
    end;

    case freq of
      FREQ_DAILY_TK:
        daysPerUnit := 1;
      FREQ_WEEKLY_TK:
        daysPerUnit := 7;
      FREQ_MONTHLY_TK:
        daysPerUnit := 30;  // Approximate; varies with calendar
      FREQ_YEARLY_TK:
        daysPerUnit := 365; // Approximate; accounts for leap years variably
    else
      daysPerUnit := 1;
    end;

    Result := (count - 1) * interval * daysPerUnit;
  end;

end.
