// Vercel serverless function to proxy Router Fusion GraphQL requests
export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed. Use POST.' });
    return;
  }

  try {
    const { query, variables } = req.body;

    // Validate input
    if (!query) {
      res.status(400).json({ 
        error: 'Missing required parameters',
        message: 'GraphQL query is required' 
      });
      return;
    }

    console.log('🚀 Router Fusion API: Processing GraphQL request');
    console.log('📊 Query:', query.substring(0, 100) + '...');
    console.log('📋 Variables:', JSON.stringify(variables, null, 2));

    // Get API key from environment
    const apiKey = process.env.ROUTER_FUSION_API_KEY;
    
    if (!apiKey) {
      console.error('❌ Router Fusion API key not found in environment variables');
      res.status(500).json({ 
        error: 'Configuration error',
        message: 'Router Fusion API key not configured' 
      });
      return;
    }

    const graphqlEndpoint = 'https://sandbox.external.routefusion.com/graphql';
    
    const requestBody = {
      query: query,
      variables: variables || {}
    };
    
    console.log('🌐 Calling Router Fusion GraphQL API...');
    
    const response = await fetch(graphqlEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
        'User-Agent': 'Vercel-Function/1.0'
      },
      body: JSON.stringify(requestBody)
    });

    console.log('📡 API Response Status:', response.status);

    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ Router Fusion API Error:', errorText);
      throw new Error(`Router Fusion API returned status: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    
    console.log('✅ Router Fusion API Response received');
    console.log('📄 Response:', JSON.stringify(data, null, 2));

    // Check for GraphQL errors
    if (data.errors && data.errors.length > 0) {
      console.error('❌ GraphQL Errors:', data.errors);
      res.status(400).json({ 
        error: 'GraphQL errors',
        message: 'Router Fusion GraphQL request failed',
        details: data.errors
      });
      return;
    }

    // Return successful response
    res.status(200).json({
      success: true,
      data: data.data,
      errors: data.errors || null
    });

  } catch (error) {
    console.error('❌ Router Fusion Function Error:', error);
    
    res.status(500).json({ 
      error: 'Internal server error',
      message: 'Failed to process Router Fusion request',
      details: error.message
    });
  }
}