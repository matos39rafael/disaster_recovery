# Disaster Recovery — On-Premises para AWS

> 🌐 Idiomas: [English](README.md) | Português (Brasil)

## Visão Geral

Este projeto implementa uma estratégia prática de **Disaster Recovery (DR)** para uma aplicação containerizada executada em ambiente on-premises, utilizando a AWS como ambiente secundário de recuperação.

Em caso de indisponibilidade do ambiente primário, a infraestrutura de Disaster Recovery é provisionada sob demanda na AWS por meio do Terraform. A instância de recuperação restaura a versão mais recente disponível do banco de dados, inicializa a aplicação em containers Docker e, após validações de integridade e saúde, o tráfego é redirecionado para o ambiente AWS.

Após a recuperação do ambiente on-premises, é realizado o processo de failback: os dados mais recentes são restaurados no ambiente primário, a integridade da aplicação é validada e o tráfego é direcionado novamente ao ambiente original.

## Objetivos
- Projetar DR híbrido;
- Automatizar infraestrutura com Terraform;
- Replicar SQLite para S3;
- Executar failover e failback;
- Medir RTO/RPO;
- Aplicar controles de segurança.

## Arquitetura
A solução utiliza dois ambientes principais:

### Primário (On-Premises)

Responsável pela execução normal da aplicação.

Principais componentes:

* Servidor Linux;
* Docker;
* Aplicação Flask;
* Banco de dados SQLite;
* Litestream;
* Traefik;
* Cloudflare Tunnel.

### Ambiente de Disaster Recovery — AWS

Provisionado quando necessário para assumir a execução da aplicação.

Principais componentes:

* Amazon EC2;
* Amazon S3;
* AWS Identity and Access Management — IAM;
* AWS Systems Manager Session Manager;
* Docker;
* Aplicação Flask;
* SQLite;
* Litestream;
* Cloudflare Tunnel.


![Arquitetura simplificada](diagrams/hybrid_disaster_recovery.png)

Mais detalhes:
[Arquitetura](docs/pt-BR/architecture.md)

## Estratégia de Recuperação


### Operação normal
Em seu modo de operação normal, as alterações do banco SQLite são continuamente replicadas para o Amazon S3 pelo Litestream. Os dados são salvos de forma versionada no bucket.

On-premises → SQLite → Litestream → S3.

### Failover
Constatada a falha do ambiente on-premises, é provisionada a estrutura de Difsaster Recovery na AWS através do Terraform. Por meio de bootstrap ao iniciar a instância EC2 é realizada a instalação das ferramentas necessárias, restaurado o banco de dados a partir do Amazon S3, é executado o healthcheck da aplicação e por fim é realizada a transição do apontamento do DNS para o novo ambiente.

Falha on-premises → provisionamento AWS → restore → healthcheck → transisão de DNS.

### Failback
Durante a operação do ambiente de Disaster Recovery, toda a informação gravada no banco de dados é replicada no Amazon S3. Após recuperar o ambiente on-premises é acionado um playbook (scripts/orchestrate-failback.sh) que realiza o processo de restauração do banco a partir do Amazon S3, validação de integridade do banco e da aplicação, transição de DNS e o desprovisionamento da estrutura na AWS.

DR → replicação para S3 → restore on-premises → validação → transição de DNS → destroy AWS.

Detalhes:
[Plano de implementação](docs/pt-BR/implementation-plan.md)

## Objetivos de Recuperação

| Métrica | Meta | Resultado |
|---|---:|---:|
| RTO | 10 min | 3 min 43 s |
| RPO | 1 min | Não mensurado |

> O RPO não foi mensurado de forma controlada nesta execução. A solução utiliza
> replicação contínua e assíncrona do SQLite para o Amazon S3 por meio do Litestream,
> portanto o RPO esperado é baixo, mas não foi validado empiricamente neste teste.

## Segurança
Principais controles:

- SSM Session Manager em vez de SSH público;
- Sem portas da aplicação expostas diretamente;
- Cloudflare Tunnel;
- IAM Role para EC2;
- Containers não-root;
- Secrets fora do repositório.

Detalhes:
[Segurança](docs/pt-BR/security.md)

## Tecnologias

| Categoria | Tecnologia |
|---|---|
| Cloud | AWS |
| IaC | Terraform |
| Compute | Amazon EC2 |
| Storage | Amazon S3 |
| Containers | Docker |
| Application | Flask |
| Database | SQLite |
| Replication | Litestream |
| Remote Management | AWS Systems Manager |
| Reverse Proxy | Traefik |
| External Access | Cloudflare Tunnel |

## Teste de Disaster Recovery

Fluxo validado:

1. Aplicação on-premises disponível;
2. Registro de teste criado;
3. Replicação confirmada no S3;
4. Ambiente on-premises indisponibilizado;
5. DR provisionado;
6. Banco restaurado;
7. Integridade validada;
8. Aplicação validada;
9. DNS redirecionado;
10. RTO registrado.

## Teste de Failback

1. Novo dado criado no DR;
2. Replicação para S3;
3. Restore no on-premises;
4. Validação do banco;
5. Healthcheck local;
6. DNS retornado;
7. Infraestrutura AWS removida.

## Evidências

Os resultados dos testes de failover e failback estão documentados em:

[Evidências do laboratório](docs/evidence/README.pt-BR.md)

## Estrutura do Repositório

```text
disaster_recovery/
├── README.md
├── README.pt-BR.md
├── docker/
├── scripts/
├── terraform/
├── diagrams/
└── docs/
    ├── en/
    ├── pt-BR/
    └── evidence/
```
