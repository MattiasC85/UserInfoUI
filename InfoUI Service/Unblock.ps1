start-transcript C:\unblock.log -Append
Function UnBlock()
{
        try
        {
            $name = 'Block'
            $namedPipe = New-Object IO.Pipes.NamedPipeClientStream('.', $name, 'Out')
            $namedPipe.Connect(2000)

            #$script:reader = New-Object IO.StreamReader($namedPipe)
            $script:writer = New-Object IO.StreamWriter($namedPipe)

            #$reader.ReadLine()
            $writer.WriteLine("done")

            #$reader.Dispose()
            $writer.Dispose()

            $namedPipe.Dispose()
        }
        catch
        {
            $userInput::BlockInput($false) 
        }

}

$code = @"
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
"@

$userInput = Add-Type -MemberDefinition $code -Name UserInput -Namespace UserInput -PassThru
UnBlock
Stop-Transcript