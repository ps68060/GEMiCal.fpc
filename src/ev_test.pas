    
    
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
    
    // original was

    tokens := TToken.Create;
    tokens.tokeniseIcal(currentLn);  // Split string at : and ; and store in tokens.part[0..n]

    if (tokens.StartsWith(CREATED_TK))
    then
    created := tokens.part[2];

    if (tokens.StartsWith(UID_TK))
    then
    uid := tokens.part[2];

    if (tokens.StartsWith(DTSTART_TK))
    then
    begin
      (*       part[0] = "DTSTART"
       *       part[1] = "TZID=Europe/London"
       *       part[2] = "20200516T000000"
       *)
      dtStart   := tokens.part[2];
      dtStartTz := GetTimeZone(tokens.part[1]);
    end;

    if (tokens.StartsWith(DTEND_TK))
    then
    begin
      dtEnd   := tokens.part[2];
      dtEndTz := GetTimeZone(tokens.part[1]);
    end;

    if ( tokens.StartsWith(SUMMARY_TK))
    and (NOT alarm)
    then
    summary := tokens.part[2];

    if ( tokens.StartsWith(DESCR_TK))
    and (NOT alarm)
    then
    description := tokens.part[2];

    if ( tokens.StartsWith(LOCATION_TK))
    and (NOT alarm)
    then
    location := tokens.part[2];

    if (NOT alarm )
    and (tokens.StartsWith(BEGIN_ALARM_TK))
    then
    alarm := GetAlarm(calFile);

    if (tokens.StartsWith(END_ALARM_TK))
    then
    alarm := FALSE;

    if (tokens.StartsWith(RECUR_RULE_TK))
    then
    log.info('Recurring event not yet handled.' + tokens.part[2]);

    tokens.Free;

