# Evidências de Teste — Disaster Recovery

> 🌐 Idiomas: [English](README.md) | Português (Brasil)

Este documento registra as evidências coletadas durante a execução dos testes
de Disaster Recovery e failback do laboratório.

As imagens desta pasta são compartilhadas entre as versões em português e inglês (que está em desenvolvimento).

## 1. Objetivo

Registrar as evidências técnicas utilizadas para validar o funcionamento da estratégia de Disaster Recovery entre o ambiente on-premises e a AWS.

As evidências deste documento devem demonstrar:

- operação normal da aplicação no ambiente on-premises;
- replicação do banco SQLite para o Amazon S3;
- indisponibilidade do ambiente primário;
- provisionamento do ambiente DR;
- restauração do banco;
- disponibilidade da aplicação na AWS;
- medição do RTO;
- gravação de dados durante a operação em DR;
- replicação desses dados para o S3;
- restauração no ambiente on-premises;
- validação do failback;
- retorno do tráfego ao ambiente primário;
- desprovisionamento do ambiente DR.

---

## 2. Escopo do Teste

### Em escopo

- failover on-premises → AWS;
- restore do banco SQLite;
- validação de integridade;
- healthcheck da aplicação;
- mudança de apontamento do DNS;
- operação temporária no ambiente DR;
- failback AWS → on-premises;
- validação de persistência dos dados;
- desprovisionamento da infraestrutura AWS.

### Fora de escopo

- testes Multi-AZ;
- High Availability;
- failover automático sem intervenção;
- testes de carga;
- testes de performance;
- testes de segurança ofensiva.

---

## 3. Ambiente de Teste

### Ambiente primário

- Linux Server
- Docker
- Flask
- SQLite
- Litestream
- Traefik
- Cloudflare Tunnel

### Ambiente DR

- Amazon EC2
- Amazon S3
- AWS Systems Manager
- Docker
- Flask
- SQLite
- Litestream
- Cloudflare Tunnel

### Orquestração

- Terraform
- AWS CLI
- Bash
- SSH
- AWS Systems Manager Session Manager

---

## 4. Critérios de Sucesso

O teste será considerado aprovado quando:

- o ambiente on-premises for interrompido;
- o DR for provisionado;
- o banco for restaurado;
- a integridade do banco for validada;
- a aplicação ficar disponível na AWS;
- o DNS for redirecionado corretamente;
- novos dados puderem ser gravados no DR;
- os dados produzidos no DR forem replicados para o S3;
- o banco for restaurado no ambiente on-premises;
- os dados criados durante o DR forem recuperados;
- a aplicação on-premises ficar saudável;
- o DNS retornar ao ambiente primário;
- o ambiente DR puder ser removido.

---

## 5. Resumo dos Resultados

## 5. Resumo dos Resultados

| Teste | Resultado esperado | Resultado observado | Status | Evidência |
|---|---|---|---|---|
| Aplicação on-premises operacional | Aplicação acessível e registro de validação presente antes da falha | Aplicação disponível no ambiente on-premises e registro de teste criado com sucesso | **Aprovado** | 01 |
| Replicação SQLite → S3 | Réplica recente do banco disponível no Amazon S3 | Réplicas do banco identificadas no S3 por meio do Console AWS e da AWS CLI após a criação de novo registro | **Aprovado** | 02–03 |
| Falha do ambiente primário | Aplicação on-premises indisponível após interrupção da stack | Stack interrompida e endpoint público indisponível, retornando HTTP 404 | **Aprovado** | 04 |
| Provisionamento DR | Infraestrutura DR criada com sucesso pelo Terraform | `terraform plan` gerado e `terraform apply` concluído, provisionando os recursos necessários ao ambiente DR | **Aprovado** | 05–07 |
| Restore no DR | Banco restaurado a partir das réplicas armazenadas no S3 | Aplicação inicializada no DR com os dados previamente existentes no ambiente on-premises disponíveis | **Aprovado** | 08–09 |
| Integridade do banco no DR | Banco restaurado íntegro e utilizável pela aplicação | A aplicação iniciou e utilizou o banco restaurado; não houve evidência específica de `PRAGMA integrity_check` nesta etapa | **Aprovado com observação** | 08–09 |
| Aplicação DR | Aplicação disponível externamente através do ambiente AWS | Aplicação tornou-se disponível no ambiente DR e permitiu acesso e operações de escrita | **Aprovado** | 08–09 |
| RTO | Serviço restabelecido dentro da meta definida | RTO observado de **223 s (3 min 43 s)** | **Aprovado** | 08 |
| Escrita durante DR | Novos registros criados e persistidos enquanto o DR estiver ativo | Novos registros foram criados no ambiente DR; evidência adicional confirma on-premises sem stack ativa e DR em execução | **Aprovado** | 09, 11 |
| Replicação DR → S3 | Estado atualizado durante o DR replicado para o S3 | Novas réplicas foram identificadas no bucket após as gravações realizadas no ambiente DR | **Aprovado** | 10 |
| Restore on-premises | Estado mais recente do banco restaurado no ambiente primário | Restore concluído com sucesso e backup de segurança pré-failback criado | **Aprovado** | 12–13 |
| Validação do failback | Banco íntegro e dados criados no DR presentes após restore | `PRAGMA integrity_check` retornou `ok` e o registro de validação criado no DR foi encontrado no banco restaurado | **Aprovado** | 13 |
| Healthcheck on-premises | Aplicação saudável antes do retorno do tráfego | Stack inicializada e healthcheck executado com sucesso por meio do Traefik | **Aprovado** | 14–15 |
| DNS failback | DNS alterado para retornar o tráfego ao ambiente on-premises | Terraform aplicou a alteração de DNS e o estado passou a indicar `active_environment = "onprem"` | **Aprovado** | 16–17 |
| Validação pública após failback | Endpoint público novamente acessível após retorno ao on-premises | Primeira tentativa retornou HTTP 502; tentativa subsequente foi concluída com sucesso | **Aprovado com observação** | 18 |
| Desprovisionamento DR | Recursos temporários da AWS removidos após o failback | Terraform concluiu a remoção do ambiente DR sem afetar o ambiente on-premises já restabelecido | **Aprovado** | 18–19 |

