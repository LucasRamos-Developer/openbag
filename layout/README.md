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

| Vitrine: busca e ordenação | Vitrine no celular |
|---|---|
| ![Ordenação da vitrine](loja-e-vitrine/15-vitrine-ordenacao.png) | <img src="loja-e-vitrine/16-vitrine-celular.png" alt="Vitrine no celular" width="260"> |

| Vitrine (cliente) | Página do restaurante (cliente) |
|---|---|
| ![Vitrine](loja-e-vitrine/08-vitrine-grade.png) | ![Página do restaurante](loja-e-vitrine/09-restaurante-barra-vidro.png) |

| Pedidos | Celular com o menu aberto |
|---|---|
| ![Pedidos](loja-e-vitrine/10-pedidos-titulo.png) | <img src="loja-e-vitrine/07-celular-gaveta.png" alt="Celular com menu" width="260"> |

**Área do cliente: rodapé e carrinho.** O carrinho flutua sobre a página e o rodapé reserva o espaço dele, então dá para ver tudo até o fim.

| Fim da página com o carrinho | No celular |
|---|---|
| ![Rodapé com o carrinho](loja-e-vitrine/11-rodape-carrinho.png) | <img src="loja-e-vitrine/12-rodape-celular.png" alt="Rodapé no celular" width="260"> |

| Cardápio em acordeão (a primeira seção recolhida) |
|---|
| ![Cardápio em acordeão](loja-e-vitrine/14-cardapio-acordeao.png) |

| Sobre a loja: endereço, mapa e botão para abrir no app de mapas |
|---|
| ![Sobre a loja com o mapa](loja-e-vitrine/13-sobre-a-loja-mapa.png) |

O mapa tem estilo próprio (`frontend/assets/map/openbag_style.json`): é claro, com cores próximas às do Google Maps e sem relevo. Os dados vêm do OpenFreeMap.

---

## Caixa e rotas

O caminho de cada rota segue as ruas (roteamento pelo OSRM).

| Rotas sendo montadas | Rota com entregador |
|---|---|
| ![Rotas montando](caixa-e-rotas/01-rotas-montando.png) | ![Rota com entregador](caixa-e-rotas/02-rotas-com-entregador.png) |

| Caixa | Acerto com o entregador |
|---|---|
| ![Caixa](caixa-e-rotas/03-caixa.png) | ![Acerto](caixa-e-rotas/04-caixa-acerto.png) |

**Entregador em rota** (painel em desenvolvimento)

<img src="caixa-e-rotas/05-entregador-rota.png" alt="Entregador em rota" width="260">

---

## Pedido do balcão, no celular

Teste de ponta a ponta da versão 0.4.0, em 375px: o pedido chega por telefone, vai para a cozinha, é entregue e depois acertado no caixa. Há também um pedido de retirada no balcão.

| Novo pedido | Quadro depois de enviar | Oferta ao entregador |
|---|---|---|
| <img src="balcao/1-novo-pedido.png" alt="Novo pedido" width="220"> | <img src="balcao/2-quadro.png" alt="Quadro" width="220"> | <img src="balcao/3-oferta-entregador.png" alt="Oferta" width="220"> |

| Caixa com o acerto | Retirada no balcão |
|---|---|
| <img src="balcao/4-caixa-acerto.png" alt="Caixa" width="220"> | <img src="balcao/5-retirada.png" alt="Retirada" width="220"> |

---

## Rastreio, avaliações e diferença assumida

Depois da retirada, o cliente vê o entregador no mapa, mas só quando é a vez do pedido dele na rota. Depois da entrega, ele avalia a loja e o entregador.

| Entregador a caminho | Avaliação do pedido | Avaliação com resposta da loja |
|---|---|---|
| ![Rastreio](entregador-finalizacao/rastreio-cliente.png) | ![Avaliação](entregador-finalizacao/avaliacao-pedido.png) | ![Resposta](entregador-finalizacao/avaliacao-com-resposta.png) |

| Avaliações no painel da loja | Nota no perfil do entregador |
|---|---|
| ![Avaliações da loja](entregador-finalizacao/avaliacoes-loja.png) | ![Perfil do entregador](entregador-finalizacao/perfil-entregador-nota.png) |

| Caixa com a diferença assumida nas entregas |
|---|
| ![Diferença assumida](entregador-finalizacao/caixa-diferenca-assumida.png) |

