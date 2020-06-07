unit WinCal;

interface

  uses
    Gem,
    Dos,
    OTypes,
    OWindows,

    DateTime,
    StrSubs,
    Logger;

{$I gemical.i}

const
  dAppName = 'GEMiCal';

type

  PWinCal      = ^TWinCal;

  TWinCal     = OBJECT(TWindow)
                   calDate  : PDateTime;
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
                 END;


implementation
var
  leftPos,
  topPos,
  xSpace,
  ySpace    : Integer;

procedure calPos(cell  : Integer;
                 var x,
                     y : Integer);

begin
  leftPos    := 30;
  topPos     := 120;
  xSpace     := 110;
  ySpace     := 100;

  x := leftPos + (cell mod 7)  * xSpace;
  y := topPos - yspace + yspace * (cell div 7) + 60;
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

  daysInMon    : Integer;
  currentMonth : Boolean;

  i            : Integer;

begin

  new(logger);
  logger^.init;
  logger^.level := INFO;

  leftPos    := 30;
  topPos     := 120;
  xSpace     := 110;
  ySpace     := 100;

  currentMonth := FALSE;

  daysInMon := daysMon[calDate^.mm];

  if (calDate^.mm = 2) and (isLeapDay(calDate^.yyyy))
  then
    daysInMon := 29;

  logger^.logInt(DEBUG, '', calDate^.yyyy );
  logger^.log(DEBUG, mon1[calDate^.mm] );

  GetDate (year, month, day, dayOfWeek) ;

  if     (calDate^.yyyy = year)
     and (calDate^.mm   = month)
  then
    currentMonth := TRUE;

  for i := 1 to daysInMon
  do
  begin
    calPos(i - 1 + calDate^.day, x, y);

    if (currentMonth)
       and (i = day)
    then
    begin
      vst_effects(vdiHandle, TF_UNDERLINED or TF_THICKENED);
      v_gtext(vdiHandle,
              newX + x,
              newY + y,
              IntToStr(i) + ' ' + day2[i mod 7]);
      vst_effects(vdiHandle, TF_NORMAL);
    end
    else
      v_gtext(vdiHandle,
              newX + x,
              newY + y,
              IntToStr(i) );
  end;

  Dispose (logger, Done);
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
  leftPos    := 30;
  topPos     := 120;
  xSpace     := 110;
  ySpace     := 100;

  (* Draw horizontal line above main grid *)
  lineLength := leftPos + 7 * xSpace;
  cellHeight := 2*Attr.boxHeight;

  pxArray[1] := leftPos;
  pxArray[2] := topPos - cellHeight;

  pxArray[3] := lineLength;
  pxArray[4] := topPos - cellHeight;

  v_pline(vdiHandle, 2, pxArray);

  pxArray[2] := pxArray[2] + cellHeight +3;
  pxArray[4] := pxArray[4] + cellHeight +3;

  v_pline(vdiHandle, 2, pxArray);

  (* Draw vertical lines between each column heading *)
  lineLength := topPos + cellHeight;

  pxArray[1] := leftPos;
  pxArray[2] := topPos - cellHeight;

  pxArray[3] := leftPos;
  pxArray[4] := lineLength;

  for i := 1 to 8
  do
  begin
    v_pline(vdiHandle, 2, pxArray);

    pxArray[1] := pxArray[1] + xSpace;
    pxArray[3] := pxArray[3] + xSpace;
  end;

  (* Write Day labels *)
  for i := 1 to 7
  do
  begin
    calPos(i - 1, x, y);
    v_gtext(vdiHandle,
            newX + x,
            newY + y - 2*Attr.boxHeight,
            day2[i-1] );
  end;

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
  GetDate(year, month, day, dayOfWeek) ;
  GetTime(hour, minute, second, sec100);

  New_X := Scroller^.GetXOrg;
  New_Y := Scroller^.GetYOrg;

  v_gtext(vdiHandle, new_x+Attr.charWidth,
          new_y + 1*Attr.boxHeight,
          date2Str(year, month, day, TRUE) );
  v_gtext(vdiHandle, new_x+Attr.charWidth + Attr.charWidth * 13,
          new_y + 1*Attr.boxHeight,
          time2Str(hour, minute, second, TRUE) );

  drawHeading(new_X, new_Y);

  leftPos    := 30;
  topPos     := 120;
  xSpace     := 110;
  ySpace     := 100;

  WriteDates(new_X, new_Y);

  vsf_interior(vdiHandle, FIS_HOLLOW);

  (* Draw horizontal lines for weeks by changing y co-ords *)

  lineLength := leftPos + 7 * xSpace;

  pxArray[1] := leftPos;
  pxArray[2] := topPos;

  pxArray[3] := lineLength;
  pxArray[4] := topPos;

  for i := 1 to 7
  do
  begin
    v_pline(vdiHandle, 2, pxArray);

    pxArray[2] := pxArray[2] + ySpace;
    pxArray[4] := pxArray[4] + ySpace;
  end;

  (* Draw vertical lines for days by changing x co-ords *)

  lineLength := topPos + 6 * ySpace;

  pxArray[1] := leftPos;
  pxArray[2] := topPos;

  pxArray[3] := leftPos;
  pxArray[4] := lineLength;

  for i := 1 to 8
  do
  begin
    v_pline(vdiHandle, 2, pxArray);

    pxArray[1] := pxArray[1] + xSpace;
    pxArray[3] := pxArray[3] + xSpace;
  end;

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
  GetScroller := new(PScroller,Init(@self, 4, 4, 160, 100) );

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


end.