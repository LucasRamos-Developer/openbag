#!/usr/bin/env python3
"""
Capturas de tela do OpenBag para layout/ e docs/assets/screens/.

Pré-requisitos (ver README.md desta pasta):
  - backend em http://localhost:8080 com OPENBAG_DEMO_ENABLED=true (conta demo@openbag.local)
  - build web em frontend/build/web (flutter build web --release)
  - pip install playwright pillow requests && playwright install chromium

Uso:
  python3 tools/screenshots/take_screenshots.py                 # todas as capturas
  python3 tools/screenshots/take_screenshots.py --only admin    # só as que contêm "admin" no nome
  python3 tools/screenshots/take_screenshots.py --store burger-da-vila --owner dono@x.com:senha
  python3 tools/screenshots/take_screenshots.py --list          # lista as capturas

--store escolhe a loja das telas do cliente e --owner a conta das telas do restaurante
(padrão: a Cantina Demo e a conta demo). Com --serve, o script serve frontend/build/web
na porta 3000 se nada estiver rodando nela.
"""
import argparse
import asyncio
import functools
import http.server
import json
import os
import socket
import threading
from pathlib import Path

import requests
from PIL import Image
from playwright.async_api import async_playwright

ROOT = Path(__file__).resolve().parents[2]
LAYOUT = ROOT / "layout"
DOCS_SCREENS = ROOT / "docs" / "assets" / "screens"
WEB_BUILD = ROOT / "frontend" / "build" / "web"

DEMO = ("demo@openbag.local", "demo1234")

DESKTOP = (1440, 900)
LAPTOP = (1280, 800)
PHONE = (390, 844)

