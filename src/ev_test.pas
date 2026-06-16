    
    
    var
      parts, leftParts: TStringArray;
      propName, paramStr, value: String;

    begin
      // Split at the first colon
      parts := SplitString(currentLn, ':');

      if Length(parts) < 2
      then
        Exit;  // Invalid iCal
    
      // Split left side into property + parameters
      leftParts := SplitString(parts[0], ';');
    
      propName := leftParts[0];
      value    := parts[1];
    
      if Length(leftParts) > 1
      then
        paramStr := leftParts[1]
      else
        paramStr := '';
    
      case propName of
    
        CREATED_TK:
        created := value;
  
        UID_TK:
        uid := value;
  
        DTSTART_TK:
        begin
          dtStart   := value;
          dtStartTz := GetTimeZone(paramStr);
        end;
  
        DTEND_TK:
        begin
          dtEnd   := value;
          dtEndTz := GetTimeZone(paramStr);
        end;
  
        SUMMARY_TK:
        if not alarm then
          summary := value;
  
        DESCR_TK:
        if not alarm then
          description := value;
  
        LOCATION_TK:
        if not alarm then
          location := value;
  
        BEGIN_ALARM_TK:
        if not alarm then
          alarm := GetAlarm(calFile);
  
        END_ALARM_TK:
          alarm := False;
  
        RECUR_RULE_TK:
          log.info('Recurring event not yet handled. ' + value);

      end;
    
    
    end; // case
    end;