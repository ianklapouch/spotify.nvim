import express from 'express';
import axios from 'axios';
import open from 'open';

if (process.argv.length < 5) {
  console.error(JSON.stringify({
    error: "Missing arguments",
    required: ["clientId", "clientSecret", "redirectUri"]
  }));
  process.exit(1);
}

const [clientId, clientSecret, redirectUri] = process.argv.slice(2);

const app = express();
const PORT = 8888;

app.get('/callback', async (req, res) => {
  try {
    const response = await axios.post('https://accounts.spotify.com/api/token', null, {
      params: {
        grant_type: 'authorization_code',
        code: req.query.code,
        redirect_uri: redirectUri,
        client_id: clientId,
        client_secret: clientSecret,
      },
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });

    res.send('<script>window.close();</script><p>Autenticação concluída! Esta janela pode ser fechada.</p>');
    console.log(JSON.stringify({
      access_token: response.data.access_token,
      expires_in: response.data.expires_in,
      token_type: response.data.token_type
    }));
    setTimeout(() => process.exit(0), 1000);
  } catch (error) {
    console.error(JSON.stringify({
      error: "Authentication failed",
      details: error.response?.data || error.message
    }));
    process.exit(1);
  }
});

const server = app.listen(PORT, () => {
  const authUrl = `https://accounts.spotify.com/authorize?response_type=code&client_id=${clientId}&scope=user-modify-playback-state&redirect_uri=${encodeURIComponent(redirectUri)}`;
  open(authUrl);
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(JSON.stringify({
      error: "Port already in use",
      solution: `Close other applications using port ${PORT} or change the port in the script`
    }));
  } else {
    console.error(JSON.stringify({
      error: "Server error",
      details: err.message
    }));
  }
  process.exit(1);
});