# Cada captura: arquivo em layout/, caminho no app, tamanho da tela e o que fazer antes do print.
#   login: "demo" (conta com todos os perfis) ou "owner" (dono das telas do restaurante; --owner)
#   cart: coloca 2 unidades do primeiro item da loja no carrinho
#   clicks: textos (acessibilidade do Flutter) clicados em ordem; "aria:..." só no rótulo (tooltip);
#           "xy:x,y" clica na posição; "css:seletor" no primeiro elemento que casa
#   scroll: quantas "roladinhas" de 400px dar no meio da tela
#   docs: nome do JPG copiado para docs/assets/screens/
SHOTS = [
    dict(name="loja-e-vitrine/08-vitrine-grade", path="/home", size=DESKTOP, login="demo", docs="cliente-restaurantes"),
    dict(name="loja-e-vitrine/15-vitrine-ordenacao", path="/home", size=DESKTOP, login="demo",
         clicks=["Recomendados"]),
    dict(name="loja-e-vitrine/16-vitrine-celular", path="/home", size=PHONE, login="demo"),
    dict(name="loja-e-vitrine/09-restaurante-barra-vidro", path="/r/{store}", size=DESKTOP, login="demo", scroll=3),
    dict(name="loja-e-vitrine/11-rodape-carrinho", path="/r/{store}", size=DESKTOP, login="demo", cart=True, scroll=80),
    dict(name="loja-e-vitrine/12-rodape-celular", path="/r/{store}", size=PHONE, login="demo", cart=True, scroll=120),
    dict(name="loja-e-vitrine/06-status-no-menu", path="/restaurante/pedidos", size=DESKTOP, login="owner",
         clicks=["Menu", "Recebendo pedidos"]),
    dict(name="loja-e-vitrine/10-pedidos-titulo", path="/restaurante/pedidos", size=DESKTOP, login="owner"),
    # Rotas precisa de pedidos em preparo na loja da conta usada
    dict(name="caixa-e-rotas/01-rotas-montando", path="/restaurante/rotas", size=DESKTOP, login="demo",
         docs="restaurante-rotas"),
    dict(name="loja-e-vitrine/14-cardapio-acordeao", path="/r/{store}", size=DESKTOP, login="demo",
         clicks=['css:flt-semantics[aria-expanded="true"]']),
    dict(name="loja-e-vitrine/13-sobre-a-loja-mapa", path="/r/{store}", size=DESKTOP, login="demo", clicks=["Sobre"]),
    dict(name="menu/01-desktop-recolhido", path="/restaurante/pedidos", size=LAPTOP, login="owner"),
    dict(name="menu/02-desktop-expandido", path="/restaurante/pedidos", size=LAPTOP, login="owner", clicks=["Menu"],
         docs="restaurante-pedidos"),
    dict(name="menu/05-vitrine-meus-paineis", path="/home", size=LAPTOP, login="demo", clicks=["xy:1224,32"]),
    dict(name="menu/06-mobile", path="/restaurante/pedidos", size=PHONE, login="owner"),
    dict(name="menu/07-mobile-gaveta", path="/restaurante/pedidos", size=PHONE, login="owner", clicks=["Menu"]),
    dict(name="cooperativa/01-lojas-parceiras", path="/associacao/lojas", size=DESKTOP, login="demo",
         docs="cooperativa-lojas-parceiras"),
    dict(name="cooperativa/02-propor-tabela", path="/associacao/lojas", size=DESKTOP, login="demo",
         clicks=["Mudar proposta"]),
    dict(name="cooperativa/03-relatorios", path="/associacao/relatorios", size=DESKTOP, login="demo",
         docs="cooperativa-relatorios"),
    dict(name="cooperativa/04-relatorios-por-cooperado", path="/associacao/relatorios", size=DESKTOP, login="demo",
         scroll=3),
    dict(name="cooperativa/05-visao-geral", path="/associacao/visao-geral", size=DESKTOP, login="demo"),
    dict(name="cooperativa/06-loja-parceiras", path="/restaurante/entregadores", size=DESKTOP, login="owner",
         scroll=3),
    dict(name="cooperativa/07-entregador-minha-associacao", path="/entregador/ganhos", size=DESKTOP, login="demo",
         scroll=3),
    dict(name="cooperativa/08-lojas-celular", path="/associacao/lojas", size=PHONE, login="demo"),
    # Gestão da associação (0.3.0): cada tela no desktop e no celular
    dict(name="gestao-associacao/01-financeiro-resumo", path="/associacao/financeiro/resumo", size=DESKTOP, login="demo",
         docs="cooperativa-financeiro"),
    dict(name="gestao-associacao/02-financeiro-resumo-celular", path="/associacao/financeiro/resumo", size=PHONE,
         login="demo"),
    dict(name="gestao-associacao/03-faturas", path="/associacao/financeiro/faturas", size=DESKTOP, login="demo"),
    dict(name="gestao-associacao/04-faturas-celular", path="/associacao/financeiro/faturas", size=PHONE, login="demo"),
    dict(name="gestao-associacao/05-fatura-detalhe-celular", path="/associacao/financeiro/faturas", size=PHONE,
         login="demo", clicks=["Bruno Lima · nº 3"]),
    dict(name="gestao-associacao/06-lancamentos", path="/associacao/financeiro/lancamentos", size=DESKTOP, login="demo"),
    dict(name="gestao-associacao/07-lancamentos-celular", path="/associacao/financeiro/lancamentos", size=PHONE,
         login="demo"),
    dict(name="gestao-associacao/08-caixinha", path="/associacao/financeiro/caixinha", size=DESKTOP, login="demo"),
    dict(name="gestao-associacao/09-caixinha-celular", path="/associacao/financeiro/caixinha", size=PHONE, login="demo"),
    dict(name="gestao-associacao/10-cobranca", path="/associacao/financeiro/cobranca", size=DESKTOP, login="demo"),
    dict(name="gestao-associacao/11-cobranca-celular", path="/associacao/financeiro/cobranca", size=PHONE, login="demo"),
    dict(name="gestao-associacao/12-convenios", path="/associacao/convenios", size=DESKTOP, login="demo",
         docs="cooperativa-convenios"),
    dict(name="gestao-associacao/13-convenios-celular", path="/associacao/convenios", size=PHONE, login="demo"),
    dict(name="gestao-associacao/14-enquetes", path="/associacao/assembleia/enquetes", size=DESKTOP, login="demo"),
    dict(name="gestao-associacao/15-enquetes-celular", path="/associacao/assembleia/enquetes", size=PHONE, login="demo"),
    dict(name="gestao-associacao/16-documentos", path="/associacao/assembleia/documentos", size=DESKTOP, login="demo"),
    dict(name="gestao-associacao/17-documentos-celular", path="/associacao/assembleia/documentos", size=PHONE,
         login="demo"),
    dict(name="gestao-associacao/18-associados", path="/associacao/associados", size=DESKTOP, login="demo"),
    dict(name="gestao-associacao/19-associados-celular", path="/associacao/associados", size=PHONE, login="demo"),
    dict(name="gestao-associacao/20-associado-ficha-celular", path="/associacao/associados", size=PHONE, login="demo",
         clicks=["Ana Souza · nº 2"]),
    dict(name="gestao-associacao/21-cooperado-resumo", path="/entregador/associacao/resumo", size=DESKTOP, login="demo",
         docs="cooperado-associacao"),
    dict(name="gestao-associacao/22-cooperado-resumo-celular", path="/entregador/associacao/resumo", size=PHONE,
         login="demo"),
    dict(name="gestao-associacao/23-cooperado-faturas-celular", path="/entregador/associacao/faturas", size=PHONE,
         login="demo"),
    dict(name="gestao-associacao/24-cooperado-convenios-celular", path="/entregador/associacao/convenios", size=PHONE,
         login="demo"),
    dict(name="gestao-associacao/25-cooperado-enquetes-celular", path="/entregador/associacao/enquetes", size=PHONE,
         login="demo"),
    dict(name="gestao-associacao/26-cooperado-documentos-celular", path="/entregador/associacao/documentos", size=PHONE,
         login="demo"),
    dict(name="gestao-associacao/27-vitrine-a-partir-de", path="/home", size=DESKTOP, login="demo"),
    dict(name="gestao-associacao/28-vitrine-a-partir-de-celular", path="/home", size=PHONE, login="demo"),
    dict(name="gestao-associacao/29-loja-taxa-repassada", path="/restaurante/entregadores", size=DESKTOP, login="demo"),
    dict(name="gestao-associacao/30-loja-taxa-repassada-celular", path="/restaurante/entregadores", size=PHONE,
         login="demo"),
    dict(name="admin/01-visao-geral", path="/admin", size=DESKTOP, login="demo"),
    dict(name="admin/02-usuarios", path="/admin/usuarios", size=DESKTOP, login="demo"),
    dict(name="admin/03-seletor-de-perfis", path="/admin", size=DESKTOP, login="demo", clicks=["Menu", "Administração"]),
]


