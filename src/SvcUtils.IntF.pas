unit SvcUtils.IntF;

interface

uses SvcUtils.Contract, uServiceManager, Winapi.winsvc;

type

  ISvcUtils = SvcUtils.Contract.ISvcUtils;
  ISvcInfo  = SvcUtils.Contract.ISvcInfo;

  TSvcUtils = class
    public
      class function New: ISvcUtils;
  end;

  TSvcType = record 
    const 
      ServiceAdapter = SERVICE_ADAPTER; //Reserved dont't use it
      ServiceFileSystemDriver = SERVICE_FILE_SYSTEM_DRIVER; //File system driver service. 
      ServiceKernelDriver = SERVICE_KERNEL_DRIVER; //Driver service
      ServiceWin32OwnProcess = SERVICE_WIN32_OWN_PROCESS; //Service that runs in its own process
      ServiceWin32ShareProcess = SERVICE_WIN32_SHARE_PROCESS; //Service that shares a process with other services.
      {If you specify either SERVICE_WIN32_OWN_PROCESS or SERVICE_WIN32_SHARE_PROCESS, 
        and the service is running in the context of the LocalSystem account, you can also specify the following type}
      ServiceInteractiveProcess = SERVICE_INTERACTIVE_PROCESS;
  end;

  TSvcStartType = record
    const 
      ServiceAutoStart = SERVICE_AUTO_START; //A service started automatically by the service control manager during system startup.
      ServiceBootStart = SERVICE_BOOT_START; //A device driver started by the system loader. This value is valid only for driver services.
      ServiceDemandStart = SERVICE_DEMAND_START; //A service started by the service control manager when a process calls the StartService function.
      ServiceDisabled = SERVICE_DISABLED; //A service that cannot be started. Attempts to start the service result in the error code ERROR_SERVICE_DISABLED.
      ServiceSystemStart = SERVICE_SYSTEM_START; //A device driver started by the IoInitSystem function. This value is valid only for driver services.
  end;

  TSvcErrorControl = record
    const
      ServiceErrorCritical = SERVICE_ERROR_CRITICAL; //The startup program logs the error in the event log, if possible. If the last-known-good configuration is being started, the startup operation fails. Otherwise, the system is restarted with the last-known good configuration.
      ServiceErrorIgnore = SERVICE_ERROR_IGNORE; //The startup program ignores the error and continues the startup operation.
      ServiceErrorNormal = SERVICE_ERROR_NORMAL; //The startup program logs the error in the event log but continues the startup operation.
      ServiceErrorSevere = SERVICE_ERROR_SEVERE; //	The startup program logs the error in the event log. If the last-known-good configuration is being started, the startup operation continues. Otherwise, the system is restarted with the last-known-good configuration.
  end;

implementation

{ TSvcUtils }

class function TSvcUtils.New: ISvcUtils;
begin
  Result:= TServiceManager.Create;
end;

end.
