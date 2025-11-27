using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using AWS.Logger;
using AWS.Logger.AspNetCore;

namespace BPCalculator
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var host = CreateHostBuilder(args).Build();
            
            var logger = host.Services.GetService(typeof(ILogger<Program>)) as ILogger<Program>;
            logger?.LogInformation("Blood Pressure Calculator application starting up");
            
            host.Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureLogging((context, logging) =>
                {
                    // Configure AWS CloudWatch Logging
                    var logConfig = new AWSLoggerConfig("bp-calculator-logs")
                    {
                        Region = Environment.GetEnvironmentVariable("AWS_REGION") ?? "eu-west-1",
                        // Use environment variables for credentials in production
                        // Credentials will be picked up from:
                        // 1. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
                        // 2. EC2 instance profile (when deployed to AWS)
                        // 3. ~/.aws/credentials (local development)
                    };
                    
                    // Add CloudWatch logging (will be disabled if no AWS credentials available)
                    logging.AddAWSProvider(logConfig);
                    
                    // Keep console logging for local development
                    logging.AddConsole();
                    logging.AddDebug();
                    
                    // Set minimum log level
                    logging.SetMinimumLevel(LogLevel.Information);
                })
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}
//
