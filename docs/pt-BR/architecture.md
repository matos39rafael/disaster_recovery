# Arquitetura

> 🌐 Idiomas: [English](../en/architecture.md) | Português (Brasil)

## 1. Visão Geral

A solução implementa uma arquitetura híbrida de Disaster Recovery entre um
ambiente on-premises e a AWS.

Durante a operação normal, a aplicação é executada exclusivamente no ambiente
on-premises. O banco SQLite é continuamente replicado para o Amazon S3 por meio
do Litestream.

Em caso de indisponibilidade do ambiente primário, a infraestrutura de DR é
provisionada sob demanda na AWS utilizando Terraform. O banco é restaurado a
partir do S3 e a aplicação passa a ser executada em uma instância Amazon EC2.

Após a recuperação do ambiente primário, os dados produzidos durante o período
de DR são restaurados no on-premises e o tráfego é direcionado novamente para
esse ambiente.

A arquitetura utiliza um modelo **active/passive**, no qual apenas um ambiente
atende o tráfego da aplicação por vez.

---

## 2. Diagrama da Arquitetura

![Arquitetura detalhada de Disaster Recovery](../../diagrams/DR_architecture.png)

O diagrama representa os principais componentes de infraestrutura, os fluxos de
tráfego, os caminhos de replicação e os mecanismos de administração utilizados
no laboratório.

---

## 3. Componentes

### 3.1 Ambiente On-Premises

O ambiente primário é composto por:

- servidor Linux executando Docker;
- aplicação Flask;
- banco SQLite;
- Litestream;
- Traefik;
- Cloudflare Tunnel.

O Traefik realiza o roteamento interno para a aplicação, enquanto o Cloudflare
Tunnel permite a publicação do serviço sem exposição direta de portas do host à
Internet.

---

### 3.2 Ambiente AWS

O ambiente de Disaster Recovery é provisionado sob demanda e utiliza:

- Amazon VPC;
- subnet pública;
- Amazon EC2;
- Security Group;
- IAM Role / Instance Profile;
- AWS Systems Manager Session Manager;
- Amazon S3;
- Docker;
- Flask;
- SQLite;
- Litestream;
- Cloudflare Tunnel.

A instância EC2 não utiliza acesso SSH público. A administração é realizada por
meio do AWS Systems Manager.

Apesar de localizada em subnet pública, a aplicação não possui portas de entrada
expostas diretamente à Internet. O acesso externo ocorre através do Cloudflare
Tunnel.

---

### 3.3 Amazon S3

O Amazon S3 atua como armazenamento intermediário para as réplicas do banco
SQLite.

Durante a operação normal:

```text
On-Premises SQLite
        ↓
    Litestream
        ↓
    Amazon S3
```

Durante a operação no DR:

```text
AWS DR SQLite
      ↓
  Litestream
      ↓
  Amazon S3
```

O mesmo armazenamento é utilizado como origem para os processos de restore
durante failover e failback.

---

### 3.4 Cloudflare

A Cloudflare é utilizada para:

- resolução DNS;
- publicação da aplicação através de Cloudflare Tunnel;
- direcionamento do tráfego para o ambiente ativo.

O apontamento DNS é gerenciado pelo Terraform através do Cloudflare Provider.

Isso permite que a alteração entre os ambientes faça parte do estado declarado
da infraestrutura.

---

### 3.5 Estação Administrativa

O gerenciamento do laboratório é realizado a partir de uma estação
administrativa Linux/WSL.

A estação é responsável por:

- execução do Terraform;
- acesso SSH ao ambiente on-premises;
- acesso à EC2 através do AWS Systems Manager;
- execução dos scripts de orquestração;
- gerenciamento do failover e failback.

Fluxo simplificado:
```text
Admin Workstation
      |
      +--- SSH ----------> On-Premises
      |
      +--- SSM ----------> AWS EC2
      |
      +--- Terraform ----> AWS
      |
      +--- Terraform ----> Cloudflare
```

---

## 4. Fluxos da Arquitetura

### 4.1 Operação Normal

