// Vercel serverless function to proxy IBAN API requests
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
    const { sortCode, accountNumber } = req.body;

    // Validate input
    if (!sortCode || !accountNumber) {
      res.status(400).json({ 
        error: 'Missing required parameters',
        message: 'Both sortCode and accountNumber are required' 
      });
      return;
    }

    // Clean sort code (remove dashes)
    const cleanSortCode = sortCode.replace(/-/g, '');

    // Validate sort code format (6 digits)
    if (!/^\d{6}$/.test(cleanSortCode)) {
      res.status(400).json({ 
        error: 'Invalid sort code format',
        message: 'Sort code must be 6 digits (XX-XX-XX or XXXXXX)' 
      });
      return;
    }

    // Validate account number (6-8 digits typically)
    if (!/^\d{6,8}$/.test(accountNumber)) {
      res.status(400).json({ 
        error: 'Invalid account number format',
        message: 'Account number must be 6-8 digits' 
      });
      return;
    }

    console.log('🚀 Vercel Function: Processing IBAN request');
    console.log('📊 Sort Code:', cleanSortCode);
    console.log('💳 Account Number:', accountNumber);

    // Call iban.com API from server-side (no CORS issues)
    const apiUrl = `https://api.iban.com/clients/api/calc-api.php?api_key=3f8c0989988cead164d141f61c221286&format=json&country=GB&bankcode=${cleanSortCode}&account=${accountNumber}`;
    
    console.log('🌐 Calling iban.com API...');
    
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Vercel-Function/1.0'
      }
    });

    console.log('📡 API Response Status:', response.status);

    if (!response.ok) {
      throw new Error(`iban.com API returned status: ${response.status}`);
    }

    const data = await response.json();
    
    console.log('✅ API Response received');
    console.log('🆔 IBAN:', data.iban || 'Not generated');
    console.log('🏛️ Bank:', data.bank || 'Not provided');

    // Validate response
    if (!data.iban) {
      res.status(422).json({ 
        error: 'IBAN generation failed',
        message: 'Invalid sort code or account number',
        details: data
      });
      return;
    }

    // Return successful response
    res.status(200).json({
      success: true,
      iban: data.iban,
      bank: data.bank || 'UK Bank',
      bic: data.bic || 'N/A',
      branch: data.branch || 'N/A',
      sortCode: data.sort_code || cleanSortCode,
      accountNumber: data.account || accountNumber,
      address: data.address || 'N/A',
      city: data.city || 'N/A',
      zip: data.zip || 'N/A',
      phone: data.phone || 'N/A',
      country: data.country || 'GB'
    });

  } catch (error) {
    console.error('❌ Vercel Function Error:', error);
    
    res.status(500).json({ 
      error: 'Internal server error',
      message: 'Failed to process IBAN request',
      details: error.message
    });
  }
}