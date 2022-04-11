// See https://aka.ms/new-console-template for more information

using Azure.Messaging.ServiceBus;
using Newtonsoft.Json;

Console.WriteLine("Hello, World!");

var client =
    new ServiceBusClient(Environment.GetEnvironmentVariable("ServiceBusConnection"));

// The sender is responsible for publishing messages to the queue.
var sender = client.CreateSender("process-queue");
var rnd = Random.Shared;

var sent = 0;
while (sent < 5000)
{
    var messages = Enumerable.Range(0, 100).Select(x =>
            new ServiceBusMessage(JsonConvert.SerializeObject(new InitialMessage { Id = Guid.NewGuid(), Value = rnd.Next(0, 100) })))
        .ToArray();

    await sender.SendMessagesAsync(messages);
    sent += messages.Length;
    Console.WriteLine($"Sent {sent} messages");
    await Task.Delay(TimeSpan.FromMilliseconds(250));
}