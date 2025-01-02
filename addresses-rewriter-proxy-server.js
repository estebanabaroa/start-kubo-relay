import http from 'node:http'
import https from 'node:https'
import {parse as parseUrl} from 'url'
import util from 'util'
util.inspect.defaultOptions.depth = 4

class AddressesRewriterProxyServer {
  constructor({plebbitOptions, port, hostname, proxyTargetUrl}) {
    this.addresses = {}
    this.plebbitOptions = plebbitOptions
    this.port = port
    this.hostname = hostname || '127.0.0.1'
    this.proxyTarget = parseUrl(proxyTargetUrl)
    this.server = http.createServer((req, res) => this._proxyRequestRewrite(req, res))
  }

  listen(callback) {
    this._startUpdateAddressesLoop()
    this.server.listen(this.port, this.hostname, callback) 
  }

  _proxyRequestRewrite(req, res) {
    // get post body
    let reqBody = ''
    req.on('data', chunk => {reqBody += chunk.toString()})

    // wait for full post body
    req.on('end', () => {
      try {
        console.log(req.method, req.url, req.headers, JSON.parse(reqBody))
      }
      catch (e) {
        console.log(req.method, req.url, req.headers, reqBody)
      }

      // rewrite body with up to date addresses
      let rewrittenBody = reqBody
      if (rewrittenBody) {
        try {
          const json = JSON.parse(rewrittenBody)
          for (const provider of json.Providers) {
            const peerId = provider.Payload.ID
            if (this.addresses[peerId]) {
              provider.Payload.Addrs = this.addresses[peerId]
            }
          }
          rewrittenBody = JSON.stringify(json)
        }
        catch (e) {
          console.log('proxy body rewrite error:', e.message)
        }
      }

      // proxy the request
      const {request: httpRequest} = this.proxyTarget.protocol === 'https:' ? https : http
      const requestOptions = {
        hostname: this.proxyTarget.hostname,
        port: this.proxyTarget.port,
        path: req.url,
        method: req.method,
        headers: {
          ...req.headers,
          'Content-Length': Buffer.byteLength(rewrittenBody),
          'content-length': Buffer.byteLength(rewrittenBody),
          host: this.proxyTarget.host
        }
      }
      const proxyReq = httpRequest(requestOptions, (proxyRes) => {
        res.writeHead(proxyRes.statusCode, proxyRes.headers)
        proxyRes.pipe(res, {end: true})
      })
      proxyReq.on('error', (e) => {
        console.log('proxy error:', e.message)
        res.writeHead(500)
        res.end('Internal Server Error')
      })
      proxyReq.write(rewrittenBody)
      proxyReq.end()
    })
  }

  // get up to date listen addresses from kubo every x minutes
  _startUpdateAddressesLoop() {
    const tryUpdateAddresses = async () => {
      if (!this.plebbitOptions.ipfsHttpClientsOptions?.length) {
        throw Error('no plebbitOptions.ipfsHttpClientsOptions')
      }
      for (const ipfsHttpClientOptions of this.plebbitOptions.ipfsHttpClientsOptions) {
        const kuboApiUrl = ipfsHttpClientOptions.url || ipfsHttpClientOptions
        try {
          const idRes = await fetch(`${kuboApiUrl}/id`, {method: 'POST'}).then(res => res.json())
          const peerId = idRes.ID
          const swarmRes = await fetch(`${kuboApiUrl}/swarm/addrs/listen`, {method: 'POST'}).then(res => res.json())
          // merge id and swarm addresses to make sure no addresses are missing
          this.addresses[peerId] = [...new Set([...swarmRes.Strings, ...idRes.Addresses])]
        }
        catch (e) {
          console.log('tryUpdateAddresses error:', e.message, {kuboApiUrl})
        }
      }      
    }
    tryUpdateAddresses()
    setInterval(tryUpdateAddresses, 1000 * 60)
  }
}

// start server
const plebbitOptions = {
  ipfsHttpClientsOptions: ['http://127.0.0.1:5001/api/v0'],
  httpRoutersOptions: [
    'https://routing.lol',
    // 'https://peers.pleb.bot',
    // 'https://peers.plebpubsub.xyz',
    // 'https://peers.forumindex.com'
  ]
}
let addressesRewriterStartPort = 19575
for (const httpRoutersOptions of plebbitOptions.httpRoutersOptions) {
  const port = addressesRewriterStartPort++
  const hostname = '127.0.0.1'
  const addressesRewriterProxyServer = new AddressesRewriterProxyServer({
    plebbitOptions: plebbitOptions,
    port, 
    hostname,
    proxyTargetUrl: httpRoutersOptions.url || httpRoutersOptions,
  })
  addressesRewriterProxyServer.listen(() => {
    console.log(`addresses rewriter proxy listening on http://${addressesRewriterProxyServer.hostname}:${addressesRewriterProxyServer.port}`)
  })
}
