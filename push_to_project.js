/**
 * Placeholder action that you can wire to Schematics/Projects.
 * For now, it just returns OK (and echoes any JSON body).
 */
exports.main = async (params) => {
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ok: true, received: params || {} })
  };
};
