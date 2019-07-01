Start-Transcript -Path C:\Windows\temp\block1.log -Append
#write-host $ParentPid
#Stop-Transcript
#exit
function Block
{
    #write-host "ReapplyBlock" (Get-Date).TimeOfDay
    [UserInput.UserInput]::BlockInput($true)
}


$code = @"
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
"@

$userInput = Add-Type -MemberDefinition $code -Name UserInput -Namespace UserInput -PassThru
[UserInput.UserInput]::BlockInput($true)


$Done=$false
$indata=""
while ($Done -ne $true)
{
$name = 'Block'
$PipeSecurity = new-object System.IO.Pipes.PipeSecurity
$sid = [System.Security.Principal.SecurityIdentifier]::new([System.Security.Principal.WellKnownSidType]::AuthenticatedUserSid, $null)
$AccessRule = New-Object System.IO.Pipes.PipeAccessRule($sid, "ReadWrite", "Allow" )
$PipeSecurity.AddAccessRule($AccessRule)
$namedPipe = New-Object IO.Pipes.NamedPipeServerStream($name,'In',100,"Message","Asynchronous", 32768,32768,$PipeSecurity)

#$namedPipe = New-Object IO.Pipes.NamedPipeServerStream($name, 'In')
#$namedPipe.SetAccessControl
$namedPipe.WaitForConnection()
write-host "."
$script:reader = New-Object IO.StreamReader($namedPipe)
$indata=$reader.ReadLine()
write-host $indata
    if ($indata.ToLower() -eq "done")
    {
        $Done=$true
    }
    if ($indata.ToLower() -eq "blockit")
    {
    Block
    }
$reader.Dispose()
$namedPipe.Dispose()
}

[UserInput.UserInput]::BlockInput($false)
Stop-Transcript