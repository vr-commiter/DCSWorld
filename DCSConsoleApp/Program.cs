using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using Microsoft.Win32;
using MyTrueGear; // 确保这个命名空间是正确的，并且包含了TrueGearMod类

class Program
{
    private static TrueGearMod _TrueGear = null;
    private static string _SteamExe;
    private const string STEAM_OPENURL = "steam://rungameid/223750";

    public static string SteamExePath()
    {
        return (string)Registry.GetValue(@"HKEY_CURRENT_USER\SOFTWARE\Valve\Steam", "SteamExe", null);
    }

    static void Main(string[] args)
    {
        //当有两个程序运行的时候，关闭前一个程序，保留当前程序
        string currentProcessName = Process.GetCurrentProcess().ProcessName;
        Process[] processes = Process.GetProcessesByName(currentProcessName);
        if (processes.Length > 1)
        {
            if (processes[0].UserProcessorTime.TotalMilliseconds > processes[1].UserProcessorTime.TotalMilliseconds)
            {
                processes[0].Kill();
            }
            else
            {
                processes[1].Kill();
            }
        }



        int port = 12138;
        TcpListener listener = null;
        _TrueGear = new TrueGearMod();

        try
        {
            // 创建一个TcpListener实例，绑定到指定的端口
            listener = new TcpListener(IPAddress.Any, port);
            listener.Start();
            Console.WriteLine($"TCP Server is listening on port {port}...");

            Thread.Sleep(500);
            _SteamExe = SteamExePath();

            if (_SteamExe != null) Process.Start(_SteamExe, STEAM_OPENURL);

            while (true)
            {
                // 接受客户端连接
                TcpClient client = listener.AcceptTcpClient();
                Console.WriteLine("Client connected.");

                NetworkStream stream = client.GetStream();

                byte[] buffer = new byte[1024];
                int bytesRead;

                // 循环读取数据直到客户端断开连接
                while ((bytesRead = stream.Read(buffer, 0, buffer.Length)) != 0)
                {
                    // 将字节转换为字符串
                    string receivedData = Encoding.UTF8.GetString(buffer, 0, bytesRead);
                    _TrueGear.Play(receivedData); // 假设TrueGearMod类有一个Play方法接受字符串参数
                    Console.WriteLine(receivedData);
                }

                // 关闭客户端连接
                client.Close();
            }
        }
        catch (Exception e)
        {
            Console.WriteLine(e.ToString());
        }
        //finally
        //{
        //    // 停止监听并关闭服务器
        //    listener?.Stop();
        //}
    }
}