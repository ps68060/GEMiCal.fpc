unit CellEvnt;

interface

  uses
    Objects,
    DateTime;


  type
    PCellEvent = ^TCellEvent;
    TCellEvent = Object(TObject)
      summary   : String;
      location  : String;
      timeStart : PDateTime;
      timeEnd   : PDateTime;

      constructor init;
      destructor  done; virtual;

    end;


implementation

  constructor TCellEvent.init;
  begin
    summary   := '';
    location  := '';

    new (timeStart);
    timeStart^.init;

    new (timeEnd);
    timeEnd^.init;    

  end;


  destructor TCellEvent.done;
  begin
    dispose (timeStart, Done);
    dispose (timeEnd,   Done);
  end;

end.