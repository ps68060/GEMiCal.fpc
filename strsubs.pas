{$B+,D-,I-,L-,N-,P-,Q-,R-,S-,T-,V-,X+,Z-}

unit StrSubs;

(* AUTHOR  : P SLEGG
   DATE    : 26th April 2020 Version 1
   PURPOSE : 
*)

interface

  FUNCTION UPPERCASE (s : STRING) : STRING;

  FUNCTION INTEGER_TO_CHAR (     Value      : INTEGER;
                             VAR Conversion : CHAR )
          : Boolean;

  FUNCTION CHAR_TO_INTEGER (     Character  : CHAR;
                             VAR Conversion : INTEGER )
          : Boolean;

  FUNCTION IntToStr(myInt : Integer)
          : String;

  FUNCTION INDEX (Key, Text : STRING) : INTEGER;

  FUNCTION LTRIM (Text : STRING) : STRING;

  Function LPad  (txt  : String;
                  len  : Integer;
                  pad  : Char)
          : String;

  FUNCTION GET_TOKEN (VAR Text : STRING) : STRING;


implementation

FUNCTION UPPERCASE (s : STRING) : STRING;
VAR
  i : INTEGER;
BEGIN
  FOR i := 1 to LENGTH(s) DO
    s[i] := UPCASE (s[i]);
  UPPERCASE := s;
END;  (* Uppercase *)


(**
FUNCTION UPPERCASE ( InChar : CHAR; VAR OutChar : CHAR ) : BOOLEAN;
VAR
  InCharOrd : INTEGER;

BEGIN
  InCharOrd := ORD (InChar);
  OutChar   := InChar;

  UPPERCASE := FALSE;
  IF ( (InCharOrd > ORD ('z')) OR
       (InCharOrd < ORD ('A')) )
  THEN
  BEGIN
    UPPERCASE := FALSE;
  END
  ELSE
  BEGIN
    IF ( InCharOrd > ORD ('Z') )
    THEN
    BEGIN
      OutChar := CHR ( InCharOrd - 32 );
      UPPERCASE := TRUE;
    END; (* if *)
(**  END; (* if *)
(**END;**)


FUNCTION INTEGER_TO_CHAR (     Value      : INTEGER;
                           VAR Conversion : CHAR )
        : Boolean;

(* PURPOSE : Converts a single integer into a character representation *)

BEGIN
  IF ( Value >= 0 ) AND ( Value <= 9 )
  THEN
  BEGIN
    Conversion := CHR ( Value + ORD('0') );
    INTEGER_TO_CHAR := TRUE;
  END
  ELSE
    INTEGER_TO_CHAR := FALSE

END;  (* function integer_to_char *)


FUNCTION CHAR_TO_INTEGER (     Character  : CHAR;
                           VAR Conversion : INTEGER )
        : Boolean;

(* PURPOSE : Converts a single character into an integer representation *)

BEGIN
  Conversion := ORD ( Character ) - ORD('0');
  IF ( Conversion >= 0 )
  THEN
    CHAR_TO_INTEGER := TRUE
  ELSE
    CHAR_TO_INTEGER := FALSE

END;  (* function char_to_integer *)


FUNCTION IntToStr(myInt : Integer)
        : String;
var
  convStr : String;

begin
  str(myInt, convStr);
  IntToStr := convStr;
end;


FUNCTION INDEX (Key, Text : STRING) : INTEGER;
{ Purpose : Find the index position of string Key in the string Text }

VAR
  TextLen, KeyLen, TextCursor, KeyCursor : INTEGER;
  
BEGIN
  TextLen := LENGTH (Text);
  KeyLen  := LENGTH (Key);

  TextCursor := 1;
  INDEX      := 0;

  WHILE TextCursor < TextLen DO
  BEGIN

    IF Key[1] = Text[TextCursor]
    THEN
    BEGIN
      INDEX := TextCursor;

      FOR KeyCursor := 1 TO KeyLen DO
      BEGIN
        IF Key[KeyCursor] <> Text[TextCursor + KeyCursor - 1]
        THEN
          INDEX := 0;
      END; (* for *)
    END; (* if *)

    TextCursor := SUCC (TextCursor);
  END; (* while *)

END;


FUNCTION LTrim (Text : STRING)
        : string;
VAR
  i : INTEGER;
BEGIN
  i := 1;
  WHILE (Text[i] <= ' ') AND (i < LENGTH(Text)) DO
    INC (i);

  LTRIM := COPY (Text, i, LENGTH(Text) - i + 1);  (* Remove leading spaces *)
END;  (* LTrim *)


Function LPad (txt  : String;
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


FUNCTION Get_Token (VAR Text : string)
        : string;
(*
  Purpose: Get the first token
           Return the token
           Text = the remainder of the string 
 *)
VAR
  Token    : string;
  SpacePos : integer;

BEGIN
  Text := LTrim(Text);
  SpacePos := POS (' ', Text);

  If (SpacePos = 0)
  THEN
    SpacePos := LENGTH(Text) + 1;

  Get_Token := COPY (Text, 1, SpacePos-1);
  Text := COPY (Text, SpacePos+1, LENGTH(Text) - SpacePos);  (* chop from first space to end *)

END;

end.