{
  Created by: Daniel Carlos Dávila - daniel@cdavila.net
  Licenced under MIT

}

unit SvcUtils.Contract;

interface

uses
  System.Classes, SvcUtils.Types, Winapi.Windows, Winapi.WinSvc;

type
  ISvcInfo = interface;

  ISvcUtils = interface
    ['{8863E4F2-0E02-4409-B122-1E6C01F0638B}']
    /// <summary>
    /// Requeries the states, names etc of all services on the given @link(MachineName).
    /// Works only while active.
    /// </summary>
    function RebuildServicesList: ISvcUtils;

    /// <summary>
    /// Install a service and return the instance to set config, start, stop etc...
    /// </summary>
    function InstallService(const AServiceName, ADisplayName: string;
      const AServiceType, AStartType, AErrorControl: DWORD;
      const ABinaryPathName, ALoadOrderGroup: string; const ATagId: LPDWORD;
      const ADependencies: string = '';
      const AExecUserName: string = 'LocalSystem';
      const AUserNamePassword: string = ''): ISvcInfo;

    /// <summary>
    /// Uninstall a service.
    /// </summary>
    function UninstallService(const AServiceName: string): Boolean;

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

  ISvcInfo = interface
    ['{45A629CF-8E3D-452D-8FA0-7491CF544BE1}']
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
    function ServiceName: string;

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
    function GetBinaryPath: string;

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
    function GetUserName: string;
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
    /// Open a handle to the service with the given access rights.
    /// This handle can be deleted via @link(CleanupHandle).
    /// </summary>
    function GetHandle(Access: DWORD): SC_HANDLE;
  end;

implementation

end.
