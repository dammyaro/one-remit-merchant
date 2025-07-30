# IBAN.com API Integration Guide

## 🚀 Quick Setup

### 1. No API Key Required! 
✅ **IBAN.com API works without authentication** for basic validation
✅ **Ready to use immediately** - no signup required
✅ **Perfect for development and testing**

### 2. Free Tier Limits
- ✅ **Rate limited but generous** for development use
- ✅ **No registration required**
- ✅ **Instant activation**
- ✅ **Professional-grade validation**

### 3. For Higher Volume (Optional)
If you need more requests:
1. Visit: https://www.iban.com/iban-checker-api
2. Sign up for a premium plan
3. Get API key for higher rate limits

## 🔧 What Changed

### Improvements Over OpenIBAN:
1. **More Reliable**: IBAN.com is a well-established service
2. **No API Key Needed**: Works immediately without registration
3. **Better Validation**: Professional-grade bank data verification
4. **Proper IBAN Generation**: Uses ISO 13616 standard algorithm
5. **Smart Fallback System**: Local IBAN calculation if API fails
6. **Rate Limit Handling**: User-friendly messages for API limits

### New Features:
- ✅ **Standard IBAN calculation** (ISO 13616 compliant)
- ✅ **Real-time validation** with bank data
- ✅ **Automatic fallback** to local generation
- ✅ **Better bank name resolution**

## 🧪 Testing

Try these test values:
- **Sort Code**: `20-00-00`
- **Account Number**: `55779911`
- **Expected IBAN**: `GB29NWBK20000055779911`

## 🔒 Security Note

For production:
- Store API key in environment variables
- Never commit API keys to version control
- Consider rate limiting and caching