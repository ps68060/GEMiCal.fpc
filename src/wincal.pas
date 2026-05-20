{$I projopts.i}
{$mode objfpc}

unit WinCal;

interface

  uses
    vdi,
    aes,
    OTypes,
    OWindows,

    Config,
    CellGrid,
    DateStrc;

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
                   calDate : TDateStruct;
                   conf    : TConfig;

                   procedure GetWindowClass(var AWndClass: TWndClass); VIRTUAL;
                   function  GetIconTitle    : String;                 VIRTUAL;
                   function  GetStyle        : SmallInt;               VIRTUAL;
                   function  GetScroller     : PScroller;              VIRTUAL;

                   procedure Paint(var PaintInfo     : TPaintStruct);  VIRTUAL;

                   procedure IconPaint(var PaintInfo : TPaintStruct);  VIRTUAL;
                   procedure SetupSize;                                VIRTUAL;

                   procedure WriteDates;                               VIRTUAL;

                   procedure DrawTitle;

                   procedure DrawGridHeading;

                   procedure DisplayEvents;

                   procedure CalcPos(row,
                                     col   : Integer;
                                     var xVar,
                                         yVar : SmallInt);

                   procedure DrawGrid(rows : Integer);
                 END;

var
  cellGr          : TCellGrid;


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
  endMonthDate : TDateStruct;

(*
constructor TWinCal.Init(AParent: PWindow;  ATitle: string);
  begin
    inherited init(AParent, ATitle);
    conf := TConfig.create;
  end;


destructor TWinCal.Done;
  begin
    conf.free;
    inherited Done;
  end;
*)


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


procedure TWinCal.SetupSize;
(* set the size when first opened *)

var
  wchar,
  hchar      : SmallInt;

  wCell,
  hCell      : SmallInt;

begin
  INHERITED SetupSize;

  conf := TConfig.create;
  
  (* Work contains the window work area *)
  with Work do
  begin
///    X := 10;         (* X,Y correspond to the co-ordinates of the working area *)
///    Y := 60;         (* of Windows, not the Auženmaže, min X:=1, min Y:=56=menu+title+subtitle *)
    W := WINWIDTH;   (* W:=113, smallest width of the working area *)
    H := WINHEIGHT;  (* H:=77,  smallest Height, because the window does not go smaller via Sizer *)

    vst_point(vdiHandle, TITLE_FONT_SIZE, wchar, hchar, wCell, hCell);
    titleHeight  := hCell * 2;

    vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wCell, hCell);
    headerHeight := hCell * 2;

    cellHeight   := hCell * 6; (*(H - headerHeight) div 6;*)
    cellWidth    := (W - X*2) div 7;  // todo - improve calcs
  end;

  Calc(WC_BORDER, Work, Curr)
end;


procedure TWinCal.Paint(var PaintInfo : TPaintStruct);

(* Purpose : called on every change *)

var
  log         : TLogger;

  New_X,
  New_Y : LongInt;

  wchar,
  hchar       : SmallInt;
  wcell,
  hcell       : SmallInt;

begin
  log.level := LLDEBUG;

  vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wCell, hCell);

  new_X := Scroller^.GetXOrg;
  new_Y := Scroller^.GetYOrg;

  (* Display the year and month in larger text *)
  DrawTitle;

  DrawGridHeading;

  vsf_interior(vdiHandle, FIS_HOLLOW);
  DrawGrid(6);

  WriteDates;

  DisplayEvents;
log.debug('Paint: DisplayEvents');

  (* new(PButton, Init(@SELF, 99, 99, true, '') );  *)

log.debug('conf lat', conf.lat);

log.debug('Paint: exit');

end;


function TWinCal.GetIconTitle
        : String;
(* Name of iconified Windows *)

begin
  GetIconTitle := 'GEMiCal';
end;


function TWinCal.GetStyle
        : SmallInt;
(* Purpose : set the Element of Windows *)

begin
  GetStyle := INHERITED GetStyle or SLIDER or SIZER;
end;


function TWinCal.GetScroller
        : PScroller;
(* Purpose : set the Scroller *)

begin
  GetScroller := new(PScroller, Init(@self, 4, 4, 160, 100) );

  (* 1,.,640,. means 1 pixel is scrolled to 640 units         *)
  (* 2,.,320,. means 2 pixels will be scrolled to 320 units   *)
  (* both correspond to a horizontal exposure of 640 pixels	  *)
  (* the window dimensions are not determined here               *)
end;


procedure TWinCal.IconPaint(var PaintInfo : TPaintStruct);
(* Purpose : Write a Text in the iconified Window
 *)

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


procedure TWinCal.CalcPos(row,
                          col   : Integer;
                          var xVar,
                              yVar : SmallInt);
(* Purpose : Calculate the x, y window coords of the cell from row, col.
 * inputs  : row 0 to 6
 *           col 0 to 5
 * returns : x, y pixel positions of the top left corner of the calendar cell
 *)

