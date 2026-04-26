{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}
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
      timeStart : PDateTime;
      timeEnd   : PDateTime;

      constructor Create;
      destructor  Destroy; override;
    end;


implementation

  constructor TCellEvent.Create;
  begin
    summary   := '';
    location  := '';

    new (timeStart);
    timeStart^.init;

    new (timeEnd);
    timeEnd^.init;

  end;


  destructor TCellEvent.Destroy;
  begin
    dispose (timeStart, Done);
    dispose (timeEnd,   Done);
  end;

end.