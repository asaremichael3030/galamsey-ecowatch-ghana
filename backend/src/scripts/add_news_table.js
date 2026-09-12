const pool = require('../config/database');

async function addNewsTable() {
    try {
        // Create news table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS news (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                content TEXT NOT NULL,
                category VARCHAR(50) DEFAULT 'General',
                image_url TEXT,
                published BOOLEAN DEFAULT false,
                author_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('✅ news table created successfully');

        // Create indexes
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_news_category ON news(category);
            CREATE INDEX IF NOT EXISTS idx_news_published ON news(published);
            CREATE INDEX IF NOT EXISTS idx_news_created_at ON news(created_at DESC);
        `);
        console.log('✅ indexes created successfully');

        // Insert sample news using parameterized queries
        const newsItems = [
            {
                title: 'Government Launches New Environmental Protection Initiative',
                content: 'The government has announced a new initiative to combat illegal mining and protect Ghana water bodies. The initiative includes increased patrols, community engagement programs, and new legislation to deter illegal mining activities.',
                category: 'Government'
            },
            {
                title: 'Community Leaders Rally Against Illegal Mining',
                content: 'Community leaders from the Ashanti Region have come together to raise awareness about the dangers of illegal mining. They are calling for stricter enforcement of environmental laws and more support for sustainable mining practices.',
                category: 'Community'
            },
            {
                title: 'New Technology to Detect Illegal Mining Activities',
                content: 'Environmental monitoring agencies are deploying new satellite technology to detect illegal mining activities in real-time. This technology will help authorities respond faster and more effectively to environmental violations.',
                category: 'Technology'
            }
        ];

        for (const item of newsItems) {
            await pool.query(`
                INSERT INTO news (title, content, category, published, author_id, created_at)
                VALUES ($1, $2, $3, true, 1, NOW())
                ON CONFLICT (id) DO NOTHING
            `, [item.title, item.content, item.category]);
        }
        console.log('✅ sample news inserted');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating news table:', error.message);
        process.exit(1);
    }
}

addNewsTable();