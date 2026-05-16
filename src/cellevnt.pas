{$I projopts.i}
{$mode objfpc}

unit CellEvnt;

interface

  uses
    Objects,
    DateTime;

  type
    TCellEvent = class
      summary   : String;
      location  : String;
      timeStart : TDateTime;
      timeEnd   : TDateTime;

      constructor Create;
      destructor  Destroy; override;
    end;


implementation

  constructor TCellEvent.Create;
  begin
    summary   := '';
    location  := '';

    timeStart := TDateTime.create;
    timeEnd   := TDateTime.create;

  end;


  destructor TCellEvent.Destroy;
  begin
    timeStart.free;
    timeEnd.free;
  end;

end.