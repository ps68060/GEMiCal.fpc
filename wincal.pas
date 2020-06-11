{$B+,D-,I-,L-,N-,P-,Q-,R+,S-,T-,V-,X+,Z-}

unit WinCal;

interface

  uses
    Gem,
    Dos,

    OTypes,
    OWindows,

    Cal,
    DateTime,
    StrSubs,
    Logger;

{$I gemical.i}

const
  dAppName = 'GEMiCal';

type

  PWinCal      = ^TWinCal;

  TWinCal     = OBJECT(TWindow)
                   calDate  : PDateTime;  (* 1st of the month *)
                   cal      : PCal;

                   procedure GetWindowClass(var AWndClass: TWndClass); VIRTUAL;
                   function  GetIconTitle    : String;                 VIRTUAL;
                   function  GetStyle        : Integer;                VIRTUAL;
                   function  GetScroller     : PScroller;              VIRTUAL;

                   procedure Paint(var PaintInfo     : TPaintStruct);  VIRTUAL;

                   procedure IconPaint(var PaintInfo : TPaintStruct);  VIRTUAL;
                   procedure SetupSize;                                VIRTUAL;

                   procedure WriteDates(newX,
                                        newY   : LongInt);             VIRTUAL;

                   procedure DrawHeading(newX,
                                         newY   : LongInt);

                   procedure DisplayEvents(newX,
                                           newY   : LongInt);

                   procedure DisplayEvent(newX,
                                          newY    : LongInt;
                                          i,
                                          row,
                                          col     : Integer);

                   procedure CalcCell(day : Integer;
                                      var row,
                                          col : Integer);

                   procedure CalcPos(row,
                                     col   : Integer;
                                     var x,
                                         y : Integer);

                   procedure DrawGrid(newX,
                                      newY : LongInt;
                                      rows,
                                      height  : Integer);
                 END;


implementation

var
  leftPos,
  topPos,
  xSpace,
  ySpace       : Integer;

  daysInMon    : Integer;
  endMonthDate : PDateTime;


function SubStr(myStr : String)
        : String;
begin
  SubStr := Copy(myStr, 1, 12);
end;

procedure TWinCal.CalcCell(day : Integer;
                 var row,
                     col : Integer);
(* Purpose : Calculate the row and column of the calendar day *)

var
  logger    : PLogger;

begin

  new(logger);
  logger^.init;
  logger^.level := INFO;

  row := (day - 1 + calDate^.day) div 7;
  col := (day - 1 + calDate^.day) mod 7;

  logger^.logInt(DEBUG, 'day ', day);
  logger^.logInt(DEBUG, 'row ', row);
  logger^.logInt(DEBUG, 'col ', col);

  Dispose (logger, Done);
end;


procedure TWinCal.CalcPos(row,
                          col   : Integer;
                          var x,
                              y : Integer);
(* Purpose : Calculate the x, y of the cell from row, col. *)

begin

  x := leftPos + (col)  * xSpace;
  y := topPos + yspace * (row) + 60;

end;


procedure TWinCal.WriteDates(newX,
                             newY   : LongInt);
var
  logger    : PLogger;

  x,
  y            : Integer;

  year,
  month,
  day,
  dayOfWeek    : Word;

  currentMonth : Boolean;
  dtStr        : String;

  row,col,
  i            : Integer;

