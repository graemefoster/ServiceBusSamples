using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace WebJobMsiTest
{
    public class Job
    {
        // This function will get triggered/executed when a new message is written 
        // on an Azure Queue called queue.
        public static void ProcessQueueMessage(
            [ServiceBusTrigger("process-queue", Connection = "tnm4f6f6rfa5qsbn_SERVICEBUS")]
            string message,
            ILogger log
        )
        {
            log.LogInformation("Using Managed Identity.", message);
            log.LogInformation("Message: {Message}", message);
            Console.WriteLine($"Message: {message}");
        }
    }
}