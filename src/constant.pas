{$I projopts.i}
{$mode objfpc}

unit Constant;

interface

  const
    dAppName = 'GEMiCal';

    BEGIN_CAL_TK = 'BEGIN:VCALENDAR';
    END_CAL_TK   = 'END:VCALENDAR';
  
    BEGIN_EVENT_TK = 'BEGIN:VEVENT';
    END_EVENT_TK   = 'END:VEVENT';
  
    CREATED_TK    = 'CREATED';
    UID_TK        = 'UID';
  
    DTSTART_TK    = 'DTSTART';
    DTEND_TK      = 'DTEND';
    TZID_TK       = 'TZID';
  
    SUMMARY_TK    = 'SUMMARY';
    DESCR_TK      = 'DESCRIPTION';
    LOCATION_TK   = 'LOCATION';
    RECUR_RULE_TK = 'RRULE';
  
    BEGIN_ALARM_TK  = 'BEGIN:VALARM';
    END_ALARM_TK    = 'END:VALARM';
    TRIGGER_TK      = 'TRIGGER:';
    ALARM_DESC_TK   = 'DESCRIPTION:';
    ALARM_ACTION_TK = 'ACTION:';

    DAYS_IN_WEEK        = 7;
    GRID_DAYS           = 31;
    CALCELL_EVENTS_MAX  = 9;
implementation

end.