begin
  log.level := LLDEBUG;
  log.debug('CalcPos: 1');
  xVar := Curr.X + (col * cellWidth);
  yVar := Curr.Y + titleHeight + row * cellHeight;

  log.debug('xVar= ', xVar);
  log.debug('yVar= ', yVar);
  log.debug('CalcPos: exit');

//  if row <= 1 then
//    writeln('CalcPos: row=', row,' ', Curr.Y, ' ', titleHeight, ':', headerHeight, ':', cellHeight, ' result=', yvar);

end;


procedure TWinCal.DrawTitle;

var
  title      : String;

  wchar,
  hchar      : SmallInt;

  wCell,
  hCell      : SmallInt;

  hAlign,
  vAlign     : SmallInt;

  todayDate  : TDateStruct;

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
  log.level := LLINFO;

  writeln('TITLE DATE = ', calDate.getYYYYFromIso,
                      '-', calDate.getMMFromIso);

  (* Display the year and month *)
  str(calDate.getYYYYFromIso, title);
  title := title + ' ' + mon1[calDate.getMMFromIso];

  vst_point(vdiHandle, TITLE_FONT_SIZE, wchar, hchar, wcell, hcell);
  vst_Alignment(vdiHandle, 1, 0, hAlign, vAlign);

  v_gtext(vdiHandle,
          Work.X + (Work.W div 2),
          Work.Y + (titleHeight div 2),
          title);

  vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wCell, hCell);
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
  todayDate := TDateStruct.create;
  todayDate.dtStr2Obj(dtStr);
log.debug('DrawTitle: date 8', dtStr);

  sunRiseSet(conf.lat
            ,conf.lng
            ,conf.UTCoffset
            ,todayDate,  sunrise, sunset);
log.debug('DrawTitle: date 9');

  todayDate.free;
log.debug('DrawTitle: date 10');

  log.debug ('sunrise ' + sunrise);
  log.debug ('sunset '  + sunset);

  (* Display Sunrise and sunset times at top right *)
  v_gtext(vdiHandle,
          Work.X + Work.W - (25 * Attr.charWidth),
          Work.Y + (headerHeight div 2),
          'Sunrise / set ');

  v_gtext(vdiHandle,
          Work.X + Work.W - (25 * Attr.charWidth),
          Work.Y + Attr.charHeight*3,
          SubStr(sunrise, 1, 5) + ' / ' + SubStr(sunset, 1, 5));

end;


procedure TWinCal.DrawGridHeading;
(* Purpose : Draw the column headings *)

var
  pxArray     : Array [1..10] of Integer;

  pixX,
  pixY        : SmallInt;

  scrollX,
  scrollY,
  c           : Integer;

  wchar,
  hchar       : SmallInt;
  wcell,
  hcell       : SmallInt;

begin
  log.level := LLDEBUG;

  scrollX := Scroller^.GetXOrg;
  scrollY := Scroller^.GetYOrg;

  vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wCell, hCell);

  DrawGrid (1);

  (* Write Day labels *)
  LOG.DEBUG('DrawGridHeading: 1');
  for c := 0 to 6 do
  begin
    CalcPos(0, c, pixX, pixY);
    v_gtext(vdiHandle,
            scrollX + pixX + Attr.boxWidth div 2,
            scrollY + pixY + Attr.boxHeight - hCell*2, // hchar, (*(cellHeight div 2),*)
            day1[c] );
  end;

  LOG.DEBUG('DrawGridHeading: exit');
end;


procedure TWinCal.DrawGrid(rows  : Integer);
var
  r, c      : Integer;
  pxy       : array[0..3] of SmallInt;  (* Declare in correct order for passing to v_pline *)

  scrollX,
  scrollY   : integer;

begin
  log.level := LLINFO;

  scrollX := Scroller^.GetXOrg;
  scrollY := Scroller^.GetYOrg;
  log.debug('DrawGrid: scroll X ', scrollX);

  (* Draw heading line *)
  pxy[0] := Curr.X;  // todo - fudged to the right
  pxy[2] := Curr.X + (7 * cellWidth);  (* constant X for horizontal line *)

  (* Draw horizontal lines for weeks by changing y co-ords *)
  //writeln ('Draw horizontal grid ', work.Y, ':', curr.Y);
  for r := 0 to rows do
  begin
    (* create a list of co-ords, declaration order above is the important bit *)
    CalcPos (r, 0, pxy[0], pxy[1]);
    CalcPos (r, 6, pxy[2], pxy[3]);

    pxy[2] := pxy[2] + cellWidth;
    pxy[1] := pxy[1] + scrollY;
    pxy[3] := pxy[3] + scrollY;
    //writeln('DrawGrid : ', rows, '-', pxy[0], ':', pxy[1], ' - ', pxy[2], ':', pxy[3]);

    v_pline(vdiHandle, 2, @pxy);  (* @pxy passes the list of co-ords *)

  end;

  (* Draw vertical lines for days by changing x co-ords *)
  log.debug ('Draw vertical grid');
  for c := 0 to 7 do  (* 8 vertical lines for 7 columns *)
  begin
    (* Use column to calc X co-ord in [0] *)
    CalcPos (0,    c, pxy[0], pxy[1]);
    CalcPos (rows, c, pxy[2], pxy[3]);

    pxy[1] := pxy[1] + scrollY;
    pxy[3] := pxy[3] + scrollY;

    v_pline(vdiHandle, 2, @pxy);  (* @pxy passes the list of co-ords *)
  end;

