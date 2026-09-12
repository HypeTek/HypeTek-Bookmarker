using System;
using System.IO;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("HypeTek Bookmarker")]
[assembly: AssemblyProduct("HypeTek Bookmarker")]
[assembly: AssemblyCompany("HypeTek")]
[assembly: AssemblyDescription("Native launcher host for HypeTek Bookmarker")]
[assembly: AssemblyCopyright("Copyright © 2026 HypeTek")]
[assembly: AssemblyVersion("3.7.2.3")]
[assembly: AssemblyFileVersion("3.7.2.3")]

namespace HypeTek.Bookmarker.Launcher
{
    internal static class Program
    {
        private static readonly IntPtr DpiAwarenessContextPerMonitorAwareV2 = new IntPtr(-4);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SetProcessDpiAwarenessContext(IntPtr dpiContext);

        private static void TryEnablePerMonitorV2Dpi()
        {
            try
            {
                SetProcessDpiAwarenessContext(DpiAwarenessContextPerMonitorAwareV2);
            }
            catch (EntryPointNotFoundException)
            {
            }
        }

        private static string GetStartupLogPath(string baseDir)
        {
            try
            {
                string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                if (!String.IsNullOrWhiteSpace(localAppData))
                {
                    string logDir = Path.Combine(localAppData, "HypeTek", "Bookmarker", "logs");
                    Directory.CreateDirectory(logDir);
                    return Path.Combine(logDir, "startup.log");
                }
            }
            catch { }

            return Path.Combine(baseDir, "Error.txt");
        }

        [STAThread]
        private static int Main()
        {
            TryEnablePerMonitorV2Dpi();

            string baseDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            string scriptPath = Path.Combine(baseDir, "ServerLauncher.ps1");
            string errorPath = GetStartupLogPath(baseDir);

            if (!File.Exists(scriptPath))
            {
                MessageBox.Show(
                    "ServerLauncher.ps1 was not found next to HypeTek-Bookmarker.exe.",
                    "HypeTek Bookmarker",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return 2;
            }

            try
            {
                string scriptSource = File.ReadAllText(scriptPath, Encoding.UTF8);
                string escapedBaseDir = baseDir.Replace("'", "''");

                const string baseDirBootstrap = "$script:BaseDir = $PSScriptRoot";
                string hostedBootstrap = "$script:BaseDir = '" + escapedBaseDir + "'";
                if (scriptSource.Contains(baseDirBootstrap))
                    scriptSource = scriptSource.Replace(baseDirBootstrap, hostedBootstrap);

                // Run #13: the live WPF window now uses the dedicated refined small icon.
                // Windows' taskbar resolves the running window icon before falling back to
                // the executable/package icon, so this targets the last remaining taskbar-only issue.
                const string mainWindowAnchor = "$window=[System.Windows.Markup.XamlReader]::Load($reader);$script:Window=$window";
                string mainWindowWithIcon = mainWindowAnchor + Environment.NewLine +
                    "    $appIconPath=Join-Path $script:BundledAssetsDir 'bookmarker-icon-small.png'" + Environment.NewLine +
                    "    if(Test-Path -LiteralPath $appIconPath){" + Environment.NewLine +
                    "        try{" + Environment.NewLine +
                    "            $appIcon=New-Object System.Windows.Media.Imaging.BitmapImage" + Environment.NewLine +
                    "            $appIcon.BeginInit()" + Environment.NewLine +
                    "            $appIcon.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad" + Environment.NewLine +
                    "            $appIcon.DecodePixelWidth=64" + Environment.NewLine +
                    "            $appIcon.UriSource=New-Object System.Uri -ArgumentList $appIconPath" + Environment.NewLine +
                    "            $appIcon.EndInit()" + Environment.NewLine +
                    "            $appIcon.Freeze()" + Environment.NewLine +
                    "            $window.Icon=$appIcon" + Environment.NewLine +
                    "        }catch{}" + Environment.NewLine +
                    "    }";
                if (scriptSource.Contains(mainWindowAnchor))
                    scriptSource = scriptSource.Replace(mainWindowAnchor, mainWindowWithIcon);

                const string dialogAnchor = "    if ($script:Window) { $w.Owner=$script:Window }\r\n    return $w";
                const string dialogAnchorLf = "    if ($script:Window) { $w.Owner=$script:Window }\n    return $w";
                string dialogWithIcon =
                    "    if ($script:Window) { $w.Owner=$script:Window }" + Environment.NewLine +
                    "    $appIconPath=Join-Path $script:BundledAssetsDir 'bookmarker-icon-small.png'" + Environment.NewLine +
                    "    if(Test-Path -LiteralPath $appIconPath){" + Environment.NewLine +
                    "        try{" + Environment.NewLine +
                    "            $appIcon=New-Object System.Windows.Media.Imaging.BitmapImage" + Environment.NewLine +
                    "            $appIcon.BeginInit()" + Environment.NewLine +
                    "            $appIcon.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad" + Environment.NewLine +
                    "            $appIcon.DecodePixelWidth=32" + Environment.NewLine +
                    "            $appIcon.UriSource=New-Object System.Uri -ArgumentList $appIconPath" + Environment.NewLine +
                    "            $appIcon.EndInit()" + Environment.NewLine +
                    "            $appIcon.Freeze()" + Environment.NewLine +
                    "            $w.Icon=$appIcon" + Environment.NewLine +
                    "        }catch{}" + Environment.NewLine +
                    "    }" + Environment.NewLine +
                    "    return $w";
                if (scriptSource.Contains(dialogAnchor))
                    scriptSource = scriptSource.Replace(dialogAnchor, dialogWithIcon);
                else if (scriptSource.Contains(dialogAnchorLf))
                    scriptSource = scriptSource.Replace(dialogAnchorLf, dialogWithIcon);

                InitialSessionState state = InitialSessionState.CreateDefault();
                using (Runspace runspace = RunspaceFactory.CreateRunspace(state))
                {
                    runspace.ApartmentState = ApartmentState.STA;
                    runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;
                    runspace.Open();

                    using (PowerShell ps = PowerShell.Create())
                    {
                        ps.Runspace = runspace;
                        ps.AddScript(scriptSource);
                        ps.Invoke();

                        if (ps.HadErrors)
                        {
                            StringBuilder sb = new StringBuilder();
                            sb.AppendLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
                            foreach (ErrorRecord error in ps.Streams.Error)
                                sb.AppendLine(error.ToString());
                            File.WriteAllText(errorPath, sb.ToString(), Encoding.UTF8);
                            return 1;
                        }
                    }
                }
                return 0;
            }
            catch (Exception ex)
            {
                try
                {
                    File.WriteAllText(errorPath,
                        DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + Environment.NewLine + ex,
                        Encoding.UTF8);
                }
                catch { }

                MessageBox.Show(
                    "HypeTek Bookmarker could not be started. Details were written to the per-user startup log.",
                    "HypeTek Bookmarker",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return 1;
            }
        }
    }
}