---

## Painel da cooperativa

A loja ou a associação pede a parceria, e o outro lado aceita. Com cada loja parceira, as duas podem combinar uma tabela especial, que só vale com o aceite dos dois lados. O entregador sempre recebe 100% do valor.

| Lojas parceiras | Propor tabela especial |
|---|---|
| ![Lojas parceiras](cooperativa/01-lojas-parceiras.png) | ![Propor tabela](cooperativa/02-propor-tabela.png) |

| Proposta da associação no painel da loja | Visão geral |
|---|---|
| ![Parceiras na loja](cooperativa/06-loja-parceiras.png) | ![Visão geral](cooperativa/05-visao-geral.png) |

Os relatórios contam cada entrega para a associação em que o cooperado estava no dia. O cooperado vê o resumo da associação e a parte dele, nunca os ganhos dos colegas.

| Relatórios do gestor | Por cooperado e por loja |
|---|---|
| ![Relatórios](cooperativa/03-relatorios.png) | ![Por cooperado e por loja](cooperativa/04-relatorios-por-cooperado.png) |

| Minha associação, na aba Ganhos do entregador | No celular |
|---|---|
| ![Minha associação](cooperativa/07-entregador-minha-associacao.png) | <img src="cooperativa/08-lojas-celular.png" alt="Lojas parceiras no celular" width="260"> |

---

## Gestão da associação

Financeiro, convênios e assembleia no painel da cooperativa, e a área do cooperado no painel do entregador. Cada tela foi desenhada também para o celular: formulários em tela cheia, totais numa faixa só, ações no botão flutuante e sub-abas em pílulas roláveis.

| Financeiro (desktop) | No celular |
|---|---|
| ![Financeiro](gestao-associacao/01-financeiro-resumo.png) | <img src="gestao-associacao/02-financeiro-resumo-celular.png" alt="Financeiro no celular" width="260"> |

| Faturas do mês | Fatura no celular | Baixa manual |
|---|---|---|
| ![Faturas](gestao-associacao/03-faturas.png) | <img src="gestao-associacao/04-faturas-celular.png" alt="Faturas no celular" width="220"> | <img src="gestao-associacao/05-fatura-detalhe-celular.png" alt="Detalhe da fatura" width="220"> |

| Lançamentos | Caixinha | Cobrança e adicionais |
|---|---|---|
| <img src="gestao-associacao/07-lancamentos-celular.png" alt="Lançamentos" width="220"> | <img src="gestao-associacao/09-caixinha-celular.png" alt="Caixinha" width="220"> | <img src="gestao-associacao/11-cobranca-celular.png" alt="Cobrança" width="220"> |

| Convênios | Enquetes | Atas e documentos |
|---|---|---|
| <img src="gestao-associacao/13-convenios-celular.png" alt="Convênios" width="220"> | <img src="gestao-associacao/15-enquetes-celular.png" alt="Enquetes" width="220"> | <img src="gestao-associacao/17-documentos-celular.png" alt="Documentos" width="220"> |

| Associados com mensalidade e exportação | Ficha com veículos |
|---|---|
| <img src="gestao-associacao/19-associados-celular.png" alt="Associados" width="220"> | <img src="gestao-associacao/20-associado-ficha-celular.png" alt="Ficha do associado" width="220"> |

Área do cooperado (painel do entregador):

| Resumo | Faturas | Convênios | Enquetes |
|---|---|---|---|
| <img src="gestao-associacao/22-cooperado-resumo-celular.png" alt="Resumo" width="190"> | <img src="gestao-associacao/23-cooperado-faturas-celular.png" alt="Faturas" width="190"> | <img src="gestao-associacao/24-cooperado-convenios-celular.png" alt="Convênios" width="190"> | <img src="gestao-associacao/25-cooperado-enquetes-celular.png" alt="Enquetes" width="190"> |

Taxa repassada ao cliente: a vitrine mostra "a partir de" e a loja vê quanto o cliente paga em cada distância.

| Vitrine | Configuração da loja |
|---|---|
| ![Vitrine a partir de](gestao-associacao/27-vitrine-a-partir-de.png) | <img src="gestao-associacao/30-loja-taxa-repassada-celular.png" alt="Taxa repassada" width="260"> |

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

## Marca

| | |
|---|---|
| ![Marca](brand.png) | ![Marca, variação](brand-2.png) |
