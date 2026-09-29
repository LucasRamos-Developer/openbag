#!/usr/bin/env python3
"""
Arquivos de SEO do app web publicado. Rode depois do `flutter build web`, no deploy.

- robots.txt: libera as páginas públicas e bloqueia os painéis, o checkout e os pedidos.
- sitemap.xml: a vitrine e a página de cada loja ativa (buscada na API pública).
- index.html: troca os endereços relativos do canônico e do Open Graph pelos absolutos do site
  (os robôs de prévia do WhatsApp e do Facebook exigem URL completa).

Uso:
  python3 tools/seo/build_seo.py --site-url https://openbag.exemplo.com.br
  python3 tools/seo/build_seo.py --site-url https://... --api https://api.exemplo.com.br/api --build frontend/build/web

Requer: pip install requests
"""
import argparse
import datetime
from pathlib import Path
from xml.sax.saxutils import escape

import requests

ROOT = Path(__file__).resolve().parents[2]

# Áreas com login: não fazem sentido no buscador
PRIVATE_PATHS = ["/restaurante", "/entregador", "/associacao", "/admin", "/checkout", "/cart", "/pedidos",
                 "/login", "/registrar", "/ui-showcase"]


def active_restaurants(api: str) -> list[dict]:
    restaurants, page = [], 0
    while True:
        response = requests.get(f"{api}/public/restaurants", params={"page": page, "size": 100}, timeout=15)
        response.raise_for_status()
        data = response.json()
        restaurants += data["content"]
        if data.get("last", True):
            return restaurants
        page += 1


def robots_txt(site: str) -> str:
    lines = ["User-agent: *", "Allow: /"] + [f"Disallow: {p}" for p in PRIVATE_PATHS]
    return "\n".join(lines + ["", f"Sitemap: {site}/sitemap.xml", ""])


def sitemap_xml(site: str, restaurants: list[dict]) -> str:
    today = datetime.date.today().isoformat()
    urls = [(f"{site}/home", "daily", "1.0")] + [(f"{site}/r/{r['slug']}", "daily", "0.8") for r in restaurants]
    body = "".join(
        f"  <url><loc>{escape(loc)}</loc><lastmod>{today}</lastmod>"
        f"<changefreq>{freq}</changefreq><priority>{priority}</priority></url>\n"
        for loc, freq, priority in urls
    )
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + body + "</urlset>\n")


def absolute_index(html: str, site: str) -> str:
    """Endereços relativos do web/index.html (canônico, og:url e og:image) viram absolutos"""
    replacements = {
        '<link rel="canonical" href="/">': f'<link rel="canonical" href="{site}/">',
        '<meta property="og:url" content="/">': f'<meta property="og:url" content="{site}/">',
        '<meta property="og:image" content="og-image.jpg">': f'<meta property="og:image" content="{site}/og-image.jpg">',
    }
    for relative, absolute in replacements.items():
        html = html.replace(relative, absolute)
    return html


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--site-url", required=True, help="endereço público do app (sem / no fim)")
    parser.add_argument("--api", default="http://localhost:8080/api")
    parser.add_argument("--build", type=Path, default=ROOT / "frontend" / "build" / "web")
    args = parser.parse_args()
    site = args.site_url.rstrip("/")

    restaurants = active_restaurants(args.api)
    (args.build / "robots.txt").write_text(robots_txt(site), encoding="utf-8")
    (args.build / "sitemap.xml").write_text(sitemap_xml(site, restaurants), encoding="utf-8")
    index = args.build / "index.html"
    index.write_text(absolute_index(index.read_text(encoding="utf-8"), site), encoding="utf-8")
    print(f"robots.txt, sitemap.xml ({len(restaurants) + 1} páginas) e index.html prontos em {args.build}")


if __name__ == "__main__":
    main()
