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

end.