```text
User
 ↓
Cloudflare DNS
 ↓
Cloudflare Tunnel
 ↓
On-Premises
 ↓
Traefik
 ↓
Flask
 ↓
SQLite
 ↓
Litestream
 ↓
Amazon S3
```

O ambiente de computação da AWS não precisa permanecer ativo durante essa etapa.

---

### 4.2 Failover

```text
On-Premises unavailable
        ↓
Terraform
        ↓
AWS DR provisioning
        ↓
Restore from S3
        ↓
Application validation
        ↓
DNS cutover
        ↓
AWS DR active
```

O tráfego somente é direcionado para o ambiente DR após a restauração e
validação da aplicação.

---

### 4.3 Operação em DR

Enquanto o ambiente AWS permanece ativo:

```text
User
 ↓
Cloudflare DNS
 ↓
Cloudflare Tunnel
 ↓
Amazon EC2
 ↓
Flask
 ↓
SQLite
 ↓
Litestream
 ↓
Amazon S3
```

Os dados produzidos durante esse período continuam sendo replicados para o S3.

---

### 4.4 Failback

```text
AWS DR
 ↓
Final replication to S3
 ↓
Restore on-premises
 ↓
Database validation
 ↓
Application healthcheck
 ↓
DNS failback
 ↓
On-Premises active
 ↓
DR decommission
```

Antes do retorno do tráfego, o banco e a aplicação no ambiente primário são
validados.

---

## 5. Decisões Arquiteturais

### DR sob demanda

O ambiente computacional de Disaster Recovery não permanece ativo
continuamente.

**Motivação:** reduzir custos.

**Trade-off:** o provisionamento aumenta o RTO quando comparado a uma estratégia
warm standby.

---

### SQLite + Litestream + S3

O Litestream permite manter uma cópia externa do SQLite sem necessidade de um
servidor de banco secundário permanentemente ativo.

**Motivação:** simplicidade e baixo custo.

**Trade-off:** a replicação é assíncrona e o banco precisa ser restaurado durante
o processo de recuperação.

---

### Systems Manager em vez de SSH público

A EC2 é administrada utilizando AWS Systems Manager Session Manager.

**Motivação:** evitar exposição da porta TCP/22 e reduzir a superfície de ataque.

---

### Cloudflare Tunnel

A aplicação é publicada sem exposição direta de portas do ambiente on-premises
ou da instância EC2.

**Motivação:** reduzir a superfície pública da infraestrutura.

---

### Terraform como fonte da verdade

Terraform é utilizado para provisionar a infraestrutura AWS e controlar o
apontamento DNS através do Cloudflare Provider.

**Motivação:** tornar alterações reproduzíveis e reduzir mudanças manuais fora
do código.

---

## 6. Segurança da Arquitetura

Os principais controles considerados no desenho são:

- ausência de SSH público na EC2;
- acesso administrativo através de SSM;
- Security Group sem exposição direta da aplicação;
- IAM Role associada à EC2;
- acesso ao S3 através de permissões IAM;
- containers executados com usuário não-root;
- Cloudflare Tunnel para publicação;
- secrets não armazenados no código versionado.

Os detalhes dos controles estão documentados em: [Segurança](security.md)

## 7. Disponibilidade e Limitações

A solução fornece capacidade de recuperação após perda do ambiente primário,
mas não implementa High Availability.

Principais limitações:

- única instância EC2 no ambiente DR;
- ausência de arquitetura Multi-AZ;
- SQLite como banco de dados;
- replicação assíncrona;
- dependência do Amazon S3 para recuperação;
- dependência da Cloudflare para publicação e DNS;
- dependência da estação administrativa para iniciar os procedimentos;
- failover não iniciado automaticamente.

Essas limitações foram aceitas em função do objetivo educacional e do foco em
baixo custo do laboratório.

## 8. Documentos Relacionados
- [Plano de Implementação](implementation-plan.md)
- [Segurança](security.md)
- [Monitoramento](monitoring.md)
- [Análise de Custos](cost-analysis.md)
- [Troubleshooting](troubleshooting.md)
- [Lições Aprendidas](lessons-learned.md)
- [Evidências](../evidence/README.pt-BR.md)
