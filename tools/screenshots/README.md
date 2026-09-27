# Capturas de tela

O script `take_screenshots.py` refaz as capturas de [`layout/`](../../layout/) e as cópias em JPG de [`docs/assets/screens/`](../../docs/assets/screens/).

## Pré-requisitos

1. Banco e serviços: `docker compose up -d`.
2. Backend com a conta demo ligada:

   ```bash
   cd backend
   OPENBAG_DEMO_ENABLED=true mvn spring-boot:run
   ```

   A conta `demo@openbag.local` / `demo1234` tem todos os perfis (cliente, restaurante, entregador, cooperativa e admin). Ela vem com a loja Cantina Demo e a Cooperativa Demo. **Nunca ligue `OPENBAG_DEMO_ENABLED` em produção.**
3. Build web: `cd frontend && flutter build web --release`.
4. Python: `pip install playwright pillow requests && playwright install chromium`.

## Uso

```bash
# Todas as capturas (serve o build web na porta 3000 se ela estiver livre)
python3 tools/screenshots/take_screenshots.py --serve

# Só algumas
python3 tools/screenshots/take_screenshots.py --only admin

# Lista o que o script captura
python3 tools/screenshots/take_screenshots.py --list
```

Por padrão, as telas do cliente usam a Cantina Demo e as do restaurante usam a conta demo. Para capturar uma loja com fotos e pedidos, passe outra loja e o dono dela:

```bash
python3 tools/screenshots/take_screenshots.py --store burger-da-vila --owner dono@exemplo.com:senha
```

## Como funciona

- O login é feito pela API. O token vai para o `localStorage` antes de a página abrir.
- A árvore de acessibilidade do Flutter é ligada para o script clicar pelos textos da tela.
- O carrinho de exemplo também é gravado no `localStorage` (2 unidades do primeiro item da loja).

Para acrescentar uma captura, adicione uma linha na lista `SHOTS` do script. Confira cada imagem antes de fazer o commit.
