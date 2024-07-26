// Written with Delphi XE3 Pro
// Created Nov 24, 2012 by Darian Miller (https://github.com/carmas123/delphi-vault/blob/master/Source/DelphiVault.Windows.ServiceManager.pas)
// Based on answer by Ritsaert Hornstra on May 6, 2011 to question:
// http://stackoverflow.com/questions/5913279/detect-windows-service-state

// Improved by Daniel Carlos Davila - 2024

{$IF CompilerVersion >= 33.0}
  {$DEFINE DELPHIRIOUP}
{$ENDIF}

unit uServiceManager;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Winapi.Winsvc, Winapi.Windows, SvcUtils.Contract, SvcUtils.Types, DBClient,
  System.Classes;

type
  TServiceManager = class;

  { Gives information of and controls a single Service. Can be accessed via @link(TServiceManager). }
  TServiceInfo = class(TInterfacedObject, ISvcInfo)
  private
    { Placeholder of the Index property.  Assigned by the ServiceManager that created this instance. }
    FIndex: Integer;
    { Link the the creating service manager. }
    FServiceManager: TServiceManager;
    { Status of this service. This contains several fields for several properties. }
    FServiceStatus: TServiceStatus;
    { Key name of this service. }
    FServiceName: string;
    { Display name of this service. }
    FDisplayName: string;
    { Are the depenedents searched. If so the @link(FDependents) array is filled with those. }
    FDependentsSearched: Boolean;
    { Array of @link(TServiceInfo) instances that depent on this service. Only filled when
      @link(FDependentsSearched) is True. }
    FDependents: array of ISvcInfo;
    { Placeholder for the live }
    FLive: Boolean;
    // Query Config
    FConfigQueried: Boolean;
    FOwnProcess: Boolean;
    FInteractive: Boolean;
    FStartType: TServiceStartup;
    FBinaryPath: string;
    FUserName: string;
    { Handle of the service during several member calls. }
    FHandle: SC_HANDLE;
    function GetDependentCount: Integer;
  protected
    { Cleanup the handle created with @link(GetHandle). }
    procedure CleanupHandle;
    { Query all dependent services (list them via the @link(TServiceManager). }
    procedure SearchDependents;
    { Query the current status of this service }
    procedure Query;
    { Wait for a given status of this service... }
    procedure WaitFor(State: DWORD);
    { Fetch the configuration information }
    procedure QueryConfig;
  public
    constructor Create; overload;
    constructor Create(ServiceName, DisplayName: String;
      ServiceStatus: TServiceStatus; ServiceManager: TServiceManager;
      Index: Integer); overload;
    destructor Destroy; override;
    function IsStarted: Boolean;
    function IsStartPending: Boolean;
    function IsStopped: Boolean;
    function IsStopPending: Boolean;
    function IsPaused: Boolean;
    function IsPausePending: Boolean;
    function IsContinuePending: Boolean;
    /// <summary>
    /// Action: Pause a running service.
    /// </summary>
    procedure ServicePause(Wait: Boolean);

    /// <summary>
    /// Action: Continue a paused service.
    /// </summary>
    procedure ServiceContinue(Wait: Boolean);

    /// <summary>
    /// Action: Stop a running service.
    /// </summary>
    procedure ServiceStop(Wait: Boolean);

    /// <summary>
    /// Action: Start a not running service.
    /// You can use the @link(State) property to change the state from ssStopped to ssRunning.
    /// </summary>
    procedure ServiceStart(Wait: Boolean);

    /// <summary>
    /// Name of this service.
    /// </summary>
    function ServiceName: String;

    /// <summary>
    /// Display name of this service.
    /// </summary>
    function DisplayName: string;

    /// <summary>
    /// Number of dependent services of this service.
    /// </summary>
    function DependentCount: Integer;

    /// <summary>
    /// Access to services that depend on this service.
    /// </summary>
    function Dependents(AIndex: Integer): ISvcInfo;

    /// <summary>
    /// The current state of the service. You can set the service only to the non-transitional states.
    /// You can restart the service by first setting the State to ssStopped and second ssRunning.
    /// </summary>
    function GetState: TServiceState;

    /// <summary>
    /// Are various properties using live information or historic information.
    /// </summary>
    function GetLive: Boolean;

    /// <summary>
    /// When the service is running, does it run as a separate process (own process) or combined with
    /// other services under svchost.
    /// </summary>
    function OwnProcess: Boolean;

    /// <summary>
    /// Is the service capable of interacting with the desktop.
    /// Possible: The logon must be the Local System Account.
    /// </summary>
    function GetInteractive: Boolean;

    /// <summary>
    /// How is this service started. See @link(TServiceStartup) for a description of startup types.
    /// If you want to set this property, the manager must be activated with AllowLocking set to True.
    /// </summary>
    function GetStartType: TServiceStartup;

    /// <summary>
    /// Path to the binary that implements the service.
    /// </summary>
    function GetBinaryPath: String;

    /// <summary>
    /// See what controls the service accepts.
    /// </summary>
    function GetServiceAccept: TServiceAccepts;

    /// <summary>
    /// Index in ServiceManagers list.
    /// </summary>
    function GetIndex: Integer;
    function SetIndex(const Value: Integer): ISvcInfo;
    /// <summary>
    /// Gets the username associated with the service.
    /// </summary>
    function GetUserName: String;

    /// <summary>
    /// Open a handle to the service with the given access rights.
    /// This handle can be deleted via @link(CleanupHandle).
    /// </summary>
    function GetHandle(Access: DWORD): SC_HANDLE;

    function ChangeServiceType(const AServiceType: DWORD): ISvcInfo;
    function ChangeServiceStart(const AServiceStart: DWORD): ISvcInfo;
    function ChangeServiceErrorControl(const AServiceErrorControl: DWORD)
      : ISvcInfo;
    function ChangeBinaryPath(const ANewBinaryPath: String): ISvcInfo;
    function ChangeAccountName(const AAccountName: String;
      const APassword: String = ''): ISvcInfo;
    function ChangeDisplayName(const ADisplayName: String): ISvcInfo;
    function ChangeDescription(const ADescription: WideString): ISvcInfo;

    /// <summary>
    /// Creates a new instance of the service information interface.
    /// </summary>
    class function New: ISvcInfo; overload;
    class function New(const ServiceName, DisplayName: String;
      const ServiceStatus: TServiceStatus;
      const ServiceManager: TServiceManager; const Index: Integer)
      : ISvcInfo; overload;
  end;

  /// <summary>
  /// A service manager allows the services of a particular machine to be explored and modified.
  /// </summary>
  TServiceManager = class(TInterfacedObject, ISvcUtils)
  private
    FManager: SC_HANDLE;
    FLock: SC_LOCK;
    FMachineName: string;
    FServices: TObjectDictionary<Integer, ISvcInfo>;
    FAllowLocking: Boolean;
    FActive: Boolean;

    /// <summary>
    /// Internal function for locking the manager.
    /// </summary>
    procedure Lock;

    /// <summary>
    /// Internal function for unlocking the manager.
    /// </summary>
    procedure Unlock;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Requeries the states, names etc of all services on the given @link(MachineName).
    /// Works only while active.
    /// </summary>
    procedure RebuildServicesList;

    /// <summary>
    /// Install a service and return the instance to set config, start, stop etc...
    /// </summary>
    function InstallService(const AServiceName, ADisplayName: String;
      const AServiceType, AStartType, AErrorControl: DWORD;
      const ABinaryPathName, ALoadOrderGroup: String; const ATagId: LPDWORD;
      const ADependencies: string = '';
      const AExecUserName: string = 'LocalSystem';
      const AUserNamePassword: String = ''): ISvcInfo;

    /// <summary>
    /// Uninstall a service.
    /// </summary>
    function UninstallService(const AServiceName: String): Boolean;

    /// <summary>
    /// Internal function that frees up all the @link(TServiceInfo) classes.
    /// </summary>
    function CleanupServices: ISvcUtils;

    /// <summary>
    /// Get the number of services. This number is refreshed when the @link(Active) is
    /// set to True or @link(RebuildServicesList) is called. Works only while active.
    /// </summary>
    function GetServiceCount: Integer;

    /// <summary>
    /// Find a servce by index in the services list. This list is refreshed when the @link(Active) is
    /// set to True or @link(RebuildServicesList) is called. Works only while active.
    /// Valid Index values are 0..@link(ServiceCount) - 1.
    /// </summary>
    function GetService(const Index: Integer): ISvcInfo;

    /// <summary>
    /// Find services by name (case insensitive). Works only while active.
    /// If no service can be found an exception will be raised.
    /// </summary>
    function GetServiceByName(const Name: string): ISvcInfo;

    function ServiceExists(const Name: String): Boolean;
    /// <summary>
    /// Activate / deactivate the service manager. In active state can you access the individual
    /// service.
    /// </summary>
    function SetActive(const Value: Boolean): ISvcUtils;
    function GetActive: Boolean;

    /// <summary>
    /// The machine name for which you want the services list.
    /// </summary>
    function SetMachineName(const Value: string): ISvcUtils;

    /// <summary>
    /// Allow locking... Is needed only when changing several properties in TServiceInfo.
    /// Property can only be set while inactive.
    /// </summary>
    function SetAllowLocking(const Value: Boolean): ISvcUtils;

    /// <summary>
    /// Sort services by display name.
    /// </summary>
    function SortByDisplayName: ISvcUtils;
    function ServicesToXMLData(const ASortedByDisplayName:boolean=false): String;
    function ServicesToCSV(const ASortedByDisplayName: boolean=false): String;
  end;

implementation

uses
  System.Generics.Defaults, Vcl.Dialogs, Data.DB;

{ TServiceManager }

procedure TServiceManager.RebuildServicesList;
var
  Services, S: {$IFDEF DELPHIRIOUP}LPENUM_SERVICE_STATUS{$ELSE}PEnumServiceStatus{$ENDIF};
  BytesNeeded, ServicesReturned, ResumeHandle: DWORD;
  i: Integer;
  LServiceInfo: ISvcInfo;
begin
  if not FActive then
    raise Exception.Create('BuildServicesList only works when active');
  // Cleanup
  CleanupServices;
  // Get the amount of memory we need...
  ServicesReturned := 0;
  ResumeHandle := 0;
  Services := nil;
  if EnumServicesStatus(FManager, SERVICE_WIN32, SERVICE_STATE_ALL, {$IFDEF DELPHIRIOUP}Services{$ELSE}Services^{$ENDIF},
    0, BytesNeeded, ServicesReturned, ResumeHandle) then
    Exit;
  if GetLastError <> ERROR_MORE_DATA then
    RaiseLastOSError;
  // And... Get all the data...
  GetMem(Services, BytesNeeded);
  try
    ServicesReturned := 0;
    ResumeHandle := 0;
    S := Services;
    if not EnumServicesStatus(FManager, SERVICE_WIN32, SERVICE_STATE_ALL,
      {$IFDEF DELPHIRIOUP}Services{$ELSE}Services^{$ENDIF}, BytesNeeded, BytesNeeded, ServicesReturned, ResumeHandle) then
      Exit;
    for i := 0 to ServicesReturned - 1 do
    begin
      LServiceInfo := TServiceInfo.New(S^.lpServiceName, S^.lpDisplayName,
        S^.ServiceStatus, Self, i);
      FServices.Add(i, LServiceInfo);
      Inc(S);
    end;
  finally
    FreeMem(Services);
  end;
end;

function TServiceManager.CleanupServices: ISvcUtils;
begin
  Result := Self;
  FServices.Clear;
end;

constructor TServiceManager.Create;
begin
  inherited Create;
  FServices := TObjectDictionary<Integer, ISvcInfo>.Create();
  FManager := 0;
  SetAllowLocking(True);
  SetActive(True);
end;

destructor TServiceManager.Destroy;
begin
  FActive := False;
  FServices.Free;
  inherited Destroy;
end;

function TServiceManager.GetActive: Boolean;
begin
  Result := FManager <> 0;
  FActive := Result;
end;

function TServiceManager.GetService(const Index: Integer): ISvcInfo;
begin
  if FServices.ContainsKey(Index) then
    Result := FServices.Items[index]
  else
    raise Exception.Create('Index out of bounds');
end;

function TServiceManager.GetServiceByName(const Name: string): ISvcInfo;
var
  LServiceInfo: ISvcInfo;
begin
  Result := nil;
  for LServiceInfo in FServices.Values do
  begin
    if Uppercase(LServiceInfo.ServiceName) = Name.ToUpper then
    begin
      Result := LServiceInfo;
      Break;
    end;
  end;
  if Result = nil then
    raise Exception.Create('Service not found');
end;

function TServiceManager.GetServiceCount: Integer;
begin
  Result := FServices.Count;
end;

function TServiceManager.InstallService(const AServiceName,
  ADisplayName: String; const AServiceType, AStartType, AErrorControl: DWORD;
  const ABinaryPathName, ALoadOrderGroup: String; const ATagId: LPDWORD;
  const ADependencies: string = ''; const AExecUserName: string = 'LocalSystem';
  const AUserNamePassword: String = ''): ISvcInfo;
var
  schService: SC_HANDLE;
  DesiredAccess: DWORD;
begin

  { About AExecUserName:
    The name of the account under which the service should run. Specify NULL if you are not changing the existing account name.
    If the service type is SERVICE_WIN32_OWN_PROCESS, use an account name in the form DomainName\UserName.
    The service process will be logged on as this user. If the account belongs to the built-in domain, you can specify }
  Result := nil;
  DesiredAccess := SC_MANAGER_ALL_ACCESS;
  FManager := OpenSCManager(PChar(FMachineName), nil, DesiredAccess);
  schService := CreateServiceA(FManager, PAnsiChar(AnsiString(AServiceName)),
    PAnsiChar(AnsiString(ADisplayName)), SERVICE_ALL_ACCESS, AServiceType,
    AStartType, AErrorControl, PAnsiChar(AnsiString(ABinaryPathName)),
    PAnsiChar(AnsiString(ALoadOrderGroup)), ATagId,
    PAnsiChar(AnsiString(ADependencies)), PAnsiChar(AnsiString(AExecUserName)),
    PAnsiChar(AnsiString(AUserNamePassword)));
  if schService = 0 then
    raise Exception.Create(SysErrorMessage(GetLastError))
  else
  begin
    Self.RebuildServicesList;
    Result := GetServiceByName(AServiceName);
  end;
end;

function TServiceManager.ServiceExists(const Name: String): Boolean;
var
  LServiceInfo: ISvcInfo;
begin
  Result := False;
  for LServiceInfo in FServices.Values do
  begin
    if LServiceInfo.ServiceName.ToUpper = Name.ToUpper then
    begin
      Result := True;
      Break;
    end;
  end;

end;

function TServiceManager.ServicesToCSV(const ASortedByDisplayName:boolean=false): String;
var
  LStr: TStringList;
  I: Integer;
begin
  RebuildServicesList;
  if ASortedByDisplayName then
    SortByDisplayName;
  LStr:= TStringList.Create;
  try
    LStr.Add('ServiceName;DisplayName;BinaryPath;Status');
    for I:= 0 to FServices.Count -1 do
      LStr.Add(Format('%s;%s;%s;%s', [FServices[i].ServiceName, FServices[i].DisplayName, FServices[i].GetBinaryPath, FServices[i].GetState.ToString]));
    Result:= LStr.Text;
  finally
    LStr.Free;
  end;

end;

function TServiceManager.ServicesToXMLData(const ASortedByDisplayName:boolean=false): String;
var
  LCds: TClientDataSet;
  I: integer;
begin
  Self.RebuildServicesList;
  if ASortedByDisplayName then
    SortByDisplayName;
  LCds:= TClientDataSet.Create(nil);
  LCds.FieldDefs.Add('ServiceName', ftString, 256);
  LCds.FieldDefs.Add('DisplayName', ftString, 256);
  LCds.FieldDefs.Add('BinaryPath', ftString, 2000);
  LCds.FieldDefs.Add('Status', ftString, 20);
  LCds.CreateDataSet;
  try
    for I:= 0 to FServices.Count-1 do
    begin
      LCds.Append;
      LCds.FieldByName('ServiceName').AsString:= FServices[i].ServiceName;
      Lcds.FieldByName('DisplayName').AsString:= FServices[i].DisplayName;
      LCds.FieldByName('BinaryPath').AsString:= FServices[i].GetBinaryPath;
      LCds.FieldByName('Status').AsString:= FServices[i].GetState.ToString;
      Lcds.Post;
    end;

    Result:= LCds.XMLData;

  finally
    Lcds.Free;
  end;
end;

function TServiceManager.SetActive(const Value: Boolean): ISvcUtils;
var
  VersionInfo: TOSVersionInfo;
  DesiredAccess: DWORD;
begin
  Result := Self;
  if Value then
  begin
    if FManager <> 0 then
      Exit;
    // Check that we are NT, 2000, XP or above...
    VersionInfo.dwOSVersionInfoSize := sizeof(VersionInfo);
    if not GetVersionEx(VersionInfo) then
      RaiseLastOSError;
    if VersionInfo.dwPlatformId <> VER_PLATFORM_WIN32_NT then
    begin
      raise Exception.Create
        ('This program only works on Windows NT, 2000 or XP');
    end;
    // Open service manager
    DesiredAccess := SC_MANAGER_CONNECT or SC_MANAGER_ENUMERATE_SERVICE;
    if FAllowLocking then
      Inc(DesiredAccess, SC_MANAGER_LOCK);
    FManager := OpenSCManager(PChar(FMachineName), nil, DesiredAccess);
    if FManager = 0 then
      RaiseLastOSError;
    // Fetch the srvices list
    GetActive;
    RebuildServicesList;
  end
  else
  begin
    if FManager = 0 then
      Exit;
    // CleanupServices
    CleanupServices;
    // Close service manager
    if Assigned(FLock) then
      Unlock;
    CloseServiceHandle(FManager);
    FManager := 0;
  end;
end;

function TServiceManager.SetMachineName(const Value: string): ISvcUtils;
begin
  Result := Self;
  if FActive then
    raise Exception.Create('Cannot change machine name while active');
  FMachineName := Value;
end;

procedure TServiceManager.Lock;
begin
  if not FAllowLocking then
    raise Exception.Create('Locking of the service manager not allowed!');
  FLock := LockServiceDatabase(FManager);
  if FLock = nil then
    RaiseLastOSError;
end;

function TServiceManager.UninstallService(const AServiceName: String): Boolean;
var
  schService: SC_HANDLE;
  LService: ISvcInfo;
begin
  RebuildServicesList;
  LService := GetServiceByName(AServiceName);

  schService := LService.GetHandle(SC_MANAGER_ALL_ACCESS);
  try
    Result := DeleteService(schService);
  except
    raise Exception.Create(SysErrorMessage(GetLastError));
  end;
end;

procedure TServiceManager.Unlock;
begin
  // We are unlocked already
  if FLock = nil then
    Exit;
  // Unlock...
  if not UnlockServiceDatabase(FLock) then
    RaiseLastOSError;
  FLock := nil;
end;

function TServiceManager.SetAllowLocking(const Value: Boolean): ISvcUtils;
begin
  Result := Self;
  if FActive then
    raise Exception.Create('Cannot change allow locking while active');
  FAllowLocking := Value;
end;

function TServiceManager.SortByDisplayName: ISvcUtils;
var
  ServiceArray: TArray<ISvcInfo>;
  ServiceInfo: ISvcInfo;
  Index: Integer;
begin
  SetLength(ServiceArray, FServices.Count);

  Index := 0;
  for ServiceInfo in FServices.Values do
  begin
    ServiceArray[Index] := ServiceInfo;
    Inc(Index);
  end;

  TArray.Sort<ISvcInfo>(ServiceArray, TDelegatedComparer<ISvcInfo>.Construct(
    function(const Left, Right: ISvcInfo): Integer
    begin
      Result := TComparer<String>.Default.Compare(Left.DisplayName, Right.DisplayName);
    end));

  FServices.Clear;

  for Index := 0 to Length(ServiceArray) - 1 do
  begin
    ServiceInfo := ServiceArray[Index];
    ServiceInfo.SetIndex(Index);
    FServices.Add(Index, ServiceInfo);
  end;

  Result := Self;
end;

{ TServiceInfo }

function TServiceInfo.ChangeAccountName(const AAccountName, APassword: String)
  : ISvcInfo;
begin
  Result := Self;
  QueryConfig;
  GetHandle(SERVICE_CHANGE_CONFIG);
  try
    try
      ChangeServiceConfig(FHandle, SERVICE_NO_CHANGE, SERVICE_NO_CHANGE,
        SERVICE_NO_CHANGE, nil, nil, nil, nil, PChar(AAccountName),
        PChar(APassword), nil);
    except
      raise Exception.Create(SysErrorMessage(GetLastError));
    end;
  finally
    CleanupHandle;
  end;
end;

function TServiceInfo.ChangeBinaryPath(const ANewBinaryPath: String): ISvcInfo;
begin
  Result := Self;
  QueryConfig;
  GetHandle(SERVICE_CHANGE_CONFIG);
  try
    if Self.IsStarted then
      raise Exception.Create
        ('You must stop the service before changing the binary path.');

    if not ChangeServiceConfig(FHandle, SERVICE_NO_CHANGE, SERVICE_NO_CHANGE,
      SERVICE_NO_CHANGE, PChar(ANewBinaryPath), nil, nil, nil, PChar(FUserName),
      nil, nil) then
      raise Exception.Create(SysErrorMessage(GetLastError));

  finally
    CleanupHandle;
  end;
end;

function TServiceInfo.ChangeDescription(const ADescription: WideString): ISvcInfo;
var
  LDescription: SERVICE_DESCRIPTION;
begin
  Result := Self;
  GetHandle(SERVICE_CHANGE_CONFIG);
  try
    FServiceManager.Lock;
    LDescription.lpDescription := PWideChar(ADescription);
    if not ChangeServiceConfig2(FHandle, SERVICE_CONFIG_DESCRIPTION,
      @LDescription) then
      raise Exception.Create(SysErrorMessage(GetLastError));

  finally
    CleanupHandle;
    FServiceManager.Unlock;
  end;
end;

function TServiceInfo.ChangeDisplayName(const ADisplayName: String): ISvcInfo;
begin
  Result := Self;
  QueryConfig;
  GetHandle(SERVICE_CHANGE_CONFIG);
  try
    if not ChangeServiceConfig(FHandle, SERVICE_NO_CHANGE, SERVICE_NO_CHANGE,
      SERVICE_NO_CHANGE, nil, nil, nil, nil, PChar(FUserName), nil,
      PChar(ADisplayName)) then
      raise Exception.Create(SysErrorMessage(GetLastError));

  finally
    CleanupHandle;
  end;
end;

function TServiceInfo.ChangeServiceErrorControl(const AServiceErrorControl
  : DWORD): ISvcInfo;
begin
  Result := Self;
  QueryConfig;
  GetHandle(SERVICE_CHANGE_CONFIG);
  try

    if not ChangeServiceConfig(FHandle, SERVICE_NO_CHANGE, SERVICE_NO_CHANGE,
      AServiceErrorControl, nil, nil, nil, nil, PChar(FUserName), nil, nil) then
      raise Exception.Create(SysErrorMessage(GetLastError));

  finally
    CleanupHandle;
  end;
end;

function TServiceInfo.ChangeServiceStart(const AServiceStart: DWORD): ISvcInfo;
begin
  Result := Self;
  QueryConfig;
  GetHandle(SERVICE_CHANGE_CONFIG);
  try

    if not ChangeServiceConfig(FHandle, SERVICE_NO_CHANGE, AServiceStart,
      SERVICE_NO_CHANGE, nil, nil, nil, nil, PChar(FUserName), nil, nil) then
      raise Exception.Create(SysErrorMessage(GetLastError));

  finally
    CleanupHandle;
  end;
end;

function TServiceInfo.ChangeServiceType(const AServiceType: DWORD): ISvcInfo;
begin
  Result := Self;
  QueryConfig;
  GetHandle(SERVICE_CHANGE_CONFIG);
  try
    if Self.IsStarted then
      raise Exception.Create
        ('You must stop the service before changing the type.');

    if not ChangeServiceConfig(FHandle, AServiceType, SERVICE_NO_CHANGE,
      SERVICE_NO_CHANGE, nil, nil, nil, nil, PChar(FUserName), nil, nil) then
      raise Exception.Create(SysErrorMessage(GetLastError));

  finally
    CleanupHandle;
  end;
end;

procedure TServiceInfo.CleanupHandle;
begin
  if FHandle = 0 then
    Exit;
  CloseServiceHandle(FHandle);
  FHandle := 0;
end;

constructor TServiceInfo.Create;
begin
  FDependentsSearched := False;
  FConfigQueried := False;
  FHandle := 0;
  FLive := False;
end;

constructor TServiceInfo.Create(ServiceName, DisplayName: String;
ServiceStatus: TServiceStatus; ServiceManager: TServiceManager; Index: Integer);
begin
  FDependentsSearched := False;
  FConfigQueried := False;
  FHandle := 0;
  FLive := False;
  FServiceName := ServiceName;
  FDisplayName := DisplayName;
  FServiceStatus := ServiceStatus;
  FServiceManager := ServiceManager;
  FIndex := Index;
end;

function TServiceInfo.DependentCount: Integer;
begin
  Result := GetDependentCount;
end;

function TServiceInfo.Dependents(AIndex: Integer): ISvcInfo;
begin
  Result:= nil;
  if FDependents[AIndex] <> nil then
    Result:= FDependents[AIndex];
end;

destructor TServiceInfo.Destroy;
begin
  CleanupHandle;
  inherited Destroy;
end;

function TServiceInfo.DisplayName: string;
begin
  Result := FDisplayName
end;

function TServiceInfo.GetDependentCount: Integer;
begin
  SearchDependents;
  Result := Length(FDependents);
end;

function TServiceInfo.GetHandle(Access: DWORD): SC_HANDLE;
begin
  Result := 0;

  if FHandle <> 0 then
  begin
    Result := FHandle;
    Exit;
  end;

  FHandle := OpenService(FServiceManager.FManager, PChar(FServiceName), Access);

  if FHandle = 0 then
    RaiseLastOSError
  else
    Result := FHandle;
end;

function TServiceInfo.GetState: TServiceState;
begin
  if FLive then
    Query;
  case FServiceStatus.dwCurrentState of
    SERVICE_STOPPED:
      Result := ssStopped;
    SERVICE_START_PENDING:
      Result := ssStartPending;
    SERVICE_STOP_PENDING:
      Result := ssStopPending;
    SERVICE_RUNNING:
      Result := ssRunning;
    SERVICE_CONTINUE_PENDING:
      Result := ssContinuePending;
    SERVICE_PAUSE_PENDING:
      Result := ssPausePending;
    SERVICE_PAUSED:
      Result := ssPaused;
  else
    raise Exception.Create('Service State unknown');
  end;
end;

function TServiceInfo.GetUserName: String;
begin
  Result := FUserName;
end;

function TServiceInfo.IsContinuePending: Boolean;
begin
  Result := Self.GetState = ssContinuePending;
end;

function TServiceInfo.IsPaused: Boolean;
begin
  Result := Self.GetState = ssPaused;
end;

function TServiceInfo.IsPausePending: Boolean;
begin
  Result := Self.GetState = ssPausePending;
end;

function TServiceInfo.IsStarted: Boolean;
begin
  Result := Self.GetState = ssRunning;
end;

function TServiceInfo.IsStartPending: Boolean;
begin
  Result := Self.GetState = ssStartPending;
end;

function TServiceInfo.IsStopped: Boolean;
begin
  Result := Self.GetState = ssStopped;
end;

function TServiceInfo.IsStopPending: Boolean;
begin
  Result := Self.GetState = ssStopPending;
end;

class function TServiceInfo.New(const ServiceName, DisplayName: String;
const ServiceStatus: TServiceStatus; const ServiceManager: TServiceManager;
const Index: Integer): ISvcInfo;
begin
  Result := TServiceInfo.Create(ServiceName, DisplayName, ServiceStatus,
    ServiceManager, Index);
end;

class function TServiceInfo.New: ISvcInfo;
begin
  Result := TServiceInfo.Create;
end;

procedure TServiceInfo.Query;
var
  Status: TServiceStatus;
begin
  if FHandle <> 0 then
  begin
    if not QueryServiceStatus(FHandle, Status) then
      RaiseLastOSError;
  end
  else
  begin
    GetHandle(SERVICE_QUERY_STATUS);
    try
      if not QueryServiceStatus(FHandle, Status) then
        RaiseLastOSError;
    finally
      CleanupHandle;
    end;
  end;
  FServiceStatus := Status;
end;

procedure TServiceInfo.ServiceContinue(Wait: Boolean);
var
  Status: TServiceStatus;
begin
  GetHandle(SERVICE_QUERY_STATUS or SERVICE_PAUSE_CONTINUE);
  try
    if not(saPauseContinue in GetServiceAccept) then
      raise Exception.Create('Service cannot be continued');
    if not ControlService(FHandle, SERVICE_CONTROL_CONTINUE, Status) then
      RaiseLastOSError;
    if Wait then
      WaitFor(SERVICE_RUNNING);
  finally
    CleanupHandle;
  end;
end;

function TServiceInfo.ServiceName: String;
begin
  Result := FServiceName;
end;

procedure TServiceInfo.ServicePause(Wait: Boolean);
var
  Status: TServiceStatus;
begin
  GetHandle(SERVICE_QUERY_STATUS or SERVICE_PAUSE_CONTINUE);
  try
    if not(saPauseContinue in GetServiceAccept) then
      raise Exception.Create('Service cannot be paused');
    if not ControlService(FHandle, SERVICE_CONTROL_PAUSE, Status) then
      RaiseLastOSError;
    if Wait then
      WaitFor(SERVICE_PAUSED);
  finally
    CleanupHandle;
  end;
end;

procedure TServiceInfo.ServiceStart(Wait: Boolean);
var
  P: PChar;
begin
  GetHandle(SERVICE_QUERY_STATUS or SERVICE_START);
  try
    P := nil;
    if not StartService(FHandle, 0, P) then
      RaiseLastOSError;
    if Wait then
      WaitFor(SERVICE_RUNNING);
  finally
    CleanupHandle;
  end;
end;

procedure TServiceInfo.ServiceStop(Wait: Boolean);
var
  Status: TServiceStatus;
begin
  GetHandle(SERVICE_QUERY_STATUS or SERVICE_STOP);
  try
    if not(saStop in GetServiceAccept) then
      raise Exception.Create('Service cannot be Stopped');
    if not ControlService(FHandle, SERVICE_CONTROL_STOP, Status) then
      RaiseLastOSError;
    if Wait then
      WaitFor(SERVICE_STOPPED);
  finally
    CleanupHandle;
  end;
end;

procedure TServiceInfo.WaitFor(State: DWORD);
var
  OldCheckPoint, Wait: DWORD;
begin
  Query;
  while State <> FServiceStatus.dwCurrentState do
  begin
    OldCheckPoint := FServiceStatus.dwCheckPoint;
    Wait := FServiceStatus.dwWaitHint;
    if Wait <= 0 then
      Wait := 5000;
    Sleep(Wait);
    Query;
    if State = FServiceStatus.dwCurrentState then
      Break;
    if FServiceStatus.dwCheckPoint <> OldCheckPoint then
    begin
      raise Exception.Create('Service did not react within timeframe given');
    end;
  end;
end;

procedure TServiceInfo.SearchDependents;
var
  Services, S: {$IFDEF DELPHIRIOUP}LPENUM_SERVICE_STATUS{$ELSE}PEnumServiceStatus{$ENDIF};
  BytesNeeded, ServicesReturned: DWORD;
  i: Integer;
begin
  if FDependentsSearched then
    Exit;
  // No dependents found...
  SetLength(FDependents, 0);
  // We need a handle to the service to do any good...
  GetHandle(SERVICE_ENUMERATE_DEPENDENTS);
  try
    // See how many dependents we have...
    Services := nil;
    BytesNeeded := 0;
    ServicesReturned := 0;
    if EnumDependentServices(FHandle, SERVICE_ACTIVE + SERVICE_INACTIVE,
      {$IFDEF DELPHIRIOUP}Services{$ELSE}Services^{$ENDIF}, 0, BytesNeeded, ServicesReturned) then
      Exit;
    if GetLastError <> ERROR_MORE_DATA then
      RaiseLastOSError;
    // Allocate the buffer needed and fetch all info...
    GetMem(Services, BytesNeeded);
    try
      if not EnumDependentServices(FHandle, SERVICE_ACTIVE + SERVICE_INACTIVE,
        {$IFDEF DELPHIRIOUP}Services{$ELSE}Services^{$ENDIF}, BytesNeeded, BytesNeeded, ServicesReturned) then
        RaiseLastOSError;
      // Now process it...
      S := Services;
      SetLength(FDependents, ServicesReturned);
      for i := 0 to High(FDependents) do
      begin
        FDependents[i] := FServiceManager.GetServiceByName(S^.lpServiceName);
        Inc(S);
      end;
    finally
      FreeMem(Services);
    end;
  finally
    CleanupHandle;
  end;
  FDependentsSearched := True;
end;

procedure TServiceInfo.QueryConfig;
var
  Buffer: LPQUERY_SERVICE_CONFIG;
  BytesNeeded: DWORD;
begin
  GetHandle(SERVICE_QUERY_CONFIG);
  try
    // See how large our buffer must be...
    assert(QueryServiceConfig(FHandle, nil, 0, BytesNeeded) = False);
    if GetLastError <> ERROR_INSUFFICIENT_BUFFER then
      RaiseLastOSError;
    GetMem(Buffer, BytesNeeded);
    try
      // Perform the query...
      if not QueryServiceConfig(FHandle, Buffer, BytesNeeded, BytesNeeded) then
        RaiseLastOSError;
      // Analyze the query...
      assert(Buffer^.dwServiceType and SERVICE_WIN32 <> 0);
      // It must be a WIN32 service
      FOwnProcess := (Buffer^.dwServiceType and SERVICE_WIN32)
        = SERVICE_WIN32_OWN_PROCESS;
      FInteractive := (Buffer^.dwServiceType and SERVICE_INTERACTIVE_PROCESS)
        = SERVICE_INTERACTIVE_PROCESS;
      case Buffer^.dwStartType of
        SERVICE_AUTO_START:
          FStartType := ssAutomatic;
        SERVICE_DEMAND_START:
          FStartType := ssManual;
        SERVICE_DISABLED:
          FStartType := ssDisabled;
      else
        raise Exception.Create('Service Start Type unknown');
      end;
      FBinaryPath := Buffer^.lpBinaryPathName;
      FUserName := Buffer^.lpServiceStartName;
      FConfigQueried := True;
    finally
      FreeMem(Buffer);
    end;
  finally
    CleanupHandle;
  end;
end;

function TServiceInfo.OwnProcess: Boolean;
begin
  if FLive or not FConfigQueried then
    QueryConfig;
  Result := FOwnProcess;
end;

function TServiceInfo.GetInteractive: Boolean;
begin
  if FLive or not FConfigQueried then
    QueryConfig;
  Result := FInteractive;
end;

function TServiceInfo.GetLive: Boolean;
begin
  Result := FLive;
end;

function TServiceInfo.GetStartType: TServiceStartup;
begin
  if FLive or not FConfigQueried then
    QueryConfig;
  Result := FStartType;
end;

function TServiceInfo.GetBinaryPath: string;
begin
  if FLive or not FConfigQueried then
    QueryConfig;
  Result := FBinaryPath;
end;

function TServiceInfo.GetServiceAccept: TServiceAccepts;
begin
  Result := [];
  if FLive then
    Query;
  if FServiceStatus.dwControlsAccepted and SERVICE_ACCEPT_PAUSE_CONTINUE <> 0
  then
    Result := Result + [saPauseContinue];
  if FServiceStatus.dwControlsAccepted and SERVICE_ACCEPT_STOP <> 0 then
    Result := Result + [saStop];
  if FServiceStatus.dwControlsAccepted and SERVICE_ACCEPT_SHUTDOWN <> 0 then
    Result := Result + [saShutdown];
end;

function TServiceInfo.GetIndex: Integer;
begin
  Result := FIndex;
end;

function TServiceInfo.SetIndex(const Value: Integer): ISvcInfo;
begin
  Result := Self;
  FIndex := Value;
end;

end.