---

# 6. Evidências do Failover

## 6.1 Operação normal no ambiente on-premises

### Objetivo

Comprovar que a aplicação estava operacional antes da simulação de falha.

### Resultado esperado

- aplicação acessível;
- banco íntegro;
- registro de teste presente.

### Resultado observado

A aplicação estava disponível no ambiente on-premises e respondendo normalmente antes da falha simulada. Um registro
de validação foi criado no banco SQLite para posterior confirmação durante o processo de recuperação. Esse estado foi
utilizado como referência inicial do teste de Disaster Recovery.

### Evidência

![Aplicação on-premises operacional](01-onprem-running.png)

---

## 6.2 Replicação do banco para o Amazon S3

### Objetivo

Confirmar que o Litestream está replicando o SQLite para o S3 antes do desastre.

### Resultado esperado

Existência de uma réplica recente no bucket configurado.

### Resultado observado

Foi confirmada, tanto pelo Console da AWS quanto pela AWS CLI, a presença das réplicas do banco SQLite no bucket do Amazon S3 após a criação de um novo registro na aplicação.
As evidências demonstram que o Litestream estava replicando corretamente as alterações do banco para o armazenamento remoto utilizado no processo de Disaster Recovery.

### Evidências

![Replicação S3 Console](02-s3-replication-console.png)

![Replicação S3 CLI](03-s3-replication-cli.png)

---

## 6.3 Simulação da falha

### Objetivo

Simular a indisponibilidade do ambiente primário.

### Ação executada

A stack da aplicação no ambiente on-premises foi interrompida, tornando o serviço indisponível para acesso pelos usuários.

### Resultado esperado

A aplicação deve deixar de responder externamente.

### Resultado observado

Após a interrupção da stack, o acesso à aplicação pelo endpoint público deixou de funcionar, retornando erro HTTP 404.
A indisponibilidade confirmou a falha do ambiente primário e marcou o início do cenário de recuperação.

### Evidência

![Falha do ambiente on-premises](04-onprem-failure.png)

---

## 6.4 Provisionamento do ambiente DR

### Objetivo

Criar a infraestrutura AWS necessária para recuperação.

### Ação executada

A infraestrutura de Disaster Recovery foi provisionada utilizando o Terraform.
Primeiramente, foi gerado um plano utilizando os arquivos de variáveis correspondentes ao ambiente DR:

```bash
terraform plan \
  -var-file=environments/dr.tfvars \
  -var-file=terraform.tfvars \
  -out=dr.tfplan
```
Após a revisão do plano, a infraestrutura foi provisionada com:

`terraform apply dr.tfplan`

### Resultado esperado

- infraestrutura criada;
- EC2 disponível;
- bootstrap iniciado;
- restore executado;
- aplicação preparada para receber tráfego.

### Resultado observado

