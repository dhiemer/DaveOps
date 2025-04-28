using Confluent.Kafka;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MimeKit;
using MailKit.Net.Smtp;
using System.Text.Json;

namespace AlertService
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly IConsumer<Ignore, string> _consumer;

        // Email settings
        private readonly string smtpServer = Environment.GetEnvironmentVariable("SMTP_SERVER") ?? "your-smtp-server";
        private readonly int smtpPort = int.Parse(Environment.GetEnvironmentVariable("SMTP_PORT") ?? "587");
        private readonly string smtpUser = Environment.GetEnvironmentVariable("SMTP_USER") ?? "your-smtp-user";
        private readonly string smtpPass = Environment.GetEnvironmentVariable("SMTP_PASS") ?? "your-smtp-password";
        private readonly string[] alertRecipients = (Environment.GetEnvironmentVariable("ALERT_RECIPIENTS") ?? "recipient@example.com")
                                                        .Split(',', StringSplitOptions.RemoveEmptyEntries);

        public Worker(ILogger<Worker> logger)
        {
            _logger = logger;

            var config = new ConsumerConfig
            {
                BootstrapServers = "kafka:9092",
                GroupId = "alert-svc-group",
                AutoOffsetReset = AutoOffsetReset.Earliest
            };

            _consumer = new ConsumerBuilder<Ignore, string>(config).Build();
            _consumer.Subscribe("earthquakes");
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Alert Service started...");

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
                            var place = properties.GetProperty("place").GetString();
                            var mag = properties.GetProperty("mag").GetDouble();

                            var geometry = quake.RootElement.GetProperty("geometry");
                            var longitude = geometry.GetProperty("coordinates")[0].GetDouble();
                            var latitude = geometry.GetProperty("coordinates")[1].GetDouble();

                            if (mag >= 3.0)
                            {
                                _logger.LogWarning($"⚠️ Significant quake: {place} - Magnitude {mag}");
                                await SendFancyEmailAlertAsync(place ?? "Unknown location", mag, latitude, longitude);
                            }
                            else
                            {
                                _logger.LogInformation($"Minor quake ignored: {place} - Magnitude {mag}");
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
            }
        }

        private async Task SendFancyEmailAlertAsync(string place, double magnitude, double latitude, double longitude)
        {
            var googleMapsUrl = $"https://www.google.com/maps/search/?api=1&query={latitude},{longitude}";

            var message = new MimeMessage();
            message.From.Add(new MailboxAddress("Earthquake Monitor", smtpUser));

            foreach (var recipient in alertRecipients)
            {
                message.To.Add(MailboxAddress.Parse(recipient.Trim()));
            }

            message.Subject = $"⚡ Earthquake Alert: {place}";

            var bodyBuilder = new BodyBuilder
            {
                HtmlBody = $@"
                    <html>
                    <body style='font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px;'>
                        <div style='max-width: 600px; margin: auto; background-color: #fff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);'>
                            <div style='background-color: #d9534f; color: white; padding: 20px; text-align: center;'>
                                <h1 style='margin: 0;'>🌋 Earthquake Alert!</h1>
                            </div>
                            <div style='padding: 20px;'>
                                <table style='width: 100%; font-size: 16px;'>
                                    <tr>
                                        <td style='font-weight: bold;'>Location:</td>
                                        <td>{place}</td>
                                    </tr>
                                    <tr>
                                        <td style='font-weight: bold;'>Magnitude:</td>
                                        <td>{magnitude}</td>
                                    </tr>
                                    <tr>
                                        <td style='font-weight: bold;'>Map:</td>
                                        <td><a href='{googleMapsUrl}' style='color: #337ab7;'>View on Google Maps</a></td>
                                    </tr>
                                </table>
                                <p style='margin-top: 20px;'>Stay safe and alert! 🚨</p>
                            </div>
                        </div>
                    </body>
                    </html>
                ",
                TextBody = $"Significant earthquake detected!\n\nLocation: {place}\nMagnitude: {magnitude}\nMap: {googleMapsUrl}\n\nStay safe!"
            };

            message.Body = bodyBuilder.ToMessageBody();

            try
            {
                using var client = new SmtpClient();
                await client.ConnectAsync(smtpServer, smtpPort, MailKit.Security.SecureSocketOptions.StartTls);
                await client.AuthenticateAsync(smtpUser, smtpPass);
                await client.SendAsync(message);
                await client.DisconnectAsync(true);

                _logger.LogInformation($"✅ Alert email sent to {string.Join(", ", alertRecipients)}");
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
