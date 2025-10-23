
/**
 * push_to_project: stages provided HTML to COS as /staged/index.html using HMAC.
 * This provides a safe artifact that a future Project re-deploy can consume.
 * Same params as push_to_cos.
 */
const crypto = require('crypto');
const https = require('https');

function sha256Hex(buf) { return crypto.createHash('sha256').update(buf).digest('hex'); }
function hmac(key, data) { return crypto.createHmac('sha256', key).update(data).digest(); }
function hmacHex(key, data) { return crypto.createHmac('sha256', key).update(data).digest('hex'); }

function sigV4Headers({ host, region, service, method, path, query, headers, payload, accessKeyId, secretAccessKey }) {
  const amzDate = new Date().toISOString().replace(/[:-]|\.\d{3}/g, '');
  const dateStamp = amzDate.slice(0,8);
  const canonicalUri = path;
  const canonicalQuerystring = query || '';
  const hdrs = Object.assign({}, headers, {
    'host': host,
    'x-amz-date': amzDate,
    'x-amz-content-sha256': sha256Hex(payload)
  });
  const signedHeaders = Object.keys(hdrs).map(k=>k.toLowerCase()).sort().join(';');
  const canonicalHeaders = Object.keys(hdrs).map(k=>k.toLowerCase()).sort().map(k=>k + ':' + String(hdrs[k]).trim() + '\n').join('');
  const canonicalRequest = [method, canonicalUri, canonicalQuerystring, canonicalHeaders, signedHeaders, sha256Hex(payload)].join('\n');
  const algorithm = 'AWS4-HMAC-SHA256';
  const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
  const stringToSign = [algorithm, amzDate, credentialScope, sha256Hex(canonicalRequest)].join('\n');
  const kDate = hmac('AWS4' + secretAccessKey, dateStamp);
  const kRegion = hmac(kDate, region);
  const kService = hmac(kRegion, service);
  const kSigning = hmac(kService, 'aws4_request');
  const signature = hmacHex(kSigning, stringToSign);
  const authorization = `${algorithm} Credential=${accessKeyId}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;
  hdrs['Authorization'] = authorization;
  return hdrs;
}

exports.main = async (params) => {
  const { bucket_name, region, cos_endpoint, access_key_id, secret_access_key } = params;
  const body = typeof params.__ow_body === 'string' ? Buffer.from(params.__ow_body, 'base64').toString() : '';
  const json = body ? JSON.parse(body) : {};
  const html = json.html || '<!doctype html><html><body><h1>Empty staged vibe</h1></body></html>';

  const service = 's3';
  const host = cos_endpoint;
  const method = 'PUT';
  const path = `/${bucket_name}/staged/index.html`;
  const payload = Buffer.from(html, 'utf8');
  const headers = { 'content-type': 'text/html' };

  const signed = sigV4Headers({
    host, region, service, method, path, headers, payload,
    accessKeyId: access_key_id, secretAccessKey: secret_access_key
  });

  const options = { host, method, path, headers: signed };

  const res = await new Promise((resolve, reject) => {
    const req = https.request(options, (r) => {
      let data = '';
      r.on('data', (c)=> data += c.toString());
      r.on('end', ()=> resolve({ statusCode: r.statusCode, data }));
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });

  if (res.statusCode >= 200 && res.statusCode < 300) {
    return {
      statusCode: 200,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ status: 'ok', action: 'project', object: 'staged/index.html' })
    };
  } else {
    return {
      statusCode: 502,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ status: 'error', details: res.data || String(res.statusCode) })
    };
  }
};