O `terraform plan` foi gerado com sucesso utilizando os arquivos de variáveis do ambiente DR, e o `terraform apply` concluiu o provisionamento dos recursos necessários na AWS.
Após a aplicação do plano, a instância EC2 e os demais recursos de suporte do ambiente de Disaster Recovery foram criados, permitindo o prosseguimento para as etapas de restore e validação da aplicação.

### Evidências

![terraform plan 1](05-terraform-plan.png)

![terraform plan 2](06-terraform-plan.png)

![terraform apply](07-terraform-apply.png)

---

## 6.5 Validação da aplicação no DR

### Objetivo

Confirmar que a aplicação está operacional após a recuperação.

### Resultado esperado
- banco restaurado;
- healthcheck válido;
- aplicação disponível externamente.

### Resultado observado

Após o provisionamento do ambiente de Disaster Recovery, a aplicação tornou-se disponível externamente por meio do ambiente AWS.
Foi confirmado que o banco restaurado continha os dados esperados e que a aplicação estava funcional, permitindo o prosseguimento do teste com a operação temporária no ambiente DR.

### Evidência

![DR disponível e RTO](08-dr-available-rto.png)

![Dados disponíveis no ambiente DR](09-dr-records.png)

---

## 7. Medição do RTO

### 7.1 Definição

Para esta execução, o RTO foi definido como o intervalo entre a conclusão da interrupção da stack da aplicação no
ambiente on-premises e a primeira confirmação automática de disponibilidade da aplicação através do ambiente DR.

A medição foi realizada automaticamente pelo script de evidências, utilizando timestamps em memória durante a execução:
```bash
DISASTER_TIME=$(date +%s)
...
END=$(date +%s)

echo "RTO: $((END - DISASTER_TIME)) seconds"
```

---

### 7.2 Resultado


| Métrica | Resultado |
|---|---:|
| RTO observado | **223 segundos (3 min 43 s)** |
| Tempo de ativação do DR | **172 segundos (2 min 52 s)** |

O RTO de 223 segundos (3 min 43 s) foi calculado automaticamente pelo script durante a execução.
Embora a saída completa não tenha sido persistida em arquivo de log, os timestamps registrados nas
capturas de tela do início da indisponibilidade e da disponibilidade do DR são consistentes com o valor calculado.

---

### 7.3 Observações

Os seguintes fatores influenciaram o RTO observado:

- **Pausas manuais para coleta de evidências:** o fluxo incluiu uma interrupção
  manual antes do início do provisionamento do ambiente DR, aumentando o tempo
  total medido.
- **Intervalo de polling do healthcheck:** a disponibilidade do ambiente DR foi
  verificada em intervalos de 5 segundos, podendo adicionar alguns segundos ao
  tempo registrado entre a disponibilidade real da aplicação e sua detecção
  pelo script.
- **Execução do `terraform plan`:** o tempo necessário para geração do plano
  antes do `terraform apply` também foi contabilizado no RTO observado.


### 7.4 Evidência

![RTO observado](08-dr-available-rto.png)

---

## 8. Operação no Ambiente DR

### 8.1 Criação de novos dados

#### Objetivo

Comprovar que a aplicação funciona normalmente durante o período de DR.

#### Ação executada

Criar um novo registro durante a operação na AWS.

#### Resultado esperado

- novos registros devem ser criados e persistidos no banco SQLite do ambiente DR;
- o ambiente on-premises deve permanecer sem a stack da aplicação em execução;
- o ambiente DR deve permanecer com a stack ativa e atendendo a aplicação;
- os dados criados durante esse período devem estar disponíveis para posterior replicação ao Amazon S3 e validação no failback.

#### Resultado observado

Durante a operação no ambiente de Disaster Recovery, foram criados novos registros com sucesso na aplicação.
A evidência coletada mostra simultaneamente o ambiente on-premises sem a stack ativa e o ambiente DR com os containers em execução,
confirmando que o ambiente AWS era o responsável pela operação da aplicação naquele momento.
Os novos registros foram persistidos no banco SQLite do DR e posteriormente utilizados para validar a replicação para o Amazon S3 e o processo de failback.

#### Evidência

![Registros no DR](09-dr-records.png)

![Status DR e On-Premises](11-dr-and-onprem-status.png)

---

### 8.2 Replicação durante o DR

#### Objetivo

Confirmar que os dados produzidos na AWS foram replicados para o S3.

#### Resultado esperado

Réplica atualizada contendo o estado produzido durante o DR.

#### Resultado observado

