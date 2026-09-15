# Plano de Implementação

> 🌐 Idiomas: [English](../en/implementation-plan.md) | Português (Brasil)

## 1. Objetivo

Implementar e validar uma estratégia de Disaster Recovery entre um ambiente
on-premises e a AWS para uma aplicação containerizada com banco de dados
SQLite.

A solução deve permitir:

- replicar continuamente o banco para o Amazon S3;
- provisionar o ambiente DR sob demanda;
- restaurar a aplicação na AWS após uma indisponibilidade;
- realizar failover controlado;
- operar temporariamente no ambiente DR;
- retornar a operação ao ambiente on-premises por meio de failback;
- validar integridade e disponibilidade antes de alterações de tráfego;
- medir RTO e avaliar RPO;
- reproduzir a infraestrutura utilizando Infrastructure as Code.

---

## 2. Abordagem de Implementação

O projeto foi desenvolvido de forma incremental, com validação funcional
dos principais componentes ao longo da implementação.

Apesar de não ter sido conduzido como um projeto Scrum formal, foram
adotados conceitos compatíveis com práticas Agile, como:

- decomposição do trabalho em incrementos;
- backlog técnico;
- critérios de aceite;
- validação contínua;
- Definition of Done;
- evolução iterativa da solução;
- documentação de riscos e decisões;
- coleta de evidências.

O código final da solução está versionado no repositório Git.

---

## 3. Escopo

### Em escopo

- aplicação Flask containerizada;
- banco SQLite;
- Docker e Docker Compose;
- Litestream;
- replicação para Amazon S3;
- infraestrutura AWS com Terraform;
- Amazon EC2;
- Amazon VPC;
- Security Groups;
- IAM Role e Instance Profile;
- AWS Systems Manager Session Manager;
- Cloudflare Tunnel;
- gerenciamento de DNS com Terraform;
- automação em Bash;
- failover on-premises → AWS;
- operação temporária no ambiente DR;
- failback AWS → on-premises;
- validação de banco;
- healthchecks;
- medição de RTO;
- análise de RPO;
- documentação e evidências.

### Fora de escopo

- arquitetura Multi-AZ;
- High Availability;
- banco gerenciado;
- replicação active-active;
- recuperação totalmente automática;
- CI/CD completo;
- failover sem intervenção humana;
- ambiente produtivo real.

---

## 4. Premissas e Restrições

### Premissas

- o ambiente on-premises está operacional em situação normal;
- apenas um ambiente recebe tráfego produtivo por vez;
- o Amazon S3 é utilizado como ponto intermediário de recuperação;
- Terraform representa o estado desejado da infraestrutura AWS e do DNS;
- o ambiente DR é provisionado sob demanda;
- a estação administrativa possui acesso aos ambientes necessários.

### Restrições

- foco em baixo custo;
- única instância EC2 no ambiente DR;
- banco SQLite;
- dependência do Cloudflare para publicação da aplicação;
- dependência de uma estação administrativa para execução de Terraform e scripts;
- ausência de orquestração totalmente autônoma.

---

## 5. Pré-requisitos

### Estação administrativa

- Terraform
- AWS CLI
- Git
- Bash
- SSH client

### AWS

- conta AWS;
- autenticação válida;
- permissões necessárias;
- região configurada;
- acesso aos serviços utilizados no laboratório.

### Cloudflare

- domínio gerenciado;
- Cloudflare Tunnel;
- API Token;
- provider Cloudflare configurado no Terraform.

### On-Premises

- Linux;
- Docker;
- Docker Compose;
- Flask;
- SQLite;
- Litestream;
- Traefik;
- SSH por chave.

---

# 6. Backlog de Alto Nível

O trabalho foi organizado conceitualmente nos seguintes épicos.

## Epic 1 — Data Protection

Objetivo:

Garantir que o estado da aplicação possa ser recuperado após perda do
ambiente primário.

Itens principais:

- configuração do Litestream;
- replicação SQLite → S3;
- restore do banco;
- validação de integridade.

**Status:** Concluído

---

## Epic 2 — AWS Disaster Recovery Infrastructure

Objetivo:

Criar uma infraestrutura reproduzível capaz de executar a aplicação na AWS.

Itens principais:

- VPC;
- subnet;
- roteamento;
- Security Group;
- EC2;
- IAM;
- Systems Manager;
- Terraform.

**Status:** Concluído

---

## Epic 3 — Application Recovery

