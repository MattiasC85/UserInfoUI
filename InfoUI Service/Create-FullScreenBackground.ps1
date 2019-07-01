# Creates a full screen 'background' styled for a Windows 10 upgrade, and hides the task bar
# Called by the "Show-OSUpgradeBackground" script
Param($DeviceName)

Function ReApplyBlock([string]$status)
{

    if ($isSys -eq $false)
    {
        $name = 'Block'
        $namedPipe = New-Object IO.Pipes.NamedPipeClientStream('.', $name, 'Out')
        $namedPipe.Connect(2000)
        try
        {
        #$script:reader = New-Object IO.StreamReader($namedPipe)
        $script:writer = New-Object IO.StreamWriter($namedPipe)

        #$reader.ReadLine()
        $writer.WriteLine($status)

        #$reader.Dispose()
        $writer.Dispose()

        $namedPipe.Dispose()
        }
        catch
        {
        write-host "Error while connecting to NamedPipe"
        }
    }
    else
    {
        $userInput::BlockInput($true)   
    }
}

#################### CHANGED ############################
Start-Transcript
$CurId=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$isSys=$CurId.IsSystem

$Script:CloseDialog=$false
$Script:AllowClose=$false																   
# Add required assemblies
$code = @"
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
"@

$userInput = Add-Type -MemberDefinition $code -Name UserInput -Namespace UserInput -PassThru
$userInput::BlockInput($true)

$forcedisplaycode=@'

[DllImport("kernel32.dll", CharSet = CharSet.Auto,SetLastError = true)]

public static extern void SetThreadExecutionState(uint esFlags);

'@

$setThread = Add-Type -memberDefinition $forcedisplaycode -name System -namespace Win32 -passThru

$ES_SYSTEM_REQUIRED = [uint32]"0x00000001"
$ES_DISPLAY_REQUIRED = [uint32]"0x00000002"
$ES_AWAYMODE_REQUIRED = [uint32]"0x00000040"
$ES_CONTINUOUS = [uint32]"0x80000000"
$Setting=$ES_DISPLAY_REQUIRED

$setThread::SetThreadExecutionState($ES_CONTINUOUS -bor $Setting)

##############################################################
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Windows.Forms,System.Drawing
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
Add-Type -Path "$PSSCriptRoot\bin\MahApps.Metro.dll"
Add-Type -Path "$PSSCriptRoot\bin\System.Windows.Interactivity.dll"

# Find screen by DeviceName
$Screens = [System.Windows.Forms.Screen]::AllScreens
$Screen = $Screens | Where {$_.DeviceName -eq $DeviceName}

# Add custom type to hide the taskbar
# Thanks to https://stackoverflow.com/questions/25499393/make-my-wpf-application-full-screen-cover-taskbar-and-title-bar-of-window
$Source = @"
using System;
using System.Runtime.InteropServices;

public class Taskbar
{
    [DllImport("user32.dll")]
    private static extern int FindWindow(string className, string windowText);
    [DllImport("user32.dll")]
    private static extern int ShowWindow(int hwnd, int command);

    private const int SW_HIDE = 0;
    private const int SW_SHOW = 1;

    protected static int Handle
    {
        get
        {
            return FindWindow("Shell_TrayWnd", "");
        }
    }

    private Taskbar()
    {
        // hide ctor
    }

    public static void Show()
    {
        ShowWindow(Handle, SW_SHOW);
    }

    public static void Hide()
    {
        ShowWindow(Handle, SW_HIDE);
    }
}
"@
Add-Type -ReferencedAssemblies 'System', 'System.Runtime.InteropServices' -TypeDefinition $Source -Language CSharp

