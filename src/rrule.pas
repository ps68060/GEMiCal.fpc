{$I projopts.i}
{$mode objfpc}
{$modeswitch advancedrecords}

unit rrule;

interface

type

  TRRule = record
    freq       : String;             // DAILY, WEEKLY, MONTHLY, YEARLY
    interval   : Integer;            // default = 1
    untilDate  : String;             // YYYYMMDD or YYYYMMDDTHHMMSSZ
    Count      : Integer;            // number of occurrences
    byDay      : array of String;    // MO,TU,WE,TH,FR,SA,SU
    byMonth    : array of Integer;   // 1..12
    byMonthDay : array of Integer;   // 1..31 or -31..-1

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

procedure TRRule.ParseRRule(const value: String;
                            var rule: TRRule);
 (* Purpose: Parse the single line Recur rule.
  * e.g  RRULE:FREQ=DAILY;COUNT=10
  *      RRULE:FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR
  *)
  var
    parts,
    kv         : TStringArray;
    i, j       : Integer;

    key,
    val        : String;
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
      val := kv[1];
  
      case key of
        FREQ_TK:
          freq := value;
  
        INTERVAL_TK:
          interval := StrToIntDef(value, 1);
  
        UNTIL_TK:
          untilDate := value;
  
        COUNT_TK:
          count := StrToIntDef(value, 0);
  
        BYDAY_TK:
          begin
            list := SplitString(value, ',');
            SetLength(byDay, Length(list));

            for j := 0 to High(list) do
              byDay[j] := list[j];
          end;
  
        BYMONTH_TK:
          begin
            list := SplitString(value, ',');
            SetLength(byMonth, Length(list));

            for j := 0 to High(list) do
              byMonth[j] := StrToIntDef(list[j], 0);
          end;
  
        BYMONTHDAY_TK:
          begin
            list := SplitString(val, ',');
            SetLength(byMonthDay, Length(list));

            for j := 0 to High(list) do
              byMonthDay[j] := StrToIntDef(list[j], 0);
          end;
  
      end;  // case
    end;  // for
  end;

end.
