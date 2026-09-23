# WindowLockManager.ps1
if ($env:OS -ne 'Windows_NT') { throw 'Windows is required.' }
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

Add-Type @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public static class WL {
 public delegate bool EnumProc(IntPtr h, IntPtr p);
 public const int GWL_EXSTYLE=-20;
 public const long TRANSPARENT=0x20, LAYERED=0x80000, NOACTIVATE=0x08000000;
 public const uint ALPHA=2, NOSIZE=1, NOMOVE=2, NOZORDER=4, NOACT=0x10, FRAME=0x20, SHOW=0x40;
 public static readonly IntPtr TOP=new IntPtr(-1), NOTOP=new IntPtr(-2);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f,IntPtr p);
 [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowEnabled(IntPtr h);
 [DllImport("user32.dll")] public static extern bool EnableWindow(IntPtr h,bool e);
 [DllImport("user32.dll")] public static extern IntPtr GetShellWindow();
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);
 [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h,IntPtr a,int x,int y,int w,int z,uint f);
 [DllImport("user32.dll")] public static extern bool SetLayeredWindowAttributes(IntPtr h,uint c,byte a,uint f);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")] public static extern int GetWindowTextLengthW(IntPtr h);
 [DllImport("user32.dll",EntryPoint="GetWindowLongPtrW")] static extern IntPtr Get64(IntPtr h,int i);
 [DllImport("user32.dll",EntryPoint="SetWindowLongPtrW")] static extern IntPtr Set64(IntPtr h,int i,IntPtr v);
 [DllImport("user32.dll",EntryPoint="GetWindowLongW")] static extern int Get32(IntPtr h,int i);
 [DllImport("user32.dll",EntryPoint="SetWindowLongW")] static extern int Set32(IntPtr h,int i,int v);
 public static long Style(IntPtr h){return IntPtr.Size==8?Get64(h,GWL_EXSTYLE).ToInt64():Get32(h,GWL_EXSTYLE);}
 public static void Style(IntPtr h,long v){if(IntPtr.Size==8)Set64(h,GWL_EXSTYLE,new IntPtr(v));else Set32(h,GWL_EXSTYLE,(int)v);SetWindowPos(h,IntPtr.Zero,0,0,0,0,NOSIZE|NOMOVE|NOZORDER|NOACT|FRAME);}
 public class Item {public IntPtr H;public string T;public uint P;public override string ToString(){return T+"  [PID "+P+"]";}}
 public static List<Item> List(IntPtr exclude){var r=new List<Item>();var shell=GetShellWindow();EnumWindows((h,p)=>{if(h==shell||h==exclude||!IsWindowVisible(h))return true;int n=GetWindowTextLengthW(h);if(n<1)return true;var b=new StringBuilder(n+1);GetWindowTextW(h,b,b.Capacity);string t=b.ToString().Trim();if(t.Length<1)return true;uint pid;GetWindowThreadProcessId(h,out pid);r.Add(new Item{H=h,T=t,P=pid});return true;},IntPtr.Zero);r.Sort((a,b)=>StringComparer.CurrentCultureIgnoreCase.Compare(a.T,b.T));return r;}
}
'@

