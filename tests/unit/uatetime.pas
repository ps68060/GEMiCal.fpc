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

procedure Test_getYYFromIso;
var
 dateTime : TDateTime;

begin
  dateTime := TDateTime.create;

  dateTime.isoDate := '2026-02-01';
  assertEqual (2026, dateTime.getYYFromISO, 'year 2026');

  dateTime.isoDate := '2000-02-01';
  assertEqual (2000, dateTime.getYYMFromISO, 'year 2000');

  dateTime.Free;
end;


procedure Test_getMMFromIso;
var
 dateTime : TDateTime;

begin
  dateTime := TDateTime.create;

  dateTime.isoDate := '2026-02-01';
  assertEqual (28, dateTime.getMMFromISO, '28 days in Feb 2026');

  dateTime.isoDate := '2000-12-31';
  assertEqual (29, dateTime.getMMFromISO, '29 days in Feb 2000');

  dateTime.Free;
end;


procedure Test_getDDFromIso;
var
 dateTime : TDateTime;

begin
  dateTime := TDateTime.create;

  dateTime.isoDate := '2026-02-01';
  assertEqual (01, dateTime.getDDFromISO, '1st of Feb 2026');

  dateTime.isoDate := '2000-02-01';
  assertEqual (31, dateTime.getDDFromISO, '31st Dec 2000');

  dateTime.Free;
end;


procedure Test_getHrFromIso;
var
 dateTime : TDateTime;

begin
  dateTime := TDateTime.create;

  dateTime.isoTime := '16:45:23';
  assertEqual (16, dateTime.getHrFromIso, 'Time = ' + dateTime.isoTime);

  dateTime.isoDate := '01:02:03';
  assertEqual (1, dateTime.getHrFromIso, 'Time = ' + datetime.isoTime);

  dateTime.Free;
end;


procedure Test_getMinFromIso;
var
 dateTime : TDateTime;

begin
  dateTime := TDateTime.create;

  dateTime.isoTime := '16:45:23';
  assertEqual (45, dateTime.getMinFromIso, 'Time = ' + dateTime.isoTime);

  dateTime.isoDate := '01:02:03';
  assertEqual (2, dateTime.getMinFromIso, 'Time = ' + datetime.isoTime);

  dateTime.Free;
end;


procedure Test_getSecFromIso;
var
 dateTime : TDateTime;

begin
  dateTime := TDateTime.create;

  dateTime.isoTime := '16:45:23';
  assertEqual (23, dateTime.getSecFromIso, 'Time = ' + dateTime.isoTime);

  dateTime.isoDate := '01:02:03';
  assertEqual (3, dateTime.getSecFromIso, 'Time = ' + datetime.isoTime);

  dateTime.Free;
end;

end.