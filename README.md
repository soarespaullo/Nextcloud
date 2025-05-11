# Backup Automático do Nextcloud

Este script foi desenvolvido para facilitar a realização de backups automáticos dos arquivos e banco de dados do **Nextcloud**, garantindo que o processo seja seguro e eficiente. O backup pode ser feito de forma simples e personalizada, com a opção de ativar o modo de manutenção do Nextcloud para evitar inconsistências.

---

## 🚀 Funcionalidades

- **Backup completo** dos arquivos e banco de dados do Nextcloud.
- **Verificação de permissões**: O script exige privilégios de `root` para garantir que o processo tenha as permissões necessárias.
- **Modo de manutenção**: O script permite ativar o modo de manutenção do Nextcloud, evitando que usuários modifiquem os arquivos durante o backup.
- **Verificação de espaço**: O script verifica se há espaço suficiente disponível no diretório de backup antes de iniciar.
- **Progresso do backup**: Utiliza a ferramenta `pv` para exibir o progresso do backup de arquivos e banco de dados.
- **Personalização**: O script permite definir os diretórios de origem e destino, o banco de dados e outras configurações importantes.

---

## 🛠️ Requisitos

- **Sistema operacional**: Linux (Ubuntu, Debian, etc.)
- **Privilégios de root**: O script precisa ser executado com permissões de superusuário.
- **Ferramentas**: O script depende das ferramentas:
  - `tar`
  - `pv` (o script irá instalá-lo automaticamente, se necessário)
  - `mysqldump`
  - `gzip`
- **MySQL/MariaDB**: O banco de dados do Nextcloud deve estar rodando em um servidor MySQL ou MariaDB.

---

## 📥 Instalação

### 1. Baixe o script

Primeiro, faça o download ou copie o código do script para o seu servidor.

```
wget https://github.com/soarespaullo/scripts/backup_nextcloud.sh
```
### 2. Torne o script executável

```
chmod +x backup_nextcloud.sh
```
## 🏃‍♂️ Como Usar

### 1. Execute o script como root

Este script deve ser executado com permissões de root. Para isso, utilize o comando `sudo`:

### 2. Forneça as informações solicitadas

O script pedirá informações sobre:

- **Caminho do diretório do Nextcloud** (ex: `/var/www/nextcloud`)

- **Caminho do diretório de destino do backup** (ex: `/backups/nextcloud`)

**Credenciais do banco de dados MySQL**:

- **Host do MySQL** (ex: `localhost`)

- **Usuário do MySQL** (ex: `root`)

- **Nome do banco de dados do Nextcloud**

- **Senha do MySQL**

### 3. Ativar o modo de manutenção (opcional)

Antes de realizar o backup, o script oferece a opção de ativar o modo de manutenção do Nextcloud. Isso impede que usuários façam alterações durante o processo de backup, evitando possíveis inconsistências.

Você pode ativar o modo de manutenção respondendo com `s` (sim) ou deixar de ativá-lo respondendo com `n` (não).

Exemplo de prompt:

```
Você deseja ativar o modo de manutenção antes do backup? (s/n): s
```
Se você optar por ativar o modo de manutenção, o script irá executar o comando necessário para colocá-lo no modo de manutenção.

### 4. Processo de Backup

O script executa as seguintes etapas durante o processo de backup:

1. **Backup dos arquivos**: O diretório do Nextcloud será compactado e salvo no diretório de backup que você especificou.

2. **Backup do banco de dados**: O banco de dados será exportado utilizando `mysqldump`, e o arquivo será comprimido para o destino informado.

3. **Status do backup**: Após o backup ser concluído, o script exibirá o status, incluindo o caminho para os arquivos gerados e o tamanho do backup.

### 5. Segurança
O backup dos dados do Nextcloud e do banco de dados é feito de maneira segura, garantindo que todos os arquivos sejam preservados e a integridade dos dados seja mantida.

É recomendado **criptografar** os backups para maior segurança, especialmente se os dados forem sensíveis, ou armazená-los em um local seguro.

O script oferece a opção de **habilitar o modo de manutenção**, o que evita que usuários façam alterações durante o processo de backup. Isso ajuda a garantir que o backup não seja corrompido.

## 🔄 Agendamento de Backup Automático (Cron)

Você pode agendar o script para ser executado automaticamente em intervalos regulares, utilizando o cron. Isso garante que o backup seja feito periodicamente sem necessidade de intervenção manual.

**Passos para agendar o script:**

1. Edite o arquivo crontab com o seguinte comando:

```
crontab -e
```

2. Adicione a seguinte linha para rodar o script todos os dias às 2 da manhã (ajuste conforme sua necessidade):

```
0 2 * * * /caminho/para/backup_nextcloud.sh
```

Isso fará com que o script seja executado automaticamente todos os dias às 2:00 da manhã. Certifique-se de fornecer o caminho correto para o script.

Dica: É uma boa prática utilizar o `logrotate` para organizar os backups, garantindo que os arquivos antigos sejam apagados ou compactados para não ocupar muito espaço em disco.

## ⚙️ Personalização

Você pode personalizar o script conforme suas necessidades, incluindo:

- **Mudança na compressão dos arquivos:** O script usa `gzip` para comprimir os arquivos, mas você pode modificar para usar outras ferramentas de compressão, como `bzip2` ou `xz`, se preferir.

- **Adicionar mais diretórios ou bancos de dados:** Se seu Nextcloud utiliza mais de um banco de dados ou você precisa fazer backup de outros diretórios, você pode editar o script para incluir essas opções.

- **Alterar os diretórios padrão:** Se o diretório de instalação do Nextcloud ou o diretório de backup for diferente, basta alterar as variáveis de caminho no script.

## 🧑‍💻 Contribuições

Se você deseja contribuir para o script, sinta-se à vontade para fazer um **fork** do repositório e criar uma **pull request**. Ao contribuir, lembre-se de:

- Testar suas mudanças antes de enviar.

- Manter a compatibilidade com as versões anteriores.

- Adicionar comentários explicativos no código para melhorar a legibilidade e manutenção.

## 📚 Recursos e Referências

- [Documentação do `Nextcloud`](https://docs.nextcloud.com/)

- [MySQL - `mysqldump`](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html)

- [Comando `pv`](https://linux.die.net/man/1/pv)
