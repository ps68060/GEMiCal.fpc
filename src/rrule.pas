{$I projopts.i}
{$mode objfpc}

unit rrule;

interface

type

  TRRule = record
    Freq       : String;             // DAILY, WEEKLY, MONTHLY, YEARLY
    Interval   : Integer;            // default = 1
    UntilDate  : String;             // YYYYMMDD or YYYYMMDDTHHMMSSZ
    Count      : Integer;            // number of occurrences
    ByDay      : array of String;    // MO,TU,WE,TH,FR,SA,SU
    ByMonth    : array of Integer;   // 1..12
    ByMonthDay : array of Integer;   // 1..31 or -31..-1
  end;

  procedure ParseRRule(const s: String;
                       var rule: TRRule);


implementation

uses
  SysUtils,
  StrUtils;

const
  FREQ_TK       = 'FREQ';
  INTERVAL_TK   = 'INTERVAL';
  UNTIL_TK      = 'UNTIL';
  COUNT_TK      = 'COUNT';
  BYDAY_TK      = 'BYDAY';
  BYMONTH_TK    = 'BYMONTH';
  BYMONTHDAY_TK = 'BYMONTHDAY';

procedure ParseRRule(const s: String;
                     var rule: TRRule);
  var
    parts,
    kv         : TStringArray;
    i, j       : Integer;

    key,
    val        : String;
    list       : TStringArray;

  begin
    // Defaults
    rule.Freq := '';
    rule.Interval := 1;
    rule.UntilDate := '';
    rule.Count := 0;
    SetLength(rule.ByDay, 0);
    SetLength(rule.ByMonth, 0);
    SetLength(rule.ByMonthDay, 0);
  
    // Split at semicolons: FREQ=DAILY;INTERVAL=2;BYDAY=MO,WE,FR
    parts := SplitString(s, ';');
  
    for i := 0 to High(parts) do
    begin
      kv := SplitString(parts[i], '=');
      if Length(kv) <> 2 then Continue;
  
      key := UpperCase(kv[0]);
      val := kv[1];
  
      case key of
  
          FREQ_TK:
          rule.Freq := val;
  
          INTERVAL_TK:
          rule.Interval := StrToIntDef(val, 1);
  
          UNTIL_TK:
          rule.UntilDate := val;
  
          COUNT_TK:
          rule.Count := StrToIntDef(val, 0);
  
          BYDAY_TK:
          begin
            list := SplitString(val, ',');
            SetLength(rule.ByDay, Length(list));

            for j := 0 to High(list) do
              rule.ByDay[j] := list[j];
          end;
  
          BYMONTH_TK:
          begin
            list := SplitString(val, ',');
            SetLength(rule.ByMonth, Length(list));

            for j := 0 to High(list) do
              rule.ByMonth[j] := StrToIntDef(list[j], 0);
          end;
  
          BYMONTHDAY:
          begin
            list := SplitString(val, ',');
            SetLength(rule.ByMonthDay, Length(list));

            for j := 0 to High(list) do
              rule.ByMonthDay[j] := StrToIntDef(list[j], 0);
          end;
  
      end; // case
    end;
  end;

end.
