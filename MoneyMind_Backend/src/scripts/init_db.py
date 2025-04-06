import psycopg2
import os
import sys
import logging
from dotenv import load_dotenv

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

load_dotenv()

# Database configuration
DB_NAME = os.getenv("DB_NAME", "financial_assistant")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")

def create_database():
    """Create the database if it doesn't exist"""
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        dbname="postgres"
    )
    conn.autocommit = True
    cursor = conn.cursor()
    
    # Check if database exists
    cursor.execute(f"SELECT 1 FROM pg_catalog.pg_database WHERE datname = '{DB_NAME}'")
    exists = cursor.fetchone()
    
    if not exists:
        logger.info(f"Creating database {DB_NAME}...")
        cursor.execute(f"CREATE DATABASE {DB_NAME}")
        logger.info(f"Database {DB_NAME} created successfully")
    else:
        logger.info(f"Database {DB_NAME} already exists")
    
    cursor.close()
    conn.close()

def create_community_tables():
    """Create community-related tables"""
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        dbname=DB_NAME
    )
    conn.autocommit = True
    cursor = conn.cursor()
    
    # Create tables
    logger.info("Creating community tables...")
    
    # Users table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) NOT NULL,
        handle VARCHAR(50) NOT NULL UNIQUE,
        bio VARCHAR(255),
        profile_image VARCHAR(255)
    )
    """)
    
    # Create authentication fields (commented out for now)
    """
    cursor.execute('''
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS email VARCHAR(100) UNIQUE,
    ADD COLUMN IF NOT EXISTS password VARCHAR(255),
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP
    ''')
    """
    
    # Posts table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS posts (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        has_image BOOLEAN DEFAULT FALSE,
        image_url VARCHAR(255),
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP
    )
    """)
    
    # Comments table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS comments (
        id SERIAL PRIMARY KEY,
        post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        text TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
    )
    """)
    
    # Replies table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS replies (
        id SERIAL PRIMARY KEY,
        comment_id INTEGER REFERENCES comments(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        text TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
    )
    """)
    
    # Post likes table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS post_likes (
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
        PRIMARY KEY (user_id, post_id)
    )
    """)
    
    # Comment likes table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS comment_likes (
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        comment_id INTEGER REFERENCES comments(id) ON DELETE CASCADE,
        PRIMARY KEY (user_id, comment_id)
    )
    """)
    
    # Bookmarks table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS bookmarks (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(user_id, post_id)
    )
    """)
    
    # Follows table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS follows (
        id SERIAL PRIMARY KEY,
        follower_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        followed_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(follower_id, followed_id)
    )
    """)
    
    logger.info("Community tables created successfully")
    
    # Create indexes for better performance
    logger.info("Creating indexes...")
    
    # Indexes for posts
    cursor.execute("""
    CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
    CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at);
    """)
    
    # Indexes for comments
    cursor.execute("""
    CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
    CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
    """)
    
    # Indexes for replies
    cursor.execute("""
    CREATE INDEX IF NOT EXISTS idx_replies_comment_id ON replies(comment_id);
    CREATE INDEX IF NOT EXISTS idx_replies_user_id ON replies(user_id);
    """)
    
    # Indexes for follows
    cursor.execute("""
    CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
    CREATE INDEX IF NOT EXISTS idx_follows_followed ON follows(followed_id);
    """)
    
    logger.info("Indexes created successfully")
    
    # Insert sample data for testing
    logger.info("Inserting sample data...")
    
    # Sample users
    sample_users = [
        ("John Smith", "@john_smith", "Financial advisor with 10+ years experience", "assets/profile.png"),
        ("Sarah Johnson", "@sarah_investments", "Stock market analyst and ETF specialist", "assets/profile.png"),
        ("Michael Chen", "@mchen_crypto", "Crypto investor and blockchain enthusiast", "assets/profile.png"),
        ("Emma Wilson", "@emma_finance", "Personal finance coach and retirement planning expert", "assets/profile.png"),
        ("Your name", "@Your_name", "Financial enthusiast and app user", "assets/profile.png")
    ]
    
    for username, handle, bio, profile_image in sample_users:
        cursor.execute("""
        INSERT INTO users (username, handle, bio, profile_image)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (handle) DO NOTHING
        """, (username, handle, bio, profile_image))
    
    # Sample posts
    sample_posts = [
        (1, "Just read an interesting article about ETF strategies for long-term wealth building. Remember that time in the market beats timing the market!", False, None),
        (2, "Market update: S&P 500 up 1.2% today. Tech stocks leading the rally with strong Q2 earnings reports.", False, None),
        (3, "Bitcoin just crossed $60,000! Is this the beginning of another bull run or should we expect a correction? What's your take?", False, None),
        (5, "Just started my investment journey with mutual funds. Excited to see how it grows over time!", False, None)
    ]
    
    for user_id, content, has_image, image_url in sample_posts:
        cursor.execute("""
        INSERT INTO posts (user_id, content, has_image, image_url, created_at)
        VALUES (%s, %s, %s, %s, NOW() - INTERVAL '1 day' * FLOOR(RANDOM() * 10))
        """, (user_id, content, has_image, image_url))
    
    # Sample comments
    cursor.execute("""
    SELECT id FROM posts ORDER BY RANDOM() LIMIT 2
    """)
    post_ids = cursor.fetchall()
    
    sample_comments = [
        (post_ids[0][0], 4, "Great insights! I've been following a similar strategy and it's working well."),
        (post_ids[0][0], 3, "Do you have any recommended resources for beginners?"),
        (post_ids[1][0], 2, "Interesting perspective. I think we should be cautious in this market."),
        (post_ids[1][0], 5, "Thanks for sharing this information!")
    ]
    
    for post_id, user_id, text in sample_comments:
        cursor.execute("""
        INSERT INTO comments (post_id, user_id, text, created_at)
        VALUES (%s, %s, %s, NOW() - INTERVAL '1 hour' * FLOOR(RANDOM() * 24))
        """, (post_id, user_id, text))
    
    # Sample follows
    sample_follows = [
        (5, 1),  
        (5, 2),  
        (1, 5),
        (3, 5),  
        (4, 5),  
    ]
    
    for follower_id, followed_id in sample_follows:
        cursor.execute("""
        INSERT INTO follows (follower_id, followed_id)
        VALUES (%s, %s)
        ON CONFLICT (follower_id, followed_id) DO NOTHING
        """, (follower_id, followed_id))
    
    # Sample likes
    cursor.execute("""
    SELECT id FROM posts ORDER BY RANDOM() LIMIT 3
    """)
    random_post_ids = cursor.fetchall()
    
    for post_id in random_post_ids:
        cursor.execute("""
        INSERT INTO post_likes (user_id, post_id)
        VALUES (5, %s)
        ON CONFLICT (user_id, post_id) DO NOTHING
        """, (post_id[0],))
    
    cursor.execute("""
    SELECT id FROM comments ORDER BY RANDOM() LIMIT 2
    """)
    random_comment_ids = cursor.fetchall()
    
    for comment_id in random_comment_ids:
        cursor.execute("""
        INSERT INTO comment_likes (user_id, comment_id)
        VALUES (5, %s)
        ON CONFLICT (user_id, comment_id) DO NOTHING
        """, (comment_id[0],))
    
    # Sample bookmarks
    cursor.execute("""
    SELECT id FROM posts ORDER BY RANDOM() LIMIT 1
    """)
    bookmark_post_id = cursor.fetchone()[0]
    
    cursor.execute("""
    INSERT INTO bookmarks (user_id, post_id)
    VALUES (5, %s)
    ON CONFLICT (user_id, post_id) DO NOTHING
    """, (bookmark_post_id,))
    
    logger.info("Sample data inserted successfully")
    
    cursor.close()
    conn.close()

def main():
    try:

        create_database()
        
        create_community_tables()
        
        logger.info("Database setup completed successfully")
    except Exception as e:
        logger.error(f"Error setting up database: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()