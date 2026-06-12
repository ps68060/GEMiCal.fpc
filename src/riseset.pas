{$I projopts.i}
{$mode objfpc}

unit riseset;

interface
  uses
    Trig,
    DateStrc,
    DateUtils,
    SysUtils,
    Logger;


  procedure SunRiseSet (lat, lng, UTCoff : Real;
                        date : TDateTime;
                        var sunrise,
                            sunset  : String);

implementation


procedure SunRiseSet (lat, lng, UTCoff : Real;
                      date : TDateTime;
                      var sunrise,
                          sunset  : String);

(*
* SUNRISESET Compute apparent sunrise and sunset times in seconds.
*
*  1  sun_rise_set = SunRiseSet( lat, lng, UTCoff, date)
*
*     Computes the *apparent* (refraction corrected) sunrise  and sunset times in seconds from mignight and
*     returns them as sun_rise_set.
*     lat and lng are the latitude (+ to N) and longitude (+ to E),
*     UTCoff is the timezone, i.e. the local time offset to UTC (Coordinated Universal Time) in hours,
*     date is the date in format 'dd-mmm-yyyy' ( see below for an example).
* 
*  2  [sun_rise_set, noon] = SunRiseSet( lat, lng, UTCoff, date)
*
*     additionally returns the solar noon in seconds from midnight.
* 
*  3  [sun_rise_set, noon, opt] = SunRiseSet( lat, lng, UTCoff, date) 
*
*     additionally returns the information opt, which contains information on every second of the day:
*       opt.elev_ang_corr   : Apparent (refraction corrected) solar elevation in degrees
*       opt.azAngle         : Solar azimuthal angle (deg clockwise from N)
*       opt.solarDecl       : Solar declination in degrees
* 
*  4  sun_rise_set = SunRiseSet( ..., PLOT) If PLOT is true, 
*
*     plots of the elevation and azimuthal angle are created.
* 
* EXAMPLE:
*     lat = 47.377037;    % Latitude (Zurich, CH)
*     lng = 8.553952;     % Longitude (Zurich, CH)
*     UTCoff = 2;         % UTC offset
*     date = '15-jun-2017';
* 
*     [sun_rise_set, noon, opt] = SunRiseSet( lat, lng, UTCoff, date, 1);
*
* 
* Richard Droste
* 
* Reverse engineered from the NOAA Excel:
* (https://www.esrl.noaa.gov/gmd/grad/solcalc/calcdetails.html)
* 
* The formulas are from:
* Meeus, Jean H. Astronomical algorithms. Willmann-Bell, Incorporated, 1991.

 Converted to Pascal by P Slegg. 2021

*)

(* Process input *)

(* variable letters correspond to columns in the NOAA Excel
 *)

  var
    E, F,
    G, H    : Double;
    I, I1,
    J,
    K,
    L, M,
    P, Q,
    R, T,
    U, V,
    W, X    : Double;
  
    AB, AC, AD,
    solarDecl,
    azAngle,
    azAngle2 : Double;
  
    srise,
    sset    : Double;
  
    sr_hh,
    sr_mm,
    ss_hh,
    ss_mm   : Word;
    
    srDateTime,
    ssDateTime : TDateTime;
    
    jd     : Double;
  
  begin
    log.level := LLINFO;
  
    log.debug ('lat = ', lat);
    log.debug ('lng = ', lng);
    log.debug ('UTC = ', UTCoff);
  
    E := 0;
    
    jd := DateTimeToJulianDate(date);
  
    F := jd - UTCoff / 24;      (* Julian day *)
    log.debug ('JD = ', jd);
    log.debug ('f = ', F);
  
    G := (F - 2451545) / 36525;               (* Julian century *)
  
    log.debug ('g = ', G);
  
    I  := (280.46646 + G * (36000.76983 + G * 0.0003032));
    I1 := trunc(I / 360);
    I  := I - I1 * 360;                                            (* Sun mean LONGITUDE *)
  
    J := 357.52911  + G * (35999.05029 - 0.0001537 * G);           (* Sun mean ANOMOLY   *)
  
    log.debug ('i = ', I);
    log.debug ('j = ', J);
  
    K := 0.016708634   - G * (0.000042037 + 0.0000001267 * G);     (* Earth orbit eccentricity *)
  
    log.debug ('k = ', K);
  
    L := sind(J)     * (1.914602 - G * (0.004817 + 0.000014 * G))
         + sind(2*J) * (0.019993 - 0.000101 * G)
         + sind(3*J) * 0.000289;                                   (* Sun EQ of Centre *)
  
    log.debug ('l = ', L);
  
    M := I + L;  (* Sun True Longitude *)
  
    log.debug ('m = ', M);
  
    P := M - 0.00569 - 0.00478 * sind(125.04 - 1934.136 * G);      (* Sun apparent Longitude *)
    log.debug ('p = ', P);
  
    Q := 23 + (26 + ((21.448 - G * (46.815 + G * (0.00059 - G * 0.001813)))) /60) /60;  (* Mean Oblique Ecliptic *)
    log.debug ('q = ', Q);
  
    R := Q + 0.00256 * cosd(125.04 - 1934.136 * G);  (* Oblique Correction *)
    log.debug ('r = ', R);
  
    T := asind(sind(R) * sind(P));                   (* Sun Declination *)
    log.debug ('t = ', T);
  
    U := tand(R/2) * tand(R/2);    (* var y *)
    V := 4 * rad2deg(U * sin(2 * deg2rad(I))
                    - 2    * K     * sin(deg2rad(J))
                    + 4    * K * U * sin(deg2rad(J)) * cos(2 * deg2rad(I)) 
                    - 0.5  * U * U * sin(4 * deg2rad(I)) 
                    - 1.25 * K * K * sin(2 * deg2rad(J)));  (* Eq of time (min) *)
  
    log.debug ('v = ', V);
  
  
    // NB NOAA uses -long for WEST !!
    // So invert the normal convention
    AB := trunc(E * 1440.0 + V - 4.0 * lng - 60.0 * UTCoff) mod 1440;    (* True Solar time (min) *)
  
    if ((AB/4) < 0)
    then
      AC := AB/4 + 180   (* Hour Angle *)
    else
      AC := AB/4 - 180;  (* Hour Angle *)
  
    AD := acosd(sind(lat) * sind(T) + cosd(lat) * cosd(T) * cosd(AC));        (* Solar Zenith angle *)
  
    W := acosd(  (cosd(90.833)
                 / (cosd(lat) * cosd(T)))
                 - (tand(lat) * tand(T))
              );
  
    X  := (720 - 4 * lng - V + UTCoff * 60.0) / 1440;                         (* Solar noon (LST) *)
  
    log.debug ('w = ', W);
    log.debug ('x = ', X);
  
    (* Results in degrees...
  
    if (nargout > 2)
    then
    begin
      solarDecl     := T;
      elev_ang_corr := 90 - AD;
      AC_ind        := AC > 0;
  
      azAngle := (acosd(( (sind(lat) * cosd(AD)) - sind(T)) / 
                            (cosd(lat) * sind(AD)))
                           +180 )
                     mod 360.0;
  
      azAngle2 := (540 - acosd(((sind(lat) * cosd(AD)) - sind(T)) /
                        (cosd(lat) * sind(AD))) )
                     mod 360.0;
  
      azAngle(AC_ind) := azAngle2(AC_ind);
    end;
    *)
  
    srise := X - W * 4 / 1440; (* fraction of 1 day *)
    sset  := X + W * 4 / 1440;
  
    // Sunrise
    sr_hh   := trunc(srise * 24);
    sr_mm   := trunc((srise * 24 - sr_hh) * 60);
    srDateTime := date;
    srDateTime := RecodeTime(srDateTime, sr_hh, sr_mm, 0, 0);
    sunrise := TimeToStr(srDateTime);

    // Sunset
    ss_hh   := trunc(sset * 24);
    ss_mm   := trunc((sset * 24 - ss_hh) * 60);
    ssDateTime := date;
    ssDateTime := RecodeTime(ssDateTime, ss_hh, ss_mm, 0, 0);
    sunset := TimeToStr(ssDateTime);
  
    log.debug('Sunrise : ' + sunrise);
    log.debug('Sunset  : ' + sunset);
  
  end;
  
end.