Objetivo:

Restaurar automaticamente a aplicação e seus dados no ambiente DR.

Itens principais:

- bootstrap EC2;
- Docker;
- restore do SQLite;
- inicialização da aplicação;
- healthcheck.

**Status:** Concluído

---

## Epic 4 — Traffic Management

Objetivo:

Controlar qual ambiente recebe o tráfego da aplicação.

Itens principais:

- Cloudflare Tunnel on-premises;
- Cloudflare Tunnel DR;
- DNS gerenciado via Terraform;
- failover de DNS;
- failback de DNS.

**Status:** Concluído

---

## Epic 5 — Disaster Recovery Operations

Objetivo:

Validar o ciclo completo de recuperação.

Itens principais:

- failover;
- operação no ambiente DR;
- persistência durante DR;
- failback;
- cleanup.

**Status:** Concluído

---

## Epic 6 — Documentation and Evidence

Objetivo:

Documentar a arquitetura, decisões e resultados do laboratório.

**Status:** Em andamento

---

# 7. Fases de Implementação

## Fase 1 — Estrutura e Fundação

### Objetivo

Preparar o projeto e os componentes fundamentais.

### Principais entregas

- estrutura do repositório;
- Terraform;
- arquivos Docker;
- scripts;
- organização da documentação.

### Critérios de aceite

- Terraform inicializa corretamente;
- estrutura reproduzível;
- arquivos sensíveis não são versionados;
- código necessário disponível no repositório.

### Status

**Concluído**

---

## Fase 2 — Replicação do Banco

### Objetivo

Garantir uma cópia externa recuperável do SQLite.

### Entregas

- configuração do Litestream;
- Amazon S3;
- replicação contínua;
- teste de restore.

### Critérios de aceite

- banco replicado para S3;
- backup recente disponível;
- restore executado com sucesso;
- `PRAGMA integrity_check` retorna `ok`;
- dados esperados estão presentes após o restore.

### Status

**Concluído**

---

## Fase 3 — Infraestrutura AWS

### Objetivo

Criar a infraestrutura necessária para execução do DR.

### Entregas

- VPC;
- subnet;
- routing;
- Internet Gateway;
- Security Group;
- EC2;
- IAM Role;
- Instance Profile;
- Systems Manager.

### Critérios de aceite

- infraestrutura criada pelo Terraform;
- EC2 inicializada corretamente;
- acesso via SSM funcional;
- nenhuma porta SSH pública necessária;
- conectividade de saída disponível.

### Status

**Concluído**

---

## Fase 4 — Bootstrap e Recuperação da Aplicação

### Objetivo

Inicializar automaticamente o ambiente DR.

### Entregas

- `user_data.sh`;
- instalação/preparação do Docker;
- configuração da aplicação;
- Litestream;
- restore do banco;
- healthcheck.

### Critérios de aceite

- bootstrap concluído;
- containers iniciados;
- banco restaurado;
- banco íntegro;
- aplicação saudável.

### Status

**Concluído**

---

## Fase 5 — Failover

### Objetivo

Validar a recuperação da aplicação após indisponibilidade do ambiente
primário.

### Fluxo validado

```text
On-Premises failure
        ↓
Terraform plan
        ↓
Terraform apply
        ↓
AWS DR provisioning
        ↓
SQLite restore
        ↓
Database validation
        ↓
Application healthcheck
        ↓
DNS cutover
        ↓
AWS DR active
```

### Critérios de aceite

- ambiente primário indisponível;
- DR provisionado;
- banco restaurado;
- banco íntegro;
- aplicação saudável;
- DNS apontando para o DR;
- acesso externo validado;
- evidências coletadas.

### Status

**Concluído**

---

## Fase 6 — Operação no Ambiente DR

### Objetivo

Comprovar que o ambiente DR pode assumir temporariamente a operação.

### Critérios de aceite

- aplicação funcional na AWS;
- novos dados podem ser gravados;
- Litestream continua replicando;
- dados produzidos durante DR são enviados ao S3.

### Status

**Concluído**

---

## Fase 7 — Failback

### Objetivo

Retornar a aplicação e os dados atualizados ao ambiente on-premises.

### Fluxo validado

```text
AWS DR active
      ↓
Stop / control writes
      ↓
Final replication to S3
      ↓
Restore on-premises
      ↓
Database integrity validation
      ↓
Application healthcheck
      ↓
DNS failback
      ↓
On-Premises active
      ↓
AWS DR cleanup
```

