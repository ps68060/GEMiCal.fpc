{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}

unit StrSubs;

(* AUTHOR  : P SLEGG
   DATE    : 26th April 2020 Version 1
   PURPOSE : 
*)

interface

  function UPPERCASE (s : STRING) : STRING;

  function INTEGER_TO_CHAR (     Value      : INTEGER;
                             var Conversion : CHAR )
          : Boolean;

  function CHAR_TO_INTEGER (     Character  : CHAR;
                             var Conversion : INTEGER )
          : Boolean;

  function IntToStr(myInt : Integer)
          : String;

  function INDEX (Key, Text : STRING) : INTEGER;

  function LTRIM (Text : STRING) : STRING;

  function LPad  (txt  : String;
                  len  : Integer;
                  pad  : Char)
          : String;

  function SubStr(myStr : String;
                  index,
                  count : Integer)
          : String;

  function GET_TOKEN (var Text : STRING) : STRING;


implementation

function UPPERCASE (s : STRING) : STRING;
var
  i : INTEGER;
begin
  for i := 1 to LENGTH(s) do
    s[i] := UPCASE (s[i]);
  UPPERCASE := s;
end;  (* Uppercase *)




function INTEGER_TO_CHAR (     Value      : INTEGER;
                           var Conversion : CHAR )
        : Boolean;

(* PURPOSE : Converts a single integer into a character representation *)

begin

  if ( Value >= 0 ) AND ( Value <= 9 )
  then
  begin
    Conversion := CHR ( Value + ORD('0') );
    INTEGER_TO_CHAR := TRUE;
  end
  ELSE
    INTEGER_TO_CHAR := FALSE

end;  (* function integer_to_char *)


function CHAR_TO_INTEGER (     Character  : CHAR;
                           var Conversion : INTEGER )
        : Boolean;

(* PURPOSE : Converts a single character into an integer representation *)

begin
  Conversion := ORD ( Character ) - ORD('0');
  if ( Conversion >= 0 )
  then
    CHAR_TO_INTEGER := TRUE
  else
    CHAR_TO_INTEGER := FALSE

end;  (* function char_to_integer *)


function IntToStr(myInt : Integer)
        : String;
var
  convStr : String;

begin
  str(myInt, convStr);
  IntToStr := convStr;
end;


function INDEX (Key, Text : STRING) : INTEGER;
{ Purpose : Find the index position of string Key in the string Text }

var
  TextLen, KeyLen, TextCursor, KeyCursor : INTEGER;
  
begin
  TextLen := LENGTH (Text);
  KeyLen  := LENGTH (Key);

  TextCursor := 1;
  INDEX      := 0;

  WHILE TextCursor < TextLen DO
  begin

    if Key[1] = Text[TextCursor]
    then
    begin
      INDEX := TextCursor;

      FOR KeyCursor := 1 TO KeyLen DO
      begin
        if Key[KeyCursor] <> Text[TextCursor + KeyCursor - 1]
        then
          INDEX := 0;
      end; (* for *)
    end; (* if *)

    TextCursor := SUCC (TextCursor);
  end; (* while *)

end;


function LTrim (Text : STRING)
        : string;
var
  i : Integer;
begin
  i := 1;
  while (Text[i] <= ' ') and (i < LENGTH(Text)) do
    INC (i);

  LTRIM := COPY (Text, i, LENGTH(Text) - i + 1);  (* Remove leading spaces *)
end;  (* LTrim *)


function LPad (txt  : String;
               len  : Integer;
               pad  : Char)
        : String;
var
  temp : String;
begin
  temp := txt;

  while (length(temp) < len)
  do
  begin
    temp := pad + temp;
  end;

  LPad := temp;
end;


function SubStr(myStr : String;
                index,
                count : Integer)
        : String;
begin
  SubStr := Copy(myStr, index, count);
end;


function Get_Token (var Text : string)
        : string;
(*
  Purpose: Get the first token
           Return the token
           Text = the remainder of the string 
 *)
var
  Token    : string;
  SpacePos : integer;

begin
  Text := LTrim(Text);
  SpacePos := POS (' ', Text);

  if (SpacePos = 0)
  then
    SpacePos := LENGTH(Text) + 1;

  Get_Token := COPY (Text, 1, SpacePos-1);
  Text := COPY (Text, SpacePos+1, LENGTH(Text) - SpacePos);  (* chop from first space to end *)

end;

end.