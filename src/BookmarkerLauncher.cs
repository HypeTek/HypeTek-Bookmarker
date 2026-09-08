using System;
using System.IO;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;

[assembly: AssemblyTitle("HypeTek Bookmarker")]
[assembly: AssemblyProduct("HypeTek Bookmarker")]
[assembly: AssemblyCompany("HypeTek")]
[assembly: AssemblyDescription("Native launcher host for HypeTek Bookmarker")]
[assembly: AssemblyCopyright("Copyright © 2026 HypeTek")]
[assembly: AssemblyVersion("3.7.2.0")]
[assembly: AssemblyFileVersion("3.7.2.0")]

namespace HypeTek.Bookmarker.Launcher
{
    internal static class Program
    {
        [STAThread]
        private static int Main()
        {
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            string scriptPath = Path.Combine(baseDir, "ServerLauncher.ps1");
            string errorPath = Path.Combine(baseDir, "Error.txt");

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
                InitialSessionState state = InitialSessionState.CreateDefault();
                using (Runspace runspace = RunspaceFactory.CreateRunspace(state))
                {
                    runspace.ApartmentState = ApartmentState.STA;
                    runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;
                    runspace.Open();

                    using (PowerShell ps = PowerShell.Create())
                    {
                        ps.Runspace = runspace;
                        string escaped = scriptPath.Replace("'", "''");
                        ps.AddScript("& '" + escaped + "'");
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
                    "HypeTek Bookmarker could not be started. Details were written to Error.txt.",
                    "HypeTek Bookmarker",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return 1;
            }
        }
    }
}
