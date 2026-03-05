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
      timeStart : TDateTime;
      timeEnd   : TDateTime;

      constructor init;
      destructor  done; virtual;

    end;


implementation

  constructor TCellEvent.init;
  begin
    summary   := '';
    location  := '';

    timeStart := TDateTime.create;
    timeEnd   := TDateTime.create;    

  end;


  destructor TCellEvent.done;
  begin
  end;

end.