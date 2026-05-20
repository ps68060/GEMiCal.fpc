{$I projopts.i}
{$mode objfpc}

unit CellEvnt;

interface

  uses
    Objects,
    DateStruct;

  type
    TCellEvent = class
      summary   : String;
      location  : String;
      timeStart : TDateStruct;
      timeEnd   : TDateStruct;

      constructor Create;
      destructor  Destroy; override;
    end;


implementation

  constructor TCellEvent.Create;
  begin
    summary   := '';
    location  := '';

    timeStart := TDateStruct.create;
    timeEnd   := TDateStruct.create;

  end;


  destructor TCellEvent.Destroy;
  begin
    timeStart.free;
    timeEnd.free;
  end;

end.