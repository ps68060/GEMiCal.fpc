unit WinCal;

interface

  uses
    vdi,
    aes,
    OTypes,
    OWindows,

    Config,
    CellGrid,
    DateTime;

{$I gemical.i}

const
  dAppName = 'GEMiCal';
  TITLE_FONT_SIZE = 20;
  BODY_FONT_SIZE  = 10;

type

  PWinCal     = ^TWinCal;

  TWinCal     = OBJECT(TWindow)
                private
                    titleHeight,
                    headerHeight, 
                    cellWidth,
                    cellHeight : integer;

                public
                   procedure GetWindowClass(var AWndClass: TWndClass); VIRTUAL;
                   function  GetIconTitle    : String;                 VIRTUAL;
                   function  GetStyle        : Integer;                VIRTUAL;
                   function  GetScroller     : PScroller;              VIRTUAL;

                   procedure Paint(var PaintInfo     : TPaintStruct);  VIRTUAL;

                   procedure IconPaint(var PaintInfo : TPaintStruct);  VIRTUAL;
                   procedure SetupSize;                                VIRTUAL;

                   procedure WriteDates(newX,
                                        newY   : LongInt);             VIRTUAL;

                   procedure DrawTitle;

                   procedure DrawGridHeading;

                   procedure DisplayEvents(newX,
                                           newY    : LongInt);

                   procedure CalcPos(row,
                                     col   : Integer;
                                     var x,
                                         y : Integer);

                   procedure DrawGrid(rows,
                                      height  : Integer);
                 END;

var
  conf            : PConfig;

  displayDate     : PDateTime;  (* 1st of the month *)

  cellGr          : PCellGrid;


implementation
  uses
    Gem,
    Dos,

    Logger,
    StrSubs,
    RiseSet;

const
  WINWIDTH  = 800;  (* W:=113, smallest width of the working area *)
  WINHEIGHT = 680;  (* H:=77,  smallest Height, because the window does not go smaller via Sizer *)


var
  daysInMon    : integer;
  endMonthDate : PDateTime;


procedure TWinCal.CalcPos(row,
                          col   : Integer;
                          var x,
                              y : Integer);
(* Purpose : Calculate the x, y of the cell from row, col.
 * inputs  : row 0 to 6
 *           col 0 to 5
 * returns : x, y pixel positions of the top left corner of the calendar cell
 *)

begin
  x := Work.X + (col * cellWidth);
  y := Work.Y + titleHeight + row * cellHeight;

  if (row > 0)
  then
    y := y + headerHeight;
end;


procedure TWinCal.WriteDates(newX,
                             newY   : LongInt);
var
  log          : TLogger;

  pixX,
  pixY         : Integer;

  year,
  month,
  day,
  dayOfWeek    : Word;

  currentMonth : Boolean;

  row, col,
  i            : Integer;

  scrollX,
  scrollY: Integer;

  wch,
  hch,
  wCell,
  hCell        : Integer;