# Find the user identity from the domain if possible
Try
{
    $PrincipalContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new([System.DirectoryServices.AccountManagement.ContextType]::Domain, [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain())
    $GivenName = ([System.DirectoryServices.AccountManagement.Principal]::FindByIdentity($PrincipalContext,[System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName,[Environment]::UserName)).GivenName
    $PrincipalContext.Dispose()
}
Catch {}

# Create a WPF window
$Window = New-Object System.Windows.Window
$window.Background = "#012a47"
$Window.WindowStyle = [System.Windows.WindowStyle]::None
$Window.ResizeMode = [System.Windows.ResizeMode]::NoResize
$Window.Foreground = [System.Windows.Media.Brushes]::White
$window.Topmost = $true

# Get the bounds of the primary screen
$Bounds = $Screen.Bounds

# Assemble a grid
$Grid = New-object System.Windows.Controls.Grid
$Grid.Width = "NaN"
$Grid.Height = "NaN"
$Grid.HorizontalAlignment = "Stretch"
$Grid.VerticalAlignment = "Stretch"

# Add a column
$Column = New-Object System.Windows.Controls.ColumnDefinition
$Grid.ColumnDefinitions.Add($Column)

# Add rows
$Row = New-Object System.Windows.Controls.RowDefinition
$Row.Height = "1*"
$Grid.RowDefinitions.Add($Row)
$Row = New-Object System.Windows.Controls.RowDefinition
$Row.Height = [System.Windows.GridLength]::Auto
$Grid.RowDefinitions.Add($Row)
$Row = New-Object System.Windows.Controls.RowDefinition
$Row.Height = [System.Windows.GridLength]::Auto
$Grid.RowDefinitions.Add($Row)
$Row = New-Object System.Windows.Controls.RowDefinition
$Row.Height = "1*"
$Grid.RowDefinitions.Add($Row)

# Add a progress ring
$ProgressRing = [MahApps.Metro.Controls.ProgressRing]::new()
$ProgressRing.Opacity = 0
$ProgressRing.IsActive = $false
$ProgressRing.Margin = "0,0,0,60"
$Grid.AddChild($ProgressRing)
$ProgressRing.SetValue([System.Windows.Controls.Grid]::RowProperty,1)

# Add a textblock
$TextBlock = New-Object System.Windows.Controls.TextBlock
If ($GivenName)
{
    $TextBlock.Text = "Hi $GivenName"
}
Else
{
    $TextBlock.Text = "Hi there"
}
$TextBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
$TextBlock.MaxWidth = $Bounds.Width
$TextBlock.Margin = "0,0,0,120"
$TextBlock.FontSize = 50
$TextBlock.FontWeight = [System.Windows.FontWeights]::Light
$TextBlock.VerticalAlignment = "Top"
$TextBlock.HorizontalAlignment = "Center"
$TextBlock.Opacity = 0
$Grid.AddChild($TextBlock)
$TextBlock.SetValue([System.Windows.Controls.Grid]::RowProperty,2)

# Add a textblock
$TextBlock2 = New-Object System.Windows.Controls.TextBlock
$TextBlock2.Margin = "0,0,0,60"
$TextBlock2.Text = "Don't turn off your pc"
$TextBlock2.TextWrapping = [System.Windows.TextWrapping]::Wrap
$TextBlock2.MaxWidth = $Bounds.Width
$TextBlock2.FontSize = 25
$TextBlock2.FontWeight = [System.Windows.FontWeights]::Light
$TextBlock2.VerticalAlignment = "Bottom"
$TextBlock2.HorizontalAlignment = "Center"
$TextBlock2.Opacity = 0
$Grid.AddChild($TextBlock2)
$TextBlock2.SetValue([System.Windows.Controls.Grid]::RowProperty,3)

# Add to window
$Window.AddChild($Grid)

# Create some animations
$FadeinAnimation = [System.Windows.Media.Animation.DoubleAnimation]::new(0,1,[System.Windows.Duration]::new([Timespan]::FromSeconds(3)))
$FadeOutAnimation = [System.Windows.Media.Animation.DoubleAnimation]::new(1,0,[System.Windows.Duration]::new([Timespan]::FromSeconds(3)))
$ColourBrighterAnimation = [System.Windows.Media.Animation.ColorAnimation]::new("#012a47","#1271b5",[System.Windows.Duration]::new([Timespan]::FromSeconds(5)))
$ColourDarkerAnimation = [System.Windows.Media.Animation.ColorAnimation]::new("#1271b5","#012a47",[System.Windows.Duration]::new([Timespan]::FromSeconds(5)))

# An array of sentences to display, in order. Leave the first one blank as the 0 index gets skipped.
$TextArray = @(
    ""
    "We're upgrading you to Windows 10 1803"
    "It may take 30-60 minutes"
    "Your pc will restart a few times"
    "Should anything go wrong (we hope it won't)..."
    "...please give the Helpdesk a call"
    "Now might be a good time to get a coffee :)"
    "We'll have you up and running again in no time"
)

# Start a dispatcher timer. This is used to control when the sentences are changed.
$TimerCode = {
    
    # The IF statement number should equal the number of sentences in the TextArray
    If ($i -lt 7)
    {
        $FadeoutAnimation.Add_Completed({            
            $TextBlock.Opacity = 0
            $TextBlock.Text = $TextArray[$i]
            $TextBlock.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)

        })   
        $TextBlock.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeoutAnimation)   
    }
    # The final sentence to display ongoing
    ElseIf ($i -eq 7)
    {
        
        $FadeoutAnimation.Add_Completed({            
            $TextBlock.Opacity = 0
            $TextBlock.Text = "Windows 10 Upgrade in Progress"
            $TextBlock.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)
            $ProgressRing.IsActive = $True

        })   
        $TextBlock.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeoutAnimation)
    }
    Else
    {}

    $ColourBrighterAnimation.Add_Completed({            
        $Window.Background.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty,$ColourDarkerAnimation)
    })   
    $Window.Background.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty,$ColourBrighterAnimation)
    