Durante a operação no ambiente de Disaster Recovery, foi confirmada a atualização das réplicas do banco SQLite no Amazon S3 após
a criação de novos registros na aplicação.
A evidência demonstra que o Litestream continuou replicando as alterações geradas no ambiente DR para o armazenamento remoto,
preservando o estado mais recente do banco para utilização posterior no processo de failback.

#### Evidência

![Replicação dos dados no S3](10-s3-replication-console.png)

---

## 9. Evidências do Failback

### 9.1 Início do failback

#### Objetivo

Iniciar o processo controlado de retorno para o ambiente primário.

#### Resultado esperado

O processo deve identificar corretamente o ambiente DR e iniciar a sequência de failback.

#### Resultado observado

O processo de failback foi iniciado a partir da estação administrativa por meio do script de orquestração.
A execução confirmou o início da sequência de retorno ao ambiente on-premises, com interação coordenada entre o ambiente DR,
o servidor on-premises e o Terraform.
A partir desse ponto, o fluxo prosseguiu para a replicação final dos dados, restauração do banco no ambiente primário,
validações de integridade e posterior retorno do tráfego ao on-premises.

#### Evidência

![Inicio failback](12-failback-start.png)

---

### 9.2 Restore no ambiente on-premises

#### Objetivo

Restaurar o banco mais recente a partir do S3.

#### Resultado esperado
- backup pré-failback criado;
- restore concluído;
- banco íntegro.

#### Resultado observado

O banco de dados mais recente foi restaurado no ambiente on-premises a partir das réplicas armazenadas no Amazon S3.
Antes da substituição do banco local, foi criada uma cópia de segurança pré-failback. Em seguida, o restore foi
concluído com sucesso, permitindo o prosseguimento para as etapas de validação de integridade, verificação dos
registros criados durante a operação em DR e inicialização da aplicação no ambiente primário.

#### Evidência

![Restauração dos dados on-prem](13-onprem-restore.png)

---

### 9.3 Validação do banco restaurado

#### Objetivo

Comprovar que o banco restaurado contém os dados produzidos durante o DR.

#### Validação de integridade
`PRAGMA integrity_check;`

Resultado esperado:
`ok`

#### Registro de validação
`TESTE_DR_FAILBACK_01`

#### Resultado observado

Após o restore no ambiente on-premises, o banco SQLite foi validado com sucesso.
A verificação de integridade retornou `ok` por meio do comando `PRAGMA integrity_check`, e o registro de validação
criado durante a operação no ambiente DR foi localizado no banco restaurado.
Esses resultados confirmaram que o banco recuperado estava íntegro e continha os dados produzidos durante o período
de operação na AWS, permitindo o prosseguimento do processo de failback.

#### Evidência

![Validação do banco](13-onprem-restore.png)

---

### 9.4 Healthcheck do ambiente on-premises

#### Objetivo

Validar a aplicação antes de retornar o tráfego público.

#### Resultado esperado
- containers em execução;
- aplicação saudável;
- Traefik respondendo corretamente.

#### Resultado observado

Após a restauração do banco e a inicialização da stack no ambiente on-premises, o healthcheck da aplicação foi executado com sucesso.
A validação confirmou que os containers estavam em execução e que a aplicação respondia corretamente por meio do Traefik no ambiente
primário, permitindo o prosseguimento do failback antes da alteração do apontamento DNS.
Com o ambiente on-premises validado como saudável, o processo avançou para a etapa de retorno do tráfego.

#### Evidência

![On-premises start](14-onprem-start.png)

![On-premises healthcheck](15-onprem-healthcheck.png)

---

### 9.5 DNS failback

#### Objetivo

Retornar o tráfego para o ambiente primário.

#### Resultado esperado

O Terraform deve alterar o estado desejado do DNS para apontar novamente para o Cloudflare Tunnel on-premises.

#### Resultado observado

Após a validação do ambiente on-premises, o Terraform foi executado para alterar o apontamento DNS e retornar o tráfego ao ambiente primário.
A alteração foi aplicada com sucesso por meio do provider da Cloudflare, e o estado desejado passou a indicar o ambiente on-premises como ativo.
Com a transição concluída, o fluxo prosseguiu para a validação pública da aplicação e posterior desprovisionamento do ambiente de Disaster Recovery.

#### Evidência

![DNS failback 1](16-dns-failback.png)

![DNS failback 2](17-dns-failback.png)

---

### 9.6 Validação externa

#### Objetivo

Confirmar que a aplicação voltou a ser atendida pelo ambiente on-premises.

#### Resultado esperado

