Start-Transcript -Path C:\Windows\temp\Dialog.log -Append

Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace DesktopLauncher
{
  public static class WinApi
  {
    [Flags]
    public enum ACCESS_MASK : uint
    {
      DELETE = 0x00010000,
      READ_CONTROL = 0x00020000,
      WRITE_DAC = 0x00040000,
      WRITE_OWNER = 0x00080000,
      SYNCHRONIZE = 0x00100000,

      STANDARD_RIGHTS_REQUIRED = 0x000f0000,

      STANDARD_RIGHTS_READ = 0x00020000,
      STANDARD_RIGHTS_WRITE = 0x00020000,
      STANDARD_RIGHTS_EXECUTE = 0x00020000,

      STANDARD_RIGHTS_ALL = 0x001f0000,

      SPECIFIC_RIGHTS_ALL = 0x0000ffff,

      ACCESS_SYSTEM_SECURITY = 0x01000000,

      MAXIMUM_ALLOWED = 0x02000000,

      GENERIC_READ = 0x80000000,
      GENERIC_WRITE = 0x40000000,
      GENERIC_EXECUTE = 0x20000000,
      GENERIC_ALL = 0x10000000,

      DESKTOP_READOBJECTS = 0x00000001,
      DESKTOP_CREATEWINDOW = 0x00000002,
      DESKTOP_CREATEMENU = 0x00000004,
      DESKTOP_HOOKCONTROL = 0x00000008,
      DESKTOP_JOURNALRECORD = 0x00000010,
      DESKTOP_JOURNALPLAYBACK = 0x00000020,
      DESKTOP_ENUMERATE = 0x00000040,
      DESKTOP_WRITEOBJECTS = 0x00000080,
      DESKTOP_SWITCHDESKTOP = 0x00000100,

      WINSTA_ENUMDESKTOPS = 0x00000001,
      WINSTA_READATTRIBUTES = 0x00000002,
      WINSTA_ACCESSCLIPBOARD = 0x00000004,
      WINSTA_CREATEDESKTOP = 0x00000008,
      WINSTA_WRITEATTRIBUTES = 0x00000010,
      WINSTA_ACCESSGLOBALATOMS = 0x00000020,
      WINSTA_EXITWINDOWS = 0x00000040,
      WINSTA_ENUMERATE = 0x00000100,
      WINSTA_READSCREEN = 0x00000200,

      WINSTA_ALL_ACCESS = 0x0000037f
    }

    [Flags]
    public enum CreateProcessFlags : uint
    {
      DEBUG_PROCESS = 0x00000001,
      DEBUG_ONLY_THIS_PROCESS = 0x00000002,
      CREATE_SUSPENDED = 0x00000004,
      DETACHED_PROCESS = 0x00000008,
      CREATE_NEW_CONSOLE = 0x00000010,
      NORMAL_PRIORITY_CLASS = 0x00000020,
      IDLE_PRIORITY_CLASS = 0x00000040,
      HIGH_PRIORITY_CLASS = 0x00000080,
      REALTIME_PRIORITY_CLASS = 0x00000100,
      CREATE_NEW_PROCESS_GROUP = 0x00000200,
      CREATE_UNICODE_ENVIRONMENT = 0x00000400,
      CREATE_SEPARATE_WOW_VDM = 0x00000800,
      CREATE_SHARED_WOW_VDM = 0x00001000,
      CREATE_FORCEDOS = 0x00002000,
      BELOW_NORMAL_PRIORITY_CLASS = 0x00004000,
      ABOVE_NORMAL_PRIORITY_CLASS = 0x00008000,
      INHERIT_PARENT_AFFINITY = 0x00010000,
      INHERIT_CALLER_PRIORITY = 0x00020000,
      CREATE_PROTECTED_PROCESS = 0x00040000,
      EXTENDED_STARTUPINFO_PRESENT = 0x00080000,
      PROCESS_MODE_BACKGROUND_BEGIN = 0x00100000,
      PROCESS_MODE_BACKGROUND_END = 0x00200000,
      CREATE_BREAKAWAY_FROM_JOB = 0x01000000,
      CREATE_PRESERVE_CODE_AUTHZ_LEVEL = 0x02000000,
      CREATE_DEFAULT_ERROR_MODE = 0x04000000,
      CREATE_NO_WINDOW = 0x08000000,
      PROFILE_USER = 0x10000000,
      PROFILE_KERNEL = 0x20000000,
      PROFILE_SERVER = 0x40000000,
      CREATE_IGNORE_SYSTEM_DEFAULT = 0x80000000,
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION
    {
      public IntPtr hProcess;
      public IntPtr hThread;
      public int dwProcessId;
      public int dwThreadId;
    }

    public enum SECURITY_IMPERSONATION_LEVEL
    {
      SecurityAnonymous,
      SecurityIdentification,
      SecurityImpersonation,
      SecurityDelegation
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STARTUPINFO
    {
      public Int32 cb;
      public string lpReserved;
      public string lpDesktop;
      public string lpTitle;
      public Int32 dwX;
      public Int32 dwY;
      public Int32 dwXSize;
      public Int32 dwYSize;
      public Int32 dwXCountChars;
      public Int32 dwYCountChars;
      public Int32 dwFillAttribute;
      public Int32 dwFlags;
      public Int16 wShowWindow;
      public Int16 cbReserved2;
      public IntPtr lpReserved2;
      public IntPtr hStdInput;
      public IntPtr hStdOutput;
      public IntPtr hStdError;
    }

    public enum TOKEN_TYPE
    {
      TokenPrimary = 1,
      TokenImpersonation
    }

    public enum TOKEN_INFORMATION_CLASS : int
    {
      TokenUser = 1,
      TokenGroups,
      TokenPrivileges,
      TokenOwner,
      TokenPrimaryGroup,
      TokenDefaultDacl,
      TokenSource,
      TokenType,
      TokenImpersonationLevel,
      TokenStatistics,
      TokenRestrictedSids,
      TokenSessionId,
      TokenGroupsAndPrivileges,
      TokenSessionReference,
      TokenSandBoxInert,
      TokenAuditPolicy,
      TokenOrigin,
      MaxTokenInfoClass
    };

    public const int READ_CONTROL = 0x00020000;
    public const int STANDARD_RIGHTS_REQUIRED = 0x000F0000;
    public const int STANDARD_RIGHTS_READ = READ_CONTROL;
    public const int STANDARD_RIGHTS_WRITE = READ_CONTROL;
    public const int STANDARD_RIGHTS_EXECUTE = READ_CONTROL;
    public const int STANDARD_RIGHTS_ALL = 0x001F0000;
    public const int SPECIFIC_RIGHTS_ALL = 0x0000FFFF;
    public const int TOKEN_ASSIGN_PRIMARY = 0x0001;
    public const int TOKEN_DUPLICATE = 0x0002;
    public const int TOKEN_IMPERSONATE = 0x0004;
    public const int TOKEN_QUERY = 0x0008;
    public const int TOKEN_QUERY_SOURCE = 0x0010;
    public const int TOKEN_ADJUST_PRIVILEGES = 0x0020;
    public const int TOKEN_ADJUST_GROUPS = 0x0040;
    public const int TOKEN_ADJUST_DEFAULT = 0x0080;
    public const int TOKEN_ADJUST_SESSIONID = 0x0100;

    public const int TOKEN_ALL_ACCESS_P =
      STANDARD_RIGHTS_REQUIRED |
      TOKEN_ASSIGN_PRIMARY |
      TOKEN_DUPLICATE |
      TOKEN_IMPERSONATE |
      TOKEN_QUERY |
      TOKEN_QUERY_SOURCE |
      TOKEN_ADJUST_PRIVILEGES |
      TOKEN_ADJUST_GROUPS |
      TOKEN_ADJUST_DEFAULT;

    public const int TOKEN_ALL_ACCESS =
      TOKEN_ALL_ACCESS_P |
      TOKEN_ADJUST_SESSIONID;

    public const int TOKEN_READ =
      STANDARD_RIGHTS_READ |
      TOKEN_QUERY;

    public const int TOKEN_WRITE =
      STANDARD_RIGHTS_WRITE |
      TOKEN_ADJUST_PRIVILEGES |
      TOKEN_ADJUST_GROUPS |
      TOKEN_ADJUST_DEFAULT;

    public const int TOKEN_EXECUTE = STANDARD_RIGHTS_EXECUTE;

    [DllImport("advapi32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool OpenProcessToken(
      IntPtr ProcessHandle,
      UInt32 DesiredAccess,
      out IntPtr TokenHandle);

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool CreateProcessAsUser(
      IntPtr hToken,
      string lpApplicationName,
      string lpCommandLine,
      IntPtr lpProcessAttributes,
      IntPtr lpThreadAttributes,
      bool bInheritHandles,
      uint dwCreationFlags,
      IntPtr lpEnvironment,
      string lpCurrentDirectory,
      ref STARTUPINFO lpStartupInfo,
      out PROCESS_INFORMATION lpProcessInformation);
	  
	[DllImport("kernel32.dll", SetLastError = true)]
   public static extern bool GetExitCodeProcess(IntPtr hProcess, out uint ExitCode);

   [DllImport("kernel32.dll", SetLastError=true)]
   public static extern UInt32 WaitForSingleObject(IntPtr hHandle, UInt32 dwMilliseconds);

    [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public extern static bool DuplicateTokenEx(
      IntPtr hExistingToken,
      uint dwDesiredAccess,
      IntPtr lpTokenAttributes,
      SECURITY_IMPERSONATION_LEVEL ImpersonationLevel,
      TOKEN_TYPE TokenType,
      out IntPtr phNewToken);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool SetTokenInformation(
      IntPtr TokenHandle,
      TOKEN_INFORMATION_CLASS TokenInformationClass,
      ref UInt32 TokenInformation,
      UInt32 TokenInformationLength);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool LockWorkStation();

    [DllImport("wtsapi32.dll", SetLastError = true)]
    public static extern bool WTSQueryUserToken(
      UInt32 sessionId,
      out IntPtr Token);

    [DllImport("kernel32.dll")]
    public static extern uint WTSGetActiveConsoleSessionId();
  }

  public static class Program
  {
    public static uint Launch(string process, string arguments = "")
    {
      string currentDirectory = Path.GetDirectoryName(process);

      IntPtr currentToken = IntPtr.Zero;
      IntPtr newToken = IntPtr.Zero;
      IntPtr interactiveUserToken = IntPtr.Zero;

      UInt32 dwSessionId = WinApi.WTSGetActiveConsoleSessionId();

      WinApi.OpenProcessToken(
        Process.GetCurrentProcess().Handle,
        WinApi.TOKEN_DUPLICATE,
        out currentToken);

      WinApi.DuplicateTokenEx(
        currentToken,
        (uint)WinApi.ACCESS_MASK.GENERIC_ALL,
        IntPtr.Zero,
        WinApi.SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation,
        WinApi.TOKEN_TYPE.TokenImpersonation,
        out newToken);

      WinApi.SetTokenInformation(
        newToken,
        WinApi.TOKEN_INFORMATION_CLASS.TokenSessionId,
        ref dwSessionId,
        sizeof(UInt32));

      if (WinApi.WTSQueryUserToken(
        WinApi.WTSGetActiveConsoleSessionId(),
        out interactiveUserToken))
      {

        WinApi.STARTUPINFO siInteractive = new WinApi.STARTUPINFO();

        siInteractive.cb = Marshal.SizeOf(siInteractive);
        siInteractive.lpDesktop = @"Winsta0\Default";

        WinApi.PROCESS_INFORMATION piInteractive =
          new WinApi.PROCESS_INFORMATION();

        string usercommandline = "\"" + process + "\" " + arguments;
        //WinApi.LockWorkStation();
        WinApi.CreateProcessAsUser(
          interactiveUserToken,
          null,
          usercommandline,
          //"rundll32.exe user32.dll,LockWorkStation",
          IntPtr.Zero,
          IntPtr.Zero,
          false,
          (uint)WinApi.CreateProcessFlags.CREATE_NO_WINDOW |
          (uint)WinApi.CreateProcessFlags.INHERIT_CALLER_PRIORITY,
          IntPtr.Zero,
          currentDirectory,
          ref siInteractive,
          out piInteractive);

          /////////////////////////////////////
        var curpid=arguments;
        WinApi.STARTUPINFO siSysInteractive = new WinApi.STARTUPINFO();

        siSysInteractive.cb = Marshal.SizeOf(siSysInteractive);
        siSysInteractive.lpDesktop = @"Winsta0\Default";

        WinApi.PROCESS_INFORMATION piSysInteractive =
          new WinApi.PROCESS_INFORMATION();

        string Replace = "\\Blocksvc.ps1";
        string find = "\\";
        int place = arguments.LastIndexOf(find);
        string ArgsEdit = arguments.Remove(place, arguments.Length - place).Insert(place, Replace);


        string syscommandline = "\"" + process + "\" " + ArgsEdit;
        WinApi.CreateProcessAsUser(
          newToken,
          null,
          syscommandline,
          //"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\Powershell.exe -EP bypass -File D:\\UpgradeLab\\block.ps1 -ParentPid " + '"' + arguments + '"',
          //"rundll32.exe user32.dll,LockWorkStation",
          IntPtr.Zero,
          IntPtr.Zero,
          true,
          (uint)WinApi.CreateProcessFlags.CREATE_NO_WINDOW |
            (uint)WinApi.CreateProcessFlags.INHERIT_CALLER_PRIORITY,
          IntPtr.Zero,
          currentDirectory,
          ref siSysInteractive,
          out piSysInteractive);
          ///////////////////////////////////
        
        uint exit_code;
        exit_code=0;
		UInt32 INFINITE = 0xFFFFFFFF;
        WinApi.WaitForSingleObject(piInteractive.hProcess,(uint)INFINITE);
		WinApi.GetExitCodeProcess(piInteractive.hProcess, out exit_code);
		//WinApi.WaitForSingleObject(piSysInteractive.hProcess,(uint)INFINITE);
		//WinApi.GetExitCodeProcess(piSysInteractive.hProcess, out exit_code);
        //Console.WriteLine("Exit Code:" + exit_code);
		return exit_code;
      }

      else{
      System.Threading.Thread.Sleep(100);

      WinApi.STARTUPINFO si = new WinApi.STARTUPINFO();

      si.cb = Marshal.SizeOf(si);
      si.lpDesktop = @"Winsta0\Winlogon";

      WinApi.PROCESS_INFORMATION pi = new WinApi.PROCESS_INFORMATION();

      string commandline = "\"" + process + "\" " + arguments;
      WinApi.CreateProcessAsUser(
        newToken,
        null,
        commandline,
        IntPtr.Zero,
        IntPtr.Zero,
        true,
        (uint)WinApi.CreateProcessFlags.CREATE_NO_WINDOW |
          (uint)WinApi.CreateProcessFlags.INHERIT_CALLER_PRIORITY,
        IntPtr.Zero,
        currentDirectory,
        ref si,
        out pi);
	
        uint exit_code;
		UInt32 INFINITE = 0xFFFFFFFF;
		WinApi.WaitForSingleObject(pi.hProcess,(uint)INFINITE);
		WinApi.GetExitCodeProcess(pi.hProcess, out exit_code);
		return exit_code;	
    }
	}
	     
  }

}

"@

function DeleteTask($FullPathToScript)
{
write-host "Path to Script" $FullPathToScript
#$tasks=(Get-ScheduledTask | % { Where($_.Actions[0].Arguments.ToLower().Contains($FullPathToScript.ToLower())){Write-host $_.TaskName}})
$tasks=Get-ScheduledTask | Where-Object {$_.Actions.Arguments} | Where-Object {$_.Actions.Arguments.ToLower().Contains($FullPathToScript.ToLower())} | Select-Object

write-host "Deleting" $tasks.TaskName
Unregister-ScheduledTask -TaskName $tasks.TaskName -Confirm:$false
[System.IO.File]::Delete($FullPathToScript)
}

if ($CreateService)
{


}

<#$code = @"
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
"@

$userInput = Add-Type -MemberDefinition $code -Name UserInput -Namespace UserInput -PassThru
$userInput::BlockInput($true)
#>
$Provmode=(Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ccm\CcmExec -Name ProvisioningMode).ProvisioningMode
write-host "Provisioning mode:" $Provmode
$process = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$arguments = "-Executionpolicy bypass -File $PSScriptRoot\Show-OSUpgradeBackground.ps1"
$CurId=[System.Security.Principal.WindowsIdentity]::GetCurrent()
Write-host "Current Process running as System: " $CurId.IsSystem

$ConsoleSessionID=[DesktopLauncher.WinApi]::WTSGetActiveConsoleSessionId()
Write-Host "Console SessionID: " $ConsoleSessionID

$Provmode=$false #testar
$Processes=(Get-Process *).ProcessName
if ($Provmode -ne "false")
{
    [IntPtr] $b=[IntPtr]::Zero
    while ($b -eq [IntPtr]::Zero)
    {
        try
        {
            $ConsoleToken=[DesktopLauncher.WinApi]::WTSQueryUserToken($ConsoleSessionID,[ref]$b)
            #write-host $ConsoleSessionID
        }
        catch
        {
            write-host "Error getting ConsoleToken"
        }
    	If (($Processes.Contains("TSManager")) -and ((gwmi Win32_computersystem).Username -eq $null) -and ($ConsoleToken -eq $false))
    	{
		    write-host "No user is logged on."
		    $b=([System.Security.Principal.WindowsIdentity]::GetCurrent()).Token
    	}
        Start-Sleep -Milliseconds 100
        $Processes=(Get-Process *).ProcessName
    }
}
else
{

write-host "Provisioning mode is false, OSD was successful. Deleting task."
#DeleteTask $MyInvocation.MyCommand.Definition
stop-transcript
exit
}



#$b=([System.Security.Principal.WindowsIdentity]::GetCurrent()).Token #testar
#$ConsoleToken=[DesktopLauncher.WinApi]::WTSQueryUserToken($ConsoleSessionID,[ref]$b)

$Consoleuser=[System.Security.Principal.WindowsIdentity]::new($b)
Write-host "Console Username: " $Consoleuser.Name
Write-host "Console user is system: " $Consoleuser.IsSystem


if ($Consoleuser.IsSystem -eq $true)
{
Write-host "Console user is system. Launching interactive."
[DesktopLauncher.Program]::Launch($process, $arguments)
}
else
{
write-host "The Console user isn't system. Running in User Context."
#write-host (Get-date).TimeOfDay
#$userInput::BlockInput($true)
[DesktopLauncher.Program]::Launch($process, $arguments) | Out-Null
#write-host "a:" $a
#write-host (Get-date).TimeOfDay
<#while ([DesktopLauncher.Program]::Launch($process, $arguments))
{
$userInput::BlockInput($true)
Start-Sleep -m 100
write-host (Get-date).TimeOfDay
}#>

#DeleteTask $MyInvocation.MyCommand.Definition
stop-transcript

exit
}

Stop-Transcript
exit
