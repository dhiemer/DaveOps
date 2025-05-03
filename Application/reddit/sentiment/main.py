from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import sys, json

analyzer = SentimentIntensityAnalyzer()
for line in sys.stdin:
    text = json.loads(line).get("body", "")
    score = analyzer.polarity_scores(text)
    print(json.dumps({"text": text, "sentiment": score}))