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
    timeStart.Free;
    timeEnd.Free;
    inherited destroy;
  end;

end.