def port_in_use(port: int) -> bool:
    with socket.socket() as s:
        return s.connect_ex(("127.0.0.1", port)) == 0


def serve_web(port: int) -> None:
    """Serve o build web com fallback para index.html (rotas do go_router)"""

    class Handler(http.server.SimpleHTTPRequestHandler):
        def send_head(self):
            if not os.path.exists(self.translate_path(self.path.split("?")[0])):
                self.path = "/index.html"
            return super().send_head()

        def log_message(self, *args):
            pass

    handler = functools.partial(Handler, directory=str(WEB_BUILD))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", port), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()


def login(api: str, credentials: tuple[str, str]) -> dict:
    response = requests.post(f"{api}/auth/login", json={"email": credentials[0], "password": credentials[1]}, timeout=10)
    response.raise_for_status()
    return response.json()


def storage_script(session: dict, cart: dict | None) -> str:
    """localStorage do shared_preferences na web: chave "flutter." + nome, valor em JSON"""
    script = (
        f"localStorage.setItem('flutter.auth_token', {json.dumps(json.dumps(session['accessToken']))});"
        f"localStorage.setItem('flutter.user_data', {json.dumps(json.dumps(json.dumps(session['user'])))});"
    )
    if cart:
        script += f"localStorage.setItem('flutter.cart_v2', {json.dumps(json.dumps(json.dumps(cart)))});"
    return script


def demo_cart(api: str, store: str) -> dict:
    restaurant = requests.get(f"{api}/public/restaurants/{store}", timeout=10).json()
    menu = requests.get(f"{api}/public/restaurants/{restaurant['id']}/menu", timeout=10).json()
    item = next(i for s in menu["sections"] for i in s["items"] if i.get("available", True))
    return {
        "restaurant": {k: restaurant.get(k) for k in ("id", "slug", "name", "logoUrl", "deliveryFee", "minimumOrder")},
        "lines": [{
            "productId": item["id"], "comboId": None, "name": item["name"], "imageUrl": item.get("imageUrl"),
            "unitPrice": item.get("promotionalPrice") or item["price"], "quantity": 2, "notes": None, "options": [],
        }],
    }


