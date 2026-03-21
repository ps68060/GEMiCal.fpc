unit trig;

interface

function deg2rad(angle : Real)
        : Real;

function rad2deg(angle : Real)
        : Real;

function sind(angle : Real)
        : Real;

function asind(angle : Real)
        : Real;

function cosd(angle : Real)
        : Real;

function acos(angle : Real)
        : Real;

function acosd(angle : Real)
        : Real;

function tand(angle : Real)
        : Real;

implementation


function deg2rad(angle : Real)
        : Real;
begin
  deg2rad := angle/180 * Pi;
end;


function rad2deg(angle : Real)
        : Real;
begin
  rad2deg := angle/Pi * 180;
end;


function sind(angle : Real)
        : Real;
begin
  angle := deg2rad(angle);
  sind  := sin(angle);

end;


function asind(angle : Real)
        : Real;
var
  as : Real;
begin

  if (abs(angle) <> 1)
  then
  begin
    as    := arctan(angle / sqrt(1 - sqr(angle)))
  end
  else
    as    := Pi / 2;

  asind := rad2deg(as);

end;


function cosd(angle : Real)
        : Real;
begin
  angle := deg2rad(angle);
  cosd  := cos(angle);

end;


function acos(angle : Real)
        : Real;
begin

  if (angle = 0)
  then
    acos := Pi / 2
  else
  begin
    acos := arctan(sqrt(1 - sqr(angle)) / angle);

  end;

end;


function acosd(angle : Real)
        : Real;
var
  ac : Real;
begin

  if (angle = 0)
  then
    ac := Pi / 2
  else
  begin
    angle := deg2rad(angle);
    ac := arctan(sqrt(1 - sqr(angle)) / angle);

  end;

  acosd := rad2deg(ac);

end;


function tand(angle : Real)
        : Real;
begin
  angle := deg2rad(angle);

  if (angle <> 1)
  then
    tand := sin(angle) / cos(angle)
  else
    tand := -99999;

end;


end.