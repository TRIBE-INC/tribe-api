const API_KEY = process.env.TRIBE_API_KEY || 'your_api_key_here';
const API_BASE = process.env.TRIBE_API_BASE || 'https://tribecode.ai/api';

async function searchKnowledgeBase(query = 'oauth') {
  try {
    const url = new URL(`${API_BASE}/knowledge-base/articles`);
    url.searchParams.append('search', query);
    url.searchParams.append('limit', '5');

    const response = await fetch(url.toString(), {
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    console.log(`📚 Knowledge Base Search Results for: "${query}"\n`);
    console.log(`Total results: ${data.total}`);
    console.log(`Showing: ${data.articles.length} articles\n`);

    data.articles.forEach((article, index) => {
      console.log(`${index + 1}. ${article.title}`);
      console.log(`   Topic: ${article.topic}`);
      console.log(`   Tags: ${article.tags?.join(', ') || 'none'}`);
      console.log(`   Updated: ${new Date(article.updated_at).toLocaleDateString()}\n`);
    });

    return data;
  } catch (error) {
    console.error('❌ Error searching knowledge base:', error.message);
    throw error;
  }
}

if (require.main === module) {
  const query = process.argv[2] || 'oauth';
  searchKnowledgeBase(query)
    .then(() => console.log('✅ Done'))
    .catch(err => process.exit(1));
}

module.exports = { searchKnowledgeBase };
