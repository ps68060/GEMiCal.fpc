{$I projopts.i}
{$mode objfpc}

unit Resource;
{$I gemical.i}

interface

uses
  Xbios,
  Objects;

type
  TNVRam = record
    bootpref  : SmallInt;
    reserved  : array[0..3] of Char;
    language  : Byte;
    keyboard  : Byte;
    datetime  : Byte;
    separator : Char;
    bootdelay : Byte;
    reserved2 : array[0..2] of Char;
    vmode     : SmallInt;
    scsi      : Byte;
  end;

  procedure LoadResourceFiles;

  procedure ReadLang;

implementation

const
  LANGUAGES : array [0..19] of String
            = ('US-English', 'German',     'French',    'UK-English',
               'Spanish',    'Italian',    'Swedish',
               'Swiss-French', 'Swiss-German',
               'Danish',     'Dutch',      'Norwegian', 'Czech',
               'Slovak',     'Hungarian',  'Polish',    'Russian',
               'Finnish',    'Portuguese', 'Turkish');


procedure LoadResourceFiles;
  begin
    (* Get current path *)
    GetDir (0, directory);
    
    LoadResource ('GEMICAL.RSC','');
    
    (* Load and set-up the menu *)
    LoadMenu (TREE000);
  end;


procedure ReadLang;
  var
    nv           : TNVRam;
    langTree     : Integer;
    dayHeadings  : array [0..6] of string;

  begin
    NVMaccess(0, 0, SizeOf(nv), @nv);  // mode (0 = read), start, count, buffer
    writeLn('Language code = ', nv.language);
    writeLn('Language name = ', LANGUAGES[nv.language]);

    (* Choose correct heading tree *)
//    langTree := GetHeadingTreeForLanguage(nv.language);
//    LoadHeadings(langTree, dayHeadings);
  end;

function GetHeadingTreeForLanguage(LangCode: Byte)
        : Integer;
  begin
    case LangCode of
        0, 3:  Result := DAYS_ENG;   (* US-English, UK-English *)
        1:     Result := DAYS_GER;   (* German *)
        2:     Result := DAYS_FRA;   (* French *)
      else
        result := DAYS_ENG;            (* default *)
    end;
  end;


procedure LoadHeadings(treeID  : Integer;
                       var arr : array of string);
  var
    Tree     : PObject;
    Obj      : PObject;
    i        : Integer;
  begin
    rsrc_gaddr(R_TREE, treeID, @Tree);
  
    obj := @Tree^[Tree^.ob_head];
  
    for i := 0 to High(arr) do
    begin
      arr[i] := obj^.ob_spec;          (* copy G_STRING text *)
      obj    := @Tree^[obj^.ob_next];  (* next object *)
    end;
  end;

end.