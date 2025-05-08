import logging
import os
import re
from datetime import datetime, timedelta
from typing import Dict, List, Set
from uuid import uuid4

import boto3
import httpx
import spacy

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

NEWS_API_KEY = os.getenv("NEWS_API_KEY")
DYNAMODB_HOST = os.getenv("DYNAMODB_HOST", None)
TABLE_NAME = os.getenv("DYNAMODB_TABLE", "gapwatch_articles")
region = os.getenv("AWS_REGION", "us-east-1")

dynamodb = boto3.resource("dynamodb", region_name=region, endpoint_url=DYNAMODB_HOST)  # For local testing
table = dynamodb.Table(TABLE_NAME)

FOOD_SECURITY = (
    'hunger OR famine OR "food insecurity" OR malnutrition OR "food crisis" OR "food supply" OR "food access"'
)
HUM_ASSISTANCE = (
    '"humanitarian assistance" OR "foreign aid" OR "development aid" OR "disaster relief" OR "emergency response"'
)
CROP_FAILURE = '"crop failure" OR "agriculture crisis" OR "crop yield decline"'

TOPICS_MAP = {
    "food_security": FOOD_SECURITY,
    "humanitarian_assistance": HUM_ASSISTANCE,
    "crop_failure": CROP_FAILURE,
}

try:
    nlp = spacy.load("en_core_web_sm")
except OSError as e:
    raise RuntimeError("spaCy model 'en_core_web_sm' not found. Make sure it's installed.") from e


def clean_text(text: str) -> str:
    if text:
        text = text.replace("\r\n", " ").replace("\n", " ").replace("\r", " ")
        text = re.sub(r"\[\+\d+ chars\]", "", text)
        text = re.sub(r"\s+", " ", text).strip()
    return text


def get_date_range(days_ago: int = 1) -> (str, str):
    date = datetime.utcnow().date() - timedelta(days=days_ago)
    return date.isoformat(), date.isoformat()


def extract_entities(text: str) -> Dict[str, Set[str]]:
    """Extract locations and organizations from text using spaCy."""
    doc = nlp(text)

    # Extract entities by type
    locations = list({ent.text for ent in doc.ents if ent.label_ in ["GPE", "LOC"]})
    organizations = list({ent.text for ent in doc.ents if ent.label_ in ["ORG"]})
    persons = list({ent.text for ent in doc.ents if ent.label_ in ["PERSON"]})
    money = list({ent.text for ent in doc.ents if ent.label_ in ["MONEY"]})
    events = list({ent.text for ent in doc.ents if ent.label_ in ["EVENT"]})
    objects = list({ent.text for ent in doc.ents if ent.label_ in ["PRODUCT"]})

    return {
        "locations": locations,
        "organizations": organizations,
        "persons": persons,
        "money": money,
        "events": events,
        "objects": objects,
    }


def fetch_news(topic: str) -> List[Dict]:
    logger.info(f"Fetching articles for topic: {topic}")

    from_date, to_date = get_date_range()

    params = {
        "q": TOPICS_MAP[topic],
        "from": from_date,
        "to": to_date,
        "sortBy": "relevancy",
        "pageSize": 100,
        "apiKey": NEWS_API_KEY,
    }
    url = "https://newsapi.org/v2/everything"

    try:
        response = httpx.get(url, params=params)
        response.raise_for_status()
        articles = response.json().get("articles", [])

        for article in articles:
            article["topic"] = topic

        logger.info(f"Fetched {len(articles)} articles for topic '{topic}'")
        return articles

    except Exception as e:
        logger.info(f"fetch_news failed with {e}")
        return []


def deduplicate_articles(articles: List[Dict]) -> List[Dict]:
    seen_urls = set()
    unique_articles = []

    for article in articles:
        url = article.get("url")
        if url and url not in seen_urls:
            seen_urls.add(url)
            unique_articles.append(article)

    return unique_articles


def get_all_articles() -> List[Dict]:
    all_articles = []
    for topic in TOPICS_MAP.keys():
        articles = fetch_news(topic)
        all_articles += articles

    all_articles = deduplicate_articles(all_articles)
    return all_articles


def store_articles() -> None:
    articles = get_all_articles()
    logger.info(f"Found {len(articles)} articles")
    clean_articles = []
    stored_count = 0
    for article in articles:
        try:
            item = {
                "id": str(uuid4()),
                "source": clean_text(article["source"]["name"]),
                "title": clean_text(article["title"]),
                "description": clean_text(article["description"]),
                "url": article["url"],
                "urlToImage": article["urlToImage"],
                "topic": article["topic"],
                "published_at": article["publishedAt"],
                "content": clean_text(article["content"]),
                "inserted_at": datetime.utcnow().isoformat(),
            }
            full_text = f"{item['title']} {item['description']} {item['content']}"
            entities = extract_entities(full_text)
            if bool([entity for entity in entities.values() if entity != []]):
                item.update(entities)
                clean_articles.append(item)
                table.put_item(Item=item)
                stored_count += 1
        except Exception as e:
            logger.info(f"Error storing article: {e}")

    logger.info(f"Stored {stored_count} articles in DynamoDB")


def lambda_handler(event=None, context=None) -> None:
    store_articles()