async def capture(browser, web: str, shot: dict, init: str, store: str) -> Path:
    width, height = shot["size"]
    page = await browser.new_page(viewport={"width": width, "height": height})
    page.on("pageerror", lambda e: print(f"  erro na página: {str(e)[:200]}"))
    await page.add_init_script(init)
    await page.goto(web + shot["path"].format(store=store), wait_until="networkidle")
    await page.wait_for_selector("flutter-view, flt-glass-pane", timeout=60000)
    await page.wait_for_timeout(4000)
    # Liga a árvore de acessibilidade do Flutter, que permite clicar pelos textos
    await page.evaluate("document.querySelector('flt-semantics-placeholder')?.click()")
    await page.wait_for_timeout(800)

    for label in shot.get("clicks", []):
        # "xy:x,y" clica na posição (botões só com ícone ou avatar)
        if label.startswith("xy:"):
            x, y = (float(v) for v in label[3:].split(","))
            await page.mouse.click(x, y)
            await page.wait_for_timeout(1500)
            continue
        # "css:seletor" clica no primeiro elemento de acessibilidade que casa com o seletor
        if label.startswith("css:"):
            await page.locator(label[4:]).first.click(timeout=5000)
            await page.wait_for_timeout(1500)
            continue
        # "aria:Texto" procura só no rótulo de acessibilidade (ex: tooltip de um botão de ícone)
        if label.startswith("aria:"):
            target = page.locator(f'flt-semantics[aria-label*="{label[5:]}"]').first
        else:
            target = page.locator(f'flt-semantics:has-text("{label}"), flt-semantics[aria-label*="{label}"]').last
        await target.click(timeout=5000)
        await page.wait_for_timeout(1500)

    if shot.get("scroll"):
        await page.mouse.move(width / 2, height / 2)
        for _ in range(shot["scroll"]):
            await page.mouse.wheel(0, 400)
            await page.wait_for_timeout(120)
        await page.wait_for_timeout(1500)

    # Tira o mouse de cima dos botões: um tooltip aberto sairia no print
    await page.mouse.move(width - 2, height - 2)
    await page.wait_for_timeout(3500 if shot.get("clicks") else 1500)
    out = LAYOUT / f"{shot['name']}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    await page.screenshot(path=str(out))
    await page.close()
    return out


def copy_to_docs(png: Path, name: str) -> None:
    DOCS_SCREENS.mkdir(parents=True, exist_ok=True)
    Image.open(png).convert("RGB").save(DOCS_SCREENS / f"{name}.jpg", quality=82, optimize=True, progressive=True)


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--api", default="http://localhost:8080/api")
    parser.add_argument("--web", default="http://localhost:3000")
    parser.add_argument("--store", default="cantina-demo", help="slug da loja das telas do cliente")
    parser.add_argument("--owner", default=":".join(DEMO), help="email:senha do dono das telas do restaurante")
    parser.add_argument("--only", help="só as capturas cujo nome contém este texto")
    parser.add_argument("--serve", action="store_true", help="serve frontend/build/web na porta 3000 se ela estiver livre")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()

    shots = [s for s in SHOTS if not args.only or args.only in s["name"]]
    if args.list:
        for s in shots:
            print(f"{s['name']:45} {s['path']:24} {s['size'][0]}x{s['size'][1]}")
        return

    if args.serve and not port_in_use(3000):
        serve_web(3000)

    sessions = {"demo": login(args.api, DEMO), "owner": login(args.api, tuple(args.owner.split(":", 1)))}
    cart = demo_cart(args.api, args.store)

    async with async_playwright() as p:
        browser = await p.chromium.launch()
        for shot in shots:
            print(f"{shot['name']} ...")
            init = storage_script(sessions[shot["login"]], cart if shot.get("cart") else None)
            try:
                out = await capture(browser, args.web, shot, init, args.store)
            except Exception as e:  # uma captura com problema não impede as outras
                print(f"  FALHOU: {e}")
                continue
            if shot.get("docs"):
                copy_to_docs(out, shot["docs"])
        await browser.close()


if __name__ == "__main__":
    asyncio.run(main())
