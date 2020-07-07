unit CalCell;

interface

  uses
    Objects;

  type
    PCalCell  = ^TCalCell;
    TCalCell  = Object(TObject)
      summary : array [0..9] of String;
      eventNum: Integer;
      counter : Integer;

      constructor init;
      destructor  done; virtual;
    end;


implementation

  constructor TCalCell.init;
  var
    i : Integer;

  begin
    counter    := 0;
    eventNum   := 0;

    for i := 0 to 9
    do
    begin
      summary[i] := '';
    end;

  end;

  destructor TCalCell.done;
  begin

  end;

end.