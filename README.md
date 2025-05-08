# **Script de Backup Automático do Nextcloud**

Este script automatiza o processo de backup dos **arquivos do Nextcloud** e do **banco de dados MySQL** associado. Ele oferece uma série de funcionalidades úteis, como ativação e desativação do modo de manutenção do Nextcloud, verificação do espaço disponível no diretório de destino, e exibição de barras de progresso durante o backup.

## **O que o script faz**

Este script realiza os seguintes passos:

1. **Ativa o Modo de Manutenção** do Nextcloud antes de realizar o backup, garantindo que o sistema não sofra alterações durante o processo.
2. **Verifica o espaço** disponível no diretório de destino para garantir que haja espaço suficiente para os arquivos de backup.
3. **Faz o backup dos arquivos** do Nextcloud e do banco de dados MySQL:
   - Backup dos arquivos é realizado utilizando `tar` e uma barra de progresso é exibida.
   - Backup do banco de dados MySQL é realizado utilizando `mysqldump`, compactado com `gzip` e exibindo uma barra de progresso.
4. **Desativa o Modo de Manutenção** após o término do backup, permitindo que o Nextcloud volte a ser acessado.
5. **Exibe um resumo final** com informações sobre o backup, incluindo o caminho dos arquivos gerados, o tamanho do backup e a data de realização.

## **Funcionalidades**

- **Modo de manutenção**: O script ativa e desativa o modo de manutenção do Nextcloud automaticamente.
- **Verificação de espaço**: Verifica o espaço disponível no diretório de destino antes de realizar o backup.
- **Backup dos arquivos e banco de dados**: Realiza o backup completo dos arquivos e do banco de dados MySQL do Nextcloud.
- **Barra de progresso**: Exibe barras de progresso durante o processo de backup.
- **Informações de resumo**: Ao final do processo, o script fornece um resumo detalhado com o tamanho dos backups e os caminhos dos arquivos gerados.

## **Instalação**

Para usar o script, siga os passos abaixo:

1. **Clone o repositório** para seu servidor:

   ```bash
   git clone https://github.com/SEU_USUARIO/nextcloud-backup-script.git
   ```
   ```
   cd nextcloud-backup-script
   ```
2. Dê permissões de execução ao script:

```
chmod +x nextcloud_backup.sh
```

### O script começará a execução e fará as seguintes perguntas interativas:

- `Caminho do diretório do Nextcloud:` Onde os arquivos do Nextcloud estão armazenados (ex: /var/www/nextcloud).

- `Caminho do destino do backup:` Onde o backup será salvo (ex: /backups/nextcloud).

- `Host do MySQL:` O endereço do servidor MySQL (geralmente localhost).

- `Usuário do MySQL:` O nome de usuário para acessar o banco de dados.

- `Nome do banco de dados:` O nome do banco de dados do Nextcloud.

- `Senha do MySQL:` A senha do banco de dados do Nextcloud.

- `Modo de Manutenção:` O script perguntará se você deseja ativar o modo de manutenção para garantir que o backup seja realizado sem interrupções.
 