### Critérios de aceite

- replicação final concluída;
- banco restaurado no on-premises;
- `PRAGMA integrity_check` retorna `ok`;
- registro criado durante o DR está presente;
- aplicação on-premises está saudável;
- DNS retorna ao ambiente primário;
- acesso externo é validado;
- ambiente DR pode ser desprovisionado.

### Status

**Concluído**

---

## Fase 8 — Documentação e Encerramento

### Objetivo

Consolidar os resultados e evidências do laboratório.

### Entregas

- README;
- arquitetura;
- plano de implementação;
- documentação de segurança;
- monitoramento;
- análise de custos;
- troubleshooting;
- lições aprendidas;
- evidências;
- RTO;
- RPO.

### Critérios de aceite

- documentação atualizada;
- evidências disponíveis;
- nenhum secret publicado;
- links internos validados;
- versão PT-BR concluída;
- versão em inglês criada.

### Status

**Em andamento**

---

## 8. Definition of Done

Uma entrega do projeto é considerada concluída quando, quando aplicável:

- a implementação necessária está presente no repositório;
- a configuração foi validada;
- o comportamento esperado foi testado;
- a validação funcional foi concluída;
- nenhum secret foi versionado;
- falhas conhecidas relevantes foram registradas;
- evidências foram coletadas;
- documentação correspondente foi atualizada.

Para mudanças Terraform:

```text
terraform fmt
      ↓
terraform validate
      ↓
terraform plan
      ↓
review
      ↓
terraform apply
      ↓
functional validation
```

A implementação final necessária para reproduzir o laboratório deve estar
versionada no repositório.

---

## 9. Métricas de Sucesso

### RTO

Tempo medido entre a conclusão da interrupção da stack no ambiente on-premises
e a primeira confirmação de disponibilidade da aplicação através do ambiente DR.

**Resultado: 3 min 43s**

### RPO

Diferença entre o último estado confirmado no ambiente primário e o estado
recuperado no ambiente DR.

**Resultado: Não mensurado de forma controlada**

> O RPO não foi mensurado de forma controlada nesta execução. A solução utiliza
> replicação contínua e assíncrona do SQLite para o Amazon S3 por meio do Litestream,
> portanto o RPO esperado é baixo, mas não foi validado empiricamente neste teste.

### Integridade

O banco restaurado deve retornar:

`PRAGMA integrity_check → ok`

### Continuidade dos Dados

Dados gravados durante o período de operação no DR devem ser recuperados no
ambiente on-premises durante o failback.

### Reprodutibilidade

A infraestrutura DR deve poder ser recriada utilizando exclusivamente:
- código versionado;
- variáveis de ambiente/configuração;
- credenciais válidas;
- dados persistidos no S3.

---

## 10. Estado Atual do Projeto


| Entrega                      | Status       |
| ---------------------------- | ------------ |
| Aplicação on-premises        | Concluída    |
| Replicação SQLite → S3       | Concluída    |
| Infraestrutura AWS Terraform | Concluída    |
| EC2 bootstrap                | Concluído    |
| Restore no DR                | Concluído    |
| SSM                          | Concluído    |
| Cloudflare Tunnel DR         | Concluído    |
| Failover                     | Concluído    |
| Transição do DNS para AWS    | Concluído    |
| Operação no DR               | Concluída    |
| Failback                     | Concluído    |
| DNS failback                 | Concluído    |
| Cleanup final                | Concluído    |
| Evidências finais            | Concluído    |
| Documentação                 | Em andamento |


## 11. Critérios de Conclusão do Projeto

O laboratório será considerado concluído quando:
- infraestrutura estiver versionada e reproduzível;
- replicação on-premises → S3 estiver validada;
- ambiente DR puder ser provisionado sob demanda;
- restore na AWS estiver validado;
- failover completo tiver sido executado;
- aplicação tiver operado no ambiente DR;
- dados produzidos no DR tiverem sido replicados;
- failback tiver sido executado com sucesso;
- dados criados durante o DR tiverem sido recuperados no on-premises;
- aplicação on-premises estiver saudável após o failback;
- DNS tiver retornado ao ambiente primário;
- recursos temporários tiverem sido removidos;
- RTO tiver sido medido e registrado;
- RPO tiver sido avaliado e sua limitação documentada;
- evidências tiverem sido coletadas;
- documentação estiver concluída.