end;


procedure TWinCal.WriteDates;
var
  pixX,
  pixY         : SmallInt;

  year,
  month,
  day,
  dayOfWeek    : Word;

  currentMonth : Boolean;

  row, col     : LongInt;
  i            : Integer;

  scrollX,
  scrollY      : Integer;

  wchar,
  hchar,
  wCell,
  hCell        : SmallInt;

begin
  log.level := LLDEBUG;

  scrollX := Scroller^.GetXOrg;
  scrollY := Scroller^.GetYOrg;

  log.debug ('year ', calDate.getYYYYFromIso );
  log.debug (mon1[calDate.getMMFromIso] );

  (* Get today's date and check if displaying current month *)
  GetDate (year, month, day, dayOfWeek);

log.debug('WriteDates: 1');
  CalcCellGrid (calDate.day, day, row, col);
log.debug('WriteDates: 2');

  currentMonth := FALSE;
  if     (calDate.getYYYYFromIso = year)
     and (calDate.getMMFromIso   = month)
  then
    currentMonth := TRUE;
log.debug('WriteDates: 3');

  (* Calculate date of end of month *)
  daysInMon := daysInMonth(calDate);
log.debug('WriteDates: 4');

  (* Set the font to get the dimensions *)
  vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wCell, hCell);

  (* Display the dates, highlighting today *)
  for i := 1 to daysInMon do
  begin
    CalcCellGrid (calDate.day, i, row, col);
    CalcPos  (row, col, pixX, pixY);
writeln ('dates: row = ', row, ' col = ', col, '  X = ', pixX, ' Y = ', pixY);

    if (currentMonth)
       and (i = day)
    then
    begin
      (* Highlight today *)
      vst_effects(vdiHandle, TF_UNDERLINED or TF_THICKENED);
      v_gtext(vdiHandle,
              scrollX + pixX + Attr.boxWidth div 2,
              scrollY + pixY + Attr.boxHeight,  (* Use char height and not the char cell height *)
              IntToStr(i) + ' ' + day2[(calDate.day + i - 1) mod 7]);
      vst_effects(vdiHandle, TF_NORMAL);
    end
    else
      v_gtext(vdiHandle,
              scrollX + pixX + Attr.boxWidth div 2,
              scrollY + pixY + Attr.boxHeight,
              IntToStr(i) );
  end;

log.debug('WriteDates: exit');
end;


procedure TWinCal.DisplayEvents;
(* Purpose : Display Events for a month
 *)

var
  pixX,
  pixY        : SmallInt;

  row,
  col         : LongInt;

  scrollX,
  scrollY     : Integer;

  wchar,
  hchar,
  wCell,
  hCell       : SmallInt;

  offset      : LongInt;

  summ,
  time,
  timePlace   : String;

  day,
  i           : Integer;

begin
  log.level := LLDEBUG;
  log.debug ('DisplayEvents: start');

  scrollX := Scroller^.GetXOrg;
  scrollY := Scroller^.GetYOrg;
log.debug('DisplayEvents: 1');

  vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wCell, hCell);
  offset    := hCell + hcell div 2;

log.debug('DisplayEvents: 2');

  vst_point(vdiHandle, 7, wchar, hchar, wCell, hCell);
log.debug('DisplayEvents: 3');

  for day := 1 to 31 do
  begin
    CalcCellGrid (calDate.day, day, row, col);
log.debug('DisplayEvents: day ', day);

    CalcPos(row, col, pixX, pixY);

    log.debug ('events: row ', row);
    log.debug ('events: col ', col);

    for i := 0 to cellGr.cell[day].counter - 1 do
    begin
log.debug('DisplayEvents: i ', i);
log.debug('Summary ', cellGr.cell[day].cellEvents[i].summary);
log.debug('start ', cellGr.cell[day].cellEvents[i].timeStart.humanDateTime);

      summ      := SubStr (cellGr.cell[day].cellEvents[i].summary, 1, 16 );
      time      := SubStr (cellGr.cell[day].cellEvents[i].timeStart.humanDateTime, 11, 5 );

      timePlace := SubStr (Concat(time,
                                  ';',
                                  cellGr.cell[day].cellEvents[i].location), 1, 16 );

      log.debug('Summary  ' + summ );
      log.debug('counter ', i);

      v_gtext(vdiHandle,
              scrollX + pixX + Attr.boxWidth div 2,
              scrollY + pixY + offset,        // (i * lineSpace),
              summ );

      v_gtext(vdiHandle,
              scrollX + pixX + Attr.boxWidth div 2,
              scrollY + pixY + offset + Attr.boxHeight div 2,    //  (i + 1) * lineSpace,
              timePlace );
    end;

  end;

  vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wcell, hcell);

end;

end.
