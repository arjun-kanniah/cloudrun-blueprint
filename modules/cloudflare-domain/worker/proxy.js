// Forwards a custom domain to a Cloud Run service. Cloudflare streams response bodies through
// as they arrive, so streamed responses (server-sent events) keep working.
//
// Bindings: ORIGIN_HOST (the run.app host), CLIENT_IP_HEADER and SECRET_HEADER (header names),
// PROXY_SECRET (shared with the service, which trusts the IP header only when it matches).
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    url.protocol = "https:";
    url.hostname = env.ORIGIN_HOST;
    url.port = "";

    const headers = new Headers(request.headers);
    headers.delete("host");
    headers.set(env.CLIENT_IP_HEADER, request.headers.get("cf-connecting-ip") ?? "");
    headers.set(env.SECRET_HEADER, env.PROXY_SECRET);

    return fetch(url, {
      method: request.method,
      headers,
      body: request.body,
      redirect: "manual",
    });
  },
};
