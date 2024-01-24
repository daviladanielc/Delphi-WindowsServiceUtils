unit SvcUtils.Types;

interface

type

  { The states a service can be in. }
  TServiceState = (ssStopped, ssStartPending, ssStopPending, ssRunning,
    ssContinuePending, ssPausePending, ssPaused);

  TServiceStateHelper = record helper for TServiceState
  public
    function ToString: String;
  end;

  { Enumeration of the standard "controls" a service can accept. The shutdown control, if not
    accepted is ignored. The shutdown control can only be sent when a shutdown occurs. }
  TServiceAccept = (saStop, saPauseContinue, saShutdown);

  { The set of "controls" a service can accept. }
  TServiceAccepts = set of TServiceAccept;

  { The service startup enumeration determines how a service is started. ssAutomatic will start the
    service automatically at startup. ssManual will allow applications and other services to start
    this service manually and ssDisabled will disallow the service to be started altogether (but it
    will be kept in the service database). }
  TServiceStartup = (ssAutomatic, ssManual, ssDisabled);

implementation

{ TServiceStateHelper }

function TServiceStateHelper.ToString: String;
begin
  case self of
    ssStopped:
      Result := 'Stopped';
    ssStartPending:
      Result := 'Start Pending';
    ssStopPending:
      Result := 'Stop Pending';
    ssRunning:
      Result := 'Started';
    ssContinuePending:
      Result := 'Continue Pending';
    ssPausePending:
      Result := 'Pause Pending';
    ssPaused:
      Result := 'Paused';
  end;
end;

end.
