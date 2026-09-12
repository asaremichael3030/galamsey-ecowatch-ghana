const pool = require('../config/database');

async function addEducationTable() {
    try {
        // Create education_articles table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS education_articles (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description TEXT NOT NULL,
                content TEXT NOT NULL,
                category VARCHAR(50) DEFAULT 'General',
                image_url TEXT,
                published BOOLEAN DEFAULT false,
                created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('✅ education_articles table created successfully');

        // Create indexes
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_education_category ON education_articles(category);
            CREATE INDEX IF NOT EXISTS idx_education_published ON education_articles(published);
            CREATE INDEX IF NOT EXISTS idx_education_created_at ON education_articles(created_at DESC);
        `);
        console.log('✅ indexes created successfully');

        // Insert sample education content - using parameterized queries
        const articles = [
            {
                title: 'What is Galamsey?',
                description: 'Understanding illegal mining in Ghana',
                content: 'Galamsey is the local term for illegal small-scale gold mining in Ghana. It involves the extraction of gold from the earth using rudimentary methods, often causing significant environmental damage including water pollution, deforestation, and land degradation. The practice has become a major environmental concern in Ghana, affecting water bodies and agricultural lands across the country.',
                category: 'Mining'
            },
            {
                title: 'Effects of Illegal Mining on Rivers',
                description: 'How galamsey destroys our water bodies',
                content: 'Illegal mining activities have devastating effects on Ghana rivers. The use of heavy machinery and chemicals like mercury and cyanide pollutes water sources, killing aquatic life and making water unsafe for human consumption. The sedimentation caused by mining activities also affects river flow and can lead to flooding in surrounding communities.',
                category: 'Environment'
            },
            {
                title: 'How You Can Help Protect the Environment',
                description: 'Simple steps to make a difference',
                content: 'Everyone can contribute to protecting Ghana environment. Report illegal mining activities through the EcoWatch platform, educate others about the dangers of galamsey, support sustainable mining practices, and participate in community clean-up exercises. Together, we can make a difference in preserving our natural resources for future generations.',
                category: 'Action'
            }
        ];

        for (const article of articles) {
            await pool.query(`
                INSERT INTO education_articles (title, description, content, category, published, created_at)
                VALUES ($1, $2, $3, $4, true, NOW())
                ON CONFLICT (id) DO NOTHING
            `, [article.title, article.description, article.content, article.category]);
        }
        console.log('✅ sample education content inserted');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating education table:', error.message);
        process.exit(1);
    }
}

addEducationTable();