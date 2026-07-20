[CmdletBinding()]
param(
    [string]$GamePath,
    [ValidateRange(640, 1599)][int]$Width = 1280,
    [ValidateRange(480, 1200)][int]$Height = 960
)

$ErrorActionPreference = 'Stop'
$launcherRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $GamePath) {
    $GamePath = Join-Path $launcherRoot 'ds9dw.exe'
}
$game = Get-Item -LiteralPath $GamePath

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class DominionWarsDisplayMode
{
    private const int ENUM_CURRENT_SETTINGS = -1;
    private const int CDS_FULLSCREEN = 0x00000004;
    private const int DISP_CHANGE_SUCCESSFUL = 0;
    private const int DM_PELSWIDTH = 0x00080000;
    private const int DM_PELSHEIGHT = 0x00100000;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DEVMODE
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion; public short dmDriverVersion; public short dmSize;
        public short dmDriverExtra; public int dmFields; public int dmPositionX;
        public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput;
        public short dmColor; public short dmDuplex; public short dmYResolution;
        public short dmTTOption; public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth;
        public int dmPelsHeight; public int dmDisplayFlags; public int dmDisplayFrequency;
        public int dmICMMethod; public int dmICMIntent; public int dmMediaType;
        public int dmDitherType; public int dmReserved1; public int dmReserved2;
        public int dmPanningWidth; public int dmPanningHeight;
    }

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE mode);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int ChangeDisplaySettings(ref DEVMODE mode, int flags);

    public static DEVMODE GetCurrent()
    {
        var mode = new DEVMODE();
        mode.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
        if (!EnumDisplaySettings(null, ENUM_CURRENT_SETTINGS, ref mode))
            throw new InvalidOperationException("Could not read the primary display mode.");
        return mode;
    }

    public static void SetSize(DEVMODE original, int width, int height)
    {
        var mode = original;
        mode.dmPelsWidth = width; mode.dmPelsHeight = height;
        mode.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT;
        int result = ChangeDisplaySettings(ref mode, CDS_FULLSCREEN);
        if (result != DISP_CHANGE_SUCCESSFUL)
            throw new InvalidOperationException("The display driver rejected " + width + "x" + height + " (code " + result + ").");
    }

    public static void Restore(DEVMODE original)
    {
        int result = ChangeDisplaySettings(ref original, CDS_FULLSCREEN);
        if (result != DISP_CHANGE_SUCCESSFUL)
            throw new InvalidOperationException("Could not restore the original display mode (code " + result + ").");
    }
}
'@

$original = [DominionWarsDisplayMode]::GetCurrent()
try {
    [DominionWarsDisplayMode]::SetSize($original, $Width, $Height)
    $process = Start-Process -FilePath $game.FullName -WorkingDirectory $game.DirectoryName -PassThru
    $process.WaitForExit()
}
finally {
    [DominionWarsDisplayMode]::Restore($original)
}
