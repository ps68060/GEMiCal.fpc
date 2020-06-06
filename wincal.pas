unit WinCal;

interface

  uses
    Gem,
    Dos,
    OTypes,
    OWindows,

    DateTime,
    StrSubs;

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

                   procedure WriteDates(offset : Integer;
                                        newX,
                                        newY   : LongInt);             VIRTUAL;
                 END;


implementation

procedure calPos(cell  : Integer;
                 var x,
                     y : Integer);
var
  leftPos,
  topPos,
  xSpace,
  ySpace    : Integer;

begin
  leftPos    := 30;
  topPos     := 120;
  xSpace     := 110;
  ySpace     := 100;

  x := leftPos + (cell mod 7)  * xSpace;
  y := topPos - yspace + yspace * (cell div 7) + 60;
end;


procedure TWinCal.WriteDates(offset : Integer;
                             newX,
                             newY   : LongInt);
var
  leftPos,
  topPos,
  xSpace,
  ySpace,
  x,
  y            : Integer;
  daysInMon    : Integer;

  i            : Integer;

begin
  leftPos    := 30;
  topPos     := 120;
  xSpace     := 110;
  ySpace     := 100;

  daysInMon := daysMon[calDate^.mm];

  if (calDate^.mm = 2) and (isLeapDay(calDate^.yyyy))
  then
    daysInMon := 29;

  writeln(calDate^.yyyy, '    ', mon1[calDate^.mm]);

  for i := 1 to daysInMon
  do
  begin
   calPos(i - 1 + offset, x, y);
   v_gtext(vdiHandle,
           newX + x,
           newY + y,
           IntToStr(i) );
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

  leftPos,
  topPos,
  xSpace,
  ySpace,
  lineLength   : Integer;

  i            : Integer;

begin
  GetDate(year, month, day, dayOfWeek) ;
  GetTime(hour, minute, second, sec100);

  New_X := Scroller^.GetXOrg;
  New_Y := Scroller^.GetYOrg;

  v_gtext(vdiHandle, new_x+Attr.charWidth, new_y + 2*Attr.boxHeight, date2Str(year, month, day, TRUE) );
  v_gtext(vdiHandle, new_x+Attr.charWidth, new_y + 3*Attr.boxHeight, time2Str(hour, minute, second, TRUE) );

  leftPos    := 30;
  topPos     := 120;
  xSpace     := 110;
  ySpace     := 100;

  WriteDates(1, new_X, new_Y);

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

(*
  v_circle(vdiHandle, new_x+320, new_y+200, 80);
  vsf_interior(vdiHandle, FIS_SOLID);

  v_ellipse(vdiHandle, new_x+300, new_y+160, 10, 20);
  vsf_interior(vdiHandle, FIS_PATTERN);
  vsf_style(vdiHandle,3);

  v_ellipse(vdiHandle, new_x+340, new_y+160, 10, 20);
  vsf_style(vdiHandle,4);

  v_ellipse(vdiHandle, new_x+320, new_y+200, 10, 20);
  vsf_style(vdiHandle,2);

  v_ellpie(vdiHandle, new_x+320, new_y+230, 50, 20, 1800, 3600);
*)
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