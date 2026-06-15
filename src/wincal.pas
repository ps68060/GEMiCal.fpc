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
    DateStrc,
    DateUtils,
    SysUtils;

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
                   calDate : TDateTime;
                   conf    : TConfig;

                   procedure GetWindowClass(var AWndClass: TWndClass); VIRTUAL;
                   function  GetIconTitle    : String;                 VIRTUAL;
                   function  GetStyle        : SmallInt;               VIRTUAL;
                   function  GetScroller     : PScroller;              VIRTUAL;

                   procedure Paint(var PaintInfo     : TPaintStruct);  VIRTUAL;

                   procedure IconPaint(var PaintInfo : TPaintStruct);  VIRTUAL;
                   procedure SetupSize;                                VIRTUAL;

                   function WriteDates       : Integer;

                   procedure DrawTitle;

                   procedure DrawGridHeading;

                   procedure DisplayEvents;

                   procedure CalcWinXY(row,
                                       col   : Integer;
                                       var xVar,
                                           yVar : SmallInt);

                   procedure CalcGridRowCol(xPos,
                                            yPos   : SmallInt;
                                            var rowColVar : array [0..1] of SmallInt);

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
  (* Purpose : Set general features of windows *)
  
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
  (* Purpose : Set the size when first opened *)
  
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
      cellWidth    := (W - X*2) div 7;  //todo - improve calcs
    end;
  
    Calc(WC_BORDER, Work, Curr)
  end;


procedure TWinCal.Paint(var PaintInfo : TPaintStruct);
  (* Purpose : called on every change *)
  
  var
    wchar,
    hchar       : SmallInt;
    wcell,
    hcell       : SmallInt;

    rows        : Integer;
  
  begin
    log.level := LLINFO;

    vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wCell, hCell);
  
    (* Display the year and month in larger text *)
    DrawTitle;
    DrawGridHeading;
  
    vsf_interior(vdiHandle, FIS_HOLLOW);
    rows := WriteDates + 1;
    DrawGrid(rows);
    DisplayEvents;
  
    (* new(PButton, Init(@SELF, 99, 99, true, '') );  *)
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
    dayNumber : Word;
  
    dayStr    : String;
  
  begin
    GetDate (year, month, day, dayNumber) ;
    str (day, dayStr);
  
    v_gtext(vdiHandle, Work.X, Work.Y + (Work.h shr 1), ' ' + dayStr);
  end;


procedure TWinCal.CalcWinXY(row,
                            col   : Integer;
                            var xVar,
                                yVar : SmallInt);
  (* Purpose : Calculate the x, y window coords of the cell from row, col.
   * inputs  : row 0 to 6
   *           col 0 to 5
   * returns : x, y pixel positions of the top left corner of the calendar cell
   *)
  
  begin
    log.level := LLINFO;
    xVar := Curr.X + (col * cellWidth);
    yVar := Curr.Y + titleHeight + row * cellHeight;
  
    log.debug('xVar= ', xVar);
    log.debug('yVar= ', yVar);
    log.debug('CalcWinXY: exit');
  end;


procedure TWinCal.CalcGridRowCol(xPos,
                                 yPos   : SmallInt;
                                 var rowColVar : array [0..1] of SmallInt);
  (* Purpose : Calculate the row and column of the calendar cell from x, y window coords
   * inputs  : x, y pixel coords.
   * returns : rowColVar
    *          where [0] is row = 0 to 6
   *                 [1] is col = 0 to 5
   *)
  begin
    log.level := LLINFO;
    rowColVar[0] := (yPos - Curr.Y - titleHeight) div cellHeight;
    rowColVar[1] := (xPos - Curr.X) div cellWidth;

    log.debug('rowVar= ', rowColVar[0]);
    log.debug('colVar= ', rowColVar[1]);
  end;


procedure TWinCal.DrawTitle;
  var
    title      : String;

    scrollX,
    scrollY    : Integer;
  
    wchar,
    hchar,  
    wCell,
    hCell      : SmallInt;
  
    hAlign,
    vAlign     : SmallInt;
  
    year,
    month,
    day,
    dayNumber   : Word;
  
    hour,
    minute,
    second,
    sec100      : Word;
  
    dateStr,
    timeStr,
    sunrise,
    sunset     : String;
    
    currentDateTime : TDateTime;
  
  begin
    log.level := LLINFO;

    scrollX := Scroller^.GetXOrg;
    scrollY := Scroller^.GetYOrg;
  
    writeln('TITLE DATE = ', YearOf(calDate),
                        '-', MonthOf(calDate));
  
    (* Display the year and month *)
    Str(YearOf(calDate), title);
    title := title + ' ' + mon1[MonthOf(calDate)];
  
    vst_point(vdiHandle, TITLE_FONT_SIZE, wchar, hchar, wcell, hcell);
    vst_Alignment(vdiHandle, 1, 0, hAlign, vAlign);
  
    v_gtext(vdiHandle,
            Work.X + (Work.W div 2),
            Work.Y + (titleHeight div 2),
            title);
  
    vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wCell, hCell);
    vst_Alignment(vdiHandle, 0, 0, hAlign, vAlign);
  
    (* Display current date and time at top left *)
    GetDate(year, month, day, dayNumber) ;
    GetTime(hour, minute, second, sec100);

    currentDateTime := EncodeDateTime(year, month, day, hour, minute, second, sec100);
    dateStr := DateToStr(currentDateTime);
    dateStr := dateStr + ' ' + day2[DayOfWeek(currentDateTime) - 1];

    timeStr := SubStr(TimeToStr(currentDateTime), 1, 5);
    if   (IsBST(currentDateTime))
    then
      timeStr := timeStr + '-BST'
    else
      timeStr := timeStr + '-GMT';

    v_gtext(vdiHandle,
            Work.X + Attr.charWidth,
            Work.Y + (headerHeight div 2),
            dateStr);
  
    v_gtext(vdiHandle,
            Work.X + Attr.charWidth,
            Work.Y + Attr.charHeight*3,
            timeStr );
  
    (* Display sunrise and sunset times of 1st of month *)
    SunRiseSet(conf.lat
              ,conf.lng
              ,conf.UTCoffset
              ,calDate,  sunrise, sunset);
  
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
            SubStr(sunrise, 1, 5) + ' / ' + SubStr(sunset, 1, 5) );
  end;