Aplicação disponível externamente após a transição do DNS.

#### Resultado observado

Após a alteração do DNS para o ambiente on-premises, o endpoint público foi novamente validado.
A primeira tentativa retornou HTTP 502; uma tentativa subsequente foi concluída com sucesso,
confirmando a restauração do acesso público após a transição.

#### Evidência

![Validação externa](18-public-validation-and-dr-decommission.png)

---

### 9.7 Desprovisionamento do ambiente DR

#### Objetivo

Remover os recursos temporários da AWS após o failback.

#### Resultado esperado
- EC2 removida;
- recursos temporários removidos;
- ambiente primário permanece operacional.

#### Resultado observado

Após a validação do retorno da aplicação ao ambiente on-premises, o ambiente de Disaster Recovery na AWS foi desprovisionado.
A execução do Terraform removeu os recursos temporários utilizados durante o processo de recuperação, encerrando o ciclo de DR
sem impactar o ambiente primário já restabelecido.
Ao final da etapa, a aplicação permaneceu operacional no ambiente on-premises e a infraestrutura temporária de Disaster Recovery
deixou de permanecer ativa na AWS.

#### Evidência

![Decomissionamento do DR](19-dr-decommission.png)

----

## 10. Resultado Final

### Failover

**Status: Aprovado**

O teste de failover foi concluído com sucesso.

Após a interrupção do ambiente on-premises, a infraestrutura de Disaster
Recovery foi provisionada na AWS através do Terraform. O banco SQLite foi
recuperado a partir das réplicas armazenadas no Amazon S3 e a aplicação
voltou a ficar disponível através do ambiente DR.

O RTO observado foi de **223 segundos (3 min 43 s)**, sendo **172 segundos
(2 min 52 s)** correspondentes ao intervalo entre o início do
`terraform apply` e a disponibilidade da aplicação no ambiente DR.

A aplicação permaneceu funcional durante a operação no ambiente AWS e novos
dados foram gravados e posteriormente replicados para o Amazon S3.

### Failback

**Status: Aprovado**

O teste de failback foi concluído com sucesso.

Os dados produzidos durante a operação no ambiente DR foram replicados para
o Amazon S3 e posteriormente restaurados no ambiente on-premises.

Após o restore:

- a integridade do banco foi validada;
- o registro criado durante o DR foi recuperado;
- a aplicação on-premises foi inicializada;
- o healthcheck local foi aprovado;
- o DNS foi alterado para retornar o tráfego ao ambiente primário;
- o acesso público foi validado;
- o ambiente DR foi desprovisionado.

### Resultado geral

**Status: Aprovado**

O laboratório demonstrou com sucesso o ciclo completo de Disaster Recovery:

```text
On-Premises
     ↓
Replicação para S3
     ↓
Falha
     ↓
Provisionamento AWS
     ↓
Restore
     ↓
Failover
     ↓
Operação em DR
     ↓
Replicação para S3
     ↓
Failback
     ↓
On-Premises
     ↓
Decommission DR
```

## 11. Observações e Limitações do Teste

A execução foi realizada em ambiente de laboratório e incluiu etapas manuais
destinadas à coleta de evidências.

As principais limitações observadas foram:

- o processo depende de uma estação administrativa externa para execução dos
  scripts e do Terraform;
- foram realizadas pausas manuais durante o failover para coleta de evidências;
- a disponibilidade do DR foi verificada por polling em intervalos de 5 segundos;
- a infraestrutura utiliza uma única instância EC2 e não implementa Multi-AZ;
- o processo de failover não é iniciado automaticamente após detecção de falha;
- as métricas e timestamps foram exibidos no terminal, mas não persistidos em
  arquivo de log nesta execução.

## 12. Conclusão

A execução validou com sucesso o ciclo completo de Disaster Recovery proposto
para o laboratório.

Após a indisponibilidade do ambiente on-premises, a aplicação foi recuperada
na AWS com RTO observado de **3 min 43 s**. Durante a operação no ambiente DR,
novos dados foram gerados e replicados para o Amazon S3.

O processo de failback restaurou esses dados no ambiente on-premises, validou
a integridade do banco e a saúde da aplicação antes do retorno do tráfego.
Após a validação externa, os recursos temporários do ambiente DR foram
desprovisionados.

Não foi observada perda dos registros utilizados como marcadores durante os
testes de failover e failback.

O teste demonstrou, portanto, a viabilidade da estratégia proposta de
recuperação sob demanda utilizando Terraform, Amazon EC2, Amazon S3,
Litestream, Docker e Cloudflare.
