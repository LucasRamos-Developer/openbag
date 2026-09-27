# Layout do OpenBag

Capturas de tela de referência da versão **0.2.0**. Veja o que mudou no [CHANGELOG](../CHANGELOG.md).

As capturas são refeitas pelo script [`tools/screenshots`](../tools/screenshots/README.md).

A imagem [`restaurante-padrão.png`](restaurante-padrão.png) é a referência visual da página do restaurante. Os tokens de cor e os componentes ficam em [`frontend/lib/core/ui`](../frontend/lib/core/ui/README.md).

Quer saber mais? Escreva para [lucasramos.developer@gmail.com](mailto:lucasramos.developer@gmail.com).

---

## Temas da loja

Cada restaurante escolhe um dos 8 temas ou usa a cor da marca. O painel de aparência mostra a prévia ao vivo.

| Painel de aparência | No celular |
|---|---|
| ![Painel de aparência](temas/painel-aparencia.png) | <img src="temas/mobile-fresh-green.png" alt="Loja no celular" width="260"> |

**Claros**

| Fresh Green | Sunset Orange | Berry Pink |
|---|---|---|
| ![Fresh Green](temas/01-fresh-green.png) | ![Sunset Orange](temas/02-sunset-orange.png) | ![Berry Pink](temas/03-berry-pink.png) |

| Ocean Blue | Grape Purple |
|---|---|
| ![Ocean Blue](temas/04-ocean-blue.png) | ![Grape Purple](temas/05-grape-purple.png) |

**Escuros**

| Midnight Green | Midnight Blue | Graphite |
|---|---|---|
| ![Midnight Green](temas/06-midnight-green.png) | ![Midnight Blue](temas/07-midnight-blue.png) | ![Graphite](temas/08-graphite.png) |

---

## Loja e vitrine

| Loja: geral | Loja: aparência |
|---|---|
| ![Loja: geral](loja-e-vitrine/01-loja-geral.png) | ![Loja: aparência](loja-e-vitrine/02-loja-aparencia.png) |

| Loja: endereço | Loja: horários |
|---|---|
| ![Loja: endereço](loja-e-vitrine/03-loja-endereco.png) | ![Loja: horários](loja-e-vitrine/04-loja-horarios.png) |

| Avaliações | Situação da loja no menu |
|---|---|
| ![Avaliações](loja-e-vitrine/05-avaliacoes.png) | ![Situação no menu](loja-e-vitrine/06-status-no-menu.png) |

| Vitrine (cliente, em testes) | Página do restaurante (cliente, em testes) |
|---|---|
| ![Vitrine](loja-e-vitrine/08-vitrine-grade.png) | ![Página do restaurante](loja-e-vitrine/09-restaurante-barra-vidro.png) |

| Pedidos | Celular com o menu aberto |
|---|---|
| ![Pedidos](loja-e-vitrine/10-pedidos-titulo.png) | <img src="loja-e-vitrine/07-celular-gaveta.png" alt="Celular com menu" width="260"> |

**Área do cliente: rodapé e carrinho.** O carrinho flutua sobre a página e o rodapé reserva o espaço dele, então dá para ver tudo até o fim.

| Fim da página com o carrinho | No celular |
|---|---|
| ![Rodapé com o carrinho](loja-e-vitrine/11-rodape-carrinho.png) | <img src="loja-e-vitrine/12-rodape-celular.png" alt="Rodapé no celular" width="260"> |

| Sobre a loja: endereço, mapa e botão para abrir no app de mapas |
|---|
| ![Sobre a loja com o mapa](loja-e-vitrine/13-sobre-a-loja-mapa.png) |

O mapa tem estilo próprio (`frontend/assets/map/openbag_style.json`): é claro, com cores próximas às do Google Maps e sem relevo. Os dados vêm do OpenFreeMap.

---

## Caixa e rotas

| Rotas sendo montadas | Rota com entregador |
|---|---|
| ![Rotas montando](caixa-e-rotas/01-rotas-montando.png) | ![Rota com entregador](caixa-e-rotas/02-rotas-com-entregador.png) |

| Caixa | Acerto com o entregador |
|---|---|
| ![Caixa](caixa-e-rotas/03-caixa.png) | ![Acerto](caixa-e-rotas/04-caixa-acerto.png) |

**Entregador em rota** (painel em desenvolvimento)

<img src="caixa-e-rotas/05-entregador-rota.png" alt="Entregador em rota" width="260">

---

## Painel do super admin

Somente leitura: números da plataforma e listas de restaurantes, associações, entregadores, usuários e pedidos. A conta demo (`demo@openbag.local`) tem todos os perfis.

| Visão geral | Usuários |
|---|---|
| ![Visão geral do admin](admin/01-visao-geral.png) | ![Usuários](admin/02-usuarios.png) |

| Seletor com os cinco perfis da conta demo |
|---|
| ![Seletor de perfis](admin/03-seletor-de-perfis.png) |

---

## Navegação

| Desktop: menu recolhido | Desktop: menu expandido |
|---|---|
| ![Menu recolhido](menu/01-desktop-recolhido.png) | ![Menu expandido](menu/02-desktop-expandido.png) |

| Seletor de perfil | Seletor com o menu recolhido |
|---|---|
| ![Seletor de perfil](menu/03-seletor-de-perfil.png) | ![Seletor recolhido](menu/04-seletor-recolhido.png) |

| Vitrine: "Meus painéis" |
|---|
| ![Meus painéis](menu/05-vitrine-meus-paineis.png) |

| Celular | Menu no celular | Aba do cardápio |
|---|---|---|
| <img src="menu/06-mobile.png" alt="Celular" width="220"> | <img src="menu/07-mobile-gaveta.png" alt="Menu no celular" width="220"> | <img src="menu/08-mobile-aba-cardapio.png" alt="Aba do cardápio" width="220"> |

---

## Em desenvolvimento

- **Painel do entregador:** as telas estão sendo concluídas na versão 0.3.0.
- **Painel da associação ou cooperativa:** parcerias com lojas e relatórios estão a caminho na versão 0.3.0.

## Marca

| | |
|---|---|
| ![Marca](brand.png) | ![Marca, variação](brand-2.png) |
