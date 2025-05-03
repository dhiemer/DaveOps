import requests, time, json
def fetch():
    url = 'https://api.pushshift.io/reddit/search/comment/?subreddit=wallstreetbets&size=10'
    while True:
        try:
            res = requests.get(url)
            data = res.json()
            print(json.dumps(data, indent=2))
        except Exception as e:
            print("Error fetching:", e)
        time.sleep(60)

if __name__ == "__main__":
    fetch()