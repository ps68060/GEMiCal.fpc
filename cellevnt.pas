unit CellEvnt;

interface

  uses
    Objects;


  type
    PCellEvent = ^TCellEvent;
    TCellEvent = Object(TObject)
      summary   : String;
      location  : String;
      timeStart : String;
      timeEnd   : String;

      constructor init;
      destructor  done; virtual;

    end;


implementation

  constructor TCellEvent.init;
  begin
    summary   := '';
    location  := '';
    timeStart := '00:00';
    timeEnd   := '23:59';    
  end;


  destructor TCellEvent.done;
  begin

  end;

end.