############### CHANGED ###############
	$Proc=(Get-Process -Name "TSManager" -ErrorAction SilentlyContinue)
    if ($Proc -eq $null)
    {
        Write-host "TSManager is closed: " (Get-date).TimeOfDay
        $Script:AllowClose=$true
        $Window.Close()
    }
######################################
    $Script:i++

}
$DispatcherTimer = New-Object -TypeName System.Windows.Threading.DispatcherTimer
$DispatcherTimer.Interval = [TimeSpan]::FromSeconds(10)
$DispatcherTimer.Add_Tick($TimerCode)


# Event: Window loaded
$Window.Add_Loaded({
    
    # Activate the window to bring it to the fore
    $This.Activate()

    # Fill the screen
    $Bounds = $screen.Bounds
    $Window.Left = $Bounds.Left
    $Window.Top = $Bounds.Top
    $Window.Height = $Bounds.Height
    $Window.Width = $Bounds.Width

    # Hide the taskbar
    [TaskBar]::Hide()

    # Hide the mouse cursor
    [System.Windows.Forms.Cursor]::Hide()

    # Begin animations
    $TextBlock.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)
    $TextBlock2.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)
    $ProgressRing.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)
    $ColourBrighterAnimation.Add_Completed({            
        $Window.Background.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty,$ColourDarkerAnimation)
    })   
    $Window.Background.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty,$ColourBrighterAnimation)

})

# Event: Window closing
#################### CHANGED ##################
$window.Add_KeyDown{
param
(
  [Parameter(Mandatory)][Object]$sender,
  [Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e 
)

    If ($e.Key -eq "RightShift")
    {
        $Script:CloseDialog=$true
    }
    else{
    ReApplyBlock "blockit"
    #$userInput::BlockInput($true)
    }
}

$window.Add_KeyUp{
param
(
  [Parameter(Mandatory)][Object]$sender,
  [Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e 
)

    If ($e.Key -eq "RightShift")
    {
        $Script:CloseDialog=$false
    }

}

$Window.Add_Closing({
param
(
  [Parameter(Mandatory)][Object]$sender,
  [Parameter(Mandatory)][System.ComponentModel.CancelEventArgs]$e 
)
    if ($AllowClose -eq $true)
    {
    write-host "AllowClose" $AllowClose
    # Restore the taskbar
    [Taskbar]::Show()

    # Restore the mouse cursor
    [System.Windows.Forms.Cursor]::Show()
    ReApplyBlock "done"
    $userInput::BlockInput($false)
    $DispatcherTimer.Stop()
	}
	else{
    write-host ($AllowClose)
    write-host ($Script:AllowClose)
    $e.Cancel=$true
    }
})

# Event: Allows to close the window on right-click (uncomment for testing)
$Window.Add_MouseRightButtonDown({
    if ($CloseDialog -eq $true)
    {
    #Stop-Transcript
    #Start-Sleep -s 1
    $Script:AllowClose=$true
    $This.Close()
    }
})

# Display the window

$Proc=(Get-Process -Name "TSManager" -ErrorAction SilentlyContinue)
if ($Proc -ne $null)
{
$DispatcherTimer.Start()
$Window.ShowDialog()
}
else
{
ReApplyBlock "done"
write-host "TSManager could not be found, not showing the dialog"
}
Stop-Transcript

##################################################
