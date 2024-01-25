# Delphi-WinServiceUtils
Create, delete, stop, start, and change configurations of Windows services.

# Description
The ISvcUtils interface provides a comprehensive set of functionalities for managing Windows services. This component simplifies service-related operations, making it easy to work with service configurations, installations, and more.

Forget about creating .bat files and invoking everything through ShellExecute; now you can do all of that directly in Delphi.

## Key Features:

### Service Management:

 - Rebuild and query the states, names, and configurations of all services on a given machine.
 - Install and uninstall services effortlessly, with options for configuring service type, start type, and more.

### Service Information:

 - Retrieve detailed information about services, including their current state, display name, dependencies, and startup type.
 - Pause, continue, start, and stop services with ease.

### Service Enumeration:

 - Access the total number of services, find services by index or name, and check if a service exists.
   
### Active Service Management:

 - Activate or deactivate the service manager, allowing seamless access to individual service properties.

### Sorting and Exporting:

 - Sort services by display name for better organization.
 - Export service information to XML or CSV format.

## How to install

To use the component is easy, simply add the "src" folder from this repository to the Library path settings in your Delphi or to the Search Path of your project. After that, you only need to declare the "SvcUtils.IntF" unit in the Delphi's uses clause.

### Works with Delphi XE3 to 12.0

## How to use

#### Declaration variable:
```Delphi
var
  LService: ISvcUtils;
begin
  LService:= TSvcUtils.New;
  if LService.GetServiceByName('MyService').isStarted then
    ShowMessage('The service is running');
end;
```

#### One line implementation
```Delphi
  TSvcUtils.New.
           .InstallService('MyService', 'My Service Display Name',
                           TSvcType.ServiceWin32OwnProcess, //default service instalation
                           TSvcStartType.ServiceDemandStart, //start manually
                           TSvcErrorControl.ServiceErrorNormal,
                           'C:\myservice.exe', //Service binary path, the path can also include arguments for an auto-start service. For example, "d:\myshare\myservice.exe arg1 arg2"
                           '', nil).ServiceStart;               
```
or 
```Delphi
  TSvcUtils.New.
           .GetServiceByName('MyService').ServiceStart;               
```

Get the Service Info 

```Delphi
var
  LSvcInfo: ISvcInfo;
begin
  LSvcInfo:= TSvcUtils.New.
           .InstallService('MyService', 'My Service Display Name',
                           TSvcType.ServiceWin32OwnProcess, //default service instalation
                           TSvcStartType.ServiceDemandStart, //start manually
                           TSvcErrorControl.ServiceErrorNormal,
                           'C:\myservice.exe', //Service binary path
                           '', nil);
// with LSvcInfo you can do a lot of things, stop, start, change configuration etc...
// Service description can be set calling LSvcInfo.ChangeDescription('My description');
end;           
```

### Uninstall a Service
```Delphi
 if TSvcUtils.New.UninstallService('MyService') then
    ShowMessage('Done!');
```

### Change service configuration 
```Delphi
  TSvcUtils.New
           .GetServiceByName('MyService')
           .ChangeServiceType()
           .ChangeServiceStart()
           .ChangeServiceErrorControl()
           .ChangeBinaryPath()
           .ChangeAccountName()
           .ChangeDisplayName()
           .ChangeDescription(); 
```

## ATTENTION 
 Make sure your application has administrative privileges.


## Don't worry about freeing up memory objects, as everything is done based on interfaces

<p align="center">
<img src="img/Delphi.png" alt="Delphi">
</p>
<h5 align="center">

Made with :heart: for Delphi
</h5>
