# SPDX-FileCopyrightText: 2021 Rafael Gieschke
# SPDX-License-Identifier: GPL-3.0-or-later

################################################################################

# SPDX-FileCopyrightText: Based on <https://stackoverflow.com/a/19348221>: Copyright 2021 Alex Jasmin
# SPDX-License-Identifier: CC-BY-SA-4.0

Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
  // f(), g(), ... are unused COM method slots. Define these if you care
  int f(); int g(); int h(); int i();
  int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
  int j();
  int GetMasterVolumeLevelScalar(out float pfLevel);
  int k(); int l(); int m(); int n();
  int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
  int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
  int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
  int f(); // Unused
  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }

public class Audio {
  static IAudioEndpointVolume Vol() {
    var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
    IMMDevice dev = null;
    Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
    IAudioEndpointVolume epv = null;
    var epvid = typeof(IAudioEndpointVolume).GUID;
    Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
    return epv;
  }
  public static float Volume {
    get {float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v;}
    set {Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty));}
  }
  public static bool Mute {
    get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
    set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
  }
}
'@

################################################################################

# SPDX-FileCopyrightText: Based on <https://github.com/hmemcpy/ChromeRegJump/blob/3c388afcc064b71bfe3dc71e286cc48512378c29/src/host/nativehost.ps1>: Copyright 2015 Igal Tabachnik
# SPDX-License-Identifier: MIT

$reader = New-Object System.IO.BinaryReader([System.Console]::OpenStandardInput())
$len = $reader.ReadInt32()
$obj = [System.Text.Encoding]::UTF8.GetString($reader.ReadBytes($len)) | ConvertFrom-Json

if ($obj.brightness) {
  # https://docs.microsoft.com/en-us/windows/win32/wmicoreprov/wmisetbrightness-method-in-class-wmimonitorbrightnessmethods
  (Get-WmiObject -Namespace root\wmi -Class WmiMonitorBrightnessMethods).wmisetbrightness(0, $obj.brightness)
}
if ($obj.volume) {
  [Audio]::Volume = $obj.volume
}
# https://docs.microsoft.com/en-us/windows/win32/wmicoreprov/wmimonitorbrightness
$obj = @{brightness = (Get-Ciminstance -Namespace root/WMI -ClassName WmiMonitorBrightness).CurrentBrightness; volume = [Audio]::Volume }

$msg = $obj | ConvertTo-Json
$writer = New-Object System.IO.BinaryWriter([System.Console]::OpenStandardOutput())
$writer.Write([int]$msg.Length)
$writer.Write([System.Text.Encoding]::UTF8.GetBytes($msg))
