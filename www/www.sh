#!/bin/bash
#
# ========================================================================
#  SCRIPT DE BACKUP AUTOMATIZADO DO SISTEMA (BANCOS DE DADOS + /var/www)
# ------------------------------------------------------------------------
#  Autor:      Paulo Soares
#  Contato:    soarespaullo@proton.me
#  GitHub:     https://github.com/soarespaullo
#  Telegram:   @soarespaullo
#  Versão:     2.0
#  Criado em:  11/04/2025
# ------------------------------------------------------------------------
#  Descrição:
#      Este script realiza o backup automatizado de todos os bancos de
#      dados MySQL e da pasta /var/www, com verificação de espaço,
#      compressão, e saída amigável com barra de progresso.
#
#  Requisitos:
#      - Executar como root (sudo)
#      - Utilitários: tar, gzip, pv, mysqldump
#
#  Licença: MIT
# ========================================================================

# === CORES PARA TERMINAL ===
VERMELHO="\e[31m" # VERMELHO
VERDE="\e[32m"    # VERDE
AZUL="\e[34m"     # AZUL
AMARELO="\e[33m"  # AMARELO
SEM_COR="\e[0m"   # SEM COR

# === VERIFICA SE É ROOT ===
if [[ "$EUID" -ne 0 ]]; then
  echo -e "${VERMELHO}Este script deve ser executado como root.${SEM_COR}"
  echo -e "${AMARELO}Execute como:${SEM_COR} sudo ./backup_system.sh"
  exit 1
fi

# === BANNER COLORIDO E INFORMATIVO ===
clear
echo -e "${AZUL}=============================================================${SEM_COR}"
echo -e "${AZUL} ${AMARELO}           BACKUP AUTOMATIZADO DO SISTEMA       ${AZUL} ${SEM_COR}"
echo -e "${AZUL}=============================================================${SEM_COR}"
echo -e "${AZUL} ${VERDE} Este script realiza o backup de todos os bancos   ${AZUL} ${SEM_COR}"
echo -e "${AZUL} ${VERDE} de dados MySQL e da pasta /var/www com segurança.${AZUL} ${SEM_COR}"
echo -e "${AZUL}=============================================================${SEM_COR}"
echo -e "${AZUL} ${AMARELO} Data e hora: ${SEM_COR}$(date +"%d/%m/%Y %H:%M:%S")    ${AZUL} ${SEM_COR}"
echo -e "${AZUL} ${AMARELO} Usuário atual: ${SEM_COR}$(whoami)                     ${AZUL} ${SEM_COR}"
echo -e "${AZUL}=============================================================${SEM_COR}"

# === SOLICITA E VALIDA O CAMINHO DO BACKUP (OU CRIA SE NÃO EXISTIR) ===
while true; do
  echo -ne "${AMARELO}Caminho do destino do backup (ex: /media/backup): ${SEM_COR}"
  read -e BACKUP_DIR
  if [[ -d "$BACKUP_DIR" ]]; then
    break
  else
    echo -ne "${AMARELO}Diretório não existe. Deseja criá-lo? (s/n): ${SEM_COR}"
    read -e CRIAR_DIR
    if [[ "$CRIAR_DIR" == "s" || "$CRIAR_DIR" == "S" ]]; then
      mkdir -p "$BACKUP_DIR"
      if [[ $? -eq 0 ]]; then
        echo -e "${VERDE}Diretório criado com sucesso.${SEM_COR}"
        break
      else
        echo -e "${VERMELHO}Erro ao criar diretório. Verifique permissões.${SEM_COR}"
      fi
    fi
  fi
done

# === BACKUP DA PASTA /VAR/WWW ===
echo -e "${VERDE}Iniciando backup da pasta /var/www...${SEM_COR}"
WWW_DIR="/var/www"
BACKUP_WWW_NAME="var_www_backup_$(date +'%d-%m-%Y_%H:%M:%S').tar.gz"

# Verificando espaço suficiente para o backup da pasta /var/www
REQUIRED_SPACE_GB=$(du -s --block-size=1G "$WWW_DIR" | awk '{print $1}')
AVAILABLE_SPACE_GB=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')

echo -e "${AZUL}Espaço necessário para /var/www: ${REQUIRED_SPACE_GB}GB${SEM_COR}"
echo -e "${AZUL}Espaço disponível: ${AVAILABLE_SPACE_GB}GB${SEM_COR}"

if (( REQUIRED_SPACE_GB > AVAILABLE_SPACE_GB )); then
  echo -e "${VERMELHO}Espaço insuficiente para o backup!${SEM_COR}"
  exit 1
fi

# Fazendo o backup da pasta /var/www com barra de progresso
tar -C "$WWW_DIR" -cf - . | pv -p -s $(du -sb "$WWW_DIR" | awk '{print $1}') | gzip > "$BACKUP_DIR/$BACKUP_WWW_NAME"
echo -e "${VERDE}Backup da pasta /var/www concluído.${SEM_COR}"

# === BACKUP DE TODOS OS BANCOS DE DADOS DO MYSQL ===
echo -e "${VERDE}Iniciando backup de todos os bancos de dados MySQL...${SEM_COR}"

# Recupera todos os bancos de dados
DATABASES=$(mysql -e "SHOW DATABASES;" -s --skip-column-names | grep -Ev "(information_schema|performance_schema|mysql|sys)")

for DB in $DATABASES; do
  echo -e "${VERDE}Realizando backup do banco de dados: $DB${SEM_COR}"
  DUMP_FILE="/tmp/${DB}_dump.sql"

  # Faz o dump do banco de dados
  mysqldump -u root -p --databases "$DB" > "$DUMP_FILE"
  if [[ $? -ne 0 ]]; then
    echo -e "${VERMELHO}Erro ao gerar o dump do banco $DB.${SEM_COR}"
    exit 1
  fi

  # Comprime o dump
  gzip "$DUMP_FILE"
  echo -e "${VERDE}Backup do banco de dados $DB concluído.${SEM_COR}"

  # Move o arquivo de backup para o diretório de destino
  mv "$DUMP_FILE.gz" "$BACKUP_DIR/${DB}_backup_$(date +'%d-%m-%Y_%H:%M:%S').sql.gz"
done

# === RESUMO FINAL COM FORMATAÇÃO COLORIDA ===
echo -e "${AZUL}=================================================================${SEM_COR}"
echo -e "${AZUL} ${VERDE}            BACKUP CONCLUÍDO COM SUCESSO                ${AZUL} ${SEM_COR}"
echo -e "${AZUL}=================================================================${SEM_COR}"
echo -e "${AZUL} ${AMARELO} Arquivos salvos em:${SEM_COR}                        ${AZUL} ${SEM_COR}"
echo -e "${AZUL} ${SEM_COR}$BACKUP_DIR/$BACKUP_WWW_NAME" 
for DB in $DATABASES; do
  echo -e "${AZUL} ${SEM_COR}$BACKUP_DIR/${DB}_backup_$(date +'%d-%m-%Y_%H:%M:%S').sql.gz" 
done
echo -e "${AZUL}=================================================================${SEM_COR}"

# === FIM DO SCRIPT ===
echo -e "${VERDE}O script foi executado com sucesso.${SEM_COR}"
