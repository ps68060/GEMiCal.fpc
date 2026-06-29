{$I projopts.i}
{$mode objfpc}

unit nvram;

interface

uses
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


  // FPCs Atari RTL provides this
  // Uses C declaration
  // xbi to map to XBIOS trap dispatcher trap #14
  function NVMaccess(mode   : Integer;
                     start  : Integer;
                     count  : Integer;
                     buffer : Pointer)
          : Integer;   cdecl;   external 'xbi';

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


procedure ReadLang;
  var
    nv : TNVRam;
  begin
    NVMaccess(0, 0, SizeOf(nv), @nv);  // mode 0 = read
    writeLn('Language code = ', nv.language);
    writeLn('Language name = ', LANGUAGES[nv.language]);
  end;

end.