$f=New-Object Windows.Forms.Form
$f.Text='Window Lock Manager';$f.Size=New-Object Drawing.Size(760,520);$f.StartPosition='CenterScreen';$f.TopMost=$true;$f.Font=New-Object Drawing.Font('Segoe UI',12)
$l=New-Object Windows.Forms.ListBox;$l.Location=New-Object Drawing.Point(14,38);$l.Size=New-Object Drawing.Size(712,190);$f.Controls.Add($l)
$lab=New-Object Windows.Forms.Label;$lab.Text='Select a visible window:';$lab.Location=New-Object Drawing.Point(14,14);$lab.AutoSize=$true;$f.Controls.Add($lab)
function Btn($text,$x,$w){$b=New-Object Windows.Forms.Button;$b.Text=$text;$b.Location=New-Object Drawing.Point($x,240);$b.Size=New-Object Drawing.Size($w,32);$f.Controls.Add($b);$b}
$refresh=Btn 'Refresh list' 14 110;$lock=Btn 'Lock selected window' 134 175;$unlock=Btn 'Unlock window' 324 151;$unlock.Enabled=$false
$ol=New-Object Windows.Forms.Label;$ol.Text='Window opacity: 100%';$ol.Location=New-Object Drawing.Point(14,300);$ol.AutoSize=$true;$f.Controls.Add($ol)
$op=New-Object Windows.Forms.TrackBar;$op.Location=New-Object Drawing.Point(14,325);$op.Size=New-Object Drawing.Size(505,45);$op.Minimum=10;$op.Maximum=100;$op.TickFrequency=10;$op.Value=100;$f.Controls.Add($op)
$apply=New-Object Windows.Forms.Button;$apply.Text='Apply appearance';$apply.Location=New-Object Drawing.Point(535,324);$apply.Size=New-Object Drawing.Size(150,32);$f.Controls.Add($apply)
$st=New-Object Windows.Forms.Label;$st.Text='Ready. Locked windows are automatically always on top; the controller stays above them.';$st.Location=New-Object Drawing.Point(14,405);$st.Size=New-Object Drawing.Size(712,48);$st.BorderStyle='Fixed3D';$st.Padding=New-Object Windows.Forms.Padding(8);$f.Controls.Add($st)
$script:h=[IntPtr]::Zero;$script:old=0L;$script:oldEnabled=$true;$script:changed=$false;$script:locked=$false
function Status($x,[bool]$err=$false){$st.Text=$x;$st.ForeColor=if($err){[Drawing.Color]::DarkRed}else{[Drawing.Color]::DarkGreen}}
function Valid{return $script:h-ne[IntPtr]::Zero-and[WL]::IsWindow($script:h)}
function ControllerTop{$f.TopMost=$true;if($f.IsHandleCreated){[void][WL]::SetWindowPos($f.Handle,[WL]::TOP,0,0,0,0,[WL]::NOSIZE-bor[WL]::NOMOVE-bor[WL]::NOACT-bor[WL]::SHOW);$f.BringToFront()}}
function Restore{if(Valid){[void][WL]::EnableWindow($script:h,$script:oldEnabled);[WL]::Style($script:h,$script:old);[void][WL]::SetWindowPos($script:h,[WL]::NOTOP,0,0,0,0,[WL]::NOSIZE-bor[WL]::NOMOVE-bor[WL]::NOACT);[void][WL]::SetLayeredWindowAttributes($script:h,0,255,[WL]::ALPHA)};$script:h=[IntPtr]::Zero;$script:changed=$false;$script:locked=$false}
function Target{if(!$l.SelectedItem){throw 'Select a window first.'};$n=$l.SelectedItem.H;if($script:h-ne$n){if($script:changed){Restore};$script:h=$n;$script:old=[WL]::Style($n);$script:oldEnabled=[WL]::IsWindowEnabled($n)}}
function Appearance{Target;$x=[WL]::Style($script:h)-bor[WL]::LAYERED;[WL]::Style($script:h,$x);$a=[byte][Math]::Round(255*$op.Value/100);if(![WL]::SetLayeredWindowAttributes($script:h,0,$a,[WL]::ALPHA)){throw 'Opacity change failed.'};$script:changed=$true;ControllerTop;Status "Appearance applied. Opacity $($op.Value)%."}
function Refresh{$save=if($l.SelectedItem){$l.SelectedItem.H}else{[IntPtr]::Zero};$l.Items.Clear();foreach($i in [WL]::List($f.Handle)){[void]$l.Items.Add($i);if($i.H-eq$save){$l.SelectedItem=$i}};Status "Found $($l.Items.Count) windows."}
$refresh.Add_Click({Refresh});$apply.Add_Click({try{Appearance}catch{Status $_.Exception.Message $true}})
$lock.Add_Click({try{Appearance;$x=[WL]::Style($script:h)-bor[WL]::TRANSPARENT-bor[WL]::NOACTIVATE-bor[WL]::LAYERED;[WL]::Style($script:h,$x);[void][WL]::SetWindowPos($script:h,[WL]::TOP,0,0,0,0,[WL]::NOSIZE-bor[WL]::NOMOVE-bor[WL]::NOACT-bor[WL]::SHOW);[void][WL]::EnableWindow($script:h,$false);$script:locked=$true;$unlock.Enabled=$true;$lock.Enabled=$false;ControllerTop;Status 'Window locked and automatically set to always on top.'}catch{Status $_.Exception.Message $true}})
$unlock.Add_Click({if(Valid){$x=[WL]::Style($script:h)-band(-bnot[WL]::TRANSPARENT)-band(-bnot[WL]::NOACTIVATE);[WL]::Style($script:h,$x);[void][WL]::EnableWindow($script:h,$true)};$script:locked=$false;$unlock.Enabled=$false;$lock.Enabled=$true;ControllerTop;Status 'Window unlocked.'})
$op.Add_ValueChanged({$ol.Text="Window opacity: $($op.Value)%";if(Valid){try{Appearance}catch{Status $_.Exception.Message $true}}})
$t=New-Object Windows.Forms.Timer;$t.Interval=300;$t.Add_Tick({if($script:locked){ControllerTop};if($script:h-ne[IntPtr]::Zero-and-not[WL]::IsWindow($script:h)){$script:h=[IntPtr]::Zero;$script:changed=$false;$script:locked=$false;$unlock.Enabled=$false;$lock.Enabled=$true;Status 'Target window closed.' $true}});$t.Start()
$f.Add_Shown({ControllerTop});$f.Add_FormClosing({$t.Stop();if($script:changed){Restore}});Refresh;[void]$f.ShowDialog()
