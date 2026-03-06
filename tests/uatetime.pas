{$mode objfpc}{$H+}

unit uatetime;

uses
  datetime;

implementation

procedure assertEqual(Expected, Actual: Integer; const Msg: string);
begin
  if Expected <> Actual then
    writeln('FAIL: ', Msg, ' Expected=', Expected, ' Actual=', Actual)
  else
    writeln('PASS: ', Msg);
end;

procedure assertTrue(Expected, Actual: boolean; const msg: string);
begin
  if Expected <> Actual then
    writeln('FAIL: ', Msg, ' Expected = ', Expected, ' Actual = ', Actual)
  else
    writeln('PASS: ', Msg);
end;

procedure Test_isLeapDay;
begin
  assertTrue (true, isLeapDay(2000), 'isleapDay(2000)');
end;


procedure Test_daysInMonth;
var
 dateTime : TDateTime;

begin
  dateTime := TDateTime.create;

  dateTime.isoDate := '2026-02-01';
  assertEqual (28, dateTime.getMMFromISO, 'Feb 2026 has 28 days');

  dateTime.isoDate := '2000-02-01';
  assertEqual (29, dateTime.getMMFromISO, 'Feb 2020 has 29 days');

  dateTime.Free;
end;

end.