procedure TWinCal.DrawGridHeading;
  (* Purpose : Draw the column headings *)
  
  var
    pxy         : Array [0..1] of SmallInt;
  
    pixX,
    pixY        : SmallInt;
  
    scrollX,
    scrollY,
    c           : Integer;
  
    wchar,
    hchar,
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
      CalcWinXY(0, c, pixX, pixY);
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
    pxy[0] := Curr.X;  //todo - fudged to the right
    pxy[2] := Curr.X + (7 * cellWidth);  (* constant X for horizontal line *)
  
    (* Draw horizontal lines for weeks by changing y co-ords *)
    //writeln ('Draw horizontal grid ', work.Y, ':', curr.Y);
    for r := 0 to rows do
    begin
      (* create a list of co-ords, declaration order above is the important bit *)
      CalcWinXY (r, 0, pxy[0], pxy[1]);
      CalcWinXY (r, 6, pxy[2], pxy[3]);
  
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
      CalcWinXY (0,    c, pxy[0], pxy[1]);
      CalcWinXY (rows, c, pxy[2], pxy[3]);
  
      pxy[1] := pxy[1] + scrollY;
      pxy[3] := pxy[3] + scrollY;
  
      v_pline(vdiHandle, 2, @pxy);  (* @pxy passes the list of co-ords *)
    end;
  end;


function GetFirstOffset(aDate : TDateTime)
        : Integer;
  begin
    GetFirstOffset := (DayOfWeek(aDate) + 6) mod 7;
  end;


function TWinCal.WriteDates
        : Integer;
  (* Purpose : Write the dates in the calendar, highlighting today if current month
   *           return: the row number of the last date written.
   *)
  var
    pixX,
    pixY         : SmallInt;
  
    yearNow,
    monthNow,
    dateNow,
    dayNumber,
    firstOffset  : Word;

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
  
    log.debug ('year  ', YearOf(calDate) );
    log.debug ('month ', mon1[MonthOf(calDate)] );
    log.debug ('date  ', DayOf(calDate) );
  
    (* Get today's date and check if displaying current month *)
    GetDate (yearNow, monthNow, dateNow, dayNumber);

    currentMonth := FALSE;
    if     (YearOf(calDate)  = yearNow)
       and (MonthOf(calDate) = monthNow)
    then
      currentMonth := TRUE;
  
    (* Set the font to get the dimensions *)
    vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wCell, hCell);

    firstOffset := GetFirstOffset(calDate);
    writeln('DayOfWeek    =', DayOfWeek(calDate) );
    writeln('DayOfTheWeek =', DayOfTheWeek(calDate), ' ', DateToISO8601(calDate) );
    writeln('firstOffset  =', firstOffset);

 CalcCellGrid(firstOffset, 1, row, col);
 log.level := LLDEBUG;
 log.debug('row=', row);

    (* Display the dates, highlighting today *)
    for i := 1 to DaysInMonth(calDate) do
    begin
      CalcCellGrid(firstOffset, i, row, col);
      CalcWinXY(row, col, pixX, pixY);

      if (currentMonth)
         and (i = dateNow)
      then
      begin
        (* Highlight today *)
        vst_effects(vdiHandle, TF_UNDERLINED or TF_THICKENED);
        v_gtext(vdiHandle,
                scrollX + pixX + Attr.boxWidth div 2,
                scrollY + pixY + Attr.boxHeight,  (* Use char height and not the char cell height *)
                IntToStr(i) + ' ' + day2[(DayOf(calDate) + i - 1) mod 7]);
        vst_effects(vdiHandle, TF_NORMAL);
      end
      else
        v_gtext(vdiHandle,
                scrollX + pixX + Attr.boxWidth div 2,
                scrollY + pixY + Attr.boxHeight,
                IntToStr(i) );
    end;
  
  log.debug('WriteDates: exit, last row=', row);
    WriteDates := row;
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
  
    vst_point(vdiHandle, 7, wchar, hchar, wCell, hCell);
  
    for day := 1 to 31 do
    begin
      CalcCellGrid (GetFirstOffset(calDate), day, row, col);
      CalcWinXY(row, col, pixX, pixY);

      if (cellGr.calCell[day].counter > 0)
      then
      begin
        for i := 0 to cellGr.calCell[day].counter - 1 do
        begin
          summ      := SubStr (cellGr.calCell[day].cellEvents[i].summary, 1, 16 );
          time      := TimeToStr(cellGr.calCell[day].cellEvents[i].timeStart.fpDateTime);
  
          timePlace := SubStr (Concat(time,
                                      ';',
                                      cellGr.calCell[day].cellEvents[i].location), 1, 16 );
  
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
        end;  // for
      end;  // if
    end;  // for

    vst_point(vdiHandle, BODY_FONT_SIZE, wchar, hchar, wcell, hcell);
  end;

end.