begin
  log := TLogger.Create(LLINFO);

  scrollX := Scroller^.GetXOrg;
  scrollY := Scroller^.GetYOrg;

  log.debug ('year ', displayDate^.getYYYYFromIso );
  log.debug (mon1[displayDate^.getMMFromIso] );

  (* Get today's date and check if displaying current month *)
  GetDate (year, month, day, dayOfWeek);

  CalcCell (displayDate^.day, day, row, col);

  currentMonth := FALSE;
  if     (displayDate^.getYYYYFromIso = year)
     and (displayDate^.getMMFromIso   = month)
  then
    currentMonth := TRUE;

  (* Calculate date of end of month *)
  daysInMon := daysInMonth(displayDate);

  (* Set the font to get the dimensions *)
  vst_point(vdiHandle, BODY_FONT_SIZE, wch, hch, wCell, hCell);

  (* Display the dates, highlighting today *)
  for i := 1 to daysInMon do
  begin
    CalcCell (displayDate^.day, i, row, col);
    CalcPos  (row, col, pixX, pixY);
    writeln ('row = ', row, ' col = ', col, '  X = ', pixX, ' Y = ', pixY);

    if (currentMonth)
       and (i = day)
    then
    begin
      (* Higlight today *)
      vst_effects(vdiHandle, TF_UNDERLINED or TF_THICKENED);
      v_gtext(vdiHandle,
              scrollX + pixX + Attr.boxWidth div 2,
              scrollY + pixY,  (* Use char height and not the char cell height *)
              IntToStr(i) + ' ' + day2[(displayDate^.day + i - 1) mod 7]);
      vst_effects(vdiHandle, TF_NORMAL);
    end
    else
      v_gtext(vdiHandle,
              scrollX + pixX + Attr.boxWidth div 2,
              scrollY + pixY,
              IntToStr(i) );
  end;

  log.Free;
end;


procedure TWinCal.Paint(var PaintInfo : TPaintStruct);

(* Purpose : called on every change *)

var
  log         : TLogger;

  New_X,
  New_Y : LongInt;

  pxArray     : Array [1..10] of Integer;

  wch,
  hch,
  wcell,
  hcell       : Integer;

  lineLength  : Integer;

  i           : Integer;

  year,
  month,
  day,
  dayOfWeek   : Word;

begin

  log := TLogger.Create(LLINFO);

  new (conf);
  conf^.init;

  vst_point(vdiHandle, BODY_FONT_SIZE, wch, hch, wCell, hCell);

  new_X := Scroller^.GetXOrg;
  new_Y := Scroller^.GetYOrg;

  (* Display the year and month in larger text *)
  DrawTitle;

  DrawGridHeading;

  vsf_interior(vdiHandle, FIS_HOLLOW);
  DrawGrid(6, cellHeight);

  WriteDates(new_X, new_Y);

  DisplayEvents(new_X, new_Y);

  (* new(PButton, Init(@SELF, 99, 99, true, '') );  *)

  log.Free;

end;


procedure TWinCal.GetWindowClass(var AWndClass : TWndClass);
(* set general features of windows *)

begin
  INHERITED GetWindowClass(AWndClass);
  AWndClass.Style   := cs_DblClks
                     + cs_CreateOnAccOpen
                     + cs_AutoOpen
                     + cs_WorkBackground
                     + cs_CancelOnClose;

  AWndClass.hCursor := IDC_HELP;
end;


function TWinCal.GetIconTitle
        : String;
(* Name of iconified Windows *)

begin
  GetIconTitle := 'GEMiCal';
end;


function TWinCal.GetStyle
        : Integer;
(* set the Element of Windows *)

begin
  GetStyle := INHERITED GetStyle or SLIDER or SIZER;
end;


function TWinCal.GetScroller
        : PScroller;
(* set the Scroller *)

begin
  GetScroller := new(PScroller, Init(@self, 4, 4, 160, 100) );

  (* 1,.,640,. means 1 pixel is scrolled to 640 units         *)
  (* 2,.,320,. means 2 pixels will be scrolled to 320 units   *)
  (* both correspond to a horizontal exposure of 640 pixels	  *)
  (* the window dimensions are not determined here               *)
end;


procedure TWinCal.SetupSize;
(* set the size when first opened *)

var
  wch,
  hch,
  wCell,
  hCell   : integer;

begin
  INHERITED SetupSize;

  (* Work contains the window work area *)
  with Work do
  begin
    X := 10;         (* X,Y correspond to the co-ordinates of the working area *)
    Y := 60;         (* of Windows, not the Auženmaže, min X:=1, min Y:=56=menu+title+subtitle *)
    W := WINWIDTH;   (* W:=113, smallest width of the working area *)
    H := WINHEIGHT;  (* H:=77,  smallest Height, because the window does not go smaller via Sizer *)


    vst_point(vdiHandle, TITLE_FONT_SIZE, wch, hch, wCell, hCell);
    titleHeight  := hch * 2;

    vst_point(vdiHandle, BODY_FONT_SIZE, wch, hch, wCell, hCell);
    headerHeight := hCell * 2;

    cellHeight   := hCell * 6; (*(H - headerHeight) div 6;*)
    cellWidth    := W div 7;
  end;

  Calc(WC_BORDER, Work, Curr)
end;


procedure TWinCal.IconPaint(var PaintInfo : TPaintStruct);
(* write a Text in the iconified Window *)

var
  year,
  month,
  day,
  dayOfWeek : Word;

  dayStr    : String;

begin
  GetDate (year, month, day, dayOfWeek) ;
  str (day, dayStr);

  v_gtext(vdiHandle, Work.X, Work.Y + (Work.h shr 1), ' ' + dayStr);

end;


procedure TWinCal.DrawTitle;

var
  log       : TLogger;
  title      : String;

  wch,
  hch,
  wCell,
  hCell,
  hAlign,
  vAlign     : Integer;

  todayDate  : PDateTime;

  year,
  month,
  day,
  dayOfWeek   : Word;

  hour,
  minute,
  second,
  sec100      : Word;

  dtStr,
  sunrise,
  sunset     : String;

begin
  writeln('TITLE DATE = ', displayDate^.getYYYYFromIso,
                      '-', displayDate^.getMMFromIso);

  log := TLogger.Create(LLDEBUG);

  (* Display the year and month *)
  str(displayDate^.getYYYYFromIso, title);
  title := title + ' ' + mon1[displayDate^.getMMFromIso];

  vst_point(vdiHandle, TITLE_FONT_SIZE, wch, hch, wcell, hcell);
  vst_Alignment(vdiHandle, 1, 0, hAlign, vAlign);

  v_gtext(vdiHandle,
          Work.X + (Work.W div 2),
          Work.Y + (titleHeight div 2),
          title);

  vst_point(vdiHandle, BODY_FONT_SIZE, wch, hch, wCell, hCell);
  vst_Alignment(vdiHandle, 0, 0, hAlign, vAlign);

  (* Display date and time at top left *)
  GetDate(year, month, day, dayOfWeek) ;
  GetTime(hour, minute, second, sec100);

  dtStr := date2str(year, month, day, FALSE);

  v_gtext(vdiHandle,
          Work.X + Attr.charWidth,
          Work.Y + (headerHeight div 2),
          date2Str(year, month, day, TRUE) );

  v_gtext(vdiHandle,
          Work.X + Attr.charWidth,
          Work.Y + Attr.charHeight*3,
          time2Str(hour, minute, second, TRUE) );

  (* Sunrise and Sunset *)
  new (todayDate);
  todayDate^.init;
  todayDate^.dtStr2Obj(dtStr);

  sunRiseSet(conf^.lat, conf^.lng, conf^.UTCoffset
            ,todayDate,  sunrise, sunset);
  dispose(todayDate);

  log.debug ('sunrise ' + sunrise);
  log.debug ('sunset '  + sunset);

  (* Display Sunrise and sunset times at top right *)
  v_gtext(vdiHandle,
          Work.X + Work.W - (25 * Attr.charWidth),
          Work.Y + Attr.boxHeight,
          'Sunrise/set: ' + SubStr(sunrise, 1, 5) );

  v_gtext(vdiHandle,
          Work.X + Work.W - (20 * Attr.charWidth),
          Attr.boxHeight,
          SubStr(sunset, 1, 5) );

end;


procedure TWinCal.DrawGridHeading;

(* Draw the column headings *)
var
  lineLength  : Integer;
  pxArray     : Array [1..10] of Integer;

  x,
  y           : Integer;

  i           : Integer;

  wch,
  hch,
  wcell,
  hcell       : Integer;

begin

  vst_point(vdiHandle, BODY_FONT_SIZE, wch, hch, wCell, hCell);

  DrawGrid (1, headerHeight);

  (* Write Day labels *)
  for i := 0 to 6 do
  begin
    CalcPos(0, i, x, y);
    v_gtext(vdiHandle,
            x + Attr.boxWidth div 2,
            y + hch, (*(cellHeight div 2),*)
            day1[i] );
  end;

end;


procedure TWinCal.DrawGrid(rows,
                           height  : Integer);
var
  log       : TLogger;
  r, c      : Integer;
  pxy       : array[0..3] of integer;  (* Declare in correct order for passing to v_pline *)

  scrollX,
  scrollY,
  Y         : integer;

  qx, qy : integer;

begin
  log := TLogger.Create(LLDEBUG);

  scrollX := Scroller^.GetXOrg;
  scrollY := Scroller^.GetYOrg;

  Y := Work.Y + titleHeight;

  (* Draw heading line *)
  pxy[0] := Work.X;
  pxy[2] := Work.X + (7 * cellWidth);  (* constant X for horizontal line *)

  (* Draw horizontal lines for weeks by changing y co-ords *)
  for r := 0 to rows do
  begin
    (* create a list of co-ords, declaration order above is the important bit *)
    pxy[1] := y;
    pxy[3] := y;

    v_pline(vdiHandle, 2, @pxy);  (* @pxy passes the list of co-ords *)

    if r=0 then
      y := y + headerHeight
    else
      y := y + cellHeight;
  end;

  (* Draw vertical lines for days by changing x co-ords *)
  CalcPos(rows-1, 0,  pxy[0], pxy[3]);

  for c := 0 to 7 do  (* 8 vertical lines for 7 columns *)
  begin
    (* Use column to calc X co-ord in [0] *)
    CalcPos(0, c,  pxy[0], pxy[3]);

    pxy[2] := pxy[0];

    v_pline(vdiHandle, 2, @pxy);  (* @pxy passes the list of co-ords *)
  end;


end;


procedure TWinCal.DisplayEvents(newX,
                                newY   : LongInt);

(* Purpose : Display Events for a month  *)

var
 log         : TLogger;

  row,
  col,
  x,
  y           : Integer;

  wch,
  hch,
  wCell,
  hCell,
  offset,
  lineSpace   : Integer;

  summ,
  time,
  timePlace   : String;

  daysBetween : Real;

  j,
  i           : Integer;

begin

  log := TLogger.Create(LLINFO);

  log.debug ('DisplayEvents');

  vst_point(vdiHandle, BODY_FONT_SIZE, wch, hch, wCell, hCell);
  offset    := hCell + hcell div 2;

  vst_point(vdiHandle, 7, wch, hch, wCell, hCell);
  lineSpace := cellHeight div 3;

  for j := 1 to 31 do
  begin
    CalcCell (displayDate^.day, j, row, col);
    CalcPos(row, col, x, y);

    log.debug ('row ', row);
    log.debug ('col ', col);

    for i := 0 to cellGr^.cell[j]^.counter - 1 do
    begin
      summ      := SubStr (cellGr^.cell[j]^.cellEvents[i]^.summary, 1, 16 );
      time      := SubStr (cellGr^.cell[j]^.cellEvents[i]^.timeStart^.humanDateTime, 11, 5 );

      timePlace := SubStr (Concat(time,
                                  ';',
                                  cellGr^.cell[j]^.cellEvents[i]^.location), 1, 16 );

      log.debug('Summary  ' + summ );
      log.debug('counter ', i);

      v_gtext(vdiHandle,
              x + Attr.boxWidth,
              y + (i * (cellHeight div 3)),
              summ );

      v_gtext(vdiHandle,
              x + Attr.boxWidth,
              y + (i + 1) * lineSpace,
              timePlace );
    end;

  end;

  vst_point(vdiHandle, BODY_FONT_SIZE, wch, hch, wcell, hcell);

  log.Free;

end;


end.