begin

  new(logger);
  logger^.init;
  logger^.level := INFO;

  (* Calculate date of end of month *)
  daysInMon := daysMon[calDate^.mm];

  if (calDate^.mm = 2) and (isLeapDay(calDate^.yyyy))
  then
    daysInMon := 29;

  dtStr := date2Str(calDate^.yyyy, calDate^.mm, daysInMon, FALSE);
  new(endMonthDate);
  endMonthDate^.init;
  endMonthDate^.dtStr2Obj(dtStr);

  logger^.logInt(DEBUG, 'year ', calDate^.yyyy );
  logger^.log(DEBUG, mon1[calDate^.mm] );

  (* Get today's date and check if displaying current month *)
  GetDate (year, month, day, dayOfWeek) ;

  CalcCell(day, row, col);

  currentMonth := FALSE;
  if     (calDate^.yyyy = year)
     and (calDate^.mm   = month)
  then
    currentMonth := TRUE;

  (* Display the dates, highlighting today *)
  for i := 1 to daysInMon
  do
  begin
    CalcCell (i, row, col);
    CalcPos  (row, col, x, y);

    if (currentMonth)
       and (i = day)
    then
    begin
      vst_effects(vdiHandle, TF_UNDERLINED or TF_THICKENED);
      v_gtext(vdiHandle,
              newX + x + Attr.boxWidth,
              newY + y - 2 * Attr.boxHeight - 10,
              IntToStr(i) + ' ' + day2[i mod 7]);
      vst_effects(vdiHandle, TF_NORMAL);
    end
    else
      v_gtext(vdiHandle,
              newX + x  + Attr.boxWidth,
              newY + y - 2 * Attr.boxHeight - 10,
              IntToStr(i) );
  end;

  Dispose (logger, Done);
end;


procedure TWinCal.Paint(var PaintInfo : TPaintStruct);

(* Purpose : called on every change *)

var
  year,
  month,
  day,
  dayOfWeek : Word;

  hour,
  minute,
  second,
  sec100    : Word;

  New_X, New_Y : LongInt;
  pxArray      : Array [1..10] of Integer;

  lineLength   : Integer;

  i            : Integer;

begin

  leftPos    := 20;
  topPos     := 80;
  xSpace     := 110;
  ySpace     := 90;

  GetDate(year, month, day, dayOfWeek) ;
  GetTime(hour, minute, second, sec100);

  new_X := Scroller^.GetXOrg;
  new_Y := Scroller^.GetYOrg;

  v_gtext(vdiHandle, new_x + Attr.charWidth,
          new_y + 1 * Attr.boxHeight,
          date2Str(year, month, day, TRUE) );

  v_gtext(vdiHandle, new_x + Attr.charWidth + Attr.charWidth * 13,
          new_y + 1 * Attr.boxHeight,
          time2Str(hour, minute, second, TRUE) );

  drawHeading(new_X, new_Y - 2 * Attr.boxHeight);

  WriteDates(new_X, new_Y);

  displayEvents(new_X, new_Y);

  vsf_interior(vdiHandle, FIS_HOLLOW);

  DrawGrid(new_X, new_Y, 6, ySpace);

end;


procedure TWinCal.GetWindowClass(var AWndClass : TWndClass);
(* set general features of windows *)

begin
  INHERITED GetWindowClass(AWndClass);
  AWndClass.Style   := cs_DblClks+cs_CreateOnAccOpen+cs_AutoOpen+cs_WorkBackground+cs_CancelOnClose;
  AWndClass.hCursor := IDC_HELP;
end;


function TWinCal.GetIconTitle
        : String;
(* Name of iconified Windows *)

begin
  GetIconTitle := 'MiniWind';
end;


function TWinCal.GetStyle
        : Integer;
(* set the Element of Windows *)

begin
  GetStyle := INHERITED GetStyle OR SLIDER;
end;


function TWinCal.GetScroller
        : PScroller;
(* set the Scroller *)

begin
  GetScroller := new(PScroller, Init(@self, 4, 4, 160, 100) );

  (* 1,.,640,. means 1 pixel is scrolled to 640 units         *)
  (* 2,.,320,. means 2 pixels will be scrolled to 320 units   *)
  (* both correspond to a horizontal exposure of 640 pixels	  *)
  (* the window ausma'e are not determined here               *)
end;


procedure TWinCal.SetupSize;
(* set the Gr”že beim ersten open *)

begin
  INHERITED SetupSize;
  with Work do
    begin
      X :=  10;  (* X,Y correspond to the coordinates of the working area *)
      Y :=  60;  (* of Windows, not the Auženmaže, min X:=1, min Y:=56=menu+title+subtitle *)
      W := 800;  (* W:=113, smallest width of the working area *)
      H := 680;  (* H:=77,  smallest Height, because the window does not go smaller via Sizer *)
    end;

  Calc(WC_BORDER,Work,Curr)
end;


procedure TWinCal.IconPaint(var PaintInfo : TPaintStruct);
(* write a Text in the iconified Window *)

begin
  v_gtext(vdiHandle, Work.X, Work.Y+(Work.h shr 1), ' 2xClick ');
end;


procedure TWinCal.DrawHeading(newX,
                              newY   : LongInt);

(* Draw the column headings *)
var
  lineLength,
  cellHeight   : Integer;
  pxArray      : Array [1..10] of Integer;

  x,
  y            : Integer;

  i            : Integer;

begin

  DrawGrid (newX, newY, 1, 30);

  (* Write Day labels *)
  for i := 0 to 6
  do
  begin
    calcPos(0, i, x, y);
    v_gtext(vdiHandle,
            newX + x + Attr.boxWidth,
            newY + y - 2 * Attr.boxHeight - 10,
            day2[i] );
  end;

end;


procedure TWinCal.DisplayEvents(newX,
                                newY   : LongInt);

(* Purpose : Decide which Events should be displayed *)

var
  logger    : PLogger;

  row,
  col,
  i         : Integer;

begin

  new(logger);
  logger^.init;
  logger^.level := INFO;

  logger^.logLongInt(DEBUG, ' 1st epoch ', calDate^.epoch);
  logger^.logLongInt(DEBUG, 'last epoch ', endMonthDate^.epoch);

  logger^.logInt(DEBUG, 'entries = ', cal^.entries );

  for i := 0 to cal^.entries do
  begin

    (*  calDate is 1st of month *)
    if      (cal^.eventList[i]^.startDate^.epoch < endMonthDate^.epoch)
        and (cal^.eventList[i]^.endDate^.epoch   > calDate^.epoch)
    then
    begin
      logger^.logInt (INFO, 'IN Scope', i );
      calcCell(cal^.eventList[i]^.startDate^.dd, row, col);
      DisplayEvent(newX, newY, i, row, col);
    end;

  end;  (* for *)

(**  Dispose (calDate, Done);  **)
  Dispose (logger, Done);

end;


procedure TWinCal.DisplayEvent(newX,
                               newY   : LongInt;
                               i,
                               row,
                               col    : Integer);

(* Purpose : Display a single event  *)

var
  logger    : PLogger;

  x,
  y         : Integer;

  summ      : String;

begin

  new(logger);
  logger^.init;
  logger^.level := INFO;

  calcPos(row, col, x, y);

  logger^.logInt (DEBUG, 'row ', row);
  logger^.logInt (DEBUG, 'col ', col);

  summ := SubStr (cal^.eventList[i]^.summary);

  v_gtext(vdiHandle,
          newX + x + Attr.boxWidth,
          newY + y - Attr.boxHeight - 10,
          summ );

  logger^.log(DEBUG, 'Summary ' + cal^.eventList[i]^.summary );

  Dispose(logger, Done);

end;


procedure TWinCal.DrawGrid(newX,
                           newY    : LongInt;
                           rows,
                           height  : Integer);
var
  lineLength : Integer;

  pxArray      : Array [1..10] of Integer;

  i : Integer;

begin
  (* Draw horizontal lines for weeks by changing y co-ords *)

  lineLength := 7 * xSpace;

  pxArray[1] := newX + leftPos;
  pxArray[2] := newY + topPos;

  pxArray[3] := newX + leftPos + lineLength;
  pxArray[4] := newY + topPos;

  for i := 1 to rows + 1
  do
  begin
    v_pline(vdiHandle, 2, pxArray);

    pxArray[2] := pxArray[2] + height;
    pxArray[4] := pxArray[4] + height;
  end;


  (* Draw vertical lines for days by changing x co-ords *)

  lineLength := topPos + rows * height;

  pxArray[1] := newX + leftPos;
  pxArray[2] := newY + topPos;

  pxArray[3] := newX + leftPos;
  pxArray[4] := newY + lineLength;

  for i := 1 to 8
  do
  begin
    v_pline(vdiHandle, 2, pxArray);

    pxArray[1] := pxArray[1] + xSpace;
    pxArray[3] := pxArray[3] + xSpace;
  end;


end;

end.