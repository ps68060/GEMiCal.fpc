unit CalCell;

interface

  uses
    Objects;

  type
    PCalCell  = ^TCalCell;
    TCalCell  = Object(TObject)
      summary : array [1..5] of String;
      counter : Integer;

      constructor init;
      destructor  done; virtual;
    end;


implementation

  constructor TCalCell.init;
  var
    i : Integer;

  begin
    for i := 1 to 5
    do
    begin
      summary[i] := '';
      counter    := 0;
    end;

  end;

  destructor TCalCell.done;
  begin

  end;

end.