using Confluent.Kafka;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MimeKit;
using MailKit.Net.Smtp;
using System.Text.Json;

namespace AlertDispatcherService
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly IConsumer<Ignore, string> _consumer;
        private readonly HashSet<string> _sentAlerts = new(); // avoid duplicate alerts

        private readonly string smtpServer = Environment.GetEnvironmentVariable("SMTP_SERVER") ?? "your-smtp-server";
        private readonly int smtpPort = int.Parse(Environment.GetEnvironmentVariable("SMTP_PORT") ?? "587");
        private readonly string smtpUser = Environment.GetEnvironmentVariable("SMTP_USER") ?? "your-smtp-user";
        private readonly string smtpPass = Environment.GetEnvironmentVariable("SMTP_PASS") ?? "your-smtp-password";
        private readonly string[] alertRecipients = (Environment.GetEnvironmentVariable("ALERT_RECIPIENTS") ?? "recipient@example.com")
                                                        .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        public Worker(ILogger<Worker> logger)
        {
            _logger = logger;

            var config = new ConsumerConfig
            {
                BootstrapServers = "kafka:9092",
                GroupId = "alert-dispatcher-group",
                AutoOffsetReset = AutoOffsetReset.Earliest
            };

            _consumer = new ConsumerBuilder<Ignore, string>(config).Build();
            _consumer.Subscribe("quake-alerts");
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Alert Dispatcher Service started...");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    var result = _consumer.Consume(stoppingToken);

                    if (result?.Message?.Value != null)
                    {
                        var root = JsonDocument.Parse(result.Message.Value).RootElement;

                        if (root.TryGetProperty("properties", out var properties) &&
                            root.TryGetProperty("geometry", out var geometry))
                        {
                            var place = properties.GetProperty("place").GetString();
                            var magnitude = properties.GetProperty("mag").GetDouble();
                            var quakeTimeMs = properties.GetProperty("time").GetInt64();
                            var quakeTime = DateTimeOffset.FromUnixTimeMilliseconds(quakeTimeMs).UtcDateTime;

                            var coordinates = geometry.GetProperty("coordinates");
                            var longitude = coordinates[0].GetDouble();
                            var latitude = coordinates[1].GetDouble();

                            var quakeId = root.GetProperty("id").GetString(); // Use ID to deduplicate

                            if (magnitude >= 4.0)
                            {
                                if (quakeId != null && !_sentAlerts.Contains(quakeId))
                                {
                                    _sentAlerts.Add(quakeId);
                                    _logger.LogWarning($"⚠️ Significant quake: {place} - Magnitude {magnitude}");
                                    await SendEmailAlertAsync(place, magnitude, latitude, longitude, quakeTime);
                                }
                                else
                                {
                                    _logger.LogInformation($"Duplicate alert ignored for quake ID: {quakeId}");
                                }
                            }
                            else
                            {
                                _logger.LogInformation($"Minor quake ignored: {place} - Magnitude {magnitude}");
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
                catch (Exception ex)
                {
                    _logger.LogError($"Unhandled error: {ex.Message}");
                }
            }
        }

        private async Task SendEmailAlertAsync(string place, double magnitude, double lat, double lon, DateTime quakeTime)
        {
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress("Earthquake Monitor", smtpUser));
            foreach (var recipient in alertRecipients)
            {
                message.To.Add(new MailboxAddress(recipient, recipient));
            }

            message.Subject = $"⚡ Earthquake Alert: {place} (M {magnitude})";

            string googleMapsLink = $"https://www.google.com/maps/search/?api=1&query={lat},{lon}";
            string quakeTimeFormatted = quakeTime.ToString("f");

            message.Body = new TextPart("html")
            {
                Text = $@"
                    <h2>🌎 Earthquake Alert!</h2>
                    <p><strong>Location:</strong> {place}</p>
                    <p><strong>Magnitude:</strong> {magnitude}</p>
                    <p><strong>Time (UTC):</strong> {quakeTimeFormatted}</p>
                    <p><a href='{googleMapsLink}'>📍 View on Google Maps</a></p>
                    <hr>
                    <p style='font-size:smaller;color:gray;'>Stay safe. This is an automated notification.</p>"
            };

            try
            {
                using var client = new SmtpClient();
                await client.ConnectAsync(smtpServer, smtpPort, MailKit.Security.SecureSocketOptions.StartTls);
                await client.AuthenticateAsync(smtpUser, smtpPass);
                await client.SendAsync(message);
                await client.DisconnectAsync(true);

                _logger.LogInformation("🚀 Alert email sent successfully!");
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ Failed to send email alert: {ex.Message}");
            }
        }

        public override void Dispose()
        {
            _consumer.Close();
            _consumer.Dispose();
            base.Dispose();
        }
    }
}
