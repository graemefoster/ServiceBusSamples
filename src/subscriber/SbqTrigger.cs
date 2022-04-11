using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.ServiceBus;
using Microsoft.Azure.ServiceBus.Core;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Graeme
{
    public static class SbqTrigger
    {
        [FunctionName("SbqTrigger")]
        [return: ServiceBus("intermediate-queue", Connection = "sample_SERVICEBUS")]
        public static async Task<string> Run1(
            [ServiceBusTrigger("process-queue", Connection = "sample_SERVICEBUS")]
            Message[] messages,
            MessageReceiver messageReceiver,
            ILogger log)
        {
            log.LogInformation("Processing {Count} messages", messages.Length);
            log.LogInformation("Processed {Count} messages", messages.Length);
            var batch = messages.Select(x =>
                JsonConvert.DeserializeObject<InitialMessage>(Encoding.UTF8.GetString(x.Body)));
            var newMessage = JsonConvert.SerializeObject(new IntermediateMessage
                { Id = Guid.NewGuid(), Count = messages.Length, InputMessages = batch.ToArray() });
            await messageReceiver.CompleteAsync(messages.Select(x => x.SystemProperties.LockToken));
            return newMessage;
        }

        [FunctionName("SbqTrigger2")]
        public static async Task Run2(
            [ServiceBusTrigger("intermediate-queue", Connection = "sample_SERVICEBUS")]
            Message message,
            ILogger log)
        {
            var msg = JsonConvert.DeserializeObject<IntermediateMessage>(Encoding.UTF8.GetString(message.Body));
            log.LogInformation("Processing intermediate message. Count {Count}", msg.Count);
            await Task.Delay(5000);
            log.LogInformation("Processed intermediate message");
        }
    }

    public class IntermediateMessage
    {
        public Guid Id { get; set; }
        public int Count { get; set; }
        public InitialMessage[] InputMessages { get; set; }
    }

    public class InitialMessage
    {
        public Guid Id { get; set; }
        public int Value { get; set; }
    }