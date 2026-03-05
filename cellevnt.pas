{$mode objfpc}

unit CellEvnt;

interface

  uses
    Objects,
    DateTime;


  type
    TCellEvent = class
    public
      summary   : String;
      location  : String;
      timeStart : TDateTime;
      timeEnd   : TDateTime;

      constructor create;
      destructor  destroy; override;

    end;


implementation

  constructor TCellEvent.create;
  begin
    summary   := '';
    location  := '';

    timeStart := TDateTime.create;
    timeEnd   := TDateTime.create;    

  end;


  destructor TCellEvent.destroy;
  begin
    inherited destroy;
  end;

end.