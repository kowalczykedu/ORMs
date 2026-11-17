---
name: task
description: >-
  Implementa a aplicação simples em TypeScript + Prisma conectada ao banco
  TechStore seguindo rigorosamente docs/02-especificacao-aplicacao.md.
---

# `/task` — Implementação da Aplicação TechStore (TypeScript + Prisma)

Este comando executa a criação da aplicação simples em **TypeScript + Prisma** ligada ao TechStore (`banco/`), seguindo exatamente a especificação salva pelo `/quest2`.

## Instruções para o Agente

1. Leia `docs/02-especificacao-aplicacao.md` (se ainda não existir, oriente o usuário a executar `/quest2` primeiro) e verifique `banco/docker-compose.yaml` e `banco/init.sql`.
2. Preserve intactos os arquivos originais da disciplina dentro de `banco/` (não quebre `init.sql`, `iniciar.sh` nem `reset.sh`).
3. Implemente a aplicação conforme a especificação, priorizando:
   - Código limpo, simples de ler e fácil de explicar pelo trio na apresentação;
   - Portabilidade para rodar tanto no notebook/SSD do usuário quanto no PC do laboratório (com `package.json`, `.env.example`, script de preparação/instalação e instruções claras);
   - Demonstração real e funcional da Parte 1 (ORM básico), Parte 2 (problema N+1 visível no `general_log` do MySQL) e Parte 3 (carregamento antecipado com `include`, comportamento de `JOIN`, contagem de queries e comparação com SQL manual).
4. Execute testes/validações reais possíveis no ambiente e documente exatamente o passo a passo de uso ao vivo e o reset final (`banco/reset.sh`).
