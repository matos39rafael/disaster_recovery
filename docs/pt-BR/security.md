# Segurança

> 🌐 Idiomas: [English](../en/security.md) | Português (Brasil)

## 1. Objetivo

Este documento descreve os principais controles de segurança adotados no
laboratório de Disaster Recovery.

O foco foi reduzir a superfície de ataque, evitar exposição desnecessária de
serviços e utilizar mecanismos nativos de autenticação e autorização sempre
que possível.

---

## 2. Princípios Adotados

A arquitetura foi desenvolvida com base nos seguintes princípios:

- menor privilégio;
- redução de superfície exposta;
- ausência de credenciais estáticas na EC2;
- administração remota sem SSH público;
- publicação da aplicação sem exposição direta de portas;
- separação entre código e secrets;
- validação antes de alterações de tráfego;
- infraestrutura reproduzível por código.

---

## 3. Acesso Administrativo

### Ambiente AWS

A instância EC2 do ambiente DR é administrada através do AWS Systems Manager
Session Manager.
Não é utilizada exposição pública da porta TCP/22.

Fluxo:

```text
Admin Workstation
       ↓
AWS Systems Manager
       ↓
EC2
```

Esse modelo reduz a necessidade de acesso administrativo direto pela Internet.

### Ambiente On-Premises

O servidor on-premises é acessado via SSH utilizando autenticação por chave.
O acesso administrativo é utilizado pelos scripts de orquestração durante
operações como restore e failback.

---

## 4. IAM

A EC2 utiliza uma IAM Role associada por Instance Profile.

As permissões permitem que a instância acesse apenas os serviços necessários
ao funcionamento do ambiente DR, principalmente:

- AWS Systems Manager;
- Amazon S3.

O objetivo é evitar o armazenamento de Access Key e Secret Access Key dentro
da instância EC2.

As permissões devem seguir o princípio de menor privilégio, limitando o acesso
aos recursos necessários ao laboratório.

---

## 5. Segurança de Rede

A instância EC2 é executada dentro de uma Amazon VPC e protegida por Security
Group.

A arquitetura não requer:

- SSH público;
- exposição direta da porta da aplicação;
- ingress público para administração.

O tráfego de saída é utilizado para comunicação com serviços externos
necessários, incluindo AWS e Cloudflare.

Embora a EC2 esteja em subnet pública, a aplicação não é publicada diretamente
por endereço IP público ou regra de ingress.

---

## 6. Publicação da Aplicação

O acesso externo à aplicação é realizado através do Cloudflare Tunnel.

Fluxo simplificado:

```text
Internet
   ↓
Cloudflare
   ↓
Cloudflare Tunnel
   ↓
Application
```

Esse modelo evita a exposição direta da porta da aplicação à Internet.
O mesmo conceito é utilizado nos ambientes on-premises e DR.

---

## 7. Containers

A aplicação é executada em containers Docker.

Sempre que aplicável, os containers utilizam usuário não-root para reduzir o
impacto de uma eventual exploração da aplicação.

Os volumes necessários à persistência são montados apenas onde requerido pelo
serviço.

---

## 8. Proteção dos Dados

O bucket utilizado para armazenar as réplicas do SQLite possui versionamento
habilitado.

Isso permite recuperar versões anteriores dos objetos caso a versão mais recente
do banco ou de uma réplica esteja corrompida ou inadequada para restauração.

Esse controle adiciona uma camada adicional de proteção contra corrupção,
sobrescrita ou recuperação de um estado indesejado.

---

## 9. Secrets e Credenciais

Credenciais e tokens não devem ser armazenados no repositório Git.

Para os secrets utilizados pelo ambiente DR, foi utilizado o AWS Systems Manager
Parameter Store.
A criação e atualização dos parâmetros foram realizadas através da AWS CLI, em vez
de Terraform, para evitar que valores sensíveis fossem persistidos no Terraform State.

Entre os dados sensíveis utilizados pelo laboratório estão:

- credenciais de autenticação AWS;
- Cloudflare API Token;
- credenciais utilizadas pelo Litestream e aplicação;
- arquivos .env;
- chaves SSH.

Esses arquivos e valores devem permanecer fora do versionamento.

A autenticação AWS da estação administrativa é realizada através da
configuração local da AWS CLI.

---

## 10. Segurança na transição do DNS

O apontamento DNS é gerenciado pelo Terraform através do Cloudflare Provider.
A alteração de tráfego somente deve ocorrer após:

- restore concluído;
- validação de integridade;
- aplicação inicializada;
- healthcheck bem-sucedido.

Isso reduz o risco de direcionar usuários para um ambiente ainda não funcional.

---

## 11. Controles Aplicados

| Controle                           | Implementação                       |
| ---------------------------------- | ----------------------------------- |
| Administração da EC2               | AWS Systems Manager Session Manager |
| SSH público na AWS                 | Não utilizado                       |
| Exposição direta da aplicação      | Não utilizada                       |
| Publicação externa                 | Cloudflare Tunnel                   |
| Autorização AWS da EC2             | IAM Role / Instance Profile         |
| Credenciais estáticas na EC2       | Não utilizadas                      |
| Proteção da aplicação em container | Usuário não-root                    |
| Gerenciamento de DNS               | Terraform + Cloudflare Provider     |
| Proteção de secrets                | Fora do repositório                 |
| Validação pré-cutover              | Banco + healthcheck                 |

## 12. Limitações de Segurança

Por se tratar de um laboratório, alguns controles de um ambiente de produção
não foram implementados.

Entre as principais limitações:

-ausência de arquitetura Multi-AZ;
-ausência de gestão centralizada de secrets;
-ausência de WAF dedicado ao ambiente DR;
-ausência de monitoramento de segurança centralizado;
-ausência de rotação automatizada de credenciais;
-dependência da estação administrativa;
-ausência de pipeline automatizado para validação de segurança do código e da infraestrutura.

Esses pontos representam oportunidades de evolução da solução.

---

### 13. Melhorias Futuras

Possíveis evoluções incluem:

- políticas IAM ainda mais restritivas;
- logs de segurança centralizados;
- alertas para eventos de segurança;
- análise automatizada do código Terraform;
- scan automatizado das imagens Docker;
- validação de segurança em pipeline CI/CD;
- implementação de regras adicionais de WAF e rate limiting na camada Cloudflare;
- rotação automatizada de secrets armazenados no Parameter Store.
