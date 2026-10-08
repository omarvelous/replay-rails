// Cloudflare Pages middleware — proxies API, ActionCable, and
// ActiveStorage requests to the Render backend. Everything else
// is served as static assets from the Pages build.

const PROXY_PREFIXES = ["/api/", "/cable", "/rails/active_storage/", "/ahoy/"]
const PREVIEW_API_PREFIX = "/preview-api/"

function shouldProxy(pathname: string): boolean {
  return PROXY_PREFIXES.some((prefix) => pathname.startsWith(prefix))
}

function getBackendOrigin(hostname: string): string {
  if (hostname.endsWith(".replaytv.dev")) {
    return "https://replay-staging-web.onrender.com"
  }
  return "https://replay-web-8yl8.onrender.com"
}

function getAppHost(hostname: string): string {
  // play.replaytv.co → app.replaytv.co
  // play.replaytv.dev → app.replaytv.dev
  return hostname.replace(/^play\./, "app.")
}

export const onRequest: PagesFunction = async (context) => {
  const url = new URL(context.request.url)

  // Preview API — proxy to app subdomain with path rewrite
  if (url.pathname.startsWith(PREVIEW_API_PREFIX)) {
    const backendOrigin = getBackendOrigin(url.hostname)
    const rewrittenPath = url.pathname.replace(PREVIEW_API_PREFIX, "/")
    const backendUrl = new URL(rewrittenPath + url.search, backendOrigin)

    const headers = new Headers(context.request.headers)
    const appHost = getAppHost(url.hostname)
    headers.set("Host", appHost)
    headers.set("X-Forwarded-Host", appHost)
    headers.set("X-Forwarded-Proto", "https")

    return fetch(backendUrl.toString(), {
      method: context.request.method,
      headers,
      body: context.request.body,
      redirect: "manual",
    })
  }

  if (!shouldProxy(url.pathname)) {
    return context.next()
  }

  const backendOrigin = getBackendOrigin(url.hostname)
  const backendUrl = new URL(url.pathname + url.search, backendOrigin)

  const headers = new Headers(context.request.headers)
  headers.set("Host", url.hostname)
  headers.set("X-Forwarded-Host", url.hostname)
  headers.set("X-Forwarded-Proto", "https")

  // WebSocket upgrade for ActionCable
  if (context.request.headers.get("Upgrade") === "websocket") {
    return fetch(backendUrl.toString(), {
      method: context.request.method,
      headers,
    })
  }

  return fetch(backendUrl.toString(), {
    method: context.request.method,
    headers,
    body: context.request.body,
    redirect: "manual",
  })
}
