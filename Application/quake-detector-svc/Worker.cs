using System.Text.Json;
using Confluent.Kafka;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace QuakeDetectorService
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly IConsumer<Ignore, string> _consumer;
        private readonly IProducer<Null, string> _producer;

        public Worker(ILogger<Worker> logger)
        {
            _logger = logger;

            var consumerConfig = new ConsumerConfig
            {
                BootstrapServers = "kafka:9092",
                GroupId = "quake-detector-svc-group",
                AutoOffsetReset = AutoOffsetReset.Earliest
            };

            var producerConfig = new ProducerConfig
            {
                BootstrapServers = "kafka:9092"
            };

            _consumer = new ConsumerBuilder<Ignore, string>(consumerConfig).Build();
            _consumer.Subscribe("earthquakes");

            _producer = new ProducerBuilder<Null, string>(producerConfig).Build();
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Quake Detector Service started...");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    var result = _consumer.Consume(stoppingToken);

                    if (result?.Message?.Value != null)
                    {
                        var quake = JsonDocument.Parse(result.Message.Value);

                        if (quake.RootElement.TryGetProperty("properties", out var properties))
                        {
                            var magnitude = properties.GetProperty("mag").GetDouble();
                            var place = properties.GetProperty("place").GetString();
                            var id = quake.RootElement.GetProperty("id").GetString();

                            if (magnitude >= 0.50)
                            {
                                _logger.LogWarning($"⚠️ Detected significant quake: {place} - Magnitude {magnitude}");

                                var quakeJson = quake.RootElement.GetRawText(); // send entire quake event
                                await _producer.ProduceAsync("quake-alerts", new Message<Null, string> { Value = quakeJson }, stoppingToken);

                                _logger.LogInformation($"📤 Sent alert to 'quake-alerts' topic: {id}");
                            }
                            else
                            {
                                _logger.LogInformation($"Ignoring minor quake: {place} - Magnitude {magnitude}");
                            }
                        }
                    }
                }
                catch (ConsumeException ex)
                {
                    _logger.LogError($"Kafka consume error: {ex.Error.Reason}");
                }
                catch (JsonException ex)
                {
                    _logger.LogError($"JSON parse error: {ex.Message}");
                }
                catch (ProduceException<Null, string> ex)
                {
                    _logger.LogError($"Kafka produce error: {ex.Error.Reason}");
                }
            }
        }

        public override void Dispose()
        {
            _consumer.Close();
            _consumer.Dispose();
            _producer.Flush();
            _producer.Dispose();
            base.Dispose();
        }
    }
}
