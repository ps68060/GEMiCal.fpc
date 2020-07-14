unit WinCal;

interface

  uses
    Gem,
    Dos,

    OTypes,
    OWindows,

    DateTime,
    StrSubs,
    CellGrid,
    Logger;

{$I gemical.i}

const
  dAppName = 'GEMiCal';

type

  PWinCal      = ^TWinCal;

  TWinCal     = OBJECT(TWindow)
                   calDate  : PDateTime;  (* 1st of the month *)

                   procedure GetWindowClass(var AWndClass: TWndClass); VIRTUAL;
                   function  GetIconTitle    : String;                 VIRTUAL;
                   function  GetStyle        : Integer;                VIRTUAL;
                   function  GetScroller     : PScroller;              VIRTUAL;

                   procedure Paint(var PaintInfo     : TPaintStruct);  VIRTUAL;

                   procedure IconPaint(var PaintInfo : TPaintStruct);  VIRTUAL;
                   procedure SetupSize;                                VIRTUAL;

                   procedure WriteDates(newX,
                                        newY   : LongInt);             VIRTUAL;

                   procedure DrawTitle(newX,
                                       newY   : LongInt;
                                       year,
                                       month  : Word);

                   procedure DrawHeading(newX,
                                         newY   : LongInt);

                   procedure DisplayEvents(newX,
                                           newY    : LongInt);

                   procedure CalcPos(row,
                                     col   : Integer;
                                     var x,
                                         y : Integer);

                   procedure DrawGrid(newX,
                                      newY : LongInt;
                                      rows,
                                      height  : Integer);
                 END;

var
  cellGr     : PCellGrid;


implementation

const
  WINWIDTH  = 800;  (* W:=113, smallest width of the working area *)
  WINHEIGHT = 680;  (* H:=77,  smallest Height, because the window does not go smaller via Sizer *)


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
  SubStr := Copy(myStr, 1, 16);
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

  row, col,
  i            : Integer;

begin

  new(logger);
  logger^.init;
  logger^.level := INFO;

  logger^.logInt(DEBUG, 'year ', calDate^.yyyy );
  logger^.log(DEBUG, mon1[calDate^.mm] );

  (* Get today's date and check if displaying current month *)
  GetDate (year, month, day, dayOfWeek) ;

  CalcCell (calDate^.day, day, row, col);

  currentMonth := FALSE;
  if     (calDate^.yyyy = year)
     and (calDate^.mm   = month)
  then
    currentMonth := TRUE;

  (* Calculate date of end of month *)
  daysInMon := daysInMonth(calDate);

  (* Display the dates, highlighting today *)
  for i := 1 to daysInMon
  do
  begin
    CalcCell (calDate^.day, i, row, col);
    CalcPos  (row, col, x, y);

    if (currentMonth)
       and (i = day)
    then
    begin
      vst_effects(vdiHandle, TF_UNDERLINED or TF_THICKENED);
      v_gtext(vdiHandle,
              newX + x + Attr.boxWidth,
              newY + y - 2 * Attr.boxHeight - 10,
              IntToStr(i) + ' ' + day2[(calDate^.day + i - 1) mod 7]);
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

  (* Display the year and month *)
  DrawTitle(new_X, new_Y, year, month);

  DrawHeading(new_X, new_Y - 2 * Attr.boxHeight);

  vsf_interior(vdiHandle, FIS_HOLLOW);
  DrawGrid(new_X, new_Y, 6, ySpace);

  WriteDates(new_X, new_Y);

  DisplayEvents(new_X, new_Y);

  (* new(PButton, Init(@SELF, 99, 99, true, '') );  *)

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
      W := WINWIDTH;   (* W:=113, smallest width of the working area *)
      H := WINHEIGHT;  (* H:=77,  smallest Height, because the window does not go smaller via Sizer *)
    end;

  Calc(WC_BORDER,Work,Curr)
end;


procedure TWinCal.IconPaint(var PaintInfo : TPaintStruct);
(* write a Text in the iconified Window *)

begin
  v_gtext(vdiHandle, Work.X, Work.Y+(Work.h shr 1), ' 2xClick ');
end;


procedure TWinCal.DrawTitle(newX,
                            newY   : LongInt;
                            year,
                            month  : Word);

var
  title     : String;

  wch,
  hch,
  wCell,
  hCell,
  hAlign,
  vAlign     : Integer;

begin

  (* Display the year and month *)
  str(year, title);
  title := title + ' ' + mon1[month];

  vst_point(vdiHandle, 20, wch, hch, wcell, hcell);
  vst_Alignment(vdiHandle, 1, 0, hAlign, vAlign);

  v_gtext(vdiHandle,
          newX + WINWIDTH div 2,
          newY + 2 * Attr.boxHeight,
          title);

  vst_point(vdiHandle, 10, wch, hch, wCell, hCell);
  vst_Alignment(vdiHandle, 0, 0, hAlign, vAlign);
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


procedure TWinCal.DisplayEvents(newX,
                                newY   : LongInt);

(* Purpose : Display Events for a month  *)

var
  logger    : PLogger;

  row,
  col,
  x,
  y         : Integer;

  wch,
  hch,
  wcell,
  hcell     : Integer;

  summ,
  timePlace   : String;

  daysBetween : Real;

  j,
  i           : Integer;

begin

  new(logger);
  logger^.init;
  logger^.level := INFO;

  logger^.log (DEBUG, 'DisplayEvents');

  vst_point(vdiHandle, 7, wch, hch, wcell, hcell);

  for j := 1 to 31
  do
  begin
    calcCell (calDate^.day, j, row, col); 
    calcPos(row, col, x, y);

    logger^.logInt (DEBUG, 'row ', row);
    logger^.logInt (DEBUG, 'col ', col);


    for i := 0 to cellGr^.cell[j]^.counter - 1
    do
    begin
      summ      := SubStr (cellGr^.cell[j]^.cellEvents[i]^.summary );
 (*     timePlace := SubStr (Concat(cellGr^.cell[j]^.cellEvents[i]^.timeStart,
                                  cellGr^.cell[j]^.cellEvents[i]^.location) );  *)
      logger^.log(DEBUG, 'Summary  ' + summ );
      logger^.logInt(DEBUG, 'counter ', i);

      v_gtext(vdiHandle,
              newX + x + Attr.boxWidth,
              newY + y - Attr.boxHeight - 10 + i * Attr.boxHeight,
              summ );

      v_gtext(vdiHandle,
              newX + x + Attr.boxWidth,
              newY + y - Attr.boxHeight - 10 + i * Attr.boxHeight,
              summ );
    end;

  end;

  vst_point(vdiHandle, 10, wch, hch, wcell, hcell);

  Dispose(logger, Done);

end;


end.